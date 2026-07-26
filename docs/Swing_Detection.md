# Swing Detection

Behavioural analysis of whether/how Apex detects swing highs/lows or other market structure as part of its entry logic.

## Status

🟠 HYPOTHESIS — an unconfirmed visual lead exists, needs a proper zoomed frame-by-frame pass before it's worth more than a note.

## ⚠️ Tentative, unconfirmed lead (needs closer follow-up before trusting it)

Video frames (E-012) show small diamond-shaped markers appearing at some, but
not all, local highs/lows on the M15 candlestick chart (e.g. near a peak
around "15 Jan 12:30–13:15" and near a trough around "15 Jan 14:30" in one
frame). These are plausibly chart objects Apex itself draws to mark detected
swing points, but at the extracted resolution (1 frame/30s, 1280x720) this
can't be distinguished with confidence from unrelated MT5 UI elements (order
markers, crosshair, etc.). **Do not treat this as evidence yet** — it's a
lead for a follow-up pass (re-extract frames at higher frequency/resolution
and crop into the marker regions) before it gets a hypothesis number.

## Questions to Answer

- Do entries cluster around visually identifiable swing highs/lows on the chart?
- Is there a consistent lookback period implied by entry timing (e.g. always reacts N bars after a local extreme)?
- Does entry timing correlate with a specific timeframe's structure, or multiple timeframes simultaneously?
- Does behaviour resemble a known public concept (ZigZag, Fractals, break-of-structure) closely enough to hypothesise it as a base?

## Confirmed (🟢)

_None yet._

## High Confidence (🟡)

_None yet._

## Hypotheses (🟠)

_None logged yet — raise new ones in [Hypotheses.md](Hypotheses.md) tagged `Swing Detection` and mirror the summary line here._

## Evidence

See [Evidence.md](Evidence.md) for the full index. Relevant IDs: E-012 (video, tentative lead only).
