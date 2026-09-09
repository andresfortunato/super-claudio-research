#!/usr/bin/env bash
# Integration test for the SECOND installer.
#
# Usage:  bash test/upgrade-integration.sh            (from the framework repo)
# Env:    node + bash. No new runtime dependency, deliberately — a test that
#         needs a toolchain installed is a test nobody runs.
#
# r2p has two installers, `r2p init` (src/lib/install-project.js) and
# `r2p init --upgrade` (src/lib/upgrade.js), and a layout change is therefore two
# changes. `--upgrade` is the one that gets forgotten: three v2 defects lived only
# there — a stale EXCLUDE list, unmapped `templates/plan_dir` and
# `templates/claude_conventions_project`, and an ungated wiki — and every one of
# them was invisible to an `r2p init` test, because v2's stated verification was
# an init into a temp repo.
#
# So this test does the thing an init test structurally cannot: it upgrades a
# project that already has state, with that state deliberately divergent from the
# framework's templates. Divergence is the steady state of an append-only file;
# it must survive an upgrade untouched and without a sidecar.
#
# Each assertion below names the defect it guards. An assertion that cannot name
# one is a test measuring the implementation instead of the contract.

set -uo pipefail

R2P=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$R2P/src/cli.js"

pass=0
fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; [[ $# -gt 1 ]] && printf '       %s\n' "$2"; }

# The eight root directories v2 got a project down to. The junk-root defect was
# `--upgrade` adding claude_conventions_project/, plan_dir/ and migration/ to
# this list, so the assertion is equality, not containment.
EXPECTED_DIRS="analysis .claude data deliverables output plan reference research"

# Every file whose whole purpose is to accumulate project state. All seven are in
# upgrade.js's EXCLUDE; a missed entry sidecars them on every upgrade forever.
APPEND_ONLY=(
  research/claims.md
  research/evidence/INDEX.md
  research/evidence/.next-id
  research/methods/INDEX.md
  research/sources/INDEX.md
  .claude/conventions/project/INDEX.md
  plan/archive/index.md
)

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r2p-upgrade-test.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# --- a project with state, diverged from the templates on purpose ------------
new_project() {   # $1 = name, $2.. = extra init flags
  local dir="$WORK/$1"; shift
  mkdir -p "$dir"
  git -C "$dir" init -q .
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  ( cd "$dir" && node "$CLI" init "$@" ) > "$dir/.init.log" 2>&1 || {
    echo "  FATAL: r2p init failed; see $dir/.init.log" >&2; exit 2; }
  printf '%s' "$dir"
}

dirty_append_only() {   # $1 = project dir
  local dir=$1 f
  for f in "${APPEND_ONLY[@]}"; do
    if [[ "$f" == *".next-id" ]]; then
      echo 42 > "$dir/$f"                       # a counter the project advanced
    else
      printf '\n<!-- project state added after init -->\n' >> "$dir/$f"
    fi
    cp "$dir/$f" "$dir/.expected-$(echo "$f" | tr / _)"
  done
}

assert_append_only_intact() {   # $1 = project dir, $2 = label
  local dir=$1 label=$2 f want clobbered="" sidecar=""
  for f in "${APPEND_ONLY[@]}"; do
    want="$dir/.expected-$(echo "$f" | tr / _)"
    cmp -s "$dir/$f" "$want" || clobbered="$clobbered $f"
    [[ -e "$dir/$f.framework-new" ]] && sidecar="$sidecar $f"
  done
  # Guards: the stale-EXCLUDE defect, which sidecars all seven forever, and any
  # future change that overwrites them outright.
  [[ -z "$clobbered" ]] && ok "$label: all 7 append-only files byte-identical" \
    || bad "$label: append-only file(s) clobbered" "$clobbered"
  [[ -z "$sidecar" ]] && ok "$label: no .framework-new sidecar on any of the 7" \
    || bad "$label: sidecar(s) written for EXCLUDE'd file(s)" "$sidecar"
}

assert_root_dirs() {   # $1 = project dir, $2 = label
  local dir=$1 label=$2 got
  got=$(cd "$dir" && for x in * .[!.]*; do [[ -d "$x" && "$x" != ".git" ]] && echo "$x"; done \
        | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
  local want
  want=$(printf '%s\n' $EXPECTED_DIRS | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')
  # Guards the junk-root defect: plan_dir/, claude_conventions_project/,
  # migration/ landing at the project root because --upgrade stripped the
  # `templates/` prefix instead of consulting TEMPLATE_DIR_MAP.
  [[ "$got" == "$want" ]] && ok "$label: root dirs are exactly the 8 v2 dirs" \
    || bad "$label: root dir list drifted" "want: $want${NL}       got:  $got"
  # The same defect's other symptom, called out by name because a bare
  # `plan/plan.md` is meaningless and reads as a real file.
  [[ ! -e "$dir/plan/plan.md" ]] && ok "$label: no bare plan/plan.md" \
    || bad "$label: plan/plan.md was introduced (templates/plan/ is not-installed)"
}
NL=$'\n'

echo "== r2p --upgrade integration test =="
echo

# --- 1. upgrade over a dirty project ----------------------------------------
echo "1. upgrade over a project with divergent append-only state"
P=$(new_project plain)
dirty_append_only "$P"
UP="$P/.upgrade.log"
( cd "$P" && node "$CLI" init --upgrade ) > "$UP" 2>&1 || bad "plain: --upgrade exited nonzero"
assert_append_only_intact "$P" plain
assert_root_dirs "$P" plain

# staleExcludes() and resurrectedHooks() both warn-and-proceed, so their only
# observable is the message. Absence is the assertion.
grep -q "EXCLUDE path(s) no longer exist" "$UP" \
  && bad "plain: staleExcludes() is non-empty — an EXCLUDE path no longer exists under templates/" \
        "$(grep -A9 'EXCLUDE path(s)' "$UP")" \
  || ok "plain: staleExcludes() reports empty"
grep -q "REMOVED_HOOKS entry(ies) are shipping again" "$UP" \
  && bad "plain: a REMOVED_HOOKS entry is shipping again" \
  || ok "plain: no REMOVED_HOOKS entry has been resurrected"

# The wiki is opt-in because on the pilot it produced zero pages in six months
# while costing two CLAUDE.md sections per session. Absence is a decision, not a
# gap for --upgrade to fill.
[[ ! -d "$P/research/wiki" ]] && ok "plain: --upgrade did not reintroduce research/wiki/" \
  || bad "plain: --upgrade scaffolded research/wiki/ into a project that opted out"

# A project with no removed hooks on disk must stay silent, or the warning is
# noise on every upgrade.
grep -q "were removed from the framework" "$UP" \
  && bad "plain: removed-hook warning fired with no removed hooks present" \
  || ok "plain: removed-hook warning stays silent when there is nothing to say"
echo

# --- 2. --with-wiki opts in later -------------------------------------------
echo "2. --upgrade --with-wiki opts an existing project in"
W=$(new_project wiki)
dirty_append_only "$W"
( cd "$W" && node "$CLI" init --upgrade --with-wiki ) > "$W/.upgrade.log" 2>&1 \
  || bad "wiki: --upgrade --with-wiki exited nonzero"
[[ -d "$W/research/wiki" ]] && ok "wiki: --with-wiki scaffolded research/wiki/" \
  || bad "wiki: --with-wiki did not scaffold research/wiki/"
assert_append_only_intact "$W" wiki
assert_root_dirs "$W" wiki
echo

# --- 3. an already-opted-in project keeps the wiki --------------------------
echo "3. a project that already has the wiki keeps it on a plain --upgrade"
A=$(new_project already --with-wiki)
[[ -d "$A/research/wiki" ]] || bad "already: init --with-wiki did not scaffold the wiki"
( cd "$A" && node "$CLI" init --upgrade ) > "$A/.upgrade.log" 2>&1 \
  || bad "already: --upgrade exited nonzero"
[[ -d "$A/research/wiki" ]] && ok "already: plain --upgrade preserved research/wiki/" \
  || bad "already: plain --upgrade removed the wiki from a project that had it"
echo

# --- 4. the removed hook that is still firing -------------------------------
# v2 deleted check-evidence.sh for firing unconditionally after a path refactor.
# Months later the pilot still had the file and a settings.json entry running it,
# and --upgrade said nothing: it warns about an obsolete .claude/skills/ and
# about stale EXCLUDE paths, and emitted zero hook-related output. Silent
# deprecation is how a removed hook survives a release cycle in production.
echo "4. a removed hook still on disk, and still wired"
O=$(new_project orphan)
printf '#!/usr/bin/env bash\n# v2 deleted this hook.\nexit 0\n' \
  > "$O/.claude/hooks/check-evidence.sh"
chmod +x "$O/.claude/hooks/check-evidence.sh"
cat > "$O/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "Stop": [
      { "matcher": "", "hooks": [
        { "type": "command", "command": "bash .claude/hooks/check-evidence.sh" }
      ] }
    ]
  }
}
JSON
OUP="$O/.upgrade.log"
( cd "$O" && node "$CLI" init --upgrade ) > "$OUP" 2>&1 || bad "orphan: --upgrade exited nonzero"
grep -q "check-evidence.sh — obsolete" "$OUP" \
  && ok "orphan: the removed hook is named as obsolete" \
  || bad "orphan: --upgrade did not name check-evidence.sh as obsolete"
grep -q "still referenced by this project's settings.json" "$OUP" \
  && ok "orphan: the settings.json wiring is called out separately" \
  || bad "orphan: --upgrade did not say the hook is still wired"
# Never auto-delete. Deleting the script while leaving the settings.json entry
# turns a stale hook into a failing one, and --upgrade does not rewrite a
# project's settings.json.
[[ -f "$O/.claude/hooks/check-evidence.sh" ]] \
  && ok "orphan: the hook file was not auto-deleted" \
  || bad "orphan: --upgrade deleted a project file"
grep -q "check-evidence.sh" "$O/.claude/settings.json" \
  && ok "orphan: the project's settings.json was not rewritten" \
  || bad "orphan: --upgrade rewrote the project's settings.json"
echo

# --- 5. idempotence ---------------------------------------------------------
# "Idempotent by rebuild, not by skip." A second upgrade must report nothing to
# do rather than accumulating sidecars.
echo "5. a second --upgrade is a no-op"
S2="$P/.upgrade2.log"
( cd "$P" && node "$CLI" init --upgrade ) > "$S2" 2>&1 || bad "repeat: --upgrade exited nonzero"
sidecars=$(find "$P" -name '*.framework-new' | wc -l | tr -d ' ')
[[ "$sidecars" == "0" ]] && ok "repeat: zero .framework-new sidecars in the tree" \
  || bad "repeat: $sidecars sidecar(s) in the tree" "$(find "$P" -name '*.framework-new')"
assert_append_only_intact "$P" repeat
echo

printf '%d passed, %d failed\n' "$pass" "$fail"
if (( fail )); then
  echo
  echo "Logs kept under $WORK — re-run with KEEP=1 to inspect them." >&2
  [[ -n "${KEEP:-}" ]] && trap - EXIT
  exit 1
fi
exit 0
