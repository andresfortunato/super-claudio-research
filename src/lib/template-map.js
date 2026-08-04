// Where each templates/ path lands inside a project.
//
// This exists because `install-project.js` and `upgrade.js` both need the answer
// and both used to derive it independently: install carried an explicit MIRRORS
// table, upgrade just stripped the `templates/` prefix. That drift is a shipped
// bug — the v2 layout renamed two template dirs precisely because their project
// destinations differ from their template names, so `r2p init --upgrade` wrote
// `claude_conventions_project/`, `plan_dir/` and `migration/` into project roots
// as new top-level directories. On a framework whose v2 release was about
// getting a project down to eight legible root dirs, the upgrade path was
// quietly adding three junk ones.
//
// One table, two consumers. Add a template directory here, not in either file.

// Template dir → project dir, for the dirs whose names differ or that nest.
// Order matters for prefix matching: longest prefix wins, so list specific
// paths before their parents.
export const TEMPLATE_DIR_MAP = [
  ['templates/plan_dir', 'plan'],
  ['templates/claude_conventions_project', '.claude/conventions/project'],
  ['templates/research', 'research'],
  ['templates/deliverables', 'deliverables'],
  ['templates/data', 'data'],
  ['templates/reference', 'reference'],
];

// templates/ paths that never get a project copy. `install-project.js` achieves
// this by only mirroring what is in TEMPLATE_DIR_MAP; `upgrade.js` walks all of
// templates/ and so has to be told. Keep the two in agreement: anything here is
// something `r2p init` does not install, and therefore something `--upgrade`
// must not introduce.
export const TEMPLATE_NOT_INSTALLED = [
  // Migration scripts are run from the framework repo against a project, and
  // are meant to be read and adapted rather than vendored per-project.
  'templates/migration/',
  // The plan seed is scaffolded per-plan by `r2p plan init <slug>` into
  // plan/plan-<slug>/plan.md. A bare plan/plan.md is meaningless.
  'templates/plan/',
  // Handled separately by both installers.
  'templates/CLAUDE.md.template',
  'templates/.env.example',
  // Loose template referenced from convention docs; no fixed project copy.
  'templates/handoff.md',
];

// True when a framework-relative templates/ path gets no project copy at all.
export function isNotInstalled(frameworkRel) {
  return TEMPLATE_NOT_INSTALLED.some((p) =>
    p.endsWith('/') ? frameworkRel.startsWith(p) : frameworkRel === p,
  );
}

// Map a framework-relative path to its project-relative destination. Returns
// null when the path gets no project copy.
export function toProjectRel(frameworkRel) {
  if (!frameworkRel.startsWith('templates/')) return frameworkRel;
  if (isNotInstalled(frameworkRel)) return null;

  // Longest prefix wins so templates/plan_dir/... never matches templates/plan/.
  const sorted = [...TEMPLATE_DIR_MAP].sort((a, b) => b[0].length - a[0].length);
  for (const [from, to] of sorted) {
    if (frameworkRel === from) return to;
    if (frameworkRel.startsWith(`${from}/`)) {
      return `${to}${frameworkRel.slice(from.length)}`;
    }
  }
  // Unmapped templates/ path: fall back to stripping the prefix, which is what
  // upgrade.js did for everything before this table existed.
  return frameworkRel.slice('templates/'.length);
}
