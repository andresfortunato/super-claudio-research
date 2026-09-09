# Citation chain — design rationale

## The problem this solves

v2 named a chain and checked none of it:

```
deliverable ──→ claim ──→ evidence ──→ artifact ──→ script ──→ source
```

Naming it was worth doing — before v2 the corpus was one append-only pile with
no curated layer — but a chain nothing resolves is a diagram, not a mechanism.
Six months of Córdoba produced one broken link of each kind, and the reason none
was caught is the same in all three cases: **an absent link has no textual
footprint.** A wrong citation can be grepped. A missing one cannot.

| Link | What broke on the pilot |
|---|---|
| deliverable → claim | memos and decks cited **122 evidence ids directly**, bypassing the claim layer; three headline numbers cited nothing at all |
| claim → evidence → artifact | the three-lens growth-gap exhibit carrying a memo's §1 lived in a plan handoff and a render script — no evidence doc existed |
| evidence → script → source | porting a chart forced a data re-read; the source had published a new wave, and the evidence doc had read as current for weeks |

Each had been true for months and none was visible to anyone reading the
corpus. That is the failure this mechanism set is shaped around, and it is why
the deliverable here is a *check* rather than a better-documented convention.

## The pieces

```
.claude/conventions/citation-discipline.md   ← the chain, stated once
.claude/hooks/lint-research.sh               ← invariants 8, 9, 9b, 10, 12, 13, 14, 16, 17, 18
.claude/skills/cite-check/SKILL.md           ← the deliverable → claim walk
.claude/skills/pipeline-check/SKILL.md       ← the evidence → script re-run
docs/citation-chain-mechanism.md             ← this file
```

Plus one optional frontmatter key (`artifacts:`) in `evidence.md`, and one line
under *Where Things Go* in `CLAUDE.md.template`. **No new section in
`CLAUDE.md`** — a mechanism with zero artifacts in a project does not get space
in the file that loads every session. The wiki held two such sections for six
months and produced nothing.

**And no hook.** See *Why no hook* below; the reason is mechanical, not
philosophical.

## Why every mechanism ships in two halves

Each link is checked twice, at two costs:

| Link | Cheap half (bash, free) | Expensive half (model, user-invoked) |
|---|---|---|
| deliverable → claim | invariants 13, 14 — does the reference resolve? | `/cite-check` — did the deliverable make one at all? |
| claim → evidence → artifact | invariants 8, 9, 9b, 12, 16, 17, 18 | *(none needed — the whole question is resolvable)* |
| evidence → script → source | invariant 10 — is the doc older than what it binds? | `/pipeline-check` — do the numbers still reproduce? |

This is principle 7 applied to the chain, and the split falls where it does for
a reason that is not budget: **the cheap half asks whether a stated link
resolves, and the expensive half asks whether a link that should exist does.**
The first is decidable by grep. The second requires reading a sentence and
judging whether it asserts something quantitative — which is exactly the
question nothing could answer on the pilot.

**No mechanism ships only its expensive half.** A skill is used by whoever
remembers to type it; a lint invariant runs on every corpus, for free, forever.
If a link can be partly checked in bash, that part goes in bash even when the
skill would cover it too.

## Redesign 1: `chart-registry` became a frontmatter key

The backlog carried this as **`save_fig(findings={...})`** — a Python helper
that writes chart metadata alongside every figure. Rejected, and the reasons are
recorded because a contributor who does not know them will propose it again.

**It fails principle 6.** The framework's core is markdown-first and
language-neutral; R and Python are both first-class and Stata is tolerated. A
Python helper serves one of three, and the R user's charts stay invisible to the
mechanism. Every other convention in the framework works by putting a fact in a
markdown file.

