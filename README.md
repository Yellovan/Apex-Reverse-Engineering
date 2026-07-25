# Apex-Reverse-Engineering

**A behavioural forensic research project reconstructing the architecture of the MT5 Expert Advisor "Apex" through observation only.**

## Role Definition

This repository is not a coding project. Anyone contributing to it — human or AI — operates as a **Senior Quantitative Research Engineer**, not as a programmer. That means:

- No assumptions presented as fact.
- No marketing claims (from vendor material, videos, or sales pages) accepted at face value.
- Every claim must trace back to evidence.
- Every hypothesis must be tested before it is trusted.
- Every finding must cite its source evidence (backtest file, journal line, screenshot, video timestamp).

If it cannot be traced to evidence, it does not belong in `docs/Findings.md` — it belongs in `docs/Hypotheses.md` at best, or nowhere.

## Project Goal

This repository attempts to reconstruct the architecture of the Apex MT5 Expert Advisor using **behavioural evidence only**.

- **No reverse compilation.**
- **No binary modification.**
- **No copyright infringement.**
- **Only behavioural analysis** — backtests, journals, HTML reports, screenshots, videos, preset files, and live observations.

The `.ex5` binary is never decompiled, disassembled, patched, or redistributed. Nothing in this repository requires or grants access to Apex's source code, intellectual property, or protected logic. The goal is to understand *what the EA does*, not to obtain or reproduce *how its code is written*.

## Methodology

```
Evidence
   ↓
Hypothesis
   ↓
Experiment
   ↓
Verification
   ↓
Conclusion
```

Every conclusion in this repository must be tagged with exactly one confidence level:

| Tag | Meaning |
|---|---|
| 🟢 **CONFIRMED** | Reproduced across multiple independent evidence sources; no contradicting observation exists. |
| 🟡 **HIGH CONFIDENCE** | Strong, consistent evidence but not yet independently reproduced or cross-checked by a second reviewer. |
| 🟠 **HYPOTHESIS** | A plausible explanation for observed behaviour, not yet tested. |
| 🔴 **DISPROVEN** | Previously suspected or hypothesised, now contradicted by evidence. Kept for the record, never deleted. |

**Never mix facts with assumptions in the same statement.** If a sentence contains both, split it: state the observed fact, then separately and explicitly label the interpretation with its confidence tag.

## Repository Structure

```
Apex-Reverse-Engineering/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── Architecture.md          – current best model of Apex's internal architecture
│   ├── Findings.md               – confirmed / high-confidence conclusions only
│   ├── Hypotheses.md             – untested or partially tested explanations
│   ├── Experiments.md            – experiment log (procedure → result → conclusion)
│   ├── Evidence.md               – index of all evidence sources and what they support
│   ├── Timeline.md               – chronological research log
│   ├── Strategy_Map.md           – map of identified strategy IDs / sub-systems
│   ├── Risk_Manager.md           – risk-sizing / lot-sizing behaviour
│   ├── Portfolio_Manager.md      – multi-symbol / multi-strategy allocation behaviour
│   ├── Trade_Manager.md          – entry/exit/order lifecycle behaviour
│   ├── Swing_Detection.md        – swing-high/low or structure detection behaviour
│   ├── Pending_Orders.md         – pending order placement/cancellation behaviour
│   ├── Trailing_Stop.md          – trailing stop logic behaviour
│   └── BreakEven.md              – break-even logic behaviour
├── data/
│   ├── backtests/{2023,2024,2025}/
│   ├── journals/
│   ├── videos/
│   ├── screenshots/
│   ├── presets/
│   └── reports/
├── research/
│   ├── DailyNotes.md
│   ├── Questions.md
│   └── TODO.md
├── scripts/
│   ├── html_parser.py
│   ├── trade_parser.py
│   ├── statistics.py
│   └── compare_backtests.py
├── templates/
│   ├── Finding_Template.md
│   ├── Experiment_Template.md
│   ├── Trade_Template.md
│   └── trade_schema.json
└── output/
    ├── graphs/
    ├── csv/
    └── reports/
```

## Structured Trade Data

Parsed trades are normalised into a JSON structure (schema in [`templates/trade_schema.json`](templates/trade_schema.json)) so they can be queried programmatically instead of re-read by eye every time:

```json
{
  "strategy": 5,
  "entry": 4548.22,
  "sl": 4492.34,
  "tp": 4610.22,
  "lot": 0.32,
  "comment": "157435",
  "time": "2025-03-04T10:22",
  "source": "backtest2025"
}
```

This enables aggregate analysis once enough trades are catalogued:

- All trades belonging to a given strategy ID
- Average SL / TP distance per strategy
- Win rate per strategy (once strategies can be reliably identified)
- Average trade duration
- Average trailing-stop distance

See [`scripts/trade_parser.py`](scripts/trade_parser.py) and [`scripts/statistics.py`](scripts/statistics.py).

## Independent Review Process

Findings gain confidence through **independent replication**, not authority:

1. **Claude** — repository, documentation, parsers, Python tooling, automation.
2. **ChatGPT** — reverse engineering, pattern analysis, MQL5 architecture reasoning, hypothesis formulation and testing.
3. **Grok** — independent second reviewer. Not there to rubber-stamp — the point is to check whether an independent analysis of the *same evidence* reaches the *same conclusion*.

**Rule:** if two of the three reviewers independently reach the same conclusion from the same evidence, that finding may be promoted one confidence level (e.g. 🟠 → 🟡). Promotion to 🟢 CONFIRMED additionally requires a reproducible experiment (see `docs/Experiments.md`).

## Contributing / Workflow

1. New observation → log it in `data/` (raw) and `docs/Evidence.md` (indexed).
2. Draft an explanation → `docs/Hypotheses.md` using `templates/Finding_Template.md`.
3. Design a test → `docs/Experiments.md` using `templates/Experiment_Template.md`.
4. Run it, record the observed result (not the expected one) even if it disproves the hypothesis.
5. Promote to `docs/Findings.md` only once confidence is 🟡 or 🟢, with evidence linked.
6. Update `docs/Timeline.md` with the date and a one-line summary.

See the [Wiki](../../wiki) for the living reference (Architecture, Known Facts, Research Timeline, Open Questions, Evidence Index, Version History, Glossary).
