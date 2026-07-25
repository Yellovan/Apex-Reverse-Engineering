"""
Parse an MT5 Strategy Tester HTML report ("Deals" table) into raw row dicts.

This module only extracts what is literally printed in the report — it does not
interpret, pair, or classify anything. That happens downstream in
trade_parser.py. Keeping this boundary means a change in how we identify
strategies or pair round-trip trades never requires re-touching the HTML
parsing itself.

MT5 Strategy Tester reports (Report > Save as Report, "Detailed report") contain
a "Deals" section as an HTML <table> with a header row roughly like:

    Time | Deal | Symbol | Type | Direction | Volume | Price | Order | Commission | Swap | Profit | Balance | Comment

Column presence/order can vary slightly between terminal builds and broker
report templates, so this parser matches columns by header name rather than
fixed position.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from bs4 import BeautifulSoup

# Header text (lowercased) -> normalised field name we store it under.
_HEADER_MAP = {
    "time": "time",
    "deal": "deal_id",
    "symbol": "symbol",
    "type": "type",
    "direction": "direction",
    "volume": "volume",
    "price": "price",
    "order": "order_id",
    "commission": "commission",
    "swap": "swap",
    "profit": "profit",
    "balance": "balance",
    "comment": "comment",
    "s / l": "sl",
    "sl": "sl",
    "t / p": "tp",
    "tp": "tp",
}


def _find_deals_table(soup: BeautifulSoup):
    """Locate the 'Deals' table by finding its section header, MT5 reports are
    one long HTML page with multiple tables (Settings, Results, Orders, Deals)."""
    for bold in soup.find_all(["b", "th"]):
        if bold.get_text(strip=True).lower() == "deals":
            table = bold.find_parent("table")
            if table is not None:
                next_table = table.find_next("table")
                if next_table is not None:
                    return next_table
    # Fallback: last table in the document (Deals is normally the final section).
    tables = soup.find_all("table")
    return tables[-1] if tables else None


def parse_deals(html_path: str | Path) -> list[dict]:
    """Return a list of raw deal-row dicts, in report order."""
    html_path = Path(html_path)
    # MT5 typically saves reports as UTF-16 with a BOM; older/other exports are UTF-8.
    try:
        raw = html_path.read_text(encoding="utf-16")
    except UnicodeError:
        raw = html_path.read_text(encoding="utf-8", errors="ignore")

    soup = BeautifulSoup(raw, "html.parser")
    table = _find_deals_table(soup)
    if table is None:
        return []

    rows = table.find_all("tr")
    if not rows:
        return []

    header_cells = [c.get_text(strip=True).lower() for c in rows[0].find_all(["th", "td"])]
    fields = [_HEADER_MAP.get(h, h.replace(" ", "_")) for h in header_cells]

    deals = []
    for row in rows[1:]:
        cells = [c.get_text(strip=True) for c in row.find_all("td")]
        if not cells or len(cells) != len(fields):
            continue
        record = dict(zip(fields, cells))
        # Skip separator/section rows that slipped in (e.g. a "Deals" title row).
        if record.get("time", "").lower() in ("", "deals"):
            continue
        deals.append(record)

    return deals


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("html_report", help="Path to the MT5 Strategy Tester .htm/.html report")
    parser.add_argument("-o", "--output", help="Write JSON output here instead of stdout")
    args = parser.parse_args()

    deals = parse_deals(args.html_report)
    output = json.dumps(deals, indent=2, ensure_ascii=False)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Wrote {len(deals)} deals to {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
