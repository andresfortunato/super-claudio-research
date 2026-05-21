# Source Registry — Protocol

**Trigger**: Whenever a researcher wants to track a URL (news outlet,
ministry page, company-filings index, infrastructure tracker, policy
blog) for periodic re-scrape over the life of an engagement. Registry
edits are manual; scraping is invoked via `/scan-sources`.

This convention defines the **single source of truth** for what gets
periodically scraped. There are no free-form bookmarks, no cron jobs
crawling the web, no LLM-discovers-its-own-sources. A URL gets
re-fetched only if it is listed in `wiki/raw/registry.yaml`.

## Where the registry lives

- Single file: `wiki/raw/registry.yaml` (collocated with the
  immutable raw layer that holds the scraped output).
- Sidecar: `wiki/raw/seen.jsonl` — append-only dedup log of every
  fetched item's content hash. Written by `/scan-sources`; never edited
  by hand.
- Both files are **committed**. The registry is project-shared
  knowledge: every researcher on the engagement should know what's
  being tracked. The seen-log is committed too so dedup survives a
  fresh clone.
- Scraped output lands under `wiki/raw/scraped/<slug>/YYYY-MM-DD_<title-slug>.md`,
  one file per fetched item. Governed by `wiki/raw/`'s immutability rule
  (see `wiki/raw/README.md`).

## Registry schema

YAML list, one entry per source. Required fields per entry:

| field             | type   | meaning                                                                 |
|-------------------|--------|-------------------------------------------------------------------------|
| `slug`            | string | short kebab-case identifier; used as directory name under `wiki/raw/scraped/` |
| `url`             | string | the page to fetch                                                       |
| `category`        | enum   | one of `investment` \| `company` \| `innovation` \| `infrastructure` \| `policy` \| `news` \| `other` |
| `freq`            | enum   | one of `daily` \| `weekly` \| `monthly` \| `adhoc`                       |
| `last_scraped`    | string\|null | ISO8601 UTC of most recent fetch attempt (auto-updated by `/scan-sources`) |
| `scrape_method`   | enum   | one of `httpx` \| `playwright` \| `scrapegraph` \| `crawl4ai`           |
| `content_selector`| string\|null | optional CSS selector or XPath narrowing the page to its meaningful body (e.g. `article.main-content`) |
| `notes`           | string\|null | free-text — why this source is on the list, watch-fors, gotchas |

Use `null` (or omit) for `content_selector`, `notes`, and the initial
`last_scraped`; never omit the required fields.

### Categories — what each one is for

- **investment** — investment-news outlets, FDI trackers, deal databases.
- **company** — corporate filings, exchange disclosures, IR pages.
- **innovation** — patent offices, R&D bulletins, tech-transfer trackers.
- **infrastructure** — project trackers (ports, rail, energy, telco rollout).
- **policy** — ministerial pages, regulatory bulletins, central-bank notices.
- **news** — general news outlets covering the country/sector.
- **other** — escape hatch; use sparingly and document in `notes`.

### Freq — what each one means

- **daily** — re-fetch when ≥24 h have elapsed since `last_scraped`.
- **weekly** — re-fetch when ≥7 d have elapsed.
- **monthly** — re-fetch when ≥30 d have elapsed.
- **adhoc** — never auto-due. Only fetched when the researcher passes
  `--slug=<slug>` or `--force`. Reserve for sources expensive to scrape,
  rate-limited, or known-stable.

### Scrape methods

These map to the existing `web-scraping` skill's tooling:

- **httpx** — fast HTTP GET + BeautifulSoup. Default for static HTML.
- **playwright** — headless browser. Use when the page renders JS or
  requires login.
- **scrapegraph** — LLM-driven extraction. Use when structure is
  irregular and a CSS selector won't hold.
- **crawl4ai** — markdown-first crawler. Use for content-heavy sites
  where you want clean prose, not raw HTML.

Pick the cheapest method that works. Upgrade only when the cheap one breaks.

## Scraped-content frontmatter

Every file `/scan-sources` writes to `wiki/raw/scraped/<slug>/YYYY-MM-DD_<title-slug>.md`
carries this YAML frontmatter:

