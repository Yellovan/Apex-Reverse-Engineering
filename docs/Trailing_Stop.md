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

**Break-even trigger and trail step size, measured across 3 independent live accounts, 2026-07-30.** For each fill+modify sequence, the SL's distance from entry at its first move to the profit side (the "BE lock") and the size of each subsequent favorable adjustment (the "trail step") were computed directly from real SL-modify events — no fitting, no inference:

| Account | Matched tickets | BE lock (median) | Trail step (median) |
|---|---|---|---|
| ultima_live (Ultima Markets) | 1554 | 1.07 | 1.24 |
| funden_propfirm | 104 | 1.06 | 1.03 |
| roboforex_live (RoboForex) | 246 | 1.07 | 0.95 |

The BE-lock trigger is remarkably consistent (1.06–1.07 across three different brokers/accounts) — strong evidence this is a fixed Apex/Zennbot constant, not something tuned per account. Trail step is a bit more variable (0.95–1.24) but stays in the same narrow band. This is a **continuous, fine-grained trailing model** (SL nudged by roughly one point at a time, very frequently — the 1554-ticket ultima_live sample alone came from 40,274 total modify events) rather than the discrete, chunky step-then-jump behaviour the earlier `v1.21` EA reconstruction draft assumed; `ea_drafts/ZennApex_XAU_v2.mq5` was rebuilt around a continuous-trailing-distance model to match.

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

- [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl) — SL is repeatedly modified toward and past entry price rather than staying static. [EXP-002](Experiments.md) quantified this: 89.7% of 78 SL-triggered closes in E-016 had a positive signed displacement (avg +0.503 price units on the profitable side), average 37 modification events per affected position. ~10.3% were genuine losing stop-outs, so the mechanism isn't risk-free, just dominant.
- [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time) — the same granular trailing pattern (SL nudged upward every 1–3 minutes) appears in E-017, a confirmed live account, not just backtests — see the representative sequence for position #369272106/#369469998 on 2026.07.22.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-001 through E-008 (aggregate exit-reason/win-rate statistics), E-016 (granular journal log showing the SL modification sequence), E-017 (live journal, same trailing pattern), 2026-07-30 raw journal batch across 3 accounts (ultima_live/funden_propfirm/roboforex_live, not yet assigned individual Evidence IDs — see research/DailyNotes.md).
