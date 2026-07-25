# Trailing Stop

Behavioural analysis of Apex's trailing-stop logic, if any.

## Status

🟠 HYPOTHESIS — initial evidence found, see [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl). Not yet promoted: needs a dedicated experiment (see below) and independent review before 🟡.

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

- [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl) — SL is repeatedly modified toward and past entry price rather than staying static; directly observed in the journal (E-016, position #7160: SL modified 3956.37 → 3997.85 → 4040.51, closing above the 4038.99 entry) and consistent with aggregate stats (70–77% of exits are `sl`-tagged across 8 backtests, yet win rate is 77–86%, meaning most `sl` exits are profitable).

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-001 through E-008 (aggregate exit-reason/win-rate statistics), E-016 (granular journal log showing the SL modification sequence).
