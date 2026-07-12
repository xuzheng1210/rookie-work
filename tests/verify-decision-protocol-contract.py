#!/usr/bin/env python3
"""Verify every decision scenario against its test-owned semantic contract."""

import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"CONTRACT ERROR: {message}", file=sys.stderr)


def main() -> int:
    if len(sys.argv) != 3:
        fail("usage: verify-decision-protocol-contract.py SCENARIOS CONTRACT")
        return 2

    scenario_path = Path(sys.argv[1])
    contract_path = Path(sys.argv[2])
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    scenarios: dict[str, dict[str, str]] = {}
    errors = 0

    for line_number, line in enumerate(
        scenario_path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not re.match(r"^\| DP-\d{2}[PN] \|", line):
            continue
        parts = [part.strip() for part in line.split("|")[1:-1]]
        if len(parts) != 5:
            fail(f"line {line_number}: expected five table fields")
            errors += 1
            continue
        scenario_id, _situation, must_do, must_not, layer = parts
        if scenario_id in scenarios:
            fail(f"duplicate scenario {scenario_id}")
            errors += 1
            continue
        scenarios[scenario_id] = {
            "layer": layer,
            "must_do": must_do,
            "must_not": must_not,
        }

    expected_ids = {
        f"DP-{number:02d}{kind}"
        for number in range(1, 17)
        for kind in ("P", "N")
    }
    for label, actual_ids in (
        ("scenario catalog", set(scenarios)),
        ("semantic contract", set(contract)),
    ):
        missing = sorted(expected_ids - actual_ids)
        extra = sorted(actual_ids - expected_ids)
        if missing or extra:
            fail(f"{label}: missing={missing} extra={extra}")
            errors += 1

    for scenario_id in sorted(expected_ids & set(scenarios) & set(contract)):
        for field in ("layer", "must_do", "must_not"):
            expected = contract[scenario_id].get(field)
            actual = scenarios[scenario_id][field]
            if actual != expected:
                fail(
                    f"{scenario_id} {field}: expected {expected!r}, got {actual!r}"
                )
                errors += 1

    if errors:
        return 1
    print(f"verified {len(expected_ids)} scenario semantic contracts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
