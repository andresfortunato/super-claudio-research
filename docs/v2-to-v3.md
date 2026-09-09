# v2 → v3 migration

**v3 has no migration.** No directory moves, no frontmatter rewrites, no
scripts to run. That is the headline, and it is deliberate: v2 moved every
research file in every project, and a second migration one release later would
have burned the credibility the first one bought. v3 adds keys and checks and
takes nothing away that a project depends on.

What it adds is the thing v2 left undone. v2 established a citation chain —

```
deliverable ──→ claim ──→ evidence ──→ artifact ──→ script ──→ source
```

— and checked almost none of it. Every change below closes a link, or hardens
something that broke while closing one.

## What changed

| v2 | v3 | Why |
|---|---|---|
| the chain is implied across four conventions | **`.claude/conventions/citation-discipline.md`** | It was stated nowhere, so each convention described its own end of it and nobody owned the middle. |
| nothing binds a chart to a finding | **`artifacts:` on the evidence doc** | `git log` records how a chart was *produced*; nothing recorded *which finding it carries*. |
| `lint-research.sh`, 7 checks, ~11s | **18 checks, 2.3s** | Four links of the chain went unchecked. The speedup is what made adding four more affordable. |
| pick the next evidence id by hand | **`r2p evidence new <slug>`** | `.next-id` shipped in v2 with nothing reading it. Hand-picking ids is how the pilot got five collisions. |
| `/verify`, `/deliverable-review` | **`+ /cite-check`, `+ /pipeline-check`** | Two links need a model to check and cannot be done in bash. |
| verification graded by token cost | **graded by token cost *and* side-effect cost** | `/pipeline-check` is the first tier that writes anything. The constitution was amended before it shipped, not after. |
| nine design principles | **ten** | *Silence reads as a pass* — four v3 mechanisms reached it independently. |
| 14 `docs/*-mechanism.md` | **6** | Eight described conventions v2 merged away: accurate about v1, misleading about the framework. |
| `--upgrade` untested | **`npm test`, 21 assertions** | Three v2 defects lived only in the second installer and none was visible to an `init` test. |
| `0.2.0` | **`0.3.0`** | — |

Nothing was removed from a project's layout. No hook was added; v3 adds none at
all, and the reason is in *Traps* below.

## The three links v3 closes

Each ships as **a cheap lint invariant plus a user-invoked skill**, never as
one or the other. Link resolution is grep and belongs in bash, where it runs for
free on every corpus; walking a document's numbers needs a model and costs real
budget, so the researcher asks for it. A mechanism that shipped only its
expensive half would be used by whoever remembered to type it.

### 1. deliverable → claim

**The Córdoba symptom:** memos and decks cited **122 evidence ids directly**,
bypassing the claim layer entirely, and three headline numbers cited nothing at
all — invisible for six months, because nothing can see a link that is simply
absent.

**The mechanism:** a deliverable cites claims (`[C12]`), never evidence ids. One
indirection is the whole point — a retired evidence leg updates one claim, and
every deliverable resting on that claim keeps working. Invariant 13 (FAIL)
catches a `[C12]` matching no claim heading; invariant 14 (WARN) catches a bare
`#nn` naming no live evidence id, honouring renumber banners. `/cite-check`
walks the half no grep can see: whether the number in the sentence is the number
in the evidence doc, and whether a quantitative paragraph cited anything at all.

**Migration for existing deliverables:** none, and that is a decision (**D** in
the plan). Measured on the pilot: 573 bare `#nn` references and zero `[C<n>]`
across three drafts of one memo, against a ledger already holding 42 claims. A
bulk converter is possible — each claim's `Rests on:` makes `#71 → C12` a
lookup — but an id can support several claims and the right one depends on what
the sentence asserts, so a script could only ever *propose*, and the result
would be one unreviewable diff against the ledger. `citation-discipline.md`
carries a **convert-on-touch** rule instead: the next edit to a paragraph
converts that paragraph. Revisit in v4 if convert-on-touch measurably stalls.

### 2. claim → evidence → artifact

**The Córdoba symptom:** the three-lens growth-gap exhibit carrying a memo's §1
lived in a plan handoff and a render script. There was no evidence doc, and
nothing could tell.

**The mechanism:** an optional `artifacts:` frontmatter key on the evidence doc,
listing the chart and table paths *this doc is the written-up finding for*.
Invariant 9 flags an artifact used in `deliverables/` that no evidence doc
mentions; 9b flags one an evidence doc discusses but does not bind; 12 flags an
`artifacts:` path that does not exist. Invariant 8 flags a claim whose
`Rests on:` names an id with no file; 16, 17 and 18 flag a claim resting on
retracted evidence, a claim with no ids at all, and dangling ids in a claim's
`Contested by:` / `Supersedes` legs.

**Why a frontmatter key and not `save_fig(findings={...})`** — the shape the
backlog proposed. It fails principle 6: the framework's core is language-neutral
and a Python helper is not. It also re-opens a question principle 7 settled — a
`manifest.jsonl` PostToolUse hook was removed in v1 because git plus a script
header already gives ~80% of the audit value at zero install cost. One optional
key on the doc that already holds the finding costs nothing per chart, works in
R, Python or Stata, and turns "chart exists with no evidence doc" into a
`test -f`. Full rationale in `docs/citation-chain-mechanism.md`; it is recorded
because a contributor who does not know why `save_fig` was rejected will propose
it again.

**The key is hand-authored or absent.** No heuristic may populate it —
principle: never infer a field whose wrongness is worse than its absence.

### 3. evidence → script → source

**The Córdoba symptom:** porting a chart forced a re-read of its data, and the
source had published a new wave in the meantime. The evidence doc had been
stale for weeks and read as current.

