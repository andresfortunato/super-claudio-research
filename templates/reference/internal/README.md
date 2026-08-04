# reference/internal/

Project-management documents that inform the work but should not be
committed: concept notes, workplans, mission and stakeholder plans,
team-internal scoping notes, counterpart correspondence.

Distinct from:

- `plan/brainstorms/` — gitignored working notes about *methodology decisions*
  before they harden into a plan.
- `research/methods/` — committed, citable methodology calls a peer reviewer
  would push on.
- `raw/` — committed (or selectively committed) immutable source
  materials that the analysis cites.

The whole directory is gitignored by the framework. Drop documents in
freely; nothing inside ships to the remote.

Typical contents:

- `<project>_concept_note.md` — concept note shaping scope and audience
- `<project>_workplan.md` — counterpart-shared workplan
- `mission_<location>.md` — field mission stakeholder map and meeting plan
- `notes_<topic>.md` — team-internal scoping or coordination notes

If a document in here becomes important enough to *cite* from a
deliverable or insight, copy the citable extract into `research/methods/` or
`raw/` — don't link the gitignored path.
