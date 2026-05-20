# Migrate-source mechanism — design rationale

## The problem this solves

Mature r2p projects (e.g. `~/cambodia-growth`) develop a clean data
layer over months of work: per-source reference docs in
`data_sources/`, wrapper functions in `<project>_utils.py`, env-var
prefixes in `.env.example`, INDEX rows, `data/README.md` entries,
CLAUDE.md mentions for the core sources. Newer r2p projects (e.g.
`~/cordoba`) starting fresh have to re-derive the same pieces
source-by-source, even when the upstream API is identical — IMF
SDMX, BIS SDMX, Atlas of Economic Complexity, World Bank wbgapi.

Without a transplant tool, the rediscovery costs compound:

- **A session looking up "how to query IMF SDMX 3.0"** re-finds the
  workarounds the donor project already encoded (which endpoints
  return 403, which dimension positions silently return empty
  series, the CDIS→DIP rename).
- **The new wrapper diverges from the donor's** in subtle ways —
  different return shape, different timeout, different
  error-handling — even though the underlying API is identical.
- **Project-specific knobs leak through ad-hoc copying.** A
  researcher who copy-pastes `atlas_query` from cambodia-growth
  also drags in Cambodia's country-id map, peer-country list, and
  headline-anchor values that have no business living in the new
  project.

The `/r2p-migrate-source` skill closes this gap. It walks one
source's full data layer in a donor r2p project, strips
project-specific bits at migration time, and lands the adapted
layer at the target — gated by a proposal-then-apply review so
nothing surprises the user.

## The pieces

```
.claude/skills/migrate-source/SKILL.md  ← the skill (frontmatter + four-phase flow)
docs/migrate-source-mechanism.md        ← this file (design rationale)
```

Plus one-line cross-references in `.claude/conventions/data-access.md`
and `.claude/conventions/data-sources.md` ("Adding a new source"
recipes), and a row in the README's skill table.

No installer changes — skills auto-mirror to `~/.claude/skills/` via
the existing `install-globals.js` step of `r2p init`.

## Why LLM-at-migration, not donor-side discipline

Considered and rejected: require donor projects to wrap each source's
artifacts with BEGIN/END markers (`# BEGIN source:imf … # END source:imf`
in the utility module, a `## Migration` section in each ref doc
listing project-specific bits). The migration tool would then just
copy between markers.

Reasons rejected:

- **Permanent maintenance tax on every donor project, forever.**
  Markers drift silently — someone refactors `atlas_query`, forgets
  the END marker, the next migration extracts a half-wrapper.
- **Bootstrap-impossible.** cambodia-growth doesn't have markers
  today. Retroactively adding them everywhere is itself a
  migration problem.
- **The `data-access` convention already provides enough
  scaffolding.** Source-prefixed filenames (`imf_*.md`,
  `atlas_*.md`), source-prefixed env vars (`ATLAS_DB_*`,
  `IMF_*`), wrapper docstring back-links (`Full guide:
  data_sources/<file>.md`), and the required INDEX
  Helper-functions table — these are *runtime* anchors the LLM
  can use to do discovery. No second discipline layer needed.

The cost of the LLM-at-migration approach is per-migration tokens
(30–50k for a typical source). Acceptable because migrations are
rare — a handful per project lifecycle.

## Why proposal-then-apply, not direct write

Considered and rejected: write files immediately, ask forgiveness
afterward. The donor's structure is well-defined, the target's
structure is well-defined, the adaptation rules are simple — why
not just do it?

Reasons rejected:

- **Adaptation is fuzzy at the edges.** The skill has to guess the
  target's utility-module name, country ISO, and peer-country list.
  Wrong guesses are recoverable but waste a `git revert` cycle.
- **Conflicts need conscious resolution.** If the target already
  has a partial `data_sources/imf_sdmx_api.md`, the user needs to
  see *both* versions before deciding which sections to keep.
- **Discovery is non-deterministic.** Two LLM runs may surface
  slightly different dependency lists. The proposal lets the user
  spot a missing wrapper before it lands.

