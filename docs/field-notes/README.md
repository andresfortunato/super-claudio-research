# Field notes — lessons about the framework itself

Operational lessons about **r2p**, not about any one project's data. They come
from real engagements and they are the reason several v2 rules exist.

**Why this directory exists.** The pilot engagement's `learnings/` directory held
70 entries, and seven of them turned out not to be about Córdoba at all — they
were bug reports about r2p: evidence-id collisions across parallel worktrees
(filed twice, months apart, because the first filing had nowhere to go that would
change the framework), two agents sharing one git index, parallel fan-out
hygiene, digest retention varying with heading style, and gap-checks that miss
unchecked branches.

Those had been sitting in a project repo where **no future project could ever see
them**, which is exactly why the evidence-numbering collision recurred instead of
getting fixed. v2 fixed it (`research/evidence/.next-id`) only because the audit
surfaced both filings at once.

**The rule.** A learning about a *dataset* goes in
`research/sources/<source>.md`. A learning about an *analysis* goes in
`research/methods/<topic>.md`. A learning about **the framework, the tooling, or
how parallel sessions behave** goes here, in the framework repo — where the next
project inherits it.

**Format.** Whatever shape the discovery wants. The pilot's own experience is
instructive: v1 prescribed YAML frontmatter for learnings and **7 of 71 complied**.
The format that actually got written — a claim-shaped title, a `**Discovered:**`
line with date and context, then numbered sections — is the one that survived
contact, so that is the shape to imitate. A convention that loses 90% of the time
is not being violated; it is wrong.
