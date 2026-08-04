# Porting a chart to a new toolchain forces a data re-read — and that is when you find out the source published a new wave

**Discovered:** 2026-08-01, closing F22 in `plan-narrativa-final-memo`. The task was
filed as a *production* debt with "a cheap mechanical path": one matplotlib chart at
208 effective dpi had to become a `theme_gl()` ggplot at 300. Same numbers, new
renderer. It was not the same numbers.

## 1. The finding

`analysis/enterprise_surveys/argentina_biggest_obstacle.py` writes a cached panel to
`data/raw/wb_enterprise_surveys/`. To write the R port I read that CSV — and it had
**four Argentine Enterprise Survey waves: 2006, 2010, 2017, 2026.**

`research/evidence/08_argentina_es_biggest_obstacle.md` says, in its own title and its own
"Survey waves in Argentina" section: **"Three waves: 2006, 2010, 2017"**, adding that
Argentina is not in the 2017→2025 round. It was pulled **2026-05-13**. The panel CSV
was refreshed **2026-07-23**. In the ten weeks between, the World Bank published a
wave, the acquisition script picked it up (its own comment even notes *"the 2026 wave
is now published, so the label is wave-agnostic"*), and **nothing propagated to the
evidence doc or to the memo section built on it.**

And the new wave answers a question the evidence doc had asked in writing. `#08` says
*"A new 2024/25 wave would likely re-invert this"* about the collapse of
access-to-finance to 5.3%. Measured: **5.25 → 10.68**, tax rates **35.92 → 33.99**,
informal-sector practices **5.27 → 8.05**.

## 2. Why the re-render is what caught it, and nothing else would have

Every other path touching this chart reads something *downstream* of the data:

- The **memo draft** reads the evidence doc. The evidence doc says three waves.
- The **chart budget gate** reads PNG pixel dimensions. A stale PNG has the right
  dimensions.
- The **retraction gate** reads strings against `retracciones.md`. "35,9% en 2017" is
  not a retired formulation; it is a *true statement about a superseded window*, which
  no string gate can see.
- The **acquisition script** would have caught it — but you only run it when you want
  fresh data, and nobody wanted fresh data. They wanted a prettier chart.

The port is the only task in the chain whose *implementation* requires opening the
data file. **A toolchain migration is an unplanned data audit**, and that is the
useful thing about it.

## 3. Split the port: chart-only, acquisition untouched

The tempting shape is one R script that fetches and draws, replacing the Python
outright. **Don't.** The port was written to read the cached CSV and make **no network
call**, leaving acquisition in the Python script:

```r
IN_CSV <- "data/raw/wb_enterprise_surveys/arg_biggest_obstacle_year_x_category.csv"
raw <- read_csv(IN_CSV, show_col_types = FALSE)   # no network — reproducible offline
```

Two reasons, and the second is the load-bearing one:

1. The acquisition code is the part that knows the API's quirks (which breakdown
   columns give the headline row, how the 15 indicators stack). Rewriting that in a
   second language duplicates a liability.
2. **A fused script means a re-render silently re-pulls.** Then "regenerate the
   charts" changes published figures with no diff anyone reads, and the memo's numbers
   drift from the numbers its captions were written against. Keeping them split makes
   a data refresh an explicit act.

## 4. A new wave is a SCOPE question — flag it, do not absorb it

The reflex is to draw the newest data because newer is better. Wrong here, twice over:

- The body caption is a **2017 statement** ("35,9% en 2017, more than double any other
  category"). Swapping the wave under a caption written for the old one is worse than
  either the old chart or an honest update.
- The prose carries **three caveats built on there being three observations** — the
  survey has no provincial cut, the choice is forced and single, and three points
  eleven years apart straddle the cepo, the 2014 default and the 2016 statistical
  reset. A fourth wave changes all three at once, plus the section's financial framing
  and its relation to a separate memo.

So: draw the wave the caption names, put `WAVE <- "2017"` on **one line** so the
promotion is a one-token change, and file the question with its measured table. Also
worth stating explicitly: **check what does NOT move.** Tax rates stay first at more
than double the runner-up in all four waves, so the section's central claim survives
and only the finance reading is in play. A flag that says "everything might be wrong"
gets ignored; one that says "this specific paragraph, and here is what is safe" gets
actioned.

## 5. The stale evidence doc is the real defect

The chart was fixable in an hour. What persists is that **`#08` carries no supersession
banner** while a wave it does not know about sits in the repo's own cached data. That
is precisely the trap `retracciones.md` R21 documents — a doc whose stated verdict is
superseded but whose file says nothing, so anyone following the citation chain forward
and stopping one doc short writes the retired reading believing it is current.

`#08` is worse than R21's case in one way: R21's chain at least *had* a newer doc to
find. Here the newer information is in a **CSV**, which no reader of `research/evidence/` will
ever open.

## Rules

1. **Treat any toolchain port as a data audit.** Before writing the new renderer,
   diff what is on disk against what the evidence doc claims is on disk — waves, years,
   row counts, country lists.
2. **Port the chart, not the acquisition.** The new script reads the cached artifact
   and makes no network call, so re-rendering can never move published numbers.
3. **Put the window/vintage selector on one line** with a comment saying what else
   changes if it moves.
4. **When fresh data answers a question the deliverable left open, that is a flag, not
   an edit** — it usually touches prose, caveats and framing together.
5. **Name what survives the new data, not only what breaks.** A scoped flag gets acted
   on; an unscoped one gets deferred forever.
6. **A cached CSV newer than the evidence doc that describes it is a silent
   supersession.** Banner the doc; a reader of `research/evidence/` never opens `data/raw/`.

## Related

- `[[hand-picked-retraction-gate-misses-captions]]` — the same shape one layer up: a
  gate that reads only what its author thought to look at. A string gate cannot see a
  true statement about a superseded window.
- `[[slide-charts-need-furniture-stripped-not-resized]]` — the other half of this
  project's chart-port work, and why the port strips title/subtitle/caption.
