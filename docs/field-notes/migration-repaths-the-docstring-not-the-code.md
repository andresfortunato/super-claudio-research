# A path-token repath rewrites the docstring and misses the code

**Encoded in:** `templates/migration/02_repath.py` § *Bare-segment guard* — `bare_segment_hits()` reports every path expression naming a moved directory as a bare quoted segment, and **fails the repath**. It never rewrites one. Watch list derived from `RULES`, not restated.

## Problem

`02_repath.py` rewrites v1 paths to the v2 layout by matching **path tokens**,
and every rule in its table carries a trailing slash:

```python
("evidence/", "research/evidence/")
```

A path built segment-by-segment has no slash for the rule to match:

```python
EVID = REPO / "evidence"                # not matched — no slash
"""Inputs: research/evidence/*.md"""    # matched, rewritten
```

So a script's **documentation** is repathed while the line that actually opens
the directory is not. The two then disagree, and the report says the job is done.

Measured on the pilot's 2026-08-04 run: `evidence/ -> research/evidence/`,
**571 rewrites across 559 files, double-prefix guard clean** — and **four dead v1
paths left in code**:

| Site | Consequence |
|---|---|
| a plan's coverage gate | `IndexError` — dead since the day of the migration, unnoticed for a fortnight |
| the project's shared utility module | dead constant, fails at first use |
| two deck chart scripts | `OUT_DIR.mkdir(parents=True, exist_ok=True)` on the v1 target — **re-creates a directory the migration deleted**, writes the chart into it, exits 0 |

The third row is the one that matters. A dead path that raises is a bug you find.
A dead path that `mkdir`s is a migration that **silently undoes itself** the next
time anyone runs a chart script, and nothing in the repo records that it happened.

## Why the check has to be a report, not a rewrite

Turning `X / "evidence"` into `X / "research" / "evidence"` requires knowing what
`X` is. It is the repo root in three of the four sites above and the script's own
directory in three *other* sites in the same repo, where the bare segment is
correct and must not be touched. A wrong rewrite of a path expression is worse
than an unrewritten one — it moves the failure from "file not found" to "wrong
file found". Hence: detect, fail, make a human look.

Two suppressions keep it honest, both measured against the pilot:

- **`__file__` earlier on the line.** `Path(__file__).parent / "slides"` inside a
  deliverable is that deliverable's own subfolder; it did not move. Without this
  rule the guard reports **3 false positives** on the pilot.
- **the v2 parent already quoted earlier on the line.** `ROOT / "research" /
  "methods"` is correct v2 and must not be flagged.

With both, the pilot yields **4 hits, 4 real, 0 false**. That measured-zero is
the whole argument for failing rather than warning: a one-shot migration whose
miss is silent is exactly how this defect survived six months.

## The second bug, which is the more general one

The pilot's coverage gate did not report "0 evidence docs found". It died forty
lines later on `IndexError: list index out of range`, because:

```python
by_num = defaultdict(list)
...
assigned[sp] |= set(by_num[str(n)])   # READ — auto-vivifies an empty list
...
if n not in by_num:                   # now answers "resolved" for phantom ids
    continue
seen.add(by_num[n][0])                # IndexError
```

**A membership test against a `defaultdict` is not a membership test.** Reading a
missing key creates it, so any later `in` check is answering a question about the
lookups you have already done, not about the data. It converted a loud, obvious
failure — an input directory that does not exist — into a cryptic one nobody
diagnosed.

Generic enough to be worth stating on its own: **if a container is a
`defaultdict`, test with `key in dict(...)`, or don't make it a `defaultdict`.**

## Applies to

Any `templates/migration/` script, and any future path-rewriting tool. The class
is broader than migration: **a mechanical rewrite over text will always miss the
structured construction of the same value**, and the artefact it *did* rewrite
(comments, docstrings, README paths) is what makes the miss invisible, because
the file now reads as if it were correct.

## Does not apply to

The pilot's own four sites. Repairing those is engagement work; this note and the
guard are the framework's share.

## Related

- [[porting-a-chart-forces-a-data-reread-and-the-data-moves]] — the other note
  where a document and the code behind it drift apart and only the document is
  believed.
- Fourth defect of the class `CLAUDE.md` names: *lives only in the
  upgrade/migration path, invisible to an `init` test.*
