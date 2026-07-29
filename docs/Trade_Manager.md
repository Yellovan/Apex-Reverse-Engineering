# Trade Manager

Behavioural analysis of Apex's entry/exit lifecycle: how a trade is opened, managed, and closed from signal to final exit.

## Status

🟠 HYPOTHESIS overall, with one 🟢 CONFIRMED engine-level fact below (scheduled close), since that's directly read from preset files rather than inferred.

## 🟢 Confirmed: scheduled daily close (directly observed in preset files)

All three presets (E-009, E-010, E-011) have `ScheduledClose_Enable=true` with `ScheduledClose_Monday` through `Friday` all set to `16:45` (server/broker time per `ScheduledClose_Timezone=3`), `Saturday`/`Sunday` blank, and `ScheduledClose_CooldownMinutes=60`. This is a Zennbot engine-level feature (see [H-003](Hypotheses.md#h-003-apex-is-a-strategy-configuration-preset-running-on-top-of-a-generic-multi-feature-bot-engine-called-zennbot)), not necessarily Apex-specific logic — but it directly constrains any time-based exit analysis: trades open near end-of-day are subject to a forced close regardless of Apex's own exit logic.

**Discrepancy noted, not yet resolved:** the live journal (E-018) shows a daily burst of pending-order *cancellations* at **22:45** every day, not 16:45. This might be a separate mechanism (end-of-day pending-order cleanup vs. the preset's open-position scheduled close), a broker-timezone offset from the preset's stated time, or evidence the live account's actual preset differs from E-009/E-010/E-011. Not investigated further yet.

## 🟡 High confidence: positions close via a synchronized breakeven batch, not individual SL/TP triggers — as ONE of several exit mechanisms

**Resolved 2026-07-26, corrected 2026-07-27** (previously flagged as an unexplained mass-close event). Quantitative analysis of the complete week's raw logs (E-018, via [`scripts/journal_log_parser.py`](../scripts/journal_log_parser.py)) found **21 explicit close events in the whole week, and all 21 closed at exactly their own position's entry price** — zero net price movement, to the cent, on every single one. This part still stands. See [H-007](Hypotheses.md#h-007) for the full write-up.

**Correction (2026-07-27):** the original write-up also claimed these 21 breakeven closes were the *only* exits observed all week, based on there being no "triggered"/"stop loss"/"take profit" phrasing anywhere in E-018's raw Trades-tab log. **That conclusion doesn't hold up against E-019** (a full month's *structured* account statement for the same account), which shows 206 individual `sl`-tagged and 48 individual `tp`-tagged exits over the month — ordinary SL/TP closes clearly happen regularly on this account. The real explanation is a limitation of the raw Trades-tab journal *format*, not an absence of ordinary exits: a closing deal and an opening deal look identical in that log (`deal #X ... done (based on order #Y)`), with nothing distinguishing "Y was a fresh pending-order placement" from "Y was a broker-generated SL/TP-trigger order." `journal_log_parser.py`'s EXP-004 analysis had no way to tell these apart and likely mislabeled some real closes as "fills" (entries) in its 176-count. The structured report (E-019) doesn't have this ambiguity — its Deals table tags each closing deal's *reason* directly in the comment field (`[sl X.XX]` / `[tp X.XX]`), which the raw journal format simply never shows.

**What's still true:** the 21-position breakeven batch on 2026-07-24 is real and directly verified (both the raw log's explicit `market ..., close #ticket` phrasing and the exact-entry-price match are unambiguous). What's corrected: it's one identified exit mechanism among others (ordinary SL/TP hits, confirmed via E-019, are the *majority* mechanism — 254 of 283 trades in the month), not the account's only way of closing positions.

## Questions to Answer

- What triggers an entry — is it purely price-structure based (see [Swing_Detection.md](Swing_Detection.md)), time-based, or a combination?
- Are entries market orders, or does Apex place [pending orders](Pending_Orders.md) that later trigger?
- What closes a trade: fixed TP/SL, [trailing stop](Trailing_Stop.md), [break-even](BreakEven.md) logic, a time-based exit, or an opposing signal?
- Is there a maximum trade duration observed across the evidence set?
- Does the manager scale in/out (partial closes, multiple entries per signal)?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

- [H-007](Hypotheses.md#h-007) — the only 21 close events observed in a full live trading week all closed at exactly their own entry price (breakeven), a synchronized batch rather than individual SL/TP hits. Directly measured, not inferred; still needs cross-reviewer agreement per the promotion rule.

## Hypotheses (🟠) / High Confidence (🟡)

- [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl) — 🟡 most trades close via a trailed SL rather than a fixed TP or a genuine loss-cutting SL, corroborated in both backtest (EXP-002, 89.7%) and live (E-019, 90.8%) data. See [Trailing_Stop.md](Trailing_Stop.md).
- [H-006](Hypotheses.md#h-006-live-xauusdsc-trading-e-017-is-broadly-consistent-with-the-backtests-gridtrailing-behaviour-on-the-same-symbol-this-time) — 🟡 **resolved 2026-07-27**: E-019's real month-long win rate (89.40%) matches/beats the backtests' 77–86% range, and total return was +38.2%. See H-006's full comparison table.
- Average trade duration varies substantially by preset/year (from ~123 min in prop-2025 to ~446 min in personal-2023, per `output/csv/per_report_statistics.json`) — live E-019 trades average 136.8 min, roughly in the middle of that range.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-001 through E-011, E-017 through E-022.
