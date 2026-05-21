# Data-sources mechanism — design rationale

## The problem this solves

Policy-research engagements depend on multiple external data
sources — IMF SDMX, World Bank wbgapi, OECD.Stat, UN Comtrade,
the Atlas of Economic Complexity DB, country-specific portals.
Each has its own auth scheme, query language, response shape,
and pitfalls — most of which are *not* in the official docs and
take hours of session time to re-discover.

Without scaffolding, this is one of two failure modes:

- **Re-discovery on each session.** Claude session N looks up
  the IMF SDMX endpoint, learns that the SDMX 2.1 path returns
  403 (it was retired), figures out that 3.0 needs
  `format=jsondata` to return parseable JSON, and finally gets
  a query through. Session N+1, fresh context, repeats the
  entire chain. Wasted tokens, wasted wall-clock, and the
  workaround details (which positions in a key silently return
  empty series, which renames happened — CDIS → DIP) scatter
  across throwaway notebooks.
- **One-off notes in a single notebook.** Researcher pastes the
  hard-won knowledge into the notebook that needed it. Six
  months later, the knowledge has not propagated, and the next
  analysis starts from zero.

The data-sources convention sits between these. A flat folder of
`<source>_<thing>.md` reference docs — verified against a real
query, with a headline anchor that proves verification — turns
the hard-won knowledge into project-shared, freshness-checkable
documentation.

## Why a flat folder

Considered and rejected: nested by source family
(`data_sources/imf/sdmx_api.md`, `data_sources/imf/weo_api.md`,
`data_sources/world_bank/wbgapi.md`). The nesting looks tidy at
ten files but hurts at two. Most engagements never grow past
~15 reference docs; a flat folder scans in seconds and the
INDEX's grouping does the organizing work.

Also rejected: a single mega-`data_sources.md` covering every
source. Reads as a wall of text; tools like `grep` work less
well; a researcher looking up "how does the WB API handle
missing years" has to scroll past nine other sources'
documentation to find the answer. One-file-per-purpose wins.

The constraint: filenames carry the structure that nesting
would. `imf_sdmx_api.md`, `imf_weo_api.md`,
`imf_dataflow_inventory.md` group naturally under the `imf_`
prefix in any sorted listing; the INDEX then groups them
visually for human readers.

## Why a required INDEX.md

Considered and rejected: rely on the directory listing alone
(the folder name suffices). It does for ~5 files; past that, a
researcher hunting for "does this project have a doc on
Comtrade?" ends up `ls`-ing and grepping titles. The INDEX is a
30-second write that saves 30 seconds on every subsequent
lookup.

The INDEX has three required parts:

1. **Quick navigation table** — "If you want X, read Y." The
   table is the fastest path from a researcher's question to
   the right doc. Sorted by likely access frequency, not
   alphabetically.
2. **Files in this folder** — a brief gloss per file, grouped
   by source family.
3. **How to add a new source** — the recipe, three or four
   bullets. Keeps the discipline honest.

The fourth part is a list of helper functions in the project's
utility module that front the documented sources. This bridges
"here's the API" with "here's the wrapper we already wrote," and
is **required** when the project has a utility module. The
sibling `data-access` convention prescribes the wrappers' shape
(env-var pattern, function signatures, docstring back-links); this
convention requires the INDEX table to exist and map wrappers to
reference docs.

## Why headline anchors are first-class

The anchor is the discipline's load-bearing piece. Without it,
a `Status: verified 2026-05-04` line is unfalsifiable — no
future reader can cheaply check whether the doc still describes
reality.

A headline anchor is a concrete value the documented procedure
produces: "the SDMX query for KHM 2009 bilateral inward FDI
from China returns $1.113B"; "the World Bank wbgapi
`wb_fetch('NY.GDP.MKTP.CD', 'KHM', range(2010, 2020))` returns
ten observations, the 2015 value being roughly $18.05B."
Future-Claude can re-run the documented procedure and check the
value matches; if it doesn't, the doc has rotted and needs an
update before being trusted.

The cross-cutting principle is in
`docs/audience-and-philosophy.md` (Principle 9, Verifiable
freshness anchors). Both the data-sources convention and the
methods convention reference it; neither duplicates it. The
principle binds future ref-doc conventions too: any folder
whose claims age out should adopt the pattern.

## The pieces

### 1. The convention file (`.claude/conventions/data-sources.md`)

Documents the boundary with `wiki/raw/scraped/`, `wiki/concepts/`,
and `data/README.md`; the required sections per doc; the
headline-anchor discipline; the INDEX schema; the naming
pattern; and the recipe for adding a source. Read on demand by
Claude when the user mentions an external API, a codebook, or
asks "where do I document the X data source."

