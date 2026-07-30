# Risk Manager

Behavioural analysis of Apex's position-sizing / risk-management logic.

## Status

🟠 HYPOTHESIS overall (per README's promotion rule). Realised-trade risk has now been analysed — see [EXP-003](Experiments.md): personal-preset trades run 9–15x the average lot size of prop-preset trades across 2023–2025, and 8–12x the average risk-per-trade, a bigger gap than the 4x `AutoLotMultiplier` difference alone would predict.

## 🟢 Confirmed: exposed preset inputs (directly read from the .set files, not inferred)

All three presets (E-009, E-010, E-011) expose the same `Apex_LotSize_*` block:
`Mode`, `Fixed`, `Percent`, `AutoLotMultiplier`, `OverrideBalance`, `CheckMargin` — plus engine-level `MaxDrawdown_*` fields (`Enable`, `Percentage`, `Amount`, `AbsoluteEquityLimit`, `RemoveEA`). Concrete values differ per preset:

| Field | personal 25k (E-009) | propfirm 25K (E-010) | ultima cent (E-011) |
|---|---|---|---|
| `Apex_LotSize_AutoLotMultiplier` | 5 | 1.25 | 8 |
| `Apex_LotSize_OverrideBalance` | 0 (live balance) | 25000 (fixed) | 0 (live balance) |
| `MaxDrawdown_Percentage` | 100 (effectively off) | 4 | 30 |
| `MaxDrawdown_AbsoluteEquityLimit` | 0 | 22750 | 0 |
| `RandomizedValues_Enable` | false | true | false |

**Update 2026-07-27 — live account's starting balance matches the personal preset exactly.** E-019's structured report shows account 31599933 started at exactly **$25,000** (2026-06-23 balance-deposit deal), matching `apex personal 25k.set` (E-009) to the dollar — good evidence this specific live account runs the *personal*, not propfirm or cent, preset variant. Margin usage stayed extremely light throughout: a live snapshot (E-022, `posities 287.png`) shows Equity $35,327.97 against only $32.42 used margin (Margin Level 108,969.68%) with one open position and ~30 pending orders resting — consistent with `MaxDrawdown_Percentage=100` (effectively off) on the personal preset.

## Open question: some `tp`-tagged exits show a loss

**Update 2026-07-30 — the pairing-artifact explanation is confirmed real (at least partially), via `trade_parser.py`'s volume-matching fix.** The original pairing logic matched entries/exits FIFO per `(symbol, side)` only, with no check that the entry's lot size actually matched the closing deal's volume. Direct proof this was a real bug, not just a plausible theory: two closing deals on 2026-07-21 (14:36:10 and 14:36:11, both **0.38 lot** @ 4060.02, `[tp 4059.95]`) had been FIFO-paired against a 0.42-lot entry (ID `114984`) and a 0.04-lot entry (ID `1149810`) — neither the right size. The real 0.38-lot entry (ID `114989`, entered 09:42:04 and 09:47:02) had been left completely unmatched. `trade_parser.py` now matches the oldest entry with a **matching volume** in the queue, not just the oldest entry regardless of size (falls back to oldest-any-size only if no volume match exists at all).

Re-running the fixed parser against E-019: this specific case is now correctly attributed (both closes → ID `114989`, matching 0.38-lot entries). **But the total tp-loss count is still 10/48** — several other cases were reshuffled to a *different* entry attribution (still same-side, same approximate time-cluster) rather than resolved to a profitable pairing. This means:
- The pairing-artifact explanation is **confirmed real** for at least the one directly-verified case.
- It does **not fully explain** the anomaly — some residual tp-tagged losses persist even with volume-aware matching, most plausibly because *multiple entries of the identical volume* were open concurrently on the same side at some of these moments (which volume-matching alone can't disambiguate — would need MT5's actual Position ID, still absent from this report format).
- The **aggregate stats are unaffected either way** (89.40% win rate, same total profit) — pairing only affects which entry price/duration/ID gets attributed to a given exit in the per-trade record; the exit's own `tp`-tag and profit value always came directly from the deal's own fields, never from the pairing logic.

**Still open:** whether the remaining ~8 residual cases are further unresolved pairing ambiguity or a genuine adjusted-TP mechanism (mirroring [H-002](Hypotheses.md#h-002)'s SL-trailing-into-profit, but toward a controlled loss instead). A report format with MT5's Position ID column would settle this definitively; the live `ApexLogger` (now correctly capturing per-deal reasons and position IDs, [Trade_Manager.md](Trade_Manager.md)) will provide this going forward.

## Questions to Answer

- Is lot size fixed, or does it scale with account equity/balance?
- Is risk-per-trade a fixed percentage, or fixed cash amount, or fixed lot?
- Does risk change per strategy ID (see [Strategy_Map.md](Strategy_Map.md))?
- Does risk change based on open exposure (martingale/anti-martingale behaviour after wins/losses)?
- Does the preset (`.set`) file expose a risk input that visibly correlates with observed lot sizes?
- Is there a maximum-exposure cap across simultaneously open trades?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

- [H-004](Hypotheses.md#h-004-apexs-propfirm-preset-trades-meaningfully-more-conservatively-than-its-personal-account-preset) — propfirm preset is configured for materially lower risk, and [EXP-003](Experiments.md) confirms this shows up in realised trade data too: avg lot 0.351/0.370/0.258 (personal, 2023/24/25) vs 0.040/0.033/0.024 (prop) — personal risks roughly 9–15x more per trade by lot size, 8–12x more by €-risk (`|entry-sl|×lot`). The gap exceeds the 4x `AutoLotMultiplier` difference alone, suggesting `OverrideBalance` or compounding effects amplify it further (untested which).
- ~~H-005~~ — ⚠️ withdrawn 2026-07-25: E-014 turned out to be the wrong file (no MarketsVox/Ultima Markets account actually runs Apex, per Melvin). Do not cite the numbers previously listed here.
- [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time) — 🟡 **resolved 2026-07-27**: real win-rate/risk comparison now computed from E-019 (89.40% win rate, +38.2% over one month) — matches/beats the backtests. See H-006's full write-up.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-009, E-010, E-011 (preset files), E-001 through E-008 (backtests, cross-checked in EXP-003), E-014 (wrong file, withdrawn), E-017 through E-022 (correct live account, H-006, H-007).
