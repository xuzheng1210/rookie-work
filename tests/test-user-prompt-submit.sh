#!/usr/bin/env bash
# Behavior tests for the per-prompt rookie-work gate used by Claude Code/Codex.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${ROOT}/hooks/user-prompt-submit"
GATE="${ROOT}/PROMPT-GATE.md"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

[ -f "$SCRIPT" ] && ok "hook script exists" || bad "hook script exists"
[ -f "$GATE" ] && ok "prompt gate exists" || bad "prompt gate exists"
GATE_WORDS="$(wc -w < "$GATE" | tr -d '[:space:]')"
if [ "$GATE_WORDS" -le 120 ]; then
  ok "prompt gate budget: ${GATE_WORDS}/120 words"
else
  bad "prompt gate budget: ${GATE_WORDS}/120 words"
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home" "$TMP/proj"
run_hook(){
  ( cd "$TMP/proj" && HOME="$TMP/home" CLAUDE_PLUGIN_ROOT="$ROOT" \
      CLAUDE_PROJECT_DIR="$TMP/proj" bash "$SCRIPT" <<<'{"hook_event_name":"UserPromptSubmit","prompt":"choose the best behavior"}' )
}

OUT="$(run_hook 2>/dev/null || true)"
printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1 && ok "default: valid JSON" || bad "default: valid JSON"
printf '%s' "$OUT" | grep -qF 'UserPromptSubmit' && ok "default: event name" || bad "default: event name"
printf '%s' "$OUT" | grep -qF 'Current prompt state' && ok "default: injects current state" || bad "default: injects current state"
printf '%s' "$OUT" | grep -qF 'Do not inspect first' && ok "default: injects no-inspection gate" || bad "default: injects no-inspection gate"
printf '%s' "$OUT" | grep -qF 'keep using it without asking again' && ok "default: preserves chosen pace" || bad "default: preserves chosen pace"

touch "$TMP/home/.rookie-work-off"; OUT="$(run_hook 2>/dev/null || true)"
printf '%s' "$OUT" | grep -qF 'Current prompt state' && bad "global off: suppresses prompt gate" || ok "global off: suppresses prompt gate"
rm -f "$TMP/home/.rookie-work-off"

touch "$TMP/proj/.rookie-work-off"; OUT="$(run_hook 2>/dev/null || true)"
printf '%s' "$OUT" | grep -qF 'Current prompt state' && bad "project off: suppresses prompt gate" || ok "project off: suppresses prompt gate"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
