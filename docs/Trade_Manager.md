# Trade Manager

Behavioural analysis of Apex's entry/exit lifecycle: how a trade is opened, managed, and closed from signal to final exit.

## Status

🟠 HYPOTHESIS — not yet investigated.

## Questions to Answer

- What triggers an entry — is it purely price-structure based (see [Swing_Detection.md](Swing_Detection.md)), time-based, or a combination?
- Are entries market orders, or does Apex place [pending orders](Pending_Orders.md) that later trigger?
- What closes a trade: fixed TP/SL, [trailing stop](Trailing_Stop.md), [break-even](BreakEven.md) logic, a time-based exit, or an opposing signal?
- Is there a maximum trade duration observed across the evidence set?
- Does the manager scale in/out (partial closes, multiple entries per signal)?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `Trade Manager` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: _none indexed yet_.
