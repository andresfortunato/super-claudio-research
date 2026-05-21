---
name: scan-sources
description: (r2p) Read wiki/raw/registry.yaml and re-scrape any entry due for re-fetch (now > last_scraped + freq), delegating to the web-scraping skill, deduping by content hash against wiki/raw/seen.jsonl, and landing new content in wiki/raw/scraped/<slug>/. Use when the user says "scan sources", "/scan-sources", "/scan-sources --slug=<slug>", "/scan-sources --category=<cat>", "/scan-sources --force", or otherwise asks to refresh the project's tracked sources. Always explicit; never auto-fires on a clock.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill
---

# scan-sources

Targeted, polite, deduped scraping of the URLs listed in
`wiki/raw/registry.yaml`. Reads the registry, decides which entries are
due, hands fetching off to the `web-scraping` skill, dedupes by content
sha256, lands fresh content in `wiki/raw/scraped/<slug>/`, and updates
`last_scraped` in the registry. Audit trail is git history of the
registry + the per-fetch frontmatter on each `wiki/raw/scraped/*` file —
no separate run log.

## Preconditions

- `wiki/raw/registry.yaml` exists in the project root. If absent, stop
  and tell the user to seed it from `templates/wiki/raw/registry.yaml`.
- `wiki/raw/seen.jsonl` exists (seeded empty by `r2p init`). If absent,
  create it as an empty file before the first fetch.
- The `web-scraping` skill is installed and discoverable. Without it,
  this skill cannot fetch.

## Invocation modes

```
/scan-sources                          # all entries due for re-scrape
/scan-sources --slug=<slug>            # one specific entry, ignore freq
/scan-sources --category=<category>    # filter to one category, then apply freq
/scan-sources --force                  # all entries, ignore freq
/scan-sources --slug=<slug> --force    # one entry, ignore freq (same as just --slug; --force is implicit when --slug is given)
```

Combinations: `--category` and `--force` compose (`/scan-sources --category=investment --force` re-fetches every investment entry regardless of `last_scraped`).

## Workflow

For each invocation:

### 1. Load and validate the registry

- Read `wiki/raw/registry.yaml`. Parse with a YAML parser
  (`python3 -c "import yaml; ..."` is acceptable; the skill is
  Python-friendly, unlike hooks).
- Validate each entry has the six required fields: `slug`, `url`,
  `category`, `freq`, `scrape_method`, plus a `last_scraped` slot
  (may be `null`). If any entry is malformed, list the offenders and
  stop without fetching.

### 2. Decide which entries are due

Apply filters in order: `--slug`, then `--category`, then freq check.

- `--slug=<slug>` → exactly one entry; skip freq check; fail loudly if
  no entry matches.
- `--category=<cat>` → only entries whose `category` matches.
- Freq check (skipped under `--force` and under `--slug`):
  - `daily`   → due if `now - last_scraped >= 24h` or `last_scraped is null`
  - `weekly`  → due if `now - last_scraped >= 7d`  or `last_scraped is null`
  - `monthly` → due if `now - last_scraped >= 30d` or `last_scraped is null`
  - `adhoc`   → never due via freq; only fetched under `--slug` or
    `--force`. (Without those flags, an `adhoc` entry is silently
    skipped.)
- If the resulting due-list is empty, exit silently with a one-line
  report ("No sources due. Latest scrape: <slug> @ <time>").

### 3. Fetch each due entry

For each due entry, in order:

1. Invoke the `web-scraping` skill with `url`, `scrape_method`, and
   `content_selector` (if any). The skill returns extracted markdown
   plus a best-effort title.
2. Polite-scraping defaults — User-Agent, rate limits, robots.txt
   compliance — are inherited from the `web-scraping` skill. Do not
   override them here.
3. If the fetch fails (timeout, 4xx/5xx, robots-blocked):
   - Log the failure to stderr (visible to the user).
   - **Still update `last_scraped`** (so we don't hammer a broken URL
     every invocation; the freq window applies even to failures).
   - Surface the error in the per-run report (step 7) so the user sees it.
   - Continue to the next entry; do not abort the run.

### 4. Compute content hash and dedup

- Compute `sha256` over the **extracted markdown body** (not the
  frontmatter, not the raw HTML).
- Read `wiki/raw/seen.jsonl`. If a row already exists with the same
  `slug` and `content_sha256`, the content is a duplicate:
  - Skip writing a new file under `wiki/raw/scraped/<slug>/`.
  - Still update `last_scraped` in the registry (we did fetch).
  - Note the duplicate in the per-run report (step 7).
  - Do not append to `seen.jsonl` (the existing row already represents this content).

### 5. Write fresh content

If the content is new (no matching `content_sha256` in `seen.jsonl`):

