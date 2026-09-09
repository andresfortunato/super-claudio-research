#!/usr/bin/env bash
# Lint the r2p v2 research record. Run manually, from CI, or wire to a Stop hook.
#
# Checks the invariants that keep the corpus readable at scale — every one of
# them is a defect that actually happened on the pilot engagement:
#   1. INDEX.md headline > 120 chars   (the index reached 330 KB with a 10,410-char row)
#   2. duplicate evidence id           (five collisions; three distinct vectors)
#   3. evidence doc missing frontmatter or a required key
#   4. id in a filename != id in its frontmatter
#   5. verdict word inside ## Measured (measurements must not carry verdicts)
#   6. claims.md staler than the newest evidence doc
#   7. method or source doc with no `triggers:` line (invisible to retrieval)
#   8. claim `Rests on:` naming an evidence id with no file  (link claim->evidence)
#   9. artifact used in deliverables/ that no evidence doc mentions at all
#  9b. artifact an evidence doc discusses but does not bind via `artifacts:`
#  10. evidence doc older than the artifacts it binds     (a re-render it never saw)
#  11. `.next-id` not ahead of the highest id on disk     (the next allocation collides)
#  12. `artifacts:` naming a path that does not exist    (a typo that satisfies inv 9)
#  13. `[C<n>]` in a deliverable matching no claim heading (link deliverable->claim)
#  14. bare `#nn` in a deliverable naming no live evidence id, banners honoured
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
#
# A tier chosen on a measured count is only as good as the count. Invariant 13
# was written WARN on a volume argument that belonged to invariant 14, and its
# own population turned out to be zero — so re-measure before citing a number
# back at a tier decision, including one you made yourself last session.

set -uo pipefail
shopt -s nullglob   # an empty evidence dir must not glob-literal into sed
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0

EV=research/evidence
fail=0
warns=0
note() { printf '  %s\n' "$1"; }
warn() { warns=$((warns+1)); printf '  WARN %s\n' "$1"; }

# Every evidence doc, recursively. The glob this replaces — "$EV"/[0-9]*_*.md —
# stopped at the top level, so a `research/evidence/<topic>/` subdirectory was
# never opened and the linter returned a confident PASS over it. On the pilot
# that hid three docs whose ids 20/21/22 collided with three root-level docs,
# and none of the three appeared in INDEX.md. A second numbering namespace is
# the one collision vector `.next-id` cannot defend against — nothing was
# allocated twice, the counter was simply never consulted — so the recursive
# walk *is* the defence. Subfolders are permitted; unique NN project-wide is not
# negotiable, because it is the key claims.md and every deliverable resolve on.
#
# Read once into an array, not once per invariant. Measured on the pilot before
# this change: 11.0s wall, of which the per-doc block below was 4.3s. `find`
# re-ran on each of ten calls, and `ev_id` spawned three processes per document
# inside four separate loops — roughly 3,400 processes to build a list of
# numbers that cannot change during a run. A linter slow enough that people stop
# running it is an adoption risk by the same reasoning that produced the WARN
# tier, and the invariants Phase 6 adds would have multiplied that cost rather
# than paying it once.
EV_DOCS=()
while IFS= read -r _f; do EV_DOCS+=( "$_f" ); done \
  < <(find "$EV" -type f -name '[0-9]*_*.md' 2>/dev/null | LC_ALL=C sort)
