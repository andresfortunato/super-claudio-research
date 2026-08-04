---
name: brainstorming
description: (r2p) Collaborative brainstorming for exploring research-design decisions before they harden into a plan. Use when the researcher has a question or goal but hasn't decided on the approach — they're weighing identification strategies, comparing deflators, choosing reference categories, deciding how to handle a survey-vintage break. Triggers on "how should we measure," "what's the right deflator," "let's think about identification," "explore options for," "brainstorm," "should we use X or Y," or when the researcher describes an analytical goal without a clear path to evidence. Also use when a planning session reveals that methodology calls haven't been made yet — brainstorming should precede planning, not happen inside it. Don't trigger when the decisions are already made and the researcher just wants to write a plan (that's the planning skill), when the question is per-artifact ("does this regression coefficient look right?" — that's `/verify`), or when they want to start running code (that's the implement skill).
---

# Brainstorming

## When to Brainstorm

The researcher has a research goal but hasn't decided how to approach it. They might have a question, a vague analytical direction, or a methodology call they're stuck on. The value of brainstorming is turning fuzzy thinking into clear decisions — not writing a plan, but producing the decisions a plan needs.

**Brainstorm when:**
- The researcher describes a research goal without a clear identification strategy or measurement approach
- Multiple valid methodology choices exist and the trade-offs aren't obvious (PWT rgdpe vs rgdpo; PPI vs CPI deflator; fixed-effects vs first-differences)
- The researcher is thinking out loud about a survey-vintage break, a sample restriction, or a reference-category choice
- A planning session stalls because methodology decisions haven't been made yet
- The researcher wants to understand how peers in the literature have handled a similar problem

**Don't brainstorm when:**
- The methodology calls are already made — go straight to planning
- The artifact already exists and the question is "does this look right" — that's `/verify`
- The deliverable is in last-mile review — that's `/deliverable-review`
- The task is clear enough to execute directly — just do it

## How Brainstorming Works

Brainstorming is a conversation, not a questionnaire. The researcher guides the direction. Claude's role shifts over the course of the discussion.

### Early phase — listen and synthesize

The researcher is exploring. They may ramble, contradict themselves, or jump between concerns. That's the point — they're thinking.

Claude's job: **organize and reflect**. Synthesize what the researcher is saying into structure. "So the three concerns are: deflator choice changes the headline number by ~30%, the 2014 EPH wave doesn't carry the variable you'd want for the panel, and the regional reference category isn't obvious. Is that right?" Don't fire a checklist of questions upfront — that biases the conversation toward Claude's framing of the problem, not the researcher's.

Let the researcher set the agenda. If they're not sure where to start, offer a lightweight prompt: "What's the headline question you want this analysis to answer?" — but then follow their lead.

### Mid phase — challenge and probe

Ideas are forming. The researcher has described what they want, maybe hinted at an approach.

Claude's job: **find gaps and contradictions**. Be a critical thinking partner. "You said you want to use PWT rgdpe for the productivity series, but earlier you mentioned the analysis is oil-exporter heavy — rgdpo and rgdpe diverge by ~40% for those countries. Which series is your headline going to be in?" Push on assumptions. Surface blind spots — sample restrictions that haven't been thought through, identification strategies that ignore selection, robustness checks that are easy to skip but hard to defend later.

This is where Claude's questions add the most value — they're reactive, responding to what the researcher actually said, not driving toward a predetermined structure. The questions should feel like a senior colleague in a methods discussion: sharp, specific, grounded in what was discussed.

### Late phase — alternatives and trade-offs

The problem space is clear. Now it's time to evaluate approaches.

Claude's job: **propose and compare**. Present 2-3 viable approaches with honest trade-offs. Don't lead with a recommendation — lay out what each approach costs (data availability, interpretation complexity, peer-review exposure) and what it buys (statistical power, defensibility, comparability). Let the researcher choose.

```
Three approaches given what we've discussed:

A) [Approach] — [what it buys] / [what it costs]
B) [Approach] — [what it buys] / [what it costs]
C) [Approach] — [what it buys] / [what it costs]

My lean is B because [reasoning], but A makes sense if [condition].
```

When the researcher makes a choice, record it with the reasoning: "We chose B because X. A was rejected because Y." For methodology calls a peer reviewer would push on, the choice should also graduate to a `research/methods/<topic>.md` record (see `.claude/conventions/methods.md`) — the brainstorm captures the discussion; the decision record is the citable artifact.

### Throughout — research on demand

When the discussion reveals a knowledge gap — "I'm not sure how the PWT versions handle this", "what's the standard reference category in this literature", "did the EPH variable actually break in 2014" — use available tools to fill it:

- **wiki**: Project-distilled knowledge in `research/wiki/` (concepts, entities, syntheses) — check first; the team may already have ingested the relevant source.
- **data_sources**: How-to-access docs in `research/sources/` for endpoints, query shape, pitfalls.
- **`/scan-sources` / web-scraping skill**: Pull a tracked source if the registry covers it; ad-hoc scrape otherwise.
- **Web search / context7 MCP**: Standard practice in the literature, library/API patterns, comparative analysis.
- **Codebase exploration**: How the current project handles the question (this knowledge may later become `context/*.md` files in the plan).

Research is on-demand, not mandatory. Don't research preemptively — wait until the discussion surfaces a specific question that needs an answer. When you do research, present findings concisely and tie them back to the decision at hand.

## Output

Brainstorming produces one of two outputs depending on the scenario:

### Scenario 1: Implementation brainstorming → trigger the planning skill

When the brainstorming was about a piece of analysis the researcher wants to build, the output is a structured summary that feeds into the planning skill.

**Example**: "I want to decompose Argentina's productivity slowdown by sector" → explore PWT rgdpe vs rgdpo → research how Diao-McMillan and other decompositions handle the comparable cases → decide on rgdpe with a one-paragraph robustness note → trigger the planning skill with decisions in hand.

Write the summary to `plan/brainstorms/<topic>.md` (directory created by `r2p init`), then trigger the planning skill. The summary becomes the decisions input — the planning skill reads it and incorporates the decisions rather than re-debating them.

For projects using the opt-in theme-parallel layout (see `.claude/conventions/evidence.md`), brainstorms tied to a specific theme may live at `plan/brainstorms/<theme>/<topic>.md`. Cross-cutting brainstorms stay flat. One sentence; don't over-engineer this.

**Summary format:**
```markdown
# <Topic> — Brainstorming Summary

## Problem
<What we're trying to answer or measure — 2-3 sentences.>

## Decisions Made
- <Decision>: <what was chosen> — because <reasoning, with a number or
  source where possible>. <Alternative> was rejected because <why>.
- <Decision>: ...

## Research Findings
- <Finding>: <source — paper, dataset note, peer convention> — <how it
  applies to our decision>.

## Open Questions
- <Anything unresolved that the planning skill needs to address.>

## Constraints Identified
- <Constraint>: <why it matters — data window, deliverable deadline,
  counterpart audience>.

## Decision records to file
- <If a decision belongs in `research/methods/<topic>.md`, name it here so
  the planning skill or implementation flags it.>
```

### Scenario 2: Exploratory brainstorming → summary only

When the brainstorming was about understanding a topic, comparing approaches conceptually, or thinking through a methodology question without immediate analysis plans.

**Example**: "How do peers in the literature handle the EPH 2014 break?" → review three or four papers' approaches → compare imputation vs sample-window trim vs proxy variable → summary of findings; no plan yet.

Write the summary to `plan/brainstorms/<topic>.md` if the discussion was substantial enough to reference later. For quick explorations, presenting the summary in conversation is sufficient.

## What Brainstorming Does NOT Do

- **Write plans.** That's the planning skill. Brainstorming produces decisions; planning produces plans.
- **Make decisions for the researcher.** Present alternatives and trade-offs. Let the researcher choose. Record their reasoning.
- **File decision records.** That's the researcher's call once the choice is settled — `research/methods/<topic>.md`. The brainstorm names which decisions deserve a record; the researcher writes them.
- **Sanity-check existing artifacts.** That's `/verify` (per-artifact, ≤2k tokens) or `/deliverable-review` (multi-lens, ≤12k).
- **Follow a rigid structure.** The conversation flows naturally. The phases (listen → challenge → evaluate) are a guide, not a checklist.
- **Research everything upfront.** Research fills specific knowledge gaps as they emerge, not as a mandatory first step.

## The Maieutic Principle

In Socratic dialogue, the one asking questions guides the conversation — they define the problem and scope by choosing what to ask. The researcher is better at this than the model because they have the domain context, the priorities, and the deliverable target.

Claude's questions should be mostly **reactive**: criticizing, finding gaps, surfacing blind spots in what the researcher said. Not **directive**: driving toward a predetermined structure or checklist.

The exception is when the researcher is stuck. If the conversation stalls, Claude can nudge: "You've named the identification strategy clearly but haven't said anything about what would invalidate it — what's the tripwire that would tell you this approach was wrong?" This is still reactive (responding to an absence) rather than directive (asking the next question on a list).
