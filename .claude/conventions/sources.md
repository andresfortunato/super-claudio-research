# Sources — Protocol (v2, merges data-sources and data-access)

**Trigger**: the project needs to fetch from an external API, query a database
that isn't local, re-use a nontrivial codebook (CAES, SITC, CIIU), or wrap any
of that in code.

## What changed in v2 and why

v1 had two conventions and two CLAUDE.md sections for one object:
`data-sources.md` (the reference doc) and `data-access.md` (the Python
wrapper). The tell that they were one mechanism was already in the repo —
`data_sources/INDEX.md` carried a "Helper functions" table whose only job was
wiring the two halves back together. v2 merges them: **one file per source,
covering how it works, how to call it, and what will bite you.**

The source-operational traps that v1 filed in `learnings/` also move here — 24
of the pilot's 70 learnings were things like *a FAOSTAT "API key" is a 1-hour
Cognito token* and *Argentine government hosts fail three ways, two of which
return HTTP 200*. Those belong with the source, not in a separate directory.

## Where sources live

- `research/sources/<source>_<thing>.md`, flat. One file per
  source-and-purpose: `eph_microdata.md`, `imf_sdmx_api.md`,
  `indec_census2022_migration.md`. A source with genuinely distinct subsystems
  gets multiple files rather than one mega-file.
- `research/sources/INDEX.md` — required. An "if you want X, read Y"
  navigation table, **grouped by domain** once the folder passes ~20 files.
  v1's "flat listing of 5–15 scans in seconds" was wrong by 4×: a real 6-month
  engagement runs **40–70** source docs. Flat *storage* still scales; a flat
  *index* does not.
- Files stay flat even at 70. Renaming into subdirectories breaks the `data:`
  frontmatter in every evidence doc that cites them, for no navigational gain
  the INDEX can't provide.
- `_`-prefixed files are cross-source (`_argentine_gov_hosts.md`).

## Required shape

```markdown
---
source: eph_microdata
status: verified 2026-07-23        # verified <date> | stale | retired
triggers: "eph pondera pondiio pp04b aglomerado microdata intensi"
wrapper: eph_fetch                 # function in <project>_utils.py, or "none"
env: [none]                        # env-var names, or [none]
---

# <Source> — <what it gives you>

## What it gives you
<Dimensions, codelists, coverage, frequency, units. Enough to know whether it
answers a question before you fetch it.>

## Access
<Endpoint / package / query shape. The wrapper name and its signature. Auth and
env vars. Rate limits. A copy-pasteable minimal call.>

## Headline anchor
<At least one re-fetchable number with its date, so a future session can tell in
one call whether the source still behaves the way this doc says.
"AR total employment 2024Q4 = 13,412,300 (PONDERA-weighted)".>

## Gotchas
<Numbered. Symptom first, then fix. Variable blanks by vintage, silent
truncation, codes that strip leading zeros, tokens that look like keys.>

## Coverage limits
<Years, geographies, or variables the source does not have — the reason someone
would need a second source.>
```

`## Headline anchor` is the freshness mechanism: a doc claiming
`status: verified 2026-07-23` is checkable in one call. A doc with no anchor
cannot be verified and drifts silently.

## The runtime half

- **`<project>_utils.py`** at project root: one wrapper per documented source,
  each docstring back-linking to its `research/sources/` doc. Importable from
  notebooks and scripts.
- **A documented source with no wrapper is fine** (manual download, one-off
  pull). **A wrapper with no doc is a smell** — wrapping means "callers will
  use this again", and re-use needs the gotchas written down.
- **`.env`** gitignored, **`.env.example`** committed and enumerating every
  env-var name the utils module reads, grouped by source with a one-line
  comment on where to get credentials. Drift between the two is a build break,
  not a style nit.
- **One prefix per source family** (`ATLAS_DB_HOST`, not `DB_HOST`). The prefix
  matches the source doc's filename stem where possible.
- Public APIs needing no credentials get no env vars. Don't invent a key
  variable for a keyless source.
- **`data/`** is the local cache. Large binaries gitignored; `data/README.md`
  is the on-disk inventory and cross-links the source docs.

## Discipline

- Re-verify a doc when you touch its source. Re-run the headline anchor, bump
  `status: verified <date>`, or mark it `stale` and say why.
- A gotcha discovered in a session goes into the source doc **in that session**.
  The cost of not writing it down is paid by whoever hits it next.
- One commit ships the wrapper, the doc, and the `.env.example` row together.

## Distinct from neighbours

- **`research/methods/<topic>.md`** — a trap that only bites *this analysis*
  (which deflator, which aglomerado pooling rule). A trap that bites *anyone
  touching the source* goes here.
- **`research/evidence/`** — what the data showed. This is how to get it.
- **`research/wiki/raw/scraped/`** — *fetched content* from tracked URLs
  (optional mechanism, see `source-registry.md`). Source docs are hand-written
  how-to-access.
- **`data/README.md`** — what's on disk. Source docs are the external systems
  it came from.
