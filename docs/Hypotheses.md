# Hypotheses

Untested or partially tested explanations for observed Apex behaviour. Every entry here is 🟠 unless explicitly marked 🔴 after being disproven (disproven entries stay here, struck through, they are never deleted — they are evidence that a path was already ruled out).

Use the [Finding Template](../templates/Finding_Template.md) for structure. A hypothesis is promoted to [Findings.md](Findings.md) only after a logged, reproducible experiment in [Experiments.md](Experiments.md) raises its confidence to 🟡 or 🟢.

## Open Hypotheses (🟠)

### H-001 — Apex operates a fixed 12-slot grid/layer identifier per symbol

**Status:** 🟠 HYPOTHESIS
**Category:** Strategy Map
**Raised:** 2026-07-25
**Raised by:** Claude

**Statement:** Apex assigns each entry to one of exactly 12 recurring internal
slot IDs (comment values of the form `15743<N>`, N = 0–11) rather than a
unique-per-trade ticket, and reuses these 12 IDs continuously across the
entire trading period — consistent with a fixed-size grid or DCA layering
system with 12 concurrent levels, not with per-signal unique trade tagging.

**Supporting observations (not yet proof):**
- Every one of 8 independently parsed backtests (E-001 through E-008 —
  spanning 2023–2026, both "personal" and "propfirm" presets) shows **exactly
  12 unique entry-comment values**, out of 1671–4036 round-trip trades per
  report.
- Only one symbol (XAUUSD) appears in any of the 8 reports, so this hasn't
  been tested against multi-symbol behaviour yet (see [Open Questions](../research/Questions.md)).
- Reproducible across account type (personal vs propfirm) and across 4
  different calendar years — strong internal consistency, but not yet
  reviewed by ChatGPT/Grok (see README's Independent Review Process).

**Proposed test:** Design an experiment that checks whether the 12 IDs
represent price levels, time-based slots, or something else — e.g. correlate
each ID with its distribution of entry prices/times within a single trading
day. Not yet logged in [Experiments.md](Experiments.md).

**Update 2026-07-25 — third independent confirmation from video (E-012):**
frames from the screen recording show the *same* `15743<N>` comment values
live in the MT5 terminal's Trade tab, on both pending orders (`buy stop` /
`sell stop`) and open positions simultaneously — e.g. one frame shows 5
pending buy stops at once (comments 157437, 1574311, 157431, 157432, 157434,
different prices/SL/TP each), and a later frame shows open positions tagged
1574311/1574310/1574310. This confirms the grid places **both directions**
(buy stop and sell stop) around price at the same time, not just one side —
refines the "grid" reading of H-001 toward a two-sided straddle grid rather
than a directional DCA ladder. Still 🟠 pending external review.

---

### H-002 — Apex trails its stop-loss progressively into profit rather than using a static SL

**Status:** 🟠 HYPOTHESIS
**Category:** Trailing Stop / Trade Manager
**Raised:** 2026-07-25
**Raised by:** Claude

**Statement:** Apex does not exit losing trades via a static stop-loss most of
the time — instead it repeatedly moves the SL toward (and past) the entry
price as the trade moves into profit, so that the majority of deals whose
closing comment is tagged `sl` are still net-profitable closes, not losses.

**Supporting observations (not yet proof):**
- Aggregate stats (via `scripts/statistics.py` over `output/csv/*_trades.json`)
  across all 8 backtests show win rates of **77–86%**, even though **70–77%
  of exits are `sl`-tagged** (not `tp`) in every single report — e.g.
  personal-2023 (E-001): 3057/4017 exits are `sl`, yet overall win rate is
  85.6%. This is only possible if most `sl` exits close at a profit, i.e. the
  SL itself moved into profit territory before triggering.
- Direct journal evidence (E-016, `personal-2026-journal(backtesttrue).txt`):
  position `#7160` (buy 0.07 XAUUSD, entry 4038.99) has its SL modified from
  3956.37 → 3997.85 → 4040.51 across 3 separate `position modified` events
  within about 30 minutes of simulated time, before "stop loss triggered
  #7160 ... sl: 4040.51" closes it — 4040.51 is *above* the 4038.99 entry
  price, confirming this specific trade closed in profit via a trailed SL,
  not a loss-cutting one. The journal contains 3740 `stop loss triggered` /
  `take profit triggered` / `position modified` events in this one file alone.
- This is two independent evidence types (aggregate backtest statistics +
  granular journal log) agreeing on the same mechanism — stronger than either
  alone, but still short of the cross-reviewer (Claude/ChatGPT/Grok) agreement
  the README's promotion rule requires before this can move to 🟡.

**Proposed test:** Not yet logged in [Experiments.md](Experiments.md). Should
quantify: (a) average number of SL modifications per trade, (b) average SL
displacement from entry at the moment of trigger, (c) whether displacement
correlates with trade duration or price movement (grid step size vs. ATR-like
trailing).

---

