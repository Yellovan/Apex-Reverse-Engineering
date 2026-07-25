# Strategy Map

Apex trade comments/magic numbers may encode an internal strategy ID (see example in the root README's JSON sample: `"strategy": 5, "comment": "157435"`). This document maps each identified strategy ID to what is currently known about it.

## Status

🟠 HYPOTHESIS — no strategy ID has been confirmed to map to a distinct, reproducible behaviour yet.

## Known Identifiers

| Strategy ID | Confidence | Observed behaviour summary | Evidence | Notes |
|---|---|---|---|---|
| _?_ | 🟠 | | | Populate as trade data accumulates in `output/csv/` |

## How to identify a strategy ID

1. Parse trades with [`scripts/trade_parser.py`](../scripts/trade_parser.py) — extract `comment` / magic number field per trade.
2. Group trades by that field using [`scripts/statistics.py`](../scripts/statistics.py).
3. For each group, compare: average SL/TP distance, average duration, symbol(s) traded, time-of-day distribution, win rate.
4. If a group shows a statistically distinct, consistent pattern vs. other groups → raise a hypothesis in [Hypotheses.md](Hypotheses.md) naming that strategy ID.
5. Cross-check the pattern against at least one independent backtest/journal source before promoting to [Findings.md](Findings.md).

## Open Questions

See [research/Questions.md](../research/Questions.md) for the running list — mirror strategy-specific open questions here as they arise.
