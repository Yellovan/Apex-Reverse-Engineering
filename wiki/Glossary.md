# Glossary

Terms used throughout this research project.

| Term | Meaning |
|---|---|
| **Apex** | The MT5 Expert Advisor under investigation. Referred to only by observed behaviour — its `.ex5` binary/source is never accessed. |
| **Behavioural analysis** | Drawing conclusions purely from external, observable outputs (trades, logs, reports) rather than source code. |
| **Confidence tag** | One of 🟢 CONFIRMED / 🟡 HIGH CONFIDENCE / 🟠 HYPOTHESIS / 🔴 DISPROVEN. Every conclusion must carry exactly one. |
| **Deal** | An MT5 execution record (fill) — a position "in" (open) or "out" (close). See `scripts/html_parser.py`. |
| **Evidence ID (E-###)** | Stable identifier assigned to a raw evidence file in `docs/Evidence.md`. |
| **Experiment (EXP-###)** | A designed, reproducible test of a specific hypothesis, logged in `docs/Experiments.md`. |
| **Finding (F-###)** | A conclusion promoted out of Hypotheses once confidence reaches 🟡 or 🟢, logged in `docs/Findings.md`. |
| **Hypothesis (H-###)** | An untested or partially tested explanation for observed behaviour, logged in `docs/Hypotheses.md`. |
| **Magic number / comment** | The numeric/string tag MT5 attaches to an order, used here as a candidate signal for identifying internal strategy IDs (see [Strategy Map](Architecture.md)). |
| **Round-trip trade** | A paired entry ("in" deal) and exit ("out" deal) forming one complete trade, as reconstructed by `scripts/trade_parser.py`. |
| **Strategy ID** | A hypothesised internal sub-strategy identifier within Apex, inferred from trade comments/magic numbers. Not confirmed to exist as a distinct mechanism until evidenced. |

_Add a term whenever new project-specific vocabulary is introduced — keep definitions to one or two sentences._
