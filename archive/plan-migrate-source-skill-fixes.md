# /r2p-migrate-source — Phase-2 follow-up fixes

Archived: 2026-08-04 — **superseded, not completed.**

A child plan of `plan-migrate-source-skill`. It exists only to unblock that
plan's Phase 2, shipped its own work, and died with the parent when v2 removed
the conventions both were written against. Read
[the parent entry](plan-migrate-source-skill.md) first — the context, the
decisions and the learnings live there and are not repeated here.

## Status at archival

| Phase | Outcome |
|---|---|
| 1. SKILL edits | ✅ shipped — four findings + both inline templates |
| 2. Atlas re-validation | ⚠️ behavior validated; smoke test never passed |
| 3. IMF re-regression | ⚠️ behavior validated; smoke test never passed |
| 4. Commit | ✅ shipped |

## What was built

Four edits to `.claude/skills/migrate-source/SKILL.md`, landed in one pass because
they sat in non-overlapping regions. All four remain in the skill today; they need
repathing to v2, not reverting.

1. **Missing ref doc → warn and bootstrap a stub.** The wrapper became the only
   hard requirement for discovery; a missing ref doc, env vars, INDEX row,
   data-README entry or CLAUDE.md mention now warn and proceed. Apply bootstraps a
   5-line stub at `<target>/data_sources/<slug>.md` and MIGRATION_TODO gains a
   step 0 to write it properly.

2. **Banner-substring anchor.** A third discovery anchor alongside name-prefix and
   docstring back-link: defs between a `# ── ` banner whose text contains the slug
   and the next banner. This is what catches donor helpers named without a source
   prefix. Cross-source banners (`# ── Atlas + IMF utilities ──`) raise an explicit
   ambiguity warning for the user to resolve rather than guessing — the brainstorm
   suggested it, the plan codified it, and a cleaner heuristic can replace it later
   if one appears.

3. **Commented env vars.** Grep widened from `^<SLUG>` to `^#?\s*<SLUG>`, with the
   leading `# ` preserved verbatim on apply and `(commented in donor)` flagged in
   the proposal. Needed because `.env.example` is a *contract template*, not a dump
   of a donor's real values, so every declaration in it is commented out.

4. **Smoke-test interpreter.** Picks `<target>/.venv/bin/python` →
   `<target>/venv/bin/python` → `python3`, reports which it used, and classifies
   `ModuleNotFoundError` on a framework-deps allowlist as an env-setup gap rather
   than a migration failure.

## Why it was not completed

Edit 4 is the one that mattered and the one that fell short. It made the smoke
test *diagnose* its own failure correctly, which is not the same as making it
pass — and Phase 2's inherited pass-criterion was that it passes. Both Atlas and
IMF re-validated cleanly on every other axis and both still ended on
`ModuleNotFoundError`. See the parent entry for the full account.

## Learnings

**A fix plan inherits its parent's pass-criteria, and should restate them.** This
plan's own phases read "Atlas re-validation" and "IMF re-regression" without
repeating what counted as a pass. The bar lived in the parent's `plan.md`. When
both plans were being worked in one session, the weaker reading — behavior matches
expectations — quietly replaced the stronger one, and produced a premature archive
commit.

**Batching edits in non-overlapping regions worked exactly as planned.** The plan
predicted the four edits would not interact and they did not; one editing pass,
no mid-edit design shifts. Worth repeating when a fix list is genuinely
independent — the usual argument for one-change-at-a-time is about interaction
risk, and where that risk is absent the batching is free.

## Metrics

- Phases: 2 of 4 shipped (1 and 4); Phases 2 and 3 never closed
- Sessions: 2
- Commits: `fee5051` (bundled with the parent), `00d4d53`
- SKILL length: 489 → 603 lines
- Follow-up: `TODO.md` → v2.1, tracked jointly with the parent
