# research/ — the durable record

Everything the project *knows*, in three layers. Read them in this order.

| Layer | What it is | Mutability |
|---|---|---|
| **`claims.md`** | the ~40 load-bearing claims the narrative rests on | **editable + deletable** — it is a curated view |
| **`research/evidence/`** | `NN_<slug>.md` + `INDEX.md`, one doc per analysis | **append-only** — never overwritten or deleted |
| **`research/methods/`** | one `<topic>.md` per methodological object | living; versioned in place with a `## Changelog` |
| **`sources/`** | one `<source>.md` per external API or dataset | living; re-verified when touched |
| **`research/wiki/`** | optional distilled pages + the `raw/` source archive | unused on this project |

## Start here when synthesizing

`claims.md`, then `research/evidence/INDEX.md`. Together they are ≤30 KB and should tell
you what the project knows, what is contested, and which evidence doc to open
next. If they don't, the ledger is stale — say so rather than reconstructing it
silently from 151 evidence docs.

## The one rule that prevents false contradictions

Every evidence doc declares `unit`, `geography` and `period` in frontmatter.
**Two findings can only contradict each other if their unit and period
overlap.** Province and metro routinely flip sign on labour questions; that is
two measurements of two objects, not a disagreement. When a real conflict does
exist, it goes in the claim's `Contested by:` field and stays there until
someone settles it. Never soften wording until both sides fit.

## Why the layers have opposite mutability

Evidence preserves; claims curate. An append-only corpus is the audit trail —
it has to survive being wrong. But an append-only corpus at 151 docs cannot be
read, so the curated layer on top is what a narrative actually cites. Deleting
a claim is cheap and correct; deleting an evidence doc destroys the record.

Protocols: `.claude/conventions/{claims,evidence,methods,sources}.md`.

`_legacy/` holds v1's `research/methods/` and `research/methods/` while their content is
folded into `research/methods/` and `sources/`. It is deleted when that finishes.
