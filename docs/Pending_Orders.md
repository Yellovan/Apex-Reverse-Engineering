# Pending Orders

Behavioural analysis of Apex's use of pending orders (buy/sell stop or limit) rather than direct market entries.

## Status

🟠 HYPOTHESIS — first direct visual evidence found in the video (E-012), not yet quantified from journal/backtest data.

## 🟠 First observation (video, not yet cross-checked against journal timing data)

Frames from E-012 show Apex placing **multiple simultaneous pending orders on both sides of price at once** — e.g. one frame shows 5 live `buy stop` orders at once (different prices/lots/SL/TP, comments `157437`/`1574311`/`157431`/`157432`/`157434`), and a later frame in the same session shows `sell stop` orders placed too, at the same time as buy stops exist. This looks like a two-sided straddle grid (pending orders both above and below current price simultaneously), not a single-direction ladder — see [H-001's 2026-07-25 update](Hypotheses.md#h-001-apex-operates-a-fixed-12-slot-gridlayer-identifier-per-symbol). Not yet quantified: typical placement-to-trigger distance, or how often pending orders get cancelled/replaced vs. left to trigger or expire (the backtests do show `canceled` status orders in the raw Orders section, per the very first inspection of E-001's HTML — worth a dedicated pass).

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

_No formal H-### entry raised for this yet — the video observation above needs a dedicated hypothesis once the journal/backtest data is cross-checked against it._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-012 (video).
