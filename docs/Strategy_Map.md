# Strategy Map

Apex trade comments/magic numbers may encode an internal strategy ID (see example in the root README's JSON sample: `"strategy": 5, "comment": "157435"`). This document maps each identified strategy ID to what is currently known about it.

## Status

🟠 HYPOTHESIS — see [H-001](Hypotheses.md#h-001-apex-operates-a-fixed-12-slot-gridlayer-identifier-per-symbol). A recurring 12-value ID pattern has been observed across 8 independent backtests plus a live terminal recording (E-012), but no ID has been confirmed to map to a *distinct behaviour* yet (only to a distinct label). [EXP-001](Experiments.md) ruled out one specific reading (fixed price levels).

## Known Identifiers

| Strategy ID | Confidence | Observed behaviour summary | Evidence | Notes |
|---|---|---|---|---|
| `15743<N>`, N = 0–11 (12 values total) | 🟠 | Recurring, reused entry-comment values on XAUUSD; not unique per trade. Frequency is uneven — in E-001 (personal 2023), ID `1574310` accounts for 1626/4017 entries (avg lot 0.088) while `157430` accounts for only 13 (avg lot 1.008). Entry-price ranges overlap almost completely across all 12 IDs (~1807–2070 for nearly every one) — see [EXP-001](Experiments.md). | E-001 through E-008, E-012, E-017 | Video (E-012) confirms these IDs appear live on both pending orders (buy stop *and* sell stop simultaneously) and open positions, not just closed backtest deals. E-017 (a genuinely-confirmed live account, unlike the withdrawn E-014) shows the *lot-size* side of this pattern live: day-1 pending orders cover eleven distinct tiers (0.04, 0.08, 0.13, 0.16, 0.21, 0.26, 0.32, 0.38, 0.42, 0.44, 0.53), each mirrored as a buy-stop/sell-stop pair — consistent with the ~12-tier grid-depth reading, though E-017's raw journal text doesn't expose the comment/magic field so the exact ID-to-lot mapping isn't directly confirmed there. |

## How to identify a strategy ID

1. Parse trades with [`scripts/trade_parser.py`](../scripts/trade_parser.py) — extract `comment` / magic number field per trade.
2. Group trades by that field using [`scripts/statistics.py`](../scripts/statistics.py).
3. For each group, compare: average SL/TP distance, average duration, symbol(s) traded, time-of-day distribution, win rate.
4. If a group shows a statistically distinct, consistent pattern vs. other groups → raise a hypothesis in [Hypotheses.md](Hypotheses.md) naming that strategy ID.
5. Cross-check the pattern against at least one independent backtest/journal source before promoting to [Findings.md](Findings.md).

## Open Questions

See [research/Questions.md](../research/Questions.md) for the running list — mirror strategy-specific open questions here as they arise.

- Why is entry frequency so uneven across the 12 IDs (1626 vs 13 in E-001), and why does it loosely inverse-correlate with lot size (EXP-001)? Working theory (untested): the ID indexes a grid depth / re-entry rung, where shallow/frequent rungs use small lots and rare/deep rungs use large (martingale-style recovery) lots — but this is speculation pending its own experiment.
- Do the 12 IDs persist as the *same* 12 values across different symbols, or are they XAUUSD-specific? Still untested — the confirmed live account (E-017) only trades XAUUSD.sc, same as every backtest.
- Is `15743` itself meaningful (e.g. derived from account/chart ID) or arbitrary?
