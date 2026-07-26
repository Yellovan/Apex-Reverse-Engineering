# Experiments

Log of every experiment run to test a hypothesis. Use the [Experiment Template](../templates/Experiment_Template.md). Record the **observed** result even when it contradicts the expected one — a failed prediction is a valid, valuable outcome and must never be edited to look like a success.

## Experiment Log

### EXP-001 — Do the 12 slot IDs correspond to fixed price levels?

**Tests hypothesis:** [H-001](Hypotheses.md#h-001-apex-operates-a-fixed-12-slot-gridlayer-identifier-per-symbol)
**Date:** 2026-07-25
**Run by:** Claude

**Purpose:** H-001's proposed test — determine whether the 12 recurring
comment IDs represent distinct price bands (grid levels), distinct times, or
neither.

**Procedure:** Loaded `output/csv/personal-2023_trades.json` (4017 trades),
grouped by `comment`, and computed count / avg entry price / min-max entry
price range / avg lot size / win rate per ID.

**Expected Result:** If IDs = fixed price levels, each ID's entry-price range
should be a distinct, mostly non-overlapping band.

**Observed Result:** All 12 IDs have entry prices spanning almost the entire
year's range (~1807 to ~2070-2086) — ranges overlap almost completely, no
distinct bands. Frequency varies hugely (13 to 1626 trades) and is loosely
inversely related to average lot size (highest-frequency ID `1574310`: avg
lot 0.088; lowest-frequency ID `157430`: avg lot 1.008) — not perfectly
monotonic, but a clear tendency. Win rate is high (81–100%) across all 12
IDs with no obvious outlier.

**Conclusion:** 🔴 DISPROVEN (the specific "fixed price level" reading) /
🟠 HYPOTHESIS revised — IDs are not tied to specific price levels. The
frequency/lot-size pattern instead suggests something like a grid-depth or
re-entry-rung index (frequently-used, small-lot rungs vs. rare, large-lot
"deep" rungs), consistent with martingale-style grid recovery — but this
specific reading is itself untested. Filed as a revision to H-001 in
[Hypotheses.md](Hypotheses.md) and [Strategy_Map.md](Strategy_Map.md).

**Evidence:** [E-001](Evidence.md).

---

### EXP-002 — Quantify SL-modification frequency and displacement at trigger time

**Tests hypothesis:** [H-002](Hypotheses.md#h-002-apex-trails-its-stop-loss-progressively-into-profit-rather-than-using-a-static-sl)
**Date:** 2026-07-25
**Run by:** Claude

**Purpose:** H-002's proposed test — quantify how often and how far the SL
moves before a stop-loss-triggered close, correcting for buy/sell direction
(a naive unsigned comparison undercounts sell-side confirmations).

**Procedure:** Parsed `data/journals/personal-2026-journal(backtesttrue).txt`
with regexes matching `position modified [#ID ...]` and
`stop loss triggered #ID (buy|sell) ... entry sl: SL`. Computed, per closed
position: number of modification events, and a *signed* displacement
(`sl - entry` for buys, `entry - sl` for sells, so positive always means "on
the profitable side").

**Expected Result:** If H-002 holds, most SL-triggered closes should show a
positive signed displacement, and modification counts should be non-trivial
(more than 1-2 per trade).

**Observed Result:** 98 positions had ≥1 SL modification (avg 37.1
modifications per modified position, max 378 on one position — very
frequent, granular trailing, not occasional). Of 78 SL-triggered closes
matched, **70 (89.7%) had the SL on the profitable side of entry**, average
signed displacement +0.503 price units. The remaining 10.3% were genuine
losing stop-outs (e.g. position #7170: entry 4080.66, SL triggered at
4045.98, a real -34.68 loss).

**Conclusion:** 🟡 HIGH CONFIDENCE (internally — still needs ChatGPT/Grok
agreement per the README's promotion rule before this can be filed in
Findings.md) — this is a substantially stronger result than the single
anecdotal example first noted in H-002: it's now a 78-sample statistic from
one journal file showing the trailing-into-profit mechanism dominates but
isn't universal (~10% are real losses).

**Evidence:** [E-016](Evidence.md).

---

### EXP-003 — Compare realised lot size / risk-per-trade between personal and prop presets

**Tests hypothesis:** [H-004](Hypotheses.md#h-004-apexs-propfirm-preset-trades-meaningfully-more-conservatively-than-its-personal-account-preset)
**Date:** 2026-07-25
**Run by:** Claude

**Purpose:** H-004's proposed test — check whether the propfirm preset's more
conservative *settings* (lower `AutoLotMultiplier`, tight `MaxDrawdown`)
actually show up as lower *realised* risk in the parsed trade data, not just
in the preset text.

**Procedure:** For each of 2023/2024/2025, computed average lot size and
average risk amount (`|entry - sl| × lot`, where SL is known) across all
personal-preset trades vs. all prop-preset trades, from
`output/csv/{personal,prop}-{year}_trades.json`.

**Expected Result:** Lower average lot size and average risk amount for prop
vs. personal, roughly proportional to the ~4x `AutoLotMultiplier` difference
(5 vs. 1.25).

**Observed Result:** Personal trades at 9–15x the average lot size of prop
across all 3 years (2023: 0.351 vs 0.040; 2024: 0.370 vs 0.033; 2025: 0.258
vs 0.024), and average risk-per-trade 8–12x higher (2023: €1.73 vs €0.21;
2024: €2.77 vs €0.23; 2025: €2.81 vs €0.24) — a bigger gap than the 4x
`AutoLotMultiplier` difference alone would predict, meaning other factors
(possibly `OverrideBalance`, or compounding effects of the multiplier over
the account's actual balance growth) amplify the difference further.

**Conclusion:** 🟡 HIGH CONFIDENCE (internally; needs cross-reviewer
agreement before Findings.md) — the propfirm preset's conservative settings
do translate into dramatically lower realised risk, more so than the raw
setting differences alone suggested. Filed as an update to H-004 and
[Risk_Manager.md](Risk_Manager.md).

**Evidence:** [E-001 through E-008](Evidence.md).

---

### EXP-004 — Trace live-account closes to test whether the mass-close event was a shared trigger or per-position breakeven exits

**Tests hypothesis:** [H-006](Hypotheses.md#h-006) / [H-007](Hypotheses.md#h-007)
**Date:** 2026-07-26
**Run by:** Claude

**Purpose:** H-006 flagged a burst of 19 "market buy/sell, close #ticket"
events on 2026.07.24 as an unexplained mass-close. Determine whether this
was a portfolio-level kill-switch reacting to a shared price/drawdown level,
or something else — and separately, attempt the win-rate comparison H-006
originally proposed now that the full week's raw logs (E-018) are available.

**Procedure:** Wrote [`scripts/journal_log_parser.py`](../scripts/journal_log_parser.py)
to parse all 5 raw UTF-16LE daily logs. It matches each pending-order fill
("deal #N ... done (based on order #TICKET)") to its ticket, then matches
every explicit "market buy/sell X, close #TICKET ..." event to that same
ticket's original fill, computing whether the position's exit price was
above or below its entry (direction-corrected). SL-modification counts per
ticket were tallied separately. Output: `output/csv/e017_ultima_analysis.json`.

**Expected Result:** If the mass-close was a shared trigger (drawdown
kill-switch, TP sweep), all 21 closed positions should share a similar
*exit* price/time relationship (e.g. all closing near one price level). If
it's per-position, each should close near its own entry/breakeven,
independent of the others.

**Observed Result:** 176 fills observed across the week; only 21 ever
closed (the rest remained open pending orders/positions past the log
window). All 21 closes matched their originating ticket with certainty. All
21 (100%) closed at **exactly** their own entry price (0.00 price
difference, to the cent) — despite the 21 positions having been opened at
different times (spanning ~9 hours) and at different entry prices (4041.40
through 4043.42). This rules out a shared-price trigger — each position's
own entry price, not a common level, determined its exit price. No other
close events (SL/TP or otherwise) were found anywhere else in the full
week's 3,364 log lines, and the words "triggered"/"stop loss"/"take profit"
do not appear anywhere in this journal format (unlike the backtest journals
E-015/E-016, which do use that phrasing).

**Conclusion:** 🟡 HIGH CONFIDENCE — this is a synchronized batch breakeven
flatten, not a shared-trigger kill-switch or ordinary SL/TP sweep. Filed as
[H-007](Hypotheses.md#h-007). The originally-proposed win-rate comparison
(H-006's proposed test) is **not answerable from this data** — the only
observed exits are this different (breakeven-batch) mechanism, not
individual SL/TP hits comparable to the backtests' 77–86% win rates. A
longer observation window would be needed to catch enough ordinary exits.

**Evidence:** [E-018](Evidence.md#e-018).

---

_Add new experiments below using the format:_

```
### EXP-001 — <short title>

**Tests hypothesis:** [H-001](Hypotheses.md#h-001)
**Date:** YYYY-MM-DD
**Run by:** Claude / ChatGPT / Grok / Melvin

**Purpose:** Why this experiment exists — what question it answers.

**Procedure:** Exact, reproducible steps taken (which backtest, which symbol/period,
which preset, what was varied).

**Expected Result:** What the hypothesis predicts, stated before running the test.

**Observed Result:** What actually happened. Raw, unedited, even if it contradicts
the expectation.

**Conclusion:** 🟢 CONFIRMED / 🟡 HIGH CONFIDENCE / 🟠 still HYPOTHESIS (inconclusive) /
🔴 DISPROVEN — and a pointer to where the result was filed (Findings.md or
Hypotheses.md).

**Evidence:** link(s) to [Evidence.md](Evidence.md) entries used.
```
