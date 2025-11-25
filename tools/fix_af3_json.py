#!/usr/bin/env python3
"""
Fix and reorder AlphaFold3 JSON-like input files.

Usage:
    python fix_af3_json.py input.json

This will create: input_modified.json
"""

import json
import sys
import ast
from pathlib import Path
import re

DESIRED_ORDER = [
    "name",
    "modelSeeds",
    "sequences",
    "bondedAtomPairs",
    "userCCD",
    "userCCDPath",
    "dialect",
    "version",
]


def read_and_preprocess_json_text(path: Path) -> str:
    """
    Read file and try to remove common non-JSON artifacts (comments, trailing commas).
    This is only used for JSON-like text, not for Python-literal parsing.
    """
    text = path.read_text(encoding="utf-8")

    # Remove full-line comments starting with // or #
    text = re.sub(r"(?m)^\s*(//|#).*?$", "", text)

    # Remove trailing commas before } or ]
    text = re.sub(r",(\s*[}\]])", r"\1", text)

    return text

def load_object(path: Path):
    """
    Try to load data from file in the following order:
    1) Strict JSON
    2) Python literal (ast.literal_eval) – handles single quotes etc.
    3) Preprocessed JSON (remove comments, trailing commas) then json.loads
    """
    raw = path.read_text(encoding="utf-8")

    # 1) Try strict JSON first
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        pass

    # 2) Try Python literal syntax (your example case)
    try:
        obj = ast.literal_eval(raw)
        return obj
    except (SyntaxError, ValueError):
        pass

    # 3) Try cleaning and re-parsing as JSON
    cleaned = read_and_preprocess_json_text(path)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse file as JSON or Python literal: {e}") from e


def reorder_top_level(data: dict) -> dict:
    """Reorder top-level keys according to DESIRED_ORDER; keep extra keys at the end."""
    new_data = {}

    # Put desired keys first, if present
    for key in DESIRED_ORDER:
        if key in data:
            new_data[key] = data[key]

    # Append any remaining keys in their original order
    for key in data:
        if key not in new_data:
            new_data[key] = data[key]

    return new_data

def sort_nested(obj, is_top_level: bool = False):
    """
    Recursively sort dict keys for better readability.
    - Top level: use DESIRED_ORDER (via reorder_top_level).
    - Nested dicts: keys sorted alphabetically.
    - Lists: elements are recursively processed, but order is kept.
    """
    if isinstance(obj, dict):
        if is_top_level:
            obj = reorder_top_level(obj)
            keys = list(obj.keys())  # keep DESIRED_ORDER + original order for extras
        else:
            keys = sorted(obj.keys())

        return {k: sort_nested(obj[k], False) for k in keys}

    elif isinstance(obj, list):
        return [sort_nested(v, False) for v in obj]

    else:
        return obj

def main():
    if len(sys.argv) != 2:
        print("Usage: python fix_af3_json.py input.json")
        sys.exit(1)

    in_path = Path(sys.argv[1])
    if not in_path.is_file():
        print(f"Error: {in_path} does not exist or is not a file.")
        sys.exit(1)

    try:
        data = load_object(in_path)
    except Exception as e:
        print(f"Failed to parse input file: {e}")
        sys.exit(1)

    if not isinstance(data, dict):
        print("Top-level structure must be a dict/object.")
        sys.exit(1)

    # Reorder top level + 정렬된 nested 구조 생성
    fixed = sort_nested(data, is_top_level=True)

    out_path = in_path.with_name(f"{in_path.stem}_modified.json")
    out_path.write_text(
        json.dumps(
            fixed,
            indent=2,
            ensure_ascii=False,
            separators=(", ", ": ")
        ),
        encoding="utf-8",
    )

    print(f"Saved modified JSON to: {out_path}")


if __name__ == "__main__":
    main()

