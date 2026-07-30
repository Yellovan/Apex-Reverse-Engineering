# Pending Orders

Behavioural analysis of Apex's use of pending orders (buy/sell stop or limit) rather than direct market entries.

## Status

🟠 HYPOTHESIS overall for the two-sided-straddle interpretation, but the SL/TP-distance-per-tier ladder is now 🟡 HIGH CONFIDENCE — directly measured from E-018's raw placements (2026-07-27), not inferred.

## 🟠 First observation (video, not yet cross-checked against journal timing data)

Frames from E-012 show Apex placing **multiple simultaneous pending orders on both sides of price at once** — e.g. one frame shows 5 live `buy stop` orders at once (different prices/lots/SL/TP, comments `157437`/`1574311`/`157431`/`157432`/`157434`), and a later frame in the same session shows `sell stop` orders placed too, at the same time as buy stops exist. This looks like a two-sided straddle grid (pending orders both above and below current price simultaneously), not a single-direction ladder — see [H-001's 2026-07-25 update](Hypotheses.md#h-001-apex-operates-a-fixed-12-slot-gridlayer-identifier-per-symbol). Not yet quantified: typical placement-to-trigger distance, or how often pending orders get cancelled/replaced vs. left to trigger or expire (the backtests do show `canceled` status orders in the raw Orders section, per the very first inspection of E-001's HTML — worth a dedicated pass).

## 🟡 Quantified: 11-tier SL/TP-distance ladder (directly measured from E-018's raw placements)

**Added 2026-07-27**, while cross-checking Melvin's draft `ZennApex_XAU.mq5` reconstruction EA against the evidence. All 634 `buy stop`/`sell stop` placement lines across the full week (E-018) were parsed for their `sl:`/`tp:` fields, giving a directly-measured SL-distance and TP-distance (in $ from the pending order's own price) per lot-size tier — no inference needed, these are the EA's own logged order parameters:

| Tier | Lot(s) | n | Lot ratio (vs. tier A) | SL distance | TP distance |
|---|---|---|---|---|---|
| A | 0.04 | 115 | 1.00 | 82.9 | 28.7 |
| B | 0.08 | 22 | 2.00 | 14.2 | 40.5 |
| C | 0.12/0.13 | 31 | 3.00 | 82.5 | 14.0 |
| D | 0.15/0.16 | 58 | 3.75 | 92.6 | 13.5 |
| E | 0.20/0.21 | 82 | 5.00 | 34.2 | 17.1 |
| F | 0.25/0.26 | 35 | 6.25 | 20.2 | 70.8 |
| G | 0.31/0.32 | 62 | 7.75 | 70.7 | 29.3 |
| H | 0.37/0.38 | 56 | 9.25 | 54.5 | 17.1 |
| I | 0.41/0.42 | 109 | 10.25 | 31.2 | 20.0 |
| J | 0.43/0.44 | 32 | 10.75 | 20.2 | 82.9 |
| K | 0.51/0.52/0.53 | 32 | 12.75 | 50.5 | 36.4 |

