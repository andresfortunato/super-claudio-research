#!/usr/bin/env bash
# Script:   plan/plan-r2p-v2-consolidation/migration/01_layout.sh
# Inputs:   the repo as of the Phase-0 commit
# Outputs:  research/ plan/ deliverables/ reference/ .claude/conventions/project/
# Seed:     none
# Env:      bash 5, git 2.4x
#
# Phase 2 (reordered ahead of content migration so CLAUDE.md never describes
# paths that do not exist). Root: 26 dirs + 22 loose files -> 8 dirs + 8 config
# files. Idempotent: every move is guarded by a test on the source path.
#
# Tracking status is PRESERVED per file, with one deliberate exception recorded
# in the plan: five large re-sourceable binaries (~90 MB) are untracked with
# `git rm --cached` so they stop shipping in every clone. They stay on disk.

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

mv_git() {  # mv_git <src> <dst>   — git mv if tracked, plain mv otherwise
  local src="$1" dst="$2"
  [[ -e "$src" ]] || { echo "  skip (absent): $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [[ -n "$(git ls-files "$src")" ]]; then
    git mv -k "$src" "$dst"
  else
    mv "$src" "$dst"
  fi
  echo "  moved: $src -> $dst"
}

echo "== research/ : the durable record =="
mkdir -p research
mv_git evidence          research/evidence
mv_git data_sources      research/sources
mv_git methods           research/methods
mv_git wiki              research/wiki
# consumed in Phase 3, then deleted; parked out of root so it is already clean
mv_git decisions         research/_legacy/decisions
mv_git learnings         research/_legacy/learnings
# literature is reading material, not a scrape target
if [[ -d research/wiki/raw/literature ]]; then
  mkdir -p reference/literature
  for f in research/wiki/raw/literature/*; do
    [[ -e "$f" ]] || continue
    mv_git "$f" "reference/literature/$(basename "$f")"
  done
  rmdir research/wiki/raw/literature 2>/dev/null || true
fi

echo "== plan/ : plans plus their pre- and post-history =="
mv_git archive           plan/archive
mv_git brainstorms       plan/brainstorms
mv_git handoff.md        plan/archive/_root_handoff_2026-06-29.md

echo "== deliverables/ : memos and decks =="
mkdir -p deliverables/memos deliverables/decks
for d in access-to-finance cordoba-spatial-equilibrium-deck country-diagnostic-memo \
         growth-diagnostics-memo internal-research-memo labour-demand-supply-narrative \
         ministerial-briefing narrativa_final_memo_interno research_workplan \
         shift-share-vab-cordoba; do
  mv_git "deliverables/$d" "deliverables/memos/$d"
done
mv_git "deliverables/Cordoba Research Work Plan.docx" "deliverables/memos/Cordoba Research Work Plan.docx"
if [[ -d slides ]]; then
  for f in slides/*; do
    [[ -e "$f" ]] || continue
    mv_git "$f" "deliverables/decks/$(basename "$f")"
  done
  rmdir slides 2>/dev/null || true
fi

echo "== reference/ : inputs we did not produce =="
mkdir -p reference/notes reference/external
mv_git internal_docs     reference/internal
mv_git iaraf             reference/external/iaraf
for f in docs/*; do [[ -e "$f" ]] && mv_git "$f" "reference/notes/$(basename "$f")"; done
rmdir docs 2>/dev/null || true

echo "== project conventions next to the framework ones =="
if [[ -d project_conventions ]]; then
  mkdir -p .claude/conventions/project
  for f in project_conventions/*; do
    [[ -e "$f" ]] || continue
    mv_git "$f" ".claude/conventions/project/$(basename "$f")"
  done
  rmdir project_conventions 2>/dev/null || true
fi

echo "== root loose files =="
# project notes / internal write-ups -> tracked, they are unrecoverable
for f in cordoba_narrative_meeting_transcript.txt minister_ppt.md \
         notes_ganaderia_faena.md notes_growth_narrative.md notes.txt \
         agri_next_steps_final.md cordoba_pizza_supply_demand_diagnostics.md \
         logistics-cost-handoff-briefing.md mining_value_chain_source_library.md; do
  mv_git "$f" "reference/notes/$f"
done
# reading material -> reference/literature/ (gitignored dir; see untrack step)
for f in oxford_econ_global_cities.pdf competitive_cities_wb_case_studies.txt \
         "Canada book.docx" "Canada’s Innovation Challenge.pptx" \
         "nuevo outline de ppt.odt"; do
  mv_git "$f" "reference/literature/$f"
done
# data -> data/raw/
mv_git AIPNET_Data_Pack_20241204.xlsx        data/raw/aipnet/AIPNET_Data_Pack_20241204.xlsx
mv_git sh_emae_actividad_base2004.xls        data/raw/indec_emae/sh_emae_actividad_base2004.xls
mv_git sh_emae_mensual_base2004.xls          data/raw/indec_emae/sh_emae_mensual_base2004.xls
mv_git zonaprop_data_jan_2026.csv            data/raw/rentals/zonaprop/2026-01-01/zonaprop_data_jan_2026.csv
mv_git "data/Copy of cep_indice_da_.xlsx"    data/raw/cep_xxi/cep_indice_da_.xlsx
# one-file scripts/ folds into scrapers/
mv_git scripts/copy_scrape_bundle.sh         scrapers/copy_scrape_bundle.sh
rmdir scripts 2>/dev/null || true

echo "== dead weight =="
# src/ is an untouched uv skeleton; main.py its stub; CLAUDE_TEMPLATE.md a stale
# copy of the r2p template; the zip is superseded by analysis/theme_gl.R
for p in src main.py CLAUDE_TEMPLATE.md gl-r-analysis-kit.zip; do
  [[ -e "$p" ]] || continue
  if [[ -n "$(git ls-files "$p")" ]]; then git rm -q -r "$p"; else rm -rf "$p"; fi
  echo "  removed: $p"
done
# agent-team scratch is process state, not a research artifact
if [[ -d agent-team-output ]]; then
  mkdir -p plan/_scratch && mv_git agent-team-output plan/_scratch/agent-team-output
fi

echo "== untrack large re-sourceable binaries (files stay on disk) =="
for f in "reference/literature/oxford_econ_global_cities.pdf" \
         "reference/literature/Canada book.docx" \
         "reference/literature/Canada’s Innovation Challenge.pptx" \
         "data/raw/aipnet/AIPNET_Data_Pack_20241204.xlsx" \
         "data/raw/rentals/zonaprop/2026-01-01/zonaprop_data_jan_2026.csv"; do
  [[ -n "$(git ls-files "$f")" ]] && git rm -q --cached "$f" && echo "  untracked: $f"
done

echo
echo "== root now =="
find . -maxdepth 1 -mindepth 1 -not -name '.git' -not -name '.venv' \
     -not -name '__pycache__' -not -name '.scc' | sort
