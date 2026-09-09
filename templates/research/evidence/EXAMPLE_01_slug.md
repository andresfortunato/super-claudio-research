---
id: 1
headline: <the measurement in <=120 chars, no verdict>
status: live                 # live | revised | retired
supersedes: []
superseded_by: []
date: YYYY-MM-DD
unit: province               # nation | province | dpto | metro | fua | sector | firm
geography: <the concrete geography, e.g. "Gran Córdoba (EPH aglomerado 13)">
period: YYYY–YYYY            # the ANALYSIS WINDOW. `unknown` beats a guess.
kind: measurement            # measurement | comparison | decomposition | scenario | null-result
confidence: high             # high | medium | low
data: []                     # research/sources/ stems
methods: []                  # research/methods/ slugs this rests on
# OPTIONAL — the charts/tables THIS doc writes up. Absent is normal and means
# "not stated", never "no charts exist". Hand-authored or absent, NEVER inferred:
# a wrong binding is worse than a missing one. Uncomment and replace with real
# paths; lint invariant 12 FAILs on a path that does not exist, so the
# placeholders below must not ship as live YAML.
# artifacts:
#   - output/<theme>/<chart>.png
#   - output/<theme>/<table>.csv
---

# <Headline measurement — the same text as the frontmatter headline>

## Measured

| Quantity | Value | Comparison | Cell |
|---|---|---|---|
| <what> | <number> | <against what> | `output/…/file.csv:L14` |

<!-- Numbers only. No "confirms", "refutes", "proves", "VERDICT". Every row
     re-derivable from ## Provenance. 3-8 rows: fewer is thin, more is padding. -->

## Reading

<2–5 sentences. The author's interpretation, and the ONLY place a verdict may
appear. If it depends on a methodology call, link the research/methods/ doc.>

## Scope

<What this does NOT establish. Unit and period limits. Known confounds. Why a
differently-scoped number elsewhere is not a contradiction.>

## Provenance

- **Script:** `analysis/<theme>/<script>`
- **Inputs:** …
- **Charts:** `output/<theme>/…png`
- **Seed:** …
