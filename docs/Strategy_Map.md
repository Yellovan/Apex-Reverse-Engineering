# Strategy Map

Apex trade comments/magic numbers may encode an internal strategy ID (see example in the root README's JSON sample: `"strategy": 5, "comment": "157435"`). This document maps each identified strategy ID to what is currently known about it.

## Status

🟠 HYPOTHESIS — see [H-001](Hypotheses.md#h-001-apex-operates-a-fixed-12-slot-gridlayer-identifier-per-symbol). A recurring 12-value ID pattern has been observed across 8 independent backtests, but no ID has been confirmed to map to a *distinct behaviour* yet (only to a distinct label).

## Known Identifiers

| Strategy ID | Confidence | Observed behaviour summary | Evidence | Notes |
|---|---|---|---|---|
| `15743<N>`, N = 0–11 (12 values total) | 🟠 | Recurring, reused entry-comment values on XAUUSD; not unique per trade. Frequency is uneven — in E-001 (personal 2023), ID `1574310` accounts for 1626/4017 entries while `157430` accounts for only 13. | E-001 through E-008 | Uneven frequency across the 12 IDs is itself unexplained — see Open Questions below. |

## How to identify a strategy ID

1. Parse trades with [`scripts/trade_parser.py`](../scripts/trade_parser.py) — extract `comment` / magic number field per trade.
2. Group trades by that field using [`scripts/statistics.py`](../scripts/statistics.py).
3. For each group, compare: average SL/TP distance, average duration, symbol(s) traded, time-of-day distribution, win rate.
4. If a group shows a statistically distinct, consistent pattern vs. other groups → raise a hypothesis in [Hypotheses.md](Hypotheses.md) naming that strategy ID.
5. Cross-check the pattern against at least one independent backtest/journal source before promoting to [Findings.md](Findings.md).

## Open Questions

See [research/Questions.md](../research/Questions.md) for the running list — mirror strategy-specific open questions here as they arise.

- Why is entry frequency so uneven across the 12 IDs (1626 vs 13 in E-001)? Grid distance from current price at signal time? Some kind of priority/weighting?
- Do the 12 IDs persist as the *same* 12 values across different symbols, or are they XAUUSD-specific? Untested — no other symbol has appeared in any evidence yet.
- Is `15743` itself meaningful (e.g. derived from account/chart ID) or arbitrary?
