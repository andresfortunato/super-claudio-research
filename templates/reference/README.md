# reference/ — inputs we did not produce

Material the project *reads*, as opposed to material it *writes*. Nothing here
is a citable project finding; if something in here becomes one, extract the
claim into `research/` rather than linking a gitignored path.

| Folder | Contents | Tracked? |
|---|---|---|
| `literature/` | papers, books, third-party decks and reports | gitignored (large, often copyrighted) |
| `notes/` | meeting transcripts, working notes, source libraries | **tracked** — unrecoverable if lost |
| `internal/` | team-internal scoping, feedback syntheses | gitignored |
| `external/` | commissioned consultant reports (e.g. `iaraf/`) | gitignored |

`notes/` is the exception on purpose: a meeting transcript or a hand-written
source library cannot be re-downloaded, so it belongs in git even though the
rest of `reference/` does not. Large binaries that *can* be re-sourced are
untracked so they stop shipping in every clone.

Pull a paper into the wiki with `/wiki-ingest reference/literature/<file>.pdf`
if the project is using the wiki (it currently is not — see CLAUDE.md).
