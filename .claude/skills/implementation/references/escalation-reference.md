# Escalation Reference

When to stop and surface an issue to the user during plan implementation.

## The Severity Test

Before escalating, ask: **does this affect the plan's direction or just its details?**

- **Direction**: which methodology to use, what identification strategy to apply, whether a phase is still valid, what the deliverable's headline finding should be → escalate
- **Details**: which package version, what helper function to extract, which intermediate filename to use → handle inline, note it

The escalate-vs-handle test: would the user want to make this decision themselves, or would they say "just handle it"?

## Triggers

### 1. Contradicted Assumption

Something you discover directly contradicts a decision in plan.md.

**Example**: The plan says "use the WB GDP-deflator" but the WB series ends in 2019 and the analysis window extends to 2024 — silently splicing with country-CPI would contradict the brainstorm's harmonization decision.

**Why**: Building on a false premise compounds errors. The user may want to adapt the plan or may have context you don't.

**Severity filter**: Trivial contradictions (column renamed, filename moved) — adapt and note. Methodological contradictions (wrong deflator, wrong fixed-effects, wrong sample frame) — escalate.

### 2. Debugging Spiral

A single task has consumed 3+ debugging cycles without resolution.

**Example**: Row counts in the harmonized panel don't reconcile against `methods/working-age/rule.md`; you adjust the filter, a different country's count breaks; you re-adjust, the original fails again.

**Why**: Diminishing returns. You're burning context on a blocker that might need a fundamentally different approach (different deflator chain, different identification spec), or the user might know something that unblocks it immediately.

**Include**: What you tried, what failed each time, your best guess at root cause.

### 3. Invalidated Future Phase

Something learned during the current phase means a future phase's approach won't work.

**Example**: Phase 3 plans to "extend the matched-pairs spec to a second country," but Phase 2 reveals that the matching variables aren't observed in the second country's survey vintage.

**Why**: The user needs to decide whether to replan future phases now or adapt later. Silently continuing means the user doesn't learn about the issue until that phase fails.

### 4. Unresolvable Ambiguity

The plan allows two or more valid interpretations and the choice materially affects the result.

**Example**: "Restrict to working-age population" — 15–64 (ILO standard) or 25–54 (prime-age, common in wage-gap papers)? Both are viable; the choice shifts the headline coefficient by ~20%.

**Why**: Guessing wrong wastes a task's worth of context and may produce a misleading artifact downstream evidence docs cite. The user can resolve this in one sentence.

**Severity filter**: Implementation details (chart palette, intermediate filename) — use your judgment. Methodological calls or anything that affects the headline finding — escalate.

### 5. Missing External Dependency

The plan assumes a data source, series, vintage, or documented methodology that doesn't exist or isn't accessible.

**Example**: The plan says "use INDEC's harmonized national poverty series," but only the city-level series is published; reconstructing the national aggregate from regional weights is out of scope for this plan.

**Why**: Can't proceed without something outside your control. The user decides: build the reconstruction, find a substitute (CEPALSTAT?), or reorder phases.

### 6. Scope Expansion

Implementation requires significantly more files or methodology work than the plan anticipated.

**Example**: Adding the cross-country panel requires harmonizing four sectoral classifications (ISIC 3, ISIC 4, NAICS, country-specific) — none in the file manifest.

**Why**: The plan underestimated scope. The user decides: expand, cut scope, or split into new phases.

**Severity filter**: One or two extra support files (a column rename, a small helper) is normal. A new harmonization scheme, a new identification step, or a methodology rule that didn't exist is an escalation.

### 7. Sample Restriction Surprise

Applying a filter unexpectedly removes more than ~10% of observations, or shifts sample composition in a way the plan didn't anticipate.

**Example**: The plan expects <2% loss from "drop respondents missing the wage variable"; you observe 18% loss because the post-2018Q3 vintage records wages with a new sentinel the cleaning script doesn't recognize as missing.

**Why**: Sample-shape changes are silent — they don't break the script, they bias the result. The user needs to know what was lost and whether it was load-bearing.

**Include**: Pre-filter N, post-filter N, the dropped rows' distinguishing characteristic.

### 8. Data Quality Issue

A pattern in the data — concentrated missingness, outliers, top-coding, unit changes — that the plan didn't anticipate and that materially affects the analysis.

**Example**: A subset of countries top-codes the wage variable at the 95th percentile; the plan didn't say whether to drop, winsorize, or impute. Or: a survey vintage changes its missing-value sentinel from -99 to NA mid-panel and the cleaning script silently treats -99 as a valid wage of $-99.

**Why**: Data quality issues that aren't surfaced become artifact integrity issues downstream — the chart says one thing, the data says another, and the deliverable is built on sand.

**Include**: The pattern's shape (which observations, which periods), magnitude (% of sample), and a default suggestion if the pattern has canonical handling in the project's `methods/` rules.
