# Project conventions — index

Lightweight, on-demand convention docs for project-bespoke
style and process rules. Read the relevant file when work
touches that domain — analogous to `.claude/conventions/`,
but project-specific and read-on-demand rather than auto-loaded.

---

## Quick navigation

| If you're working on… | Read |
|---|---|
| Charts, plots, or any visual output | `EXAMPLE_visualization.md` |

Sort rows by likely access frequency. One row per file. If the
folder grows past ~5 files, that's a healthy pilot — past ~10,
ask whether two files have collapsed into one domain.

---

## How to add a new convention

When the project commits to a recurring style or process call
(visualization color rules, writing voice, slide design, naming
idioms), follow the recipe in
`.claude/conventions/project-conventions.md` (full protocol).
The short form:

1. **Identify the domain.** One file per domain. Lowercase
   snake_case. Match the row in this INDEX. Common domains:
   `visualization.md`, `writing_guidelines.md`,
   `slide_design.md`, `naming.md`.
2. **Open the file with a triggering line.** "Use this
   document whenever \<situation\>." This is the cue that
   tells Claude when to load the file on demand. Without it,
   on-demand loading degrades to "load everything, just in
   case."
3. **Write rules in whatever shape the domain calls for.**
   Color tables, voice guidance, file-naming patterns,
   layout notes — concrete examples beat abstract principles.
   No required internal sections.
4. **Add a row to the Quick navigation table** above so
   future-you finds it.

Edit files in place when rules change. Don't append "UPDATE:
now use blue." Git history is the version log; the doc reads
as current truth.
