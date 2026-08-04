#!/usr/bin/env python3
"""
Inputs:  research/_legacy/decisions/*.md, research/_legacy/learnings/*.md,
         research/methods/<v1 folders>/rule.md,
         mapping/{decisions_map,learnings_map}.csv, mapping/methods_topics.tsv
Outputs: research/methods/<topic>.md (28), research/methods/_craft.md,
         research/methods/INDEX.md,
         research/sources/<source>.md (## Gotchas appended, 24 learnings),
         plan/plan-r2p-v2-consolidation/mapping/methods_merge_report.md
Seed:    none
Env:     python3 stdlib only

Phase 5 of plan-r2p-v2-consolidation. Structural merge, not a rewrite: the v1
decision records and learnings are well-written and carry exact numbers, so their
prose moves verbatim under the v2 section headings rather than being re-prosed.
What the merge adds is (a) one file per topic, (b) uniform sections, (c) traps
folded in from learnings, (d) frontmatter with retrieval triggers.

v1 section -> v2 section:
  Decision / Rule                         -> ## Rule
  Alternatives considered / Why rejected   -> ## Why this and not the alternatives
  Validation / Diagnostic counts           -> ## Diagnostic counts
  Key assumptions / What would invalidate  -> ## Scope and limits
  Known limitations / Edge cases / Exclusions
  learnings (Problem/Solution/Prevention)  -> ## Traps
  everything else                          -> kept under its own heading in Rule
"""
from __future__ import annotations

import csv
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                           capture_output=True, text=True, check=True).stdout.strip())
MAP = ROOT / "plan/plan-r2p-v2-consolidation/mapping"
LEG = ROOT / "research/_legacy"
METH = ROOT / "research/methods"
SRC = ROOT / "research/sources"

RULE_H = re.compile(r"^##+\s*(Decision|Rule|Decisión|What we compute|Source)\b", re.I)
WHY_H = re.compile(r"^##+\s*(Alternatives|Why rejected|Why \(|Why this|Why—|Why —|"
                   r"Why$|Alternativas)", re.I)
DIAG_H = re.compile(r"^##+\s*(Validation|Diagnostic|Diagnostics|Counts|Verification)\b", re.I)
LIM_H = re.compile(r"^##+\s*(Key assumptions|What would invalidate|Known limitations|"
                   r"Edge cases|Exclusions|Caveats|Scope|Limitations|Assumptions|"
                   r"Consequences|Implementation notes|Data availability)", re.I)


def demote(body: str, base: int = 4) -> str:
    """Strip the H1 and push every remaining heading below `base`.

    Merged learnings arrive with their own `#`/`##`/`###` headings. Pasted as-is,
    a `##` inside a `### block` silently re-opens a top-level section and the
    topic file's structure collapses -- which is exactly what the first run did.
    """
    body = re.sub(r"(?m)^#[ \t]+.*$", "", body, count=1).strip()

    def bump(m: re.Match) -> str:
        depth = len(m.group(1))
        return "#" * min(6, base + depth - 1) + " "

    return re.sub(r"(?m)^(#{1,6})[ \t]+", bump, body)


def load_map(name: str) -> dict[str, tuple[str, str]]:
    out = {}
    with (MAP / name).open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            out[row["file"]] = (row["destination"], row["target"])
    return out


def strip_fm(t: str) -> str:
    if t.startswith("---\n"):
        parts = t.split("---\n", 2)
        if len(parts) == 3:
            return parts[2].lstrip("\n")
    return t


def split_sections(text: str) -> list[tuple[str, str]]:
    """-> [(heading_line_or_'', body)] preserving order."""
    out, cur_h, buf = [], "", []
    for line in text.splitlines():
        if line.startswith("## "):
            out.append((cur_h, "\n".join(buf).strip()))
            cur_h, buf = line, []
        else:
            buf.append(line)
    out.append((cur_h, "\n".join(buf).strip()))
    return [(h, b) for h, b in out if b or h]


def route(heading: str) -> str:
    if RULE_H.match(heading):
        return "rule"
    if WHY_H.match(heading):
        return "why"
    if DIAG_H.match(heading):
        return "diag"
    if LIM_H.match(heading):
        return "lim"
    return "rule"


def title_of(text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+)$", text, re.M)
    return m.group(1).strip() if m else fallback


