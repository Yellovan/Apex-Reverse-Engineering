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
- Still open from this batch: E-012 (video) not watched, E-013 (screenshot) not cross-checked, E-014 (xlsx report) not opened.
- Next: get these 4 hypotheses in front of ChatGPT/Grok for independent review; open the video/screenshot/xlsx; design experiments for H-001/H-002 in `docs/Experiments.md`.
