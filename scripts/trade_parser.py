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
import re
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


def _parse_exit_comment(comment: str) -> tuple[str | None, float | None]:
    """MT5 stamps the closing deal's comment with the reason and triggered
    price, e.g. 'tp 1838.47' / 'sl 2062.52' (Strategy Tester reports) or
    '[tp 1838.47]' / '[sl 2062.52]' (live account "Trade History Report"
    exports, e.g. E-019) — this is observed evidence of which level was hit,
    not an inference, so it's safe to lift directly."""
    match = re.match(r"^\[?(tp|sl)\s+([\d.]+)\]?$", comment.strip(), re.IGNORECASE)
    if not match:
        return None, None
    reason, price = match.groups()
    return reason.lower(), _to_float(price)


def _pop_matching_volume(queue: deque, target_volume: float | None, tol: float = 1e-6):
    """Pop the OLDEST queued entry whose volume matches the closing deal's
    volume, not just the oldest entry regardless of size.

    Proven necessary 2026-07-30 (E-019 re-analysis): two 0.38-lot closing
    deals at 2026.07.21 14:36:10/11 were previously FIFO-paired against a
    0.42-lot and a 0.04-lot entry from DIFFERENT grid IDs — a volume
    mismatch that's easy to catch mechanically but wasn't being checked.
    The real 0.38-lot entry (grid ID 114989, entered 09:42:04) was left
    unmatched. Falls back to plain FIFO (oldest, any size) only if no
    volume match exists in the queue at all, since an exit must be
    attributed to *something* rather than silently dropped."""
    if target_volume is not None:
        for i, candidate in enumerate(queue):
            cand_vol = _to_float(candidate.get("volume"))
            if cand_vol is not None and abs(cand_vol - target_volume) <= tol:
                del queue[i]
                return candidate
    return queue.popleft() if queue else None


def pair_trades(deals: list[dict], source: str) -> list[dict]:
    """Pair 'in'/'out' deals per symbol (FIFO, volume-matched) into
    structured trade records.

    Queues are kept separate per (symbol, position side), not just per symbol.
    A hedging-mode account (e.g. E-019) can hold many simultaneous buy AND
    sell positions on the same symbol — MT5 always closes a position with a
    deal of the OPPOSITE type (a "sell"-type deal closes a buy position, a
    "buy"-type deal closes a sell position), so a single FIFO queue per
    symbol would silently pair an exit with the wrong entry whenever both
    directions are open at once. Splitting the queue by the *entry's* type
    keeps each side's FIFO order correct. Within a queue, entries are further
    matched by volume (see _pop_matching_volume) since multiple concurrent
    same-side entries of DIFFERENT sizes are common on this grid strategy,
    and plain oldest-first FIFO can grab the wrong one."""
    open_by_symbol_side: dict[tuple[str, str], deque] = defaultdict(deque)
    trades: list[dict] = []

    for deal in deals:
        direction = deal.get("direction", "").lower()
        symbol = deal.get("symbol", "")
        deal_type = deal.get("type", "").lower()

        if not symbol or direction not in ("in", "out", "in/out"):
            continue  # balance/credit operations etc.

        if direction in ("in", "in/out"):
            open_by_symbol_side[(symbol, deal_type)].append(deal)
            if direction == "in":
                continue

        if direction in ("out", "in/out"):
            # An "out" deal's type is the opposite of the position it closes.
            entry_side = "sell" if deal_type == "buy" else "buy"
            queue = open_by_symbol_side[(symbol, entry_side)]
            if not queue:
                continue  # no matching open entry observed (e.g. report window cut off mid-position)
            if direction == "out":
                entry = _pop_matching_volume(queue, _to_float(deal.get("volume")))
                if entry is None:
                    continue
            else:
                entry = deal
            exit_deal = deal

            entry_time = _to_iso(entry.get("time", ""))
            if entry_time is None:
                continue  # cannot place this trade on the timeline; skip rather than guess

            exit_reason, exit_trigger_price = _parse_exit_comment(exit_deal.get("comment", ""))

            trades.append({
                "strategy": None,
                "entry": _to_float(entry.get("price")),
                "exit": _to_float(exit_deal.get("price")),
                "sl": exit_trigger_price if exit_reason == "sl" else _to_float(entry.get("sl")),
                "tp": exit_trigger_price if exit_reason == "tp" else _to_float(entry.get("tp")),
                "trail": None,
                "lot": _to_float(entry.get("volume")),
                "comment": entry.get("comment") or None,
                "exit_reason": exit_reason,
                "profit": _to_float(exit_deal.get("profit")),
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
