#!/usr/bin/env python3
"""
Inputs:  research/evidence/*.md, research/evidence/INDEX.md,
         plan/plan-r2p-v2-consolidation/mapping/headlines.tsv (authored)
Outputs: research/evidence/*.md (frontmatter prepended, banners normalised),
         research/evidence/INDEX.md (rebuilt, capped),
         research/evidence/.next-id
Seed:    none
Env:     python3 stdlib only

Phase 3 of plan-r2p-v2-consolidation.

Scope keys (unit / geography / period / kind / confidence) are inferred by the
heuristics below and are meant to be reviewed, not trusted blindly — they are a
starting state for a corpus that had no scope fields at all, not a measurement.
Headlines are NOT inferred: truncating a 200-char title produces garbage, so
they are authored in mapping/headlines.tsv and this script only applies them.

--check reports without writing.
"""
from __future__ import annotations

import csv
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                           capture_output=True, text=True, check=True).stdout.strip())
EV = ROOT / "research/evidence"
MAP = ROOT / "plan/plan-r2p-v2-consolidation/mapping"

BANNER_RE = re.compile(r"⚠|RETIRED|WITHDRAWN|RETRACTED", re.I)
YEARS_RE = re.compile(r"\b(19[5-9]\d|20[0-4]\d)\b")

# --- scope heuristics ------------------------------------------------------
# ordered most-specific-first; first hit wins
UNIT_RULES = [
    ("fua", r"\bFUA\b|functional urban area|eFUA"),
    ("metro", r"aglomerad|Gran Córdoba|metro\b|metropolitan|GBA|CABA\b|city|ciudad"),
    ("dpto", r"departament|\bdpto\b|municipi|localidad|comuna"),
    ("sector", r"\bletra\b|CIIU|CLAE|CAES|sector|industr|rubro|cadena"),
    ("province", r"provinci|24 jurisdic|PBG|VAB provincial"),
    ("nation", r"nacional|national|Argentina|país|PIB\b"),
]
KIND_RULES = [
    ("decomposition", r"shift-share|decomposit|Oaxaca|Bartik|descomposi"),
    ("scenario", r"scenario|upside|escenario|target|×5|x5 |multiplier|potential"),
    ("null-result", r"\bnull\b|no evidence|refut|not confirmed|does not"),
    ("comparison", r"\bvs\b|versus|peer|benchmark|ranking|rank \d|comparat"),
]
CONF_RULES = [
    ("low", r"\bproxy\b|modelled|modeled|thin sample|not measured|inferred not measured|"
            r"unusable|derived ="),
    ("medium", r"medium conf|descriptive|caveat|emergencia|no apples-to-apples|"
               r"single-source|pseudo-replication"),
]


def infer(body: str) -> dict[str, str]:
    head = body[:6000]
    unit = next((u for u, rx in UNIT_RULES if re.search(rx, head, re.I)), "province")
    kind = next((k for k, rx in KIND_RULES if re.search(rx, head, re.I)), "measurement")
    conf = next((c for c, rx in CONF_RULES if re.search(rx, head, re.I)), "high")
    yrs = sorted({int(y) for y in YEARS_RE.findall(head)})
    period = f"{yrs[0]}–{yrs[-1]}" if len(yrs) > 1 else (str(yrs[0]) if yrs else "n/a")
    status = "revised" if BANNER_RE.search(head[:2500]) else "live"
    return {"unit": unit, "kind": kind, "confidence": conf,
            "period": period, "status": status}


def cited(body: str, own: str) -> list[str]:
    return sorted({c for c in re.findall(r"#(\d{1,3})\b", body) if c != own}, key=int)


