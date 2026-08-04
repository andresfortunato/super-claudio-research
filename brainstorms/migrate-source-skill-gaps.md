# /r2p-migrate-source — gaps surfaced in Phase 2 validation

Input for a `/planning` session on follow-up fixes. The gaps below came
out of dry-running the skill against `~/cambodia-growth` on 2026-05-19.
Full validation transcript and rationale: `archive/plan-migrate-source-skill.md`
(the plan was archived as superseded on 2026-08-04; v2 removed the `data-access`
convention and `data_sources/` layout these findings were written against).

IMF migration validated end-to-end. Conflict-marker mechanic verified.
Atlas migration blocked. The 5 findings below sit at different points
on the repo-fix-vs-skill-fix axis.

## Findings

| # | Finding | Repo fix (cambodia-growth) | SKILL fix |
|---|---|---|---|
| 1 | Atlas has no `data_sources/atlas*.md` ref doc; SKILL refuses on missing ref doc | Add `atlas_postgres.md` eventually (good hygiene) | Warn-and-proceed instead of refuse — write a TODO at target for the missing ref doc |
| 2 | Atlas helpers `get_country_year_data` / `get_product_data` / etc. don't match `<slug>_*` filename pattern; SKILL discovers 1 of 6 | Renaming cascades through every notebook — too expensive | Add section-banner block (`# ── Atlas ──`) as a third discovery anchor |
| 3 | `.env.example` ships with commented-out vars (`# ATLAS_DB_HOST=`); SKILL grep `^ATLAS_DB_` misses them | Uncomment the Atlas block (optional, "declare what we use") | Match commented form (`^#?\s*<SLUG>`), preserve `# ` prefix on write |
| a | Smoke test runs `python -c "..."`; default `python3` lacks project deps | n/a | Use `<target>/.venv/bin/python` if present, fall back; treat `ModuleNotFoundError` on framework deps as env-setup gap, not migration failure |
| b | IMF docs predate the data-sources convention (no `Status:` / `## Headline anchor` lines); SKILL's strip-and-prompt is a no-op | Add sections at next re-verification | None — SKILL already handles correctly (lifts verbatim) |

## The pattern

Where the **framework's own templates** establish the "non-compliant"
state (commented env vars in the shipped `.env.example`), the SKILL
needs to accommodate it. Where **cambodia-growth has genuine
pre-convention debt** (no Atlas ref doc, helper names that don't
signal Atlas), there's a real call on which side absorbs the fix.

For most cases the answer leans SKILL-side because:
- Future donors will also be partly pre-convention. Brittleness in
  discovery defeats the skill's purpose.
- Repo refactors (renaming Atlas helpers) cascade through notebooks
  and prior analysis. Migration cost shouldn't fall on the donor.
- The framework template's own commented `.env.example` form means
  the SKILL must handle commented vars regardless of donor.

## Open design questions for the planning session

1. **Strictness on missing ref doc** (Finding 1): refuse, warn-and-proceed,
   or configurable? If warn-and-proceed, what does the bootstrapped target
   look like — empty file with a TODO header, or no file at all?
2. **Banner-discovery rules** (Finding 2): "all defs between two `# ── X ──`
   banners" — how to disambiguate when banners aren't slug-prefixed
   (e.g. `# ── Common Atlas queries ──`)? Keyword match inside the banner?
3. **Smoke-test python search order** (Finding a): is `.venv` enough or
   should we also probe `venv/`, conda envs, `pyproject.toml`'s
   `[tool.poetry]` python? Probably keep it minimal — `.venv/bin/python`
   then `venv/bin/python` then `python3`, document the fallback.

## Out of scope for the fix plan

- The donor (cambodia-growth) repo cleanup is optional and lives in
  that project, not this plan. Mention in the plan but don't sequence
  the fix here.
- The framework's `.env.example` template format is not changing.
  Commented examples are the design; SKILL adapts.

## Cross-references

- `archive/plan-migrate-source-skill.md` — the findings and the decisions behind them, preserved at archival
- `.claude/skills/migrate-source/SKILL.md` — current skill, 489 lines
- `brainstorms/migrate-source-skill.md` — original brainstorm (pre-implementation)
- `docs/migrate-source-mechanism.md` — design rationale doc
