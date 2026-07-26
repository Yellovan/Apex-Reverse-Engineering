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
- [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time) — the correct live account (E-017, confirmed running Apex) hasn't had a win-rate/risk comparison computed yet (only a curated excerpt is stored so far) — this is the real successor to what H-005 was trying to answer.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-009, E-010, E-011 (preset files), E-001 through E-008 (backtests, cross-checked in EXP-003), E-014 (wrong file, withdrawn), E-017 (correct live account, H-006).
