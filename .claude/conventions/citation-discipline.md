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
- **Resolving a reference means matching `^#{2,3} C<n>` in `research/claims.md`,
  never `^## C<n>` alone.** A ledger that groups claims under `## §N` narrative
  sections carries them at `###`. The pilot's 42-claim ledger does exactly that,
  so a checker anchored to `##` reports **zero claims on a full ledger** — a
  false all-clear, which is worse than a false alarm.

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
| `[C12]` matches no `#{2,3} C12` heading | deliverable → claim | invariant 13 *(proposed)*, `/cite-check` |
| `Rests on:` names an id with no file | claim → evidence | invariant 8 |
| a chart in a deliverable that no evidence doc lists in `artifacts:` | evidence → artifact | invariant 9 |
| an `artifacts:` path that does not exist on disk | evidence → artifact | invariant 12 |
| a headline number with no `[C<n>]` at all | deliverable → claim | `/cite-check` only |

The last row is the expensive one, and deliberately so: finding *every* number in
a document and asking whether it is cited is a judgement walk, not a grep. That is
`/cite-check`'s job, at the ≤2k tier.

## Adopting this on a project that already cites evidence directly

Measured on the pilot: three drafts of one memo carry **573 bare `#nn` evidence
references and zero claim references**, against a ledger that already holds 42
claims. Direct citation is not a habit someone can be told out of — it was the
only expressible form before `[C<n>]` existed, so every existing deliverable is
in the old form by construction.

- **Convert on touch, not in a sweep.** When you edit a paragraph, convert the
  references in it. A repo-wide rewrite re-opens every deliverable at once and
  makes one enormous diff nobody can review against the ledger.
- **The mapping is mechanically derivable, and must still be checked by hand.**
  Each claim's `Rests on:` lists its evidence ids, so `#71 → C12` is a lookup.
  But an id can support several claims, and the right claim depends on what the
  *sentence* asserts — so the lookup proposes, the author decides.
- **An `#nn` that no claim rests on is the valuable output of the exercise**, not
  an inconvenience: it is either a claim nobody wrote down, or a number that
  should not be in the deliverable. Both are findings.
- Until a project's deliverables are converted, `/cite-check` will report large
  counts. That is accurate. **It must print the count rather than truncating** —
  a silent cap reads as "mostly fine" when it is not.

## Repairing an ambiguous evidence id

`.next-id` (`evidence.md`) is the *prevention* half. This is the *recovery* half.

**This is the fifth recorded appearance of the evidence-id collision** — and the
count is the reason the section exists. It has arrived by three distinct vectors:
parallel worktrees on separate branches, parallel agent teams inside one worktree,
and a **second numbering namespace** (a `research/evidence/<topic>/` subdirectory
whose ids restarted at 20 and collided with the root's). The third of those
`.next-id` cannot defend against at all: nothing was allocated twice, the counter
was simply never consulted. Prevention is necessary and has not been sufficient
once. Read this section as load-bearing, not as a hypothetical.

**A collision breaks link 2 in a way no lint can see.** `Rests on: #119` resolves
— to two different files. The check passes, the citation is wrong, and nothing
errors.

### The rule: renumber the doc, never tag the reference

The pilot ran the full recovery cycle on three collisions and both halves are
measured. **Only one held.**

| Repair | Verdict |
|---|---|
| **Renumber the doc**, banner it, append `(was #NN)` to the headline | **held** — still resolves correctly, and is self-describing to a reader who has never heard of the collision |
| **Tag the reference inline** — `#119`(sec) vs `#119`(mig) | **rots** — do not use |

The inline disambiguator is **rejected, not an alternative.** It fails for a
structural reason, not a discipline one: the tag encodes a distinction *between*
two ids, so it is frozen against a numbering that the renumbering step then
changes. On the pilot, the disambiguation table names three files that no longer
exist, and three memo fragments still carry `#119`(sec) pointing at a doc that has
been `#149` since 2026-08-04. **A reference cannot be repaired in place; only the
doc can.** Tagging spreads the collision to every citation site and leaves nothing
that a later reader can resolve.

### The banner

Renumbering silently is worse than the collision — every existing citation of the
old id becomes wrong with no trace. The doc that moves carries a banner directly
under the frontmatter, and it states four things:

```markdown
> ⚠ **Renumbered 131 → 150 on 2026-08-04.** This doc shared id #131 with another
> evidence doc after a parallel fan-out. Citations reading "#131" before that date
> may mean either doc — check the unit and period.
```

1. **Old id and new id**, in that order. The old id is what a stale citation
   carries, so it is what a reader arrives searching for.
2. **The date.** It is what makes the ambiguity bounded rather than permanent.
3. **How the collision happened** — one clause. It tells the next reader whether
   the vector is still open.
4. **The explicit ambiguity warning**, naming the old id in quotes and saying how
   to disambiguate (`unit` and `period` are the discriminating keys —
   `evidence.md`, *Frontmatter scope keys make contradictions checkable*).

Append `(was #NN)` to the doc's headline as well. The banner serves someone who
opened the file; `(was #NN)` serves someone scanning the INDEX, who is the reader
more likely to be holding the stale id.

**Which doc moves:** the one with fewer inbound citations. Renumbering is a cost
paid per citation site, and the point is to pay it once.

**`status:` does not change.** The id moved; the finding did not. `revised` means
part of the doc is retired (`evidence.md`) and setting it here puts a retraction
signal in the INDEX for a doc that retracted nothing. *(The pilot set `revised` on
all three, for want of anything better — the banner it wrote is the part that
graduated, not the status.)*

**A renumber is one commit** — the doc, its INDEX row, and `.next-id`. Splitting it
leaves a window in which the INDEX points at a file that does not exist.

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
