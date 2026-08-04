#!/usr/bin/env python3
"""
Inputs:  research/evidence/*.md, research/evidence/INDEX.md, decisions/*.md, learnings/*.md,
         learnings/index.yaml, deliverables/**, deliverables/decks/**
Outputs: plan/plan-r2p-v2-consolidation/mapping/evidence_audit.csv
         plan/plan-r2p-v2-consolidation/mapping/learnings_audit.csv
         plan/plan-r2p-v2-consolidation/mapping/decisions_audit.csv
         plan/plan-r2p-v2-consolidation/mapping/summary.md
Seed:    n/a
Env:     python3 stdlib only

Phase 0 of plan-r2p-v2-consolidation. Read-only inventory: emits the facts the
migration mapping tables are authored against. No file is moved or edited.
"""
from __future__ import annotations

import csv
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "plan/plan-r2p-v2-consolidation/mapping"
OUT.mkdir(parents=True, exist_ok=True)

EVID_RE = re.compile(r"#(\d{1,3})\b")
BANNER_RE = re.compile(r"⚠|RETIRED|WITHDRAWN|RETRACT|SUPERSEDED", re.I)
VERDICT_RE = re.compile(
    r"\b(CONFIRM(?:S|ED)?|REFUT(?:E|ES|ED)|REJECT(?:S|ED)?|PROVES?|VERDICT|"
    r"DOWNGRADED|DISPROV|falsifi)\w*\b", re.I
)


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


# ---------------------------------------------------------------- evidence ---
ev_dir = ROOT / "evidence"
ev_files = sorted(p for p in ev_dir.glob("*.md") if p.name != "INDEX.md")

# citation counts from the deliverable/slide/plan surface (what a revision breaks)
consumer_text = []
for d in ("deliverables", "slides", "plan"):
    for p in (ROOT / d).rglob("*.md"):
        consumer_text.append(read(p))
consumer_cites = Counter(EVID_RE.findall("\n".join(consumer_text)))

index_txt = read(ev_dir / "INDEX.md")
index_rows = {}
for line in index_txt.splitlines():
    if not line.startswith("| "):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) < 3 or not re.fullmatch(r"\d{1,3}", cells[0]):
        continue
    index_rows[str(int(cells[0]))] = cells[1]

ev_rows = []
for p in ev_files:
    m = re.match(r"(\d{1,3})_(.+)\.md$", p.name)
    if not m:
        continue
    eid, slug = str(int(m.group(1))), m.group(2)
    body = read(p)
    cites = sorted({c for c in EVID_RE.findall(body) if c != eid}, key=int)
    ev_rows.append(
        {
            "id": eid,
            "slug": slug,
            "file": p.name,
            "bytes": p.stat().st_size,
            "cited_by_consumers": consumer_cites.get(eid, 0),
            "cites": " ".join(f"#{c}" for c in cites),
            "n_cites": len(cites),
            "has_retraction_banner": int(bool(BANNER_RE.search(body[:2000]))),
            "verdict_words": len(VERDICT_RE.findall(body)),
            "index_title_chars": len(index_rows.get(eid, "")),
            "tier": "",  # filled below
        }
    )

# duplicate ids
dupes = {k for k, v in Counter(r["id"] for r in ev_rows).items() if v > 1}

# Tier 1 = full Measured/Reading rewrite. Per plan §3 the target is ~40 docs, so
# the rule is a RANK cut, not an absolute count: the top TIER1_RANK docs by
# consumer citations, unioned with every doc carrying a retraction banner (a
# retraction has to be re-stated as machine-readable status, so it cannot be
# deferred to tier 2). Absolute thresholds were tried first and admitted 145/151
# — with citation counts running 80-180 on this corpus, any fixed bar is either
# everything or nothing.
TIER1_RANK = 40

ev_cited_by = Counter()
for r in ev_rows:
    for c in r["cites"].split():
        ev_cited_by[c.lstrip("#")] += 1
for r in ev_rows:
    r["cited_by_evidence"] = ev_cited_by.get(r["id"], 0)

top_ids = {
    r["id"]
    for r in sorted(ev_rows, key=lambda r: -r["cited_by_consumers"])[:TIER1_RANK]
}
for r in ev_rows:
    tier1 = r["id"] in top_ids or r["has_retraction_banner"]
    r["tier"] = "1-rewrite" if tier1 else "2-frontmatter"

