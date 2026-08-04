---
name: wiki-ingest
description: (r2p) Distill a file in raw/ (paper, scrape, dataset note, transcript) into one or more research/wiki/ pages following the project's wiki schema. Use when the user says "ingest this paper", "/wiki-ingest <path>", "add this to the wiki", or otherwise asks to turn a raw source into structured, queryable knowledge. Always explicit — never auto-fires on raw/ writes.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# wiki-ingest

Turn one immutable item in `raw/` into durable, schema-conforming pages in `research/wiki/`. This skill is the only sanctioned writer to `research/wiki/`. The researcher invokes it; the skill decides how the source decomposes into source / concept / entity / synthesis pages.

## Preconditions

- `research/wiki/SCHEMA.md` exists in the project. Read it before doing anything else — it defines page types, frontmatter, and naming.
- `research/wiki/index.md` and `research/wiki/log.md` exist (seeded by `r2p init`).
- The target file lives under `raw/` and is readable. If absent, stop and tell the user.

## Workflow

1. **Read the source.** Open the file in `raw/`. For PDFs, use `pdf-extraction` if needed. For scrapes, the markdown frontmatter already names url/title/date.
2. **Read `research/wiki/SCHEMA.md`** in full. It is the authoritative spec for what to produce.
3. **Read `research/wiki/index.md`** to see what pages already exist. Prefer extending an existing page over creating a duplicate.
4. **Decompose.** Decide which page types this source contributes to:
   - Always: one `source` page summarizing the item itself (≤300 words).
   - Often: one or more `concept` pages (≤800 words each) for ideas the source advances or evidences.
   - Sometimes: one or more `entity` pages (≤600 words each) for named organizations, places, datasets, people referenced.
   - Rarely (only on explicit request, or when ≥3 sources now converge): a `synthesis` page (uncapped; `last_condensed` frontmatter required).
5. **Write or extend pages.** Honor the per-type word budget. If a page would exceed budget, split it or condense — do not silently overflow.
6. **Cross-link.** Every concept/entity page MUST link back to its source page(s). Source pages MUST link to the originating `raw/` file by relative path.
7. **Update `research/wiki/index.md`** — add new pages under the right section; do not remove existing entries.
8. **Append to `research/wiki/log.md`** — one line:
   `YYYY-MM-DD ingest <raw/path> -> <research/wiki/page1>, <research/wiki/page2> (<n> new, <m> extended)`
9. **Report back** to the user: the list of pages created/extended, any budget violations you had to resolve by splitting, and any ambiguity you punted (e.g. "this could be its own concept page; left as a section under existing concept X — flag if you disagree").

## Rules of thumb

- **Don't paraphrase the whole source into a source page.** A source page is a 300-word descriptor: what it is, why it's in the wiki, what concepts/entities it touches. The full content stays in `raw/`.
- **Concept pages are claims, not summaries.** A good concept page asserts something about the world and cites sources for each claim. Bad: "This page is about industrial policy." Good: "Industrial policy works conditional on state capacity (Cherif & Hasanov 2019; Studwell 2013)."
- **Never edit `raw/`.** `raw/` is immutable. If the source is wrong, note the correction in the wiki page, don't rewrite the raw.
- **One source per ingest invocation.** If the user gives a directory, ingest one file per run — easier to review, easier to log.

## Invocation example

```
User: /wiki-ingest raw/2026-04-12_studwell_how-asia-works.md
```

Skill will:
1. Read `raw/2026-04-12_studwell_how-asia-works.md` and `research/wiki/SCHEMA.md`.
2. Create `research/wiki/sources/studwell-2013-how-asia-works.md` (source, ≤300w).
3. Create or extend `research/wiki/concepts/agriculture-first-development-sequencing.md` (concept).
4. Create or extend `research/wiki/concepts/export-discipline-as-industrial-policy-test.md` (concept).
5. Create or extend `research/wiki/entities/japan-meti.md`, `research/wiki/entities/south-korea-epb.md` (entities).
6. Update `research/wiki/index.md` to list the four new/extended pages.
7. Append one line to `research/wiki/log.md`.
8. Report: "5 pages touched: 1 source (new), 2 concepts (1 new, 1 extended), 2 entities (new). No budget violations."

## What this skill does NOT do

- Does not auto-trigger on `raw/` writes — the researcher decides what becomes load-bearing.
- Does not fetch web content. Use `web-scraping` or `/scan-sources` for that; the output lands in `raw/`, then you ingest.
- Does not delete or rewrite existing wiki pages without the user's explicit say-so. Extending is safe; restructuring is a conversation.
- Does not run lint. Use `/wiki-lint` after ingest to catch orphans, contradictions, or stale synthesis pages.