1. Compose frontmatter:
   ```yaml
   ---
   url: <entry url>
   source_slug: <entry slug>
   category: <entry category>
   scraped_at: <ISO8601 UTC, current>
   content_sha256: <hash>
   title: <extracted from page; fallback to URL path>
   ---
   ```
2. Slugify the title for the filename: lowercase, kebab-case, strip
   punctuation, truncate to ~60 chars. Format:
   `wiki/raw/scraped/<slug>/YYYY-MM-DD_<title-slug>.md`.
   If a file with the exact same path already exists (date + title-slug
   collision), append `-2`, `-3`, … to disambiguate. (Rare; usually
   means two different articles published the same day with identical
   titles.)
3. Write the file: frontmatter + body.
4. Append one row to `wiki/raw/seen.jsonl`:
   ```json
   {"slug": "<slug>", "url": "<url>", "content_sha256": "<hash>", "scraped_at": "<ts>", "raw_path": "wiki/raw/scraped/<slug>/<filename>.md"}
   ```

### 6. Update registry `last_scraped`

After each entry (whether fresh, duplicate, or failed), update the
entry's `last_scraped` field in `wiki/raw/registry.yaml` to the current
ISO8601 UTC. Preserve all other fields and YAML structure exactly.
Use a YAML round-trip library (Python `ruamel.yaml`) when available,
or careful in-place edit otherwise — preserving comments and ordering
matters because the registry is human-curated.

### 7. Report

Print a structured summary to the user:

```
/scan-sources report — 2026-05-05T14:32:11Z

Filtered to: <category=investment | slug=<slug> | all>
Due: 4 entries
  - investment-news-cambodia    [daily]    fresh
  - cambodia-mef-policy         [weekly]   duplicate (sha256 already seen)
  - portinfra-tracker           [weekly]   fresh
  - exchange-disclosures-kh     [monthly]  fetch failed: 503

Files written: 2
  + wiki/raw/scraped/investment-news-cambodia/2026-05-05_new-port-deal.md
  + wiki/raw/scraped/portinfra-tracker/2026-05-05_sihanoukville-throughput-q1.md

Registry updated: last_scraped fields for 4 entries
```

If the run was silent (no entries due), print one line:

```
No sources due. Most recent: <slug> @ <ts>.
```

## Rules

- **Don't auto-ingest into `wiki/`.** Scraped content lands in
  `wiki/raw/scraped/`. Promotion to `wiki/` requires the user to invoke
  `/wiki-ingest` explicitly. The skill must not call `/wiki-ingest` itself.
- **Idempotent.** Two consecutive `/scan-sources` runs an hour apart
  produce zero new files (the freq window for daily is 24h; weekly is
  7d). Only `--force` or `--slug` bypasses the window.
- **Polite.** Honor robots.txt, rate limits, and User-Agent identity
  via `web-scraping`. If a source's robots.txt forbids the URL, log it
  and skip — never override.
- **Append-only seen.jsonl.** Never edit or delete rows. Even on
  `--force` re-fetches that produce duplicates, do not rewrite the
  ledger.
- **Atomic registry update.** When updating `last_scraped`, write to a
  temp file then `mv` over the original to avoid corruption on partial
  writes.

## Cost

`/scan-sources` is a deliberate user-invoked operation. No hard token
cap, but reasonable: a typical "all due" run with 5–10 entries should
land under a few k tokens of skill output, plus whatever the
`web-scraping` skill's per-fetch cost is. If a single entry's fetch
balloons (LLM-extraction on a long page), document it in the entry's
`notes` and consider switching to a cheaper `scrape_method`.

## Invocation example

```
User: /scan-sources --category=investment
```

Skill will:

1. Load `wiki/raw/registry.yaml`; filter to `category: investment`.
2. Apply freq check; identify 3 of 5 investment entries are due (the
   other 2 were scraped <24h ago).
3. Delegate fetching to `web-scraping` skill, three times.
4. For each: compute content sha256, check `wiki/raw/seen.jsonl`, write
   fresh file or skip as duplicate.
5. Update `last_scraped` for all 3 entries.
6. Report: 2 fresh + 1 duplicate + 0 failures.

## What this skill does NOT do

- **Does not crawl.** One URL per registry entry per run. Multi-page
  sites need multiple entries.
- **Does not maintain the registry's other fields.** Only
  `last_scraped` is auto-updated. `slug`, `url`, `category`, `freq`,
  `scrape_method`, `content_selector`, `notes` are researcher-managed.
- **Does not ingest into `wiki/`.** That's `/wiki-ingest`, explicit.
- **Does not run on a schedule.** No cron, no daemon. The researcher
  invokes; the skill runs once and exits.
- **Does not fetch sources outside the registry.** A URL the
  researcher mentions in passing does not get added to the registry by
  this skill. Edits to `wiki/raw/registry.yaml` are manual.
