# Evidence-doc digesting is 22–96% lossy per doc, and the loss tracks the doc's Findings-header style

**Encoded in:** `.claude/conventions/evidence.md` § The `Measured` / `Reading` split is the load-bearing rule — as the machine-readability argument for *why* the headers are fixed, plus the measure-retention-per-doc rule.

**Discovered:** 2026-07-31, `plan-narrativa-final-memo` Phase 1, sub-phase 1a.

## The gotcha

`plan/plan-narrativa-final-memo/digest_evidence.py` compresses `research/evidence/*.md` to
title + headline + findings + full caveats + chart paths. Its measured corpus-wide
retention is **42%** (240,037 → 101,024 words), and the phase file cites that number
as the safety argument for digest-reading instead of full-reading.

**The 42% is an average over a bimodal distribution and it is not safe to plan
against.** Measured per doc on sub-phase 1a's 33 docs, retention ranges **22% to 96%**,
and the low end is concentrated in the docs carrying the most numbers.

## Why — the mechanism

The script captures findings two ways:

1. `###` headers — the **whole line** is kept.
2. Under a `## Findings`-class header, any line matching `line.startswith("**")` — this
   captures **only the first physical line of a hard-wrapped paragraph.**

So a doc that writes findings as `### 1. Argentine maize yield falls 5.3% since 2011`
survives intact. A doc that writes

```markdown
## Findings

**1. Aggregate labour productivity FELL, 2004–2024.** Córdoba's market-economy
`P_agg` went 0.0376 (2004) → 0.0362 (2011) → 0.0336 (2024), CAGR **−0.56%/yr**.
```

comes back as **only the first line** — headline kept, every number dropped.

Docs whose findings live under `## Findings` / `## Finding` / `## Result` with **no
`###` children at all** come back with those sections **completely empty**. In 1a that
hit `#51`, `#90`, `#95` and `#12`.

## Measured, 1a's 33 docs

| Retention | Docs |
|---|---|
| **22–35%** | `#107` (22%), `#40` (30), `#121` (30), `#142` (30), `#03` (30), `#09` (31), `#120` (33), `#90` (34), `#06` (35), `#10` (35) |
| 36–50% | `#27`, `#07`, `#42`, `#02`, `#95`, `#51`, `#88`, `#05`, `#12`, `#139`(MOI), `#25`, `#70` |
| 55–96% | `#79`, `#119`(sec), `#08`, `#11`, `#92`, `#26`, `#98`, `#91`, `#99`, `#93`, `#55` |

**The style correlates with the theme, which is what makes this a trap rather than
noise.** The agro docs (`#128`–`#138`) mostly use `###` claim headers, so sub-phase 1b
digest-read 14 of 15 docs and lost little. The macro/VAB/shift-share docs
overwhelmingly use `## Findings` + bolded numbered paragraphs, so 1a's digest amputated
`#107`'s entire three-regime result table, `#121`'s CAGR and 87%-within-sector split,
and `#90`'s three Córdoba findings.

## How to apply

**Measure retention per doc before deciding how to read, not after.** Three lines:

```sh
for f in $(cat filelist.txt); do
  raw=$(wc -w < "$f"); dig=$(python3 plan/.../digest_evidence.py "$f" | wc -w)
  printf "%3d%% %s\n" $(( dig * 100 / raw )) "$(basename $f)"
done | sort -n
```

Then **full-read everything under ~50%** and digest-read the rest. On 1a that is 22
full reads and 11 digests — affordable, and it removes the amputation risk entirely.

**Cheaper structural proxy if you don't want to run the loop:**
`grep -c '^### ' <doc>` — a doc with zero `###` headers will lose its findings
wholesale.

**Do not "fix" the script mid-phase.** A parallel sub-phase reading the same corpus
with a changed digest produces fragments that are not comparable, and the append-only
convention on `research/evidence/` means the docs themselves cannot be reformatted. Measure and
route instead.

Related: [[parallel-phase-fanout-hygiene]] (a parallel agent obeys its phase file, not
the handoff — so a correction like this belongs in the phase file).
