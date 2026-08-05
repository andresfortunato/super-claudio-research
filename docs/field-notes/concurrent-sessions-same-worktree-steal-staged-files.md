# Two agents in the SAME worktree share one git index — `git add` then `git commit` lets the other session's commit swallow your staged files under its message; commit by pathspec instead

**Encoded in:** `.claude/conventions/provenance.md` § Half 2 → *Commit by pathspec, never stage-then-commit*

## What

Multiple Claude sessions can be working in the **same** worktree at the same time (not
just in different worktrees). The git **index is per-worktree, not per-session**, so the
sequence

```bash
git add fileA fileB fileC     # session 1 stages
                              # ...session 2 runs `git commit` here...
git commit -F - <<'EOF'       # session 1's commit finds NOTHING staged
```

hands session 1's files to **session 2's commit**, under session 2's message. Session 1
then sees `no changes added to commit`, a `git log -1` that shows a stranger's commit, and
a `git status` that looks like its work vanished.

Observed 2026-07-28 on `cordoba-growth-narrative`. Session 1 staged three files (a 184-line
revision of `research/evidence/125_...md`, an `research/evidence/INDEX.md` row, a learning). Session 2 — an
unrelated agri-potential work-stream — committed at that instant. Result:

```
4592c07 "phase 0: file the quantity-outcome and two-comparator-set calls before any code"
 decisions/2026-07-28_city-growth-outcome-variable.md      | 116 ++++   <- session 2's
 decisions/2026-07-28_comparator-set-construction.md       | 151 ++++   <- session 2's
 research/evidence/125_industry_share_vs_labour_market_size.md      | 184 ++--   <- SESSION 1's
 research/evidence/INDEX.md                                         |   2 +-    <- SESSION 1's
 learnings/eph-pp04b-leading-zero-stripped-sections-a-b.md |  29 ++    <- SESSION 1's
```

**Nothing is lost** — the content is committed and pushable. What is lost is
**provenance**: `git log -- research/evidence/125_...md` now resolves to a message about FAOSTAT
and comparator sets, which is exactly what this project's
`.claude/conventions/provenance.md` exists to prevent (`git log -- output/<file>`
must resolve to the script and rationale that produced it).

## Prevention — commit by pathspec, never stage-then-commit

`git commit <paths>` commits **only those paths**, reading them from the working tree and
ignoring whatever else is in the index. It is atomic against a concurrent commit:

```bash
# SAFE — one command, explicit paths, index-independent
git commit -F - -- research/evidence/125_foo.md research/evidence/INDEX.md learnings/bar.md <<'EOF'
message
EOF

# UNSAFE — two commands with a race window, and the index is shared
git add research/evidence/125_foo.md research/evidence/INDEX.md
git commit -F - <<'EOF'
```

Caveats on the safe form: it does not work for a *first* commit of a brand-new file in
some git versions unless the path is added first — for new files use
`git add <paths> && git commit -F - -- <paths>`, which still scopes the commit to those
paths even if the index has been polluted. And it bypasses any staged *partial* hunks, so
don't use it if you deliberately staged a subset of a file's changes.

## Detection

If `git commit` reports **`no changes added to commit`** right after you staged files,
do **not** re-stage and retry blindly — first check whether another session took them:

```bash
git log --oneline -3                       # is HEAD a commit you don't recognise?
git reflog -8                              # are there interleaved commits from another stream?
git show --stat HEAD                       # does HEAD contain YOUR files?
git diff --stat HEAD -- <your paths>       # empty => your content IS committed, just mislabelled
```

`git status` showing your files as neither modified nor untracked, while the content is
present on disk, means **committed by someone else** — not lost.

## Do NOT fix it by rewriting history

The mixed commit will already be pushed, and the other session is still working on the
same branch. `git reset`, `git rebase -i` or a force-push would clobber a live
collaborator. Leave the history; record the misattribution in the evidence doc or a
follow-up commit message, and move on. Provenance noise is much cheaper than destroying
another agent's work.

## Related

- `[[evidence-search-data-layer-wiki-branches]]` — the *read*-side counterpart: findings
  live across worktrees and non-checked-out branches, so "no evidence doc exists" ≠ "no
  evidence exists". This learning is the *write*-side hazard of the same topology.
- `[[evidence-number-collision-parallel-worktrees]]` — the numbering hazard when parallel
  streams both allocate `research/evidence/NN_`. A concurrent session in the same worktree can
  collide on the *same* number with no merge conflict to warn you: check
  `ls research/evidence/ | grep -oE '^[0-9]+' | sort -n | tail -1` immediately before writing, not
  minutes earlier.
- `.claude/conventions/provenance.md` — the convention this hazard breaks.
