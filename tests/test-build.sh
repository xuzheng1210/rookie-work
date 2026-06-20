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
  canon_md="$(cd "${ROOT}/references" && ls *.md 2>/dev/null | sort)"
  dist_md="$( ([ -d "${base}/skills/rookie-work/references" ] && cd "${base}/skills/rookie-work/references" && ls 2>/dev/null | sort) || true )"
  if [ -n "$canon_md" ] && [ "$canon_md" = "$dist_md" ]; then ok "${agent}: refs set == canonical *.md (no strays)"; else bad "${agent}: refs set == canonical *.md (no strays)"; fi
  rc=1; for r in $canon_md; do diff -q "${ROOT}/references/${r}" "${base}/skills/rookie-work/references/${r}" >/dev/null 2>&1 || rc=0; done
  [ "$rc" = 1 ] && ok "${agent}: refs content == canonical" || bad "${agent}: refs content == canonical"
done

if [ -f "${ROOT}/dist/README.md" ] && grep -q "DO NOT EDIT" "${ROOT}/dist/README.md"; then ok "dist/README.md generated-marker"; else bad "dist/README.md generated-marker"; fi

# --- Codex-specific generated files ---
cm="${ROOT}/dist/codex/.codex-plugin/plugin.json"
if python3 -c "import json,sys;m=json.load(open('${cm}'));sys.exit(0 if m.get('name')=='rookie-work' and m.get('skills')=='./skills/' else 1)" 2>/dev/null; then ok "codex: plugin.json valid (name+skills)"; else bad "codex: plugin.json valid (name+skills)"; fi
ccv="$(python3 -c "import json;print(json.load(open('${ROOT}/.claude-plugin/plugin.json'))['version'])" 2>/dev/null)"
cxv="$(python3 -c "import json;print(json.load(open('${cm}'))['version'])" 2>/dev/null)"
if [ -n "$cxv" ] && [ "$ccv" = "$cxv" ]; then ok "codex: version matches CC ($ccv)"; else bad "codex: version matches CC (cc=$ccv codex=$cxv)"; fi
for f in hooks/hooks.json hooks/session-start hooks/run-hook.cmd; do
  if [ -f "${ROOT}/dist/codex/${f}" ]; then ok "codex: ${f} present"; else bad "codex: ${f} present"; fi
done

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
if [ -f "${ROOT}/dist/hermes/config-snippet.yaml" ]; then ok "hermes: config-snippet.yaml present"; else bad "hermes: config-snippet.yaml present"; fi
if [ -f "${ROOT}/dist/hermes/INSTALL.md" ]; then ok "hermes: INSTALL.md present"; else bad "hermes: INSTALL.md present"; fi

# Determinism: snapshot, rebuild, compare contents
T1="$(mktemp -d)"; cp -R "${ROOT}/dist" "${T1}/dist1"
bash "${ROOT}/build/build.sh" >/dev/null 2>&1
if diff -rq "${T1}/dist1" "${ROOT}/dist" >/dev/null 2>&1; then ok "deterministic (rebuild identical)"; else bad "deterministic (rebuild identical)"; fi
rm -rf "$T1"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
