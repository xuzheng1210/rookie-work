#!/usr/bin/env bash
# Tests for build/build.sh: shared content is placed per-agent, matches the
# canonical sources byte-for-byte, and regeneration is deterministic (anti-drift).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ ! -x "${ROOT}/build/build.sh" ] && [ ! -f "${ROOT}/build/build.sh" ]; then
  echo "FAIL: build/build.sh missing"; echo "PASS=0 FAIL=1"; exit 1
fi
bash "${ROOT}/build/build.sh" >/dev/null 2>&1 || { echo "FAIL: build.sh did not run cleanly"; echo "PASS=0 FAIL=1"; exit 1; }

for agent in codex hermes; do
  base="${ROOT}/dist/${agent}"
  if diff -q "${ROOT}/SKILL.md" "${base}/skills/rookie-work/SKILL.md" >/dev/null 2>&1; then ok "${agent}: SKILL.md == canonical"; else bad "${agent}: SKILL.md == canonical"; fi
  if diff -q "${ROOT}/SESSION-PREAMBLE.md" "${base}/SESSION-PREAMBLE.md" >/dev/null 2>&1; then ok "${agent}: SESSION-PREAMBLE.md == canonical"; else bad "${agent}: SESSION-PREAMBLE.md == canonical"; fi
  if diff -q "${ROOT}/PROMPT-GATE.md" "${base}/PROMPT-GATE.md" >/dev/null 2>&1; then ok "${agent}: PROMPT-GATE.md == canonical"; else bad "${agent}: PROMPT-GATE.md == canonical"; fi
  canon_md="$(cd "${ROOT}/references" && ls *.md 2>/dev/null | sort)"
  dist_md="$( ([ -d "${base}/skills/rookie-work/references" ] && cd "${base}/skills/rookie-work/references" && ls 2>/dev/null | sort) || true )"
  if [ -n "$canon_md" ] && [ "$canon_md" = "$dist_md" ]; then ok "${agent}: refs set == canonical *.md (no strays)"; else bad "${agent}: refs set == canonical *.md (no strays)"; fi
  rc=1; for r in $canon_md; do diff -q "${ROOT}/references/${r}" "${base}/skills/rookie-work/references/${r}" >/dev/null 2>&1 || rc=0; done
  [ "$rc" = 1 ] && ok "${agent}: refs content == canonical" || bad "${agent}: refs content == canonical"
  dp="${base}/skills/rookie-work/references/decision-protocol.md"
  if [ -f "$dp" ]; then ok "${agent}: decision protocol present"; else bad "${agent}: decision protocol present"; fi
  if grep -qF "Only explicit answers count" "$dp" 2>/dev/null; then ok "${agent}: decision protocol content present"; else bad "${agent}: decision protocol content present"; fi
done

if [ -f "${ROOT}/dist/README.md" ] && grep -q "DO NOT EDIT" "${ROOT}/dist/README.md"; then ok "dist/README.md generated-marker"; else bad "dist/README.md generated-marker"; fi

