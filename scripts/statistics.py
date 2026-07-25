"""
Aggregate statistics over parsed Apex trades (see templates/trade_schema.json).

Loads one or more JSON trade files produced by trade_parser.py, groups by
`strategy` (falling back to a single "unknown" group when strategy IDs have
not been identified yet — see docs/Strategy_Map.md), and reports:

- trade count
- win rate (from the `profit` field trade_parser.py lifts off the closing deal)
- average SL distance, average TP distance (in price units, not points —
  point-normalisation depends on the symbol's tick size, deliberately left
  to the caller since this script is symbol-agnostic)
- average trade duration (minutes)
- average trailing distance, where recorded
- exit reason breakdown (tp / sl / other), from the `exit_reason` field
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

# NOTE: this module is deliberately named statistics.py to match the required
# repo layout. That means it shadows the stdlib `statistics` module for any
# script run from this directory — so averages are computed by hand below
# instead of importing the real one.


def load_trades(paths: list[str]) -> list[dict]:
    trades: list[dict] = []
    for path in paths:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        if isinstance(data, list):
            trades.extend(data)
    return trades


def _mean(values: list[float]) -> float | None:
    values = [v for v in values if v is not None]
    return round(sum(values) / len(values), 5) if values else None


def summarize(trades: list[dict]) -> dict:
    groups: dict[str | int, list[dict]] = defaultdict(list)
    for t in trades:
        key = t.get("strategy") if t.get("strategy") is not None else "unknown"
        groups[key].append(t)

    report = {}
    for strategy, group in groups.items():
        sl_distances = [
            abs(t["entry"] - t["sl"])
            for t in group
            if t.get("entry") is not None and t.get("sl") is not None
        ]
        tp_distances = [
            abs(t["entry"] - t["tp"])
            for t in group
            if t.get("entry") is not None and t.get("tp") is not None
        ]
        durations = [t["duration_minutes"] for t in group if t.get("duration_minutes") is not None]
        trails = [t["trail"] for t in group if t.get("trail") is not None]
        profits = [t["profit"] for t in group if t.get("profit") is not None]
        exit_reasons = [t["exit_reason"] for t in group if t.get("exit_reason") is not None]

        wins = sum(1 for p in profits if p > 0)
        win_rate = round(wins / len(profits), 4) if profits else None

        report[str(strategy)] = {
            "trade_count": len(group),
            "win_rate": win_rate,
            "win_rate_sample_size": len(profits),
            "avg_sl_distance": _mean(sl_distances),
            "avg_tp_distance": _mean(tp_distances),
            "avg_duration_minutes": _mean(durations),
            "avg_trailing_distance": _mean(trails),
            "sl_distance_sample_size": len(sl_distances),
            "tp_distance_sample_size": len(tp_distances),
            "exit_reason_counts": {
                reason: exit_reasons.count(reason) for reason in sorted(set(exit_reasons))
            },
        }
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("trade_files", nargs="+", help="One or more trade JSON files (trade_parser.py output)")
    parser.add_argument("-o", "--output", help="Write JSON report here instead of stdout")
    args = parser.parse_args()

    trades = load_trades(args.trade_files)
    report = summarize(trades)
    output = json.dumps(report, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Wrote statistics for {len(trades)} trades to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
