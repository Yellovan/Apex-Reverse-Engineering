"""
Compare aggregate statistics (see statistics.py) across two or more backtest
trade sets — e.g. data/backtests/2023 vs 2024 vs 2025, or two different
preset configurations of the same year.

This is a diffing tool, not a judgement tool: it reports the numbers side by
side per strategy group so a reviewer can decide whether a difference is
meaningful. It does not compute significance and does not flag "changed
behaviour" on its own — that determination belongs in docs/Experiments.md
as a reasoned conclusion, with this script's output cited as evidence.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from statistics import load_trades, summarize


def compare(labelled_paths: dict[str, list[str]]) -> dict:
    """labelled_paths: {label: [trade_file, ...]}"""
    per_label_summary = {label: summarize(load_trades(paths)) for label, paths in labelled_paths.items()}

    all_strategies = sorted({
        strategy
        for summary in per_label_summary.values()
        for strategy in summary.keys()
    })

    comparison = {}
    for strategy in all_strategies:
        comparison[strategy] = {
            label: summary.get(strategy)
            for label, summary in per_label_summary.items()
        }
    return comparison


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Example:\n"
               "  python compare_backtests.py --set 2023 data/2023_trades.json "
               "--set 2024 data/2024_trades.json --set 2025 data/2025_trades.json",
    )
    parser.add_argument(
        "--set", nargs=2, action="append", metavar=("LABEL", "TRADE_FILE"), required=True,
        dest="sets",
        help="A label and a trade JSON file, repeatable. Multiple files per label: "
             "repeat the same label with different files.",
    )
    parser.add_argument("-o", "--output", help="Write JSON output here instead of stdout")
    args = parser.parse_args()

    labelled_paths: dict[str, list[str]] = {}
    for label, path in args.sets:
        labelled_paths.setdefault(label, []).append(path)

    result = compare(labelled_paths)
    output = json.dumps(result, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Wrote comparison across {len(labelled_paths)} sets to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
