# Open Questions

Running list of unanswered questions, independent of which sub-system doc they'll eventually belong to. Move a question to the relevant `docs/*.md` file's "Questions to Answer" section once it's scoped to a specific sub-system; keep a pointer here until it's answered.

## Unscoped / General

- ~~What is the full set of raw evidence currently available (backtests, journals, videos, screenshots, presets)?~~ → catalogued in [docs/Evidence.md](../docs/Evidence.md) (E-001–E-016, 2026-07-25).
- What preset (`.set`) inputs are exposed to the end user, and do their names hint at internal logic (e.g. `TrailingStart`, `RiskPercent`, `MaxTrades`)? Partially answered — see [docs/Risk_Manager.md](../docs/Risk_Manager.md) for the `Apex_LotSize_*`/`MaxDrawdown_*` fields found so far; no grid/trail-specific preset fields have turned up yet.
- Is Apex a single monolithic strategy, or a bundle of multiple internal strategies switched by ID (see [docs/Strategy_Map.md](../docs/Strategy_Map.md))?
- **[new 2026-07-26]** Why does the live account (E-018) show pending-order cleanup at 22:45 daily, when the presets' `ScheduledClose_*` fields all say 16:45? See [docs/Trade_Manager.md](../docs/Trade_Manager.md).
- **[new 2026-07-26]** What is `testdaashboard` (the second EA running alongside Apex on the live account in E-018)? Monitoring tool, unrelated bot, or something that interacts with Apex?
- **[new 2026-07-26]** Does the H-007 breakeven-batch-close pattern recur regularly (same time of day / same trigger), or was 2026-07-24's event a one-off? Needs a longer log to check. Partially answered by E-019: no second batch-close event of the same signature (~19-21 positions, all at exact entry price) shows up elsewhere in the month's structured deals, so 2026-07-24 looks more like an occasional/conditional event than a daily routine — but E-019's format doesn't make batch-vs-individual closes as visually obvious as the raw journal did, so this is tentative.
- **[new 2026-07-27]** Why does the same EA/account show three different timeframe tags across evidence — `M30` (E-017/E-018 expert-loaded lines), `H1` (E-020 OrderSend lines), `H4` (E-022 `h4.png` chart)? See [docs/Architecture.md](../docs/Architecture.md) open question.
- **[new 2026-07-27]** Why do 10 of 48 `tp`-tagged exits in E-019 show a net loss? See [docs/Risk_Manager.md](../docs/Risk_Manager.md) open question — pairing artifact vs. genuine adjusted-TP mechanism, not yet distinguished.
- **[new 2026-07-27]** Why did strategy ID `114984` lose money overall (n=8, 75% win rate, -$1835.90) while every other ID in E-019 was net profitable? See [docs/Strategy_Map.md](../docs/Strategy_Map.md) open question.

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
- ~~Is there a live Apex account we can use for a real backtest-vs-live comparison?~~ → **Yes, confirmed 2026-07-26, quantitatively resolved 2026-07-27.** Account 31599933, Ultima Markets Ltd, directly names `ZennbotApex2.3beta1`/`ZennbotApex2.4` in its Experts log (E-017/E-018). E-019 (a full month's structured statement) finally gave real numbers: 89.40% win rate and +38.2% return live, vs. 77–86% win rate across the backtests — live matches/beats backtest. See [H-006](../docs/Hypotheses.md#h-006) (now 🟡 HIGH CONFIDENCE) and [docs/Trade_Manager.md](../docs/Trade_Manager.md).
- ~~What caused the mass-close event in the live account's log (2026-07-24, ~04:47–04:58, ~19 positions closed via market order over ~11 minutes)?~~ → **A synchronized breakeven flatten, not a shared kill-switch.** Every one of the 21 traceable closes in the full week (E-018) closed at exactly its own entry price, independent of the other closes. Raised as [H-007](../docs/Hypotheses.md#h-007). **Correction 2026-07-27:** the original write-up also claimed these 21 closes were the *only* exits that week — E-019 disproved that (254 ordinary sl/tp exits occurred over the month; the raw journal format just can't tell opens from closes). The breakeven-batch finding itself still stands; it's one exit mechanism among several, not the only one. See [docs/Trade_Manager.md](../docs/Trade_Manager.md).
