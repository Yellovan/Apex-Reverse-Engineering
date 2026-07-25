# Trailing Stop

Behavioural analysis of Apex's trailing-stop logic, if any.

## Status

🟠 HYPOTHESIS — not yet investigated.

## Questions to Answer

- Does the SL visibly move in the direction of profit across the trade's lifetime (per journal SL-modification events)?
- Is the trailing step fixed (points/pips) or dynamic (ATR-like, structure-based)?
- At what profit threshold does trailing begin — immediately, or only after a minimum move?
- Does trailing behaviour differ per strategy ID (see [Strategy_Map.md](Strategy_Map.md))?
- Average trailing distance (see JSON schema field set) once enough trades are catalogued — compute via [`scripts/statistics.py`](../scripts/statistics.py).

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `Trailing Stop` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: _none indexed yet_.
