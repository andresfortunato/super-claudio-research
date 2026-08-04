# deliverables/decks/

Presentation decks — kickoff meetings, internal updates, conference
talks, working-session decks. Committed by default so collaborators
can pick up the latest version; binary `.pptx` files are still
tracked, but consider Git LFS if the directory grows large.

Distinct from `deliverables/`, which holds **formal** outputs with
fixed profiles (country-diagnostic memo, ministerial briefing,
internal research memo). Slides are typically less formal and more
frequent — a deck for next week's meeting belongs here; a final
project briefing belongs in `deliverables/`.

Typical contents:

- `YYYYMMDD_<topic>.pptx` — dated, single-purpose deck
- `<deck-slug>/` — subdirectory if the deck has a Markdown source,
  charts, or speaker notes alongside the `.pptx`

Build decks with the `ppt-creator` skill, which assembles `.pptx`
files from charts and analytical outputs.
