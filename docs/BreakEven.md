# Break-Even

Behavioural analysis of Apex's break-even logic, if any (moving SL to entry, or entry + a small buffer, once a trade is sufficiently in profit).

## Status

🟠 HYPOTHESIS — not yet investigated.

## Questions to Answer

- Does the journal show an SL modification that lands at/near the original entry price mid-trade?
- At what profit threshold (points, % of TP distance, or R-multiple) does break-even trigger?
- Is there a buffer beyond pure entry price (spread/commission offset)?
- Does break-even interact with [trailing stop](Trailing_Stop.md) — i.e. is break-even a special case of trailing, or a separate mechanism entirely?
- Does behaviour differ per strategy ID (see [Strategy_Map.md](Strategy_Map.md))?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `BreakEven` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: _none indexed yet_.