`MIGRATION_PROPOSAL.md` at the target root, with the user's "apply"
as the only go-signal, is the same pattern `/r2p-adopt` uses for
legacy-→-r2p adoption. Consistent mental model across both
transplant flavors.

## Why strip-and-prompt for headline anchors, not auto-derive

Considered and rejected: the migration tool re-runs the donor's
headline-anchor query against the target's parameters (the target's
country instead of Cambodia) and pastes the new value into the
migrated ref doc.

Reasons rejected:

- **Masks upstream API drift.** If the IMF SDMX 3.0 endpoint
  changed since the donor's last verification, the auto-derived
  anchor would silently encode the change as "verified." The whole
  point of the anchor is to be a freshness check; auto-derivation
  invalidates it.
- **Requires credentialled API access.** Atlas Postgres needs DB
  credentials; many sources need API keys. The migration tool
  shouldn't assume the target has any of those configured yet —
  the user may run the migration *before* populating `.env`.
- **Conflates "the wrapper works" with "the doc is verified."**
  Those are different invariants. Verification belongs to the
  receiving project's first real session.

The chosen behavior — strip the `Status: verified <date>` line,
replace Cambodia-specific anchor values with `TODO(migrate):
verify against <target-context>` — pushes re-verification to
`MIGRATION_TODO.md` step 2, where the user re-runs the documented
procedure with target parameters and pastes the real value back
in.

## Why git-style merge markers on conflict, not bespoke UI

Considered and rejected: a prompt UI that walks the user through
each conflicting section ("Keep donor version? Keep target version?
Edit manually?"). Cleaner in theory; brittle in practice across
multi-conflict migrations.

Git-style markers (`<<<<<<<` / `=======` / `>>>>>>>`) leverage a
mental model every r2p user already has — they've all resolved
merge conflicts in git. Editor support is excellent (VS Code,
neovim, JetBrains all highlight conflicts natively), and the
resolution is a `git add`-then-commit away.

The proposal lists each conflicting file, so the user knows what
they're walking into before approving apply.

## Why refuse on missing target convention, not auto-install

Considered and rejected: if the target lacks
`.claude/conventions/data-access.md`, install it on the fly (copy
from the framework) and proceed.

Reasons rejected:

- **Convention installation is the framework's job, not a skill's
  job.** `r2p init` and `r2p init --upgrade` are the entry points
  for landing conventions; bypassing them creates a parallel
  install path that drifts.
- **Surprising side effects.** Installing the data-access
  convention may also pull in the data-sources convention,
  template seeds (`templates/data_sources/`, `templates/.env.example`),
  and a `.gitignore` block — the user didn't ask for any of that.
- **One-line failure message is information enough.** "Target
  lacks data-access convention; run `r2p init --upgrade` first."
  is actionable in under five seconds.

The convention is the precondition; the framework owns its install.

## Why one source per proposal cycle, not batched

Considered and rejected: comma-list invocations
(`--source imf,atlas,bis`) produce one big proposal that the user
approves or rejects atomically.

Reasons rejected:

- **Approval granularity matters.** The user might be happy with
  the IMF proposal and unhappy with the Atlas one. Atomic
  approval forces all-or-nothing on a per-source basis that
  rarely aligns with how research projects actually adopt
  sources.
- **Per-source review is the natural unit.** Each source has its
  own conflicts, its own TODOs, its own dependency analysis. A
  bundled proposal is just N proposals concatenated; the
  user-cognitive cost is the same.

The skill *does* accept comma-list invocations as a convenience
— but iterates one source at a time, each with its own proposal
gate. Multi-source is shorthand, not parallelism.

## What this does NOT do

- **No orchestration of multi-source dependency graphs.** If two
  sources share a helper function (uncommon), the migration tool
  doesn't notice — each source carries the helper it needs and the
  user resolves the duplication post-apply.
- **No auto-anchor verification.** See "Why strip-and-prompt" above.
- **No real-fetch smoke test in v1.** Only an import check. A real
  fetch test (call the wrapper with target params, verify response
  shape) requires `.env` populated; it's a v1.x extension and is
  documented as step 4 of `MIGRATION_TODO.md`.
- **No `.env` writes.** Only `.env.example`. Real secrets are the
  receiving project's job.
- **No cross-project recipe library.** The conventions are the
  catalog. If a project needs the IMF wrapper, it migrates from
  whatever donor project has the best version; there is no
  framework-curated "official IMF wrapper."

## Tradeoffs accepted

- **Token cost per migration.** 30–50k tokens for a typical source.
  Acceptable because migrations are rare.
- **Non-determinism.** Two LLM runs may surface slightly different
  dependency lists. Mitigated by the proposal-then-apply gate —
  the user catches missing pieces before files land.
- **LLM may miss obscure shared dependencies.** A helper function
  called by the wrapper but not source-prefixed (e.g. a generic
  `_parse_sdmx_response`) may slip through. Mitigated by the
  import smoke test (catches `NameError` at import time) and the
  receiving project's first-real-use session.
- **Project-specific constants need manual fill-in.** The proposal
  flags them as `TODO_TARGET_*` placeholders; the receiving
  project's first session replaces them. The skill doesn't try to
  derive target-country-id maps from the target's CLAUDE.md (would
  be guessy and easy to get wrong).
