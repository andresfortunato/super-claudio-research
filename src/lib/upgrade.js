// Upgrade flow: pulls framework changes (under .claude/conventions/ and
// templates/) into a target project non-destructively. For each candidate
// file:
//   - absent in project           → copy in (log "+ <rel>")
//   - present and byte-identical  → silent skip
//   - present and divergent       → write "<rel>.framework-new" sidecar
//     (never overwrite the live file) and add to a tally
//
// Also runs a one-shot v1→v2 path migration before the file sweep: renames
// pre-rename layout (insights/, top-level raw/, top-level sources/) into the
// current shape (evidence/, wiki/raw/, wiki/raw/registry.yaml). Only safe
// renames execute; ambiguous cases are surfaced as warnings.
//
// At the end, prints a one-line summary and (separately) a one-line warning
// if the project still has the obsolete <project>/.claude/skills/ directory
// from a pre-Phase-3 install layout. Never auto-deletes anything.
//
// Excludes: files the user actively customizes — CLAUDE.md.template (the
// user edits CLAUDE.md immediately on install), various INDEX.md / log.md /
// registry.yaml / wiki-index files the user appends rows or content to, and
// loose template files (handoff.md, decision-record.md) that don't have a
// fixed project counterpart.

import {
  mkdir,
  copyFile,
  readFile,
  writeFile,
  access,
  stat,
  chmod,
  readdir,
  rename,
  unlink,
} from 'node:fs/promises';
import { join, dirname, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FRAMEWORK_ROOT = resolve(__dirname, '../..');

// Paths are relative to FRAMEWORK_ROOT. Match exactly.
const EXCLUDE = new Set([
  'templates/CLAUDE.md.template',
  'templates/evidence/INDEX.md',
  'templates/wiki/index.md',
  'templates/wiki/log.md',
  'templates/wiki/raw/registry.yaml',
  'templates/wiki/raw/seen.jsonl',
  'templates/data_sources/INDEX.md',
  'templates/project_conventions/INDEX.md',
  // Archivist appends rows here across sessions; framework never overwrites.
  'templates/archive/index.md',
  // Loose templates referenced from convention docs; no fixed project copy.
  'templates/handoff.md',
  'templates/decision-record.md',
]);

// Gitignore lines the framework requires. Upgrade appends any missing on an
// existing project that already has a framework block — keeps `r2p init
// --upgrade` self-contained when new gitignored slots ship.
const REQUIRED_GITIGNORE_LINES = [
  'internal_docs/',
  'literature/',
  '.env',
  '.env.*',
  '!.env.example',
  'data/*',
  '!data/README.md',
];

async function fileExists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

async function isFrameworkRepo(target) {
  const pkgPath = join(target, 'package.json');
  if (!(await fileExists(pkgPath))) return false;
  try {
    const pkg = JSON.parse(await readFile(pkgPath, 'utf-8'));
    return pkg.name === 'research-to-policy';
  } catch {
    return false;
  }
}

// Project-relative path for a given framework-relative path.
//   templates/foo/bar.md         → foo/bar.md
//   .claude/conventions/x.md     → .claude/conventions/x.md
function toProjectRel(frameworkRel) {
  const prefix = 'templates/';
  if (frameworkRel.startsWith(prefix)) return frameworkRel.slice(prefix.length);
  return frameworkRel;
}

// Recursively yield framework-relative file paths under `frameworkRel`.
async function* walkFiles(frameworkRel) {
  const absDir = join(FRAMEWORK_ROOT, frameworkRel);
  let entries;
  try {
    entries = await readdir(absDir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.name === '.gitkeep') continue;
    const childRel = `${frameworkRel}/${entry.name}`;
    if (entry.isDirectory()) {
      yield* walkFiles(childRel);
    } else if (entry.isFile()) {
      yield childRel;
    }
  }
}

async function compareFiles(srcPath, dstPath) {
  const srcStat = await stat(srcPath);
  const dstStat = await stat(dstPath);
  if (srcStat.size !== dstStat.size) return false;
  const [srcBuf, dstBuf] = await Promise.all([readFile(srcPath), readFile(dstPath)]);
  return srcBuf.equals(dstBuf);
}

// Move oldPath → newPath if safe. Safe = oldPath exists, newPath doesn't.
// Returns one of: 'renamed' | 'already-new' | 'no-old' | 'both-exist'.
async function safeRename(target, oldRel, newRel, label) {
  const oldPath = join(target, oldRel);
  const newPath = join(target, newRel);
  const oldHas = await fileExists(oldPath);
  const newHas = await fileExists(newPath);
  if (!oldHas && newHas) return 'already-new';
  if (!oldHas && !newHas) return 'no-old';
  if (oldHas && newHas) {
    console.log(`  ⚠ migrate skipped: ${oldRel} AND ${newRel} both exist — resolve manually.`);
    return 'both-exist';
  }
  await mkdir(dirname(newPath), { recursive: true });
  await rename(oldPath, newPath);
  console.log(`  ↻ migrated ${label}: ${oldRel} → ${newRel}`);
  return 'renamed';
}

// One-shot v1→v2 layout migration. Renames:
//   insights/                              → evidence/
//   raw/                                   → wiki/raw/   (merges into wiki/)
//   raw/sources/<slug>/                    → wiki/raw/scraped/<slug>/  (via the move above)
//   sources/registry.yaml                  → wiki/raw/registry.yaml
//   sources/seen.jsonl                     → wiki/raw/seen.jsonl
//   .claude/hooks/check-insights.sh        → .claude/hooks/check-evidence.sh
//   .claude/conventions/insights-logging.md → .claude/conventions/evidence-logging.md
//   docs/insights-mechanism.md (if vendored) → docs/evidence-mechanism.md
// Each rename is skipped if both old and new exist (user resolves manually).
async function migrateLayout(target) {
  let touched = 0;
  const renames = [
    ['insights', 'evidence', 'evidence folder'],
    ['raw', 'wiki/raw', 'raw archive folder'],
    ['sources/registry.yaml', 'wiki/raw/registry.yaml', 'scrape registry'],
    ['sources/seen.jsonl', 'wiki/raw/seen.jsonl', 'dedup ledger'],
    ['.claude/hooks/check-insights.sh', '.claude/hooks/check-evidence.sh', 'evidence hook'],
    [
      '.claude/conventions/insights-logging.md',
      '.claude/conventions/evidence-logging.md',
      'evidence convention',
    ],
  ];
  for (const [oldRel, newRel, label] of renames) {
    const result = await safeRename(target, oldRel, newRel, label);
    if (result === 'renamed') touched++;
  }
  // Tidy: remove empty sources/ and sources/README.md after migration.
  const sourcesDir = join(target, 'sources');
  if (await fileExists(sourcesDir)) {
    try {
      const remaining = await readdir(sourcesDir);
      const onlyReadme = remaining.length === 1 && remaining[0] === 'README.md';
      const empty = remaining.length === 0;
      if (onlyReadme) {
        await unlink(join(sourcesDir, 'README.md'));
        console.log('  ↻ removed legacy sources/README.md (content moved to wiki/raw/README.md)');
      }
      if (onlyReadme || empty) {
        await readdir(sourcesDir).then((files) =>
          files.length === 0 ? import('node:fs/promises').then((m) => m.rmdir(sourcesDir)) : null,
        );
        console.log('  ↻ removed empty legacy sources/ directory');
        touched++;
      }
    } catch {
      // best-effort tidy; skip silently if it doesn't apply
    }
  }
  return touched;
}

export async function upgradeProject(target) {
  if (await isFrameworkRepo(target)) {
    console.log('Refusing to run r2p init --upgrade against the framework repo itself.');
    console.log('  r2p init --upgrade is for target research projects, not research-to-policy.');
    return false;
  }

  console.log(`Upgrading research-to-policy framework files in: ${target}`);

  // 0. One-shot layout migration (insights→evidence, raw→wiki/raw, sources→wiki/raw).
  const migrated = await migrateLayout(target);
  if (migrated > 0) {
    console.log('');
  }

  const candidates = [];
  for await (const rel of walkFiles('.claude/conventions')) candidates.push(rel);
  for await (const rel of walkFiles('.claude/hooks')) candidates.push(rel);
  for await (const rel of walkFiles('templates')) {
    if (!EXCLUDE.has(rel)) candidates.push(rel);
  }
  // settings.template.json is a single tracked file — surface as sidecar so
  // users can diff against their runtime .claude/settings.json.
  candidates.push('.claude/settings.template.json');

  let copied = 0;
  let identical = 0;
  const sidecars = [];

  for (const frameworkRel of candidates) {
    const srcPath = join(FRAMEWORK_ROOT, frameworkRel);
    const projectRel = toProjectRel(frameworkRel);
    const dstPath = join(target, projectRel);

    if (!(await fileExists(dstPath))) {
      await mkdir(dirname(dstPath), { recursive: true });
      await copyFile(srcPath, dstPath);
      if (projectRel.startsWith('.claude/hooks/') && projectRel.endsWith('.sh')) {
        await chmod(dstPath, 0o755);
      }
      console.log(`  + ${projectRel}`);
      copied++;
      continue;
    }

    if (await compareFiles(srcPath, dstPath)) {
      identical++;
      continue;
    }

    const sidecarPath = `${dstPath}.framework-new`;
    await copyFile(srcPath, sidecarPath);
    const sidecarRel = relative(target, sidecarPath);
    console.log(`  ⚠ ${sidecarRel} (divergent — sidecar written, original untouched)`);
    sidecars.push(sidecarRel);
  }

  // CLAUDE.md handling: never overwrite a user-curated CLAUDE.md. If one
  // exists, (re)write CLAUDE_TEMPLATE.md alongside so the user always has the
  // current framework template to diff against. If CLAUDE.md is absent, drop
  // the template in directly — matches install-project.js behavior.
  const claudePath = join(target, 'CLAUDE.md');
  const claudeTemplateSrc = join(FRAMEWORK_ROOT, 'templates/CLAUDE.md.template');
  if (await fileExists(claudePath)) {
    const sidecarPath = join(target, 'CLAUDE_TEMPLATE.md');
    const sidecarExists = await fileExists(sidecarPath);
    if (!sidecarExists || !(await compareFiles(claudeTemplateSrc, sidecarPath))) {
      await copyFile(claudeTemplateSrc, sidecarPath);
      console.log(
        sidecarExists
          ? '  ↻ CLAUDE_TEMPLATE.md (refreshed from framework — CLAUDE.md untouched)'
          : '  + CLAUDE_TEMPLATE.md (reference copy — CLAUDE.md untouched)',
      );
    }
  } else {
    await copyFile(claudeTemplateSrc, claudePath);
    console.log('  + CLAUDE.md (from template — edit it for your project)');
  }

  // Backfill any newly-required gitignore lines so existing projects pick
  // up new gitignored slots (e.g. internal_docs/, literature/) without a
  // manual edit. Only acts on files that already contain a framework block.
  const gitignorePath = join(target, '.gitignore');
  if (await fileExists(gitignorePath)) {
    const existing = await readFile(gitignorePath, 'utf-8');
    if (existing.includes('research-to-policy framework')) {
      const lines = existing.split('\n').map((l) => l.trim());
      const missing = REQUIRED_GITIGNORE_LINES.filter(
        (line) => !lines.includes(line),
      );
      if (missing.length > 0) {
        const block =
          '\n# r2p framework — gitignore additions (' +
          new Date().toISOString().slice(0, 10) +
          ')\n' +
          missing.join('\n') +
          '\n';
        await writeFile(gitignorePath, existing.trimEnd() + '\n' + block);
        console.log(`  + .gitignore (appended: ${missing.join(', ')})`);
      }
    }
  }

  // Old-shape skills layout warning. Skills now live globally in
  // ~/.claude/skills/; a project-local .claude/skills/ is leftover from the
  // old install.sh layout and should be removed manually.
  const oldSkillsDir = join(target, '.claude', 'skills');
  if (await fileExists(oldSkillsDir)) {
    console.log('');
    console.log(
      '  ⚠ .claude/skills/ exists in this project — obsolete (skills now live globally in ~/.claude/skills/).',
    );
    console.log('    Run `rm -rf .claude/skills/` to clean up. Not deleting automatically.');
  }

  console.log('');
  if (sidecars.length === 0 && copied === 0 && migrated === 0) {
    console.log('No upgrades needed — project is in sync with the framework.');
  } else if (sidecars.length === 0) {
    console.log(
      `Upgrade complete: ${migrated} migration(s), ${copied} new file(s) added, ${identical} unchanged.`,
    );
  } else {
    console.log(
      `${sidecars.length} file(s) have framework-new sidecars; review with \`git diff\` or your editor.`,
    );
    if (copied > 0 || migrated > 0)
      console.log(
        `  (${migrated} migration(s), ${copied} new file(s) added, ${identical} unchanged.)`,
      );
  }

  return true;
}
