# Data Sources — Protocol

**Trigger**: Whenever a researcher needs to fetch from an external
data API, query a database not local to the project, or re-use a
nontrivial codebook (SITC, NACE, COICOP). A `data_sources/` doc
captures the *how* (auth, endpoints, query shape) and the *what*
(dimensions, codelists, gotchas) for one external source — so the
next session, yours or a teammate's or one a year from now, does
not re-discover it.

This convention defines a flat folder of reference documentation,
one `<source>_<thing>.md` per external API or dataset. Bulk data
goes elsewhere; this folder holds **how to access**, not the data
itself.

## Boundary with neighbors

Three folders look adjacent and would be confusing if researchers
reinvented the boundaries:

- **`raw/sources/<slug>/`** is *fetched content* — markdown files
  scraped from tracked URLs, governed by the source-registry
  convention. `data_sources/` is *how-to-access* docs, written
  by hand. The two never overlap: a registry entry watches a
  news outlet; a `data_sources/` doc explains the IMF SDMX
  endpoint.
- **`wiki/concepts/`** is *distilled domain claims with
  citations* — "Cambodian electronics exports tripled
  2020–2023". `data_sources/` is *operational mechanics* —
  "to retrieve those numbers, hit `/data/dataflow/...`". A
  wiki concept may cite numbers a data-sources doc explains how
  to fetch.
- **`data/README.md`** documents *what data files live on disk*
  (the local PostgreSQL DB, the CSVs in `data/raw/`).
  `data_sources/` documents *the external systems those files
  came from*. They cross-link.

## Where data-source docs live

- Single folder: `data_sources/` at the project root.
- One file per source-and-purpose: `<source>_<thing>.md`.
  Naming is conventional — `imf_sdmx_api.md` (IMF, the SDMX
  API), `imf_weo_api.md` (IMF, WEO indicators),
  `world_bank_wbgapi.md` (World Bank, the wbgapi client),
  `oecd_dotstat.md`. If a single source spawns multiple
  distinct subsystems, split into multiple files rather than
  building one mega-file.
- The folder is **flat** — no subdirectories. With ~5–15 docs
  per engagement, a flat listing scans in seconds; subdirectories
  add bureaucracy without orienting.
- `data_sources/INDEX.md` is required. The index has a "if you
  want X, read Y" navigation table and a short "how to add a
  new source" recipe. Researchers update the INDEX when adding
  files.
- The folder is **committed**. Reference docs are project-shared
  knowledge; the team needs the same picture of the data
  landscape.

## Required sections per doc

Every `data_sources/<source>_<thing>.md` opens with these, in
this order:

| Section | What it carries |
|---|---|
| **Status** | One line: `**Status**: verified <YYYY-MM-DD>` plus what changed since the last verification. |
| **Headline anchor(s)** | At least one concrete value future-Claude can re-fetch as a smoke test (see "Verifiable freshness anchors" in `docs/audience-and-philosophy.md`). |
| **Endpoints / access** | Base URL, auth scheme (none / API key / OAuth), header requirements. |
| **Query shape** | The path syntax, query parameters, response format. Worked example with a real URL. |
| **Parsing / decoding** | The smallest code block that turns a response into a tidy frame (Python or R; matches the project's idiom). |
| **Pitfalls** | Empty-result silent-fail modes, retired endpoints, naming gotchas, rate limits. |

These are required. A doc may add — and most should — sections
for codelist cheatsheets, dimension-order tables, agency
landscapes, and dataset-family quick references. Extra sections
are fine; missing required sections are a smell.

## The status-and-anchor pattern

The `Status` line and the headline anchor are the *cross-cutting
discipline* this convention shares with `methods.md`. The
rationale lives once in `docs/audience-and-philosophy.md` —
"Verifiable freshness anchors". In short: a date stamp without a
re-fetchable anchor rots silently. A date stamp paired with a
concrete number ("KHM 2009 inward FDI from China = $1.113B") lets
future-Claude run a one-line check that confirms or invalidates
the doc's claims.

The anchor is most useful when:

- It's bilateral / specific (a country-year-indicator triple,
  not a regional aggregate that quietly re-bins).
- It's stable across reasonable vintages (an IMF DIP figure from
  2009 won't be revised; a 2024 figure might).
- It's named alongside the URL or query that produced it, so
  re-fetching is one paste away.

If a source genuinely has no stable anchor (a daily news feed, a
streaming API), document why and use a *structural* anchor
instead ("the response object has these top-level keys";
"the codelist contains 20 codes").