- **Conflict resolution requires a git-aware user.** Acceptable —
  r2p users are already git-fluent.

## Relationship to `/r2p-adopt`

The two skills share the proposal-then-apply pattern but operate on
different inputs and produce different outputs:

| | `/r2p-adopt` | `/r2p-migrate-source` |
|---|---|---|
| **Input** | A legacy (non-r2p) project | A donor r2p project + one source slug |
| **Output proposal** | `ADOPTION_PROPOSAL.md` (full repo audit) | `MIGRATION_PROPOSAL.md` (one source's data layer) |
| **Scope** | Whole-project classification against framework slots | One source's ref doc + wrapper + env + INDEX + cache entry |
| **Frequency** | Once per project, at adoption | A handful per project lifecycle, as sources are added |
| **Donor-side prep** | N/A (legacy by definition) | Donor follows the data-access + data-sources conventions |

They're kept separate because conflating them — making `/r2p-adopt`
also do source transplants, or making `/r2p-migrate-source` also do
adoption — would force one tool to handle two very different input
shapes. Cross-references in both directions are in the skill
descriptions and this doc.

## Extension points

- **Real-fetch smoke test (v1.x).** After import succeeds, call the
  wrapper with target-appropriate dummy params, confirm the response
  shape matches the doc's "Parsing / decoding" section. Requires
  `.env` populated, so gate behind a `--with-fetch` flag.
- **Auto-derive target country context.** If the target's
  `CLAUDE.md` or `decisions/` records name a country explicitly,
  use that to seed `TODO_TARGET_COUNTRY_IDS` with a plausible
  default. Today the skill leaves the placeholder for manual fill.
- **Cross-source dependency detection.** If two sources slated for
  migration share a helper (e.g. a generic `_resolve_iso`), surface
  it once rather than duplicating across both wrappers. Trip-wire
  on first pilot report of duplication.
- **Multi-project catalog skill.** A separate `/r2p-list-sources
  <donor>` skill that walks a donor's INDEX and reports available
  sources for migration. Defer until the user-facing question
  "what's available?" becomes recurring.

## Provenance

The skill emerged from the same v1.2 session that shipped the
`data-access` convention. The convention's INDEX
Helper-functions table, source-prefixed filenames, and wrapper
docstring back-links were originally framed as cambodia-growth
hygiene; in brainstorming the migrate-source skill, those anchors
turned out to be exactly the runtime hooks a transplant tool
needs. The convention enables the skill, and the skill validates
that the convention's anchors are load-bearing.

First validated against `~/cambodia-growth` (donor) and a throwaway
`/tmp/migrate-source-test-target/` (target) for the IMF SDMX and
Atlas Postgres sources — the simplest (one wrapper, no auth) and
most complex (5 wrappers, Postgres credentials, project-specific
country constants) sources in the donor.