**It re-opens a question principle 7 already settled.** v1 shipped a
`manifest.jsonl` PostToolUse hook capturing timestamp, script, inputs, outputs,
`output_sha256`, seed, `env_hash` and git SHA. It was removed because git plus a
script header gives ~80% of the audit value at zero install cost, and the 20%
delta did not pay for a JSONL substrate, a `jq` dependency and a hook. A
`save_fig` registry is that proposal with a different serialization.

**And it answers a question nobody asked.** What git does *not* record is not
how a chart was produced — `git log -- <path>` resolves that already, via the
`Run:`/`Out:` commit lines. What nothing recorded is **which finding a chart
carries**. That is the actual Córdoba hole, and it is one line of frontmatter on
the document that already holds the finding:

```yaml
artifacts:
  - output/labour/emp_rate.png
```

Costs nothing per chart, works in any language, and turns *"a chart exists with
no evidence doc"* from a judgement call into a `test -f`.

**A per-chart sidecar (`emp_rate.png.meta`) was also considered and rejected**:
it doubles the file count in `output/`, and it puts the binding on the artifact
rather than on the finding — so a chart re-rendered under a new name silently
loses it. The binding belongs on the durable end of the link.

**The key is hand-authored or absent, and nothing may infer it.** A heuristic
that guesses which chart an evidence doc means would be right most of the time,
and the residue would be a confident wrong binding that satisfies invariant 9
and points at the wrong finding. *Never infer a field whose wrongness is worse
than its absence.* A doc with no `artifacts:` is the normal state, not a defect;
invariant 9b's finding is "you discussed this chart and did not bind it", which
is a prompt, not an error.

## Redesign 2: `/pipeline-check` is principle 9 generalized

The backlog framed this as *"TDD-equivalent for research pipelines"* — a
whole-pipeline regression harness. That framing implies a fixture corpus, a
golden-output store and a runner, which is a build system, and the framework is
explicitly not a workflow engine.

What made it tractable was noticing that **the anchor already existed**.
Principle 9 requires every freshness date to be paired with a re-runnable
value — a concrete number a future reader can re-produce to see drift. An
evidence doc's `## Measured` block *is* one, and had been since v2:

- concrete numbers,
- produced by a documented procedure,
- and kept **verdict-free** by lint invariant 5.

That third property is the one that matters, and it was a coincidence. Invariant
5 exists because measurements do not contradict each other and verdicts do — a
*legibility* rule, written so two docs on the same topic could be read side by
side. It happens to be exactly what makes the block mechanically diffable
against a re-run. The skill did not have to design an anchor format; it had to
recognise one. Principle 9's text is generalized in v3 to say so explicitly,
because the next such doc type should not need the same accident.

So the mechanism is not a harness. It is: trace the doc to its script through
the existing provenance trail, re-run that one script, diff the numbers.

**Why it re-runs rather than reporting.** The recommendation on file was
report-and-hand-over — print the command, let the researcher run it. Overruled,
and the reason generalizes: the finding is *"this chart is older than the data
under it"*, and the only useful response to that finding is to re-render the
chart. Printing a command that the researcher pastes back makes them a
copy-paste relay for a decision the check already made.

That made it the first framework tier that writes anything, so **the
constitution was amended before the skill shipped** (`c7543f5`), per its own
rule that a proposal failing a principle revises the document first rather than
being silently excepted. Principle 7 gained a side-effect axis and four bounds;
they are in `docs/audience-and-philosophy.md` and restated in
`docs/verification-architecture.md`. A proposal wanting to write *source* files
does not inherit that amendment.

## Why `/cite-check` is its own skill

It shares `/verify`'s budget (≤2k) and its trigger moment (about to publish), so
folding it in as a fourth check menu was the obvious move. Rejected on **shape**,
not cost.

`/verify` runs three to five *judgement-shaped* checks on one artifact and
chooses which apply — sign of coefficients, magnitude plausibility, missingness.
Choosing is the design. `/cite-check` is mechanical and exhaustive: it
enumerates every number in a document and asks the same question of each. **A
menu that sometimes runs is the wrong container for a walk that must not skip a
row.** The boundary is written into `verify/SKILL.md` as well, so a session
reaching for the wrong one gets redirected rather than getting a partial answer
that looks complete.

