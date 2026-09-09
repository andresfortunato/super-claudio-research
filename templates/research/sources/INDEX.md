# Data sources — index

Documentation for every external data source this project uses.
**Bulk data lives in `data/`; helper functions live in the project's
utility module; this folder holds the *references* — how to access
each source, what's in it, what to watch out for.**

---

## Quick navigation

| If you want… | Read |
|---|---|
| (example — replace) World Bank indicators via the API | `EXAMPLE_world_bank_api.md` |

Sort rows by likely access frequency, not alphabetically. Three to
ten rows is the right size; if it grows past ten, the engagement is
probably touching too many sources.

---

## Files in this folder

Group files by source family (all IMF docs together, then World
Bank, then OECD, etc.). Drop the `EXAMPLE_*.md` row once a real
source is documented.

| File | Purpose |
|---|---|
| `EXAMPLE_world_bank_api.md` | Worked example — delete once real sources land. |

---

## Conventions for adding new sources

When adding a new data source, follow the recipe in
`.claude/conventions/sources.md` (full protocol). The short
form:

1. **Create `research/sources/<source>_<thing>.md`** with frontmatter
   (`source`, `status`, `triggers`, `wrapper`, `env`) and the five
   required sections: `## What it gives you` / `## Access` /
   `## Headline anchor` / `## Gotchas` / `## Coverage limits`. Naming
   is lowercase snake_case; the first token names the source, the rest
   narrows the scope (`imf_sdmx_api.md`, `world_bank_wbgapi.md`).
   `triggers:` is what `retrieve-learnings.sh` globs — a doc without
   one is invisible to retrieval.
   *(`EXAMPLE_world_bank_api.md` still carries v1's Endpoints / Query
   shape / Parsing / Pitfalls headings. Follow this list, not that
   file, until it is reshaped.)*
2. **Run the headline-anchor query at least once** and paste the
   returned value into the doc; set `status: verified <today>` in the
   frontmatter.
   A date stamp without a re-fetchable anchor rots silently — see
   "Verifiable freshness anchors" in `docs/audience-and-philosophy.md`,
   in the framework repo (`r2p init` does not install `docs/`).
3. **Add a row to the Quick navigation table** above so future-you
   finds it.
4. **Cross-link from `CLAUDE.md`** only if the source is core
   enough that an agent would waste time without knowing it
   exists. Most sources don't need the cross-link — the INDEX
   carries them all.

Avoid sub-folders within `research/sources/`. Flat is easier to scan,
and the INDEX's grouping does the organizing work.

---

## Helper functions

Required when the project has a utility module (`<project>_utils.py`
or analogous R file). List each wrapper here so the bridge from "API
mechanics" to "wrapper we already wrote" is one table; a researcher
who hits a strange function name in a notebook jumps here, finds
the row, and lands on the reference doc.

Full protocol (env-var pattern, wrapper signatures, docstring
back-links): `.claude/conventions/sources.md`.

| Helper | Source |
|---|---|
| *(none yet — add `wrapper_name(args)` → `research/sources/<file>.md` as wrappers land)* | — |
