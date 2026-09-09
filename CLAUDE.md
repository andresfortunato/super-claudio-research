# research-to-policy — CLAUDE.md

**This repo is the framework, not a research project.** It ships the conventions,
hooks, skills, agents and templates that `r2p init` installs *into* a research
repo. Do not run `r2p init` here — it would scaffold `research/`, `analysis/`,
`data/` and five more directories that do not belong in this tree.

**Current focus, and what's next:** `.scc/status/project.md`. That file owns
volatile state; this one owns stable identity. Do not restate its contents here —
two files describing "current focus" is the drift this framework exists to prevent.

## Talking to the researcher

Everything written to disk here — conventions, handoffs, plans, phase files,
field notes — is written **for the next Claude session**: dense, terse, safe to
assume the reader will look up what it doesn't know. Keep it that way.

**Conversation with the researcher is the opposite, and assumes nothing.** In
chat: name the problem in plain words before naming the fix; expand an internal
term the first time it appears in a session (`invariant 9`, `#71`, `D2`, a phase
number, a bare file path all mean nothing on their own); give the rationale, not
just the conclusion; and keep **"what I decided myself"** visibly separate from
**"what needs your call."** Comprehensive, but readable start to finish without
opening a file. The detail belongs in the files — that is what they are for.

Ships to every project via `templates/CLAUDE.md.template`. It lives in CLAUDE.md
rather than a convention because it applies to every message and so has no
trigger to fire on; conventions are read on demand, and there is no moment at
which "how to explain" starts being relevant, because it always is.

## Layout

```
.claude/conventions/   the 8 mandatory + 2 optional protocols r2p installs
.claude/{hooks,skills,agents}/   enforcement, user-invoked skills, subagents
templates/             what init/upgrade copies into a target project
templates/migration/   the v1→v2 scripts — read-and-adapt, not a library
src/                   the npm CLI: init, upgrade, plan init
docs/                  design rationale + the Córdoba audit + field-notes/
plan/ · brainstorms/ · archive/    this repo's own plan lifecycle
```

## Rules specific to this repo

- **The constitution binds every addition.** `docs/audience-and-philosophy.md`
  holds ten principles and a table of questions to run a proposal past. A
  change that fails one revises that document explicitly, first — it is never
  silently bypassed. `docs/extending.md` has the concrete steps.
- **There are two installers.** `src/lib/install-project.js` (init) and
  `src/lib/upgrade.js` (upgrade). A layout or template change must be made in
  both, and `--upgrade` is the one that gets forgotten — three v2 defects lived
  only there and none was visible to an `init` test.
- **Framework bugs go in `docs/field-notes/`**, never in a project's own notes.
  That directory exists because seven of the pilot's 70 "learnings" were r2p bug
  reports filed where no future project could see them; one recurred because of it.
- **Nothing engagement-specific lands in a committed file.** Córdoba and Cambodia
  are proving ground, not content.
