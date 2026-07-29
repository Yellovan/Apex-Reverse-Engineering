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

E-019's trade pairing (283 trades) found 48 `tp`-tagged exits, of which 79.2% (38) were profitable — but **21% (10 trades) show a `tp` exit reason with a net loss**, e.g. one 0.08-lot trade: entry 4036.92, tp 4012.86 (*below* entry), exit 4013.07, profit -$190.80. Two explanations, not yet distinguished:
1. **A pairing artifact.** `trade_parser.py` matches entries/exits FIFO per (symbol, side) — see the script's docstring — which can misattribute the entry price when multiple same-grid-ID positions are open concurrently on the same side (very plausible for e.g. ID `1149810`, which alone accounts for 129 of the 283 trades). The exit's own `tp`-tag and profit value are still directly observed and correct; only the *paired entry price* shown in the trade record might be wrong.
2. **A genuine adjusted-TP mechanism.** Apex might, in some grid-recovery scenario, move a position's TP to a *worse* level than the original entry (mirroring how [H-002](Hypotheses.md#h-002) shows the SL getting trailed *toward* profit — a TP getting dragged the other way, toward a controlled loss, would be a novel and symmetrical finding worth its own hypothesis if confirmed).

**Proposed test:** get a report format that includes MT5's "Position" ID column (not present in E-019's export) to pair deals unambiguously, then re-check whether these losing-TP trades persist.

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
