# Brainstorm mechanism — design rationale

## The problem this solves

Applied research projects routinely produce a long methodology essay early
on — a document that *feels* like a plan because it names variables, sketches
identification, and lists data sources, but that never resolves the
trade-offs into actual choices. Implementation sessions then stall because
the questions the essay should have settled — *which* deflator, *which*
identification strategy, *which* reference category, *what* to do about a
survey-vintage break — keep coming back. The team re-debates choices that
were never explicitly decided.

The brainstorming skill closes this gap. It makes "settle the decisions"
a distinct, named step that runs *before* the planning skill, so plans
inherit a settled set of choices rather than a list of open questions.

## Three pieces

### 1. The skill (`.claude/skills/brainstorming/SKILL.md`)

Drives the conversation. Three phases — listen and synthesize → challenge
and probe → propose alternatives and trade-offs — with research on demand
when the discussion surfaces a knowledge gap. Output is one of two
shapes: an implementation brainstorm (handoff to the planning skill) or
an exploratory brainstorm (summary only).

### 2. The convention (`.claude/conventions/brainstorm-format.md`)

Documents the file shape (`brainstorms/<topic>.md`), the five-section
output structure (Problem / Decisions / Research / Open Questions /
Constraints), the optional "Decision records to file" section, and the
boundary with `decisions/`, `plan/`, `evidence/`, and `/verify`. Read on
demand by Claude when invoked by the skill or when the researcher edits
a brainstorm.

### 3. The directory (`brainstorms/` — gitignored)

Project-local working state. Created by `r2p init`. Theme-parallel
projects may use `brainstorms/<theme>/<topic>.md`; flat is the default.

## Why brainstorms are gitignored

Brainstorms are the *conversation* — durable enough to reference within a
session and across a few sessions, but not the artifact a peer reviewer
should cite. The citable form of any methodology call is a
`decisions/YYYY-MM-DD_<slug>.md` record, which **is** committed. Splitting
the two surfaces protects two distinct goals:

- **`brainstorms/`** stays free-form, exploratory, sometimes sloppy —
  the place where wrong turns and rejected alternatives live.
- **`decisions/`** stays clean, structured, citable — the place a peer
  reviewer or successor researcher reads to understand *what was chosen*.

If brainstorms were committed, two failure modes would compound: (1) the
team would feel pressure to clean them up before commit, defeating the
"thinking out loud" purpose; (2) successors would find both the brainstorm
and the decision record and have to reconcile two sources of truth.
Gitignored brainstorms means the decision record is the canonical form;
the brainstorm is the working draft that fed it.

## Why brainstorms are distinct from `/verify`

Both involve "is this right?" questions, but at different points in time:

- **Brainstorming happens before the artifact exists.** The question is
  *which approach to take*. Output: decisions and a path to a plan.
- **`/verify` happens after the artifact exists.** The question is *does
  this specific artifact look right*. Output: a 3–5-check audit on
  sign-of-coefficients, magnitude, missingness, source citation,
  provenance.

A brainstorm asks "should we use rgdpe or rgdpo for the productivity
series?". A `/verify` asks "the rgdpo coefficient on this regression is
+0.34 — is that plausible?". Different stages, different scopes,
different budgets.

## Why brainstorms are distinct from `decisions/`

A brainstorm is a *conversation*; a decision record is an *artifact*.
The brainstorm explores trade-offs across multiple decisions in one
session ("for this analysis we need to decide deflator, identification,
sample window, and reference category"); a decision record captures one
methodology call in one structured file with sections a peer reviewer
expects (Decision / Alternatives / Why-rejected / Key-assumptions /
What-would-invalidate).

Three brainstorms typically produce one or two decision records each.
Many decisions made in brainstorms are too low-stakes to graduate (file
naming, ordering of analysis steps, which subset to sanity-check first).
The "Decision records to file" section of the brainstorm is the
graduation list — choices that *do* deserve a `decisions/*.md`.

## What this does NOT do

- **Doesn't auto-trigger planning.** The brainstorming skill hands off to
  the planning skill explicitly when the researcher signals readiness
  ("let's write the plan"). Until then, the brainstorm stays in
  conversation. Auto-triggering would push half-settled decisions into
  plans.
- **Doesn't write decision records.** The skill names which choices
  deserve a record; the researcher writes them. Auto-writing decision
  records would produce structurally-correct but substantively-shallow
  records — the failure mode the convention is engineered to avoid.
- **Doesn't research everything upfront.** Research fills specific gaps
  as they emerge ("what's the standard reference category in this
  literature?"), not as a mandatory first step.
- **Doesn't enforce a length.** Five-line brainstorms are fine for short
  questions; longer brainstorms with three rounds of trade-off comparison
  are fine for stickier ones.

## Tradeoffs accepted

- **Skill triggering depends on phrasing.** "How should we measure
  productivity?" triggers; "let's measure productivity" doesn't always.
  The skill description lists the trigger phrases that work; researchers
  can also invoke it explicitly.
- **Two artifacts for some decisions.** A brainstorm + a decision record
  for the same call. The brainstorm captures the messy thinking; the
  decision record captures the citable conclusion. Some duplication is
  intentional — the brainstorm is gitignored, so the decision record
  has to stand alone.
- **Planning-skill agnostic by design.** The brainstorming skill triggers
  "the planning skill" — whichever is installed globally. r2p does not
  ship its own planning skill in v1.1; a research-domain rewrite is a
  v1.2 call if pilot use surfaces friction with the upstream version.

## Provenance

This convention codifies a gap surfaced during an audit of an applied-research
project that ran without r2p conventions. A long methodology essay had
been written that *felt* like a plan but never produced one — implementation
sessions kept stalling on choices the essay had only described, never
settled. The audit traced this back to the absence of a named "brainstorm"
step distinct from "plan." Adding it as an explicit skill — with an output
shape that hands off cleanly to the planning skill — was the smallest
change that closed the gap without inventing new categories.

The skill itself is a research-adapted port of the brainstorming skill from
`super-claudio-code`. The shape (three-phase conversation, two output
scenarios, maieutic principle) carries over; the domain examples (deflator
choice, identification, reference categories, survey-vintage breaks) and
the planning-skill-agnostic handoff are the adaptations. The gitignored-
brainstorms / committed-decisions split is also adapted from scc; in r2p it
maps cleanly to the existing `decisions/` convention.
