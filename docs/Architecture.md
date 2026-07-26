# Architecture

Current best behavioural model of Apex's internal architecture. This document is a **living model**, not a spec — every box and arrow below must trace to an entry in [Evidence.md](Evidence.md) or [Findings.md](Findings.md). Anything not yet backed by evidence belongs in [Hypotheses.md](Hypotheses.md), referenced here only as a dashed/unconfirmed block.

## Status

🟠 **HYPOTHESIS** overall — the diagram below is still unconfirmed. One 🟢 CONFIRMED structural fact has emerged, though (see next section).

## 🟢 Confirmed: Apex runs on top of a generic engine called "Zennbot"

Directly observed in all 3 preset files (E-009, E-010, E-011): each opens with `; Zennbot` / `ZennbotPresetName=...`, and every setting key is namespaced either generically (`Trading_`, `BacktestRealism_`, `Timezone_`, `MaxDrawdown_`, `ScheduledClose_`, `TimeFilter_`, `DailyProfitTarget_`, `Limits_`, `RandomizedValues_`) or `Apex_`-specific (currently only `Apex_LotSize_*`). See [H-003](Hypotheses.md#h-003-apex-is-a-strategy-configuration-preset-running-on-top-of-a-generic-multi-feature-bot-engine-called-zennbot) for the (still-hypothesis) architectural interpretation of what this split implies for the diagram below.

Confirmed four independent ways as of 2026-07-26: the 3 preset files' text, the Strategy Tester settings dialog's Expert dropdown (`ZennbotApex2.4.ex5`, E-013), the video's in-terminal overlay (E-012), and — the strongest of the four, since it's the platform's own record rather than a UI label — a live account's Experts log (E-017) showing `ZennbotApex2.3beta1` being removed and `ZennbotApex2.4` being loaded on the same machine a few hours later, i.e. a real version upgrade caught in the act.

## Working Model (draft)

```
                ┌─────────────────────┐
                │   Portfolio Manager  │  (see Portfolio_Manager.md)
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │    Strategy Map      │  (see Strategy_Map.md)
                │  (multiple internal  │
                │   sub-strategies?)   │
                └──────────┬──────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼──────┐  ┌────────▼───────┐  ┌───────▼───────┐
│ Swing         │  │ Trade Manager   │  │ Risk Manager   │
│ Detection     │  │ (entries/exits) │  │ (lot sizing)   │
└───────────────┘  └────────┬───────┘  └───────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
        ┌───────▼──────┐ ┌───▼────┐ ┌────▼─────┐
        │ Pending       │ │Trailing│ │ BreakEven │
        │ Orders        │ │ Stop   │ │           │
        └───────────────┘ └────────┘ └───────────┘
```

Each sub-system above has its own document with its own confidence-tagged findings. This diagram itself is 🟠 HYPOTHESIS until each connection is independently supported by evidence.

## Sub-system Index

| Module | Doc | Status |
|---|---|---|
| Strategy identification | [Strategy_Map.md](Strategy_Map.md) | 🟠 12-tier grid-depth reading, live+backtest confirmed |
| Risk / lot sizing | [Risk_Manager.md](Risk_Manager.md) | 🟠 preset diffs confirmed, realised-risk gap quantified (EXP-003) |
| Multi-symbol allocation | [Portfolio_Manager.md](Portfolio_Manager.md) | 🟠 not started |
| Entry/exit lifecycle | [Trade_Manager.md](Trade_Manager.md) | 🟢 scheduled close confirmed; 🟠 mass-close event unexplained |
| Swing/structure detection | [Swing_Detection.md](Swing_Detection.md) | 🟠 tentative visual lead only |
| Pending order behaviour | [Pending_Orders.md](Pending_Orders.md) | 🟠 two-sided grid placement observed |
| Trailing stop logic | [Trailing_Stop.md](Trailing_Stop.md) | 🟠 quantified in backtest + live (EXP-002) |
| Break-even logic | [BreakEven.md](BreakEven.md) | 🟠 not started |

## Revision Log

| Date | Change | Author |
|---|---|---|
| 2026-07-25 | Initial skeleton created | Claude (repo scaffold) |
| 2026-07-25 | First evidence batch analysed, H-001–H-005 raised (H-005 later withdrawn) | Claude |
| 2026-07-26 | Correct live-account evidence (E-017) received, H-006 raised, 4th confirmation of Zennbot/Apex naming | Claude |
