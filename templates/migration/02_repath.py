#!/usr/bin/env python3
"""
Inputs:  every tracked text file (md, R, py, sh, yaml, yml, txt, json, qmd)
Outputs: the same files, with v1 paths rewritten to the v2 layout
         plan/plan-r2p-v2-consolidation/mapping/repath_report.md
Seed:    none
Env:     python3 stdlib only

Phase 2b of plan-r2p-v2-consolidation. Rewrites references to moved
directories. `decisions/` and `learnings/` are deliberately NOT rewritten here
— their targets are method topics that Phase 3 creates, so rewriting them now
would only have to be redone.

Safety: a path token only matches when preceded by start-of-line or one of
`\\s ( [ ` " ' : , = |` — never by another path segment. That is what stops
`research/evidence/` becoming `research/research/evidence/` and stops
`.claude/conventions/methods.md` being mangled into a directory reference.

Run with --check to report what would change without writing.
"""
from __future__ import annotations

import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(subprocess.run(
    ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
).stdout.strip())

EXTS = {".md", ".R", ".r", ".py", ".sh", ".yaml", ".yml", ".txt", ".json", ".qmd", ".Rmd"}

# A mechanical repath will rewrite the documentation ABOUT the repath — the one
# place old paths are supposed to survive. On the pilot it turned this script's
# own RULES table into ("research/sources/", "research/sources/") and mangled the
# v1-vs-v2 comparison tables inside the new conventions. Both were caught by
# reading the diff, not by any test. Exclude those paths.
EXCLUDE_PREFIXES = (
    ".claude/conventions/",                  # v1-vs-v2 contrast tables live here
    "templates/migration/",                  # this script and its siblings
    "plan/plan-r2p-v2-consolidation/",       # the migration plan itself
    "docs/v1-to-v2-migration.md",
)

# ordered: longest / most specific first
RULES: list[tuple[str, str]] = [
    # wiki/raw/literature/ left the wiki entirely — must precede the wiki/ rule
    ("wiki/raw/literature/", "reference/literature/"),
    # the four v1 method folders go straight to their final flat v2 slugs, so
    # these 100+ references are rewritten once instead of twice
    ("methods/pizza_chart/rule.md", "research/methods/pizza-chart.md"),
    ("methods/city_growth_models/rule.md", "research/methods/city-growth-models.md"),
    ("methods/structural_transformation/rule.md",
     "research/methods/structural-transformation.md"),
    ("methods/cordoba_shift_share_bartik/rule.md",
     "research/methods/shift-share-bartik.md"),
    ("methods/spatial_equilibrium_mincer/rule.md",
     "research/methods/spatial-equilibrium-mincer.md"),
    ("methods/cordoba_shift_share_bartik/",
     "research/methods/_adjuncts/shift-share-bartik/"),
    ("data_sources/", "research/sources/"),
    ("project_conventions/", ".claude/conventions/project/"),
    ("internal_docs/", "reference/internal/"),
    ("brainstorms/", "plan/brainstorms/"),
    ("evidence/", "research/evidence/"),
    ("wiki/", "research/wiki/"),
    ("slides/", "deliverables/decks/"),
    ("archive/", "plan/archive/"),
    # `methods/` must not touch `conventions/methods.md`; the trailing slash and
    # the left-boundary class together guarantee that.
    ("methods/", "research/methods/"),
]

LEFT = r"(?<![\w./-])"
COMPILED = [(re.compile(LEFT + re.escape(src)), src, dst) for src, dst in RULES]

# ---------------------------------------------------------------------------
# Bare-segment guard. Every RULE above carries a trailing slash, so a path
# BUILT SEGMENT-BY-SEGMENT is invisible to all of them:
#
#     EVID = REPO / "evidence"              # not matched — no slash
#     """Inputs: research/evidence/*.md"""  # matched, rewritten
#
# The docstring gets repathed and the line that opens the directory does not,
# and the report above reads clean. Measured on the pilot: 571 rewrites across
# 559 files, double-prefix guard clean, and FOUR dead v1 paths left in code —
# one gate that now crashes, one shared util module, and two chart scripts that
# `mkdir(parents=True)` their v1 target and so RE-CREATE a directory this
# migration deleted, silently, exit 0.
#
# This guard reports; it never rewrites. Turning `X / "evidence"` into
# `X / "research" / "evidence"` needs to know what X is, and a wrong rewrite of
# a path expression is worse than an unrewritten one.
#
# The watch list is DERIVED FROM `RULES`, not restated, so the guard and the
# rewriter can never disagree about which directories moved.
CODE_EXTS = {".py", ".R", ".r", ".sh", ".qmd", ".Rmd"}

