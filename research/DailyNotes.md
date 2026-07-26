# Daily Notes

Free-form running log, one section per research session. This is scratch space — raw observations go here first, before being formalised into `docs/Evidence.md`, `docs/Hypotheses.md`, or `docs/Experiments.md`. Nothing here carries a confidence tag; it is pre-evidence.

## Format

```
## YYYY-MM-DD

- What was looked at today (which backtests/journals/videos).
- Raw observations, unfiltered.
- Anything that looks like a pattern → flag it, then formalise separately as a
  Hypothesis in docs/Hypotheses.md with a link back to this date.
```

---

## 2026-07-25

- Repository scaffolded: structure, docs, templates, parsers, GitHub labels/board/wiki set up.
- First real evidence batch received (`Apex_Investigation.zip`, Desktop): 8 backtests (personal/prop × 2023–2026), 3 Zennbot presets, 1 video, 1 settings screenshot, 1 xlsx report, 2 journal logs. Indexed as E-001 through E-016 in `docs/Evidence.md`.
- Discovered the real MT5 report HTML structure differs from initial assumptions (one single table with `<th colspan>` section markers, not separate `<table>` per section; Dutch UI labels — Tijd/Symbool/Richting/etc. — while type/direction values stay English). Rewrote `scripts/html_parser.py` accordingly and verified against real data (8035 deals parsed correctly from E-001).
- Batch-parsed all 8 backtests via new `scripts/batch_parse.py` → 26,141 total trades in `output/csv/`.
- Four initial hypotheses raised from this first pass (all 🟠, none reviewed yet by ChatGPT/Grok):
  - H-001: fixed 12-slot grid/layer ID pattern (`15743<N>`), consistent across all 8 backtests.
  - H-002: SL is progressively trailed into profit rather than static — backtest stats (77–86% win rate despite 70–77% `sl`-tagged exits) plus direct journal evidence (position #7160 SL moved 3956→3997→4040, above its 4038.99 entry).
  - H-003: Apex is a preset running on a generic engine called "Zennbot" (🟢 confirmed from preset file structure itself; the architectural interpretation stays 🟠).
  - H-004: propfirm preset is configured more conservatively than personal (drawdown limit, lot multiplier, fixed sizing balance, randomized anti-detection values) — not yet confirmed to translate into lower realised risk.
- Still open from this batch (at the time): E-012 (video) not watched, E-013 (screenshot) not cross-checked, E-014 (xlsx report) not opened.

### Same day, second pass — reviewed E-012/E-013/E-014 and ran the proposed tests

- **E-013 (settings screenshot):** Expert = `ZennbotApex2.4.ex5` (the compiled binary's actual name, not just preset text), M15, real-tick modeling, 25,000 EUR / 1:500 leverage, "Willekeurige Vertraging" execution maps directly to the `BacktestRealism_*` preset fields.
- **E-012 (video, 6:30 silent screen recording, no narration — audio is -91dB noise floor):** third independent confirmation of the `15743<N>` ID pattern, now seen live in the MT5 terminal on both pending orders and open positions. Also shows **simultaneous buy-stop AND sell-stop pending orders** — a two-sided straddle grid, not a one-directional ladder. Noted a tentative, unconfirmed lead on diamond-shaped chart markers that might be swing/pivot markers (`docs/Swing_Detection.md`) — needs a proper zoomed re-pass, not trustworthy yet.
- **E-014 (xlsx):** turned out to be a **real live-money account statement** (not a backtest) — account 30064842, broker MarketsVox (SC) Ltd, 9647 trades, 2025.06.19–2026.07.24. Big surprise: trades 8 forex cent-pairs (GBPUSD/EURUSD/NZDUSD/AUDUSD/EURGBP/USDCAD/AUDCAD/AUDNZD), essentially **no XAUUSD** (2 trades only), win rate 52.86% (vs 77–86% in every backtest), Sharpe 0.09, asymmetric win/loss size (avg win $29 vs avg loss -$22), and almost no comment/magic tagging (11/19502 deals). Raised as **H-005** — flagged as high-priority since it's the "does the backtest hold up in reality" question the project exists to answer, but explicitly caveated: **no direct proof this account even runs Apex/Zennbot** — the only link is the matching filename convention with preset E-011, provided in the same folder.
- Ran the 3 proposed tests from the first pass as formal experiments ([EXP-001](../docs/Experiments.md), [EXP-002](../docs/Experiments.md), [EXP-003](../docs/Experiments.md)):
  - EXP-001 (H-001 price-level test): **disproven** — all 12 IDs have overlapping entry-price ranges, not distinct bands. Revised reading: frequency loosely inverse-correlates with lot size (freq. ID `1574310`: n=1626, avg lot 0.088; rare ID `157430`: n=13, avg lot 1.008) — looks more like a grid-depth/re-entry-rung index than a price level.
  - EXP-002 (H-002 SL-displacement test, sign-corrected for buy/sell): 89.7% of 78 SL-triggered closes in E-016 had the SL on the profitable side of entry (avg +0.503), avg 37 modifications per affected position (max 378). ~10.3% were genuine losses — mechanism is dominant, not universal.
  - EXP-003 (H-004 realised-risk test): personal trades ran 9–15x the avg lot size and 8–12x the avg €-risk of prop trades across 2023–2025 — bigger gap than the 4x `AutoLotMultiplier` setting alone predicts.
- Filed H-001 through H-004 as GitHub issues #1–#4 (labeled, added to the Project board's "Investigating" column). H-005 needs its own issue next session.
- Next: file H-005 as an issue; try to confirm/deny whether the live cent account actually runs Apex (ask Melvin, or look for corroborating evidence); get all 5 hypotheses in front of ChatGPT/Grok for independent review; a proper zoomed pass on the video for the swing-marker lead.
