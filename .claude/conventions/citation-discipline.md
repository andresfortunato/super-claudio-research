# Citation Discipline — Protocol (new in v3)

**Trigger**: writing or revising anything under `deliverables/`; adding or editing
a claim in `research/claims.md`; adding an `artifacts:` binding to an evidence
doc. Not a session boundary — the trigger is the edit.

## The chain

```
deliverable ──[C12]──→ claim ──Rests on: #71──→ evidence ──artifacts:──→ artifact ──Run:──→ script ──data:──→ source
```

v2 established this chain and checked none of it. The consequence, measured on the
pilot: memos and decks cited evidence ids **directly**, bypassing the claim layer
entirely, and three headline numbers cited nothing at all — invisible for six
months, because nothing could see a link that was simply absent.

Every rule below names the mechanism that checks it or is marked **advisory**. A
rule nothing checks decays to whatever the last session felt like doing.

| Link | Expressed as | Checked by |
|---|---|---|
| deliverable → claim | `[C12]` in the deliverable body | `/cite-check` · lint **invariant 13** *(proposed — see Gaps)* |
| claim → evidence | `Rests on: #71, #72` in `research/claims.md` | lint **invariant 8** — FAIL |
| evidence → artifact | `artifacts:` frontmatter key on the evidence doc | lint **invariants 9, 12** — FAIL |
| artifact → script | commit message `Run:` / `Out:` (`provenance.md`) | `/verify` — **advisory** in lint |
| script → source | script header `Inputs:` + evidence `data:` | **advisory** |

Freshness rides alongside the last link: lint **invariant 10** (WARN) flags an
evidence doc older than the source data it declares. WARN, not FAIL, because a
re-render is often cosmetic and a linter that cries wolf gets ignored — which is
how `check-evidence.sh` died.

## Deliverable → claim: the `[C12]` form

**A deliverable cites claims, never evidence ids.** One indirection is the whole
point: a retired evidence leg updates one claim, and every deliverable resting on
that claim keeps working. Citing `#71` from a memo couples the memo to the
append-only layer, so every evidence revision threatens every deliverable.

- **Form:** `[C<n>]` — square bracket, capital `C`, digits, close bracket. No
  space, no `#`, no range syntax. Multiple claims: `[C12] [C14]`, not `[C12,14]`.
- **Extraction regex:** `\[C[0-9]+\]`. It is deliberately narrow enough that prose
  numbers, currency, footnote markers and `[1]`-style references cannot match it.
- **Where:** anywhere in the deliverable's prose, plus chart and table captions.
  A caption is where a reader is most likely to want the provenance.
- **`C<n>` is stable forever and never renumbered** (`claims.md`), which is what
  makes it safe to embed in a Word draft, a slide, or a PDF that outlives the repo.

### A number that cites nothing

**Every number a reader could quote back at you carries a `[C<n>]`.** When one
doesn't, exactly one of these is true, and both have a required action:

1. **It traces to a claim** — add the reference. Cheap, and the common case.
2. **It traces to nothing** — then it is *not publishable yet*. Write the claim
   first, which forces the evidence doc, which forces the artifact. Do not soften
   the sentence until it stops needing a citation; that buries the gap in prose
   and it resurfaces in the next deck.

This is the rule that would have caught the pilot's three load-bearing numbers.
Not a style preference — the absence of a citation was the only observable symptom
that the underlying evidence doc had never been written.

**Illustrative context is exempt**, and the boundary is whether the number is
*yours*: a figure you measured needs a claim; a figure you are quoting from a named
external source needs that source named inline, in the sentence.

## What a broken link looks like

| Symptom | Broken link | Where it surfaces |
|---|---|---|
| `[C12]` names no `## C12` heading | deliverable → claim | invariant 13 *(proposed)*, `/cite-check` |
| `Rests on:` names an id with no file | claim → evidence | invariant 8 |
| a chart in a deliverable that no evidence doc lists in `artifacts:` | evidence → artifact | invariant 9 |
| an `artifacts:` path that does not exist on disk | evidence → artifact | invariant 12 |
| a headline number with no `[C<n>]` at all | deliverable → claim | `/cite-check` only |

The last row is the expensive one, and deliberately so: finding *every* number in
a document and asking whether it is cited is a judgement walk, not a grep. That is
`/cite-check`'s job, at the ≤2k tier.

## Gaps — stated, not hidden

**Invariant 13 is proposed, not shipped.** Links 2 and 3 have cheap checks; link 1
currently has only the expensive one. The framework's own rule is that no mechanism
ships only its expensive half, so `[C<n>]` resolving to a `## C<n>` heading should
be a lint invariant — it is one grep against one file. Until it exists, treat the
first table row's lint column as a promise, not a fact.

Links 4 and 5 are **advisory on purpose**: `provenance.md` already makes them
`git log`-discoverable, and a lint that parsed every script header would duplicate
`/verify` at zero added confidence.

## Discipline

- **Deliverables cite claims; claims cite evidence; evidence cites artifacts.**
  Skipping a layer is the defect, even when the shortcut is correct today.
- **Add the citation in the commit that adds the number**, not in a cleanup pass.
  A cleanup pass is where "I'll trace that later" becomes six months.
- **A broken link is fixed by writing the missing layer, never by deleting the
  reference.** Deleting `[C12]` because C12 doesn't exist converts a caught defect
  into an uncatchable one.

## Distinct from neighbours

- **`claims.md`** — what a claim *is* and the six fields it carries. This file is
  how deliverables and evidence *reach* it.
- **`provenance.md`** — how an artifact was produced (`Run:` / `Out:` / script
  header). This file is about which *finding* an artifact carries. Neither
  subsumes the other.
- **`evidence.md`** — the shape of an evidence doc, including `artifacts:`.
