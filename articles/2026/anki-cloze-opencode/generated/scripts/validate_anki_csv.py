#!/usr/bin/env python3
"""Validate a one-note-per-row Anki cloze CSV.

Usage:
    python scripts/validate_anki_csv.py decks/regex/simple-patterns_revised.csv

The output is JSON so an orchestrator agent can read the result directly.
Exit code 0 means no structural errors; warnings do not fail validation.
"""

from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

CLOZE_RE = re.compile(r"\{\{c(\d+)::(.*?)\}\}", re.S)


def validate(path: Path) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    stats = {"notes": 0, "cards": 0, "blanks": 0}
    seen_notes: dict[str, int] = {}

    try:
        with path.open(encoding="utf-8-sig", newline="") as f:
            rows = list(csv.reader(f))
    except (UnicodeDecodeError, csv.Error) as exc:
        return {
            "ok": False,
            "file": str(path),
            "errors": [f"could not read CSV: {exc}"],
            "warnings": [],
            "stats": stats,
        }

    for row_number, row in enumerate(rows, 1):
        # A blank line is not a note. Do not count it in the statistics.
        if not row or all(not cell.strip() for cell in row):
            continue

        if len(row) != 1:
            errors.append(
                f"note {row_number}: expected exactly 1 CSV field, got {len(row)}"
            )
            continue

        text = row[0]
        if not text.strip():
            errors.append(f"note {row_number}: empty note")
            continue

        stats["notes"] += 1

        if text.count("{{") != text.count("}}"):
            errors.append(f"note {row_number}: unbalanced cloze braces")

        matches = CLOZE_RE.findall(text)
        if not matches:
            errors.append(f"note {row_number}: no cloze found")
            continue

        ids = sorted({int(cid) for cid, _ in matches})
        expected_ids = list(range(1, max(ids) + 1))
        if ids != expected_ids:
            errors.append(
                f"note {row_number}: cloze ids are not contiguous: {ids}"
            )

        for cid, raw in matches:
            answer, separator, hint = raw.partition("::")
            if not answer.strip():
                errors.append(f"note {row_number}: c{cid} has an empty answer")
            if "{{" in raw or "}}" in raw:
                errors.append(f"note {row_number}: c{cid} contains a nested cloze")
            if separator:
                if not hint.strip():
                    warnings.append(f"note {row_number}: c{cid} has an empty hint")
                elif "::" in hint:
                    warnings.append(
                        f"note {row_number}: c{cid} hint contains another '::'"
                    )

        if text in seen_notes:
            warnings.append(
                f"note {row_number}: exact duplicate of note {seen_notes[text]}"
            )
        else:
            seen_notes[text] = row_number

        stats["cards"] += len(ids)
        stats["blanks"] += len(matches)

    if stats["notes"] == 0:
        errors.append("CSV contains no notes")

    return {
        "ok": not errors,
        "file": str(path),
        "errors": errors,
        "warnings": warnings,
        "stats": stats,
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(
            "usage: python scripts/validate_anki_csv.py <file.csv>",
            file=sys.stderr,
        )
        return 2

    path = Path(sys.argv[1])
    if not path.is_file():
        print(
            json.dumps(
                {"ok": False, "errors": [f"file not found: {path}"]},
                ensure_ascii=False,
                indent=2,
            )
        )
        return 1

    result = validate(path)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
