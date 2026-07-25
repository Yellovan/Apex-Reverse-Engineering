# Hypotheses

Untested or partially tested explanations for observed Apex behaviour. Every entry here is 🟠 unless explicitly marked 🔴 after being disproven (disproven entries stay here, struck through, they are never deleted — they are evidence that a path was already ruled out).

Use the [Finding Template](../templates/Finding_Template.md) for structure. A hypothesis is promoted to [Findings.md](Findings.md) only after a logged, reproducible experiment in [Experiments.md](Experiments.md) raises its confidence to 🟡 or 🟢.

## Open Hypotheses (🟠)

_None logged yet. Add new hypotheses below using the format:_

```
### H-001 — <short title>

**Status:** 🟠 HYPOTHESIS
**Category:** <Risk / Trade Management / Swing Detection / ...>
**Raised:** YYYY-MM-DD
**Raised by:** Claude / ChatGPT / Grok / Melvin

**Statement:** What we think Apex does, phrased as a falsifiable claim.

**Supporting observations (not yet proof):**
- ...

**Proposed test:** link to an Experiments.md entry once designed, e.g. [EXP-001](Experiments.md#exp-001)
```

## Disproven (🔴)

_None yet. Disproven hypotheses move here, struck through, with a link to the disproving experiment. Never delete a disproven hypothesis — a documented dead end saves the next reviewer from re-testing it._

```
### ~~H-000 — example disproven hypothesis~~

**Status:** 🔴 DISPROVEN
**Disproven by:** [EXP-000](Experiments.md#exp-000)
**Why it's kept:** documents that this path was checked and ruled out.
```
