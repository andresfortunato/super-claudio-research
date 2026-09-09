# Phase 3 — Lint the chain, and make `.next-id` real

**✅ DONE 2026-09-09.** All tasks — 3.0, 3.1, 3.2, 3.3, 3.4, 3.4b, 3.4c, 3.5, 3.6
— plus the recursive fix to invariant 1. Every invariant was seen red against a
built fixture before it landed. Commits `def96b6` (3.0 WARN tier) · `6535549`
(invariant 1 recursive) · `665d6b6` (8) · `68ce58f` (9 / 9b) · `2f1344a` (10) ·
`566e57b` (11, 12) · `1419586` (13, 14) · `50c246c` (3.5) · `aa6b61a` (3.6) ·
`bf25bbe` (gitignore the allocator lock). Three out-of-phase fixes the phase's
own verification forced: `a93d49d`, `91ac89d`, `d0829ba` — see *Execution notes*.

**Two specced decisions were changed on measurement, both toward WARN, and both
recorded in `log.md` D6:** invariant 9 is split into a FAIL and a WARN half, and
invariant 10's comparison is a conjunction. Neither is a scope change; both apply
the phase's own "do not ship a check that fires on a correct project" rule — the
one it already applied to invariant 13 — to a case measurement revealed.

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** Phase 2, **Phase 2b** · **Blocks:** Phases 4, 5
**Session scope:** likely two · **Estimated context:** ~55% for 3.0–3.5, ~25% for 3.6
**Context file:** read `context/installer-map.md` before touching anything under `src/`.
**⚠ ADDED 2026-08-17** (`log.md` **D4**): task **3.0** — the WARN tier — is new and
comes first; **3.4c** — invariant 14 — is new. 2b now blocks this phase because
3.4c resolves against a banner format 2b specifies.

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

## ⚠ ADDED 2026-08-05 — measured against the pilot repo, read before 3.1

A review of `~/research/cordoba` (v2 layout, 173 evidence docs, 42 claims)
found three things that change how these invariants must be written. All are
measurements, not guesses.

**1. Claims sit at `###`, not `##`.** The ledger groups its 42 claims under six
`## §N` narrative sections, so every claim heading is `### C<n>`. A checker
anchored to `^## C[0-9]+` finds **zero claims in a full 42-claim ledger** — a
false all-clear, the worst failure mode a linter has. **Match `^#{2,3} C[0-9]+`.**
`claims.md` and `citation-discipline.md` were corrected on 2026-08-05; the earlier
convention specified `## C<n>` *and* `##` narrative sections, which cannot both
hold.

**2. Invariant 8 has almost nothing to bite on yet, and invariant 13 has 573
targets.** The pilot's deliverables carry **573 bare `#nn` references and zero
claim references** across three drafts of one memo (334 / 148 / 91). So:

- Invariant 13, if written as FAIL, makes the linter unusable on any real project
  mid-adoption. **Write it WARN**, with the count printed — same reasoning that
  made invariant 10 a WARN, and `check-evidence.sh` died of exactly this.
- **No silent caps.** If output is bounded, print the dropped count.

**3. Invariant 11 already passes on the pilot** (highest id 173, `.next-id` 174),
so it will not self-demonstrate there. Its value is prospective; do not treat a
green result as evidence the check is wrong.

**Still true and worth doing:** `plan.md`'s note that running the lint against the
pilot validates invariant 9 stands — the three claims with no evidence doc are
`docs/v2-case-study-cordoba.md` §7's highest-value follow-up, and invariant 9 is
the check that finds them.

**4. Invariant 1 is already broken, and fixing it belongs here.** The existing
uniqueness check globs `"$EV"/[0-9]*_*.md` (`lint-research.sh:49`, and the same
shape at `:80`) — **non-recursive**. The pilot has a tracked
`research/evidence/access_to_finance/` holding three evidence docs whose ids
**20, 21, 22 collide with three root-level docs**; none of the three appears in
`INDEX.md`; and the linter reports none of it. A check that silently skips a whole
directory is worse than no check, because it returns a confident PASS. Make the
glob recursive, and see **decision E** on whether such subfolders are permitted at
all. This is the evidence-id collision recurring a *fourth* time, through a vector
`.next-id` cannot defend: not parallel allocation, but a second numbering
namespace.

**5. Baseline, measured 2026-08-05** — per case-study §5.2, *measure before
claiming you broke nothing*. `lint-research.sh` on the pilot today:

