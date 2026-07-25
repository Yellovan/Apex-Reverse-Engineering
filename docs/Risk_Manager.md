# Risk Manager

Behavioural analysis of Apex's position-sizing / risk-management logic.

## Status

🟠 HYPOTHESIS — preset-level configuration differences found, see [H-004](Hypotheses.md#h-004-apexs-propfirm-preset-trades-meaningfully-more-conservatively-than-its-personal-account-preset). Realised-trade risk (actual lot sizes/exposure in the parsed trade data) not yet analysed.

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

- [H-004](Hypotheses.md#h-004-apexs-propfirm-preset-trades-meaningfully-more-conservatively-than-its-personal-account-preset) — propfirm preset is configured for materially lower risk (tighter drawdown limit, lower auto-lot multiplier, fixed reference balance for sizing, randomized values for anti-detection), but this hasn't yet been confirmed to show up as lower realised risk in the actual trade data.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-009, E-010, E-011 (preset files), E-001 through E-008 (backtests to cross-check realised risk against).
