#!/usr/bin/env python3
"""Print pip requirements for one or more Hermes lazy-install features.

    tools/print-deps.py provider.anthropic platform.matrix
    tools/print-deps.py --append requirements.txt provider.anthropic
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tools.lazy_deps import LAZY_DEPS, feature_specs


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Print pip requirements for Hermes lazy-install features.",
    )
    parser.add_argument(
        "features",
        nargs="+",
        help="Feature names (e.g. provider.anthropic platform.matrix).",
    )
    parser.add_argument(
        "-a", "--append",
        metavar="FILE",
        help="Also append the collected specs to FILE (e.g. requirements.txt).",
    )
    args = parser.parse_args()

    unknown = [f for f in args.features if f not in LAZY_DEPS]
    if unknown:
        print(f"error: unknown feature(s): {', '.join(unknown)}", file=sys.stderr)
        print(f"available: {', '.join(sorted(LAZY_DEPS))}", file=sys.stderr)
        return 2

    all_specs: list[str] = []
    for feature in args.features:
        specs = feature_specs(feature)
        print(f"# {feature}")
        for spec in specs:
            print(spec)
            all_specs.append(spec)
        print()

    if args.append:
        path = Path(args.append)
        with path.open("a", encoding="utf-8") as fh:
            for spec in all_specs:
                fh.write(spec + "\n")
        print(f"appended {len(all_specs)} spec(s) to {path}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
