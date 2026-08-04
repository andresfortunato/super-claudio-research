---
name: wiki-lint
description: (r2p) Audit the project's research/wiki/ for structural integrity — orphan pages, contradictions, stale synthesis pages, and page-type budget violations. Use when the user says "lint the wiki", "/wiki-lint", "check the wiki for problems", "is the wiki healthy", or after a batch of ingests. Read-only; produces a structured report and never modifies research/wiki/ pages itself.
allowed-tools: Read, Bash, Glob, Grep
---

# wiki-lint

Static checks over `research/wiki/`. Reports problems; does not fix them — the researcher (or a follow-up `/wiki-ingest` call) decides whether to act.

## Preconditions

- `research/wiki/SCHEMA.md`, `research/wiki/index.md`, `research/wiki/log.md` exist. If missing, stop and tell the user the project hasn't been initialized properly.

## Checks performed

Run all four. Each emits zero or more findings.

### 1. Orphans

A page is an orphan if **no other page in `research/wiki/` links to it** AND it is not listed in `research/wiki/index.md`. Source pages are the one exception — they may be linked only from `research/wiki/index.md` and `research/wiki/log.md`, which is fine.

Detection:
- Enumerate all `research/wiki/**/*.md` files (excluding `SCHEMA.md`, `README.md`, `index.md`, `log.md`).
- For each page, grep the rest of `research/wiki/` (and `index.md`) for relative links to it.
- Zero hits → orphan.

### 2. Contradictions

A pair of pages is contradictory if both make claims about the same subject in opposing terms (e.g. one says "industrial policy in Vietnam succeeded post-1986", another says "Vietnam's industrial policy failed post-1986" — same subject, opposite verdict).

This check is best-effort and LLM-driven, not regex:
- Read every concept and synthesis page.
- Build an in-memory list of (subject, claim) pairs.
- Surface any pair where two claims share a subject and disagree on direction, magnitude, or causal sign.
- False positives are OK; flag, don't fix.

### 3. Stale synthesis

A synthesis page is stale if its `last_condensed` frontmatter date is **>90 days old as of today**. Synthesis pages aggregate across sources; if the underlying sources have churned, the synthesis must be revisited.

Detection:
- Glob `research/wiki/synthesis/**/*.md` (or wherever the schema places synthesis pages).
- Parse YAML frontmatter; read `last_condensed`.
- If absent on a synthesis page → that's a budget violation (see check 4), not a stale finding.
- If `today - last_condensed > 90 days` → stale.

### 4. Page-budget violations

Word count cap by page type, defined in `research/wiki/SCHEMA.md` and enforced here:

| Type      | Max words | Required frontmatter |
|-----------|-----------|----------------------|
| source    | 300       | `type: source`, `raw_path`, `ingested_at` |
| concept   | 800       | `type: concept` |
| entity    | 600       | `type: entity` |
| synthesis | (none)    | `type: synthesis`, `last_condensed` |

Detection:
- For every page, parse frontmatter `type`.
- Count words in the body (everything after the closing `---`). Use `wc -w` minus a small fudge for markdown punctuation.
- If `type == source` and words > 300 → violation.
- Same for concept (>800), entity (>600).
- If `type == synthesis` and `last_condensed` is missing → violation.
- If `type` is missing or unrecognized → violation (unschemaed page).

## Report format

Emit a single markdown report to stdout:

```markdown
# wiki-lint report — YYYY-MM-DD

## Summary
- Orphans: <n>
- Contradictions: <n>
- Stale synthesis: <n>
- Budget violations: <n>

## Orphans
- `research/wiki/concepts/foo.md` — no inbound links, not in index

## Contradictions
- `research/wiki/concepts/x.md` vs `research/wiki/concepts/y.md` — both discuss <subject>, claims disagree on <axis>

## Stale synthesis
- `research/wiki/synthesis/z.md` — last_condensed: 2025-12-01 (155 days ago)

## Budget violations
- `research/wiki/sources/long-source.md` — type=source, 412 words (cap 300)
- `research/wiki/synthesis/w.md` — missing required `last_condensed` frontmatter
```

If a section has zero findings, write `(none)` under it. Always emit all four sections so the report is parseable.

## Rules

- **Read-only.** Never edit a wiki page. Never append to `research/wiki/log.md`. The lint output goes to the chat; the user decides what to do.
- **Don't auto-fix.** Even obvious cases (e.g. a 305-word source page) require the researcher's call on what to cut.
- **Surface, don't suppress.** A noisy report is better than a silent miss.

## Invocation example

```
User: /wiki-lint
```

Skill walks `research/wiki/`, runs the four checks, prints the report, exits. Total cost ≤2k tokens for a wiki under ~50 pages.
