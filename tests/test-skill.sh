#!/usr/bin/env bash
# Structural tests for the rookie-work SKILL.md (single-skill plugin at repo root).
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${REPO_ROOT}/SKILL.md"
PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
bad(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

if [ -f "$SKILL" ]; then ok "SKILL.md exists at plugin root"; else bad "SKILL.md exists at plugin root"; echo "PASS=$PASS FAIL=$FAIL"; exit 1; fi
if [ "$(head -1 "$SKILL")" = "---" ]; then ok "starts with YAML frontmatter"; else bad "starts with YAML frontmatter"; fi

# Extract frontmatter (between the first two '---' lines)
FM="$(awk 'NR==1&&/^---/{f=1;next} /^---/{if(f)exit} f{print}' "$SKILL")"

if printf '%s\n' "$FM" | grep -Eq '^name:[[:space:]]*rookie-work[[:space:]]*$'; then ok "frontmatter name is rookie-work"; else bad "frontmatter name is rookie-work"; fi

DESC="$(printf '%s\n' "$FM" | sed -n 's/^description:[[:space:]]*//p')"
if [ -n "$DESC" ]; then ok "frontmatter has description"; else bad "frontmatter has description"; fi
LEN=${#DESC}
if [ "$LEN" -gt 0 ] && [ "$LEN" -le 1536 ]; then ok "description length ${LEN} within 1536"; else bad "description length ${LEN} within 1536"; fi

# Required body sections (dash-free substrings, to avoid em-dash matching issues)
for m in "Which tier is this task" "the light flow" "the full method" "Disclose before you modify" "Record every change" "Turning rookie-work off and on" "Frame the work" "boundary checklist" "First-response gate" "Do not inspect first" "Per-prompt gate" "Real-choice protocol" "Choose the decision pace" "Only explicit answers count"; do
  if grep -qF "$m" "$SKILL"; then ok "section present: $m"; else bad "section present: $m"; fi
done

# Reference files exist
for ref in \
  "references/changelog-format.md" \
  "references/model-and-review-policy.md" \
  "references/framing-and-boundaries.md" \
  "references/decision-protocol.md"; do
  if [ -f "${REPO_ROOT}/${ref}" ]; then ok "ref exists: $ref"; else bad "ref exists: $ref"; fi
done

# Framing reference content (boundary checklist + portable template)
FB="${REPO_ROOT}/references/framing-and-boundaries.md"
for m in "Scope & non-goals" "Definition of done" "turn it into a development framework" "decision-protocol.md" "choose the decision pace"; do
  if grep -qF "$m" "$FB" 2>/dev/null; then ok "framing ref has: $m"; else bad "framing ref has: $m"; fi
done

DP="${REPO_ROOT}/references/decision-protocol.md"
for m in "What counts as a real choice" "Choose the decision pace" "Only explicit answers count"; do
  if grep -qF "$m" "$DP" 2>/dev/null; then ok "decision protocol has: $m"; else bad "decision protocol has: $m"; fi
done

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
