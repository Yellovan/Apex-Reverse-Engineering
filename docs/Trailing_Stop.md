# Trailing Stop

Behavioural analysis of Apex's trailing-stop logic, if any.

## Status

🟠 HYPOTHESIS overall (per README's promotion rule — needs ChatGPT/Grok agreement, not just Claude, before this can be a Finding). Internally the evidence is now strong: [EXP-002](Experiments.md) found 89.7% of SL-triggered closes (70/78, one journal file) had the SL on the profitable side of entry at trigger, with an average of 37 SL-modification events per affected position (max 378 on one position) — i.e. continuous, granular trailing, not an occasional break-even jump.

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

- [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl) — SL is repeatedly modified toward and past entry price rather than staying static. [EXP-002](Experiments.md) quantified this: 89.7% of 78 SL-triggered closes in E-016 had a positive signed displacement (avg +0.503 price units on the profitable side), average 37 modification events per affected position. ~10.3% were genuine losing stop-outs, so the mechanism isn't risk-free, just dominant.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-001 through E-008 (aggregate exit-reason/win-rate statistics), E-016 (granular journal log showing the SL modification sequence).
