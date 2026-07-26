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
- Filed H-001 through H-005 as GitHub issues #1–#5 (labeled, added to the Project board — #1–#4 in "Investigating", #5 in "TODO" since it had an open prerequisite question).

### Same day, third pass — E-014 confirmed to be the wrong file

- Asked Melvin directly whether the live cent account (E-014) runs Apex — exactly the prerequisite question flagged above. **Answer: no.** Melvin confirmed there is no MarketsVox/Ultima Markets account actually running Apex — E-014 was mistakenly included in the evidence batch. He's investigating what went wrong and will upload the correct file.
- Withdrew H-005 (marked "⚠️ EVIDENCE UNDER CORRECTION" in `docs/Hypotheses.md`, not deleted — it's a useful record of exactly the mismatched-evidence risk its own caveat warned about) and flagged E-014's row in `docs/Evidence.md` as wrong-file/do-not-cite. Removed the now-answered question from `research/Questions.md`'s open list, logged it under Answered.
- Next: wait for the corrected file, re-run the E-014 review from scratch once it arrives (index as a new E-### rather than overwriting E-014, per the "never renumber/reuse an ID" rule), re-evaluate whether H-005 (or a new hypothesis) applies. Still outstanding from earlier: get H-001–H-004 in front of ChatGPT/Grok; a proper zoomed video pass for the swing-marker lead.

## 2026-07-26 — correct file received: E-017

- Melvin pasted the correct file: a live MT5 Experts journal, account 31599933, broker "Ultima Markets Ltd" (UltimaMarkets-Live 2), covering 2026.07.20–2026.07.24. Indexed as **E-017**.
- **Confirmed directly in the log itself** — no inference needed this time: `expert ZennbotApex2.3beta1 (XAUUSD.sc,M30) removed` at 12:28 on 2026.07.24, then `expert ZennbotApex2.4 (XAUUSD.sc,M30) loaded successfully` at 16:43 the same day. This account genuinely runs Apex, on the same symbol (XAUUSD, broker suffix `.sc`) as every backtest — unlike E-014, which was a different account trading forex majors with no EA name anywhere in it.
- Also caught a live version upgrade (2.3beta1 → 2.4) mid-week — useful for the timeline, and it confirms 2.3beta1 was a real prior production version, not just a guess.
- **Storage note/self-correction:** first attempt at saving this file to the repo went wrong — tried to reproduce the full multi-thousand-line paste verbatim via the Write tool and hit output-length limits twice, at one point leaving a truncated/incomplete file in place without flagging it clearly enough. Fixed by rewriting `data/journals/ultima raport.txt` as an explicitly-labeled curated excerpt (header explains exactly what's included and why, and that the full log needs a proper file upload from Melvin if exhaustive parsing is ever needed) rather than silently passing off a partial file as complete.
- Cross-checked behaviour against the backtests: lot-size ladder on day 1 (0.04/0.08/0.13/0.16/0.21/0.26/0.32/0.38/0.42/0.44/0.53 — eleven tiers, buy+sell mirrored pairs) matches the ~12-tier grid-depth reading from EXP-001; a representative SL-trailing sequence (2026.07.22, position #369272106 etc.) matches the granular trailing pattern from EXP-002. Raised as **H-006** rather than resurrecting H-005, to keep the "this hypothesis was based on wrong evidence" record intact and separate from the new, correctly-sourced one.
- One event flagged as an open question, not yet a finding: a burst of ~19 market-close events over ~11 minutes on 2026.07.24 (~04:47-04:58) — possible drawdown kill-switch, grid TP sweep, or manual intervention. Also noticed: a second EA (`testdaashboard`, M1) runs alongside Apex on this account, purpose unknown; and pending-order cleanup happens at 22:45 daily in the live log vs. the presets' stated 16:45 `ScheduledClose` time — an unresolved discrepancy.
- Updated Evidence.md, Hypotheses.md (H-003 4th confirmation, new H-006), Architecture.md, Strategy_Map.md, Trailing_Stop.md, Trade_Manager.md, Risk_Manager.md, and research/Questions.md accordingly.
- Next: get a full/proper export of E-017 (or the full pasted log, stored via file upload rather than chat paste) to actually compute a live win-rate/risk comparison against the backtests — that's what H-006 still needs to become more than a qualitative match. Still outstanding: ChatGPT/Grok review of all 6 hypotheses; the swing-marker video re-pass; the mass-close and 22:45-vs-16:45 questions.

### Same day, later pass — full raw logs received, mass-close event solved

- Melvin uploaded the actual complete raw MT5 journal exports directly to GitHub as 5 UTF-16LE files (`data/journals/20260720.log` through `20260724.log`, 3,364 lines total), replacing the need for the earlier hand-transcribed excerpt. Indexed as **E-018** (E-017 kept, marked superseded — not deleted, per the never-reuse-IDs rule).
- Also found: 5 open GitHub issues (H-001, H-002, H-003, H-004, H-006) had gone stale — their "Proposed test" text was still shown as open work even though EXP-001/002/003 had already answered 3 of them back on 07-25. Posted status-sync comments on issues #1, #2, #3, #4 with the actual results, explaining these are intentional hypothesis-trackers (not bugs) that stay open pending ChatGPT/Grok cross-review, not because the work is undone.
- Wrote [`scripts/journal_log_parser.py`](../scripts/journal_log_parser.py) to parse the raw UTF-16LE journal format (different from the Strategy Tester's structured Deals table that `trade_parser.py`/`html_parser.py` handle). Ran it as **EXP-004** against the full week: 176 pending-order fills, 86 positions modified (avg 3.52 mods, max 18) — and critically, **all 21 explicit close events in the whole week closed at exactly their own entry price**, to the cent, despite being opened at different times/prices. Ruled out a shared-trigger kill-switch (each ticket's exit price tracks only its own entry, not a common level). No SL/TP-triggered close phrasing ("stop loss triggered", etc.) appears anywhere in this journal format at all — every observed exit all week was one of these 21 breakeven closes.
- Raised **H-007** (🟡 HIGH CONFIDENCE): Apex/Zennbot flattens positions via a synchronized breakeven market-close, not broker-side SL/TP triggers. This resolves H-006's "unexplained mass-close event" flag, but also means H-006's original quantitative win-rate-vs-backtest question is *still* unanswered — the only live exits observed this week aren't the same exit mechanism as the backtests' individual SL/TP hits, so there's nothing directly comparable yet. Would need a longer live log to catch ordinary exits.
- Updated Evidence.md (E-018 added, E-017 marked superseded), Hypotheses.md (H-006 updated, H-007 added), Trade_Manager.md, Experiments.md (EXP-004), Questions.md accordingly.
- Next: file H-007 as a GitHub issue; get a longer live-account log if Melvin can pull one, to test whether the breakeven-batch pattern recurs and to finally get a comparable win-rate figure; still outstanding — ChatGPT/Grok review of all 7 hypotheses, the swing-marker video re-pass, the 22:45-vs-16:45 and `testdaashboard` questions.