def main() -> int:
    dmap, lmap = load_map("decisions_map.csv"), load_map("learnings_map.csv")
    topics: dict[str, dict[str, str]] = {}
    with (MAP / "methods_topics.tsv").open(encoding="utf-8") as f:
        for row in csv.reader(f, delimiter="\t"):
            if row and not row[0].startswith("#") and len(row) >= 3:
                topics[row[0]] = {"title": row[1], "triggers": row[2]}

    # topic -> {section -> [blocks]}
    acc: dict[str, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    dates: dict[str, list[str]] = defaultdict(list)
    craft: list[str] = []
    gotchas: dict[str, list[str]] = defaultdict(list)
    framework: list[tuple[str, str]] = []
    conventions: list[tuple[str, str, str]] = []
    unrouted: list[str] = []

    def ingest(path: Path, dest: str, target: str, kind: str) -> None:
        raw = path.read_text(encoding="utf-8")
        body = strip_fm(raw)
        title = title_of(body, path.stem)
        dm = re.search(r"\*\*(?:Date|Discovered|date)\*\*:?\s*([0-9]{4}-[0-9]{2}-[0-9]{2})",
                       body) or re.search(r"^date:\s*([0-9-]+)", raw, re.M)
        date = dm.group(1) if dm else "unknown"

        if dest == "framework":
            framework.append((path.name, body)); return
        if dest == "conventions":
            conventions.append((path.name, target, body)); return
        if dest == "craft":
            craft.append(f"## {title}\n\n*From `learnings/{path.name}`, "
                         f"{date}.*\n\n{demote(body, base=3)}\n")
            return
        if dest == "sources":
            gotchas[target].append(
                f"### {title}\n\n*Was `learnings/{path.name}` ({date}).*\n\n"
                f"{demote(body, base=4)}\n")
            return
        if dest != "methods":
            unrouted.append(path.name); return

        dates[target].append(f"{date} — {title} *(was `{kind}/{path.name}`)*")
        if kind == "learnings":
            acc[target]["traps"].append(
                f"### {title}\n\n*Was `learnings/{path.name}` ({date}).*\n\n"
                f"{demote(body, base=4)}\n")
            return
        # decision record: route section by section
        secs = split_sections(re.sub(r"(?m)^#[ \t]+.*$", "", body, count=1))
        first = True
        for h, b in secs:
            if not b.strip():
                continue
            slot = route(h) if h else "rule"
            label = (f"### {title}\n\n*Was `{kind}/{path.name}` ({date}).*\n\n"
                     if first and slot == "rule" else "")
            first = False
            head = (h.replace("## ", "#### ") + "\n\n") if h else ""
            acc[target][slot].append(f"{label}{head}{b}\n")

    for name, (dest, target) in sorted(dmap.items()):
        p = LEG / "decisions" / name
        if p.exists():
            ingest(p, dest, target, "decisions")
    for name, (dest, target) in sorted(lmap.items()):
        p = LEG / "learnings" / name
        if p.exists():
            ingest(p, dest, target, "learnings")

    # v1 method folders already flattened by name in 02_repath; fold their rule.md
    V1_METHODS = {"pizza_chart": "pizza-chart", "city_growth_models": "city-growth-models",
                  "structural_transformation": "structural-transformation",
                  "cordoba_shift_share_bartik": "shift-share-bartik"}
    for folder, target in V1_METHODS.items():
        rp = METH / folder / "rule.md"
        if rp.exists():
            ingest(rp, "methods", target, f"methods/{folder}")

    # ---- write topic files -------------------------------------------------
    written = []
    for slug, meta in topics.items():
        a = acc.get(slug, {})
        if not a:
            unrouted.append(f"(empty topic) {slug}")
        dts = sorted(dates.get(slug, []), reverse=True)
        newest = dts[0][:10] if dts else "unknown"
        oldest = dts[-1][:10] if dts else "unknown"
        out = [
            "---",
            f"slug: {slug}",
            "status: active",
            f'triggers: "{meta["triggers"]}"',
            f"decided: {oldest}",
            f"revised: {newest}",
            "sources_merged: " + str(len(dts)),
            "---",
            "",
            f"# {meta['title']}",
            "",
            "> **v2 consolidation note.** This file merges the v1 `decisions/`,",
            "> `methods/` and `learnings/` entries for one topic. Section prose is",
            "> **verbatim** from those records — they carried exact numbers worth",
            "> preserving. Each block names the file it came from; `git log` has the",
            "> originals.",
            "",
            "## Rule",
            "",
        ]
        out += a.get("rule", ["*No rule recorded yet.*", ""])
        out += ["", "## Why this and not the alternatives", ""]
        out += a.get("why", ["*Not recorded.*", ""])
        out += ["", "## Traps", ""]
        out += a.get("traps", ["*None recorded.*", ""])
        out += ["", "## Diagnostic counts", ""]
        out += a.get("diag", ["*Not recorded — see the implementing script.*", ""])
        out += ["", "## Scope and limits", ""]
        out += a.get("lim", ["*Not recorded.*", ""])
        out += ["", "## Changelog", ""]
        out += [f"- {d}" for d in dts] or ["- unknown — initial"]
        out += ["- 2026-08-04 — merged into one topic file (r2p v2)", ""]
        (METH / f"{slug}.md").write_text("\n".join(out) + "\n", encoding="utf-8")
        written.append((slug, len(dts)))

    # ---- _craft.md ---------------------------------------------------------
    craft_doc = [
        "---", "slug: _craft", "status: active",
        'triggers: "rolling isclose log-mean cagr endpoint differencing control '
        'multiples proxy string-gate shapely dplyr summarise"',
        "---", "",
        "# Analysis craft — cross-cutting numerical and reasoning traps", "",
        "One file, deliberately. These traps have no single methodological home, and",
        "giving each its own file is how v1 grew a 70-entry directory. If an entry",
        "here becomes specific to one method, move it into that topic's `## Traps`.",
        "",
    ] + craft
    (METH / "_craft.md").write_text("\n".join(craft_doc) + "\n", encoding="utf-8")

    # ---- source gotchas ----------------------------------------------------
    src_written = []
    for stem, blocks in sorted(gotchas.items()):
        p = SRC / f"{stem}.md"
        existing = p.read_text(encoding="utf-8") if p.exists() else (
            f"# {stem}\n\n*Created by the r2p v2 merge to hold gotchas that had no "
            f"source doc. Fill in What-it-gives-you / Access / Headline anchor.*\n")
        add = ("\n\n## Gotchas\n\n"
               "*Merged from v1 `learnings/` by the r2p v2 consolidation — a trap that "
               "bites anyone touching this source belongs with the source.*\n\n"
               + "\n".join(blocks))
        if "## Gotchas" not in existing:
            p.write_text(existing.rstrip() + add, encoding="utf-8")
        src_written.append((stem, len(blocks), p.exists()))

    # ---- staged for the r2p repo ------------------------------------------
    fn_dir = ROOT / "plan/plan-r2p-v2-consolidation/for-r2p/field-notes"
    fn_dir.mkdir(parents=True, exist_ok=True)
    for name, body in framework:
        (fn_dir / name).write_text(body, encoding="utf-8")
    cv_dir = ROOT / "plan/plan-r2p-v2-consolidation/for-project-conventions"
    cv_dir.mkdir(parents=True, exist_ok=True)
    for name, target, body in conventions:
        (cv_dir / f"{target}__{name}").write_text(body, encoding="utf-8")

    # ---- methods INDEX -----------------------------------------------------
    idx = ["# Methods index", "",
           "One file per methodological object. Each merges what v1 split across",
           "`decisions/` (why), `methods/` (the rule) and `learnings/` (the traps).",
           "", "| Topic | Title | v1 records merged |", "|---|---|--:|"]
    for slug, n in sorted(written):
        idx.append(f"| [`{slug}`]({slug}.md) | {topics[slug]['title']} | {n} |")
    idx += ["| [`_craft`](_craft.md) | Cross-cutting numerical and reasoning traps "
            f"| {len(craft)} |", "",
            "`triggers:` frontmatter in each file feeds the retrieve-learnings hook.",
            "Source-specific gotchas live with the source in `research/sources/`."]
    (METH / "INDEX.md").write_text("\n".join(idx) + "\n", encoding="utf-8")

    rep = ["# Methods merge report", "",
           f"- topic files written: **{len(written)}**",
           f"- v1 records merged into topics: **{sum(n for _, n in written)}**",
           f"- craft entries: **{len(craft)}**",
           f"- source docs given a `## Gotchas` section: **{len(src_written)}** "
           f"({sum(n for _, n, _ in src_written)} learnings)",
           f"- framework field-notes staged for r2p: **{len(framework)}**",
           f"- project-convention additions staged: **{len(conventions)}**",
           f"- unrouted: **{len(unrouted)}**", ""]
    if unrouted:
        rep += ["## Unrouted", ""] + [f"- {u}" for u in unrouted]
    rep += ["", "## Records per topic", "", "| topic | records |", "|---|--:|"] + \
           [f"| {s} | {n} |" for s, n in sorted(written, key=lambda x: -x[1])]
    (MAP / "methods_merge_report.md").write_text("\n".join(rep) + "\n", encoding="utf-8")
    print("\n".join(rep[:12]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
