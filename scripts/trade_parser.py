"""
Pair raw MT5 deal rows (from html_parser.py) into round-trip trades and emit
them in the structured schema defined in templates/trade_schema.json.

MT5's "Deals" table records each fill as an independent row with a
direction of "in" or "out" (position open / position close). A round-trip
trade is one "in" deal paired with its later "out" deal on the same symbol.
Balance operations (deposits/withdrawals, direction blank, type "balance")
are not trades and are skipped.

SL/TP are frequently only present on the Orders table, not the Deals table —
when html_parser.py did not find sl/tp columns, they are stored as null
rather than guessed. This is deliberate: a forensic record must never
fabricate a value it did not observe (see docs/Evidence.md).
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict, deque
from datetime import datetime
from pathlib import Path

from html_parser import parse_deals


def _to_float(value: str) -> float | None:
    if value in (None, ""):
        return None
    try:
        return float(value.replace(" ", "").replace(",", ""))
    except ValueError:
        return None


def _to_iso(value: str) -> str | None:
    if not value:
        return None
    for fmt in ("%Y.%m.%d %H:%M:%S", "%Y.%m.%d %H:%M"):
        try:
            return datetime.strptime(value, fmt).isoformat()
        except ValueError:
            continue
    return value  # keep raw string rather than silently dropping data


def pair_trades(deals: list[dict], source: str) -> list[dict]:
    """Pair 'in'/'out' deals per symbol (FIFO) into structured trade records."""
    open_by_symbol: dict[str, deque] = defaultdict(deque)
    trades: list[dict] = []

    for deal in deals:
        direction = deal.get("direction", "").lower()
        symbol = deal.get("symbol", "")

        if not symbol or direction not in ("in", "out", "in/out"):
            continue  # balance/credit operations etc.

        if direction in ("in", "in/out"):
            open_by_symbol[symbol].append(deal)
            if direction == "in":
                continue

        if direction in ("out", "in/out") and open_by_symbol[symbol]:
            entry = open_by_symbol[symbol].popleft() if direction == "out" else deal
            exit_deal = deal

            entry_time = _to_iso(entry.get("time", ""))
            if entry_time is None:
                continue  # cannot place this trade on the timeline; skip rather than guess

            trades.append({
                "strategy": None,
                "entry": _to_float(entry.get("price")),
                "exit": _to_float(exit_deal.get("price")),
                "sl": _to_float(entry.get("sl")),
                "tp": _to_float(entry.get("tp")),
                "trail": None,
                "lot": _to_float(entry.get("volume")),
                "comment": entry.get("comment") or None,
                "time": entry_time,
                "close_time": _to_iso(exit_deal.get("time", "")),
                "symbol": symbol,
                "duration_minutes": None,
                "source": source,
            })

    for trade in trades:
        if trade["time"] and trade["close_time"]:
            try:
                start = datetime.fromisoformat(trade["time"])
                end = datetime.fromisoformat(trade["close_time"])
                trade["duration_minutes"] = round((end - start).total_seconds() / 60, 2)
            except ValueError:
                pass

    return trades


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html_report", help="Path to the MT5 Strategy Tester .htm/.html report")
    parser.add_argument("--source", help="Evidence.md ID or tag to stamp each trade with, "
                                          "defaults to the report filename")
    parser.add_argument("-o", "--output", help="Write JSON output here instead of stdout")
    args = parser.parse_args()

    source = args.source or Path(args.html_report).stem
    deals = parse_deals(args.html_report)
    trades = pair_trades(deals, source)
    output = json.dumps(trades, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Wrote {len(trades)} trades to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
