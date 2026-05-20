# Handoff — /r2p-migrate-source skill

## Status

| Phase | Status | Notes |
|---|---|---|
| 1. Implement the skill | ✅ done | `.claude/skills/migrate-source/SKILL.md`, 603 lines (489 → 603 after fix-plan Phase 1 edits). Frontmatter valid. |
| 2. Dry-run validation | ✅ done (2026-05-20) | IMF: full pass (original + re-regression). Conflict test: pass (original + re-run). Atlas: full pass (re-validation against fix-plan-edited SKILL). |
| 3. Docs + framework wiring | ✅ done | `docs/migrate-source-mechanism.md`, README, conventions cross-references. |

**Commits**: bundled with fix plan's Phase 4 — see `plan/plan-migrate-source-skill-fixes/handoff.md`. Both plans commit together because parent's Phase 1 + 3 edits were never committed and the fix plan's Phase 1 edits build on them.

## Within-session

What this session did:
1. Pre-setup. `mkdir /tmp/migrate-source-test-target`, `git init`, `r2p init` (installed `data-access.md` convention at target).
2. Discovered cambodia-growth blocker: donor lacked `data-access.md` and `.env.example`. **Ran `r2p init --upgrade` on cambodia-growth** to fix; this also installed framework sidecars (`.framework-new` files) in cambodia-growth — those are unreviewed and the user should diff/decide.
3. Validated **IMF** end-to-end (manual execution of the SKILL's four phases):
   - Phase A discovery found 4 ref docs + 1 OpenAPI YAML, the `imf_sdmx_fetch` wrapper, no env vars, 5 INDEX rows.
   - Phase B dep analysis: `IMF_SDMX_BASE` in-block, `pd`/`requests` generic. No project-specific deps. Bootstrap target utility module needed (`migrate_source_test_target_utils.py` from dirname snake-cased).
   - Phase C proposal written to `/tmp/migrate-source-test-target/MIGRATION_PROPOSAL.md` covering everything.
   - Phase D apply: bootstrapped utility module, copied 4 docs + 1 yaml, updated INDEX (IMF subsection + Helper-functions row), wrote MIGRATION_TODO.
   - **Smoke test PASS** (with caveat — see finding (a) below).
4. Constructed the **conflict-marker** scenario by hand: seeded a divergent target file, built the merge-marker output per the SKILL spec, confirmed 3 markers present. Mechanic works as documented.
5. Started **Atlas** discovery only — surfaced 3 hard SKILL gaps that prevent migration. User chose to stop and document rather than fix-and-retest this session.
6. Tore down `/tmp/migrate-source-test-target/`.

## Researcher ↔ researcher (next session)

**Pre-condition for resuming**: the SKILL-fix plan (planned from `brainstorms/migrate-source-skill-gaps.md`) has shipped its edits to `.claude/skills/migrate-source/SKILL.md`. Until then, this plan stays paused. The 5 findings (3 SKILL gaps + 2 smaller) and the recommended SKILL edits per finding are captured in that brainstorm + fix plan — don't re-derive them here.

**Scope of this session = re-validation only.** No SKILL edits in this session. If validation surfaces a new gap not anticipated by the fix plan, document and stop — don't patch in-session.

### State you can rely on at resumption

- `~/cambodia-growth` has been `r2p init --upgrade`'d already (2026-05-19). It now has `.claude/conventions/data-access.md` and the standard `.env.example` template (commented examples). The upgrade also left `.framework-new` sidecars in cambodia-growth — those are unrelated to this plan; user may have addressed them separately by then.
- `/tmp/migrate-source-test-target/` was torn down.
- Phase 1 + 3 changes in the framework repo are still staged (uncommitted) from the original implementation session. Whether the fix plan commits or rebases them is its call; just be aware they're there.

### Re-validation steps

1. **Pre-setup target**: `mkdir -p /tmp/migrate-source-test-target && cd /tmp/migrate-source-test-target && git init && r2p init`.
2. **Run Atlas**: `/r2p-migrate-source --from ~/cambodia-growth --source atlas --to /tmp/migrate-source-test-target`.
3. **Review proposal against pass-criteria below**, apply if it matches, smoke-test, inspect MIGRATION_TODO.
4. **Re-run IMF** (regression check that the fix plan didn't break the working path): same command with `--source imf` (use a fresh target dir or accept conflict markers on the IMF docs).
5. **Conflict test**: pre-seed one ref doc with divergent content, re-run migration, confirm merge markers.
6. **Tear down**: `rm -rf /tmp/migrate-source-test-target`.
7. **Mark complete**: `touch plan/plan-migrate-source-skill/.completed` once both Atlas and IMF re-pass and conflict test passes.

### Atlas pass-criteria

- Proposal lists: a warning that no `data_sources/atlas*.md` ref doc exists in donor (fix-plan-defined behavior — likely warn-and-proceed); `atlas_query` + `get_atlas_conn` + 4 higher-level helpers (`get_country_year_data`, `get_product_data`, `get_pci_data`, `get_export_by_section`) as one bundle; 5 `ATLAS_DB_*` env vars (preserved with `# ` prefix, picked up from commented form); dependency analysis flagging `COUNTRY_IDS` / `ID_TO_ISO` as project-specific (and `psycopg2` as a module-level import the target's preamble needs).
- Post-apply: `<target_venv>/bin/python -c "from migrate_source_test_target_utils import atlas_query"` succeeds.
- MIGRATION_TODO lists: write `data_sources/atlas_postgres.md`, fill `ATLAS_DB_*` in `.env`, replace `TODO_TARGET_COUNTRY_IDS` / `TODO_TARGET_ID_TO_ISO` in utility module, real-fetch smoke test.

### IMF regression pass-criteria (unchanged from prior session)

Proposal lists `imf_sdmx_api.md` + `imf_sdmx_openapi_3_0.yaml` + `imf_dataflow_inventory.md` + `imf_weo_api.md` + `imf_sdmx_fetch`. No env vars. Post-apply: `python -c "from migrate_source_test_target_utils import imf_sdmx_fetch"` succeeds. MIGRATION_TODO lists headline-anchor re-verification.

## Year-later

- The SKILL was written assuming donors fully follow the data-access + data-sources conventions. Reality: cambodia-growth was the first non-trivial donor and is partly pre-convention. Phase 2 surfaced 3 places the SKILL was strict where it should be lenient (or use a fallback anchor). Future donors will likely be cleaner; the lenient discovery still works on clean donors.
- The decision to lift cambodia-growth's strangely-named helpers (`get_country_year_data` etc.) via section-banner discovery is a compromise — those names don't make Atlas obvious from the function name, but renaming them in cambodia-growth would cascade through notebooks. The MIGRATION_TODO can suggest a rename to target, but the lift itself shouldn't force it.
- The smoke test's "default python" assumption was a planning gap; project venvs are the norm for r2p projects.

## What didn't work / surprises

- **`r2p init --upgrade` installed a generic `.env.example` template** at cambodia-growth, not one populated from cambodia-growth's actual `.env`. The lines are commented-out placeholders. This is expected behavior (`.env.example` is a *contract* template, not a dump of secrets) — but it means the SKILL needs to read commented declarations, not just uncommented ones. Hence Finding 3.
- **Many `.framework-new` sidecars landed in cambodia-growth** during the upgrade. They're unreviewed; the user should diff and accept/reject before next session. Not blocking for SKILL work.
- **The plan assumed Atlas would have a ref doc.** It doesn't, and the SKILL refused. Plan vs reality mismatch — fix is in the SKILL (lenient discovery), not the plan.
