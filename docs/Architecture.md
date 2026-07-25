# Architecture

Current best behavioural model of Apex's internal architecture. This document is a **living model**, not a spec — every box and arrow below must trace to an entry in [Evidence.md](Evidence.md) or [Findings.md](Findings.md). Anything not yet backed by evidence belongs in [Hypotheses.md](Hypotheses.md), referenced here only as a dashed/unconfirmed block.

## Status

🟠 **HYPOTHESIS** overall — the diagram below is still unconfirmed. One 🟢 CONFIRMED structural fact has emerged, though (see next section).

## 🟢 Confirmed: Apex runs on top of a generic engine called "Zennbot"

Directly observed in all 3 preset files (E-009, E-010, E-011): each opens with `; Zennbot` / `ZennbotPresetName=...`, and every setting key is namespaced either generically (`Trading_`, `BacktestRealism_`, `Timezone_`, `MaxDrawdown_`, `ScheduledClose_`, `TimeFilter_`, `DailyProfitTarget_`, `Limits_`, `RandomizedValues_`) or `Apex_`-specific (currently only `Apex_LotSize_*`). See [H-003](Hypotheses.md#h-003-apex-is-a-strategy-configuration-preset-running-on-top-of-a-generic-multi-feature-bot-engine-called-zennbot) for the (still-hypothesis) architectural interpretation of what this split implies for the diagram below.

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
| Strategy identification | [Strategy_Map.md](Strategy_Map.md) | 🟠 not started |
| Risk / lot sizing | [Risk_Manager.md](Risk_Manager.md) | 🟠 not started |
| Multi-symbol allocation | [Portfolio_Manager.md](Portfolio_Manager.md) | 🟠 not started |
| Entry/exit lifecycle | [Trade_Manager.md](Trade_Manager.md) | 🟠 not started |
| Swing/structure detection | [Swing_Detection.md](Swing_Detection.md) | 🟠 not started |
| Pending order behaviour | [Pending_Orders.md](Pending_Orders.md) | 🟠 not started |
| Trailing stop logic | [Trailing_Stop.md](Trailing_Stop.md) | 🟠 not started |
| Break-even logic | [BreakEven.md](BreakEven.md) | 🟠 not started |

## Revision Log

| Date | Change | Author |
|---|---|---|
| 2026-07-25 | Initial skeleton created | Claude (repo scaffold) |
