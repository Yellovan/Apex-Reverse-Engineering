# Risk Manager

Behavioural analysis of Apex's position-sizing / risk-management logic.

## Status

🟠 HYPOTHESIS — not yet investigated.

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

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `Risk Manager` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: _none indexed yet_.