# Constructors that take a path segment as a bare quoted string.
JOINERS = ("join(", "Path(", "file.path(", "here(", "glue(")


def _bare_segments() -> dict[str, str | None]:
    """v1 first segment -> the v2 parent that may legitimately precede it.

    `methods/` -> `research/methods/` keeps the name, so a line already reading
    `ROOT / "research" / "methods"` is correct and must not be flagged; the
    parent to look for is `research`. `data_sources/` -> `research/sources/`
    renames the segment, so `data_sources` can never be legitimate and the
    parent is None.
    """
    out: dict[str, str | None] = {}
    for src, dst in RULES:
        seg = src.strip("/").split("/")[0]
        if seg in out:
            continue
        parts = dst.strip("/").split("/")
        i = parts.index(seg) if seg in parts else 0
        out[seg] = parts[i - 1] if i > 0 else None
    return out


BARE = _bare_segments()


def bare_segment_hits(files: list[Path]) -> list[str]:
    """Path expressions naming a moved directory as a bare quoted segment."""
    hits = []
    for p in files:
        if p.suffix not in CODE_EXTS:
            continue
        try:
            lines = p.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue
        for lineno, line in enumerate(lines, 1):
            for seg, v2parent in BARE.items():
                q = r"[\"']" + re.escape(seg) + r"[\"']"
                m = re.search(r"/\s*" + q, line) or (
                    re.search(q, line) if any(j in line for j in JOINERS) else None
                )
                if not m:
                    continue
                head = line[:m.start()]
                # Relative to the script's own directory, not the repo root —
                # `Path(__file__).parent / "slides"` inside a deliverable is
                # that deliverable's own subfolder and did not move.
                if "__file__" in head:
                    continue
                # Already under its v2 parent: `ROOT / "research" / "methods"`.
                if v2parent and re.search(r"[\"']" + re.escape(v2parent) + r"[\"']", head):
                    continue
                hits.append(f"{p.relative_to(ROOT)}:{lineno}  "
                            f"bare `{seg}` — {line.strip()[:88]}")
                break
    return hits


def tracked_text_files() -> list[Path]:
    out = subprocess.run(["git", "-C", str(ROOT), "ls-files", "-z"],
                         capture_output=True, text=True, check=True).stdout
    files = []
    for rel in out.split("\0"):
        if not rel:
            continue
        p = ROOT / rel
        if rel.startswith(EXCLUDE_PREFIXES):
            continue
        if p.suffix in EXTS and p.is_file():
            files.append(p)
    return files


def main() -> int:
    check = "--check" in sys.argv
    counts: Counter[str] = Counter()
    touched: dict[str, Counter[str]] = {}

    for p in tracked_text_files():
        try:
            orig = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        text = orig
        per_file: Counter[str] = Counter()
        for rx, src, dst in COMPILED:
            text, n = rx.subn(dst, text)
            if n:
                per_file[f"{src} -> {dst}"] += n
                counts[f"{src} -> {dst}"] += n
        if text != orig:
            touched[str(p.relative_to(ROOT))] = per_file
            if not check:
                p.write_text(text, encoding="utf-8")

    # guard: no double prefixes anywhere
    bad = []
    for p in tracked_text_files():
        try:
            t = p.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pat in ("research/research/", "plan/plan/archive", "reference/reference/",
                    ".claude/conventions/project/project/"):
            if pat in t:
                bad.append(f"{p.relative_to(ROOT)}: {pat}")

    # guard: paths built segment-by-segment, which no RULE can see
    segs = bare_segment_hits(tracked_text_files())

    lines = ["# Repath report", "", f"mode: {'check' if check else 'write'}", "",
             "| rewrite | occurrences |", "|---|--:|"]
    for k, v in counts.most_common():
        lines.append(f"| `{k}` | {v} |")
    lines += ["", f"files touched: **{len(touched)}**", "",
              "## Double-prefix guard", ""]
    lines.append("clean" if not bad else "\n".join(f"- ⚠ {b}" for b in bad))
    lines += ["", "## Bare-segment guard", "",
              "Path expressions that name a moved directory as a bare quoted",
              "segment. Nothing above rewrote these — every rule needs a",
              "trailing slash. **Fix each by hand before trusting this repath.**",
              ""]
    lines.append("clean" if not segs else "\n".join(f"- ⚠ {s}" for s in segs))
    report = "\n".join(lines) + "\n"
    (ROOT / "plan/plan-r2p-v2-consolidation/mapping/repath_report.md").write_text(
        report, encoding="utf-8")
    print(report)
    return 1 if (bad or segs) else 0


if __name__ == "__main__":
    sys.exit(main())
