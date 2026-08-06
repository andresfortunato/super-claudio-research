# Log — plan-r2p-v3

Direction changes and dead ends. Appended, never rewritten. `plan.md` stays
stable unless the researcher approves a change; each entry below records one that
they did.

---

## D1 — 2026-08-05 · Principle 5's line budgets are dropped

**Raised during:** Phase 1, on discovering that all four of its routes landed in
files the phase's own constraint said were near a ≤120-line ceiling.

**What was found.** Phase 1's constraint quoted destination sizes in **KB** but
stated the limit in **lines**, so the headroom it assumed did not exist. Measured
in lines, **5 of 8 conventions already breached the limit before this plan ran**
(`evidence.md` 146, `methods.md` 144, `plan-lifecycle.md` 214,
`project-conventions.md` 185, `source-registry.md` 184). Three further facts
decided it:

1. **The cap was never in principle 5's body.** The body prescribed 80–120 lines
   for *CLAUDE.md*, because CLAUDE.md is loaded every session. The ≤120-line
   *protocol* cap existed only in the checkable-questions table, which applied the
   CLAUDE.md number to a different object.
2. **Nothing enforced it.** The only mechanical `120`s in the repo are unrelated —
   `lint-research.sh`'s 120-**character** INDEX headline cap and
   `retrieve-learnings.sh`'s own `MAX_LINES`.
3. **The mechanism the principle protects was never at risk.** Conventions are
   read *on demand*; the always-loaded budget is CLAUDE.md, which is 38 lines in
   this repo and 107 in `templates/CLAUDE.md.template`.

By the framework's own codification test — *a prescribed format with 10%
compliance is wrong, not disobeyed* (case study §6.6) — a rule at 37% compliance
in r2p's own repo is wrong rather than disobeyed.

**Researcher's decision.** Drop the rule, and **leave the length of CLAUDE.md to
the user.** Broader than the four options offered: not only is the protocol cap
removed, the framework stops prescribing CLAUDE.md's length at all. It is the
researcher's file.

**What changed, and why it landed out of phase.** The constitution's own rule is
that a revision is explicit and lands *before* the addition that depends on it.
Phase 2 creates `citation-discipline.md` and its spec said "≤120 lines", so the
edit could not wait for Phase 7.

| File | Change |
|---|---|
| `docs/audience-and-philosophy.md` | principle 5 body: line budgets removed, dated revision note explaining why; questions-table row now tests *shape* (is the rule in the convention file, with only a pointer in CLAUDE.md?) with no numbers |
| `docs/extending.md` | "Length target: 50–120 lines" → split-on-the-trigger test, no number |
| `phases/phase-1.md` | constraint marked `⚠ CORRECTED`, kept visible as the wrong version |
| `phases/phase-2.md` | both `≤120 lines` criteria marked `⚠ CORRECTED` and voided |
| `plan.md` | File Manifest line for `citation-discipline.md` |

**Deliberately not done.** The 5 over-length conventions are left exactly as they
are — under the new principle their length is not a defect, so "fixing" them would
be work created by a rule that no longer exists. `evidence.md` (187) and
`provenance.md` (135) keep Phase 1's additions.

**Still open, for Phase 7.** `docs/project-conventions-mechanism.md:49–50` cites
"Principle 5 (Short CLAUDE.md)" as a token-cost argument. That file is one of the
stale v1 mechanism docs already pending **decision B**; the citation is now one
step more stale. Fold it into whatever B decides rather than patching it twice.

---

## D2 — 2026-08-05 · Pilot-repo review corrects a shipped Phase 2 assumption

**Raised by:** a review of `~/cordoba-growth-narrative` (v2 layout, 173 evidence
docs, 42 claims, 10 worktrees) asking what the pilot does that the framework
doesn't follow.

**The correction.** `claims.md` specified the claim heading as `## C<n>` **and**
said to group claims under `##`-level narrative sections. Both cannot hold. The
pilot resolved it by demoting claims to `###` — its 42 claims all sit at
`### C<n>` under six `## §N` sections. Phase 2 shipped `citation-discipline.md`
assuming `## C<n>`, so **a checker built to that spec would report zero claims on
a full 42-claim ledger**: a false all-clear, which is strictly worse than a false
alarm. Fixed in both conventions — resolution now matches `^#{2,3} C[0-9]+`.

This is §6.6 (*the emergent format is the specification*) catching a defect one
release after the case study named the lesson.

**What else the review measured, and where each landed:**

| Finding | Landed |
|---|---|
| 573 bare `#nn` refs, 0 claim refs across 3 memo drafts, against 42 existing claims | `citation-discipline.md` § *Adopting this on a project that already cites evidence directly*; new **Decision D** |
| invariant 13 as FAIL would be unusable mid-adoption | `phase-3.md` ⚠ ADDED — write it WARN, print counts, no silent caps |
| claims at `###` breaks any `^## C` anchor | `phase-3.md` ⚠ ADDED — match `^#{2,3} C` |
| invariant 11 already passes on the pilot (id 173, `.next-id` 174) | `phase-3.md` ⚠ ADDED — will not self-demonstrate there |
| pilot still runs `check-evidence.sh`, wired in `settings.json`; no `check-archival.sh` | `phase-6.md` 6d ⚠ ADDED — upgrade gains an orphaned-hook warning + test asserts it |
| `--upgrade` warns about obsolete `skills/` and stale EXCLUDEs but **never** about orphaned hooks | same |
| pilot `CLAUDE.md` still lists `.claude/skills/` and "a Stop hook" | `phase-6.md` 6d ⚠ ADDED — noted, out of scope, warning is the cheap fix |

**Checked and found already correct — no action:** the `_inbox/` staging rule was
already promoted into `templates/CLAUDE.md.template`; the pilot is fully on the v2
layout; all its CLAUDE.md convention pointers resolve; project-local
`.claude/skills/` is correctly absent (skills live in `~/.claude/skills/`, which
symlinks to this repo, so framework skill edits reach installed projects
immediately).

**Deliberately not done.** The pilot's own remediation — converting 573 references,
filing the three missing evidence docs — remains out of scope per *Open Items
Deferred*. This entry changes the framework, not the pilot.
