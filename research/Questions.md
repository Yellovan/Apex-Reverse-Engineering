# Open Questions

Running list of unanswered questions, independent of which sub-system doc they'll eventually belong to. Move a question to the relevant `docs/*.md` file's "Questions to Answer" section once it's scoped to a specific sub-system; keep a pointer here until it's answered.

## Unscoped / General

- ~~What is the full set of raw evidence currently available (backtests, journals, videos, screenshots, presets)?~~ → catalogued in [docs/Evidence.md](../docs/Evidence.md) (E-001–E-016, 2026-07-25).
- What preset (`.set`) inputs are exposed to the end user, and do their names hint at internal logic (e.g. `TrailingStart`, `RiskPercent`, `MaxTrades`)? Partially answered — see [docs/Risk_Manager.md](../docs/Risk_Manager.md) for the `Apex_LotSize_*`/`MaxDrawdown_*` fields found so far; no grid/trail-specific preset fields have turned up yet.
- Is Apex a single monolithic strategy, or a bundle of multiple internal strategies switched by ID (see [docs/Strategy_Map.md](../docs/Strategy_Map.md))?
- **[HIGH PRIORITY, new 2026-07-25]** Does the live "Ultima Markets personal cent" account (E-014) actually run Apex/Zennbot at all? No EA name/magic number appears in that export — the only link to Apex is a matching filename convention with preset E-011. This needs a direct answer (ask Melvin, or find corroborating evidence) before [H-005](../docs/Hypotheses.md) can be trusted as being about Apex specifically rather than an unrelated account. See [docs/Risk_Manager.md](../docs/Risk_Manager.md).
- If E-014 does turn out to be Apex: why does it trade an entirely different symbol set (8 forex cent-pairs) than every backtest (XAUUSD only), and why is its comment/magic-tagging behaviour (11/19502 deals tagged) so different from the backtests (near-universal tagging)?

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

_None yet — move a question here with a link to the finding that answered it once resolved._
