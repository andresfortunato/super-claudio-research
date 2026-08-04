# Six months of AI-assisted applied research: what broke, and what fixed it

*A note for people considering using an AI coding agent for serious research
work. No prior knowledge assumed.*

---

## 1. The setting

We spent six months doing applied economic research — the kind of work that ends
in a policy memo: pull data from a dozen government and international sources,
build panels, run decompositions, make charts, and eventually write something a
minister will read.

Most of that work ran through **Claude Code**, an AI agent that lives in a
terminal, reads and writes files in a repository, and runs code. It is very good
at the middle of the job: fetching an awkward dataset, writing the script,
spotting that a variable changed definition in 2016.

But it has one hard limitation that shapes everything else.

> **The agent starts every session with no memory of the last one.**

It knows only what it can read in the repository right now. So the repository
stops being a place where you keep files and becomes **the agent's memory**. If a
hard-won discovery isn't written down in a findable place, it is gone — and the
next session will cheerfully re-derive it, or worse, contradict it.

## 2. What we built, and why

To handle that, we built a small framework — a set of conventions about which
folders hold what, and what each kind of document must contain. We called it
**r2p** ("research to policy"). It is not software so much as a filing discipline
that both humans and the agent follow:

- **findings** from the data, one document per analysis, numbered, never edited
  after the fact — the audit trail
- **methodology choices** ("we use this price index, not that one, because…")
- **gotchas** — the "careful, this survey has a hole in 2013" warnings
- **source manuals** — how to actually get data out of each API
- **plans and handoffs** so multi-session work survives a gap

Plus a few automated nudges: if the agent produced a chart without writing down
what it learned, a hook reminds it.

**This worked well.** Six months in, the project had 151 findings documents, 43
methodology records, 70 gotchas, 60 source manuals. Nothing was lost. New
sessions could pick up cold.

And then it stopped working — not because anyone ignored the framework, but
because they followed it.

## 3. The failure: a library nobody can read

The researcher's complaint was specific and, at first, puzzling: *the agent is
getting lost when it tries to summarise our own findings, and some of them look
like they contradict each other for no good reason.*

Both halves were true. Here is what we found.

### Problem 1 — The index ate the library

Every finding got a row in an index file, with a title. Over six months those
titles quietly absorbed everything: the numbers, the caveats, the sources, the
corrections. By the end the **index was 330 KB — bigger than the five largest
findings documents combined.** The median "title" was 1,554 characters. The
longest was over 10,000.

An index is supposed to help you decide what to read. This one had become the
thing you had to read, and reading it consumed a large share of the agent's
available attention before any actual thinking started.

**Fix:** cap the index. One line per finding, headline hard-limited to 120
characters, with the detail in the document where it belongs. 330 KB → 33 KB.

### Problem 2 — Findings argued with each other for the wrong reason

Two causes, both about *writing*, not about data.

**(a) Verdicts were welded to measurements.** Our template asked for "the claim,
the number, the implication" in one line. So people wrote conclusions:
*confirmed*, *REFUTED*, *this proves*. We counted **338 such words across 93 of
the 151 documents.**

The trouble is:

> **Measurements don't contradict each other. Verdicts do.**

Two documents can measure entirely compatible things and still read like a
collision, because each shipped its own pre-baked judgement and nobody ever
reconciled the judgements with one another. The agent, asked to synthesise, was
handed 93 verdicts and no way to tell a real disagreement from two people
phrasing a nuance differently.

**Fix:** split every document in two. A **Measured** section that holds numbers
and nothing else — no "confirms", no "refutes", enforced by an automatic check.
And a **Reading** section, clearly labelled as the author's interpretation. When
you synthesise, you read the measurements across documents and write the
interpretation *once*, at the top level.

**(b) Nobody wrote down what they were measuring.** Whether a number described a
whole province or just its main city, and over which years, lived in a paragraph
somewhere. But a province and a city genuinely move in opposite directions, so
those two numbers *should* differ — they aren't a disagreement, they measure
different things.

**Fix:** put the scope in a small structured header on every document — unit
(country / province / city / sector), the exact geography, the time window. That
turns a judgement call into a test:

> **Two findings can only contradict each other if their unit and period
> overlap.**

### Problem 3 — Corrections nobody could act on

When a finding got partly overturned, people wrote a warning at the top: *⚠ this
part is retired.* Twenty-five documents had one. It was prose, so nothing could
filter on it, and retired numbers kept getting quoted from the middle of
documents whose warning sat elsewhere.

The clearest symptom, which the project had written down about itself: **one
document retired a number in one section and carried on asserting it in
another.** A document contradicting itself is what prose corrections produce once
there are enough of them.

**Fix:** a machine-readable status field — `live`, `revised`, `retired` — and one
banner in the document, never in the index.

### Problem 4 — The missing layer, which someone had already built in secret

The deepest problem was structural. Our findings documents are **append-only** on
purpose: an audit trail has to survive being wrong, so nothing gets edited or
deleted. Correct — but it means the collection only ever *grows*. Nothing in it
ever gets distilled.

At 151 documents that is unreadable, so every drafting session rebuilt a mental
summary from scratch, differently each time.

