# research-to-policy

A Claude Code harness for applied empirical, data-analytical, and policy research — adapts scc's planning/handoff/verification discipline to the realities of policy research and applied development economics.

**v3 shipped 2026-09-09 — `package.json` is `0.3.0`.** `plan-r2p-v3` archived the same day: `archive/plan-r2p-v3.md`. **Current focus: nothing open.** No plan directory exists under `plan/`.

**What v3 is.** v2 established the `deliverable → claim → evidence → artifact → script → source` citation chain and checked almost none of it. v3 checks it, and **adds no migration** — no directory moves, no frontmatter rewrites, `r2p init --upgrade` plus one lint run is the whole adoption. `lint-research.sh` went from 7 checks to **18** and from **11.0s to 2.3s**; `.next-id` acquired the first tool that reads it (`r2p evidence new <slug>`); `/cite-check` walks the half of link 1 no grep can see; `/pipeline-check` re-runs an evidence doc's producing script and diffs against `## Measured`; the second installer has an integration test (`npm test`, 21 assertions). Change table and the four traps: **`docs/v2-to-v3.md`**. Design rationale, including why `save_fig(findings={...})` and a whole-pipeline harness were both rejected: **`docs/citation-chain-mechanism.md`**.

**⚠ The constitution changed twice in v3, both times *before* the code.** Principle 7 now grades additions on a **side-effect axis** (read-only / derived files / source files) as well as token cost, because `/pipeline-check` is the first r2p tier that writes anything — a proposal wanting to write *source* files does not inherit that amendment. And there is now a **tenth principle, "silence reads as a pass"**: a check that finds nothing must say so and name what it examined. It does not contradict principle 1 — ambient mechanisms stay quiet, invoked ones account for everything they examined.

**⚠ Verify before you trust a number here.** Three verifications, all green at `e396392`:

```
bash .claude/hooks/lint-research.sh              # PASS, 1 warning (plan/ only, self-clearing)
npm test                                         # 21 passed, 0 failed
python3 templates/migration/03_linkcheck.py --baseline HEAD   # 0 new breaks, 0 collapses
```

**⚠ Run a new lint invariant against a fresh `r2p init`, not just against a mature repo.** Eleven v3 invariants shipped before anyone did, and three of them failed a scaffold containing no research at all — two because the *check* was wrong (a `~/`-prefixed global path is not project-relative; a prose-qualified `docs/` pointer is deliberate), one because the shipped `claims.md` seed carried a placeholder claim. See `docs/field-notes/a-linter-must-be-run-against-a-fresh-install.md`. The rule is now in `docs/extending.md` step 2a: mature project, this repo, throwaway `init` — and the third is the only one whose correct answer is known in advance.

**⚠ The pilot repo is `~/research/cordoba`, and it is a *mixed* v1/v2 install.** Good donor for lint work, bad model of a clean v2 project: it still has `check-evidence.sh` wired and firing (v2 deleted it a year ago; `--upgrade` warns by name but never rewrites a project's `settings.json`) and `.claude/conventions/data-access.md` on disk. Its lint verdict is FAIL with 5 warnings, and that is real defects rather than a regression. **Re-measure before diffing** — a baseline against a live engagement decays in weeks.

**Next:** no plan is scoped yet. From `TODO.md`: **v4 is the plugin migration**, deliberately deferred out of v3 because it moves every file v3 touched; it lands cleanly now the convention surface has settled. Open and diagnosed but unscheduled: `--upgrade` could warn about a stale project `CLAUDE.md`; nothing checks this file for staleness; **the framework repo has no `.claude/settings.json` of its own**, so its own hooks are unwired here; and **`lint-research.sh` has no CI job in either repo** despite being designed for one, which is what would make its FAIL tier mean something. The Córdoba pilot-repo follow-ups in the case study's §7 are a separate track and belong in the pilot repo.

**⚠ This file was five weeks stale in early 2026-09** — it claimed `plan/` was empty while plan-r2p-v3 was mid-execution. It is the first thing a session reads. Update it when a phase lands, not when the plan does.
