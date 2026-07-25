"""
One-off batch runner: parse every backtest HTML report under data/backtests/
into structured trade JSON under output/csv/, then print aggregate statistics
per report and a combined total.

Not part of the documented pipeline (html_parser -> trade_parser -> statistics
-> compare_backtests) — this is a convenience wrapper for processing many
reports in one pass. Kept in scripts/ since it's reusable whenever a new batch
of evidence arrives, but it's a thin orchestration layer over the real tools.
"""

from __future__ import annotations

import json
from pathlib import Path

from trade_parser import pair_trades
from html_parser import parse_deals
from statistics import summarize

REPO_ROOT = Path(__file__).resolve().parent.parent
BACKTESTS_DIR = REPO_ROOT / "data" / "backtests"
OUTPUT_DIR = REPO_ROOT / "output" / "csv"


def main() -> None:
    all_trades = []
    per_report = {}

    for html_path in sorted(BACKTESTS_DIR.glob("*/*/*.html")):
        year = html_path.parent.parent.name
        account = html_path.parent.name
        source = f"{account}-{year}"

        stem = html_path.stem.lower()
        if "backtestfalse" in stem:
            source += "-backtestfalse"
        elif "backtesttrue" in stem:
            source += "-backtesttrue"

        deals = parse_deals(html_path)
        trades = pair_trades(deals, source)
        all_trades.extend(trades)

        out_path = OUTPUT_DIR / f"{source}_trades.json"
        out_path.write_text(json.dumps(trades, indent=2, ensure_ascii=False), encoding="utf-8")

        per_report[source] = summarize(trades)
        print(f"{source}: {len(deals)} deals -> {len(trades)} trades -> {out_path.name}")

    combined_path = OUTPUT_DIR / "all_trades.json"
    combined_path.write_text(json.dumps(all_trades, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nCombined: {len(all_trades)} trades -> {combined_path.name}")

    summary_path = OUTPUT_DIR / "per_report_statistics.json"
    summary_path.write_text(json.dumps(per_report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Per-report statistics -> {summary_path.name}")


if __name__ == "__main__":
    main()