## Why no hook

v3 adds five lint invariants, two skills, a CLI subcommand and no hook, and the
reason is a property of the installer rather than a preference.

**`r2p init --upgrade` never rewrites a project's `.claude/settings.json`** —
correctly, since it is the project's own file. A new hook therefore lands on
disk in every upgraded project and is wired in none of them. A check that runs
in half the projects that have it is worse than one that runs in all of them by
being typed, because the half that silently does not run looks identical to the
half that passes.

The same asymmetry runs the other way and is live today: `check-evidence.sh` was
deleted by v2 and is still firing in the pilot, because nothing removed its
`settings.json` entry either. v3's `--upgrade` warns about a removed hook by
name and says whether the project is still wired to run it; it does not
auto-delete.

## Tier decisions, and the rule behind them

FAIL exits 1; WARN prints, counts and exits 0. The rule: **a check is FAIL only
if a green run on a correct project is genuinely reachable today.** Everything
else is WARN — not as a soft landing, but because a linter whose failures a
project cannot clear trains everyone to stop reading it. v2 deleted a hook for
exactly that, and the pilot reached the same conclusion independently in its
own `gate_retracciones.py`, which prints rows and asks for an eye rather than
shipping a test that misreports 12 of 40.

Two consequences worth recording:

- **Invariant 14 (bare `#nn` in a deliverable) will stay WARN.** Its
  true-positive population on the pilot is 573. Failing on it would fail every
  installed project by construction, since every existing deliverable is in the
  old form. `citation-discipline.md`'s convert-on-touch rule is the version that
  survives contact.
- **A tier chosen on a measured count is only as good as the count.** Invariant
  13 was written WARN on a volume argument that belonged to invariant 14; its
  own population turned out to be zero, and it was promoted. Re-measure before
  citing a number back at a tier decision, including one you made last session.

## Tradeoffs accepted

- **The last two links are advisory.** artifact → script rests on commit
  discipline (`provenance.md`) and script → source on a script header's
  `Inputs:`. Neither is mechanically enforced, because both live outside the
  markdown corpus the lint reads. `/verify` and `/pipeline-check` surface their
  absence when they trip over it.
- **`/pipeline-check` asks whether a number still *reproduces*, not whether it
  is *right*.** A pipeline reproduces a wrong number perfectly. That is
  `/verify`'s question, and the skills say so to each other.
- **No bulk `#nn → [C<n>]` converter.** Each claim's `Rests on:` makes the
  lookup derivable, but an id can support several claims and the right one
  depends on what the sentence asserts — so a script could only propose, and the
  output would be one unreviewable diff against the ledger. Convert on touch.
  Revisit in v4 if that measurably stalls.
- **The framework cannot check itself against itself.** Two defect classes —
  a shipped file pointing into `docs/` (never installed) or at `.claude/skills/`
  (global since v2) — resolve in this repo and nowhere else. They surfaced only
  when the lint ran against the pilot, and any future check with an install-time
  path dependency has the same blind spot.

## Extension points

- **A new invariant.** The cheapest extension in the framework; v3 used it
  eleven times. Admission test: the defect actually happened on a real project,
  and a green run is reachable. Steps in `docs/extending.md`.
- **A fourth link.** `source → upstream` is the obvious candidate — a
  `research/sources/` doc whose headline anchor no longer re-fetches. It is
  `/pipeline-check`'s shape pointed one step further out, and it needs a network
  call, which is why v3 did not take it.
- **`artifacts:` on a claim.** Today the binding lives on the evidence doc. A
  claim that carries an exhibit directly (a synthesis chart resting on six
  evidence docs) has nowhere to declare it. Wait for a project to hit this
  before adding the key.
