#!/usr/bin/env bash
# Behavior tests for the rookie-work SessionStart hook script.
# Runs hooks/session-start in an ISOLATED env (temp HOME + temp project dir)
# so it never touches the real ~/.rookie-work-off.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${REPO_ROOT}/hooks/session-start"
PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/home" "$TMP/proj"

run_hook() {
  ( cd "$TMP/proj" && HOME="$TMP/home" CLAUDE_PLUGIN_ROOT="$REPO_ROOT" \
      CLAUDE_PROJECT_DIR="$TMP/proj" bash "$SCRIPT" </dev/null )
}

# 1) Default (no off-marker)
OUT="$(run_hook)"
if printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1; then ok "default: valid JSON"; else bad "default: valid JSON"; fi
if printf '%s' "$OUT" | grep -q "hookSpecificOutput"; then ok "default: uses hookSpecificOutput"; else bad "default: uses hookSpecificOutput"; fi
if printf '%s' "$OUT" | grep -q "Explain before you act"; then ok "default: injects discipline"; else bad "default: injects discipline"; fi
if printf '%s' "$OUT" | grep -q "build the framework"; then ok "default: injects framing trigger"; else bad "default: injects framing trigger"; fi
for marker in \
  "First-response gate" \
  "Before any inspection, plan, tool call, or sub-agent" \
  "A real choice makes Tier 1 become Tier 2" \
  "choose the decision pace" \
  "Silence, omissions, or ambiguity are not approval"; do
  if printf '%s' "$OUT" | grep -qF "$marker"; then ok "default: injects $marker"; else bad "default: injects $marker"; fi
done

# 2) Global off-marker
touch "$TMP/home/.rookie-work-off"
OUT="$(run_hook)"
if printf '%s' "$OUT" | grep -q "currently OFF"; then ok "global off: shows OFF notice"; else bad "global off: shows OFF notice"; fi
if printf '%s' "$OUT" | grep -q "Explain before you act"; then bad "global off: suppresses discipline"; else ok "global off: suppresses discipline"; fi
if printf '%s' "$OUT" | grep -qF "choose the decision pace"; then bad "global off: suppresses decision pace"; else ok "global off: suppresses decision pace"; fi
rm -f "$TMP/home/.rookie-work-off"

# 3) Project off-marker
touch "$TMP/proj/.rookie-work-off"
OUT="$(run_hook)"
if printf '%s' "$OUT" | grep -q "currently OFF"; then ok "project off: shows OFF notice"; else bad "project off: shows OFF notice"; fi
if printf '%s' "$OUT" | grep -q "Explain before you act"; then bad "project off: suppresses discipline"; else ok "project off: suppresses discipline"; fi
if printf '%s' "$OUT" | grep -qF "choose the decision pace"; then bad "project off: suppresses decision pace"; else ok "project off: suppresses decision pace"; fi
rm -f "$TMP/proj/.rookie-work-off"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
