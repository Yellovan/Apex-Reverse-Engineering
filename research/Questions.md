# Open Questions

Running list of unanswered questions, independent of which sub-system doc they'll eventually belong to. Move a question to the relevant `docs/*.md` file's "Questions to Answer" section once it's scoped to a specific sub-system; keep a pointer here until it's answered.

## Unscoped / General

- ~~What is the full set of raw evidence currently available (backtests, journals, videos, screenshots, presets)?~~ → catalogued in [docs/Evidence.md](../docs/Evidence.md) (E-001–E-016, 2026-07-25).
- What preset (`.set`) inputs are exposed to the end user, and do their names hint at internal logic (e.g. `TrailingStart`, `RiskPercent`, `MaxTrades`)? Partially answered — see [docs/Risk_Manager.md](../docs/Risk_Manager.md) for the `Apex_LotSize_*`/`MaxDrawdown_*` fields found so far; no grid/trail-specific preset fields have turned up yet.
- Is Apex a single monolithic strategy, or a bundle of multiple internal strategies switched by ID (see [docs/Strategy_Map.md](../docs/Strategy_Map.md))?
- **[new 2026-07-26]** Why does the live account (E-018) show pending-order cleanup at 22:45 daily, when the presets' `ScheduledClose_*` fields all say 16:45? See [docs/Trade_Manager.md](../docs/Trade_Manager.md).
- **[new 2026-07-26]** What is `testdaashboard` (the second EA running alongside Apex on the live account in E-018)? Monitoring tool, unrelated bot, or something that interacts with Apex?
- **[new 2026-07-26]** Does the H-007 breakeven-batch-close pattern recur regularly (same time of day / same trigger), or was 2026-07-24's event a one-off? Needs a longer log to check.

## Per Sub-system

See the "Questions to Answer" section in each of:
- [docs/Risk_Manager.md](../docs/Risk_Manager.md)
- [docs/Portfolio_Manager.md](../docs/Portfolio_Manager.md)
- [docs/Trade_Manager.md](../docs/Trade_Manager.md)
- [docs/Swing_Detection.md](../docs/Swing_Detection.md)
- [docs/Pending_Orders.md](../docs/Pending_Orders.md)
- [docs/Trailing_Stop.md](../docs/Trailing_Stop.md)
- [docs/BreakEven.md](../docs/BreakEven.md)

## Answered

- ~~Does the live "Ultima Markets personal cent" account (E-014) actually run Apex/Zennbot at all?~~ → **No** (that specific account/file didn't). Melvin confirmed 2026-07-25 there is no MarketsVox/Ultima Markets account matching E-014 running Apex — it was the wrong file. [H-005](../docs/Hypotheses.md) withdrawn. See [docs/Evidence.md](../docs/Evidence.md#e-014).
- ~~Is there a live Apex account we can use for a real backtest-vs-live comparison?~~ → **Yes, confirmed 2026-07-26.** Account 31599933, Ultima Markets Ltd, directly names `ZennbotApex2.3beta1`/`ZennbotApex2.4` in its Experts log (E-017, later superseded by the complete raw logs E-018). Raised as [H-006](../docs/Hypotheses.md#h-006) — but note the actual quantitative win-rate comparison is still unanswered (see H-006's 2026-07-26 update), since the only observed live exits this week were a different mechanism (H-007) than the backtests' individual SL/TP hits.
- ~~What caused the mass-close event in the live account's log (2026-07-24, ~04:47–04:58, ~19 positions closed via market order over ~11 minutes)?~~ → **A synchronized breakeven flatten, not a shared kill-switch.** Every one of the 21 traceable closes in the full week (E-018) closed at exactly its own entry price, independent of the other closes. Raised as [H-007](../docs/Hypotheses.md#h-007). See [docs/Trade_Manager.md](../docs/Trade_Manager.md).
