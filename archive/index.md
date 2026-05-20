# Archive — completed plans

One line per completed plan, newest at the top. The archivist agent
appends entries automatically when a `plan/plan-<slug>/.completed`
marker fires the Stop hook.

Entry format:

```
- **<Plan Title>** (YYYY-MM-DD) — one-sentence summary. [Full archive](plan-<slug>.md)
```

## Entries

- **r2p-migrate-source Skill — Discovery & Smoke-test Gap Fixes** (2026-05-20) — fixed 4 dry-run gaps in `/r2p-migrate-source`: missing ref doc now warns + bootstraps a stub; banner-substring discovery catches non-slug-prefixed helpers; commented env-var declarations matched and preserved; smoke-test uses project venv with framework-dep error allowlist. [Full archive](plan-migrate-source-skill-fixes.md)
- **r2p-migrate-source Skill** (2026-05-20) — shipped the `/r2p-migrate-source` proposal-then-apply skill for transplanting one source's full data layer from a donor r2p project to a target; validated against Atlas (6 helpers, no ref doc → stub bootstrapped) and IMF SDMX (3 ref docs + OpenAPI YAML); fix-plan sibling `plan-migrate-source-skill-fixes` landed 4 discovery/smoke-test gap fixes before final validation. [Full archive](plan-migrate-source-skill.md)
- **Framework v1.2 — Skill Independence** (2026-05-08) — vendored `planning`, `implementation`, and `agent-teams` from scc; added `r2p plan init <slug>` CLI subcommand; r2p is now fully standalone. [Full archive](plan-skill-independence.md)
- **Framework v1.1 — Córdoba Lessons** (2026-05-08) — shipped six convention hardening fixes, opt-in theme-parallel layout, brainstorming/learning-capture/archival skills and hooks (ported from scc), and a researcher-audience README rewrite. [Full archive](plan-cordoba-lessons.md)
- **Install Redesign** (2026-05-07) — replaced `install.sh` with Node-based `r2p` CLI; symlink-skills + copy-conventions split; `--upgrade` with `.framework-new` sidecars. [Full archive](plan-install-redesign.md)
- **Project Conventions** (2026-05-07) — added `project_conventions/` folder convention for project-bespoke style/process rules; no required internal sections, no freshness anchors. [Full archive](plan-project-conventions.md)
- **Refdocs Conventions** (2026-05-06) — added `data_sources/` (API reference docs with freshness anchors) and `methods/` (project-internal methodology specs with diagnostic counts) folder conventions. [Full archive](plan-refdocs-conventions.md)
- **research-to-policy v1 framework** (2026-05-05) — shipped the v1 framework: 7 conventions, 6 skills, 1 Stop hook, 0 hard external dependencies. Two post-ship simplifications removed `manifest.jsonl` and pre/post-compact hooks. [Full archive](plan-v1-framework.md)