**The mechanism:** invariant 10 (WARN) flags an evidence doc older than the
artifacts it binds. `/pipeline-check` traces a doc to its producing script
through the provenance trail, re-runs it, and diffs against `## Measured`.

**`## Measured` was already a freshness anchor and nobody had noticed.**
Principle 9 demands a re-runnable value beside every freshness date; the block
is concrete numbers from a documented procedure, held verdict-free by invariant
5 — a rule written for *legibility* that turns out to be the property an
automated diff needs. The skill did not invent an anchor format; it recognised
one. Principle 9 is generalized in v3 to say so.

## The tier that writes, and the bound on it

`/pipeline-check` re-runs analytical scripts. Every prior verification tier was
read-only, and that was never a stated property — it was a coincidence of the
first three all being *review* tools. The constitution was amended **before**
the skill shipped (`c7543f5`), per its own rule that a proposal failing a
principle revises the document first. Principle 7 now grades on two axes:

| Axis | Question |
|---|---|
| **Token cost** | zero / ≤2k / ≤12k — how much context does invoking it spend? |
| **Side-effect cost** | read-only / writes derived files / writes source files — what does it change if it is wrong? |

Four bounds make a side-effecting tier admissible, and they are narrow on
purpose:

1. It re-runs existing, human-inspectable code — never writes or edits a script.
2. It writes only derived files the script declares in its header `Outputs:`.
   Never `data/raw/`, never source, never a deliverable.
3. It stays user-invoked. An always-fire tier that executes scripts is a build
   system.
4. It reports what it ran.

**A future proposal that wants to write source files does not inherit this
amendment.** It fails principle 7 as amended and revises the document again.

## Adopting v3 on an existing project

```bash
cd /path/to/your/research-project
r2p init --upgrade
```

That is the whole migration. Then:

```bash
bash .claude/hooks/lint-research.sh
```

**Expect findings on first run, and read them before fixing them.** Eleven
checks are new since your last upgrade, and on a live corpus they will surface
defects that have been there for months. That is the point; it is not a
regression. Two things to know before you start closing them:

- **A WARN is a WARN on purpose.** The split is not severity theatre. FAIL is
  for a broken link or a duplicate id — mechanical, never a judgement call, and
  never numerous enough to drown a project. WARN is for findings that need an
  eye, or whose true-positive count on a real project is large enough that
  failing the build would train everyone to ignore the linter.
- **Re-measure before you compare.** Any baseline against a live engagement
  decays in weeks.

Three optional adoptions, in the order they pay:

1. **`r2p evidence new <slug>`** from now on. It allocates atomically from
   `.next-id`; hand-picking is the collision vector.
2. **`artifacts:` on new evidence docs**, and on old ones when you next touch
   them. It is optional and absent is fine.
3. **`[C12]` on the next paragraph you edit** in a deliverable. Convert on
   touch; do not bulk-rewrite.

## Traps

Four things that will bite, three of them found the hard way during v3 itself.

### A new hook is mirrored but not wired

`r2p init --upgrade` **never rewrites a project's `.claude/settings.json`** —
correctly, since that file is the project's own. So a hook added by the
framework lands on disk in every upgraded project and runs in none of them,
while a hook *removed* by the framework keeps running in every project that
already had it wired.

Both halves are live right now: `check-evidence.sh` was deleted in v2 and is
still firing in the pilot, a year later. v3 makes `--upgrade` warn about a
removed hook by name and say whether the project is still wired to run it, and
invariant 15 catches the same orphan from the other direction. **Neither
auto-deletes.** Removing the `settings.json` entry is yours.

This is also why v3 adds no hook. A check that cannot be reliably wired is a
check that half your projects do not run.

### A shipped file must not point into `docs/`

`r2p init` does not install `docs/`. So a convention, skill, hook or template
citing `docs/<name>.md` resolves perfectly in the framework repo and dangles in
every project built from it — a defect class that is *invisible where it is
authored*. v3 found nine instances and fixed them by pointing at conventions
(which are installed) or by naming the framework repo explicitly. Invariant 15
catches new ones, but only when run against a project rather than against the
framework: **a framework cannot check itself against itself.**

### The half-repathed pointer is worse than the stale one

In three of four cases v3 examined, a dangling pointer was not the defect — it
was a thread attached to a live v1 *instruction* underneath.
`precompact-handoff.sh` routed learnings to a directory `retrieve-learnings.sh`
does not read. A skill demanded an `index.yaml` its own heading said no longer
exists. Fixing the pointer alone leaves an instruction that now succeeds at
producing the wrong layout, which fails silently where a dangling reference
fails visibly. When you repath a reference, read what it was pointing *at*.

### An inventory of invisible defects is always short

v3 hand-listed the stale pointers three times, at five, then seven, then ten —
and the pilot's seven were not the same seven. The lesson is in the argument
itself: **when the case for a check is "the defect is invisible", stop
enumerating and write the check.** The corollary is narrower and cost a wasted
pass — widening what a check *looks for* is nearly free, but widening what it
*reads* is not. Broadening invariant 15's target pattern found four more real
defects; broadening its citing set to the whole tree produced 22 pilot findings
that were mostly the researcher's own prose. **A check's precision lives in
which files it reads.**

## The full record

- The design rationale for the three mechanisms, including the two redesigns and
  why the rejected shapes were rejected: `docs/citation-chain-mechanism.md`.
- The verification tier list and how the two new skills fit it:
  `docs/verification-architecture.md`.
- The constitution, with principle 7's amendment and the new principle 10:
  `docs/audience-and-philosophy.md`.
- The audit that motivated all of it: `docs/v2-case-study-cordoba.md`.
- Framework bugs found while running the framework: `docs/field-notes/`.