### H-003 — Apex is a strategy configuration ("preset") running on top of a generic multi-feature bot engine called "Zennbot"

**Status:** 🟠 HYPOTHESIS (architecture interpretation) — built on a 🟢 CONFIRMED observation
**Category:** Architecture
**Raised:** 2026-07-25
**Raised by:** Claude

**Statement:** "Apex" itself is not the whole EA — it's one strategy/preset
running inside a broader, reusable bot platform ("Zennbot") that provides
generic infrastructure (trading enable/disable, backtest-realism simulation,
daily reset/timezone handling, max-drawdown kill-switch, scheduled close,
time-of-day filtering, daily profit target, entry limits, randomized-value
anti-detection) — with only the lot-sizing parameters so far observed as
being genuinely "Apex_"-namespaced.

**🟢 CONFIRMED sub-fact (directly observed, not inferred):** all three preset
files (E-009, E-010, E-011) open with `; Zennbot` and a
`ZennbotPresetName=...` field, and every setting key in the file is prefixed
either generically (`Trading_`, `BacktestRealism_`, `Timezone_`,
`MaxDrawdown_`, `ScheduledClose_`, `TimeFilter_`, `DailyProfitTarget_`,
`Limits_`, `RandomizedValues_`) or with `Apex_` (currently only
`Apex_LotSize_*` fields are visible in these three presets).

**Supporting observations (not yet proof of the architectural interpretation):**
- This namespacing pattern is consistent across all 3 presets.
- Only lot-sizing appears under the `Apex_` prefix in the presets seen so far
  — no `Apex_Entry_*`, `Apex_Grid_*`, or similar have turned up yet, which
  may mean Apex's actual entry/exit logic is hardcoded (not exposed as preset
  inputs) rather than that it doesn't exist.

**Proposed test:** Not yet logged. Would need more Apex-branded presets, or a
`.set` file with a wider parameter set, to test whether more `Apex_`-prefixed
categories exist (e.g. `Apex_Grid_`, `Apex_TP_`, `Apex_Trail_`).

**Update 2026-07-25 — two more independent confirmations of the naming
itself (still 🟢 for the naming fact, interpretation stays 🟠):** the
Strategy Tester settings screenshot (E-013) shows the Expert dropdown set to
`ZennbotApex2.4.ex5` — the *compiled binary itself* carries the combined
name, not just the preset text. The video (E-012) shows the same build's
in-terminal overlay label reading "Zennbot Apex v2.4". Three independent
sources (3 preset files, a settings dialog, a live terminal overlay) now
agree on the exact same name/version, which is about as solid as internal
(non-cross-reviewed) confirmation gets for a naming fact — but per the
README's promotion rule this still needs ChatGPT/Grok agreement before any
part of this moves to 🟡/🟢 as a *Finding*, not just a repeatedly-observed
label.

---

### H-004 — Apex's propfirm preset trades meaningfully more conservatively than its personal-account preset

**Status:** 🟠 HYPOTHESIS
**Category:** Risk Manager
**Raised:** 2026-07-25
**Raised by:** Claude

**Statement:** The propfirm preset (E-010) is configured for materially lower
risk than the personal preset (E-009), consistent with typical prop-firm
drawdown rules, and this should be visible in realised trade risk once
per-strategy/per-preset statistics are compared directly (not yet done).

**Supporting observations (not yet proof):**
- Preset diff (`apex personal 25k.set` vs `apex propfirm 25K.set`):
  - `MaxDrawdown_Percentage`: 100 (personal, effectively disabled) vs **4**
    (propfirm), with propfirm additionally setting a hard
    `MaxDrawdown_AbsoluteEquityLimit=22750` on top of `MaxDrawdown_Amount=1000`.
  - `Apex_LotSize_AutoLotMultiplier`: **5** (personal) vs **1.25** (propfirm)
    — personal scales lot size 4x more aggressively per unit of account
    growth.
  - `Apex_LotSize_OverrideBalance`: 0 (personal, uses live balance) vs
    **25000** (propfirm, lot sizing calculated off a fixed reference balance
    regardless of actual equity — likely to satisfy a prop firm's static
    risk-per-trade rule).
  - `RandomizedValues_Enable`: false (personal) vs **true** (propfirm) — the
    propfirm preset randomizes TP/SL/entry-price/order-skip values, which
    reads as anti-correlation-detection behaviour for prop-firm compliance
    rather than a trading-edge feature.
  - A third preset (E-011, cent account) sits at yet another point:
    `MaxDrawdown_Percentage=30`, `AutoLotMultiplier=8` (most aggressive of
    the three).
- Aggregate win rates are actually *similar* between personal and prop presets
  for the same year (e.g. 2023: personal 85.6% vs prop 79.3%; 2024: personal
  83.5% vs prop 77.4%) — the risk *settings* differ more than the realised
  *win rate* does, which is itself worth noting rather than assuming risk
  translates linearly into win rate.

