# Open Questions

Running list of unanswered questions, independent of which sub-system doc they'll eventually belong to. Move a question to the relevant `docs/*.md` file's "Questions to Answer" section once it's scoped to a specific sub-system; keep a pointer here until it's answered.

## Unscoped / General

- ~~What is the full set of raw evidence currently available (backtests, journals, videos, screenshots, presets)?~~ → catalogued in [docs/Evidence.md](../docs/Evidence.md) (E-001–E-016, 2026-07-25).
- What preset (`.set`) inputs are exposed to the end user, and do their names hint at internal logic (e.g. `TrailingStart`, `RiskPercent`, `MaxTrades`)? Partially answered — see [docs/Risk_Manager.md](../docs/Risk_Manager.md) for the `Apex_LotSize_*`/`MaxDrawdown_*` fields found so far; no grid/trail-specific preset fields have turned up yet.
- Is Apex a single monolithic strategy, or a bundle of multiple internal strategies switched by ID (see [docs/Strategy_Map.md](../docs/Strategy_Map.md))?
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

- ~~Does the live "Ultima Markets personal cent" account (E-014) actually run Apex/Zennbot at all?~~ → **No.** Melvin confirmed 2026-07-25 there is no MarketsVox/Ultima Markets account running Apex — E-014 was the wrong file, mistakenly included in the evidence batch. [H-005](../docs/Hypotheses.md) withdrawn pending a corrected upload. See [docs/Evidence.md](../docs/Evidence.md#e-014) and [docs/Risk_Manager.md](../docs/Risk_Manager.md).
