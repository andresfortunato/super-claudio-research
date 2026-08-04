# literature/

Reference papers, articles, and book chapters that contextualize the
work — academic literature, policy papers, prior-art reports. Large
PDFs, often copyrighted; gitignored by the framework.

Distinct from:

- `raw/` — committed (or selectively committed) project-specific source
  materials that the analysis cites: scrapes, regulatory PDFs,
  primary-data downloads. Project-internal in origin.
- `research/wiki/` — distilled knowledge derived from literature and other
  sources, ready to query and reference.

Drop PDFs in freely; nothing inside ships to the remote. To pull a
paper into the wiki, use `/wiki-ingest literature/<file>.pdf`. If you
want a bibliography file (`refs.bib`, `citations.json`) committed, add
an exception in `.gitignore` (e.g. `!literature/refs.bib`).

Typical contents:

- `<author>-<year>-<short-title>.pdf` — single papers
- `<topic>/` — subdirectories grouping papers by theme
- `refs.bib` — bibliography file (commit by exception if desired)