## INDEX.md schema

`data_sources/INDEX.md` carries:

1. **Quick navigation table** — `If you want X | Read Y`. Three
   to ten rows; sorted by likely access frequency, not
   alphabetically.
2. **Files in this folder** — short table grouping files by
   source family (e.g. all IMF docs together, then World Bank,
   then OECD).
3. **Conventions for adding new sources** — three or four
   bullet points: drop the spec, add a usage guide, add an
   INDEX row, cross-link from CLAUDE.md if core.
4. **Helper functions** — list the wrappers in
   `<project>_utils.py` (or analogous R file) and which source
   each fronts. This is the bidirectional bridge from "here's how
   the API works" to "here's the wrapper we already wrote," and
   is **required** whenever the project has a utility module.
   Pattern, signatures, and discipline rules live in the sibling
   `.claude/conventions/data-access.md`.

## Naming

- File names are lowercase, snake_case: `imf_sdmx_api.md`, not
  `IMF SDMX API.md` or `imf-sdmx-api.md`. Consistency matters
  more than the exact rule.
- The first token names the source (`imf`, `world_bank`,
  `oecd`, `unctad`, `un_comtrade`). The remaining tokens narrow
  the scope (`sdmx_api`, `weo_api`, `dataflow_inventory`).
- Codebooks and reference tables that aren't *access* docs but
  belong in the same folder (e.g. `sitc_codes.md`,
  `pwt110_columns.md`) follow the same naming. The INDEX
  disambiguates.

## Discipline rules

- **Verify before claiming verified.** A `Status: verified
  2026-05-04` line means the author re-ran the headline anchor
  query and got the documented value on that date. Bumping the
  date without re-running is a lie waiting to be caught.
- **Edit, don't accumulate.** When an API changes, edit the doc
  in place — don't append "UPDATE: now use endpoint Y." Git
  history is the version log; the doc reads as the current
  truth.
- **Cross-link from CLAUDE.md only for the core sources.** Every
  data-sources doc does not need a CLAUDE.md mention; the INDEX
  carries them all. Promote a source to CLAUDE.md only if a
  Claude session would waste time without knowing it exists.
- **Avoid sub-folders.** Flat is easier to scan, and the INDEX's
  grouping does the organizing work. If the folder grows past
  ~20 files, split *the project* into focused engagements — not
  the folder into hierarchies.
- **Project-utility-module rules live in the sibling convention.**
  How wrappers like `imf_sdmx_fetch()` are organized (env vars,
  function signatures, docstring back-links to these docs) is the
  scope of `.claude/conventions/data-access.md`. The two
  conventions cross-link via the INDEX's "Helper functions" table:
  this convention requires the table to *exist* and *map wrappers
  to reference docs*; data-access prescribes the wrappers' shape.

## Adding a new source — recipe

1. Create `data_sources/<source>_<thing>.md` with the required
   sections.
2. Run the headline-anchor query at least once and paste the
   returned value into the doc; record `Status: verified
   <today>`.
3. Add a row to `data_sources/INDEX.md`'s navigation table.
4. If the source is core to the project (a Claude session would
   waste time without knowing it), add a one-line mention in
   `CLAUDE.md`'s Data Sources section.
5. If a helper function in the project's utility module fronts
   the source, cross-link both ways.

> **Transplanting from another r2p project?** Use
> `/r2p-migrate-source --from <donor-path> --source <slug>` instead
> of hand-writing — it lifts the ref doc (with the donor's
> headline anchor stripped to a `TODO(migrate)`) and the rest of
> the source's data layer in one proposal-then-apply cycle.

## What this convention does NOT cover

- **The data files themselves** — `data/README.md` documents
  what's on disk; this folder documents how to fetch more.
- **Periodic re-scraping of public web pages** — the
  source-registry convention covers tracked URLs and
  `/scan-sources`. A `data_sources/` doc is for APIs and
  codebooks, not RSS-style polling.
- **Bulk download retrieval** — if a source is "download a
  500MB CSV from a portal once," document the download URL
  and the local cache path; the API mechanics section becomes
  one line ("not an API; manual download").
- **Auth secrets** — never commit keys. Document the env-var
  name (`IMF_API_KEY`, `WB_TOKEN`) and how to obtain one; the
  secret itself stays in the researcher's local environment. The
  env-var naming convention, `.env.example` contract, and how
  wrappers read these values are scoped to
  `.claude/conventions/data-access.md`.
