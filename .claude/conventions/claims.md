# Claims Ledger — Protocol (new in v2)

**Trigger**: the project's evidence corpus passes **40 docs**. Below that the
capped `INDEX.md` is still a usable triage surface and this file is overhead.
Above it, the ledger is mandatory.

## The problem it solves

`research/evidence/` is append-only by design, and must stay that way — the
audit trail depends on nothing being edited or deleted. The consequence is that
the corpus is **monotonic**: it only grows, and nothing in it distills. On the
pilot engagement it reached 151 docs, 122 of which were cited directly from
memos and decks.

With no layer in between, every synthesis session rebuilt one from scratch, from
a 330 KB index, differently each time — which is exactly what "the model gets
lost when synthesizing" looks like from the inside. The ledger is that layer,
written down once.

## Where it lives

`research/claims.md` — a single file. Not a directory. If it needs a directory
the project has confused claims with evidence.

## Shape

```markdown
# Claims ledger
**Last reviewed:** 2026-08-04 against evidence #151

## §2 — Labour: the deficit is formal        <!-- optional narrative section -->

### C12 — Gran Córdoba's employment deficit is formal, not total
**Status:** live · reviewed 2026-08-03
**Unit:** metro (EPH aglomerado 13) · **Period:** 2014–2025
**One number:** the formal employment-rate gap vs the nation widens 4.3 pp
while the total employment rate holds flat — informality absorbs the shortfall.
**Rests on:** #71, #72 · **Supersedes the reading of:** #62
**Contested by:** —
```

Six fields, no more:

| Field | Rule |
|---|---|
| heading | `C<n> — <claim as a sentence>` at **`##` or `###`** — `###` when the ledger groups claims under `## §N` narrative sections, `##` when it doesn't. `C<n>` is stable forever; never renumber. Anything reading the ledger must match `^#{2,3} C[0-9]+`, never `^## C` alone. |
| `Status` | `live` \| `open` \| `retired`. `open` = we expect to settle it. |
| `Unit` / `Period` | copied from the evidence it rests on. If sources disagree on unit, that is a `Contested by:` row, not a claim. |
| `One number` | exactly one, the one you would put on a slide. If you can't pick one, it isn't a claim yet. |
| `Rests on` | evidence ids. A claim with no ids is an assertion — delete it. |
| `Contested by` | evidence ids, or a named open question, or `—`. |

## The three rules that make it work

**1. Claims are editable and deletable. Evidence is not.** The ledger is a
*view*, not a record. Rewrite a claim when the reading changes; delete it when
it dies. Git history is the genealogy. This is the inverse of the evidence
rule and the inversion is deliberate — one layer preserves, the other curates.

**2. `Contested by:` is where narrative↔evidence conflicts live, and it is
never resolved silently.** A non-empty field is an open question *by
construction*, visible in one file. The distinction to hold:

- **A flag** (`Contested by: #94 measures this at province level and gets the
  opposite sign`) is an open question. It stays until someone settles it.
- **A retraction** is a closed one: the claim is deleted or rewritten, and the
  evidence id that killed it is named in the replacement.

Never reconcile a conflict by softening the wording until both sides fit. That
buries the disagreement in prose and it resurfaces in the next deck.

**3. Deliverables cite claims; claims cite evidence.** On the pilot, memos and
decks cited 122 evidence ids directly, so every evidence revision threatened
every deliverable. One indirection fixes it: a retired evidence leg updates one
claim, and the claim's consumers keep working.

The deliverable side of that indirection needs a syntax, or it cannot be
followed: **a deliverable cites a claim as `[C12]`** — square bracket, capital
`C`, digits, no `#`, no ranges. Extractable with `\[C[0-9]+\]`, narrow enough that
prose numbers and `[1]`-style footnote markers cannot match it. Because `C<n>` is
stable forever and never renumbered, the reference survives copy-paste into a Word
draft or a slide deck. A number in a deliverable with **no `[C<n>]` and no named
external source is not publishable yet** — write the claim, which forces the
evidence doc. Full rules, and what each broken link looks like:
`.claude/conventions/citation-discipline.md`.

## Size and maintenance

- **~30–50 claims** for a 6-month multi-theme engagement, ~6 KB. If it passes
  60, claims are being written at evidence granularity — merge.
- **Review trigger**: any evidence doc newer than the ledger's
  `Last reviewed` line. A hook nudges; the review is a human-or-model pass, not
  an automatic append.
- Group claims under `##`-level narrative sections if the project has them, so
  the ledger reads in deliverable order. **Claims then sit at `###`** — see the
  heading rule above. This is what the pilot's 42-claim ledger does, under six
  `## §N` sections, and it is why the heading rule allows both levels: an earlier
  draft of this convention specified `## C<n>` *and* `##` narrative sections,
  which cannot both hold.

## Success test

A session that reads `research/claims.md` plus `research/evidence/INDEX.md`
— together ≤30 KB — should be able to state what the project knows, what is
contested, and which evidence to open next, **without opening a single evidence
doc**. If it can't, the ledger is stale or the index cap is being violated.
