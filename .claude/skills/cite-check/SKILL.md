---
name: cite-check
description: (r2p) Walk one finished deliverable's citation chain — every number traced to a claim, every claim to live evidence. Use when the user says "/cite-check <path>", "is every number in this memo cited", "check the citations before I send this", or asks whether a draft's claims hold up to their evidence. Finished drafts only; user-invoked, never auto-fires. Budget ≤2k tokens.
allowed-tools: Read, Bash, Glob, Grep
---

# cite-check

Answer one publish-time question about one deliverable: **is every number in
here traceable to a claim, and is every claim it cites still standing on live
evidence?**

The chain (`.claude/conventions/citation-discipline.md`):

```
deliverable ──[C12]──→ claim ──Rests on: #71──→ evidence ──artifacts:──→ artifact
```

`lint-research.sh` checks that references *resolve*. This checks that the
deliverable *uses* them — a different question, and the expensive half.

## When to invoke

- `/cite-check deliverables/cordoba-diagnostic.md`
- "Is every number in this memo cited?"
- "Check the citation chain before this goes to the minister."
- "Does this deck still rest on live evidence?"

## When NOT to invoke

- **The draft is mid-composition** — see *Refuse early* below. This is the
  common case and the refusal is the feature.
- **One artifact, not a whole document.** `/verify` — one regression, one
  chart, one paragraph.
- **A full substantive review.** `/deliverable-review`, ≤12k, parallel lenses.
  This skill has no opinion on whether the argument is any good.
- **The user wants the references fixed.** This reports. The researcher
  resolves — the mapping `#71 → C12` proposes, the author decides
  (`citation-discipline.md` § *Adopting this*).

## Refuse early

On a mid-composition draft **every number is uncited**, so the report is
noise — and a check that fires constantly on correct work is how a format
reaches 7-of-71 compliance. Before anything else, scan for:

- sections marked `TBD`, `TK`, `[CHECK]`, `[cite]`, `XXX`
- headers with no body under them
- an outline of bare bullets with no prose sentences

If any hit, **refuse in one line** and point at `/verify` for partial checks.
Do not produce a partial report as a compromise; a diluted report gets
skimmed and the habit of skimming is what this is defending against.

**Do not use length as the test.** `/deliverable-review` has an ≥800-word floor
because a seven-lens fan-out is too expensive to spend on a stub; a ≤2k check
has no such excuse, and the documents that most need a citation walk — a
two-page briefing note, a one-page ministerial summary — are short *and*
finished. Refuse on draft markers, never on word count. *(Caught by the Phase 4
fixture: a 127-word finished memo carrying all three defect classes, which an
inherited 500-word floor refused outright.)*

## Preconditions

- The target path exists and is readable. If not, stop and say so.
- `research/claims.md` exists. Without a ledger there is nothing to trace to,
  and the honest output is "this project has no claim layer yet" plus a
  pointer at `claims.md`. Not a defect report.

## Workflow

**1. Run the lint once, first.** `bash .claude/hooks/lint-research.sh`

Do **not** re-derive what it already knows. Invariant 13 (FAIL) has resolved
every `[C<n>]` in `deliverables/`; invariant 14 (WARN) has resolved every bare
`#nn`, honouring renumber banners; invariant 9's FAIL list enumerates artifacts
used in deliverables that no evidence doc mentions — that list is a worklist,
already built. Read its output and carry the findings into your report; spend
your own budget on the three classes below, which it cannot see.

**2. Extract references from the target file.** Regexes are settled and
verified — reuse them, do not re-derive:

| Thing | Form | Gotcha |
|---|---|---|
| claim reference | `\[C[0-9]+\]` | rejects `[1]`, `[23]`, `[2024]`, `[c12]`, image alt-text |
| evidence reference | `#[0-9][0-9A-Fa-f]*`, then drop any token carrying a hex letter or >4 digits | `#5FA1C7` reads as id 5; `#266798` reads as id 266798 |
| claim heading in `claims.md` | `^#{2,3} C[0-9]+` | `^## C[0-9]+` alone matched **0** of the pilot's 48 claims — they sit at `###` under `## §N` sections |
| `Rests on:` ids | ids **before the first `·`** only | the rest of the line is `**Supersedes the reading of:** #62` |

**3. Report the three classes.** In this order — it is worst-first.

### Class 1 — cites nothing

The judgement walk, and the reason this skill exists. Enumerate every number in
the prose and captions, then triage each:

| Verdict | Test |
|---|---|
| **defect** | a number *you measured*, carrying no `[C<n>]` |
| **exempt — external** | a figure quoted from a named source, **and the source is named in the same sentence**. "The World Bank puts it at 4.2%" is fine; "it is 4.2%" with the source three paragraphs up is not |
| **exempt — not a finding** | a year, a page or section number, a count of interviews, a currency unit, a date, an ordinal |
| **ask** | genuinely ambiguous. Ask once, in a batch at the end — never one question per number |

On the pilot this class found **three load-bearing memo numbers with no evidence
doc at all**, invisible for six months. The absence of a citation was the only
observable symptom that the evidence had never been written.