cols = [
    "id", "slug", "file", "tier", "cited_by_consumers", "cited_by_evidence",
    "n_cites", "has_retraction_banner", "verdict_words", "index_title_chars",
    "bytes", "cites",
]
with (OUT / "evidence_audit.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
    w.writeheader()
    w.writerows(sorted(ev_rows, key=lambda r: (-r["cited_by_consumers"], int(r["id"]))))

# --------------------------------------------------------------- learnings ---
le_dir = ROOT / "learnings"
le_rows = []
for p in sorted(le_dir.glob("*.md")):
    if p.name == "README.md":
        continue
    body = read(p)
    has_fm = body.startswith("---")
    title = ""
    if has_fm:
        mt = re.search(r"^title:\s*(.+)$", body, re.M)
        title = mt.group(1).strip() if mt else ""
    else:
        mt = re.search(r"^#\s+(.+)$", body, re.M)
        title = mt.group(1).strip() if mt else ""
    le_rows.append(
        {
            "file": p.name,
            "has_frontmatter": int(has_fm),
            "bytes": p.stat().st_size,
            "title": title[:200],
            "destination": "",  # authored by hand in learnings_map.csv
        }
    )
with (OUT / "learnings_audit.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=["file", "has_frontmatter", "bytes", "destination", "title"])
    w.writeheader()
    w.writerows(le_rows)

# --------------------------------------------------------------- decisions ---
de_dir = ROOT / "decisions"
de_rows = []
for p in sorted(de_dir.glob("*.md")):
    if p.name == "README.md":
        continue
    body = read(p)
    mt = re.search(r"^#\s+(.+)$", body, re.M)
    ms = re.search(r"^\*\*Status:?\*\*:?\s*(.+)$", body, re.M)
    de_rows.append(
        {
            "file": p.name,
            "bytes": p.stat().st_size,
            "status_field": (ms.group(1).strip() if ms else "MISSING")[:60],
            "has_invalidate_section": int("would invalidate" in body.lower()),
            "has_alternatives": int(bool(re.search(r"alternativ", body, re.I))),
            "title": (mt.group(1).strip() if mt else "")[:200],
            "method_topic": "",  # authored by hand in methods_map.csv
        }
    )
with (OUT / "decisions_audit.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(
        f,
        fieldnames=["file", "bytes", "status_field", "has_invalidate_section",
                    "has_alternatives", "method_topic", "title"],
    )
    w.writeheader()
    w.writerows(de_rows)

# ----------------------------------------------------------------- summary ---
n_t1 = sum(1 for r in ev_rows if r["tier"] == "1-rewrite")
idx_bytes = (ev_dir / "INDEX.md").stat().st_size
lines = [
    "# Phase 0 audit — inventory",
    "",
    f"- evidence docs: **{len(ev_rows)}**  ({sum(r['bytes'] for r in ev_rows)/1e6:.2f} MB)",
    f"- research/evidence/INDEX.md: **{idx_bytes/1024:.0f} KB**; "
    f"longest index title: **{max(r['index_title_chars'] for r in ev_rows)} chars**; "
    f"median: **{sorted(r['index_title_chars'] for r in ev_rows)[len(ev_rows)//2]}**",
    f"- duplicate evidence ids: **{', '.join('#'+d for d in sorted(dupes, key=int)) or 'none'}**",
    f"- docs with a retraction banner in the first 2 KB: "
    f"**{sum(r['has_retraction_banner'] for r in ev_rows)}**",
    f"- verdict words across the corpus: "
    f"**{sum(r['verdict_words'] for r in ev_rows)}** in {sum(1 for r in ev_rows if r['verdict_words'])} docs",
    f"- **Tier 1 (full rewrite): {n_t1}**  ·  Tier 2 (frontmatter+index only): {len(ev_rows)-n_t1}",
    "",
    f"- learnings: **{len(le_rows)}**, of which **{sum(r['has_frontmatter'] for r in le_rows)}** "
    "carry the documented YAML frontmatter",
    f"- decisions: **{len(de_rows)}**, of which "
    f"**{sum(r['has_invalidate_section'] for r in de_rows)}** have the required "
    "'what would invalidate' section and "
    f"**{sum(1 for r in de_rows if r['status_field']=='MISSING')}** have no Status field",
    "",
    "## Most-cited evidence (consumer surface: deliverables/, deliverables/decks/, plan/)",
    "",
    "| id | cited | slug |",
    "|---|--:|---|",
]
for r in sorted(ev_rows, key=lambda r: -r["cited_by_consumers"])[:20]:
    lines.append(f"| #{r['id']} | {r['cited_by_consumers']} | {r['slug']} |")
(OUT / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))
