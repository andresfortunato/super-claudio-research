#!/usr/bin/env bash
# Stop hook: two tripwires on a single Stop event.
#
# Tripwire 1 — Plan archival (BLOCKING).
#   When any plan/plan-*/.completed marker is present and the plan's
#   .archival-triggered sentinel is absent: write the sentinel, emit
#   decision:block + reason instructing Claude to launch the archivist
#   subagent, exit 2. The sentinel prevents re-block loops on subsequent
#   Stop events; both markers are removed when the archivist deletes
#   the plan directory. Bash-port of scc hooks/stop.js. See
#   .claude/conventions/plan-structure.md "Completion and archival" and
#   docs/plan-archival-mechanism.md.
#
# Tripwire 2 — Evidence logging (NON-BLOCKING nudge).
#   Nudge Claude to write evidence/NN_*.md when a session produced new
#   analysis artifacts (charts, panels, methods notes) without a new
#   evidence doc to record what was learned. Only emits when:
#     1. There ARE uncommitted analysis artifacts
#        (output/[<theme>/]0[0-9]*_*.{png,csv,meta.json} or methods/*.md), AND
#     2. There are NO uncommitted evidence/[<theme>/]NN_*.md changes.
#   Both flat (output/01_*, evidence/01_*.md) and theme-parallel
#   (output/<theme>/01_*, evidence/<theme>/01_*.md) layouts satisfy
#   the tripwire. See .claude/conventions/evidence-logging.md and
#   docs/theme-parallel-mechanism.md.
#
# SILENT by default. Tripwire 1 fires before tripwire 2 when both apply
# (archival is the higher-signal event; the evidence nudge can wait for
# the next Stop after archival completes).

set -euo pipefail

# CLAUDE_PROJECT_DIR is set by Claude Code; fall back to current dir if missing.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

# === Tripwire 1: plan archival ===
# Iterate plan/plan-*/.completed markers. For the first plan whose
# .archival-triggered sentinel is missing, write the sentinel and
# emit a block. Subsequent Stop events on the same plan are silent
# (sentinel honored) until the archivist deletes the directory.
if [[ -d plan ]]; then
  for completed_marker in plan/plan-*/.completed; do
    [[ -f "$completed_marker" ]] || continue
    plan_dir="$(dirname "$completed_marker")"
    plan_name="$(basename "$plan_dir")"
    sentinel="$plan_dir/.archival-triggered"
    [[ -f "$sentinel" ]] && continue

    # Write sentinel first — protects against re-block loops if the
    # archivist invocation is interrupted before plan-dir cleanup lands.
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$sentinel"

    # Emit decision:block + reason. Claude Code reads the JSON from
    # stdout, blocks the Stop, and surfaces `reason` to the model.
    cat <<EOF
{
  "decision": "block",
  "reason": "Plan \"$plan_name\" is marked complete (.completed marker found). Before stopping, launch the archivist subagent (defined in ~/.claude/agents/archivist.md) to synthesize archive/$plan_name.md, update archive/index.md, clean up plan/$plan_name/, and update CLAUDE.md if architecture changed. After archival completes you can stop. If the plan touched many source files, recommend the user run /research-cleanup afterward — project-wide cleanup is outside the archivist's scope."
}
EOF
    exit 2
  done
fi

# === Tripwire 2: evidence logging ===
# Skip if not a git repo (no way to detect "what changed this session").
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Look at uncommitted changes (staged + unstaged + untracked) in scope.
status=$(git status --porcelain -u 2>/dev/null || true)
[[ -z "$status" ]] && exit 0

# Tripwires for "analysis happened":
#   - notebook-numbered output artifacts: output/01_, 06c_, 06b_ etc.
#     (also accepts output/<theme>/01_* for theme-parallel layouts)
#   - methods notes (methodology docs)
#   - panel CSVs in output/ matching *_panel.csv or analytical patterns
analysis_hit=$(printf '%s\n' "$status" | grep -E \
  '^([ AM?]+|[?]+) (output/([^/]+/)?0[0-9][a-z]?_.*\.(png|csv|meta\.json)|methods/[^/]+/.*\.md|methods/[^/]+\.md)$' \
  || true)

# If no analysis artifacts, exit silently.
[[ -z "$analysis_hit" ]] && exit 0

# If new/modified evidence/*.md exists, the user is already capturing — silent.
# Accepts both flat (evidence/NN_*.md) and theme-parallel (evidence/<theme>/NN_*.md).
evidence_hit=$(printf '%s\n' "$status" | grep -E \
  '^([ AM?]+|[?]+) evidence/([^/]+/)?[0-9]+_.*\.md$' \
  || true)

[[ -n "$evidence_hit" ]] && exit 0

# Conditions met: emit additionalContext nudge.
# Show first ~5 analysis files so Claude can see the evidence.
top_artifacts=$(printf '%s\n' "$analysis_hit" | head -5 | sed 's/^/    /')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "Evidence checkpoint — uncommitted analysis artifacts detected without a corresponding evidence doc.\n\nAnalysis artifacts (sample):\n${top_artifacts//$'\n'/\\n}\n\nNo new evidence/*.md found in git status. Before stopping:\n  1. Read .claude/conventions/evidence-logging.md\n  2. Find the next free NN with: ls evidence/ | sort\n  3. Write evidence/NN_<slug>.md with 3–8 evidence-based findings\n  4. Append a row to evidence/INDEX.md\n  5. Commit the analysis artifacts and the evidence doc together\n\nIf this was research/exploration with no real new evidence, you can ignore this nudge and proceed."
  }
}
EOF
