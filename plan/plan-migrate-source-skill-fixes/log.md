# Log — /r2p-migrate-source fix plan

Methodology notes and design-call drift. Append per session.

## 2026-05-20 — Plan written

- Resolved the 3 open design questions from
  `brainstorms/migrate-source-skill-gaps.md`:
  - **Missing ref doc** → warn-and-proceed + bootstrap a 5-line stub
    at the target. Chose stub over "no file" because the
    `Full guide: data_sources/<slug>.md` docstring back-link is
    documented as load-bearing for the INDEX bridge; even if today's
    pre-convention donor lacks the back-link, the target should land
    convention-compliant.
  - **Banner anchor** → case-insensitive substring on the slug inside
    `# ── ... ──` banner text. Cross-source banners get an explicit
    ambiguity note in the proposal rather than a heuristic.
    De-dupe by function name when multiple anchors fire on the
    same def.
  - **Interpreter search** → `<target>/.venv/bin/python` →
    `<target>/venv/bin/python` → `python3`, report which was used.
    `ModuleNotFoundError` on a small framework-deps allowlist
    (`dotenv`, `pandas`, `requests`, `psycopg2`, `pyyaml`, `numpy`,
    `pandasdmx`) is labeled env-setup gap, not migration failure.
- Decided against a `--strict` flag. Speculative knob; defers the
  design call rather than answering it.
- Decided against editing the framework `.env.example` template or
  pushing cambodia-growth to rename helpers. Both were on the table
  in the brainstorm's repo-vs-skill axis; both lose because future
  donors will share the same pre-convention shape and the SKILL
  should accommodate.
