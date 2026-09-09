# Extending research-to-policy

This framework adds research-specific discipline to Claude Code via three composable pieces per convention. To add a new convention, follow the same pattern.

## The convention pattern

Every convention has up to three artifacts:

```
.claude/conventions/<name>.md         ← the protocol (read on demand)
.claude/hooks/lint-research.sh        ← the check: one invariant, appended
.claude/skills/<name>/SKILL.md        ← optional: the half a grep cannot do
docs/<name>-mechanism.md              ← design rationale + tradeoffs
```

Plus a 2–4 line pointer in the project's `CLAUDE.md`.

**⚠ The middle slot used to be `.claude/hooks/check-<name>.sh`, and it should
not be your first choice.** v3 added five checks, two skills and no hook. The
reason is mechanical and is in step 2.

## Step-by-step: adding a new convention

### 1. Write the convention file

`.claude/conventions/<name>.md` is the **prescriptive document** that Claude reads when applying the convention. It should answer:

- **What is this?** (one-paragraph summary)
- **When does it apply?** (concrete trigger conditions)
- **Where do artifacts live?** (filesystem layout + naming)
- **Required structure** (format spec, optionally a literal template)
- **What counts as a good vs bad instance** (avoid trivial compliance)
- **Discipline rules** (commit cadence, immutability, indexing)

No length target — see principle 5's 2026-08-05 revision in `docs/audience-and-philosophy.md`. The useful signal behind the old one still holds, but test it on shape rather than lines: if a convention is long **because it is covering two triggers**, that is two conventions. Split on the trigger, not on a line count.

### 2. Write the check — a lint invariant first, a skill second, a hook almost never

If the convention needs *enforcement* — i.e. Claude reliably forgets to apply
it without a nudge — it needs a check. There are three shapes, and they are not
equally good.

#### 2a. A lint invariant — the default

Append it to `.claude/hooks/lint-research.sh`. This is what v3 used eleven
times, and it is the cheapest extension point in the framework: no install
footprint, no wiring, no per-turn cost, and it reaches every project on the next
`--upgrade` with no installer edit (both installers build their candidate list
by walking `.claude/hooks/`).

Two things to get right:

- **The admission test is that the defect actually happened.** Every invariant
  in the script is a real defect from a real project, not a designer's guess at
  what could go wrong. If you cannot name the instance, you are writing a
  preference.
- **Pick the tier by the rule, not by how bad the defect feels.** FAIL exits 1
  and is for a broken link or a duplicate id — mechanical, never a judgement
  call. WARN prints, counts and exits 0. **A check is FAIL only if a green run
  on a correct project is genuinely reachable today.** A linter whose failures a
  project cannot clear trains everyone to stop reading it; v2 deleted a hook for
  exactly that.

And print something when it finds nothing (principle 10): an invariant with an
empty population prints that it had one, rather than vanishing from the report.

#### 2b. A user-invoked skill — for the half a grep cannot do

Some checks are not decidable in bash: whether a paragraph asserts something
quantitative, whether a number still reproduces. Those go in a skill under
`.claude/skills/<name>/`, user-invoked, with a stated token budget.

**Ship both halves, not just this one.** If a link can be partly checked in
bash, that part goes in bash even when the skill would cover it too. A skill is
run by whoever remembers to type it; an invariant runs on every corpus, for
free, forever. Every v3 mechanism ships as an invariant *plus* a skill, and the
split falls in a consistent place: the invariant asks whether a stated reference
resolves, the skill asks whether a reference that should exist does.

If the skill would write anything, read principle 7's side-effect bounds in
`docs/audience-and-philosophy.md` before designing it. `/pipeline-check` is the
only tier that writes, the constitution was amended before it shipped, and a
proposal wanting to write *source* files does not inherit that amendment.

#### 2c. A Stop hook — read this before you write one

**A new hook is mirrored but not wired.** `r2p init --upgrade` never rewrites a
project's `.claude/settings.json` — correctly, since that file is the project's
own. So a hook you add lands on disk in every upgraded project and runs in none
of them. A check that runs in half the projects that have it is worse than one
that runs in all of them by being typed, because the half that silently does not
run looks identical to the half that passes.

The asymmetry runs the other way too, and is live right now: `check-evidence.sh`
was deleted by v2 and is still firing in the pilot repo, because nothing removed
its `settings.json` entry either. `--upgrade` warns about a removed hook by name
and says whether the project is still wired to run it; it does not auto-delete.

So: use a hook only for something that genuinely cannot be a script or a skill —
a state transition that must be noticed at a specific moment, like
`check-archival.sh` catching a `.completed` marker. If you do write one, the
contract below is not optional, and you must also document the `settings.json`
entry in the release notes, because every existing project has to add it by hand.

**Hook design contract** (read this before writing one):

- **Silent by default.** Exit 0 with no stdout when conditions don't trip.
- **Conditional, not always-fire.** Use `git status` or filesystem checks to detect actual evidence that the convention should apply.
- **Soft warn, not hard block.** Return `additionalContext` JSON. Avoid `"decision": "block"` unless the convention is genuinely critical.
- **No external dependencies.** Pure bash + `git` + standard Unix tools. The hook runs on every collaborator's machine.
- **Self-testable.** Include a "self-test" comment block showing how to invoke the hook manually for each scenario.

