# Research Timeline

Chronological log of research activity. One line per meaningful event (evidence added, hypothesis raised, experiment run, finding confirmed/disproven). This is the fast "what happened and when" view — details live in the linked docs.

| Date | Event | Links |
|---|---|---|
| 2026-07-25 | Repository scaffolded: structure, docs, templates, parsers, GitHub labels/board/wiki initialised | — |
| 2026-07-25 | First evidence batch (E-001–E-016) added and parsed; 4 initial hypotheses raised (H-001–H-004) | [DailyNotes](../research/DailyNotes.md), [Hypotheses](Hypotheses.md) |
| 2026-07-25 | Video/screenshot/xlsx reviewed; 3 proposed tests run as EXP-001–EXP-003; H-005 raised (live cent account shows very different behaviour from XAUUSD backtests) | [DailyNotes](../research/DailyNotes.md), [Experiments](Experiments.md), [Hypotheses](Hypotheses.md) |
| 2026-07-25 | E-014 confirmed to be the wrong file (not an Apex account, per Melvin) — H-005 withdrawn | [DailyNotes](../research/DailyNotes.md), [Evidence](Evidence.md) |
| 2026-07-26 | Correct live-account evidence received (E-017) — directly confirms Apex/Zennbot via the account's own Experts log, including a live 2.3beta1→2.4 version upgrade; H-006 raised | [DailyNotes](../research/DailyNotes.md), [Evidence](Evidence.md), [Hypotheses](Hypotheses.md) |
| 2026-07-26 | Full raw live-account logs received (E-018, supersedes E-017 excerpt); EXP-004 finds all 21 observed live closes in the week close at exactly their own entry price — H-007 raised (synchronized breakeven flatten, not a shared kill-switch) | [DailyNotes](../research/DailyNotes.md), [Evidence](Evidence.md), [Experiments](Experiments.md), [Hypotheses](Hypotheses.md) |
| 2026-07-27 | Full month structured account statement received (E-019) plus Experts-tab log, partial journal, and screenshots (E-020–E-022); `trade_parser.py` direction-aware-pairing and bracketed-exit-reason bugs found and fixed | [DailyNotes](../research/DailyNotes.md), [Evidence](Evidence.md) |
| 2026-07-27 | H-006 resolved (🟡): E-019 gives real live win-rate 89.40% and +38.2% return, matching/beating backtests' 77–86% range; SL-profitability 90.8% live vs 89.7% backtest (EXP-002) | [Hypotheses](Hypotheses.md), [Trade_Manager](Trade_Manager.md), [Risk_Manager](Risk_Manager.md) |
| 2026-07-27 | H-007 corrected: the 21 breakeven closes are one exit mechanism among several, not the week's only exits — E-019 shows 254 ordinary sl/tp exits the raw journal format couldn't distinguish from opens | [Hypotheses](Hypotheses.md), [Trade_Manager](Trade_Manager.md) |
| 2026-07-27 | E-020 (Experts-tab debug log) confirms `CTrade` class usage and literal `Zennbot: Scheduled close triggered` internal naming — 5th independent Apex/Zennbot confirmation (account metadata "Name: APEX EA"); multi-timeframe discrepancy (M30/H1/H4) flagged as open question | [Architecture](Architecture.md) |
| 2026-07-27 | `11498<N>` ID prefix found on E-019 (same 12-slot structure as backtests' `15743<N>`, different prefix — first evidence the prefix varies by account/deployment); ID `114984` is the first-observed net-losing strategy slot | [Strategy_Map](Strategy_Map.md), [Hypotheses](Hypotheses.md) |

_Add new rows at the bottom, most recent last (chronological, not reverse)._