```
FAIL headline cap (>120 chars): rows 157, 158, 162 ×2, 165, 168
FAIL duplicate evidence ids: 162
FAIL 15 evidence docs missing frontmatter or a required key
ok   filename id matches frontmatter · no verdicts in ## Measured
```

Plus the three invisible collisions above, which do **not** appear. Any v3 lint
run against the pilot must be diffed against this, not read cold — most of these
predate v3.

> **⚠ CORRECTED 2026-09-09 — the baseline above is five weeks stale and every
> number in it has moved.** The pilot grew from 173 evidence docs to **285** and
> from 42 claims to **48**. Re-measured on the v2 script before any v3 change:
>
> ```
> FAIL headline cap (>120 chars): 64 rows           (was 6)
> ok   evidence ids unique                          (the 162 duplicate is resolved)
> FAIL 106 evidence docs missing a frontmatter key  (was 15)
> FAIL 11 docs whose filename id != frontmatter id  (frontmatter=none on all 11)
> FAIL verdict words in ## Measured: 3 docs
> WARN claims.md reviewed 2026-08-11, newest evidence 2026-09-03
> WARN 47 method/source docs with no triggers:
> ```
>
> **The three invisible collisions are gone, and not because we fixed them.**
> `research/evidence/access_to_finance/` no longer holds evidence docs — its
> README records that the `access-to-finance` branch merged on 2026-08-21 and ids
> 20/21/22 were promoted to 208/209/210. The subfolder is now a frozen provenance
> snapshot of charts and a memo. **Decision E's live instance has resolved
> itself.** The recursive fix ships regardless: the *vector* is what a check
> defends against, and T2 now names that vector in a shipped convention.
>
> A session diffing a v3 run against the pilot must use **this** block, not the
> one above it. The stale version stays visible rather than deleted, per D1's
> habit — a corrected number teaches more than a vanished one.

## Tasks

**3.0 — ✚ ADDED 2026-08-17 — the WARN tier, which does not exist.** `lint-research.sh`
is ok-or-FAIL throughout: `note "FAIL …"; fail=1` at every check, `exit $fail` at
`:106`. There is no `warn` function, no warn counter, and PASS/FAIL is the only
verdict. **3.3 and 3.5 below are both written as if the tier already existed, and
so is invariant 13** (WARN, decided in `log.md` **D2**). Build it first: a `warn`
helper, a separate counter, a summary line that reports both, and **exit 0 when
only warnings fired**. Everything else in this phase depends on it.

The pilot built this tier independently and wrote down why
(`gate_retracciones.py:132-146`): its language check misreports — `base
exportadora`, `gradiente plano` and `industrias urbanas` carry no accent and no
function word, so a stopword test called all three wrong — so it **prints the
rows and asks for an eye** rather than *"ship a test that misreports"*. Measured
12 of 40 rows. That sentence is the tier's design rationale; put it in the
script, not only here.

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

**3.4c — ✚ ADDED 2026-08-17 — invariant 14: every `#nn` in a deliverable resolves
to a live evidence id.** **WARN** (needs 3.0). Independent of 3.4b — it does not
assume invariant 13 ships, and if 13 is dropped this is the only thing checking
`deliverables/` at all.

Why it is needed on top of 13: 13 checks `[C<n>]` **claim** references, and
`citation-discipline.md`'s convert-on-touch rule means the old `#nn` form stays
legal indefinitely. The pilot measured **573 bare `#nn` and zero claim
references** across three drafts of one memo, so at adoption time this is the
invariant that actually fires.

**The failure it catches is real and already happened.** The pilot resolved three
id collisions by renumbering (`131→150`, `119→149`, `139→151`), did it carefully —
banner, `(was #131)` in the headline — and **never updated the citations**.
Nothing could see it. Three memo fragments still write `#119`(sec); a gate's
lookup table still names three files that no longer exist. Resolve against the
renumber banner Phase 2b **T2** specifies, so `(was #131)` counts as a live
target rather than a dangling one.

**3.5 — Report shape.** Keep the existing `note`/`fail` idiom and the FAIL/WARN
split built in **3.0**. **No silent caps** — if output is bounded, print the dropped count.
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

---

## Execution notes — 2026-09-09

### The three out-of-phase fixes, and why each was unavoidable

Each was forced by a verification criterion in this file, not chosen.

**`a93d49d` — `templates/research/sources/EXAMPLE_world_bank_api.md` had no
frontmatter.** *Verification:* "full run against a fresh `r2p init` scaffold:
green and silent." It was green, not silent: one WARN on invariant 7, against a
file `init` had just written. Both methods examples carry `triggers:`; the
sources example was the outlier. It is also the doc a researcher copies to write
their first real source doc, so the omission propagates.

