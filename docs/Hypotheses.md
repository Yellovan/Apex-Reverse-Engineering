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

**Update 2026-07-27 — the numeric prefix is account/deployment-specific,
not a universal constant; the 12-slot structure itself repeats exactly.**
E-019 (a full month's structured trade history for live account 31599933)
shows comment IDs of the form **`11498<N>`, N = 0–11** — the *same* 12-value
structure as every backtest, but a completely different 5-digit prefix
(`11498` vs `15743`). This rules out "`15743` is a hardcoded constant
shared by every Apex deployment" — the prefix must be computed or assigned
per account/preset/instance somehow (candidates: derived from the account
number, a chart/magic-number seed, or a per-license value), while the
underlying "12 concurrent slots, N=0–11" structure is robust across both
prefixes. Still 🟠 pending external review on the interpretation, though the
raw fact (different prefix, same slot count) is directly observed.

---

### H-002 — Apex trails its stop-loss progressively into profit rather than using a static SL

**Status:** 🟡 HIGH CONFIDENCE — corroborated independently in both backtest
(EXP-002) and live-account (E-019) data; still needs ChatGPT/Grok agreement
per the promotion rule before Findings.md.
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

**Proposed test:** Ran as [EXP-002](Experiments.md#exp-002--quantify-sl-modification-frequency-and-displacement-at-trigger-time) on 2026-07-25 — see that entry for the average-modifications-per-trade and displacement-at-trigger results (89.7% of 78 sl-triggered backtest closes were profitable).

**Update 2026-07-27 — independently corroborated from a live account,
not just backtests.** E-019 (a full month of real trade history for account
31599933) shows **206 sl-tagged exits, of which 90.8% (187) were still
profitable** — essentially the same figure as EXP-002's 89.7% from the
backtest journal, but from a completely different evidence type (a
broker-generated statement with real currency profit values, not a
Strategy Tester log). Two independent measurement methods, two independent
data sources (backtest vs. live), converging on ~90% — see
[H-006's 2026-07-27 update](#h-006) for the full comparison table. Upgraded
internally to 🟡 HIGH CONFIDENCE; still needs ChatGPT/Grok agreement per the
promotion rule before Findings.md.

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

**Update 2026-07-26 — fourth confirmation, this time from a live terminal's
own Experts log, not a UI label:** E-017 (a live MT5 journal, account
31599933, broker Ultima Markets Ltd) contains the literal lines `expert
ZennbotApex2.3beta1 (XAUUSD.sc,M30) removed` and, ~4 hours later the same
day, `expert ZennbotApex2.4 (XAUUSD.sc,M30) loaded successfully` — a live
version upgrade from 2.3beta1 to 2.4, captured by the terminal itself. This
is a different kind of evidence than the first three (preset text, a
settings dialog, an in-chart overlay) — it's the platform's own EA-lifecycle
log — and it also confirms 2.3beta1 as a real prior live version, not just
an inferred one. Still 🟠 pending external review per the promotion rule,
but four independent, structurally different sources now agree.

**Update 2026-07-27 — fifth confirmation, this time from broker/account
metadata itself, not EA output at all:** E-019 (MT5's own generated "Trade
History Report" for account 31599933) titles itself *"31599933: APEX EA -
Trade History Report"*, and its "Name:" field — the account's own
user-assigned display name inside MT5 — literally reads **"APEX EA"**. This
is qualitatively different from the first four sources: it isn't the EA
identifying itself, it's the broker/terminal's account-level metadata,
independently corroborating that this specific account is understood (by
whoever named it) to be running Apex. Also visually confirmed in E-022's
`h4.png` screenshot, which shows the EA's own in-chart dashboard panel
reading "Zennbot Apex v2.4 \| OK \| 0 (0.00%) Max DD \| USC 35254.06" —
directly showing the EA tracks and displays its own drawdown against the
`MaxDrawdown_*` preset fields in real time.

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

**Resolution 2026-07-26:** answered — no, per Melvin. See H-005's status line
and [Evidence.md](Evidence.md#e-014). The correct live-account evidence is
E-017, evaluated fresh as [H-006](#h-006) below rather than reusing this
entry, to keep the record of what went wrong intact.

---

### H-006 — Live XAUUSD.sc trading (E-017) is broadly consistent with the backtests' grid/trailing behaviour, on the same symbol this time

**Status:** 🟡 HIGH CONFIDENCE — the quantitative comparison this hypothesis
set out to make is now answered (see the 2026-07-27 update below); still
needs ChatGPT/Grok cross-review per the promotion rule before Findings.md.
**Category:** Strategy Map / Trailing Stop / Trade Manager
**Raised:** 2026-07-26
**Raised by:** Claude

**Statement:** Unlike the withdrawn H-005 (wrong account, wrong symbol),
E-017 is a confirmed Apex deployment (see [H-003's 2026-07-26
update](#h-003)) trading the *same* symbol as every backtest (XAUUSD, broker
suffix `.sc`), and its observable behaviour is directionally consistent with
what the backtests and video predicted — not contradicting it the way the
withdrawn E-014 data did.

**Supporting observations:**
- **Lot ladder matches.** Day-1 pending orders (2026.07.20) show lot sizes
  0.04, 0.08, 0.13, 0.16, 0.21, 0.26, 0.32, 0.38, 0.42, 0.44, 0.53 — eleven
  distinct tiers, each placed as a mirrored buy-stop/sell-stop pair straddling
  price. This lines up with the ~12-tier grid-depth reading from
  [EXP-001](Experiments.md) (backtest data) and the video (E-012).
- **SL trailing matches.** A representative sequence (E-017, 2026.07.22
  03:01–03:15) shows the same position's SL nudged upward in small steps
  every 1–3 minutes — the same granular trailing pattern quantified in
  [EXP-002](Experiments.md) from the backtest journal (E-016).
- **The mass-close event is now explained — see [H-007](#h-007) below.** It
  is not a random drawdown kill-switch; it's a synchronized batch close where
  every position closed at its own exact entry price.
- **A second EA runs alongside Apex** on this account: `testdaashboard
  (XAUUSD.sc,M1)`. Purpose unknown — likely an unrelated monitoring/dashboard
  tool, but not yet confirmed to have zero interaction with Apex's own logic.

**Update 2026-07-26 — full week's raw logs received (not just an excerpt),
quantitative analysis run via
[`scripts/journal_log_parser.py`](../scripts/journal_log_parser.py):**
176 pending-order fills observed across the week, 86 of which received at
least one SL modification (avg 3.52 modifications per touched position, max
18) — consistent with the granular-trailing pattern above. Only **21 of the
176** opened positions closed within the observed week (the rest were still
open pending orders/positions at the end of the log); all 21 closes were the
[H-007](#h-007) breakeven-flatten batch.

**Caveat — the originally proposed quantitative comparison is not obtainable
from this evidence.** The backtests' 77–86% win rates come from *individual*
SL/TP-triggered exits. This live account's only observed closes in the week
are a *different* exit mechanism entirely (a synchronized breakeven flatten,
not per-position SL/TP), so there is no apples-to-apples win rate to compare
against the backtests from this data. H-006 therefore remains a *qualitative*
match (lot ladder, trailing pattern) — the quantitative performance
comparison H-005 originally set out to do is still not answered, and may
require a longer observation window (weeks/months) to catch enough
individual SL/TP exits to compute a comparable win rate.

**Proposed test:** Get a longer live-account log (multiple weeks) or a
structured account statement for 31599933 covering enough time to observe
individual SL/TP exits, not just the one batch-close event seen this week.

**Update 2026-07-27 — ANSWERED. Melvin supplied exactly the structured
account statement this hypothesis was waiting for (E-019, a full month:
2026.06.23–2026.07.24).** Parsed with the same `html_parser.py`/
`trade_parser.py` pipeline used for the backtests (E-001–E-008), giving a
genuinely apples-to-apples comparison for the first time:

| | Backtests (E-001–E-008) | Live (E-019, 1 month) |
|---|---|---|
| Win rate | 77–86% | **89.40%** (253/283) |
| SL-tagged exits still profitable | 89.7% ([EXP-002](Experiments.md)) | **90.8%** (187/206) |
| Total return | n/a (per-backtest) | **+38.2%** ($25,000 → $34,540) |

The live account's win rate is **at or above the top of the backtests'
range**, and the "SL trailed into profit" mechanism ([H-002](#h-002)) shows
up just as strongly live (90.8%) as in the backtest journal (89.7%) — an
independent confirmation from a completely different evidence type (a
broker-generated account statement vs. a Strategy Tester journal). This is
the strongest evidence yet that the backtests are not curve-fit fantasy —
the live account is performing in line with, or better than, what they
predicted.

**Caveat, worth keeping honest:** one month (283 trades) is a modest sample
next to the backtests' multi-year, thousands-of-trades runs, and the account
grew during the window (compounding could flatter the % return figure
somewhat). Also, `trade_parser.py`'s FIFO entry/exit pairing can misattribute
which specific concurrent same-ID entry an exit belongs to when several are
open at once (aggregate win-rate/profit are unaffected, since those come
directly from each exit deal's own recorded profit — see the script's
docstring) — this may explain part of why some `tp`-tagged exits show a
loss (21% of them), though that's not fully resolved; see
[Risk_Manager.md](Risk_Manager.md).

---

### H-007 — Apex/Zennbot flattens positions via a synchronized market-close at each position's own breakeven price, not via broker-side SL/TP triggers

**Status:** 🟡 HIGH CONFIDENCE (directly measured, not inferred — still needs
ChatGPT/Grok cross-review per the README's promotion rule before Findings.md)
**Category:** Trade Manager
**Raised:** 2026-07-26
**Raised by:** Claude

**Statement:** The "mass-close event" first flagged in [H-006](#h-006) (a
burst of 19 "market buy/sell, close #ticket" events on 2026.07.24
~04:47–04:53) is not a stop-out, a take-profit sweep, or a drawdown
kill-switch reacting to a shared trigger price. Every one of the 21 explicit
close events observed in the full week's log (E-017, all 5 days) closed its
position at **exactly** that position's own original entry fill price —
zero net price movement, to the cent, on every single one.

**Supporting observations (directly measured via
[`scripts/journal_log_parser.py`](../scripts/journal_log_parser.py) against
[E-017](Evidence.md#e-017), output in
`output/csv/e017_ultima_analysis.json`):**
- 21/21 traceable closes (100%) had `exit_price == entry_price` to 2 decimal
  places. Example: ticket #374943471, a sell filled 2026.07.23 at 21:10:16
  at 4043.23, closed via `market buy 0.04 ..., close #374943471 sell 0.04
  XAUUSD.sc 4043.23` at 2026.07.24 04:47:34 — over 7 hours later, at the
  identical price.
- These closes are spread across 11 minutes (04:47:26–04:53:07) and involve
  positions opened at different times over the preceding ~9 hours at
  different entry prices (4041.40 through 4043.42) — ruling out "all closed
  because price hit one shared level." Each ticket's close price matches
  *only its own* entry, not a common level.
- Across the entire 5-day log, no line anywhere contains the words
  "triggered", "stop loss", or "take profit" (unlike the Strategy Tester
  backtest journals E-015/E-016, which do use that phrasing). **Correction,
  2026-07-27: this does *not* mean ordinary SL/TP exits didn't happen that
  week** — see [Trade_Manager.md](Trade_Manager.md#-high-confidence-positions-close-via-a-synchronized-breakeven-batch-not-individual-sltp-triggers--as-one-of-several-exit-mechanisms)
  for the correction. E-019 (a full month's structured account statement for
  this same account) shows 254 individual sl/tp-tagged exits, so they
  clearly occur regularly — the raw Trades-tab journal format just doesn't
  distinguish a closing deal from an opening one (`journal_log_parser.py`
  had no way to tell them apart), unlike the structured report's explicit
  `[sl X.XX]`/`[tp X.XX]` comment tags. The 21-position breakeven batch is
  real and still directly verified; it is one exit mechanism among several,
  not the account's only one.

**What this could mean (not yet distinguished):**
1. This is Apex's actual break-even-stop mechanism in action — once price
   revisits a position's entry after having moved favourably (the modify
   logs show SL being trailed upward for several of these tickets earlier),
   the EA closes it at market rather than waiting for a broker-side SL to
   be hit, functionally converting a "trailing stop got run over" event into
   a clean breakeven exit instead of a small loss.
2. This is a portfolio-level flatten triggered by something external to any
   single position (e.g. total floating P/L, a time-of-day rule, or the
   `MaxDrawdown_*`/`ScheduledClose_*` engine-level presets) that happens to
   pick breakeven as its exit price for each leg — less likely given how
   precisely each price matches its own entry rather than a shared
   portfolio-level trigger, but not ruled out.

**Caveat:** only 21 closes were observed in one week from one account — too
small a sample to rule out coincidence entirely, though 21/21 exact matches
makes coincidence very unlikely.

**Proposed test:** Get a longer log (multiple weeks) to see whether this
breakeven-batch pattern recurs regularly (e.g. same time of day, same
triggering condition) or was a one-off; check whether it correlates with the
22:45 pending-order-cleanup time noted in [Trade_Manager.md](Trade_Manager.md)
or with a specific floating-P/L threshold.

**Evidence:** [E-017](Evidence.md#e-017).

## Disproven (🔴)

_None yet. Disproven hypotheses move here, struck through, with a link to the disproving experiment. Never delete a disproven hypothesis — a documented dead end saves the next reviewer from re-testing it._

```
### ~~H-000 — example disproven hypothesis~~

**Status:** 🔴 DISPROVEN
**Disproven by:** [EXP-000](Experiments.md#exp-000)
**Why it's kept:** documents that this path was checked and ruled out.
```