This matches the "eleven distinct tiers" lot ladder already noted from E-017 (see [Strategy_Map.md](Strategy_Map.md)/[H-001](Hypotheses.md#h-001)), now with each tier's own SL/TP distance attached — each lot size is paired with its own fixed offset pair, not a shared SL/TP across the grid. The near-duplicate lot values within a tier (e.g. 0.12 vs 0.13, 0.51/0.52/0.53) are consistent with `AutoLotMultiplier`/risk-based rounding drift over the week (equity moved during this period), not distinct tiers.

**Cross-check against Melvin's `ZennApex_XAU.mq5` draft (v1.21, pasted 2026-07-28):** the draft's `g_layers[]` table (8 entries, `L0`–`L7`) already captures 4 of these 11 tiers almost exactly:

| Draft layer | Draft (sl, tp) | Closest real tier | Real (sl, tp) |
|---|---|---|---|
| L3 | (31, 20) | I | (31.2, 20.0) | ✅ near-exact |
| L4 | (20, 71) | F | (20.2, 70.8) | ✅ near-exact |
| L6 | (14, 40.5) | B | (14.2, 40.5) | ✅ near-exact |
| L7 | (20, 82) | J | (20.2, 82.9) | ✅ near-exact |
| L0 | (100, 28.5) | A | (82.9, 28.7) | ⚠️ TP matches, SL off by ~17 |
| L1 | (50, 17) | E or H | (34.2, 17.1) / (54.5, 17.1) | ⚠️ TP matches both, ambiguous SL |
| L2 | (110, 13.5) | C or D | (82.5, 14.0) / (92.6, 13.5) | ⚠️ TP close, SL off by 17–28 |
| L5 | (32, 20) | — | — | ⚠️ near-duplicate of L3, doesn't match any distinct real tier |
| — | (missing) | G | (70.7, 29.3) | ❌ tier not represented at all |
| — | (missing) | K | (50.5, 36.4) | ❌ tier not represented at all |

Recommendation for the EA reconstruction: replace the draft's guessed `sl_dist` values for L0/L1/L2 with the measured 82.9/34.2 (or 54.5)/92.6, replace L5 with tier G's (70.7, 29.3), and add a 9th layer for tier K (50.5, 36.4). Also note the draft defaults to `InpMaxLayers=3` (only L0–L2 active), while live evidence shows all ~11 tiers placed simultaneously — this input needs raising to at least 9–11 to actually approximate observed behaviour. The lot-multiplier side of the draft's table is a much closer match already: its `lot_mult` values `{1.00, 5.25, 4.00, 10.50, 6.50, 10.25, 2.00, 11.00}` are (mostly exact) members of the real lot-ratio set `{1, 2, 3, 3.75, 5, 6.25, 7.75, 9.25, 10.25, 10.75, 12.75}` — someone had already derived the lot ladder correctly, just not yet the matching SL/TP distances or the full tier count.

**Update 2026-07-30 — offset reconstruction attempted, real negative result.** Rather than waiting for a new evidence source, the full `ultima_live` journal folder's 3684 raw placement lines (2026-03-31 through 2026-07-30, not just E-018's 5-day window) were cross-referenced against real historical M1 price bars for XAUUSD.sc (pulled directly via the MetaTrader5 Python package from the live account's own terminal), using `(M1_high+M1_low)/2` at each placement's exact minute as a mid-price estimate. 1482 of 3684 placements fell within the available M1 history (2026-04-20 onward) and could be matched.

Result: offset (`|placement_price − mid_at_that_minute|`) is far noisier than the SL/TP-distance measurement was — even restricted to only the first fresh occurrence of each distinct (direction, lot, price) combination (574 of 1482, filtering out routine same-price re-placements), standard deviation regularly exceeds the median (e.g. lot=0.01: median 40.2, std 165.1; lot=0.21: median 18.5, std 26.1 — the one tier with a tight-ish spread). This is not just measurement noise from the M1-proxy — it's evidence against the working assumption itself.

**Cross-account validation, 2026-07-30 (a positive result, unlike the offset attempt above).** The same SL/TP-distance ladder was checked against the other two accounts collected this week (`funden_propfirm` and `roboforex_live` — different brokers, different balances). It holds up well: `funden_propfirm`'s 0.01-lot tier measures (83.3, 29.0) vs tier A's reference (82.9, 28.7); its 0.06-lot tier measures (51.0, 36.7) vs tier K's (50.5, 36.4); similar close matches for tiers E, H, I. `roboforex_live` (a much smaller account, only 4 distinct lot sizes observed vs Ultima's 11) also matches tiers E and K closely. This is good evidence the SL/TP ladder is a fixed Apex/Zennbot property, not something tuned per account or broker. It also explains why `roboforex_live` shows only 4 distinct lots: with a small enough balance, `AutoLotMultiplier` scaling pushes several different nominal tiers below the broker's minimum tradeable lot, so they all round up to the same observed 0.01–0.04 values — the exact same lot-floor-compression effect found (and fixed) in the `ZennApex_XAU_v2.mq5` reconstruction's own `InpSpikeInitialFrac` bug this week.

**Revised reading:** "offset = fixed distance from the live market mid at placement time" is probably the wrong model. Two supporting observations: (1) the daily ~08:25 cancel+re-place cycle overwhelmingly re-uses the SAME price level for days at a stretch (only the lot size gets nudged, e.g. 0.53→0.51) — inconsistent with continuous re-pricing off current mid; (2) even genuinely fresh, distinct price levels show offset spreads too wide for a simple constant-per-tier rule. More likely: levels are anchored to some other reference (a session/day open, a longer-lived pivot, or simply held from whenever they were last set) and only occasionally recomputed, rather than recalculated fresh on every placement. Not yet tested against a session-open or daily-open reference price — that's the natural next hypothesis to check, either with more historical cross-referencing or with fresh `ApexLogger` PENDING_ADD-vs-PENDING_UPD data (which can distinguish a genuinely new level from a routine same-price refresh directly, instead of inferring it from price-repetition).

## Questions to Answer

- Does the journal/log show pending order placement events distinct from market fills?
- What is the typical distance between placement price and trigger price?
- Are pending orders cancelled/modified before triggering, and under what observed condition?
- How long do pending orders typically remain live before triggering or expiring?
- Does pending-order placement relate to [swing detection](Swing_Detection.md) levels?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

- The 11-tier SL/TP-distance ladder above — directly measured from 634 raw order placements (E-018), not inferred. Still needs cross-reviewer agreement per the promotion rule before it can move to Findings.md.

## Hypotheses (🟠)

- What is the typical distance between placement price and trigger price? — offset itself is still not directly measured (E-018's format lacks concurrent bid/ask), so this remains open even though SL/TP distance is now quantified.

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-012 (video), E-018 (raw placement logs, source of the SL/TP-distance ladder).