**When a number cites nothing, exactly two repairs exist** and both are in
`citation-discipline.md` § *A number that cites nothing*: add the reference, or —
if it traces to nothing — write the claim first, which forces the evidence doc.
**Say this in the report.** The third option a hurried author reaches for is
softening the sentence until it stops needing a citation, which buries the gap in
prose and resurfaces it in the next deck.

### Class 2 — cites evidence directly

Bare `#nn` in the deliverable body: the v1 form, legal but wrong-shaped. One
indirection through a claim is the whole point — a retired evidence leg then
updates one claim instead of threatening every deliverable resting on it.

- **Report the count. Never truncate silently.** On a mid-conversion project
  this is large and accurate — the pilot carries 159 distinct ids across 1053
  occurrences. A capped list reads as "mostly fine" when it is not, so print the
  total, show a bounded sample, and state what was dropped.
- **Recommend convert-on-touch, not a sweep.** A repo-wide rewrite is one
  unreviewable diff against the ledger.
- **The argument that actually persuades** — say it, because "tidiness" does not:
  evidence ids are contiguous (285 docs over 1..285, zero gaps), so a transposed
  `#71` → `#17` resolves to the wrong doc and no check will ever catch it. Claim
  ids are sparse and hand-curated, so `[C99]` is caught immediately.
  **Convert-on-touch buys checkability.**
- An `#nn` that no claim rests on is the **valuable** output, not an
  inconvenience: it is either a claim nobody wrote or a number that should not
  be in the deliverable. Both are findings. Name them separately.

### Class 3 — cites a claim standing on retired evidence

For each `[C<n>]` in the deliverable: find `^#{2,3} C<n>` in `research/claims.md`,
read its `Rests on:` ids (before the first `·`), open each evidence doc, read
`status:`.

| `status:` | Verdict |
|---|---|
| `live` | pass |
| `revised` | **flag** — part of the doc is retired. Read the doc's banner and say which leg, then whether this deliverable leans on that leg or the part that stands |
| `retired` | **defect** — the whole doc is superseded. Follow `superseded_by:` and name the replacement |

`status:` exists precisely so this is filterable, and nothing yet filters on it.
The pilot carried 25 docs with prose retraction banners while retired legs kept
being cited from doc bodies — a retraction that exists only as prose is invisible.

*(This class is mechanical enough to be a lint invariant one day. It is not one
today, so it lives here. Do not add it to `lint-research.sh` from this skill.)*

## Report format

One markdown report to stdout. Always all four sections; `(none)` where empty.

```markdown
# /cite-check <path> — YYYY-MM-DD

**Lint:** invariant 13 <PASS|FAIL, n unresolvable> · invariant 14 <n of m bare ids unresolved>
**This document:** <n> numbers examined · <n> `[C<n>]` · <n> bare `#nn`

## Cites nothing — <n>
| Number | Sentence (trimmed) | Why it is not exempt |

## Cites evidence directly — <n> occurrences, <n> distinct ids
<bounded sample; state the total and what was dropped>
Of these, <n> are cited by no claim in the ledger: <ids> — each is a missing
claim or a number that should not be here.

## Cites retired or revised evidence — <n>
| Ref | Claim | Evidence | status: | Replacement |

## Not flagged — <n>
<one compressed line-list: the number, then two or three words of reason>

## Researcher decisions
<the batched ambiguous cases, and nothing else>
```

**The *Not flagged* section is not padding.** Without it a reader cannot tell an
exemption from a miss, and a report whose silence is ambiguous gets discounted
whole. This is the rule `lint-research.sh` already applies to inapplicable
invariants — an invariant that vanishes when it had nothing to check reads as a
pass. Keep it to a compressed line-list, never a table, and cap it like any
other list: print the count, show a sample, say what was dropped.

## Rules

- **Never edits the deliverable.** Reports only — same posture as
  `/research-cleanup`, which writes a proposal and touches nothing.
- **≤2k tokens.** If it will not fit, cut narrative and keep the tables. A
  verbose report on a memo that needs one fix is a report nobody finishes.
- **Print counts, cap lists, always say what was dropped.**
- **Prefer a flag over a pass.** A false positive costs a glance; a silent miss
  ships an uncitable number to a minister.
- **One batch of questions at the end**, or none.

## Cross-references

- `.claude/conventions/citation-discipline.md` — the chain, the `[C<n>]` form,
  convert-on-touch, and the *number that cites nothing* rule this enforces.
- `.claude/conventions/claims.md` — what a claim is and its six fields.
- `.claude/conventions/evidence.md` — `status:` semantics and supersession.
- `.claude/hooks/lint-research.sh` — invariants 13, 14, 8, 9. Run it; do not
  reimplement it.

## What this skill does NOT do

- **Does not check whether a reference resolves.** Invariants 13 and 14 do, and
  they are cheaper. This asks whether the reference is *there* and *right-shaped*.
- Does not judge the argument, the framing, or the audience fit —
  `/deliverable-review`.
- Does not check one artifact's plausibility — `/verify`. **The boundary:**
  `/verify` asks *does this one paragraph cite something?*; `/cite-check` asks
  *does this whole deliverable's chain hold, end to end?*
- Does not convert `#nn` to `[C<n>]`. The lookup proposes, the author decides.
- Does not edit, and does not auto-fire.
