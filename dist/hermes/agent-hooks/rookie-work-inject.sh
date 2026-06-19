#!/usr/bin/env bash
# rookie-work pre_llm_call hook for Hermes: inject the discipline preamble once,
# at the first turn of a session, unless an off-switch marker is present.
# Reads the Hermes event payload (JSON) on stdin; emits {"context": ...} or {}.
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

# Off-switch: global or project marker -> no-op.
if [ -f "${HOME}/.rookie-work-off" ] || [ -f "${PWD}/.rookie-work-off" ]; then
  printf '{}\n'; exit 0
fi

# pre_llm_call fires every turn; only inject on the first turn (payload extra.is_first_turn).
# Fail safe: on any parse problem, treat as NOT first turn (don't inject) rather than spam.
is_first="$(printf '%s' "$INPUT" | python3 -c "import sys,json;d=json.load(sys.stdin);print('true' if d.get('extra',{}).get('is_first_turn') else 'false')" 2>/dev/null || echo false)"
if [ "$is_first" != "true" ]; then
  printf '{}\n'; exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREAMBLE="$(cat "${SCRIPT_DIR}/SESSION-PREAMBLE.md" 2>/dev/null || echo "rookie-work is active, but its preamble file is missing.")"

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
printf '{\n  "context": "%s"\n}\n' "$(escape_for_json "$PREAMBLE")"
exit 0
