# <Memo title — concrete claim or question, not a topic>

<!--
Bad: "Notes on industrial policy in Country X"
Good: "Country X's post-2010 industrial policy: which firms benefited,
and did the targeting criteria predict it?"

The title can be more exploratory than a country-diagnostic-memo title,
but it should still be specific. A topic ("industrial policy") becomes a
question ("did the targeting criteria predict it?"). If you cannot write
the title yet, the memo's question is not yet sharp.
-->

**Author(s)**: <names>
**Date**: YYYY-MM-DD (started) | YYYY-MM-DD (last revised)
**Status**: in progress | draft for peer review | settled
**Audience**: internal Lab + <other researchers, if any>
**Length**: ~<N> words
**Linked decision records**: `research/methods/<topic>.md`, ...
**Linked evidence**: `research/evidence/NN_<slug>.md`, ...
**Linked wiki pages**: `research/wiki/concepts/<slug>.md`, ...

---

## Summary

<!--
~300 words. The memo's spine in compact form. Provisional is fine; mark
speculative findings explicitly. A reader of this section alone should
walk away with: the question, the approach, the headline finding(s),
what's settled vs still uncertain.

This section is what gets lifted into external deliverables (with
revisions). Write it as if it will be quoted.
-->

## 1. Question and motivation

<!--
1–2 pages. What question is this memo investigating, and why does it
matter for the engagement (or for the Lab's broader research agenda)?

This section is allowed to show the seams. If the question evolved during
the analysis, say so: "I started with question A; the data led to question
B, which is what this memo answers."
-->

### 1.1 The question
<!-- Concrete, answerable. -->

### 1.2 Why it matters
<!-- 1–3 paragraphs. Engagement context, theoretical relevance, or both. -->

### 1.3 What this memo argues
<!-- The argumentative spine in 3–4 sentences. -->

## 2. Prior work and our angle

<!--
What does the existing literature (academic, gray, internal Lab memos)
say? What is the gap or under-explored angle this memo addresses? Engage
with the literature, don't just cite it — every citation should be doing
work.
-->

## 3. Data and method

<!--
Same shape as the country-diagnostic memo's section 2, but allowed to be
more provisional. Decision records still link out for non-obvious choices;
the memo can also flag choices it has not yet made ("Pending: choice of
deflator — see `research/methods/<topic>.md` once filed").
-->

### 3.1 Data sources
- **<dataset>**: <vintage, units, sample, key variable used>.
- **<dataset>**: ...

### 3.2 Method
<!-- 2–5 paragraphs. Include identification or measurement strategy. -->

### 3.3 Choices and decision records
- See `research/methods/<topic>.md`.
- Pending: <choice>. To be resolved when <condition>.

## 4. Findings

<!--
One subsection per finding. Findings can be a mix of:
- Settled findings (similar in shape to the country-diagnostic memo).
- Provisional findings, explicitly marked.
- Negative findings (we expected X; we did not find X).

Negative findings are valuable in internal memos and rare elsewhere.
Report them.
-->

### 4.1 <Finding 1>
<!-- Claim. Evidence. Hedges. -->

### 4.2 <Finding 2 — provisional>
**Speculative — to be tested.** <Claim>. <What evidence we have, what's
missing.> <What would confirm or falsify this.>

### 4.3 <Negative finding — what we expected and did not see>
<!-- Hypothesis we entered with, what we found, why the prior was wrong. -->

## 5. Discussion

<!--
1–3 pages. What do these findings mean? How do they fit with prior
literature? What alternative interpretations does the author NOT favor,
and why?

The discussion is where the author's voice is most welcome. Speculation
is fine here so long as it is labeled.
-->

### 5.1 Implications for the engagement
<!-- What does this change about the next analytic move, or the framing
of the diagnostic memo this feeds? -->

### 5.2 Implications for the broader question
<!-- If the memo touches a question the Lab cares about beyond this
engagement, name it. -->

### 5.3 Alternative interpretations weighed and rejected
<!-- Where reasonable readers might disagree; the author's reasoning. -->

## 6. What this memo settles vs. leaves open

<!--
Two short subsections. Be honest about the boundary between the two.
-->

### 6.1 Settled
- <claim, with hedge>
- <claim, with hedge>

### 6.2 Open
<!-- Concrete future work. Each bullet names a dataset, comparison, or
analytic move that would resolve the question. NOT aspirational
("explore further"); operational ("estimate the X elasticity using the
Y panel restricted to Z"). -->

- <next analytic move>
- <next analytic move>

## 7. Pointers

<!--
This memo is a node in the project's knowledge graph. List pointers
out and pointers in.
-->

### 7.1 This memo builds on
- `research/evidence/NN_<slug>.md`
- `research/wiki/concepts/<slug>.md`
- prior memo `deliverables/<slug>/memo.md`

### 7.2 This memo feeds into
- planned diagnostic: `deliverables/<country-diagnostic>/`
- planned briefing: `deliverables/<briefing>/`
- wiki synthesis: `research/wiki/synthesis/<slug>.md` (to be authored when ≥3
  sources converge)

---

## Appendix A: Methodological details

<!-- Anything a peer would want to verify but a primary reader doesn't
need: full regression tables, sensitivity analyses, robustness battery,
data-cleaning notes. -->

## Appendix B: Data provenance

| Dataset | Source | Vintage | Retrieved | Raw path | Pipeline script |
|---------|--------|---------|-----------|----------|-----------------|
| ...     | ...    | ...     | ...       | ...      | ...             |

## References

<!-- Standard academic references, papers and reports cited in the body. -->

<!--
## Update: YYYY-MM-DD

When the memo's findings need updating after the original draft has
circulated, append a dated `## Update:` section here rather than
editing the body of the memo in place. One section per revision,
in chronological order. Each addendum says what changed and why,
without erasing the prior version — the memo's history is part of
what makes it useful six months later.

A typical addendum has three parts:

**What's new.** New data, a re-estimation, a corrected mistake, a
peer-review comment that landed.

**What this changes in the original argument.** Which findings
above are upgraded, downgraded, or superseded. Be specific — name
the section / subsection.

**What still stands.** The findings the addendum does NOT touch
remain authoritative as written.

Successive updates stack in chronological order. The body of the
memo is not edited (except for typo fixes and broken-link repairs);
the dated addenda carry the revisions.
-->

