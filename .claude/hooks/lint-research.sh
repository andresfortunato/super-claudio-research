#!/usr/bin/env bash
# Lint the r2p v2 research record. Run manually, from CI, or wire to a Stop hook.
#
# Checks the invariants that keep the corpus readable at scale — every one of
# them is a defect that actually happened on the pilot engagement:
#   1. INDEX.md headline > 120 chars   (the index reached 330 KB with a 10,410-char row)
#   2. duplicate evidence id           (three collisions from parallel fan-outs)
#   3. evidence doc missing frontmatter or a required key
#   4. id in a filename != id in its frontmatter
#   5. verdict word inside ## Measured (measurements must not carry verdicts)
#   6. claims.md staler than the newest evidence doc
#   7. method or source doc with no `triggers:` line (invisible to retrieval)
#
# Two verdict tiers, and the split is deliberate:
#   FAIL — a broken link or a duplicate id. Exit 1. Always mechanical, never a
#          judgement call, and never so numerous that a mid-adoption project
#          drowns in them.
#   WARN — printed, counted, exit 0. For checks whose finding needs an eye
#          before it means anything, or whose true-positive count on a real
#          project is large enough that failing the build would train everyone
#          to ignore the linter. That is not hypothetical: v2 deleted
#          `check-evidence.sh` for exactly that, and the pilot reached the same
#          conclusion independently — its `gate_retracciones.py:132-146` prints
#          rows and asks for an eye rather than shipping a test that misreports,
#          because a stopword check called 12 of 40 rows wrong.
#
# A check that cannot decide which tier it belongs in is FAIL only if a green
# run on a correct project is genuinely reachable today. Nothing is auto-fixed.

set -uo pipefail
shopt -s nullglob   # an empty evidence dir must not glob-literal into sed
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0

EV=research/evidence
fail=0
warns=0
note() { printf '  %s\n' "$1"; }
warn() { warns=$((warns+1)); printf '  WARN %s\n' "$1"; }

echo "== r2p v2 research lint =="

# --- 1. headline cap -------------------------------------------------------
if [[ -f "$EV/INDEX.md" ]]; then
  over=$(awk -F'|' '/^\| *[0-9]+ *\|/ {
            h=$3; gsub(/^ +| +$/,"",h);
            if (length(h) > 120) printf "    row %s: %d chars\n", $2, length(h) }' "$EV/INDEX.md")
  if [[ -n "$over" ]]; then
    note "FAIL headline cap (>120 chars):"; printf '%s\n' "$over"; fail=1
  else
    note "ok   headline cap"
  fi
fi

# --- 2. duplicate ids ------------------------------------------------------
dupes=$(ls "$EV"/[0-9]*_*.md 2>/dev/null | sed 's|.*/||' | grep -oE '^[0-9]+' \
        | sed 's/^0*//' | sort -n | uniq -d)
if [[ -n "$dupes" ]]; then
  note "FAIL duplicate evidence ids: $(tr '\n' ' ' <<< "$dupes")"; fail=1
else
  note "ok   evidence ids unique"
fi

# --- 3/4/5. per-doc checks -------------------------------------------------
missing_fm=0; bad_id=0; verdicts=""
for f in "$EV"/[0-9]*_*.md; do
  [[ -f "$f" ]] || continue
  if ! head -1 "$f" | grep -q '^---$'; then
    missing_fm=$((missing_fm+1)); continue
  fi
  fm=$(sed -n '2,/^---$/p' "$f")
  for key in id headline status unit period confidence; do
    grep -q "^${key}:" <<< "$fm" || { missing_fm=$((missing_fm+1)); break; }
  done
  fid=$(sed -n 's/^id:[[:space:]]*\([0-9]*\).*/\1/p' <<< "$fm" | head -1)
  nid=$(basename "$f" | grep -oE '^[0-9]+' | sed 's/^0*//')
  [[ "$fid" == "$nid" ]] || { bad_id=$((bad_id+1)); note "     id mismatch: $f (fm=$fid file=$nid)"; }
  # verdict words inside ## Measured only
  meas=$(awk '/^## Measured/{f=1;next} /^## /{f=0} f' "$f")
  if [[ -n "$meas" ]] && grep -qiE '\b(confirms?|confirmed|refut|rejected|verdict|proves)\b' <<< "$meas"; then
    verdicts="${verdicts}     $f"$'\n'
  fi
done
(( missing_fm == 0 )) && note "ok   frontmatter complete" \
  || { note "FAIL $missing_fm evidence docs missing frontmatter or a required key"; fail=1; }
(( bad_id == 0 )) && note "ok   filename id matches frontmatter" || fail=1
if [[ -n "$verdicts" ]]; then
  note "FAIL verdict words inside ## Measured:"; printf '%s' "$verdicts"; fail=1
else
  note "ok   no verdicts in ## Measured"
fi

# --- 6. claims staleness ---------------------------------------------------
if [[ -f research/claims.md ]]; then
  reviewed=$(grep -m1 -oE '\*\*Last reviewed:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}' research/claims.md \
             | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  newest=$(for f in "$EV"/[0-9]*_*.md; do
             [[ -f "$f" ]] || continue
             sed -n 's/^date:[[:space:]]*\([0-9-]\{10\}\).*/\1/p' "$f" | head -1
           done | sort -r | head -1)
  if [[ -n "$reviewed" && -n "$newest" && "$newest" > "$reviewed" ]]; then
    warn "claims.md last reviewed $reviewed but newest evidence is $newest"
  else
    note "ok   claims.md current (reviewed ${reviewed:-?})"
  fi
else
  n=$(ls "$EV"/[0-9]*_*.md 2>/dev/null | wc -l)
  (( n > 40 )) && { note "FAIL $n evidence docs and no research/claims.md (mandatory past 40)"; fail=1; }
fi

# --- 7. retrieval triggers -------------------------------------------------
notrig=0
for f in research/methods/*.md research/sources/*.md; do
  [[ -f "$f" ]] || continue
  case "$(basename "$f")" in INDEX.md|README.md) continue ;; esac
  head -14 "$f" | grep -q '^triggers:' || { notrig=$((notrig+1)); }
done
(( notrig == 0 )) && note "ok   every method/source doc has triggers" \
  || warn "$notrig method/source docs have no triggers: line (invisible to retrieval)"

echo
if (( fail )); then
  printf 'FAIL'
else
  printf 'PASS'
fi
(( warns )) && printf ' — %d warning(s)' "$warns"
printf '\n'
exit $fail
