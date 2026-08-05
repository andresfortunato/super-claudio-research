# Evidence-number collisions across parallel worktrees/branches

**Encoded in:** `.claude/conventions/evidence.md` § Where evidence lives — the `research/evidence/.next-id` counter, lead-allocated, with parallel workers requesting a block up front. Deriving the next id from `ls` is explicitly forbidden there. Duplicate of [[evidence-number-collisions-parallel-teams]]; both notes stamp this one target.

**Gotcha.** `research/evidence/INDEX.md`'s rule is "numbering is sequential — append, never
renumber," but that assumes a single linear history. This project runs **parallel
worktrees / branches** (e.g. `worktree-urban-industries-demand`, the agent-teams skill).
Two branches that both pick "the next number" off the same base **claim the same evidence
number independently**. Whoever pushes/merges first wins; the second push is rejected and
the INDEX conflicts.

**What happened (2026-07-22).** While building the FUA net-migration re-cut I wrote it as
`research/evidence/115_...`. In parallel, a worktree wrote a *different* finding (urban-industry
demand) as `research/evidence/115_...` and merged to `origin` first. My `git push` was rejected;
`git pull --rebase` produced a content conflict on the last INDEX row (both `| 115 |`).

**Fix (cheap, mechanical).** On an INDEX-row conflict caused by a duplicate number:
1. Keep BOTH rows; renumber yours to `max(remote) + 1` (here 115→**116**).
2. `git mv research/evidence/115_<slug>.md research/evidence/116_<slug>.md`.
3. Update the doc's own H1 (`# 115 —` → `# 116 —`) and **every cross-reference**: the INDEX
   link `](116_<slug>.md)`, other evidence docs that cite it, decision records, the handoff.
   `grep -rn "#115\|115_<slug>" evidence decisions plan` to catch them all.
4. `git add`, `git rebase --continue`, then `git commit --amend` to fix the number in the
   commit message too, then push.

**Prevention.** When starting evidence work in a branch/worktree, treat the next-number as
*provisional* until pushed. If you know parallel work is in flight, either coordinate the
number up front or expect to renumber to max+1 at push time. The renumber is safe *because*
the doc is new — no downstream artifact cites it yet within the same session.