```yaml
---
url: https://example.com/article-path
source_slug: investment-news-cambodia
category: investment
scraped_at: 2026-05-05T14:32:11Z
content_sha256: 9f1c...e3a4
title: <title extracted from page>
---
```

Body is markdown — converted from the page's `content_selector` region
(or the full body if no selector). Preserve links and headings; drop
boilerplate (nav, footer, ads).

## Dedup — how it works

Same URL fetched twice should not produce two files in `wiki/raw/scraped/<slug>/`.
The dedup key is `content_sha256` — the sha256 of the **post-extraction
body** (not the raw HTML, which is volatile due to ads and tracking).

`wiki/raw/seen.jsonl` is the dedup ledger. One JSON object per line:

```json
{"slug": "investment-news-cambodia", "url": "https://example.com/article", "content_sha256": "9f1c...e3a4", "scraped_at": "2026-05-05T14:32:11Z", "raw_path": "wiki/raw/scraped/investment-news-cambodia/2026-05-05_new-port-deal.md"}
```

`/scan-sources` checks `seen.jsonl` before writing each file. If
`content_sha256` already exists for that slug, the new fetch is
discarded — but `last_scraped` in the registry is still updated (we
*did* re-fetch; we just got nothing new).

## Why not cron-everything

Considered and rejected. A cron job crawling every source on a
schedule produces:

- Volume the researcher can't read (most fetches are duplicates or
  noise; the registry is curated; the cron is not).
- Token cost on every run, whether or not a human will look.
- Dependency on always-on infrastructure (the laptop doing the cron),
  which fails the "works on a fresh clone" test.
- A pipeline divorced from the researcher's mental model. Scraping
  should fire when the researcher decides to look, not on a wall clock.

`/scan-sources` is a deliberate user-invoked operation. The freq field
limits redundant fetches *within* a session, not across time.

## Why not free-form bookmarks

A `bookmarks.md` of "interesting URLs" was the simpler alternative.
Rejected because:

- No structure for `/wiki-ingest` to consume — how does the skill know
  which bookmarks are worth re-fetching versus one-off curiosities?
- No dedup — two researchers add the same URL with different titles.
- No category/freq — every source gets the same treatment.
- No audit trail — the bookmark file is editable; the registry's
  `last_scraped` is hook-maintained.

The registry is a small amount of typing for a lot of structure.

## Discipline rules

- **The registry is the only authority.** A URL that isn't in the
  registry should not be scraped by `/scan-sources`. One-off scrapes
  for a specific question go through the `web-scraping` skill directly
  and land at `wiki/raw/<date>_<slug>.md` (loose), not under `wiki/raw/scraped/`.
- **`last_scraped` is hook-maintained.** Never edit by hand. If a
  source's last fetch was bad and you want to re-fire, use
  `/scan-sources --slug=<slug> --force`.
- **`wiki/raw/seen.jsonl` is append-only.** Never delete rows. If you
  truly want to re-ingest a duplicate, use `--force` and accept the
  duplicate-file noise; the seen-log is the audit trail.
- **Commit registry edits with the rationale.** A new entry's `notes`
  field, plus the commit message, should explain *why* this source is
  worth tracking — future-you will thank present-you.
- **Don't proliferate slugs.** One source = one slug. Two slugs for
  variants of the same site is a smell (different URL paths under the
  same domain are usually distinguishable by `content_selector`).

## Hand-off to the wiki

`/scan-sources` lands content in `wiki/raw/scraped/<slug>/...md`. It does
**not** auto-ingest into `wiki/`. Promotion to load-bearing knowledge
requires explicit `/wiki-ingest <wiki/raw/scraped/<slug>/<file>.md>`. This
is intentional: scraped content should not silently shape the wiki's
claims. The researcher curates.

## What this convention does NOT cover

- **General-purpose web scraping** — see the `web-scraping` skill.
  This convention is specifically about *tracked, periodic* scraping.
- **Polite-scraping defaults** (rate limits, robots.txt, User-Agent) —
  inherited from the `web-scraping` skill; not duplicated here.
- **Legal review of what to scrape** — researcher's call. The framework
  does not adjudicate copyright or ToS.
- **Pagination and crawl depth** — out of scope for v1. A registry
  entry fetches one URL per run. If the source is a multi-page index,
  add multiple entries (or use `crawl4ai` with a depth-limited config
  documented in `notes`).
