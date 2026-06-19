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
  for r in changelog-format model-and-review-policy; do
    if diff -q "${ROOT}/references/${r}.md" "${base}/skills/rookie-work/references/${r}.md" >/dev/null 2>&1; then ok "${agent}: ref ${r} == canonical"; else bad "${agent}: ref ${r} == canonical"; fi
  done
done

if [ -f "${ROOT}/dist/README.md" ] && grep -q "DO NOT EDIT" "${ROOT}/dist/README.md"; then ok "dist/README.md generated-marker"; else bad "dist/README.md generated-marker"; fi

# Determinism: snapshot, rebuild, compare contents
T1="$(mktemp -d)"; cp -R "${ROOT}/dist" "${T1}/dist1"
bash "${ROOT}/build/build.sh" >/dev/null 2>&1
if diff -rq "${T1}/dist1" "${ROOT}/dist" >/dev/null 2>&1; then ok "deterministic (rebuild identical)"; else bad "deterministic (rebuild identical)"; fi
rm -rf "$T1"

echo "----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
