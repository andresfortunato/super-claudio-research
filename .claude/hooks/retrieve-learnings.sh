#!/usr/bin/env bash
# UserPromptSubmit hook (r2p v2): surface relevant methods and source docs by
# matching their frontmatter `triggers:` against the user's prompt.
#
# v1 read a separate learnings/index.yaml, which made every learning a two-file
# write — the .md plus an index row — and a learning whose row was forgotten was
# invisible to retrieval. v2 reads the trigger line out of the document itself,
# so a doc can no longer be silently unreachable.
#
# SILENT by default. Emits additionalContext only when some doc has ≥2 trigger
# keywords matching prompt words. Up to 3 docs, highest match count first, and
# each is truncated so a 50 KB merged topic file cannot flood the context.
#
# See .claude/conventions/methods.md (Retrieval) and sources.md.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)
[[ -z "$prompt" ]] && exit 0

prompt_words=$(printf '%s' "$prompt" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -cs 'a-z0-9_' '\n' \
  | sort -u)
[[ -z "$prompt_words" ]] && exit 0

matches_file=$(mktemp)
trap 'rm -f "$matches_file"' EXIT

# Scan the first 12 lines of each doc — the frontmatter block — for `triggers:`.
shopt -s nullglob
for path in research/methods/*.md research/sources/*.md; do
  case "$(basename "$path")" in INDEX.md) continue ;; esac
  triggers=$(head -12 "$path" \
    | sed -n 's/^triggers:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p;s/^triggers:[[:space:]]*'"'"'\(.*\)'"'"'[[:space:]]*$/\1/p' \
    | head -1)
  [[ -z "$triggers" ]] && continue
  hits=0
  for t in $(printf '%s' "$triggers" | tr '[:upper:]' '[:lower:]'); do
    [[ -z "$t" ]] && continue
    if grep -qFx "$t" <<< "$prompt_words"; then
      hits=$((hits + 1))
    fi
  done
  if [[ $hits -ge 2 ]]; then
    printf '%d\t%s\n' "$hits" "$path" >> "$matches_file"
  fi
done

[[ -s "$matches_file" ]] || exit 0

top=$(sort -t$'\t' -k1,1 -nr "$matches_file" | head -3 | cut -f2)

# Per-doc line cap. v2 topic files merge several v1 records and can run past
# 40 KB; injecting three of those whole would cost more context than the
# retrieval saves. Head the doc (frontmatter + Rule) and point at the rest.
MAX_LINES=120

combined=""
sep=""
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  [[ -f "$path" ]] || continue
  total=$(wc -l < "$path")
  content=$(head -"$MAX_LINES" "$path")
  if (( total > MAX_LINES )); then
    content="${content}"$'\n\n'"*[truncated at ${MAX_LINES} of ${total} lines — read \`${path}\` for Traps, Diagnostic counts and Scope.]*"
  fi
  combined="${combined}${sep}${content}"
  sep=$'\n\n---\n\n'
done <<< "$top"

[[ -z "$combined" ]] && exit 0

body=$(printf '## Relevant methods and sources\n\n%s' "$combined")

jq -n --arg ctx "$body" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'
