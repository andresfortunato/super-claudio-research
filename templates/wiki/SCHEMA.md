# Wiki schema — how this directory is organized

This file is the authoritative spec for `wiki/` in this project. Read it before
writing any wiki page. The wiki is **LLM-owned**: Claude (via `/wiki-ingest`)
maintains it. Researchers may correct factual errors but should not restructure.

## Mental model

`wiki/raw/` is the immutable archive — papers, scrapes, dataset notes. Never edited.

`wiki/{sources,concepts,entities,synthesis}/` is the distilled, queryable
knowledge layer built *from* `wiki/raw/`. Every claim cites a source page,
which cites a `wiki/raw/` file. This is the Karpathy three-layer pattern:
raw → distilled → schema (this file).

## Page types

Four types. Every page must declare its type in frontmatter.

| Type      | Purpose                                              | Max words | Naming                                |
|-----------|------------------------------------------------------|-----------|---------------------------------------|
| source    | One ingested item from `raw/` — descriptor, not full content | 300       | `wiki/sources/<slug>.md`              |
| concept   | An idea, mechanism, or claim about the world         | 800       | `wiki/concepts/<kebab-case-claim>.md` |
| entity    | A named thing: org, place, dataset, person, program  | 600       | `wiki/entities/<kebab-case-name>.md`  |
| synthesis | Aggregation across ≥3 sources on a single question   | (none)    | `wiki/synthesis/<question-slug>.md`   |

### When to create vs extend

- **Source page**: always one new page per ingested `raw/` file. Never extend.
- **Concept page**: extend if a relevant page exists; create only if the claim is genuinely new. Search `wiki/concepts/` first.
- **Entity page**: extend if the entity exists; create otherwise. One canonical slug per entity.
- **Synthesis page**: only create when ≥3 source pages bear on the same question. Extending a synthesis is normal as new sources arrive — bump `last_condensed` when you do.

## Required frontmatter

YAML frontmatter at the top of every page, between `---` fences.

### Source

```yaml
---
type: source
raw_path: wiki/raw/2026-04-12_studwell_how-asia-works.md
ingested_at: 2026-05-05
title: How Asia Works
author: Joe Studwell
year: 2013
---
```

### Concept

```yaml
---
type: concept
sources:
  - wiki/sources/studwell-2013-how-asia-works.md
  - wiki/sources/cherif-hasanov-2019-tigers.md
related:
  - wiki/concepts/export-discipline-as-industrial-policy-test.md
---
```

`sources` is required and non-empty. `related` is optional.

### Entity

```yaml
---
type: entity
kind: organization  # or: place | dataset | person | program
sources:
  - wiki/sources/world-bank-2023-vietnam-cem.md
---
```

`kind` is required. `sources` required and non-empty.

### Synthesis

```yaml
---
type: synthesis
question: Does industrial policy work in late developers?
last_condensed: 2026-05-05
sources:
  - wiki/sources/studwell-2013-how-asia-works.md
  - wiki/sources/cherif-hasanov-2019-tigers.md
  - wiki/sources/lin-2012-quest.md
---
```

`last_condensed` is required (the lint will flag if missing or >90 days old).
`sources` required, length ≥3.

## Naming conventions

- **Slugs**: lowercase kebab-case. Strip articles ("the", "a"). No dates in slugs except for source pages, where the date prefix from `wiki/raw/` is encoded in the source page's `slug` field, not the filename.
- **Source slugs**: `<author-or-org>-<year>-<short-title>.md`. Example: `studwell-2013-how-asia-works.md`. For scrapes without a clear author: `<source-slug>-<YYYYMMDD>-<title>.md`.
- **Concept slugs**: assert the claim. `industrial-policy-needs-export-discipline.md` is better than `industrial-policy.md`.
- **Entity slugs**: canonical name, English transliteration if needed. `vietnam-state-bank.md`, not `sbv.md` (acronyms are aliased inside the page, not slugged).

## Link conventions

- All links are **relative paths** within `wiki/`: `[Studwell 2013](../sources/studwell-2013-how-asia-works.md)`.
- Every concept and entity page MUST link to at least one source page.
- Every source page MUST link back to its `wiki/raw/` file (relative path, e.g. `../raw/2026-04-12_studwell_how-asia-works.md`).
- Bidirectional linking is expected: if concept X cites source S, and source S advances concept X, S's page should mention X.

## Page structure

Inside the frontmatter fence, use this body skeleton:

### Source page body

```markdown
# <Title>

**Type**: <book / paper / scrape / dataset note / transcript>
**Date**: <publication date>
**Raw file**: [<filename>](../raw/<filename>)

## What it is
1-3 sentences.

## Why it's in the wiki
1-2 sentences — what question(s) this source helps answer.

## Touches
- Concepts: [concept-a](../concepts/concept-a.md), [concept-b](../concepts/concept-b.md)
- Entities: [entity-x](../entities/entity-x.md)
```

### Concept page body

```markdown
# <Claim as a sentence>

## Claim
The single-sentence version of what this page asserts.

## Evidence
- <Source 1>: <one-sentence what-it-shows>. [link](../sources/...)
- <Source 2>: ...

## Caveats / counter-evidence
- ...

## Related
- See [other-concept](../concepts/other-concept.md)
```

### Entity page body

```markdown
# <Canonical name>

**Kind**: <organization | place | dataset | person | program>
**Aliases**: <comma-separated alternative names / acronyms>

## What it is
2-3 sentences.

## Relevance
Why this entity matters to the project's questions.

## Sources
- [source-1](../sources/...)
```

### Synthesis page body

```markdown
# <Question this page answers>

**Last condensed**: YYYY-MM-DD
**Sources synthesized**: <n>

## Summary answer
1 paragraph.

## Evidence balance
- For: ...
- Against: ...
- Ambiguous: ...

## Open questions
- ...

## Sources
- [source-1](../sources/...)
- [source-2](../sources/...)
- [source-3](../sources/...)
```

## Worked example: ingesting a paper

A researcher drops `wiki/raw/2026-04-12_studwell_how-asia-works.md` (a markdown
extract of the book) into `wiki/raw/`. They run `/wiki-ingest wiki/raw/2026-04-12_studwell_how-asia-works.md`.

The skill:
1. Reads the file. Identifies it as a book about East Asian industrial policy.
2. Searches `wiki/concepts/` for existing related pages. Finds none.
3. Creates `wiki/sources/studwell-2013-how-asia-works.md` (source, ~250 words).
4. Creates `wiki/concepts/agriculture-first-development-sequencing.md` (concept).
5. Creates `wiki/concepts/export-discipline-as-industrial-policy-test.md` (concept).
6. Creates `wiki/entities/japan-meti.md`, `wiki/entities/south-korea-epb.md`.
7. Adds 5 entries to `wiki/index.md`.
8. Appends one line to `wiki/log.md`.
9. Reports back to the researcher with the list of pages and any caveats.

## What the wiki is NOT

- **Not a dump of `wiki/raw/` content.** Source pages are descriptors, not transcripts.
- **Not a personal notebook.** No first-person voice, no daily log entries, no scratch.
- **Not auto-maintained.** `/wiki-ingest` is explicit. Nothing writes to `wiki/` automatically.
