# Phase 3 — Lint the chain, and make `.next-id` real

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phase 2 · **Blocks:** Phases 4, 5
**Session scope:** likely two · **Estimated context:** ~55% for 3.1–3.5, ~25% for 3.6
**Context file:** read `context/installer-map.md` before touching anything under `src/`.

## Intent

Five invariants in `lint-research.sh`, in the style of the existing seven — each
named to the defect it would have caught, because that is what makes a check
survive a future refactor that no longer remembers why it exists.

Then `r2p evidence new <slug>`. v2 shipped `research/evidence/.next-id` and
`evidence.md:18` names it as the source of ids — but **nothing in the framework
reads or writes it.** A counter no tool touches is a convention, and this
particular convention already failed twice: the evidence-id collision was filed
as a project learning in two separate months, and three duplicate ids (#119,
#131, #139) accumulated from same-day parallel fan-outs under `ls`-based
allocation. Advice does not survive a fan-out; an atomic allocator does.

## The invariant refinement — read this before writing 3.3

`plan.md` describes invariant 10 as *"an evidence doc whose declared inputs carry
a newer commit than the doc."* **Evidence frontmatter has no `inputs` field, and
adding one is the wrong fix** — it would duplicate the script header's `Inputs:`
line, and two sources of truth for the same fact is the drift this framework
exists to prevent.

Use the binding Phase 2 just added instead: **an evidence doc is stale when the
newest commit touching any path in its own `artifacts:` is newer than the doc's
`date:`.** Cheap (one `git log` per artifact), no new field, and it catches the
documented case exactly — the chart-port field note is a chart re-rendered after
a data re-read while the evidence doc kept asserting the old numbers. The
deeper input-level walk (artifact → `Run:` → script → header `Inputs:`) needs
provenance traversal and belongs to `/pipeline-check` in Phase 5.

## Tasks

**3.1 — Invariant 8: `Rests on:` resolves.** Every id in every claim's `Rests on:`
names a file in `research/evidence/`. FAIL. Catches: a claim resting on evidence
that was never written.

**3.2 — Invariant 9: artifact ↔ evidence binding.** Every chart or table path
referenced from `deliverables/` resolves to an evidence doc that lists it in
`artifacts:`. FAIL. **This is the three-missing-docs check** — §4's 408-cell
immunity screen, the three-lens growth-gap exhibit that carried §1 from a plan
handoff and a render script, and the consolidated agro verdict. Six months
invisible behind a 330 KB index; this makes it a `test -f`.

**3.3 — Invariant 10: evidence staleness.** Per the refinement above. **WARN, not
FAIL** — a re-rendered chart is often a cosmetic change, and a FAIL here would
train researchers to ignore the linter, which is the failure mode `check-evidence.sh`
died of.

**3.4 — Invariants 11 and 12.** `.next-id` exceeds the highest id on disk (FAIL —
if it doesn't, the next allocation collides). No `artifacts:` path that does not
exist (FAIL — a typo'd binding silently satisfies invariant 9 for nothing).

**3.5 — Report shape.** Keep the existing `note`/`fail` idiom and the FAIL/WARN
split. **No silent caps** — if output is bounded, print the dropped count.
`05_methods_merge.py:304` truncates to 12 with no notice and Phase 6b is fixing
it; do not import the habit here.

**3.6 — `r2p evidence new <slug>`** ✚ `src/commands/evidence.js`, ✎ `src/cli.js`
Read `.next-id`, write `id+1` back, create the doc from the template with
frontmatter pre-filled, print the path. **Atomic** — the whole point is two agents
in a same-day fan-out. `unit` and `period` are left blank for hand-authoring, per
Phase 2's no-inference rule; never guess them from a slug.
*Clean session boundary here.* If context is past 60% after 3.5, commit, hand off,
and start 3.6 fresh.

## Verification

**Every invariant must be seen to fail before it lands.** Build the broken
fixture, watch it go red, fix the fixture, watch it go green. An invariant that
has only ever been green is untested — and the framework has already shipped one
check whose satisfaction condition could never be met (`check-evidence.sh`
globbing a path that v2 had moved, so it nudged unconditionally).

- Pure bash + git, no new runtime dependency (principle 6).
- Full run against a fresh `r2p init` scaffold: green and silent.
- `r2p evidence new` called twice in a row yields consecutive, distinct ids, and
  `.next-id` is correct afterwards. Simulate the real failure: two calls
  interleaved, both ids unique.
- Per `context/installer-map.md`, both installers walk `.claude/hooks/` and
  `.claude/conventions/` wholesale, so **no `upgrade.js` edit should be needed**.
  Confirm, and if so delete that line from `plan.md`'s manifest rather than
  making a no-op edit.

## Do not touch

`templates/migration/*`, `.claude/skills/migrate-source/`, `test/` (Phase 6).
Do not write the skills — Phases 4 and 5 own those and both are decision-gated.

## Commit discipline

By pathspec, one command. One commit per invariant is fine and preferable — each
carries its own fixture story in the message.