### 2. The templates (`templates/data_sources/{INDEX.md,README.md,EXAMPLE_world_bank_api.md}`)

Seeded by `r2p init` into target projects.

- `INDEX.md` — empty quick-nav table and the "how to add a
  source" recipe, ready for the project's first entry.
- `README.md` — one-liner pointing at the convention.
- `EXAMPLE_world_bank_api.md` — generic worked example with
  all required sections, including a real-shape headline
  anchor. The example's content is illustrative — researchers
  replace it with their first real source — but the *shape*
  matches what this convention requires.

### 3. The CLAUDE.md pointer (~5 lines)

Tells Claude that `data_sources/` exists, names the required
sections, and points at the convention file for the protocol.

### 4. Audit trail (git, not a separate log)

Verification dates and headline anchors live in the doc itself
and in the git history of `data_sources/<source>_<thing>.md`.
To reconstruct what was verified when:

```bash
git log -p -- data_sources/imf_sdmx_api.md | grep -E '^\+.*Status: verified'
```

No separate log; the doc's commit history is the audit trail.

## Why no `/data-sources-lint` skill

Considered and rejected for v1. A lint skill would check that:

- Every doc has a `Status: verified` line.
- Every doc has at least one headline anchor.
- The INDEX has a row for every doc in the folder.

These checks are useful but trivially failable: a missing
`Status` line is loud; a missing INDEX row is found at the
next lookup. The discipline is the convention, not a tool. If
pilot use shows the rules slip frequently, ship a
`/data-sources-lint` skill in v1.x — but start with the
convention.

## Why no auto-extraction of anchors

Considered and rejected: a runner that extracts every doc's
headline anchor, re-fetches the value, and alerts on drift.
Tempting, but it adds always-on infrastructure (a service
host), secrets handling (API keys for every documented source),
and a new failure surface. The convention's deliverable is
markdown discipline; auto-anchor-checking is a v1.x extension,
not a v1 deliverable.

In the meantime, `/verify` covers per-artifact spot checks; a
researcher running `/verify` against a chart that depends on an
IMF figure can re-check the doc's anchor as part of the same
session.

## Boundary with `wiki/raw/scraped/` (revisited)

The two folders are easy to confuse. The clearest rule:

- `wiki/raw/scraped/<slug>/` is *content fetched from a tracked
  URL*, governed by `source-registry`. Files are markdown,
  written by `/scan-sources`, with frontmatter (url,
  scraped_at, content hash). The folder is automated.
- `data_sources/` is *human-written reference documentation
  about external systems*. Files are markdown, written by
  hand, with no frontmatter (the Status line takes its place).
  The folder is curated.

A `data_sources/imf_sdmx_api.md` documents how to query an API.
A `wiki/raw/scraped/policy-bulletin/2026-05-05_central-bank-rate.md`
is a scraped policy announcement. They never overlap — but
they both contribute to the project's evidence base, the former
by making external data legible, the latter by preserving
moving public information.

## Tradeoffs accepted

- **Hand-verified anchors decay.** A researcher who bumps the
  `Status` date without re-running the anchor query has
  corrupted the audit trail. The convention assumes good-faith
  discipline; a future `/data-sources-lint` could check.
- **Headline anchors require a stable reality.** Some sources
  (intraday market feeds, frequently-revised series) have no
  point-in-time anchor. The convention's escape hatch — a
  structural anchor ("the response object has these top-level
  keys") — is weaker but better than nothing.
- **Naming is conventional, not enforced.** A doc called
  `imfSDMX-api.md` would still work but breaks sort order and
  the INDEX's regularity. Convention, not lint.
- **Sub-folder rule is opinionated.** A research engagement
  that wants nested `data_sources/` can ignore the rule;
  nothing enforces flatness. The cost of the opinion is
  occasional pushback; the benefit is the pattern reads
  consistently across pilot projects.

## Provenance

The hard-won lesson behind this convention: in a Cambodia
diagnostic, the IMF SDMX 2.1 endpoint returned 403 for half a
session before the workaround (3.0 at a different URL) was
re-derived from scratch. The next session, fresh context, was
on track to rediscover the same workaround until a researcher
remembered that the prior session had figured it out and
pasted the recipe into a notebook. The convention captures
that recipe — plus the headline anchor that proves it still
works — so the third, fourth, and Nth session don't redo the
work.

The pilot's `data_sources/imf_sdmx_api.md` (verified against
the KHM 2009 China inward FDI = $1.113B anchor) is the working
proof of the pattern.
