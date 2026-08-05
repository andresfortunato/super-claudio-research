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
