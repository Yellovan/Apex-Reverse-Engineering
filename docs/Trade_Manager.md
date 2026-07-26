# Trade Manager

Behavioural analysis of Apex's entry/exit lifecycle: how a trade is opened, managed, and closed from signal to final exit.

## Status

🟠 HYPOTHESIS overall, with one 🟢 CONFIRMED engine-level fact below (scheduled close), since that's directly read from preset files rather than inferred.

## 🟢 Confirmed: scheduled daily close (directly observed in preset files)

All three presets (E-009, E-010, E-011) have `ScheduledClose_Enable=true` with `ScheduledClose_Monday` through `Friday` all set to `16:45` (server/broker time per `ScheduledClose_Timezone=3`), `Saturday`/`Sunday` blank, and `ScheduledClose_CooldownMinutes=60`. This is a Zennbot engine-level feature (see [H-003](Hypotheses.md#h-003-apex-is-a-strategy-configuration-preset-running-on-top-of-a-generic-multi-feature-bot-engine-called-zennbot)), not necessarily Apex-specific logic — but it directly constrains any time-based exit analysis: trades open near end-of-day are subject to a forced close regardless of Apex's own exit logic.

**Discrepancy noted, not yet resolved:** the live journal (E-017) shows a daily burst of pending-order *cancellations* at **22:45** every day, not 16:45. This might be a separate mechanism (end-of-day pending-order cleanup vs. the preset's open-position scheduled close), a broker-timezone offset from the preset's stated time, or evidence the live account's actual preset differs from E-009/E-010/E-011. Not investigated further yet.

**Unexplained event (E-017, 2026-07-24 ~04:47–04:58):** a burst of ~19 individual "market buy, close #ticket" events over ~11 minutes, all covering SELL positions via market order as price dropped from ~4041 to ~4024. This looks like a deliberate batch close (drawdown kill-switch, grid take-profit sweep, or manual intervention) rather than the normal one-at-a-time SL/TP trigger pattern seen everywhere else in the evidence. See [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time).

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

- [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl) — most trades close via a trailed SL rather than a fixed TP or a genuine loss-cutting SL. See [Trailing_Stop.md](Trailing_Stop.md).
- [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time) — live behaviour (E-017) is broadly consistent with backtests, with one unexplained mass-close event flagged above.
- Average trade duration varies substantially by preset/year (from ~123 min in prop-2025 to ~446 min in personal-2023, per `output/csv/per_report_statistics.json`) — not yet understood whether this reflects market conditions, preset differences, or both.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-001 through E-011, E-017.
