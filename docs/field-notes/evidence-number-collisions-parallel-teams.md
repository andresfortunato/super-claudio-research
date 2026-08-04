## Problem

Evidence docs are numbered `NN_<slug>.md` and the lead assigns the "next free"
number when scoping work. Two independent ways this races into a **duplicate
number**:

1. **Parallel agent-teams**: N teammates each write an evidence doc concurrently.
   If the lead pre-assigns 61–65 but they all read "next free = 61" (or the lead's
   own session-start `ls` was **truncated** and missed an already-committed
   higher number), several land on overlapping numbers. In the 2026-07-07 sweep
   the lead's `ls research/evidence/` preview cut off at file 51, so it never saw a
   pre-existing committed `#61` — the 5-doc plan (61–65) was silently off by one.
2. **Mid-session external commits**: another session/process commits a new
   `#NN` while the team is running, occupying a number the lead thought was free.

Left unfixed you get two files sharing a number (this repo had `#55`×2 and
`#58`×2) — `git log`/INDEX links still work, but cross-references (`#55`, `#58`)
become **ambiguous**: the same token means different docs in different files.

## Solution

Renumber to restore uniqueness, then repoint references:

1. **Keep the heavier-referenced (usually earlier) doc at its number; renumber the
   LIGHTER-referenced duplicate to a fresh trailing number** (`#67`, `#68` …).
   Fewer inbound cross-refs to fix = lower risk. (#55: kept `pop_decomposition`
   [8 inbound], moved `formal_informal`→67 [1 inbound]. #58: kept `land_and_charges`
   [18 inbound], moved `age_fertility`→68 [9 inbound].)
2. **`git mv`** the file (preserves history), fix its **H1 title** (`# NN —`, which
   is `"# NN "` with a space — NOT matched by a `#NN` sed) and any **self-reference**
   in its body.
3. **Disambiguate every inbound `#NN` by MEANING, not string.** A doc citing `#58`
   may mean either duplicate. Grep with context; e.g. "brain-drain / TFR / age
   structure" → the fertility doc, "residual / tasas / land" → the housing-cost
   doc. Only then repoint. A blind `sed s/#58/#68/g` across the repo corrupts the
   refs that legitimately point at the *kept* doc.
4. Fix INDEX rows (leading `| NN |` + the `](NN_slug.md)` link) and any
   `[[NN_slug]]` wiki-links (the slug carries the number too).
5. Verify: no duplicate file numbers, no duplicate INDEX leading numbers, every
   INDEX link resolves, and the *kept* doc's inbound refs are untouched. The INDEX
   is maintained in **append/creation order** (not strict numeric sort — it already
   has pre-existing 22↔23, 25↔29 disorder), so append the renumbered rows at the
   end rather than re-sorting the whole file.

## Prevention

- Before assigning numbers for a parallel team, get the true max with
  `git ls-files research/evidence/ | grep -oE '[0-9]+' | sort -n | tail -1` **and**
  `ls research/evidence/` in full (don't trust a truncated preview) — reconcile both.
- Give each teammate an **explicit distinct number** and tell them: if their
  assigned number is already taken when they go to write, **bump to the next free
  and report it** (teammates did this correctly — Task A self-bumped 61→62).
- Teammates must **not** edit `research/evidence/INDEX.md` (five-way write race); they hand
  the lead a proposed row and the lead consolidates + resolves numbering in one
  pass. See [[eph-cordoba-two-aglomerados-do-not-pool]] for the sibling rule that
  the same sweep's docs must keep 13/36 separate.