**Proposed test:** Not yet logged. Compare average lot size, average risk-per-trade
(as % of balance), and max drawdown reached between personal and prop presets
using `scripts/compare_backtests.py` across matched years.

---

### H-005 — The live "Ultima Markets cent" account shows materially different, weaker-edge behaviour than the XAUUSD backtests

**Status:** ⚠️ EVIDENCE UNDER CORRECTION — Melvin has confirmed there is no MarketsVox/Ultima Markets account actually running Apex; E-014 appears to be the wrong file, mistakenly included in the evidence batch. **Do not treat anything below as informative about Apex until a corrected file is supplied and this is re-evaluated.** Kept here (not deleted) as a record of exactly the kind of mismatched-evidence risk the caveat below was written to guard against — see [Evidence.md](Evidence.md#e-014) for the correction note once logged.
**Category:** Risk Manager / Portfolio Manager / Architecture
**Raised:** 2026-07-25
**Raised by:** Claude

**Statement:** The trading behaviour recorded in the live "Ultima Markets
personal cent" account (E-014) is meaningfully different from — and by one
key risk-adjusted measure (Sharpe ratio), much weaker than — the behaviour
seen in all 8 XAUUSD Strategy Tester backtests (E-001–E-008), to the point
that these look like two different strategies/deployments rather than the
same edge running on different accounts.

**⚠️ Important caveat before the observations below:** there is **no direct
confirmation** that this live account is running the "Apex"/"Zennbot" EA at
all — no EA name, magic number, or version string appears anywhere in the
xlsx export. The only link is that E-014 (the account statement) and E-011
(a Zennbot preset named `ulltima_markets_personak_cent.set`) were provided
together in the same evidence folder with matching names. Treat everything
below as "what this account did," not yet as "what Apex does live."

**Supporting observations:**
- **Completely different symbol set.** The backtests (E-001–E-008) trade
  XAUUSD exclusively. The live account trades 8 forex cent-pairs — GBPUSD
  (2911 trades), EURUSD (2299), NZDUSD (1643), AUDUSD (1357), EURGBP (601),
  USDCAD (530), AUDCAD (191), AUDNZD (104) — with XAUUSD.cent appearing only
  **twice** in 9647 trades.
- **Much lower, near-coin-flip win rate.** Overall 52.86% (5099 wins / 9647),
  with per-symbol win rates ranging 43.5–52.6%. Every backtest, by contrast,
  showed 77–86% win rate (see H-002 — driven by the trailed-SL mechanism).
- **Different profit structure.** Average winning trade $29.11 vs average
  losing trade -$22.02 — a classic "let winners run, cut losers" asymmetric
  payoff profile. Every symbol is still net-profitable (total profit ranges
  from $570 to $14,936 across pairs), but via trade-size asymmetry rather
  than high win rate.
- **Very low Sharpe ratio (0.09)** despite a high recovery factor (19.56) —
  consistent with a choppy, high-variance equity curve that ended net
  positive rather than a smooth one. Max balance drawdown 2.49% (absolute),
  3.57% (relative).
- **Comment/magic tagging is almost entirely absent**: only 11 of 19,502
  deals in the Deals section have any `Comment` value at all (mostly
  MT5-generated hedge-netting notes like `#5305835 by #5074422`, plus one
  `[sl 4759.00]` — note the bracket format differs from the backtests'
  unbracketed `sl 2062.52`). This is the opposite of the backtests, where
  the grid-slot comment (H-001) is present on nearly every entry.

**What this could mean (not yet distinguished — needs more evidence):**
1. This is a different Zennbot/Apex configuration or an older/different EA
   build that behaves fundamentally differently on forex majors vs. XAUUSD
   (plausible: grid/DCA logic tuned for a ranging metal could behave very
   differently on trending forex pairs).
2. This isn't Apex at all — it could be an unrelated EA or manual/other-bot
   trading on this account, and the shared filename is coincidental or just
   organisational (same folder, unrelated content).
3. This is genuinely the same "Apex" logic, and it reveals that real-world
   multi-symbol performance diverges sharply from the curated XAUUSD
   backtest results — which would be an important, cautionary finding for
   anyone evaluating Apex's marketing claims.

**Proposed test:** Not yet logged. First step should be confirming *whether*
this account even runs Apex/Zennbot (ask Melvin directly, or look for
supporting evidence — e.g. does an EA name appear in any other export for
this account?). Only after that's settled does it make sense to design a
same-symbol comparison (there are only 2 XAUUSD.cent trades here, too few to
compare against E-001–E-008 directly).

## Disproven (🔴)

_None yet. Disproven hypotheses move here, struck through, with a link to the disproving experiment. Never delete a disproven hypothesis — a documented dead end saves the next reviewer from re-testing it._

```
### ~~H-000 — example disproven hypothesis~~

**Status:** 🔴 DISPROVEN
**Disproven by:** [EXP-000](Experiments.md#exp-000)
**Why it's kept:** documents that this path was checked and ruled out.
```