**`91ac89d` — a doc copied from the evidence template failed invariants 5 and
12.** Found while building 3.6, which creates docs *from that template*. The
`## Measured` guidance comment reads `No "confirms", "refutes", "proves"` — the
words invariant 5 greps for. And the `artifacts:` example shipped as live YAML
pointing at `output/<theme>/<chart>.png`, so invariant 12 failed on every copy.
Fixed in the check for the first (a comment is guidance, not a measurement — the
Measured section is now stripped of `<!-- … -->` before the grep) and in the
template for the second (the block is commented out, so absent is the default,
which is what `evidence.md` says it should be).

**`d0829ba` — the conventions described invariants that no longer matched the
code.** `citation-discipline.md` called invariant 13 "proposed" in a *Gaps*
section after it shipped, and `evidence.md` described invariant 9 as one check
in one direction after it became two tiers. The handoff named the first
explicitly as a condition of 3.4b.

### What measurement changed, against the spec

**Invariant 9 is two checks, not one.** Specced as a single FAIL: an artifact
referenced from `deliverables/` that no evidence doc lists under `artifacts:`.
Measured on the pilot that is **67 of 67**, because zero evidence docs carry an
`artifacts:` key — it shipped in Phase 2 of this plan, so on any project
predating v3 every reference is unbound by construction. Splitting on *does any
evidence doc mention this path at all* gives 14 / 53:

| | | |
|---|---|---|
| **9 FAIL** | 14 | appear nowhere in `research/evidence/` — the audit's finding |
| **9b WARN** | 53 | discussed by a doc but not listed — an adoption meter |

This keeps the phase's intent (the three-missing-docs check FAILs) without the
cliff where the first person to adopt the key inherits 66 failures.

**Invariant 10 compares two things, not one.** Specced as *artifact commit newer
than the doc's `date:`*. That is a commit timestamp against a hand-authored
measurement date, and the green fixture — doc and chart in **one commit** —
reported itself stale. Comparing against the doc's last commit alone has the
opposite flaw: a typo fix after a re-render masks the staleness. It now requires
both, and compares `%ct` seconds rather than `--date=short`, because at day
resolution a same-afternoon re-render compares equal and the check silently
misses it. That last one was found by a fixture that came back green when it
should have been red.

**Invariant 13's tier rationale no longer holds, and it was left WARN anyway.**
D2 made it WARN because it had 573 targets. Those were bare `#nn` — invariant
14's population, and 14 did not exist when D2 was written. Measured today, 13's
population on the pilot is **zero**. Left WARN because that honours the recorded
decision and WARN → FAIL is a one-word change; flagged for a researcher call.

### What the checks found on the pilot

- **Invariant 8 is green: 123 distinct evidence ids across 48 claims all
  resolve.** The `^#{2,3} C[0-9]+` anchor matters exactly as the 2026-08-05
  review said — `^## C[0-9]+` matches **0** of those 48 headings.
- **Invariant 9 FAILs on 14 artifacts.** These are `docs/v2-case-study-cordoba.md`
  §7's "highest-value follow-up", now enumerated by a command rather than by
  hand. `plan.md`'s closing note — that running v3's lint against the pilot is
  the cheapest validation that invariant 9 is real — is discharged.
- **Invariant 14 is green, and its ceiling is now written into the script.**
  158 distinct bare ids all resolve, and 119/131/139 are correctly absent
  because T2's renumber banners claim them. But evidence ids are contiguous —
  285 docs over 1..285, **zero gaps** — so a transposed `#71` → `#17` resolves
  to the wrong doc and always will. That is the ceiling of the `#nn` form, and
  the strongest argument for `[C<n>]`, whose id space is sparse.

### Measured, and left alone

**The lint takes ~9s on the pilot, and ~8.9s of that predates this phase.** The
per-doc loop spawns roughly six subprocesses per document across 285 documents.
Invariant 9 adds ~0.5s (one `grep -rhoFf` pass; per-path recursion cost 9s on
its own and was replaced). Not fixed here — it is not in the task list and not a
regression — but a nine-second linter is an adoption risk by the same logic that
produced the WARN tier. **Phase 6 candidate.**

### Adjacent checks, deliberately not shipped

Both are one-liners; neither is in the task list, and a phase that quietly grows
its own scope is how a plan stops predicting anything.

- `claims.md` says "a claim with no ids is an assertion — delete it." Nothing
  checks it.
- A dangling `**Supersedes the reading of:** #62` is a broken link. Invariant 8
  deliberately reads only the ids before the first `·`, so it does not see it.
