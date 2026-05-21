# Source-registry mechanism — design rationale

## The problem this solves

Policy-research engagements depend on a moving body of public
information: investment-deal wires, ministerial bulletins,
infrastructure trackers, exchange disclosures, sector news. The
researcher needs to re-look at a known set of sources every few days,
pull the new items, and decide which (if any) become load-bearing
knowledge in the project's wiki.

Without scaffolding, this is one of two failure modes:

- **Manual revisit.** Open ten browser tabs every Monday, skim, copy
  interesting bits into a notes doc. Loses the audit trail; loses the
  question "did we ever look at X for date range Y." Falls apart the
  moment a second researcher joins the engagement.
- **Crawl everything.** Point a generic crawler at the project's
  domains and let it run on a cron. Produces volume the researcher
  can't read; charges tokens for every duplicate; couples the project
  to always-on infrastructure.

The source-registry sits between these. A small, curated, project-shared
YAML file lists exactly what to track, at what cadence, with what
extraction method. A user-invoked skill (`/scan-sources`) reads it,
fetches what's due, dedupes, lands new content, and updates the
ledger. Nothing fires on a clock.

## Why a YAML registry, not a database

Considered and rejected: SQLite (binary, can't review in an editor,
overkill for ~20 entries), CSV (no nesting for `notes` blocks, hostile
to commits), free-form markdown (no schema, can't validate). YAML
wins because:

- **Editable.** The researcher curates entries. YAML is the cheapest
  format for hand-edits with comments and block scalars.
- **Validatable.** A schema check on load (six required fields, two
  enums) catches typos before they become silent bugs.
- **Diffable.** Git diffs of registry edits read cleanly; reviewers
  can see what was added and why.
- **Round-trippable.** `ruamel.yaml` preserves ordering and comments
  on auto-update of `last_scraped` — important because the comments
  *are* the rationale.

## Why JSONL for the dedup log

`wiki/raw/seen.jsonl` is JSON Lines: append-only, greppable, parseable
from Python/R, survives merge conflicts. One row per successful fetch.
The dedup key is `(slug, content_sha256)`; the `url` is informational
(URLs change; content does not).

## Why hash the post-extraction body, not the HTML

Same URL, two different visits, two different raw HTMLs — because
ad networks rotate, because a CSRF token changes, because the page's
own cache-buster query string flipped. If we hashed raw HTML, every
visit would look "fresh" and we'd write duplicates forever.

Hashing the *extracted* body (the markdown after the `content_selector`
applies, or after the `web-scraping` skill's text extraction)
produces a hash over the meaningful content. Two visits to a stable
article yield identical hashes; the dedup works.

This is also why a missing `content_selector` is bad: hashing the
full page body picks up nav menus, footers, and "you might also like"
sidebars, all of which churn — every visit looks fresh, dedup degrades.

## The pieces

### 1. The convention file (`.claude/conventions/source-registry.md`)

Documents the registry schema, the six required fields, the closed-set
enums for category and freq, the dedup logic, and the discipline rules
(registry is the only authority; `last_scraped` is hook-maintained;
the seen-log is append-only). Read on demand by Claude when the user
mentions sources, scraping, or the registry.

### 2. The `/scan-sources` skill (`.claude/skills/scan-sources/SKILL.md`)

The invokable workflow. Reads the registry, applies filters
(`--slug`, `--category`, `--force`), checks freq for each entry,
delegates fetching to the existing `web-scraping` skill, computes the
content hash, dedupes against `seen.jsonl`, writes new content to
`wiki/raw/scraped/<slug>/`, updates `last_scraped` in the registry. Reports
a structured per-run summary. The audit trail is git history of the
registry plus the per-fetch frontmatter on each `wiki/raw/scraped/*` file —
no separate run log.

### 3. The templates (`templates/wiki/raw/{registry.yaml,README.md}`)

Seeded by `r2p init` into target projects. The registry has four
commented examples covering the four "shape" archetypes
(investment-news daily/httpx, company-filings weekly/playwright,
infrastructure-tracker monthly/scrapegraph, policy-news weekly/crawl4ai).
The README explains how to register, retire, force, and query.

### 4. The CLAUDE.md pointer (~5 lines)

Tells Claude the registry exists, points at the convention file for
the schema, and notes that scrapes land in `wiki/raw/scraped/<slug>/` and
require `/wiki-ingest` for wiki promotion.

### 5. Audit trail (git, not a separate log)

Every `/scan-sources` invocation that produces fresh content lands files
under `wiki/raw/scraped/<slug>/` (with full frontmatter: url, scraped_at,
content_sha256, title) and bumps `last_scraped` in the registry. Both
are committed normally. To reconstruct what was fetched when:

```bash
git log -- wiki/raw/registry.yaml          # registry edits, including last_scraped bumps
git log -- wiki/raw/scraped/                   # every fresh-content commit
```

Failures and duplicates show up in the per-run report (stderr / chat
output) but are not persisted to a separate log. Rationale: the
registry's `last_scraped` already changes on failure (so we don't
re-hammer); a persistent failure log was overkill for the typical use
case. If a source breaks chronically, the researcher will notice in the
per-run reports and either retire the entry or fix the `scrape_method`.

## Freq logic — why these four buckets

Considered and rejected: free-form intervals (`every 4 hours`,
`every 36 hours`). They look flexible but in practice researchers
choose between "every day," "every week," "every month," or "never
auto." A four-element enum captures all the real cadences and has
the side benefit of making the registry skim-readable: a glance tells
you the volume.

`adhoc` is the escape hatch: sources you want in the registry (so
they're visible to the team and dedupable) but never want auto-fetched.
Examples: a paywalled site you'll only re-fetch when a specific event
fires; an expensive scrapegraph extraction you trigger by hand.

The freq window is a *minimum*; `/scan-sources` doesn't fire on its
own. So a `daily` entry isn't fetched 365 times a year — it's
fetched only when the researcher invokes the skill *and* ≥24h have
elapsed. In practice, a researcher who runs `/scan-sources` twice a
week sees daily entries fire on each invocation; the freq just
prevents redundant fetches within a single session.

## Dedup logic — what counts as a duplicate

A fetch is a duplicate if:
- Same `slug` (we don't dedup across sources — two different outlets
  reporting the same story are two stories from the project's POV),
- Same `content_sha256` (post-extraction body).

URL doesn't enter the dedup decision because URLs change (the article
moved; the index URL got a query parameter). Content is the truth.

When a duplicate is detected:
- No new file is written under `wiki/raw/scraped/<slug>/`.
- `last_scraped` in the registry IS updated (we did fetch).
- The duplicate is reported in the per-run output.
- `seen.jsonl` is NOT appended (the prior row already represents this
  content).

## Why-not-cron-everything (rationale repeated for the skeptics)

The naive design is "scrape every registered source on a cron, push
notifications when something new shows up." It fails on every axis:

- **Volume.** A daily source typically yields 0–2 new items per day
  that are interesting; a researcher can't read 50 daily-curated
  notifications across a year-long engagement.
- **Cost.** Token charges accrue per fetch, even for duplicates the
  researcher will never look at. With LLM-extraction (`scrapegraph`)
  this gets expensive fast.
- **Infrastructure.** A cron requires an always-on host, secrets
  rotation, monitoring, alerting on failures — none of which a
  research repo should own.
- **Mental-model mismatch.** The researcher's natural rhythm is
  "going to look at sources now, refresh them all" — episodic, not
  continuous. The registry encodes the *what*; the researcher
  decides the *when*.

`/scan-sources` is a deliberate user-invoked operation. The freq
field exists to prevent redundant fetches *within a session*, not to
schedule the researcher.

## Why-not-bookmarks (rationale repeated for the skeptics)

The other naive design is "just keep a `bookmarks.md` file with URLs
and titles." It fails because:

- **No structure for the skill to consume.** Which bookmarks should
  be re-fetched? At what cadence? With what extraction method? The
  bookmarks file is fundamentally unstructured.
- **No dedup primitive.** Two researchers add the same URL with
  different titles; no way to detect.
- **No category for filtering.** Want to scan only investment
  sources? The bookmarks file has no notion of category.
- **No `last_scraped` discipline.** The bookmarks file is editable;
  the registry's `last_scraped` is skill-maintained. The skill
  knows what's due; the bookmarks file does not.
- **No retire-without-delete pattern.** A bookmark is either there
  or not. The registry's `freq: adhoc` lets you preserve the audit
  trail of past tracking without continuing to fetch.

The registry is a small amount of typing for a large amount of
structure. It's worth it.

## Tradeoffs accepted

- **Registry is hand-edited.** No `/source add <url>` skill. Adding
  a slug, picking a category, choosing a method, writing a `notes`
  rationale — these are decisions the researcher should make
  deliberately, not automate. A bad slug or wrong method propagates.
- **Hash collisions are theoretically possible.** sha256 over
  human-scale content makes this vanishingly unlikely. If you see one
  in practice, file a bug; the more likely explanation is that two
  pages have content_selectors that capture the same boilerplate.
- **Multi-page sources require multiple entries.** A registry entry
  is one URL. Sites with paginated indexes (page 1, 2, 3) need either
  multiple entries (if the per-page URLs are stable) or a
  `crawl4ai`-driven entry with depth-limited config in `notes`. We
  did not build a "follow next-page links" primitive in v1; the
  researcher curates.
- **`last_scraped` updates even on failure.** A 503 from a flaky
  source still bumps the timestamp. This prevents hammering a
  broken URL but also means a chronically-broken source isn't
  obvious from the registry alone — the researcher must read the
  per-run reports. The summary mitigates this in the common case;
  for systematic monitoring, scan `git log -- wiki/raw/registry.yaml`
  for entries whose `last_scraped` keeps advancing without matching
  commits under `wiki/raw/scraped/<slug>/`.
- **No locking on parallel runs.** Two `/scan-sources` invocations
  in parallel could race on `seen.jsonl` and `registry.yaml` writes.
  The skill is invoked by humans, not daemons; this is not expected
  in practice. If it becomes one, add an `flock` step.

## Extension points

- **Categories list.** The seven-element enum
  (`investment | company | innovation | infrastructure | policy | news | other`)
  is opinionated for development-research projects. Edit
  `.claude/conventions/source-registry.md` to add domain-specific
  categories (e.g. `health`, `agriculture`) — but keep the list
  closed; free-form categories defeat the filter.
- **Freq buckets.** Same — the four buckets are deliberate. Adding
  a fifth (e.g. `quarterly`) is fine if the project genuinely needs
  it; updating both the convention and the skill's due-detection
  block keeps them in sync.
- **Scrape methods.** The four methods
  (`httpx | playwright | scrapegraph | crawl4ai`) are the ones the
  `web-scraping` skill supports. Adding a method is a `web-scraping`
  edit first, then a registry-convention edit.
- **Per-entry rate limits.** Currently inherited from the
  `web-scraping` skill globally. If a single source needs throttling
  beyond the global default, add a `rate_limit_seconds` optional
  field — easy extension.
- **Auto-promotion to wiki.** Deliberately omitted from v1. If a
  pilot finds the explicit `/wiki-ingest` step too friction-heavy,
  consider an `auto_ingest: true` field per registry entry — but
  start with the friction; load-bearing knowledge benefits from
  human curation.

## Provenance

The hard-won lesson behind this convention: in a Côte d'Ivoire
diagnostic, a chart showing the timing of port-throughput
deceleration was undermined when a counterpart pointed out that the
underlying tracker had been re-scraped six times across the
engagement, with no record of which pull supported the chart. The
source-registry pairs with the `script-header` and
`analytical-commit-format` conventions on the analytical side: the
registry + `wiki/raw/scraped/*` frontmatter answers "where did this
content come from"; the script header + commit `Run:`/`Out:` lines
answer "which pull, by which script, produced this chart." Together
they trace a number all the way back to a URL and a date.
