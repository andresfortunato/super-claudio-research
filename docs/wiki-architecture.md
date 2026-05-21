# Wiki architecture — design rationale

## The problem this solves

Research projects accumulate context that doesn't fit anywhere good.

A growth-diagnostics engagement reads 40 papers, scrapes 150 news articles,
runs interviews, downloads datasets. By month three, the human team
"remembers" most of it; by month six, half is fuzzy; by month nine, when a
new researcher joins or the team revisits a question, that context is
effectively gone. Notebooks reference papers by surname-and-year; nobody
remembers which `data/raw/wb_*.csv` corresponds to which World Bank
indicator pull.

The same problem hits Claude harder, and on a faster clock. Each new session
loads CLAUDE.md and whatever files Claude opens; everything else is gone.
Putting all context into CLAUDE.md doesn't work — the file would be 10k+
lines and load every turn. Conventions help (`.claude/conventions/<name>.md`
loads on demand) but conventions are *protocols*, not *content*.

What's missing is a place for **load-bearing project knowledge** that:
- persists across sessions,
- is queryable without reading everything,
- maintains an audit trail back to primary sources,
- can be extended incrementally as new material arrives,
- doesn't drift from the underlying evidence.

## Karpathy's three layers

The pattern adopted here is Andrej Karpathy's three-layer wiki:

```
wiki/raw/        immutable archive (papers, scrapes, datasets)
wiki/       distilled, schema-conforming pages (LLM-owned)
SCHEMA.md   the rules the LLM follows when writing the distilled layer
```

The schema lives inside the wiki (`wiki/SCHEMA.md`) so it travels with the
project, can be tuned per engagement, and is read-on-demand by the same
skill that writes the distilled pages.

## Page types and why each exists

Four page types, each with a word budget. Budgets are not stylistic
preferences — they're forcing functions against drift.

| Type      | Budget | Why                                                          |
|-----------|--------|--------------------------------------------------------------|
| source    | 300    | A source page is a *descriptor*, not a copy. Anything longer means the page is duplicating `wiki/raw/`. |
| concept   | 800    | A concept is a claim with evidence. 800 words = ~3-5 paragraphs of claim + evidence + caveats. Beyond that, the concept is two concepts. |
| entity    | 600    | Entities are reference cards. They aggregate aliases, dates, and the project's reasons for caring. They should not become essays. |
| synthesis | (none) | Synthesis pages aggregate across ≥3 sources to answer a question. Capping length would defeat the purpose. Instead, require `last_condensed` so they can't quietly rot. |

Synthesis pages compensate for being uncapped by carrying `last_condensed`
frontmatter. The `/wiki-lint` skill flags any synthesis whose
`last_condensed` is >90 days old. Stale synthesis is worse than missing
synthesis — it looks current and isn't.

## Three operations

### Ingest (`/wiki-ingest <wiki/raw/path>`)

Explicit, never automatic. The researcher decides which raw files become
load-bearing knowledge. Auto-ingest would silently bloat the wiki with
every scrape and erode the budget discipline.

Workflow:
1. Read the raw file.
2. Read `wiki/SCHEMA.md` to know the rules.
3. Read `wiki/index.md` to avoid duplicates.
4. Decompose the source into source/concept/entity/synthesis pages.
5. Cross-link.
6. Update `index.md` and append to `log.md`.

### Query

Just reading. Open `wiki/index.md`, scan for the page type or topic, follow
links. No special skill needed; markdown editors and Claude both handle
this natively. The structural discipline of the schema is what makes
queryability possible.

### Lint (`/wiki-lint`)

Audit, no fix. Four checks:
1. **Orphans** — pages with no inbound links.
2. **Contradictions** — pairs of pages with disagreeing claims on the same subject.
3. **Stale synthesis** — `last_condensed` >90 days old.
4. **Budget violations** — pages over their type's word cap; missing `last_condensed` on synthesis.

Lint emits a markdown report; the researcher decides what to act on.

## What this does NOT do

- **No auto-ingest.** Writes to `wiki/raw/` do not trigger `/wiki-ingest`. The
  researcher controls what's load-bearing.
- **No live web fetches.** The wiki is built from `wiki/raw/`; new sources land
  in `wiki/raw/` via the `web-scraping` skill or `/scan-sources` (Phase 7).
- **No automatic conflict resolution.** Lint surfaces contradictions; the
  researcher reconciles by editing pages or adding a synthesis.
- **No versioning beyond git.** The wiki is plain markdown; git is the
  audit trail.
- **No quality enforcement.** Lint catches *structural* problems. Whether
  a concept page makes a defensible claim is on the researcher and the
  ingest skill.

## Tradeoffs accepted

- **LLM-owned writing.** The wiki is written primarily by Claude via
  `/wiki-ingest`. This means the wiki's quality is bounded by the skill's
  prompt and the model's reasoning. We accept this in exchange for the
  wiki actually existing — researcher-maintained wikis don't get
  maintained.
- **Markdown, not a graph DB.** Cross-links are file paths, not foreign
  keys. Renames break links. Lint catches the resulting orphans, but
  there's no referential integrity at write time. The cost: the wiki is
  human-readable in any markdown editor (Obsidian, VSCode, plain `cat`)
  and survives `git diff`. Worth it.
- **Word-count budgets, not token budgets.** Word counts are a coarse
  proxy. We picked them anyway because they're trivial to enforce
  (`wc -w`) and the right order of magnitude.
- **No section-level discipline inside pages.** A 300-word source page
  could be all preamble and no substance. The schema specifies a body
  skeleton, but lint doesn't enforce sections. Prescriptive enough is
  the goal; mechanical enough breaks fluency.

## Extension points

- **Tune the budgets.** Edit `wiki/SCHEMA.md` per project. The lint reads
  budgets from there, not from `SKILL.md`. Higher budgets for
  philosophy-heavy projects, tighter for fast-moving policy work.
- **Add page types.** A project could add a `dataset-version` type with
  its own schema. Update `SCHEMA.md`, update `wiki-lint/SKILL.md` to
  enforce the new budget, update `wiki-ingest/SKILL.md` to know when to
  produce it.
- **Plug in `/scan-sources`.** Phase 7 lands continuous-scrape content in
  `wiki/raw/scraped/<slug>/`. The ingest skill reads those files the same way
  it reads any other `wiki/raw/` content — no changes needed at the wiki layer.
- **Subagent ingest.** For large sources (a 400-page report), `/wiki-ingest`
  can fan out to a subagent that reads chunks and proposes pages, with
  the parent skill doing the merge. Not in v1; the seam is there.

## Provenance

The three-layer design is Karpathy's. The page-type-and-budget refinement
is from this framework — the canonical Karpathy pattern is looser about
what goes in the distilled layer. The 300/800/600/uncapped split was
calibrated against the kinds of sources policy-research projects actually
ingest: short scraped articles, mid-length papers, long books, growing
synthesis docs.

Adopted in this framework because lossy context across sessions is the
single most-cited failure mode in the brainstorms feeding plan v1.
