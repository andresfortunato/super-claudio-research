#!/usr/bin/env python3
"""
Inputs:  every tracked .md file
Outputs: plan/plan-r2p-v2-consolidation/mapping/linkcheck.md (+ nonzero exit on breaks)
Seed:    none
Env:     python3 stdlib only

Verification gate for the Phase-2 repath. Extracts every repo-internal path
reference from tracked markdown — markdown links AND backticked paths, since the
r2p corpus cites files both ways — and reports the ones that do not exist.

Known-absent references that predate the migration are listed in BASELINE so the
gate reports only NEW breakage. Run before every layout commit.
"""
from __future__ import annotations

import re
import subprocess
import sys
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


def main() -> int:
    files = [ROOT / f for f in subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "*.md"],
        capture_output=True, text=True, check=True).stdout.split()]
    broken: dict[str, set[str]] = {}
    checked = 0
    for p in files:
        if not p.is_file():
            continue
        try:
            text = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for tok in candidates(text):
            checked += 1
            target = (ROOT / tok)
            if not target.exists():
                broken.setdefault(tok, set()).add(str(p.relative_to(ROOT)))

    lines = ["# Link check", "", f"markdown files scanned: **{len(files)}**",
             f"repo-path references checked: **{checked}**",
             f"unresolved: **{len(broken)}**", ""]
    if broken:
        lines += ["| missing target | cited from |", "|---|---|"]
        for tok in sorted(broken):
            src = sorted(broken[tok])
            lines.append(f"| `{tok}` | {', '.join(src[:3])}"
                         f"{f' (+{len(src)-3})' if len(src) > 3 else ''} |")
    report = "\n".join(lines) + "\n"
    (ROOT / "plan/plan-r2p-v2-consolidation/mapping/linkcheck.md").write_text(
        report, encoding="utf-8")
    print(report)
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