ev_docs() { (( ${#EV_DOCS[@]} )) && printf '%s\n' "${EV_DOCS[@]}"; return 0; }

# The id a filename claims, leading zeros stripped, in pure bash. `basename |
# grep | sed` was three processes and this is called from report loops.
ev_id() {
  local b=${1##*/} d
  d=${b%%[!0-9]*}
  while [[ ${d:0:1} == 0 ]]; do d=${d:1}; done   # as `sed 's/^0*//'` did
  [[ -n "$d" ]] && printf '%s\n' "$d"
  return 0
}

# Parallel to EV_DOCS. Invariants 2, 8, 11 and 14 each need the same id list and
# each used to rebuild it from scratch.
EV_IDNUM=()
for _f in "${EV_DOCS[@]+"${EV_DOCS[@]}"}"; do
  _b=${_f##*/}; _d=${_b%%[!0-9]*}
  while [[ ${_d:0:1} == 0 ]]; do _d=${_d:1}; done
  EV_IDNUM+=( "$_d" )
done
ev_ids_all() { (( ${#EV_IDNUM[@]} )) && printf '%s\n' "${EV_IDNUM[@]}"; return 0; }

# `<!-- … -->` stripping now lives inside the corpus scan below, as awk's
# decomment(). It is not a general-purpose helper: its only caller was invariant
# 5, and keeping a shell version alive next to the awk one would be two
# implementations of the same rule.

# `artifacts:` is a YAML *block* list, never inline (evidence.md). Reads one
# doc's paths, one per line, by its index in EV_DOCS. The key is OPTIONAL and
# absent is the common legitimate state — a doc that measures something without
# drawing it. Absence means "not stated", never "no charts exist", so nothing
# here may treat it as a finding.
#
# Parsing moved into the corpus scan below. Invariants 9, 10 and 12 each called
# this once per document, so on the pilot it was 855 awk processes reading the
# same 285 files three times over.
ev_artifacts_at() { printf '%s' "${EV_ART_OF[$1]-}"; }

# A path as a deliverable writes it -> as the repo names it. `../../output/x.png`
# from deliverables/memos/ and `output/x.png` from the root are the same artifact.
norm_path() { sed -e 's|^/*||' -e 's|^\(\.\./\)*||' -e 's|^\./||'; }

# Print a list, bounded, and ALWAYS say what was dropped. A silent cap reads as
# "mostly fine" when it is not; `05_methods_merge.py:304` truncates to 12 with no
# notice and that is the habit this exists to avoid importing. Override with
# LINT_MAX=0 for the full list.
LINT_MAX=${LINT_MAX:-20}
show() {
  local n=0 total
  total=$(grep -c . <<< "$1")
  while IFS= read -r l; do
    [[ -n "$l" ]] || continue
    if (( LINT_MAX > 0 && n >= LINT_MAX )); then
      note "     … and $((total - n)) more not shown (LINT_MAX=$LINT_MAX; set LINT_MAX=0 for all)"
      break
    fi
    note "     $l"; n=$((n+1))
  done <<< "$1"
}

# Every artifact-shaped path a deliverable points at, repo-relative and unique.
# Anchored on `output/` because that is where the layout puts artifacts and what
# provenance.md's `Run:`/`Out:` records — it keeps `data/raw/*.csv` and a memo's
# own companion PDF out of a check about charts.
# Ids that USED to be live and were renumbered away. citation-discipline.md's
# recovery rule (T2) says the moved doc carries
# `> ⚠ **Renumbered 131 → 150 on <date>.**` under its frontmatter and `(was #131)`
# on its headline, precisely so a stale citation stays resolvable. So `#131`
# matching no file is not automatically broken — it is broken only if no banner
# claims it. Three live examples on the pilot: 119→149, 131→150, 139→151.
renumbered_ids() {
  grep -rhoE 'Renumbered[[:space:]]+[0-9]+[[:space:]]*(→|->)' "$EV" 2>/dev/null \
    | grep -oE '[0-9]+'
  grep -rhoE '\(was #[0-9]+\)' "$EV" 2>/dev/null | grep -oE '[0-9]+'
}

# Every markdown deliverable. `.R`/`.py` render scripts living under
# deliverables/ are excluded on purpose: they are full of hex colours, and a
# deliverable is a document.
deliverable_docs() { find deliverables -type f -name '*.md' -print0 2>/dev/null; }

deliverable_artifacts() {
  [[ -d deliverables ]] || return 0
  find deliverables -type f -name '*.md' -print0 2>/dev/null \
    | xargs -0 -r grep -ohE '(\.\./)*output/[A-Za-z0-9._/-]+\.(png|svg|jpg|jpeg|pdf|csv|tsv|xlsx)' 2>/dev/null \
    | norm_path | LC_ALL=C sort -u
}

# --- the corpus scan -------------------------------------------------------
# One pass over every evidence doc, feeding invariants 3, 4, 5, 6 and 16. Each
# of those used to re-read the corpus itself: a `head`, six `grep`s, two `sed`s,
# an `awk` and a `grep` per document. awk takes the path list on stdin and opens
# each file itself — not as argv, which would put a corpus-sized ceiling on
# ARG_MAX, and not one awk per file, which is the cost being removed.
#
# Records emitted, tab-separated, tag first:
#   FM_MISSING   <file>                      no `---` on line 1, or a required key absent
#   ID_MISMATCH  <file> <fm-id> <name-id>    frontmatter id differs from the filename's
#   DATE         <idx> <date>                first `date:` in the file  (invariants 6, 10)
#   STATUS       <idx> <status>              frontmatter status         (invariant 16)
#   ART          <idx> <path>                one `artifacts:` entry     (invariants 9, 10, 12)
#   MEAS         <idx> <line>                a `## Measured` line, comments stripped
#
# `MEAS` and `STATUS` carry an index into EV_DOCS rather than a path, because the
# verdict-word grep below runs over whole records and a path can contain the
# words it looks for. Porting `\b` into awk was the alternative and it is not
# safe here: mawk has no `\y` and is byte-oriented, so an accented letter stops
# being a word character and `confirmó` would start matching `confirm`. The
# check's meaning must not change inside a performance commit.
#
# An empty evidence doc reaches `n == 0` and is reported as missing frontmatter,
# which is what `head -1 | grep -q '^---$'` did. That case is why awk reads the
# path list rather than being handed the files as arguments: an empty file
# produces no records at all, so FNR==1 never fires for it and every index after
# it would have shifted by one.
EV_SCAN=$(ev_docs | awk -v need="id headline status unit period confidence" '
function decomment(line) {
  # Verbatim port of the shell strip_html_comments this replaced. Authoring
  # guidance is not a measurement, and the shipped evidence template spells out
  # the verdict words under `## Measured` inside a comment — so a doc created
  # from the template failed invariant 5 on creation.
  if (inc) { p = index(line, "-->"); if (p == 0) return ""; line = substr(line, p + 3); inc = 0 }
  while ((sopen = index(line, "<!--")) > 0) {
    pre = substr(line, 1, sopen - 1); rest = substr(line, sopen + 4)
    e = index(rest, "-->")
    if (e == 0) { line = pre; inc = 1; break }
    line = pre substr(rest, e + 3)
  }
  return line
}
BEGIN { nneed = split(need, needk, " "); idx = -1 }
{
  path = $0; idx++
  b = path; sub(/^.*\//, "", b)
  match(b, /^[0-9]+/); nid = substr(b, RSTART, RLENGTH); sub(/^0+/, "", nid)
  split("", seen)
  nofm = 0; infm = 0; fmid = ""; gotid = 0; st = ""; gotst = 0
  dt = ""; gotdt = 0; meas = 0; inc = 0; inart = 0; n = 0

  while ((getline line < path) > 0) {
    n++
    if (n == 1) { nofm = (line != "---"); infm = !nofm; continue }
    if (infm) {
      if (line == "---") { infm = 0 }
      else {
        if (match(line, /^[A-Za-z_][A-Za-z0-9_]*:/)) seen[substr(line, 1, RLENGTH - 1)] = 1
        if (!gotid && substr(line, 1, 3) == "id:") {
          v = substr(line, 4); sub(/^[ \t]*/, "", v)
          match(v, /^[0-9]*/); fmid = substr(v, 1, RLENGTH); gotid = 1
        }
        if (!gotst && substr(line, 1, 7) == "status:") {
          v = substr(line, 8); sub(/^[ \t]*/, "", v)
          sub(/[ \t]*#.*$/, "", v); sub(/[ \t]+$/, "", v); st = v; gotst = 1
        }
        if (substr(line, 1, 10) == "artifacts:") inart = 1
        else if (inart) {
          if (match(line, /^[ \t]+-[ \t]*/)) {
            v = substr(line, RLENGTH + 1)
            sub(/[ \t]*#.*$/, "", v)                 # trailing YAML comment
            gsub(/^["'"'"']|["'"'"']$/, "", v)
            if (length(v)) print "ART\t" idx "\t" v
          } else inart = 0
        }
      }
    }
    # `date:` is read from the whole file, not only the frontmatter, because
    # that is where invariant 6 read it from and 45 pilot docs predate
    # frontmatter entirely.
    if (!gotdt && substr(line, 1, 5) == "date:") {
      v = substr(line, 6); sub(/^[ \t]*/, "", v)
      if (length(v) >= 10) { d = substr(v, 1, 10); if (d ~ /^[0-9-]+$/) { dt = d; gotdt = 1 } }
    }
    if (nofm) continue
    if (line ~ /^## Measured/) { meas = 1; inc = 0; continue }
    if (line ~ /^## /) { meas = 0 }
    if (meas) { c = decomment(line); if (length(c)) print "MEAS\t" idx "\t" c }
  }
  close(path)
  if (n == 0) nofm = 1

  if (nofm) print "FM_MISSING\t" path
  else {
    miss = 0
    for (k = 1; k <= nneed; k++) if (!(needk[k] in seen)) { miss = 1; break }
    if (miss) print "FM_MISSING\t" path
    if (fmid != nid) print "ID_MISMATCH\t" path "\t" (fmid == "" ? "none" : fmid) "\t" nid
    if (st != "") print "STATUS\t" idx "\t" st
  }
  if (dt != "") print "DATE\t" idx "\t" dt
}')
scan_rows() { [[ -n "$EV_SCAN" ]] && grep "^$1"$'\t' <<< "$EV_SCAN"; return 0; }

# Two per-document lookups, both indexed by position in EV_DOCS and both built
# with no subprocess per document. Sparse on purpose: a doc with no `artifacts:`
# and a doc with no `date:` are the common case, and `${arr[i]-}` reads empty.
EV_ART_OF=(); EV_DATE_OF=()
while IFS=$'\t' read -r _i _v; do
  [[ -n "$_i" ]] || continue
  EV_ART_OF[$_i]="${EV_ART_OF[$_i]-}$_v"$'\n'
done < <(scan_rows ART | cut -f2-)
while IFS=$'\t' read -r _i _v; do
  [[ -n "$_i" ]] || continue
  EV_DATE_OF[$_i]=$_v
done < <(scan_rows DATE | cut -f2-)

echo "== r2p v2 research lint =="

# --- 1. headline cap -------------------------------------------------------
if [[ -f "$EV/INDEX.md" ]]; then
  over=$(awk -F'|' '/^\| *[0-9]+ *\|/ {
            h=$3; gsub(/^ +| +$/,"",h);
            if (length(h) > 120) { gsub(/^ +| +$/,"",$2); printf "row %s: %d chars\n", $2, length(h) } }' "$EV/INDEX.md")
  if [[ -n "$over" ]]; then
    note "FAIL headline cap (>120 chars), $(grep -c . <<< "$over") row(s):"; show "$over"; fail=1
  else
    note "ok   headline cap"
  fi
fi

# --- 2. duplicate ids ------------------------------------------------------
dupes=$(ev_ids_all | sort -n | uniq -d)
if [[ -n "$dupes" ]]; then
  note "FAIL duplicate evidence ids:"; fail=1
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    note "     #$d claimed by:"
    for i in "${!EV_DOCS[@]}"; do
      [[ "${EV_IDNUM[$i]}" == "$d" ]] && note "       ${EV_DOCS[$i]}"
    done
  done <<< "$dupes"
else
  note "ok   evidence ids unique"
fi

# --- 3/4/5. per-doc checks -------------------------------------------------
# Read off the corpus scan. The verdict test stays a real `grep -iE` so the
# `\b` boundaries keep the semantics they had; `cut -f2-` drops the tag first so
# the pattern sees `<idx>\t<line>` and cannot match inside a path.
missing_fm=0; bad_id=0; verdicts=""; mismatch=""
while IFS=$'\t' read -r tag a b c; do
  case "$tag" in
    FM_MISSING)  missing_fm=$((missing_fm+1)) ;;
    ID_MISMATCH) bad_id=$((bad_id+1))
                 mismatch="${mismatch}$a (frontmatter=$b filename=$c)"$'\n' ;;
  esac
done <<< "$EV_SCAN"
while IFS= read -r i; do
  [[ -n "$i" ]] || continue
  verdicts="${verdicts}${EV_DOCS[$i]}"$'\n'
done < <(scan_rows MEAS | cut -f2- \
         | grep -iE '\b(confirms?|confirmed|refut|rejected|verdict|proves)\b' \
         | cut -f1 | sort -un)
(( missing_fm == 0 )) && note "ok   frontmatter complete" \
  || { note "FAIL $missing_fm evidence docs missing frontmatter or a required key"; fail=1; }
if (( bad_id == 0 )); then
  note "ok   filename id matches frontmatter"
else
  note "FAIL $bad_id doc(s) whose filename id differs from their frontmatter:"; show "$mismatch"; fail=1
fi
if [[ -n "$verdicts" ]]; then
  note "FAIL verdict words inside ## Measured, $(grep -c . <<< "$verdicts") doc(s):"; show "$verdicts"; fail=1
else
  note "ok   no verdicts in ## Measured"
fi

# --- 6. claims staleness ---------------------------------------------------
if [[ -f research/claims.md ]]; then
  reviewed=$(grep -m1 -oE '\*\*Last reviewed:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}' research/claims.md \
             | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  newest=$(scan_rows DATE | cut -f3 | sort -r | head -1)
  if [[ -n "$reviewed" && -n "$newest" && "$newest" > "$reviewed" ]]; then
    warn "claims.md last reviewed $reviewed but newest evidence is $newest"
  else
    note "ok   claims.md current (reviewed ${reviewed:-?})"
  fi
else
  n=$(ev_docs | wc -l)
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

# --- 8. claim -> evidence: every `Rests on:` id resolves --------------------
# Link 2 of the citation chain (citation-discipline.md). FAIL: a claim resting
# on an evidence doc that was never written is the pilot's highest-value defect
# class, and the only observable symptom is the dangling id.
EV_IDS=$(ev_ids_all | sort -u)
have_id() { grep -qx -- "$1" <<< "$EV_IDS"; }

if [[ -f research/claims.md ]]; then
  unresolved=""; claim="?"
  while IFS= read -r line; do
    if [[ "$line" =~ ^#{2,3}[[:space:]]+(C[0-9]+) ]]; then
      claim="${BASH_REMATCH[1]}"
    elif [[ "$line" == *"Rests on:"* ]]; then
      # `**Rests on:** #71, #72 · **Supersedes the reading of:** #62` — take only
      # the ids before the first `·`, or the supersedes leg gets checked as if it
      # were a rest-on and reports the wrong field name.
      seg=${line#*Rests on:}; seg=${seg%%·*}
      while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        have_id "$id" || unresolved="${unresolved}     $claim rests on #$id — no such evidence doc"$'\n'
      done < <(grep -oE '#[0-9]+' <<< "$seg" | tr -d '#' | sed 's/^0*//')
    fi
  done < research/claims.md
  if [[ -n "$unresolved" ]]; then
    note "FAIL claim rests on evidence that does not exist:"; printf '%s' "$unresolved"; fail=1
  else
    note "ok   every claim's Rests on: resolves"
  fi
fi

# --- 9 / 9b. evidence -> artifact binding ----------------------------------
# Two populations, and conflating them was the trap. Measured on the pilot:
# 67 artifacts referenced from deliverables/, of which 53 are discussed inside
# some evidence doc but not listed under `artifacts:`, and 14 appear nowhere in
# research/evidence/ at all. Only the second group is the audit's finding — a
# chart carrying a headline number with no evidence doc behind it, invisible for
# six months. The first group is an adoption gap: `artifacts:` is a v3 key, so on
# any project that predates it every reference is unbound by construction, and
# failing the build on that is how check-evidence.sh died.
if [[ -d deliverables ]]; then
  refs=$(deliverable_artifacts)
  bound=$(scan_rows ART | cut -f3 | norm_path | LC_ALL=C sort -u)
  # One -f pass over the corpus, not one grep per path: on the pilot (67 paths,
  # 285 docs) per-path recursion cost 9s, which is long enough that people stop
  # running the linter.
  mentioned=$(grep -rhoFf <(printf '%s\n' "$refs") "$EV" 2>/dev/null | LC_ALL=C sort -u)
  orphan=""; unbound=""; nref=0
  while IFS= read -r a; do
    [[ -n "$a" ]] || continue
    nref=$((nref+1))
    grep -qxF -- "$a" <<< "$bound" && continue
    if grep -qxF -- "$a" <<< "$mentioned"; then
      unbound="${unbound}${a}"$'\n'
    else
      orphan="${orphan}${a}"$'\n'
    fi
  done <<< "$refs"

  if [[ -n "$orphan" ]]; then
    note "FAIL artifact used in deliverables/ that no evidence doc mentions ($(grep -c . <<< "$orphan") of $nref):"
    show "$orphan"; fail=1
  elif (( nref )); then
    note "ok   every artifact in deliverables/ is known to some evidence doc"
  fi

  if [[ -n "$unbound" ]]; then
    warn "$(grep -c . <<< "$unbound") of $nref artifacts in deliverables/ are discussed by an evidence doc but not listed under the artifacts: key:"
    show "$unbound"
  elif (( nref )) && [[ -z "$orphan" ]]; then
    # Only vouch for the binding when there is something left to vouch for —
    # with every reference orphaned, "every artifact is bound" is true and
    # useless, and reads as reassurance next to a FAIL.
    note "ok   every artifact in deliverables/ is bound via artifacts:"
  fi
fi

# --- 10. evidence staleness ------------------------------------------------
# An evidence doc is stale when the newest commit touching any path in its own
# `artifacts:` is newer than the doc's own `date:`. The documented case is a
# chart re-rendered after a data re-read while the doc kept asserting the old
# numbers (docs/field-notes/porting-a-chart-…), and the doc had been wrong for
# weeks with nothing able to see it.
#
# WARN, not FAIL: a re-render is often cosmetic — a palette, a label, a figure
# size — and failing the build on every one of those trains people to stop
# reading the output.
#
# Deliberately NOT the deeper walk. `plan.md` describes this as "inputs carry a
# newer commit than the doc", but evidence frontmatter has no `inputs` field and
# adding one would duplicate the script header's `Inputs:` line — two sources of
# truth for one fact. The artifact -> Run: -> script -> header traversal needs
# real provenance walking and belongs to /pipeline-check.
if git rev-parse --git-dir >/dev/null 2>&1; then
  stale=""; checked=0
  for i in "${!EV_DOCS[@]}"; do
    # Nothing bound means nothing to compare, and asking git about the doc costs
    # a process either way. On the pilot — 285 docs, zero `artifacts:` keys —
    # this test alone was 285 `git log` calls for a check with no population.
    arts=$(ev_artifacts_at "$i"); [[ -n "$arts" ]] || continue
    f=${EV_DOCS[$i]}
    ddate=${EV_DATE_OF[$i]-}
    [[ -n "$ddate" ]] || continue
    # The doc's own last commit, as well as its `date:`. Both are needed and
    # neither alone is right:
    #   `date:` alone   — a hand-authored measurement date compared against a
    #                     commit timestamp. Author a doc on Monday, commit it
    #                     Wednesday with its chart, and the chart is "newer"
    #                     than the doc it shipped in. Measured: a fresh fixture
    #                     whose doc and chart are in one commit warned.
    #   commit alone    — a typo fix on the doc after a re-render masks the
    #                     staleness, because the doc "moved" more recently
    #                     without anyone re-reading the numbers.
    # Requiring both means: the artifact moved after the doc last moved AND
    # after the date the doc claims to describe. The field-note case (chart
    # re-rendered weeks later, doc untouched) satisfies both.
    # `%ct` (unix seconds) for the commit-vs-commit half: `--date=short` is
    # day-resolution, so a chart re-rendered the same afternoon as the doc's
    # last edit compares equal and the check silently misses it.
    read -r dct dcommit <<< "$(git log -1 --format='%ct %cd' --date=short -- "$f" 2>/dev/null)"
    while IFS= read -r a; do
      [[ -n "$a" ]] || continue
      read -r act adate <<< "$(git log -1 --format='%ct %cd' --date=short -- "$a" 2>/dev/null)"
      # No commit touching it yet: uncommitted or untracked. Invariant 12 owns
      # "does not exist"; silence here, or every new chart warns before its
      # first commit.
      [[ -n "$act" ]] || continue
      checked=$((checked+1))
      [[ "$adate" > "$ddate" ]] || continue
      [[ -n "$dct" ]] && (( act <= dct )) && continue
      stale="${stale}#${EV_IDNUM[$i]} dated $ddate (last commit ${dcommit:-none}) — $a committed $adate"$'\n'
    done <<< "$arts"
  done
  if [[ -n "$stale" ]]; then
    warn "$(grep -c . <<< "$stale") artifact(s) re-committed after the evidence doc that reads them:"
    show "$stale"
  elif (( checked )); then
    note "ok   no evidence doc is older than the artifacts it binds ($checked checked)"
  fi
fi

# --- 11. `.next-id` is ahead of the corpus ---------------------------------
# evidence.md names `.next-id` as the source of ids. If it is not strictly
# greater than the highest id on disk, the next allocation collides on issue —
# a fifth appearance of the defect, pre-armed. FAIL, because it is a one-line
# fix and the failure it prevents is silent.
#
# This will pass on a healthy project and stay quiet for months. Its value is
# prospective: a green run here is not evidence the check is idle.
highest=$(ev_ids_all | sort -n | tail -1)
if [[ -f "$EV/.next-id" ]]; then
  nid=$(tr -dc '0-9' < "$EV/.next-id")
  if [[ -z "$nid" ]]; then
    note "FAIL $EV/.next-id holds no number"; fail=1
  elif [[ -n "$highest" ]] && (( nid <= highest )); then
    note "FAIL $EV/.next-id is $nid but the highest id on disk is $highest — the next allocation collides"; fail=1
  else
    note "ok   .next-id ($nid) is ahead of the corpus (highest ${highest:-none})"
  fi
elif [[ -n "$highest" ]]; then
  note "FAIL $EV/.next-id is missing, so the next id is whatever someone guesses (highest on disk: $highest)"; fail=1
fi

# --- 12. every bound artifact exists ---------------------------------------
# A typo'd path satisfies invariant 9 for nothing: the deliverable's reference
# resolves to a binding, and the binding resolves to nothing. FAIL — this only
# fires on docs that opted into `artifacts:`, so there is no adoption cliff.
gone=""; nbound=0
while IFS=$'\t' read -r _i a; do
  [[ -n "$a" ]] || continue
  nbound=$((nbound+1))
  [[ -e "$a" ]] || gone="${gone}#${EV_IDNUM[$_i]} binds $a — no such file"$'\n'
done < <(scan_rows ART | cut -f2-)
if [[ -n "$gone" ]]; then
  note "FAIL $(grep -c . <<< "$gone") artifacts: path(s) do not exist:"; show "$gone"; fail=1
elif (( nbound )); then
  note "ok   every artifacts: path exists ($nbound bound)"
elif [[ -n "$highest" ]]; then
  # A corpus exists but nothing binds, so 10 and 12 both had nothing to read.
  # Say so: two invariants silently absent from a report reads as two passes.
  # (Empty on a fresh scaffold, which must stay silent.)
  note "--   no artifacts: bindings in the corpus yet; invariants 10 and 12 had nothing to check"
fi

# --- 13 / 14. deliverable -> claim, and the legacy `#nn` form ---------------
# Link 1 of the chain, which v2 left with only its expensive half (/cite-check).
# citation-discipline.md § Gaps promised invariant 13; this is it.
if [[ -d deliverables ]]; then

  # 13. `[C<n>]` resolving to a claim heading.
  # Anchored `^#{2,3} C<n>`, never `^## C<n>` alone — the pilot's ledger carries
  # all 48 claims at `###` under `## §N` sections, so the `##` form matches zero.
  #
  # FAIL, promoted from WARN 2026-09-09. It shipped WARN on a rationale that had
  # expired before it was written: the "573 references would drown a real
  # project" count is invariant 14's population — bare `#nn` — and 14 did not
  # exist when that call was made. Measured on the pilot, invariant 13's own
  # population is ZERO, so the volume argument that keeps 14 at WARN never
  # applied here. What is left is a check as mechanical as invariant 8 (FAIL):
  # claim ids are sparse and hand-curated, so an unresolvable `[C<n>]` is a typo
  # or a claim nobody wrote, never a mid-adoption backlog.
  #
  # The one workflow this blocks is citing `[C50]` in a draft before adding C50
  # to the ledger. That is the order citation-discipline.md § *A number that
  # cites nothing* already forbids — write the claim first, which forces the
  # evidence doc. Blocking it is the point, not a side effect.
  if [[ -f research/claims.md ]]; then
    claim_ids=$(grep -oE '^#{2,3} C[0-9]+' research/claims.md | grep -oE '[0-9]+' | sort -u)
    badc=""; nc=0
    while IFS= read -r c; do
      [[ -n "$c" ]] || continue
      nc=$((nc+1))
      grep -qx -- "$c" <<< "$claim_ids" || badc="${badc}[C$c] — no such claim in research/claims.md"$'\n'
    done < <(deliverable_docs | xargs -0 -r grep -ohE '\[C[0-9]+\]' 2>/dev/null \
             | grep -oE '[0-9]+' | sort -un)
    if [[ -n "$badc" ]]; then
      note "FAIL $(grep -c . <<< "$badc") claim reference(s) in deliverables/ resolve to nothing:"
      show "$badc"; fail=1
    elif (( nc )); then
      note "ok   every [C<n>] in deliverables/ resolves ($nc distinct)"
    elif [[ -s research/claims.md ]] && [[ -n "$(deliverable_docs | xargs -0 -r grep -l . 2>/dev/null)" ]]; then
      # Deliverables exist and a ledger exists, but nothing cites a claim. Saying
      # so is the point of the check: on the pilot that is 48 claims and zero
      # references, which is the adoption gap convert-on-touch is meant to close.
      # Silence here would read as a pass.
      note "--   no [C<n>] claim references in deliverables/ yet (see citation-discipline.md)"
    fi
  fi

  # 14. bare `#nn` resolving to a live evidence id, or to a renumber banner.
  # WARN and it will stay WARN: citation-discipline.md's convert-on-touch rule
  # keeps the `#nn` form legal indefinitely, so this fires at adoption volume.
  # The pilot carries 159 distinct bare ids across 1053 occurrences and zero
  # claim references — at adoption time this, not 13, is what actually reports.
  #
  # The failure it catches already happened: the pilot renumbered 119/131/139
  # carefully — banner, `(was #NN)` — and never updated the citations. Nothing
  # could see it. Honouring the banner is what keeps those three out of the
  # report while a genuinely dangling id stays in.
  #
  # Know what this CANNOT catch. Evidence ids are allocated contiguously, so the
  # id space is dense — measured on the pilot, 285 docs over 1..285 with zero
  # gaps. A reference can therefore only be caught when it lands ABOVE the high
  # water mark; a transposed `#71` -> `#17` resolves silently to the wrong doc
  # and always will. That is not a bug in the check, it is the ceiling of the
  # `#nn` form, and it is the strongest argument for converting to `[C<n>]`:
  # claim ids are sparse and hand-curated, so `[C99]` is catchable where `#99`
  # is not (invariant 13).
  live=$( { ev_ids_all; renumbered_ids; } | sort -u)
  badn=""; nn=0
  while IFS= read -r tok; do
    [[ -n "$tok" ]] || continue
    # `#5FA1C7` and `#266798` are hex colours in an embedded code block, not
    # ids. Drop anything carrying a hex letter, and anything longer than four
    # digits — no evidence corpus reaches five.
    [[ "$tok" =~ [A-Fa-f] ]] && continue
    (( ${#tok} > 4 )) && continue
    id=$(sed 's/^0*//' <<< "$tok"); [[ -n "$id" ]] || continue
    nn=$((nn+1))
    grep -qx -- "$id" <<< "$live" || badn="${badn}#$id — no evidence doc and no renumber banner claims it"$'\n'
  done < <(deliverable_docs | xargs -0 -r grep -ohE '#[0-9][0-9A-Fa-f]*' 2>/dev/null \
           | sed 's/^#//' | sort -u)
  if [[ -n "$badn" ]]; then
    warn "$(grep -c . <<< "$badn") of $nn bare #nn reference(s) in deliverables/ resolve to nothing:"
    show "$badn"
  elif (( nn )); then
    note "ok   every bare #nn in deliverables/ resolves ($nn distinct)"
  fi
fi

echo
if (( fail )); then
  printf 'FAIL'
else
  printf 'PASS'
fi
(( warns )) && printf ' — %d warning(s)' "$warns"
printf '\n'
exit $fail
