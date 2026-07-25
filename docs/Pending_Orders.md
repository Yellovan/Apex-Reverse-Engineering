# Pending Orders

Behavioural analysis of Apex's use of pending orders (buy/sell stop or limit) rather than direct market entries.

## Status

🟠 HYPOTHESIS — not yet investigated.

## Questions to Answer

- Does the journal/log show pending order placement events distinct from market fills?
- What is the typical distance between placement price and trigger price?
- Are pending orders cancelled/modified before triggering, and under what observed condition?
- How long do pending orders typically remain live before triggering or expiring?
- Does pending-order placement relate to [swing detection](Swing_Detection.md) levels?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `Pending Orders` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: _none indexed yet_.
