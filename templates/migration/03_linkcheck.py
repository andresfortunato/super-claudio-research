#!/usr/bin/env python3
"""
Inputs:  every tracked .md file
Outputs: linkcheck.md at the repo root (+ nonzero exit on new breaks)
Seed:    none
Env:     python3 stdlib only

Verification gate for the Phase-2 repath. Two independent checks:

  1. UNRESOLVED REFERENCES. Extracts every repo-internal path reference from
     tracked markdown — markdown links AND backticked paths, since the r2p
     corpus cites files both ways — and reports the ones that do not exist.

     `--baseline <git-ref>` reports the DELTA against that ref rather than a raw
     count, and a raw count is close to meaningless here. The v2 migration's
     checker reported 238 dangling references, which reads as catastrophic until
     the same checker, run against a worktree of the pre-migration commit,
     reported 405. Most dangling links predated any migration and the repath
     fixed more than it touched. Without the comparison there is no way to
     separate your breakage from the repo's.

  2. DUPLICATE PATHS ON ONE LINE — a many-to-one collapse. `02_repath.py`'s
     EXCLUDE_PREFIXES guard structurally cannot catch this: when three v1
     directories map to one v2 directory, an enumerating sentence becomes the
     same *valid* path three times, so check 1 passes on every one of them. It
     is a property of the result, which is why it lives here and not in the
     repather.

`BASELINE_PAT` below is unrelated to `--baseline` despite the name: it is a
filter for tokens that are not checkable references at all (templates, globs,
`<slug>` placeholders, URLs). It does not measure pre-existing breakage; that is
what `--baseline` is for.
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                           capture_output=True, text=True, check=True).stdout.strip())

TOP = {"analysis", "data", "output", "research", "plan", "deliverables",
       "reference", "scrapers", ".claude", "cordoba_utils.py"}

# markdown link targets, and backticked tokens that look like repo paths
MD_LINK = re.compile(r"\]\(([^)\s#]+)")
TICKED = re.compile(r"`([A-Za-z_.][\w./<>*-]*/[\w./<>*-]+)`")

# templates, globs, and prose fragments — not checkable path references
BASELINE_PAT = re.compile(
    r"<|>|\*|\$|NN_|YYYY|plan-<|<slug>|<source>|<theme>|<topic>|<method>|"
    r"^https?:|^mailto:|^\.\./|^~/|\.\.\."
)

# A token is only a real reference if it names a file (has an extension) or a
# directory (trailing slash). Bare `research/evidence/125` is prose shorthand for
# evidence #125, not a path, and 100+ such fragments swamped the first run.
REAL_REF = re.compile(r"(\.[A-Za-z0-9]{1,6}$)|(/$)")

# --- the two criteria that make check 2 a detector rather than a nuisance ----
# A collapse leaves the same path repeated as adjacent items in an enumeration.
# A legitimate repeat is the same path named twice across a sentence. Both were
# measured against every same-path repeat in the framework repo, plus the two
# pre-fix lines recovered from commit c133bc2, plus the live instance in
# README.md that this check found on its first run:
#
#   three real collapses   separator lengths 4, 4, 7, 10, 18   no sentence break
#   eleven legitimate      16, 48, 48, 70, 83, 86, 102, …      the 16 is `. Anything in `
#
# Gap alone does not separate them — 16 < 18. Gap AND "no sentence boundary in
# between" separates all fourteen. Anything that fails either criterion is still
# printed, under `noted`, because a bounded report that drops the rest silently
# is the habit 6b exists to correct.
DUP_MAX_GAP = 20
SENTENCE_BREAK = re.compile(r"[.!?][\s)\"'`]+[A-Z(]")


def candidates(text: str) -> set[str]:
    out = set()
    for rx in (MD_LINK, TICKED):
        for m in rx.finditer(text):
            tok = m.group(1).strip().rstrip(".,;:")
            if BASELINE_PAT.search(tok) or not REAL_REF.search(tok):
                continue
            head = tok.split("/")[0]
            if head in TOP or tok.split("/")[0] + "/" in {t + "/" for t in TOP}:
                out.add(tok)
    return out


def tracked_md(root: Path) -> list[Path]:
    out = subprocess.run(["git", "-C", str(root), "ls-files", "*.md"],
                         capture_output=True, text=True, check=True).stdout.split()
    return [root / f for f in out]


def scan(root: Path) -> tuple[dict[str, set[str]], int, int]:
    """Unresolved references under `root`. Returns (broken, refs, files)."""
    files = tracked_md(root)
    broken: dict[str, set[str]] = {}
    checked = 0
    real = 0
    for p in files:
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        real += 1
        for tok in candidates(text):
            checked += 1
            if not (root / tok).exists():
                broken.setdefault(tok, set()).add(str(p.relative_to(root)))
    return broken, checked, real


def line_spans(line: str) -> list[tuple[int, int, str]]:
    """Every path-shaped token on one line, with its position, in order."""
    out = []
    for rx in (TICKED, MD_LINK):
        for m in rx.finditer(line):
            out.append((m.start(1), m.end(1), m.group(1)))
    return sorted(out)


def duplicate_paths(root: Path) -> tuple[list[tuple], list[tuple]]:
    """Same path 2+ times on one line. Returns (flagged, noted)."""
    flagged, noted = [], []
    for p in tracked_md(root):
        if not p.is_file():
            continue
        try:
            lines = p.read_text(encoding="utf-8").split("\n")
        except UnicodeDecodeError:
            continue
        rel = str(p.relative_to(root))
        for n, line in enumerate(lines, 1):
            by: dict[str, list[tuple[int, int]]] = {}
            for s, e, tok in line_spans(line):
                by.setdefault(tok, []).append((s, e))
            for tok, at in by.items():
                if len(at) < 2:
                    continue
                # Every adjacent pair, so a triple is judged on its tightest gap.
                gaps = []
                enumerated = False
                for i in range(len(at) - 1):
                    between = line[at[i][1]:at[i + 1][0]]
                    gaps.append(len(between))
                    if len(between) <= DUP_MAX_GAP and not SENTENCE_BREAK.search(between):
                        enumerated = True
                row = (rel, n, tok, len(at), min(gaps), line.strip()[:120])
                (flagged if enumerated else noted).append(row)
    flagged.sort(key=lambda r: (r[4], r[0], r[1]))
    noted.sort(key=lambda r: (r[4], r[0], r[1]))
    return flagged, noted


def baseline_scan(ref: str) -> tuple[dict[str, set[str]], int, int]:
    """Scan `ref` in a throwaway worktree. Removed even on failure."""
    tmp = Path(tempfile.mkdtemp(prefix="r2p-linkcheck-")) / "tree"
    try:
        add = subprocess.run(["git", "-C", str(ROOT), "worktree", "add",
                              "--detach", str(tmp), ref],
                             capture_output=True, text=True)
        if add.returncode:
            # A traceback here reads as "the tool is broken" when the actual
            # problem is a typo in a ref name. These scripts are read and run by
            # hand; the message has to say which of the two it is.
            sys.exit(f"linkcheck: cannot check out baseline ref {ref!r}\n"
                     f"  git said: {add.stderr.strip()}")
        return scan(tmp)
    finally:
        subprocess.run(["git", "-C", str(ROOT), "worktree", "remove", "--force",
                        str(tmp)], capture_output=True)
        subprocess.run(["git", "-C", str(ROOT), "worktree", "prune"],
                       capture_output=True)
        shutil.rmtree(tmp.parent, ignore_errors=True)


def cite_table(broken: dict[str, set[str]], keys) -> list[str]:
    out = ["| missing target | cited from |", "|---|---|"]
    for tok in sorted(keys):
        src = sorted(broken[tok])
        out.append(f"| `{tok}` | {', '.join(src[:3])}"
                   f"{f' (+{len(src) - 3})' if len(src) > 3 else ''} |")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[1])
    ap.add_argument("--baseline", metavar="GIT_REF",
                    help="report the delta against this ref instead of a raw count")
    ap.add_argument("--out", metavar="PATH", default="linkcheck.md",
                    help="report destination, relative to the repo root "
                         "(default: linkcheck.md)")
    args = ap.parse_args()

    broken, refs, files = scan(ROOT)
    flagged, noted = duplicate_paths(ROOT)

    lines = ["# Link check", "",
             f"markdown files scanned: **{files}**",
             f"repo-path references checked: **{refs}**",
             f"unresolved: **{len(broken)}**", ""]

    new_breaks: set[str] = set(broken)
    if args.baseline:
        base, brefs, bfiles = baseline_scan(args.baseline)
        new_breaks = set(broken) - set(base)
        fixed = set(base) - set(broken)
        pre = set(broken) & set(base)
        lines += [f"## Delta against `{args.baseline}`", "",
                  f"- baseline unresolved: **{len(base)}** "
                  f"({brefs} refs across {bfiles} files)",
                  f"- **new breaks: {len(new_breaks)}** ← the only number that "
                  f"is about this change",
                  f"- fixed by this change: {len(fixed)}",
                  f"- pre-existing, untouched: {len(pre)}", ""]
        if new_breaks:
            lines += ["### New breaks", ""] + cite_table(broken, new_breaks) + [""]
        if fixed:
            lines += ["### Fixed", ""] + [f"- `{t}`" for t in sorted(fixed)] + [""]
        if pre:
            lines += ["### Pre-existing (not yours)", ""] + \
                     cite_table(broken, pre) + [""]
    elif broken:
        lines += ["## Unresolved", "",
                  "*No `--baseline <ref>` given, so this is a raw count and says "
                  "nothing about whether this change broke anything.*", ""] + \
                 cite_table(broken, broken) + [""]

    lines += [f"## Duplicate paths on one line", "",
              f"A many-to-one collapse leaves the same *valid* path repeated, so "
              f"the check above passes on every copy.", "",
              f"- **likely collapses: {len(flagged)}** (repeats ≤{DUP_MAX_GAP} "
              f"chars apart with no sentence boundary between)",
              f"- legitimate repeats, listed not dropped: {len(noted)}", ""]
    for label, rows in (("### Likely collapses", flagged),
                        ("### Noted — same path twice, but across a sentence", noted)):
        if not rows:
            continue
        lines += [label, "", "| file:line | path | × | min gap | line |",
                  "|---|---|--:|--:|---|"]
        for rel, n, tok, count, gap, txt in rows:
            lines.append(f"| `{rel}:{n}` | `{tok}` | {count} | {gap} | "
                         f"{txt.replace('|', '\\|')} |")
        lines.append("")

    report = "\n".join(lines) + "\n"
    out = ROOT / args.out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(report, encoding="utf-8")
    print(report)
    return 1 if (new_breaks or flagged) else 0


if __name__ == "__main__":
    sys.exit(main())
