#!/usr/bin/env bash
# Stop hook: plan-archival tripwire (BLOCKING).
#
# When any plan/plan-*/.completed marker is present and that plan's
# .archival-triggered sentinel is absent: write the sentinel, emit
# decision:block + reason instructing Claude to launch the archivist
# subagent, exit 2. The sentinel prevents re-block loops on subsequent
# Stop events; both markers go away when the archivist deletes the plan
# directory.
#
# Was Tripwire 1 of check-evidence.sh. That hook's second tripwire — a
# nudge to write an evidence doc when analysis artifacts were uncommitted —
# was removed in v2: its regexes matched the v1 layout (`evidence/NN_*.md`,
# `methods/*.md`), so on a v2 project the "did you already write one?"
# check could never match and the nudge fired unconditionally, pointing at
# `conventions/evidence-logging.md`, which v2 deleted. Its v2 successor is
# .claude/hooks/lint-research.sh, which checks the real invariants and is
# run manually or from CI rather than on every Stop.
#
# See .claude/conventions/plan-lifecycle.md and docs/plan-archival-mechanism.md.
# SILENT unless a completed-but-unarchived plan exists.

set -euo pipefail

# CLAUDE_PROJECT_DIR is set by Claude Code; fall back to current dir if missing.
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

[[ -d plan ]] || exit 0

# v2 scaffolds plan/archive/; v1 projects put it at the repo root. Report
# whichever this project actually has so the reason text names a real path.
if [[ -d plan/archive ]]; then
  archive_dir="plan/archive"
else
  archive_dir="archive"
fi

for completed_marker in plan/plan-*/.completed; do
  [[ -f "$completed_marker" ]] || continue
  plan_dir="$(dirname "$completed_marker")"
  plan_name="$(basename "$plan_dir")"
  sentinel="$plan_dir/.archival-triggered"
  [[ -f "$sentinel" ]] && continue

  # Write sentinel first — protects against re-block loops if the archivist
  # invocation is interrupted before plan-dir cleanup lands.
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$sentinel"

  # Claude Code reads this JSON from stdout, blocks the Stop, and surfaces
  # `reason` to the model.
  cat <<EOF
{
  "decision": "block",
  "reason": "Plan \"$plan_name\" is marked complete (.completed marker found). Before stopping, launch the archivist subagent (defined in ~/.claude/agents/archivist.md) to synthesize $archive_dir/$plan_name.md, update $archive_dir/index.md, clean up plan/$plan_name/, and update CLAUDE.md if architecture changed. After archival completes you can stop. If the plan touched many source files, recommend the user run /research-cleanup afterward — project-wide cleanup is outside the archivist's scope."
}
EOF
  exit 2
done

exit 0
