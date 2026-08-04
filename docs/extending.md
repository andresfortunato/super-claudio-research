# Extending research-to-policy

This framework adds research-specific discipline to Claude Code via three composable pieces per convention. To add a new convention, follow the same pattern.

## The convention pattern

Every convention has up to three artifacts:

```
.claude/conventions/<name>.md         ← the protocol (read on demand)
.claude/hooks/check-<name>.sh         ← optional Stop hook (silent by default)
docs/<name>-mechanism.md              ← design rationale + tradeoffs
```

Plus a 2–4 line pointer in the project's `CLAUDE.md`.

## Step-by-step: adding a new convention

### 1. Write the convention file

`.claude/conventions/<name>.md` is the **prescriptive document** that Claude reads when applying the convention. It should answer:

- **What is this?** (one-paragraph summary)
- **When does it apply?** (concrete trigger conditions)
- **Where do artifacts live?** (filesystem layout + naming)
- **Required structure** (format spec, optionally a literal template)
- **What counts as a good vs bad instance** (avoid trivial compliance)
- **Discipline rules** (commit cadence, immutability, indexing)

Length target: 50–120 lines. Anything longer is probably two conventions.

### 2. (Optional) Write the Stop hook

If the convention needs *enforcement* — i.e. Claude reliably forgets to apply it without a nudge — add a hook script.

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

Standard sections:
- The problem this solves
- The pieces (convention + hook + pointer)
- Why these specific tripwires
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
- **Hooks are optional.** A convention without enforcement is fine if the user remembers to apply it. Add a hook only when forgetting is costly.
- **Pre-commit checks belong in pre-commit hooks, not Claude Code Stop hooks.** Stop hooks are for *agent-facing* discipline, not for human git hygiene.
- **Avoid hooks that block.** Almost every research-context discipline can be expressed as a soft nudge. Hard blocks turn the framework into a wall.

## Anti-patterns to avoid

- **Always-fire Stop hooks** (`pattern: .*` or unconditional script). They produce noise and pressure trivial compliance.
- **Conventions encoded in CLAUDE.md.** They load every session and can't be selectively applied.
- **Hooks that depend on Python, Node, or other runtimes** beyond bash + standard Unix. Portability suffers.
- **Hooks without self-tests.** A hook that silently misfires for weeks is worse than no hook.
- **Convention files that read like blog posts.** Keep them prescriptive — Claude needs to act on them, not read them for context.
