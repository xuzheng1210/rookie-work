#!/usr/bin/env bash
# rookie-work pre_llm_call hook for Hermes: inject the full preamble on the
# first turn and a short shared gate on every turn, unless rookie-work is off.
# Reads the Hermes event payload (JSON) on stdin; emits {"context": ...} or {}.
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

# Off-switch: global or project marker -> no-op.
if [ -f "${HOME}/.rookie-work-off" ] || [ -f "${PWD}/.rookie-work-off" ]; then
  printf '{}\n'; exit 0
fi

# On a parse problem, fall back to the short gate rather than repeating the full preamble.
is_first="$(printf '%s' "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('true' if d.get('extra',{}).get('is_first_turn') else 'false')" 2>/dev/null || echo false)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATE="$(cat "${SCRIPT_DIR}/PROMPT-GATE.md" 2>/dev/null || echo "rookie-work prompt gate is active, but PROMPT-GATE.md is missing.")"
if [ "$is_first" = "true" ]; then
  PREAMBLE="$(cat "${SCRIPT_DIR}/SESSION-PREAMBLE.md" 2>/dev/null || echo "rookie-work is active, but its preamble file is missing.")"
  CONTEXT="${PREAMBLE}

${GATE}"
else
  CONTEXT="$GATE"
fi

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
printf '{\n  "context": "%s"\n}\n' "$(escape_for_json "$CONTEXT")"
exit 0
