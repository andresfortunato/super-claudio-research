# Visualization conventions

> **This is a template / worked example.** Replace with your
> project's actual visualization rules, or delete once a real
> file lands. The rules below are illustrative — generic
> guidance shaped to match the kind of decisions a country-
> diagnostic or sectoral project typically commits to.

Use this document whenever creating, editing, or reviewing
charts, plots, maps, or any other visual output in this
project.

## Color rules

1. **Subject vs. peers (scatter / line / bar with comparison).**
   - The *subject* (the country, region, or sector this
     project is about): one accent color. Pick a hex from the
     project's brand palette and use it consistently
     everywhere.
   - All *peers / comparators*: one shared color, distinct
     from the subject. Do **not** assign each peer its own
     color — the peer set is "everyone else," not a legend
     of individual entities.
   - Both subject and peers carry **labels** on scatter
     plots. Use a label-repulsion library (e.g.
     `adjustText.adjust_text` in Python) to prevent
     overlapping text.
   - Use the **default round marker** (`'o'`) for all
     entities — color alone distinguishes the subject. No
     special markers (diamonds, stars) for the highlight.
   - When all highlighted points are clearly labelled, **omit
     the legend** — it's redundant.

2. **Bar charts.**
   - Category names on the **y-axis** (horizontal bars are
     easier to read than vertical when category labels are
     long).
   - Ordered **highest-to-lowest** value (top = highest), unless
     the category has an inherent ordering (year, age band).

3. **Sector / category palettes.** When a chart shows
   composition across sectors / product groups / income bands,
   define the palette **once** in the project's utility
   module (e.g. a sector-color dict in
   `<project>_utils.py`) and reuse across charts. Re-defining
   sector colors per notebook produces deck slides where the
   same sector is green here and orange there.

4. **Color files (project-wide).** If the project has a
   `colors/` folder of CSVs (brand colors, sector colors,
   complexity gradients, region colors), list them here so
   collaborators know where to find them. Examples:
   - `brand_colors.csv` — project palette (subject color,
     peer color, accent).
   - `sector_colors.csv` — sector / industry palette.
   - `region_colors.csv` — geographic region palette.

## Plotting conventions

- Use a project setup helper (e.g. `setup_plotting()` from the
  project's utility module) to apply consistent matplotlib /
  ggplot defaults — font, sizes, spine removal, DPI.
- Save figures via a project-standard helper (e.g.
  `save_fig(fig, name, findings={...})`) that writes the PNG
  *and* a metadata JSON to `output/` — never `plt.show()`-
  only, which leaves no artifact behind.
- Prefix chart filenames with the **notebook number** that
  produced them: `01_`, `02_`, `03_`, `03b_`. This keeps the
  output folder navigable as the project grows.
- Use a country-or-subject highlight helper (e.g.
  `country_line_kwargs(iso)`) for line charts so the subject
  is visually distinguishable (heavier line weight) without
  reinventing the styling per chart.
- Publication quality defaults: ~200 DPI, white background,
  no top/right spines, sans-serif fonts.

## What to do when a rule is ambiguous

When you're unsure which color, marker, or layout the project
expects, look at recently-committed charts in `output/`. If
the answer isn't there, ask — and once you have an answer,
add the rule here. The doc grows by accretion, edited in
place.
