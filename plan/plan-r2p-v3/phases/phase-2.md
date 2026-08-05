# Phase 2 — State the chain once, and make each link expressible

**Plan:** `plan/plan-r2p-v3/plan.md` · **Depends on:** nothing (may start before 1/6 finish)
**Blocks:** Phase 3 · **Session scope:** one session · **Estimated context:** ~35%

## Intent

v2 established `deliverable → claim → evidence → artifact → script → source` and
verified none of it. This phase writes the chain down once and makes each link
*expressible* — Phase 3 then checks it. A check for a rule that has not been
written is a guess about what the rule would have said.

The gap is narrower than it looks. Read before writing:

- `claims.md` already says *"A claim with no ids is an assertion — delete it"* and
  *"Deliverables cite claims; claims cite evidence."* The rules exist.
- **What does not exist is a syntax for the deliverable side.** Nothing in v2
  says how a memo names the claim it is citing, so nothing can find it. That is
  the actual hole, and it is why the pilot's memos cited 122 evidence ids
  directly — direct citation was the only expressible option.
- `evidence.md` frontmatter carries `id / headline / status / unit / geography /
  period / confidence`. No artifact binding.

## Tasks

**2.1 — `.claude/conventions/citation-discipline.md`** ✚
State the chain, what each link obliges, and what a broken link looks like. Every
rule either names the Phase 3 invariant that checks it or is explicitly marked
advisory — an unenforced rule in a new convention is how `learnings/index.yaml`
got to 7-of-71 compliance.
*Done when:* ≤120 lines (principle 5); zero absolute-count thresholds (§1 — ranks
or shares only); a reader can state from this file alone what `Rests on: #71`
obliges and who checks it.

**2.2 — The deliverable→claim syntax** ✎ `claims.md`, `citation-discipline.md`
Pick one greppable form for a deliverable citing a claim (`[C12]` is the obvious
candidate — stable, unambiguous, survives copy-paste into a Word draft) and
specify it. The claim heading `## C<n>` is already stable-forever and never
renumbered, so the id is a safe anchor.
*Done when:* a regex can extract every claim reference from a memo, and the
convention says what to do with a number that cites nothing.

**2.3 — `artifacts:` on evidence frontmatter** ✎ `evidence.md`,
`templates/research/evidence/EXAMPLE_01_slug.md`
Optional list of the chart/table paths this doc explains. **Hand-authored or
absent — no heuristic may ever populate it.** Say that in the convention, with
the reason: §5.3's scope-key inference tagged a 24-province panel as
`metro | 1960–2026` because a year regex swept every number in the first 6 KB,
and *a confidently wrong field manufactures the exact false contradiction the
field exists to prevent.* A blank makes a reader open the doc; a wrong one makes
them trust it.
*Done when:* the example doc shows both a populated `artifacts:` and the absent
case, and the spec states the no-inference rule with its reason.

**2.4 — Cross-links** ✎ `provenance.md`
Provenance answers *how* an artifact was made; `artifacts:` answers *which
finding it carries*. Neither subsumes the other and both should say so, or a
future session will collapse them and re-open the `manifest.jsonl` question v1
settled.
*Done when:* each file points at the other in one sentence.

## Verification

- `citation-discipline.md` ≤120 lines, no absolute counts, every rule mapped to
  an invariant or marked advisory.
- The claim-reference regex, run against a hand-written three-claim fixture memo,
  extracts exactly three references and no false positives from prose numbers.
- No new *directory* anywhere. v3 adds keys and checks, never layout.
- `bash .claude/hooks/lint-research.sh` still passes.

## Do not touch

`.claude/hooks/lint-research.sh` (Phase 3 — writing the check here would make
this phase unverifiable against its own spec), `templates/migration/*`,
`.claude/skills/migrate-source/` (Phase 6).

## Commit discipline

By pathspec, one command. One commit for the new convention, one for the
frontmatter key, one for the cross-links.
