#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROTOCOL="${ROOT}/references/decision-protocol.md"
SCENARIOS="${ROOT}/tests/fixtures/decision-protocol-scenarios.md"
CONTRACT="${ROOT}/tests/fixtures/decision-protocol-contract.json"
VERIFY_CONTRACT="${ROOT}/tests/verify-decision-protocol-contract.py"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

for f in "$PROTOCOL" "$SCENARIOS" "$CONTRACT" "$VERIFY_CONTRACT"; do
  if [ -f "$f" ]; then ok "exists: ${f#${ROOT}/}"; else bad "exists: ${f#${ROOT}/}"; fi
done

for marker in \
  "What counts as a real choice" \
  "First-response gate" \
  "Per-prompt reminder" \
  "Choose the decision pace" \
  "Only explicit answers count" \
  "Conflicts, safety, and feasibility" \
  "Recovery and incomplete context" \
  "Completion states" \
  "Examples are explanatory, not exhaustive"; do
  if grep -qF "$marker" "$PROTOCOL" 2>/dev/null; then ok "protocol marker: $marker"; else bad "protocol marker: $marker"; fi
done

for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16; do
  if grep -qF "DP-${n}P" "$SCENARIOS" 2>/dev/null; then ok "positive scenario DP-${n}P"; else bad "positive scenario DP-${n}P"; fi
  if grep -qF "DP-${n}N" "$SCENARIOS" 2>/dev/null; then ok "negative scenario DP-${n}N"; else bad "negative scenario DP-${n}N"; fi
done

for marker in "Must do" "Must not do" "Layer"; do
  if grep -qF "$marker" "$SCENARIOS" 2>/dev/null; then ok "scenario field: $marker"; else bad "scenario field: $marker"; fi
done

if python3 "$VERIFY_CONTRACT" "$SCENARIOS" "$CONTRACT" >/dev/null; then
  ok "all 32 scenarios match their semantic contracts"
else
  bad "all 32 scenarios match their semantic contracts"
fi

# Prove the verifier rejects a semantic regression instead of only counting
# IDs and headings.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
sed 's/Stop and upgrade to Tier 2 before editing/Ignore the user-visible choice/' \
  "$SCENARIOS" > "${TMP}/mutated-scenarios.md"
if python3 "$VERIFY_CONTRACT" "${TMP}/mutated-scenarios.md" "$CONTRACT" >/dev/null 2>&1; then
  bad "semantic verifier rejects a changed requirement"
else
  ok "semantic verifier rejects a changed requirement"
fi

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
