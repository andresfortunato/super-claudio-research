// Per-project install: ports the project-level work of install.sh into Node.
// Skills/agents are NOT mirrored here — Phase 3 handles those as global symlinks
// to ~/.claude/{skills,agents}/.

import {
  mkdir,
  copyFile,
  readFile,
  writeFile,
  access,
  stat,
  chmod,
  readdir,
} from 'node:fs/promises';
import { join, dirname, basename, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FRAMEWORK_ROOT = resolve(__dirname, '../..');

const SCAFFOLDING_DIRS = [
  'insights',
  'wiki',
  'raw',
  'deliverables',
  'sources',
  'data',
  'data_sources',
  'methods',
  'project_conventions',
  'brainstorms',
  'learnings',
  'archive',
  'internal_docs',
  'literature',
  'slides',
];

// Gitignore block emitted into target projects. Diverges from install.sh's
// version: no !.claude/skills/ or !.claude/skills/** entries — those are
// obsolete now that skills live in ~/.claude/skills/ globally.
const GITIGNORE_BLOCK = `# research-to-policy framework — share scaffolding, hide local state
.claude/*
!.claude/conventions/
!.claude/conventions/**
!.claude/hooks/
!.claude/hooks/**
!.claude/settings.json

# Framework working state — local to each researcher's machine
plan/
brainstorms/
.scc/

# Project-management docs (concept notes, workplans, mission plans, team notes)
internal_docs/

# Reference literature (large PDFs, often copyrighted)
literature/

# Secrets and per-machine config (see .env.example for the contract)
.env
.env.*
!.env.example

# Local cached data — large binaries; data/README.md is the committed inventory
data/*
!data/README.md
`;

async function fileExists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

async function copyDirRecursive(src, dst) {
  await mkdir(dst, { recursive: true });
  const entries = await readdir(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = join(src, entry.name);
    const dstPath = join(dst, entry.name);
    if (entry.isDirectory()) {
      await copyDirRecursive(srcPath, dstPath);
    } else if (entry.isFile()) {
      await copyFile(srcPath, dstPath);
    }
  }
}

async function copyIfAbsent(src, dst, target) {
  const name = basename(src);
  if (name === '.gitkeep') return;
  const rel = relative(target, dst);
  if (await fileExists(dst)) {
    console.log(`  ~ ${rel} (exists, skipping)`);
    return;
  }
  const srcStat = await stat(src);
  if (srcStat.isDirectory()) {
    await copyDirRecursive(src, dst);
  } else {
    await mkdir(dirname(dst), { recursive: true });
    await copyFile(src, dst);
  }
  console.log(`  + ${rel}`);
}

async function mirrorDir(srcDir, dstDir, target) {
  if (!(await fileExists(srcDir))) return;
  await mkdir(dstDir, { recursive: true });
  const entries = await readdir(srcDir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name === '.gitkeep') continue;
    await copyIfAbsent(join(srcDir, entry.name), join(dstDir, entry.name), target);
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

export async function installProject(target) {
  if (await isFrameworkRepo(target)) {
    console.log('Refusing to run r2p init against the framework repo itself.');
    console.log('  r2p init is for target research projects, not research-to-policy.');
    return false;
  }

  console.log(`Installing research-to-policy into: ${target}`);

  // 1. Conventions and hooks. Skills mirror is gone — Phase 3 handles globals.
  await mirrorDir(
    join(FRAMEWORK_ROOT, '.claude/conventions'),
    join(target, '.claude/conventions'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, '.claude/hooks'),
    join(target, '.claude/hooks'),
    target,
  );

  // Hooks must be executable.
  const hooksDir = join(target, '.claude/hooks');
  if (await fileExists(hooksDir)) {
    const hookEntries = await readdir(hooksDir, { withFileTypes: true });
    for (const entry of hookEntries) {
      if (entry.isFile() && entry.name.endsWith('.sh')) {
        await chmod(join(hooksDir, entry.name), 0o755);
      }
    }
  }

  // 2. settings.json (only if absent — user customizations preserved)
  const settingsPath = join(target, '.claude/settings.json');
  if (!(await fileExists(settingsPath))) {
    await mkdir(join(target, '.claude'), { recursive: true });
    await copyFile(
      join(FRAMEWORK_ROOT, '.claude/settings.template.json'),
      settingsPath,
    );
    console.log('  + .claude/settings.json (from template)');
  } else {
    console.log(
      '  ~ .claude/settings.json (exists — merge new hook entries manually if needed)',
    );
  }

  // 3. Project-level scaffolding
  for (const dir of SCAFFOLDING_DIRS) {
    await mkdir(join(target, dir), { recursive: true });
  }
  await copyIfAbsent(
    join(FRAMEWORK_ROOT, 'templates/insights/INDEX.md'),
    join(target, 'insights/INDEX.md'),
    target,
  );
  await mirrorDir(join(FRAMEWORK_ROOT, 'templates/wiki'), join(target, 'wiki'), target);
  await mirrorDir(join(FRAMEWORK_ROOT, 'templates/raw'), join(target, 'raw'), target);
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/deliverables'),
    join(target, 'deliverables'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/sources'),
    join(target, 'sources'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/data_sources'),
    join(target, 'data_sources'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/data'),
    join(target, 'data'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/methods'),
    join(target, 'methods'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/project_conventions'),
    join(target, 'project_conventions'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/brainstorms'),
    join(target, 'brainstorms'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/learnings'),
    join(target, 'learnings'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/archive'),
    join(target, 'archive'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/internal_docs'),
    join(target, 'internal_docs'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/literature'),
    join(target, 'literature'),
    target,
  );
  await mirrorDir(
    join(FRAMEWORK_ROOT, 'templates/slides'),
    join(target, 'slides'),
    target,
  );

  // 4. sources/seen.jsonl (empty seed — append-only dedup log)
  const seenPath = join(target, 'sources/seen.jsonl');
  if (!(await fileExists(seenPath))) {
    await writeFile(seenPath, '');
    console.log('  + sources/seen.jsonl (empty seed)');
  } else {
    console.log('  ~ sources/seen.jsonl (exists, leaving as-is)');
  }

  // 5. CLAUDE.md (only if absent — never overwrite). If one exists, drop the
  // framework template as CLAUDE_TEMPLATE.md so the user can diff and merge.
  const claudePath = join(target, 'CLAUDE.md');
  const templateSrc = join(FRAMEWORK_ROOT, 'templates/CLAUDE.md.template');
  if (!(await fileExists(claudePath))) {
    await copyFile(templateSrc, claudePath);
    console.log('  + CLAUDE.md (from template — edit it for your project)');
  } else {
    const sidecarPath = join(target, 'CLAUDE_TEMPLATE.md');
    await copyFile(templateSrc, sidecarPath);
    console.log(
      '  ~ CLAUDE.md (exists — wrote CLAUDE_TEMPLATE.md alongside for reference; merge pointer blocks manually)',
    );
  }

  // 6. .env.example — committed contract for env vars (.env stays local)
  const envExamplePath = join(target, '.env.example');
  const envExampleSrc = join(FRAMEWORK_ROOT, 'templates/.env.example');
  if (!(await fileExists(envExamplePath))) {
    await copyFile(envExampleSrc, envExamplePath);
    console.log('  + .env.example (from template — edit for your project)');
  } else {
    console.log('  ~ .env.example (exists, leaving as-is)');
  }

  // 7. .gitignore — share framework scaffolding, hide local state
  const gitignorePath = join(target, '.gitignore');
  if (await fileExists(gitignorePath)) {
    const existing = await readFile(gitignorePath, 'utf-8');
    if (existing.includes('research-to-policy framework')) {
      console.log(
        '  ~ .gitignore (framework block already present — review manually if upgrading from an older install)',
      );
    } else {
      await writeFile(gitignorePath, existing.trimEnd() + '\n\n' + GITIGNORE_BLOCK);
      console.log('  + .gitignore (appended framework block)');
    }
  } else {
    await writeFile(gitignorePath, GITIGNORE_BLOCK);
    console.log('  + .gitignore (created with framework block)');
  }

  return true;
}

export function printNextSteps() {
  console.log('');
  console.log('Done. Next steps:');
  console.log('  1. Edit CLAUDE.md to fit your project.');
  console.log('  2. Verify .claude/settings.json hooks list matches what you want enabled.');
  console.log('  3. Test the insights hook:');
  console.log('       touch output/06_test_chart.png   # simulate analysis');
  console.log('       bash .claude/hooks/check-insights.sh   # should print JSON');
  console.log('       rm output/06_test_chart.png');
  console.log('');
  console.log('  Adopting a pre-framework project? See docs/r2p-adopt.md in the');
  console.log('  framework repo. It is a plain instruction doc, not an installed');
  console.log('  skill — paste a prompt at Claude pointing to that path and it will');
  console.log('  run the one-shot adoption audit. Greenfield? Skip; nothing to do.');
}
