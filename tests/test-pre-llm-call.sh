#!/usr/bin/env bash
# Tests the Hermes pre_llm_call hook source: first-turn injection, non-first no-op, off-switch.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/build/templates/hermes/rookie-work-inject.sh"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ ! -f "$SRC" ]; then echo "FAIL: hook source missing"; echo "PASS=0 FAIL=1"; exit 1; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/ah" "$TMP/home" "$TMP/proj"
cp "$SRC" "$TMP/ah/rookie-work-inject.sh"; chmod +x "$TMP/ah/rookie-work-inject.sh"
cp "${ROOT}/SESSION-PREAMBLE.md" "$TMP/ah/SESSION-PREAMBLE.md"   # co-located, as build does
run(){ ( cd "$TMP/proj" && HOME="$TMP/home" bash "$TMP/ah/rookie-work-inject.sh" <<<"$1" ); }
FIRST='{"extra":{"is_first_turn":true}}'
NOTFIRST='{"extra":{"is_first_turn":false}}'

OUT="$(run "$FIRST")"
printf '%s' "$OUT" | python3 -m json.tool >/dev/null 2>&1 && ok "first: valid JSON" || bad "first: valid JSON"
printf '%s' "$OUT" | grep -q '"context"' && ok "first: has context" || bad "first: has context"
printf '%s' "$OUT" | grep -q "Explain before you act" && ok "first: injects preamble" || bad "first: injects preamble"
printf '%s' "$OUT" | grep -qF "choose the decision pace" && ok "first: injects decision pace" || bad "first: injects decision pace"
printf '%s' "$OUT" | grep -qF "Silence, omissions, or ambiguity are not approval" && ok "first: rejects implicit approval" || bad "first: rejects implicit approval"

OUT="$(run "$NOTFIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "non-first: no injection" || ok "non-first: no injection"

touch "$TMP/home/.rookie-work-off"; OUT="$(run "$FIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "global off: suppressed" || ok "global off: suppressed"
printf '%s' "$OUT" | grep -qF "choose the decision pace" && bad "global off: suppresses decision pace" || ok "global off: suppresses decision pace"
rm -f "$TMP/home/.rookie-work-off"

touch "$TMP/proj/.rookie-work-off"; OUT="$(run "$FIRST")"
printf '%s' "$OUT" | grep -q "Explain before you act" && bad "project off: suppressed" || ok "project off: suppressed"
printf '%s' "$OUT" | grep -qF "choose the decision pace" && bad "project off: suppresses decision pace" || ok "project off: suppresses decision pace"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