Here is the part worth remembering. While auditing, we found that a researcher
**had already built the missing layer by hand** — a 1,568-line map of claims, a
list of 40 corrections, a list of 128 open conflicts — tucked inside a folder for
one specific memo. Its own header explained why it existed: *so that no drafting
session would have to open the 317 KB index again.*

Somebody hit the wall and built exactly the right thing. But the framework had no
place for it, so it went into a project folder, was marked "generated, do not
edit by hand", and died when that memo shipped. The next memo would have built it
again.

**Fix:** make it a first-class artifact. A single **claims file** — about 40
entries, one paragraph each: the claim, one number, which findings support it,
and *what contests it*. Crucially it has the **opposite** rule from the findings
beneath it:

| Layer | Rule |
|---|---|
| findings | append-only, never edited — it is the record |
| claims | freely edited and deleted — it is a curated view |

Deleting a claim is cheap and correct. Deleting a finding destroys the audit
trail. Memos now cite claims; claims cite findings. One layer of indirection
means a corrected finding updates one claim, and everything downstream keeps
working.

**Result:** what a drafting session must read to know what the project knows went
from 330 KB to 57 KB. And compressing 151 documents into 40 claims immediately
exposed **three headline numbers in the memo that had no supporting document at
all** — invisible for months behind the 330 KB index.

### Problem 5 — One idea, three folders

We had separate folders for methodology choices, operational rules, and gotchas.
It felt clean. It failed, because real work doesn't arrive in those categories —
it arrives as a *topic* that needs all three at once. Deciding how to define a
city's boundary produces a rule, a justification, and a trap, and we were filing
them in three places joined by hand-written cross-references.

The evidence that the boundary wasn't real: the "methodology choices" folder
filled to 43 entries against a guideline that said more than 30 meant we were
over-recording, while the "operational rules" folder starved at 4 — because
people were filing rules as choices. And of 70 gotchas, only **7** followed the
prescribed format.

> **A rule that is broken 90% of the time isn't being disobeyed. It's wrong.**

**Fix:** one folder, one file per topic, with fixed sections for the rule, the
alternatives rejected, the traps, and the numbers that prove the rule is in
force. 113 files became 28.

Sorting those 70 gotchas by hand also revealed that **seven of them were not
about our project at all** — they were bugs in the framework itself, sitting in a
project repository where no future project could ever see them. One of them had
been filed *twice*, months apart, because the first filing had nowhere to go that
could change anything.

### Problem 6 — Rules written for a small project, applied to a big one

Nearly every size guideline the framework stated was wrong by a factor of three
to ten once the project got real: "5–15 source manuals" became 60; "more than 10
rules means refocus" became 28.

And we made the same mistake *during the repair*. To pick which documents
deserved a full rewrite we said "cited at least 3 times". On a collection where
citation counts run 80 to 180, that selected 145 of 151 — everything. Switching to
"the top 40 by citations" gave a workable list.

> **Size-dependent rules must be written as ranks or shares, never as absolute
> counts.** A threshold that is well-judged at 20 documents is all-or-nothing at
> 150.

### Problem 7 — Machinery that charged rent and delivered nothing

The framework shipped a knowledge-wiki and an automatic source-watchlist. Both
were prominently documented in the file the agent reads at the start of *every*
session. After six months: **zero wiki pages, zero scrapes.** They didn't fit how
this project consumed information, but they were charging attention every single
session.

**Fix:** ship them, but don't promote them. A mechanism earns space in the
always-loaded file only once it has produced something.

## 4. What we'd tell someone starting out

1. **Your repository is the agent's memory.** Design it as a memory, not as
   storage. Decide where a discovery goes *before* you make one.
2. **Separate what you measured from what you concluded.** One sentence per
   document, in two different sections. It is the cheapest possible defence
   against a body of work that appears to argue with itself.
3. **Write down the scope of every number** — unit, place, period — in a fixed,
   structured place. Most "contradictions" are two different objects.
4. **Make corrections structured, not prose.** A warning nobody can filter on
   will be ignored, including by you.
5. **Append-only records need a curated layer above them.** Past a few dozen
   entries nobody can read the record, so something has to distil it. Give the
   two layers opposite editing rules.
6. **Organise by topic, not by document type.** Type-based folders feel tidy when
   you design them and fail when you use them.
7. **Anything that loads every session must earn its place.** Unused scaffolding
   is a recurring tax.
8. **Watch what people build in the wrong place.** Every real gap in our
   framework showed up first as a workaround, not a complaint: the claims layer
   hidden in a memo folder, framework bugs filed as project notes, rules filed as
   choices. Nobody complains about a missing mechanism. They quietly invent it,
   in the wrong directory — and that is the most precise bug report you will ever
   get.

## 5. The honest summary

None of these problems came from the AI being bad at research. They came from a
filing system that was designed for a small project, used successfully for a big
one, and never re-tuned. The agent's difficulty synthesising was not a limitation
of the model; it was **150 documents' worth of pre-baked, mutually unreconciled
conclusions and no curated layer**, which is a situation that would defeat a human
research assistant too.

The general lesson is unglamorous. Working with an AI agent puts unusual pressure
on how you write things down, because the agent is a very literal, very
fast-reading colleague with no memory and no instinct for which of your documents
is out of date. Everything vague in your filing system gets amplified. But the
fixes are all things good research practice already wanted: say what you
measured, say what you concluded, say what you don't know, and keep one place
that tells you the current state of the argument.
