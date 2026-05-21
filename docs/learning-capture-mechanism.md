# Learning capture mechanism — design rationale

## The problem this solves

Applied research projects accumulate two kinds of valuable knowledge:
the *formal findings* a peer reviewer reads (a chart, a regression, a
ranked list of decompositions) and the *methodology calls* a peer
reviewer pushes on (deflator choice, identification strategy). Both
have homes in r2p — `evidence/NN_*.md` for findings,
`decisions/YYYY-MM-DD_<slug>.md` for choices.

A third kind of knowledge has no home in v1: the *tacit warnings* — the
kind of thing a colleague would say over coffee. "PONDII didn't exist
in 2014 EPH waves." "Asking-vs-transaction price gap is roughly 10% in
Argentina ZonaProp listings." "If you build a panel from EPH 2003 onward
without filtering on `agglo` you'll silently lose the rural sample." In
projects that ran without r2p conventions, these warnings either lived
in researcher heads (lost on handoff) or were buried in commit messages
and notebook scratch cells (invisible at retrieval time, when a future
session is about to make the same mistake).

The learning-capture mechanism closes that gap with three pieces.

## Three pieces

### 1. The skill (`.claude/skills/learning-capture/SKILL.md`)

Triggered when the pre-compact hook fires, when the user asks ("save a
learning", "remember this gotcha"), or when work surfaces a discovery
worth preserving. Drives a two-file write: `learnings/<slug>.md` plus a
`triggers:` row in `learnings/index.yaml`. Two types: **gotcha**
(severity low/medium/high; problem/solution/prevention) and **insight**
(discovery/why-it-matters/when-to-apply).

### 2. The convention (`.claude/conventions/learning-capture.md`)

Documents the file shape, the index format, the retrieval contract
(min 2 trigger matches, top 3 surfaced), the atomicity rule (both
files updated together), and the boundary with `evidence/`,
`decisions/`, and `brainstorms/`.

### 3. The retrieval hook (`.claude/hooks/retrieve-learnings.sh`)

UserPromptSubmit hook. Reads `learnings/index.yaml`, tokenizes the
user's prompt, counts trigger overlap per entry, and emits the top
3 matching learnings as `additionalContext` when at least one entry
has ≥2 matches. Silent otherwise. ~80 lines bash with a single
runtime dep (jq, the framework's ceiling). The companion PreCompact
hook (`precompact-handoff.sh`) nudges the model to refresh the active
plan's handoff and capture any session surprises before context is
compacted away.

## The three-bucket model

```
                      ┌──────────────────────────────┐
                      │ project knowledge             │
                      └──────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
   ┌─────────┐               ┌──────────┐                ┌──────────┐
   │evidence/│               │decisions/│                │learnings/│
   └─────────┘               └──────────┘                └──────────┘
   findings                  methodology                  tacit
   from data                 calls                        warnings

   evidence-based            peer-reviewable              operational
   numbered docs             dated records                short notes
   chart-backed              alternatives + why-rejected  triggers + body
   project-wide              project-wide                 project-wide
   committed                 committed                    committed
```

The three are **distinct in stakes, structure, and audience**:

- **`evidence/`** is *what the data shows*. A peer reviewer reads it for
  the headline numbers; a successor researcher reads it to understand
  what's been established. Stakes-graded by `/verify` and surfaced via
  `INDEX.md`. The Stop hook nudges if analysis happens without an
  insight doc.
- **`decisions/`** is *how we chose to look at the data*. A peer
  reviewer reads it to understand why a particular deflator or
  identification strategy was preferred. Auditable, with structured
  Alternatives / Why-rejected / Key-assumptions / What-would-invalidate
  sections.
- **`learnings/`** is *what we tripped over along the way*. Short,
  operational, retrieval-keyed. A successor researcher hits the same
  trigger keywords in a future prompt and gets the warning surfaced
  automatically — no manual lookup, no folder browsing.

A learning may **prompt** an insight (the gotcha leads to a follow-up
analysis) or **graduate** to a decision record (the gotcha forces a
methodology call), but it doesn't **replace** either. The three layers
serve different consumption patterns.

## Why project-wide, not theme-aware

Even in projects using the opt-in theme-parallel layout for `evidence/`
and `output/` (see `docs/theme-parallel-mechanism.md`), learnings stay
flat at `learnings/<slug>.md` — never `learnings/<theme>/<slug>.md`.

The reasoning: a gotcha about a survey wave (PONDII not in EPH 2014)
is *universal*, not theme-bound. It applies whether the analysis is
about labor markets or spatial equilibrium or political-economy
contagion. Theme-locking the directory would force researchers to
duplicate learnings, or worse, silently miss applicable ones because
they're filed under the "wrong" theme.

Trigger-keyword matching does the routing. A learning's triggers field
("PONDII EPH 2014 panel attrition vintage") is what surfaces it in
relevant prompts — independent of which theme's analysis raised the
prompt. The directory shape stays simple; the retrieval contract
carries the routing.

## Why trigger-keyword retrieval over LLM matching

Two alternatives were considered:

1. **Trigger keywords (chosen).** Each learning lists 4–8 specific
   keywords; the hook matches by literal word overlap with the prompt;
   minimum 2 hits to fire.
2. **LLM-based semantic matching.** Each prompt is embedded; learnings
   are embedded; cosine similarity routes the top-N.

Trigger keywords win on three axes:

- **Sub-millisecond.** A grep over a YAML file is ~1 ms. Embedding +
  cosine similarity over even a few dozen learnings is 100–500 ms per
  prompt — paid on every UserPromptSubmit, every session. The hook
  budget is "near-zero" by design.
- **Deterministic.** Word-overlap is reproducible: "Why does PONDII fail
  in EPH 2014?" matches the same learning every time, with the same
  match count. Embedding-based routing drifts as embedding models
  evolve, defeating the audit-trail purpose.
- **Transparent.** A researcher can read `index.yaml`, see the trigger
  string, and predict whether their prompt will match. With LLM
  matching, the researcher can't anticipate or debug routing — they
  add a learning, hope it surfaces, and have no way to confirm the
  match logic.

The cost: trigger keywords miss synonyms ("EPH" doesn't match "Encuesta
Permanente de Hogares"), and they require deliberate keyword choice
when filing. The discipline section of the convention addresses this —
choose specific concrete tokens, not generic ones. False positives are
the noisier failure mode, and the ≥2-match threshold filters them.

## Why severity is on gotchas only

Gotchas have a severity field (`low | medium | high`); insights don't.
The asymmetry is intentional: a gotcha's severity tells future sessions
how much to weight the warning. A `high`-severity gotcha cost the
project hours or invalidated a published number; a `low`-severity
gotcha is a footnote.

Insights (the learning type) are *neutral* knowledge — they don't carry "this hurt us"
weight. The body sections (Discovery / Why it matters / When to
apply) carry the import without needing a severity tag.

## Why two-file atomicity

Every learning write produces both `learnings/<slug>.md` and a
`learnings/index.yaml` row. Skipping the index is the failure mode that
makes the corpus invisible to retrieval — the hook reads
`index.yaml`, not the directory.

The skill enforces this; the convention restates it; this mechanism
doc explains why a single-file design (parse the directory contents
directly) was rejected: it would force the hook to open every `.md`
file on every prompt, and would tie retrieval to filename heuristics
rather than explicit researcher-curated triggers. An explicit index
keeps retrieval cheap, retrieval-routing under researcher control, and
the directory itself free to carry whatever shape and length the
learnings need.

## Tradeoffs accepted

- **Two writes for every learning.** The atomicity rule means filing a
  learning is a two-step write. The skill handles this; manual writes
  must remember to update both. The convention's "Atomicity" section
  is the durable reminder.
- **Triggers depend on phrasing.** A researcher who writes "Why is the
  Argentina household panel breaking?" won't hit triggers tuned for
  "PONDII EPH 2014 vintage". The fix is broader trigger sets when
  filing, not LLM-side matching. Pilot use will reveal whether 4–8
  keywords is enough; the convention's calibration may shift in v1.2.
- **Index file is the single source of truth.** A learning file
  without an index row is invisible. This is intentional (researcher
  controls retrieval) but means `find learnings/ -name '*.md'` may
  show files that retrieve-learnings.sh won't surface. The wiki-lint
  pattern (orphan detection) could extend to learnings in v1.2.
- **No automated graduation.** A high-severity learning that names a
  methodology choice doesn't auto-create a `decisions/*.md`. The
  researcher names it. Auto-promotion would produce structurally
  correct but substantively shallow records — the failure mode the
  decision-records convention is engineered to avoid.

## What this does NOT do

- **Doesn't run on a clock.** The retrieval hook fires on every
  UserPromptSubmit by design; there is no timer-based audit, no
  "weekly learnings review" automation. The pre-compact hook
  prompts capture; otherwise the researcher (or the skill, on user
  invocation) writes when the moment calls for it.
- **Doesn't replace `wiki/`.** The wiki holds *distilled* knowledge
  from sources (papers, scrapes, dataset notes). Learnings hold
  *operational warnings* from execution. A finding about how a
  literature handles a problem belongs in `wiki/concepts/`; a
  finding about how *our project* tripped over a problem belongs
  in `learnings/`.
- **Doesn't enforce length.** A two-paragraph gotcha is fine; a
  longer write-up with code examples is fine. The retrieval cost
  is independent of file length (only triggers are scanned by the
  hook).

## Provenance

This mechanism codifies a gap surfaced during an audit of an
applied-research project that ran without r2p conventions. The
project produced excellent evidence and a handful of decision records,
but operational warnings — survey-wave breakage, deflator-divergence
patterns, sample-restriction side effects — lived in researcher heads
and commit messages. Each new researcher onboarding to the project
re-discovered the same gotchas. The audit traced this pattern back
to the absence of a third bucket: somewhere committed, retrieval-keyed,
short.

The skill, file format, and retrieval mechanic are research-adapted
ports from `super-claudio-code`. The retrieval hook
(`retrieve-learnings.sh`) and the pre-compact handoff hook
(`precompact-handoff.sh`) are bash re-implementations of scc's
`user-prompt-submit.js` and `pre-compact.js` — the v1 framework
constitution forbids JS leakage outside the `r2p` CLI itself.

The directory choice (`learnings/`, project root, sibling of
`evidence/` and `decisions/`) deviates from scc's `.scc/learnings/`
nesting. r2p treats learnings as project-level knowledge worth
sharing in the repo, not as framework-internal state.
