# research/wiki/

Distilled, queryable project knowledge plus the immutable raw layer it's
built from. Owned by Claude.

## Mental model

```
research/wiki/raw/   → immutable source material (papers, scrapes, dataset notes)
research/wiki/       → distilled pages with claims, citations, cross-links
```

A claim in `research/wiki/` always cites a source page. A source page always cites
a file in `research/wiki/raw/`. The chain back to evidence is unbroken.

## What goes where

| Goes in `research/wiki/raw/`                       | Goes in `research/wiki/<page-type>/`                  |
|-------------------------------------------|----------------------------------------------|
| The PDF of a paper                        | A source page summarizing the paper          |
| A scrape of a news article (full HTML→md) | A concept page citing the article            |
| A dataset codebook                        | An entity page about the dataset             |
| A transcript                              | An entity (person) and concept pages it touches |

If you're tempted to write something in `research/wiki/raw/`, you're using it wrong.
If you're tempted to read the full text of a paper from a wiki page,
you're using it wrong.

## Ownership

- **Claude owns the wiki.** The `/wiki-ingest` skill is the sanctioned writer.
- **Researchers may correct factual errors.** If a wiki page misstates what a source says, fix the page directly — it's just markdown.
- **Researchers should not restructure.** Renaming pages, splitting concepts, or changing the schema breaks links and confuses the lint. Talk to Claude first (`/wiki-ingest` can refactor on instruction).

## Layout

```
research/wiki/
├── README.md          (this file)
├── SCHEMA.md          ← authoritative format spec; read first
├── index.md           ← the catalog, updated by /wiki-ingest
├── log.md             ← append-only ingest log
├── sources/           ← page type: descriptors of raw/ items (300w cap)
├── concepts/          ← page type: claims with evidence (800w cap)
├── entities/          ← page type: reference cards (600w cap)
├── synthesis/         ← page type: cross-source answers (no cap, last_condensed required)
└── raw/               ← immutable archive layer
    ├── README.md
    ├── registry.yaml  ← scrape watchlist
    ├── seen.jsonl     ← dedup ledger
    └── scraped/       ← /scan-sources output
```

Page-type directories are created on first ingest.

## Operations

- `/wiki-ingest <research/wiki/raw/path>` — distill one raw file into wiki pages.
- `/wiki-lint` — audit for orphans, contradictions, stale synthesis, budget violations.
- `/scan-sources` — refresh tracked sources from `research/wiki/raw/registry.yaml`.

Querying is just reading: open the page, follow the links, drop into chat.