def main() -> int:
    check = "--check" in sys.argv
    headlines: dict[str, str] = {}
    hl_path = MAP / "headlines.tsv"
    if hl_path.exists():
        with hl_path.open(encoding="utf-8") as f:
            for row in csv.reader(f, delimiter="\t"):
                if len(row) >= 2 and not row[0].startswith("#"):
                    headlines[row[0].strip()] = row[1].strip()

    # unit and period are AUTHORED, not inferred. The heuristics were tried and
    # produced "metro | 1960-2026" for a 24-province panel -- a confidently wrong
    # scope key manufactures exactly the false contradictions v2 exists to close,
    # so anything not in scope.tsv falls back to `unknown` rather than a guess.
    scope: dict[str, tuple[str, str]] = {}
    sc_path = MAP / "scope.tsv"
    if sc_path.exists():
        with sc_path.open(encoding="utf-8") as f:
            for row in csv.reader(f, delimiter="\t"):
                if len(row) >= 3 and not row[0].startswith("#"):
                    scope[row[0].strip()] = (row[1].strip(), row[2].strip())

    docs = sorted(p for p in EV.glob("*.md") if p.name != "INDEX.md")
    rows, missing, overlong = [], [], []
    for p in docs:
        m = re.match(r"(\d{1,3})_(.+)\.md$", p.name)
        if not m:
            continue
        eid = str(int(m.group(1)))
        body = p.read_text(encoding="utf-8")
        # Idempotent: an existing frontmatter block is STRIPPED and rebuilt, not
        # skipped. Skipping made the first run's heuristic scope keys permanent.
        if body.startswith("---\n"):
            parts = body.split("---\n", 2)
            if len(parts) == 3:
                body = parts[2].lstrip("\n")

        sc = infer(body)
        unit, period = scope.get(p.name, ("unknown", "unknown"))
        sc["unit"], sc["period"] = unit, period
        sc["scope_authored"] = p.name in scope
        key = p.name
        hl = headlines.get(key) or headlines.get(eid)
        if not hl:
            missing.append(p.name)
            h1 = re.search(r"^#\s+(.+)$", body, re.M)
            hl = (h1.group(1).strip() if h1 else p.stem)
        if len(hl) > 120:
            overlong.append(f"{p.name}: {len(hl)}")

        date = re.search(r"\*\*Date\*\*:?\s*([0-9]{4}-[0-9]{2}(?:-[0-9]{2})?)", body)
        fm = [
            "---",
            f"id: {eid}",
            f"headline: {hl}",
            f"status: {sc['status']}",
            "supersedes: []",
            "superseded_by: []",
            f"date: {date.group(1) if date else 'unknown'}",
            f"unit: {sc['unit']}",
            "geography: Córdoba",
            f"period: {sc['period']}",
            f"kind: {sc['kind']}",
            f"confidence: {sc['confidence']}",
            f"cites: [{', '.join(cited(body, eid))}]",
            f"scope_authored: {str(sc['scope_authored']).lower()}   "
            "# unit/period hand-checked against the doc; kind/confidence still heuristic",
            "---",
            "",
        ]
        if not check:
            p.write_text("\n".join(fm) + body, encoding="utf-8")
        rows.append({"id": eid, "file": p.name, "headline": hl, **sc})

    # ---- rebuild the index -------------------------------------------------
    rows.sort(key=lambda r: int(r["id"]))
    idx = [
        "# Evidence Index",
        "",
        "One row per evidence doc. **The headline is capped at 120 characters** —",
        "caveats, findings lists and retraction prose live in the doc, never here.",
        "`status: revised` means part of the doc is retired; open it for the banner.",
        "",
        "Two findings only contradict each other if their **unit and period overlap**.",
        "Start from `research/claims.md`, not from this table.",
        "",
        "| # | Headline | Unit | Period | Status | Conf | File |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        idx.append(f"| {r['id']} | {r['headline']} | {r['unit']} | {r['period']} "
                   f"| {r['status']} | {r['confidence']} | [{r['file']}]({r['file']}) |")
    idx_text = "\n".join(idx) + "\n"
    if not check:
        (EV / "INDEX.md").write_text(idx_text, encoding="utf-8")
        nxt = max(int(r["id"]) for r in rows) + 1
        (EV / ".next-id").write_text(f"{nxt}\n", encoding="utf-8")

    print(f"docs: {len(rows)}")
    print(f"index size: {len(idx_text)/1024:.1f} KB")
    print(f"headlines authored: {len(rows)-len(missing)}  missing: {len(missing)}")
    print(f"overlong (>120): {len(overlong)}")
    if missing:
        print("\nMISSING headlines (first 40):")
        for x in missing[:40]:
            print("  ", x)
    if overlong:
        print("\nOVERLONG:", *overlong[:20], sep="\n  ")
    return 0


if __name__ == "__main__":
    sys.exit(main())
