"""
Parse an MT5 Strategy Tester HTML report's "Deals" section into raw row dicts.

This module only extracts what is literally printed in the report — it does not
interpret, pair, or classify anything. That happens downstream in
trade_parser.py. Keeping this boundary means a change in how we identify
strategies or pair round-trip trades never requires re-touching the HTML
parsing itself.

MT5 Strategy Tester reports (Report > Save as Report, "Detailed report") are
NOT multiple separate <table> elements — the whole report (Settings, Results,
Orders, Deals) is ONE long <table>, with each section introduced by a
<tr><th colspan="N"><b>SectionName</b></th></tr> row, immediately followed by
a bold column-header row, then data rows, then a bold totals row, e.g.:

    <tr><th colspan="13"><div><b>Deals</b></div></th></tr>
    <tr><td><b>Tijd</b></td><td><b>Deal</b></td>...</tr>
    <tr><td>2023.01.03 03:03:10</td><td>16</td>...</tr>
    ...
    <tr><td colspan="8"></td><td><b>-5 108.16</b></td>...</tr>   <- totals row

The report's UI language changes the header labels (Dutch: Tijd/Symbool/
Soort/Richting/Prijs/Opdracht/Commissie/Winst/Saldo/Opmerkingen) but MT5 keeps
deal type ("buy"/"sell"/...) and direction ("in"/"out") values in English
regardless of locale, so those are matched literally in trade_parser.py.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from bs4 import BeautifulSoup

# Header text (lowercased) -> normalised field name we store it under.
# Includes English and Dutch (MT5 NL locale) labels; add more locales here as
# they show up in evidence rather than guessing them in advance.
_HEADER_MAP = {
    "time": "time", "tijd": "time",
    "deal": "deal_id",
    "symbol": "symbol", "symbool": "symbol",
    "type": "type", "soort": "type",
    "direction": "direction", "richting": "direction",
    "volume": "volume",
    "price": "price", "prijs": "price",
    "order": "order_id", "opdracht": "order_id",
    "commission": "commission", "commissie": "commission",
    "swap": "swap",
    "profit": "profit", "winst": "profit",
    "balance": "balance", "saldo": "balance",
    "comment": "comment", "opmerkingen": "comment",
    "s / l": "sl", "sl": "sl",
    "t / p": "tp", "tp": "tp",
}


def _find_section_title_row(soup: BeautifulSoup, section_name: str):
    """Find the <tr> containing the bold section header (e.g. '<b>Deals</b>' in a <th>)."""
    for th in soup.find_all("th"):
        if th.get_text(strip=True).lower() == section_name.lower():
            return th.find_parent("tr")
    return None


def _row_is_bold(row) -> bool:
    """True if every non-empty cell in this row is entirely bold (totals/header rows)."""
    cells = row.find_all("td")
    if not cells:
        return False
    return all(cell.find("b") is not None for cell in cells if cell.get_text(strip=True))


def parse_deals(html_path: str | Path) -> list[dict]:
    """Return a list of raw deal-row dicts, in report order."""
    html_path = Path(html_path)
    # MT5 typically saves reports as UTF-16 with a BOM; older/other exports are UTF-8.
    try:
        raw = html_path.read_text(encoding="utf-16")
    except UnicodeError:
        raw = html_path.read_text(encoding="utf-8", errors="ignore")

    soup = BeautifulSoup(raw, "html.parser")
    title_row = _find_section_title_row(soup, "Deals")
    if title_row is None:
        return []

    header_row = title_row.find_next_sibling("tr")
    if header_row is None:
        return []

    header_cells = [c.get_text(strip=True).lower() for c in header_row.find_all("td")]
    fields = [_HEADER_MAP.get(h, h.replace(" ", "_")) for h in header_cells]

    deals = []
    row = header_row.find_next_sibling("tr")
    while row is not None:
        if row.find("th") is not None:
            break  # a new section started — Deals is normally last, but don't assume
        if _row_is_bold(row):
            break  # totals row marks the end of the data rows
        cells = [c.get_text(strip=True) for c in row.find_all("td")]
        if cells and len(cells) == len(fields):
            record = dict(zip(fields, cells))
            if record.get("time"):
                deals.append(record)
        row = row.find_next_sibling("tr")

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
