# TODO

Actionable next steps for the research effort itself (not findings — process tasks).

## Now

- [ ] Collect and drop in first batch of real evidence: backtests, journals, presets, screenshots, videos into `data/`.
- [ ] Index each item in [docs/Evidence.md](../docs/Evidence.md) with an `E-###` ID.
- [ ] Run [`scripts/html_parser.py`](../scripts/html_parser.py) on the first Strategy Tester report to validate the parser against a real file.
- [ ] Run [`scripts/trade_parser.py`](../scripts/trade_parser.py) to produce the first structured trade JSON in `output/csv/`.

## Next

- [ ] Draft first hypotheses in [docs/Hypotheses.md](../docs/Hypotheses.md) once enough evidence is catalogued.
- [ ] Share the evidence set with ChatGPT and Grok for independent review (see README's Independent Review Process).
- [ ] Design first experiments in [docs/Experiments.md](../docs/Experiments.md).

## Later

- [ ] Populate [docs/Strategy_Map.md](../docs/Strategy_Map.md) once strategy IDs are identifiable in trade comments/magic numbers.
- [ ] Build first aggregate stats (win rate per strategy, avg SL/TP, avg duration, avg trailing distance) via [`scripts/statistics.py`](../scripts/statistics.py).
- [ ] Cross-backtest comparison across 2023/2024/2025 via [`scripts/compare_backtests.py`](../scripts/compare_backtests.py).
