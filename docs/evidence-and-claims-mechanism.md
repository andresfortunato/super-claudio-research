# Evidence mechanism — design rationale

## The problem this solves

Research sessions produce a lot of artifacts — charts, panel CSVs, methods notes, derived tables. By default, Claude Code (and most AI coding agents) **report what they did** in their reply text and move on. The artifacts pile up; what was *learned* from them gets buried in the conversation, then lost when the session ends.

The traditional fix — "tell Claude to summarize at the end of every session" — has two failure modes:
1. **In CLAUDE.md**: a long protocol loads every turn (40+ lines), even on sessions that don't need it. Context bloat.
2. **As an always-fire reminder**: Claude is pressured to write something at every stop, so it writes trivial summaries to "comply" with the rule. Signal collapses.

The evidence mechanism is engineered to avoid both.

## Three pieces

### 1. The convention files (`.claude/conventions/{evidence,claims}.md`)

`evidence.md` defines what counts as an evidence-bearing finding, the frontmatter
schema, the `## Measured` / `## Reading` split, the numbering protocol, and the
discipline (one commit, never overwrite, append-only). `claims.md` defines the
curated layer above it — mandatory once the corpus passes 40 docs. Both live
outside CLAUDE.md and are read **only when Claude is actually writing one**. Cost:
zero context tokens on sessions that don't trigger them.

In v1 this was a single `evidence-logging.md`. v2 split it because the two layers
have opposite mutability: evidence preserves and is append-only; claims curate and
are editable and deletable.

### 2. The CLAUDE.md pointer (~4 lines)

Just enough to make Claude aware the convention exists and where to look:
```
## Research Record — claims, evidence, methods
1. research/claims.md — curated, editable. Start here when synthesizing.
2. research/evidence/NN_<slug>.md — append-only. `## Measured` holds numbers
   only; `## Reading` is the only place a verdict may appear.
3. research/methods/<topic>.md — one file per methodological object.
Two findings only contradict each other if their `unit` and `period` overlap.
Protocols: .claude/conventions/{claims,evidence,methods}.md (read on demand).
Lint: bash .claude/hooks/lint-research.sh
```

It grew from ~4 lines to ~8 because v2 gave the record three layers instead of
one, and the reconciliation rule (`unit` and `period` must overlap) has to be
resident — it is the thing a session gets wrong *before* it thinks to read a
convention file.

### 3. The lint (`.claude/hooks/lint-research.sh`)

Not a Stop hook. Run manually or from CI; exits 1 on any failure and fixes
nothing. It checks seven invariants of the research record, each one a defect
that actually happened on the pilot engagement:

```
1. INDEX.md headline > 120 chars      the index reached 330 KB, longest row 10,410 chars
2. duplicate evidence id              three collisions from parallel fan-outs
3. missing frontmatter or a key       id / headline / status / unit / period / confidence
4. filename id != frontmatter id
5. verdict word inside ## Measured    measurements must not carry verdicts
6. claims.md staler than newest evidence
7. method or source doc with no triggers:   invisible to retrieval
```

## Why a lint and not a Stop hook

v1 enforced this with `check-evidence.sh`, a Stop hook that nudged when
uncommitted analysis artifacts existed without a new evidence doc. v2 removed it.

The proximate reason is that it broke: its "have you already written one?" check
globbed `evidence/NN_*.md`, and v2 moved the corpus to `research/evidence/`. The
condition could no longer be satisfied, so a hook whose whole design premise was
*silent by default* began firing on every turn — pointing at
`conventions/evidence-logging.md`, which v2 had also deleted. **A hook whose
silence depends on a path is one refactor away from firing every turn, and it
fails in the direction of noise.**

The deeper reason is that the hook was testing the wrong thing. "A file exists in
`research/evidence/`" is not the property worth enforcing — it is trivially
satisfiable by writing a bad doc, and the pilot's failure mode was never *missing*
evidence. It was 151 docs that could not be read together: verdicts fused into
measurements, scope in prose, status as a banner, an index too large to load. None
of those are detectable at Stop time on one turn's diff; all seven are detectable
across the corpus at once. So the check moved from per-turn to per-corpus, and
from blocking to reporting.

What is lost: the per-turn prompt to write the doc while the analysis is fresh.
That obligation now rests on `.claude/conventions/evidence.md` and the researcher.
The trade was accepted because a nudge that fires on every turn gets ignored
within days, which is worse than no nudge — see "silent by default" in
`docs/audience-and-philosophy.md`.

## What this does NOT do

- **Doesn't enforce quality.** The lint checks structure — frontmatter present, id
  unique, no verdict words under `## Measured`. It cannot tell you the evidence is
  weak, only that it is malformed.
- **Doesn't auto-fix.** It reports and exits 1. Auto-rewriting frontmatter is how
  `04_evidence_frontmatter.py` froze a bad heuristic run into 151 docs.
- **Doesn't run on its own.** Nothing wires it to an event. If you want it on every
  commit, add it as a pre-commit hook; if you want it in CI, call it there.

## Extension points

- **Wire it up**: add `bash .claude/hooks/lint-research.sh` to a pre-commit hook or
  CI job. Deliberately not a Stop hook — see above.
- **Add an invariant**: each check is a self-contained block between `# --- N.`
  markers that sets `fail=1`. Follow the existing shape and add a `note` line.
- **Relax the headline cap**: the 120-char limit in check 1 is what took the pilot
  index from 330 KB to 33 KB. Raise it only with a number in hand.

## Provenance

This mechanism originated in a Cambodia growth-diagnostics project where multi-phase analysis kept producing charts faster than findings were being distilled. After 7 phases, the team realized the most useful artifact across plans was a *project-level evidence index* — and the only way to keep it populated was to make "writing the evidence" a turn-stop concern, not a session-end concern. The folder was originally called `insights/` — renamed to `evidence/` to make the contrast with `learnings/` (operational gotchas) explicit.

---

## v2 addendum — why an append-only corpus needs a curated layer

v1 got the append-only rule right and stopped there. The rule is correct: an
evidence corpus is an audit trail and has to survive being wrong, so nothing in
it is edited or deleted. The consequence v1 did not anticipate is that the
corpus is therefore **monotonic** — it only grows, and nothing in it distills.

At 151 docs on the pilot engagement, with 122 of them cited directly from memos
and decks, that produced three failures at once:

1. **No triage surface.** `INDEX.md` grew to 330 KB because the "Title" column
   absorbed findings, caveats and retraction banners — median 1,554 chars,
   longest 10,410. It cost ~80k tokens to read and returned undifferentiated
   prose.
2. **No stable citation target.** Deliverables cited 122 evidence ids directly,
   so every evidence revision threatened every deliverable.
3. **A distillation rebuilt from scratch every session**, differently each time.

`research/claims.md` is that distillation, written down once, with the opposite
mutability rule from the layer beneath it: **evidence preserves, claims curate.**
Deleting a claim is cheap and correct; deleting an evidence doc destroys the
record. One indirection — deliverables → claims → evidence — means a retired
evidence leg updates one claim and its consumers keep working.

The threshold is **40 evidence docs**. Below that the capped index is still a
usable triage surface and the ledger is overhead.

See `docs/v1-to-v2-migration.md` for the four evidence defects v2 fixes and the
calibration table.