# --- Codex-specific generated files ---
cm="${ROOT}/dist/codex/.codex-plugin/plugin.json"
if python3 -c "import json,sys;m=json.load(open('${cm}'));sys.exit(0 if m.get('name')=='rookie-work' and m.get('skills')=='./skills/' else 1)" 2>/dev/null; then ok "codex: plugin.json valid (name+skills)"; else bad "codex: plugin.json valid (name+skills)"; fi
ccv="$(python3 -c "import json;print(json.load(open('${ROOT}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)"
cxv="$(python3 -c "import json;print(json.load(open('${cm}'))['version'])" 2>/dev/null)"
if [ -n "$cxv" ] && [ "$ccv" = "$cxv" ]; then ok "codex: version matches CC ($ccv)"; else bad "codex: version matches CC (cc=$ccv codex=$cxv)"; fi
for f in hooks/hooks.json hooks/session-start hooks/user-prompt-submit hooks/run-hook.cmd; do
  if [ -f "${ROOT}/dist/codex/${f}" ]; then ok "codex: ${f} present"; else bad "codex: ${f} present"; fi
done

# Validate the declared integration, not just the presence of hook files.
codex_hooks="${ROOT}/dist/codex/hooks/hooks.json"
if python3 -c 'import json,sys; h=json.load(open(sys.argv[1]))["hooks"]; assert set(h)=={"SessionStart","UserPromptSubmit"}' "$codex_hooks" 2>/dev/null; then
  ok "codex: hooks.json declares exactly both required events"
else
  bad "codex: hooks.json declares exactly both required events"
fi
if python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["hooks"]["SessionStart"][0]; c=x["hooks"][0]; assert x["matcher"]=="startup|resume|clear|compact" and c=={"type":"command","command":"\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start","async":False}' "$codex_hooks" 2>/dev/null; then
  ok "codex: SessionStart declaration targets generated wrapper"
else
  bad "codex: SessionStart declaration targets generated wrapper"
fi
if python3 -c 'import json,sys; x=json.load(open(sys.argv[1]))["hooks"]["UserPromptSubmit"][0]; c=x["hooks"][0]; assert "matcher" not in x and c=={"type":"command","command":"\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" user-prompt-submit","async":False}' "$codex_hooks" 2>/dev/null; then
  ok "codex: UserPromptSubmit declaration targets generated wrapper"
else
  bad "codex: UserPromptSubmit declaration targets generated wrapper"
fi

# Execute the generated package from a temporary installed layout through the
# same wrapper named by hooks.json. This catches packaging/path drift.
CX_TMP="$(mktemp -d)"
mkdir -p "${CX_TMP}/home" "${CX_TMP}/project"
cp -R "${ROOT}/dist/codex" "${CX_TMP}/plugin"
run_generated_codex_hook(){
  hook_name="$1"
  ( cd "${CX_TMP}/project" && HOME="${CX_TMP}/home" \
      CLAUDE_PLUGIN_ROOT="${CX_TMP}/plugin" CODEX_PROJECT_DIR="${CX_TMP}/project" \
      bash "${CX_TMP}/plugin/hooks/run-hook.cmd" "$hook_name" <<<'{}' )
}
cx_session="$(run_generated_codex_hook session-start 2>/dev/null || true)"
if printf '%s' "$cx_session" | python3 -m json.tool >/dev/null 2>&1 && \
   printf '%s' "$cx_session" | grep -qF 'SessionStart' && \
   printf '%s' "$cx_session" | grep -qF 'Explain before you act'; then
  ok "codex: generated SessionStart executes with canonical context"
else
  bad "codex: generated SessionStart executes with canonical context"
fi
cx_prompt="$(run_generated_codex_hook user-prompt-submit 2>/dev/null || true)"
if printf '%s' "$cx_prompt" | python3 -m json.tool >/dev/null 2>&1 && \
   printf '%s' "$cx_prompt" | grep -qF 'UserPromptSubmit' && \
   printf '%s' "$cx_prompt" | grep -qF 'Current prompt state'; then
  ok "codex: generated UserPromptSubmit executes with canonical gate"
else
  bad "codex: generated UserPromptSubmit executes with canonical gate"
fi
rm -rf "$CX_TMP"

# The supported Codex setup is the plugin-bundled hook plus Codex's trust
# review. Keep both languages aligned and prevent the old version-pinned,
# hand-written hooks.json path from returning.
check_codex_install_docs(){
  label="$1"; doc="$2"; trust_word="$3"; update_word="$4"; remove_word="$5"
  section="$(awk '/^### Codex/{inside=1} /^### Hermes/{inside=0} inside' "$doc")"
  for marker in '`/hooks`' 'SessionStart' 'UserPromptSubmit' "$trust_word" "$update_word" "$remove_word"; do
    if printf '%s' "$section" | grep -qF "$marker"; then
      ok "${label}: Codex setup mentions ${marker}"
    else
      bad "${label}: Codex setup mentions ${marker}"
    fi
  done
  if printf '%s' "$section" | grep -qF 'CLAUDE_PLUGIN_ROOT'; then
    bad "${label}: Codex setup avoids hand-written hook command"
  else
    ok "${label}: Codex setup avoids hand-written hook command"
  fi
  if printf '%s' "$section" | grep -qF '<version>'; then
    bad "${label}: Codex setup avoids version-pinned path"
  else
    ok "${label}: Codex setup avoids version-pinned path"
  fi
}

check_codex_install_docs "README" "${ROOT}/README.md" "trust" "update" "remove"
check_codex_install_docs "README.zh-CN" "${ROOT}/README.zh-CN.md" "信任" "升级" "删除"

# --- Codex marketplace manifest (static, repo-root; for `codex plugin marketplace add owner/repo`) ---
mkt="${ROOT}/.agents/plugins/marketplace.json"
if [ -f "$mkt" ]; then ok "codex: marketplace.json present"; else bad "codex: marketplace.json present"; fi
if python3 -c "import json,sys;m=json.load(open('${mkt}'));p=m['plugins'][0];s=p['source'];sys.exit(0 if m.get('name')=='rookie-work-marketplace' and p.get('name')=='rookie-work' and s.get('source')=='git-subdir' and s.get('path')=='./dist/codex' else 1)" 2>/dev/null; then ok "codex: marketplace.json valid (name+plugin+git-subdir source)"; else bad "codex: marketplace.json valid (name+plugin+git-subdir source)"; fi

# --- .gitattributes LF guard (a Windows clone must not CRLF-corrupt the hook scripts) ---
if [ -f "${ROOT}/.gitattributes" ] && grep -Eq 'eol=lf' "${ROOT}/.gitattributes"; then ok ".gitattributes enforces eol=lf"; else bad ".gitattributes enforces eol=lf"; fi

# --- Hermes-specific generated files ---
hh="${ROOT}/dist/hermes/agent-hooks/rookie-work-inject.sh"
if [ -x "$hh" ]; then ok "hermes: inject.sh present+exec"; else bad "hermes: inject.sh present+exec"; fi
if diff -q "${ROOT}/SESSION-PREAMBLE.md" "${ROOT}/dist/hermes/agent-hooks/SESSION-PREAMBLE.md" >/dev/null 2>&1; then ok "hermes: co-located preamble == canonical"; else bad "hermes: co-located preamble == canonical"; fi
if diff -q "${ROOT}/PROMPT-GATE.md" "${ROOT}/dist/hermes/agent-hooks/PROMPT-GATE.md" >/dev/null 2>&1; then ok "hermes: co-located prompt gate == canonical"; else bad "hermes: co-located prompt gate == canonical"; fi
if [ -f "${ROOT}/dist/hermes/config-snippet.yaml" ]; then ok "hermes: config-snippet.yaml present"; else bad "hermes: config-snippet.yaml present"; fi
if [ -f "${ROOT}/dist/hermes/INSTALL.md" ]; then ok "hermes: INSTALL.md present"; else bad "hermes: INSTALL.md present"; fi

# Follow each published Hermes copy command in an isolated home, then run the
# installed hook on a later turn. This catches install docs that omit a runtime
# dependency even when the package itself contains the file.
smoke_hermes_install_doc(){
  label="$1"; doc="$2"; source_root="$3"
  tmp="$(mktemp -d)"
  mkdir -p "${tmp}/home/.hermes/agent-hooks" "${tmp}/project"
  line="$(grep -E '^[[:space:]]*cp .*SESSION-PREAMBLE\.md .*~/\.hermes/agent-hooks/' "$doc" | head -n 1)"
  if [ -z "$line" ]; then
    bad "${label}: Hermes hook copy command found"
    rm -rf "$tmp"
    return
  fi
  set -- $line
  shift
  for source in "$@"; do
    [ "$source" = '~/.hermes/agent-hooks/' ] && break
    cp "${source_root}/${source}" "${tmp}/home/.hermes/agent-hooks/" 2>/dev/null || true
  done
  chmod +x "${tmp}/home/.hermes/agent-hooks/rookie-work-inject.sh" 2>/dev/null || true
  out="$(cd "${tmp}/project" && HOME="${tmp}/home" \
    bash "${tmp}/home/.hermes/agent-hooks/rookie-work-inject.sh" \
    <<<'{"extra":{"is_first_turn":false}}' 2>/dev/null || true)"
  if printf '%s' "$out" | grep -qF 'Current prompt state' && \
     ! printf '%s' "$out" | grep -qF 'PROMPT-GATE.md is missing'; then
    ok "${label}: documented Hermes install loads later-turn gate"
  else
    bad "${label}: documented Hermes install loads later-turn gate"
  fi
  rm -rf "$tmp"
}

smoke_hermes_install_doc "dist INSTALL" "${ROOT}/dist/hermes/INSTALL.md" "${ROOT}/dist/hermes"
smoke_hermes_install_doc "README" "${ROOT}/README.md" "${ROOT}"
smoke_hermes_install_doc "README.zh-CN" "${ROOT}/README.zh-CN.md" "${ROOT}"

# Determinism: snapshot, rebuild, compare contents
T1="$(mktemp -d)"; cp -R "${ROOT}/dist" "${T1}/dist1"
bash "${ROOT}/build/build.sh" >/dev/null 2>&1
if diff -rq "${T1}/dist1" "${ROOT}/dist" >/dev/null 2>&1; then ok "deterministic (rebuild identical)"; else bad "deterministic (rebuild identical)"; fi
rm -rf "$T1"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
