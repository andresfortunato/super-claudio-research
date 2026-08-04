# <Country> diagnostic — <topic, e.g. growth slowdown 2015–2025>

<!--
Concrete claim, not a topic. Bad: "Cambodia's economy". Good: "Cambodia's
post-2015 productivity slowdown and its sectoral composition". The title is
the headline finding; if you can't write it now, draft the analysis first
and come back.
-->

**Author**: <name>
**Date**: YYYY-MM-DD
**Status**: draft | under review | final
**Audience**: <e.g. internal Lab + counterpart researcher at <institution>>
**Length**: ~<N> words body + appendices
**Linked decision records**: `research/methods/<topic>.md`, ...
**Linked evidence**: `research/evidence/NN_<slug>.md`, ...

---

## Executive summary

<!--
≤500 words. Three or four bulleted findings, each one sentence and
quantified. The reader who only reads this section should walk away with the
diagnosis. Save framing for the body.

Pattern per bullet:
- **<finding>**: <number/comparison>. <one-sentence implication>.
-->

- **<finding 1>**: <specific number or comparison>. <implication>.
- **<finding 2>**: <specific number or comparison>. <implication>.
- **<finding 3>**: <specific number or comparison>. <implication>.

The remainder of this memo develops the evidence and discusses what these
findings do and do not establish.

---

## 1. Context and question

<!--
What is the country's situation as the diagnostic begins? What specific
question is this memo answering? Half a page; do not retread the country's
full economic history.

End this section with a one-paragraph statement of the diagnostic question.
The question is concrete and answerable, not "How is the economy doing?"
-->

## 2. Data and method

<!--
One subsection per major data source. Cite vintage, units, deflator,
sample frame, known caveats. Cross-link to the relevant decision record
(research/methods/YYYY-MM-DD_<deflator-or-source-choice>.md) for any non-obvious
choice.

Method subsection: the analytic strategy in 1–3 paragraphs. Identification
or measurement choices that aren't obvious go in their own decision records.
-->

### 2.1 Data sources
- **<dataset>**: <vintage, units, sample, key variable used>. See
  `research/methods/<topic>.md`.
- **<dataset>**: ...

### 2.2 Method
<!-- 1–3 paragraphs. Reference decision records for choices. -->

## 3. Stylized facts

<!--
2–4 charts establishing the country's situation along the dimensions the
diagnostic touches. These are the "look at the data" charts: levels, trends,
comparisons. Save the diagnostic-specific analysis for the next section.

Each chart: a one-sentence assertion as the figure caption (NOT "Figure 1:
GDP per capita over time" — instead "Figure 1: <Country>'s GDP per capita
fell behind the regional median after 2015, reversing a 20-year
convergence."). Below the chart, 2–3 sentences elaborating, citing
data source.
-->

**Figure 1: <assertion-style title>.**
![Figure 1](../output/<chart>.png)
*<2–3 sentences. Source: <dataset>. See `research/evidence/NN_<slug>.md`.*

**Figure 2: <assertion-style title>.**
...

## 4. Diagnostic findings

<!--
This is the core. One subsection per finding. Each subsection:
1. Claim (one sentence).
2. Evidence (chart, table, regression — show, don't tell).
3. What this rules out / does not rule out.
4. Robustness (at least one alternative specification, deflator, sample, or
   vintage, reported INLINE, not deferred).
-->

### 4.1 <Finding 1 — concrete claim>

<!-- Claim sentence first. Then evidence. Then alternatives ruled in/out. -->

**Robustness.** <Alternative spec / sample / deflator>. Headline number
moves from <X> to <Y> (<delta> change). The qualitative finding is /
is not preserved.

### 4.2 <Finding 2>
...

### 4.3 <Finding 3>
...

## 5. What this does and does not establish

<!--
Scope honesty. Two short subsections:
- What we can claim: the findings, with their hedges.
- What we cannot claim: the questions the data cannot answer with this
  design, the counterfactuals we did not test, the populations we did not
  observe.

This section is what separates a diagnostic from a sales pitch.
-->

### 5.1 What the evidence supports
- <claim, with the hedge>
- <claim, with the hedge>

### 5.2 What this analysis does not establish
- <out-of-scope question or unobserved counterfactual>
- <known data limitation that constrains inference>

## 6. Implications

<!--
1–2 paragraphs. What does this diagnosis suggest for the next analytic
question or the engagement's research agenda? Resist the temptation to write
policy recommendations here — that's the briefing's job, not the
diagnostic's.
-->

## 7. Open questions and next steps

<!--
3–6 bullets. Concrete, not aspirational ("estimate sectoral elasticities
using XYZ panel" — not "deepen our understanding of structural
transformation").
-->

- <next step>
- <next step>

---

## Appendix A: Methodology details

<!--
Anything a peer reviewer would want to verify but a primary reader doesn't
need: regression tables, sensitivity analyses beyond the one in section 4,
data-cleaning notes, code references.
-->

## Appendix B: Robustness

<!--
The full robustness battery. Section 4 reports the headline alternative
spec; this appendix reports the rest.
-->

## Appendix C: Data provenance

<!--
For each dataset: source URL, vintage retrieved, retrieval date, file path
in `data/raw/`, transformations applied (with script paths), any manual
adjustments. This is what makes the analysis reproducible by someone else
in two years.
-->

| Dataset | Source | Vintage | Retrieved | Raw path | Pipeline script |
|---------|--------|---------|-----------|----------|-----------------|
| ...     | ...    | ...     | ...       | ...      | ...             |

## References

<!-- Standard academic references, papers and reports cited in the body. -->