Template:
```bash
#!/usr/bin/env bash
# Stop hook: <one-line purpose>
# Silent unless: <condition A> AND <condition B>.
set -euo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

status=$(git status --porcelain -u 2>/dev/null || true)
[[ -z "$status" ]] && exit 0

# Tripwire 1: <evidence convention should apply>
trigger=$(printf '%s\n' "$status" | grep -E '<your-pattern>' || true)
[[ -z "$trigger" ]] && exit 0

# Tripwire 2: <convention has NOT been satisfied>
satisfied=$(printf '%s\n' "$status" | grep -E '<satisfaction-pattern>' || true)
[[ -n "$satisfied" ]] && exit 0

# Both tripwires fire → emit nudge
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "<short reminder pointing at .claude/conventions/<name>.md>"
  }
}
EOF
```

Wire it into `.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/check-archival.sh" },
          { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/check-<name>.sh" }
        ]
      }
    ]
  }
}
```

### 3. Write the design doc

`docs/<name>-mechanism.md` explains *why* the convention exists, the tradeoffs of the chosen approach, and where it can be tuned. This is documentation for future framework users (and AI assistants reading the framework). Length target: 80–150 lines.

**When a convention is merged away, its design doc goes with it.** v2 folded thirteen conventions into seven, and v3 deleted the eight design docs left describing conventions that no longer exist — they were accurate about v1 and misleading about the framework. The rationale that outlived the merge moves into the surviving convention file, where the reader who needs it is already looking. A design doc is not an archive; `archive/` is.

Standard sections:
- The problem this solves — with the instance it actually happened to
- The pieces (convention + check + pointer)
- Why this shape and not the obvious one — **the redesigns and why the rejected
  shape was rejected.** This is the section that pays: a contributor who does
  not know why a shape was rejected will propose it again, and v3 has two worked
  examples in `docs/citation-chain-mechanism.md`.
- What this does NOT do
- Tradeoffs accepted
- Extension points

### 4. Add the CLAUDE.md pointer

In the target project's `CLAUDE.md`:

```markdown
## <Convention Name>

<One-sentence summary>. Full protocol: `.claude/conventions/<name>.md`
(read on demand)<. A Stop hook nudges if X happens without Y.>
```

Keep it under 5 lines.

### 5. Update README + roadmap

- Add the new convention to the "Conventions installed" section in `README.md`
- Move it from the Roadmap list to "installed" status
- Update the install snippet if any new files need copying

## Rules of thumb

- **One convention, one concern.** "evidence-logging" is one. "handoff-format" is one. Don't bundle.
- **The convention file is for Claude; the design doc is for humans.** Don't blend them.
- **Checks are optional; hooks are close to forbidden.** A convention without enforcement is fine if the user remembers to apply it. When forgetting is costly, add a lint invariant. See step 2c for why a hook is the last resort rather than the default.
- **Codify what survives contact.** A prescribed format with 10% compliance is wrong, not disobeyed — v1's `learnings/index.yaml` reached 7 of 71 and was deleted, not enforced. If a rule cannot be checked mechanically, expect it to decay to whatever the last session felt like doing.
- **Express size rules as ranks or shares, never absolute counts.** A threshold like "over 30 decision records is over-recording" ages out of correctness the moment a project is larger than the one it was measured on.
- **Pre-commit checks belong in pre-commit hooks, not Claude Code Stop hooks.** Stop hooks are for *agent-facing* discipline, not for human git hygiene.
- **Avoid hooks that block.** Almost every research-context discipline can be expressed as a soft nudge. Hard blocks turn the framework into a wall.

## Anti-patterns to avoid

- **Always-fire Stop hooks** (`pattern: .*` or unconditional script). They produce noise and pressure trivial compliance.
- **A silent-by-default hook whose silence depends on a path.** It is one refactor away from firing every turn, in every installed project, with no way for the project to know why. This is not hypothetical — it is how `check-evidence.sh` died.
- **A shipped file pointing into `docs/`.** `r2p init` does not install `docs/`, so a convention, skill, hook or template citing `docs/<name>.md` resolves perfectly here and dangles in every project. The defect is invisible where it is authored. Point at a convention, which is installed, or name the framework repo explicitly.
- **Inferring a field whose wrongness is worse than its absence.** A heuristic that fills `artifacts:` would be right most of the time, and the residue would be a confident wrong binding that satisfies the check and points at the wrong finding. Hand-authored or absent.
- **Conventions encoded in CLAUDE.md.** They load every session and can't be selectively applied.
- **Hooks that depend on Python, Node, or other runtimes** beyond bash + standard Unix. Portability suffers.
- **Hooks without self-tests.** A hook that silently misfires for weeks is worse than no hook.
- **Convention files that read like blog posts.** Keep them prescriptive — Claude needs to act on them, not read them for context.
