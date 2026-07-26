# Evidence Index

Every raw evidence file added to `data/` must be indexed here with a stable ID (`E-###`) before it is cited anywhere in `Findings.md`, `Hypotheses.md`, or `Experiments.md`. This file is the single source of truth for "where did this fact come from."

## Index

Batch added 2026-07-25 from `Apex_Investigation.zip` (Melvin's own MT5 Strategy Tester exports + Zennbot preset files). All backtest reports parsed via [`scripts/batch_parse.py`](../scripts/batch_parse.py); structured trade JSON lives in `output/csv/<source>_trades.json`.

| ID | Type | Path | Date range | Symbol(s) | Summary | Cited in |
|---|---|---|---|---|---|---|
| E-001 | Backtest | `data/backtests/2023/personal/ReportTester-personal-2023.html` (+3 companion PNGs) | 2023 full year | XAUUSD | "Apex personal 25k" preset, 8035 deals / 4017 trades | H-001, H-002 |
| E-002 | Backtest | `data/backtests/2024/personal/ReportTester-personal-2024.html` (+3 companion PNGs) | 2024 full year | XAUUSD | 7789 deals / 3894 trades | H-001, H-002 |
| E-003 | Backtest | `data/backtests/2025/personal/ReportTester-personal-2025.html` (+3 companion PNGs) | 2025 full year | XAUUSD | 7111 deals / 3555 trades | H-001, H-002 |
| E-004 | Backtest | `data/backtests/2026/personal/ReportTester-personal-2026(backtestfalse).html` (+3 PNGs) | 2026 partial | XAUUSD | "BacktestRealism" disabled variant; 3381 deals / 1690 trades | H-001, H-002 |
| E-005 | Backtest | `data/backtests/2026/personal/ReportTester-personal-2026(backtesttrue).html` (+3 PNGs) | 2026 partial | XAUUSD | "BacktestRealism" enabled variant (slippage simulation); 3343 deals / 1671 trades | H-001, H-002 |
| E-006 | Backtest | `data/backtests/2023/prop/ReportTester-prop-2023.html` (+3 companion PNGs) | 2023 full year | XAUUSD | "Apex propfirm 25K" preset, 8073 deals / 4036 trades | H-001, H-002, H-004 |
| E-007 | Backtest | `data/backtests/2024/prop/ReportTester-prop-2024.html` (+3 companion PNGs) | 2024 full year | XAUUSD | 7631 deals / 3815 trades | H-001, H-002, H-004 |
| E-008 | Backtest | `data/backtests/2025/prop/ReportTester-prop-2025.html` (+3 companion PNGs) | 2025 full year | XAUUSD | 6927 deals / 3463 trades | H-001, H-002, H-004 |
| E-009 | Preset | `data/presets/apex personal 25k.set` | n/a | n/a | "Zennbot" engine preset, `ZennbotPresetName=Apex personal 0`, MaxDrawdown 100% (off), AutoLotMultiplier=5 | H-003, H-004 |
| E-010 | Preset | `data/presets/apex propfirm 25K.set` | n/a | n/a | `ZennbotPresetName=Apex prop-live 25000`, MaxDrawdown 4% / hard equity floor 22750, AutoLotMultiplier=1.25, RandomizedValues enabled | H-003, H-004 |
| E-011 | Preset | `data/presets/ulltima_markets_personak_cent.set` | n/a | n/a | Cent-account variant, MaxDrawdown 30%, AutoLotMultiplier=8 | H-003, H-004 |
| E-012 | Video | `data/videos/apex video.mp4` (Git LFS) | chart dates shown: Jan 2026 | XAUUSD | Silent (-91dB) 6:30 screen recording, 1280x720, of MT5 Strategy Tester visual/replay mode running "Zennbot Apex v2.4". Shows simultaneous buy-stop + sell-stop pending orders at multiple price levels, each tagged with a `15743<N>` comment ID, plus per-position SL levels drawn on chart with $/% risk labels. | H-001, H-003 |
| E-013 | Screenshot | `data/screenshots/instellling backtest.png` | config for a 2025.01.01–2026.01.01 single-year run | XAUUSD | Strategy Tester settings dialog: Expert = `ZennbotApex2.4.ex5`, M15, "Elke tick gebaseerd op echte ticks" (real-tick modeling), 25,000 EUR deposit, 1:500 leverage, "Willekeurige Vertraging" execution (maps to `BacktestRealism_*` preset fields), optimization disabled. | H-003 |
| E-014 | Report | `data/reports/repport ultima markets personal cent account.xlsx` | 2025.06.19–2026.07.24 | GBPUSD.cent, EURUSD.cent, NZDUSD.cent, AUDUSD.cent, EURGBP.cent, USDCAD.cent, AUDCAD.cent, AUDNZD.cent (XAUUSD.cent: only 2 trades) | **⚠️ WRONG FILE — under correction (2026-07-25, Melvin):** initially catalogued as a real-money account statement for account 30064842 ("MarketsVox (SC) Ltd"). Melvin has since confirmed there is no MarketsVox/Ultima Markets account actually running Apex — this file was mistakenly included in the evidence batch. The stats originally recorded here (9647 trades, 52.86% win rate, Sharpe 0.09, etc.) are **not evidence about Apex** and must not be cited. Superseded once Melvin uploads the correct file — see [H-005](Hypotheses.md#h-005-the-live-ultima-markets-cent-account-shows-materially-different-weaker-edge-behaviour-than-the-xauusd-backtests). | H-005 (invalidated) |
| E-015 | Journal | `data/journals/personal-2026-journal(backtestfalse).txt` | 2026.07.21 (backtest run logged 2026.07.25) | XAUUSD | MT5 Experts log, BacktestRealism-off run, 8191 lines | H-002 |
| E-016 | Journal | `data/journals/personal-2026-journal(backtesttrue).txt` | 2026.07.21 (backtest run logged 2026.07.25) | XAUUSD | MT5 Experts log, BacktestRealism-on run, 10240 lines, 3740 stop-loss/take-profit/position-modified events | H-002 |

_Add one row per evidence item. Never renumber or reuse an ID once assigned, even if the evidence is later found to be irrelevant — mark it "unused" rather than deleting the row, to keep citations in other docs valid._

_E-012, E-013, E-014 reviewed 2026-07-25 — see updated rows above._

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
