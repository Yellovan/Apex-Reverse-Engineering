"""
Parse a raw MT5 Experts/Journal terminal log (UTF-16LE, one live-terminal
export per day) into structured position lifecycle data for account
31599933 (E-017, Ultima Markets Ltd).

Unlike html_parser.py (which reads the Strategy Tester's structured Deals
table with an explicit profit column), a live journal only logs *events* as
they happen: pending-order placements, fills ("deal ... done (based on
order #N)"), SL/TP modifications, explicit market-close events
("market buy/sell X, close #N ..."), and pending-order cancellations.

There is no position-ID field in this log format, and no profit column.
This script therefore does NOT fabricate a win rate for every trade. It
only computes win/loss for closes it can trace with certainty:

  1. Explicit market closes ("market buy/sell LOT SYMBOL, close #TICKET
     ... PRICE") — the ticket is given directly, and if that ticket's
     original opening fill was also observed in the log, entry and exit
     price are both known facts, so win/loss (by price direction, not
     currency, since contract size/point value for .sc symbols isn't
     documented anywhere in the evidence set) can be stated without
     guessing.

  2. Everything else (silent SL/TP-triggered closes) is reported as
     "unmatched" rather than guessed, because MT5 assigns SL/TP triggers a
     new system order ticket that this log format does not link back to
     the original position ticket. Forcing a match here would mean
     fabricating evidence, which the project's rules forbid.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Real log lines are prefixed with a 2-letter thread tag, a severity code (0/1/2), a tab-separated
# timestamp, and a source tag (Trades/Network/Signal/Experts/Terminal), e.g.:
#   EN\t0\t00:00:00.941\tTrades\t'31599933': buy stop 0.53 XAUUSD.sc at 4886.38 sl: 4836.68 tp: 4922.16
_PREFIX = r"^\S+\t\d\t(\d{2}:\d{2}:\d{2})\.\d+\tTrades\t"

PLACEMENT_RE = re.compile(
    _PREFIX + r"'(\d+)': (buy|sell) stop ([\d.]+) (\S+) at ([\d.]+) "
    r"sl: ([\d.]+) tp: ([\d.]+)$"
)
FILL_RE = re.compile(
    _PREFIX + r"'(\d+)': deal #(\d+) (buy|sell) ([\d.]+) (\S+) at ([\d.]+) "
    r"done \(based on order #(\d+)\)$"
)
CLOSE_RE = re.compile(
    _PREFIX + r"'(\d+)': market (buy|sell) ([\d.]+) (\S+), "
    r"close #(\d+) (buy|sell) ([\d.]+) (\S+) ([\d.]+)$"
)
MODIFY_RE = re.compile(
    _PREFIX + r"'(\d+)': modify #(\d+) (buy|sell) ([\d.]+) (\S+) "
    r"sl: ([\d.]+), tp: ([\d.]+) -> sl: ([\d.]+), tp: ([\d.]+)$"
)


def load_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-16").splitlines()


def parse_files(paths: list[Path]) -> dict:
    placements = {}       # ticket -> dict(direction, lot, symbol, price, sl, tp)
    fills = {}            # ticket -> dict(direction, lot, symbol, price, time, deal_id) [first fill only]
    modifications = {}     # ticket -> count of modify lines
    explicit_closes = []   # list of dicts

    for path in paths:
        for line in load_lines(path):
            line = line.strip("﻿").rstrip()

            m = PLACEMENT_RE.match(line)
            if m:
                _time, account, direction, lot, symbol, price, sl, tp = m.groups()
                # placements repeat (retried while market closed); keep the first seen per unique
                # (direction, lot, price) tuple is not reliable as a key since duplicates share values.
                continue

            m = FILL_RE.match(line)
            if m:
                time_, account, deal_id, direction, lot, symbol, price, order_ticket = m.groups()
                if order_ticket not in fills:
                    fills[order_ticket] = {
                        "direction": direction,
                        "lot": float(lot),
                        "symbol": symbol,
                        "price": float(price),
                        "time": time_,
                        "deal_id": deal_id,
                    }
                continue

            m = MODIFY_RE.match(line)
            if m:
                ticket = m.group(3)
                if "->" in line and "accepted" not in line and " done in " not in line:
                    modifications[ticket] = modifications.get(ticket, 0) + 1
                continue

            m = CLOSE_RE.match(line)
            if m:
                (time_, account, close_dir, close_lot, close_symbol,
                 ticket, orig_dir, orig_lot, orig_symbol, price) = m.groups()
                if "placed for execution" in line:
                    continue
                explicit_closes.append({
                    "time": time_,
                    "ticket": ticket,
                    "close_direction": close_dir,
                    "lot": float(close_lot),
                    "symbol": close_symbol,
                    "price": float(price),
                })

    return {
        "fills": fills,
        "modifications": modifications,
        "explicit_closes": explicit_closes,
    }


def compute_results(parsed: dict) -> dict:
    fills = parsed["fills"]
    closes = parsed["explicit_closes"]

    matched = []
    unmatched_tickets = []

    for close in closes:
        ticket = close["ticket"]
        entry = fills.get(ticket)
        if entry is None:
            unmatched_tickets.append(ticket)
            continue

        entry_price = entry["price"]
        exit_price = close["price"]
        direction = entry["direction"]  # the original position's direction

        if direction == "buy":
            win = exit_price > entry_price
            pips = exit_price - entry_price
        else:
            win = exit_price < entry_price
            pips = entry_price - exit_price

        matched.append({
            "ticket": ticket,
            "direction": direction,
            "lot": entry["lot"],
            "entry_price": entry_price,
            "exit_price": exit_price,
            "entry_time": entry["time"],
            "exit_time": close["time"],
            "price_diff": round(pips, 3),
            "win": win,
        })

    wins = sum(1 for t in matched if t["win"])

    return {
        "total_fills_observed": len(fills),
        "total_explicit_close_events": len(closes),
        "matched_closes": len(matched),
        "unmatched_close_tickets": unmatched_tickets,
        "matched_trades": matched,
        "win_rate_among_matched": round(wins / len(matched), 4) if matched else None,
        "wins": wins,
        "losses": len(matched) - wins,
        "modification_count_summary": {
            "positions_with_modifications": len(parsed["modifications"]),
            "avg_modifications_per_position": (
                round(sum(parsed["modifications"].values()) / len(parsed["modifications"]), 2)
                if parsed["modifications"] else None
            ),
            "max_modifications_on_one_position": (
                max(parsed["modifications"].values()) if parsed["modifications"] else None
            ),
        },
        "lot_size_distribution": sorted({round(f["lot"], 2) for f in fills.values()}),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+", help="Path(s) to UTF-16LE MT5 journal .log files")
    parser.add_argument("-o", "--output", help="Write JSON output here instead of stdout")
    args = parser.parse_args()

    paths = [Path(p) for p in args.logs]
    parsed = parse_files(paths)
    result = compute_results(parsed)
    output = json.dumps(result, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Wrote result to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
