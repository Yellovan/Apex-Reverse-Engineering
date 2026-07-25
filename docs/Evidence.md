# Evidence Index

Every raw evidence file added to `data/` must be indexed here with a stable ID (`E-###`) before it is cited anywhere in `Findings.md`, `Hypotheses.md`, or `Experiments.md`. This file is the single source of truth for "where did this fact come from."

## Index

| ID | Type | Path | Date range | Symbol(s) | Summary | Cited in |
|---|---|---|---|---|---|---|
| _E-001_ | _backtest / journal / screenshot / video / preset / report_ | `data/...` | | | | |

_Add one row per evidence item. Never renumber or reuse an ID once assigned, even if the evidence is later found to be irrelevant — mark it "unused" rather than deleting the row, to keep citations in other docs valid._

## Evidence Types

- **Backtest** — Strategy Tester `.htm`/`.html` report or raw `.xml`, stored under `data/backtests/<year>/`.
- **Journal** — MT5 Experts/Journal log export, stored under `data/journals/`.
- **Screenshot** — chart or terminal screenshot, stored under `data/screenshots/`.
- **Video** — recorded live session or vendor demo, stored under `data/videos/` (tracked via Git LFS, see `.gitattributes`).
- **Preset** — `.set` input file, stored under `data/presets/`.
- **Report** — any other exported report (e.g. custom statement), stored under `data/reports/`.

## Adding New Evidence — Checklist

1. Drop the raw file into the correct `data/` subfolder.
2. Assign the next `E-###` ID and add a row above.
3. If it contains trades, run [`scripts/trade_parser.py`](../scripts/trade_parser.py) to extract structured JSON into `output/csv/` or a project database, tagging each trade with `"source": "E-###"`.
4. Reference `E-###` from any hypothesis, experiment, or finding that relies on it.
