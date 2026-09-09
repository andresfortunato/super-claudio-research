import { readFile, writeFile, open, stat, unlink, readdir } from 'node:fs/promises';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FRAMEWORK_ROOT = resolve(__dirname, '../..');
const TEMPLATE = join(FRAMEWORK_ROOT, 'templates/research/evidence/EXAMPLE_01_slug.md');

const SLUG_PATTERN = /^[a-z][a-z0-9_]*$/;

// Lock tuning. `wait` is generous because the work under the lock is three
// small file operations; if we are waiting longer than this, something is wrong
// rather than busy. `stale` is what lets a crashed session stop blocking the
// project forever — a lock older than this is assumed abandoned.
const LOCK_WAIT_MS = 10_000;
const LOCK_STALE_MS = 30_000;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Run `fn` while holding an exclusive lock on the evidence counter.
 *
 * This is the whole point of the command. `.next-id` shipped in v2 and
 * `evidence.md` names it as the source of ids, but nothing read or wrote it, so
 * allocation was advice — and advice does not survive a fan-out. The pilot
 * accumulated three colliding ids (#119, #131, #139) from same-day parallel
 * agents each deriving "the next id" from `ls`, and the collision has now
 * appeared five times by three distinct vectors.
 *
 * `open(path, 'wx')` is O_CREAT|O_EXCL: the kernel guarantees exactly one
 * caller creates the file. A read-then-write without it has a window between
 * the read and the write in which a second agent reads the same number, which
 * is precisely how the three collisions happened.
 */
async function withCounterLock(evDir, fn) {
  const lockPath = join(evDir, '.next-id.lock');
  const deadline = Date.now() + LOCK_WAIT_MS;
  let handle;

  for (;;) {
    try {
      handle = await open(lockPath, 'wx');
      break;
    } catch (err) {
      if (err.code !== 'EEXIST') throw err;

      // A lock left behind by a crashed run. Break it rather than making the
      // researcher find and delete a dotfile they have never heard of.
      try {
        const st = await stat(lockPath);
        if (Date.now() - st.mtimeMs > LOCK_STALE_MS) {
          console.warn(`  ! breaking a stale lock (${lockPath}, untouched for >30s)`);
          await unlink(lockPath);
          continue;
        }
      } catch {
        continue; // vanished between the failed open and the stat — retry
      }

      if (Date.now() > deadline) {
        throw new Error(
          `timed out waiting for ${lockPath}. Another allocation is holding it; ` +
            'if no other session is running, delete the file and retry.',
        );
      }
      // Jitter matters. Without it a fan-out of N agents retries in lockstep
      // and the same one keeps winning.
      await sleep(25 + Math.random() * 75);
    }
  }

  try {
    await handle.writeFile(`${process.pid}\n`);
    return await fn();
  } finally {
    await handle.close();
    await unlink(lockPath).catch(() => {});
  }
}

/** Highest id already on disk, recursively — a subdirectory is a namespace, not a hiding place. */
async function highestIdOnDisk(evDir) {
  let highest = 0;
  const walk = async (dir) => {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of entries) {
      if (e.isDirectory()) {
        await walk(join(dir, e.name));
        continue;
      }
      const m = /^(\d+)_.*\.md$/.exec(e.name);
      if (m) highest = Math.max(highest, parseInt(m[1], 10));
    }
  };
  await walk(evDir);
  return highest;
}

/**
 * Fill the template's frontmatter for a freshly allocated doc.
 *
 * `id` and `date` are the only fields set. `unit`, `geography` and `period` are
 * blanked rather than left at their template defaults, because a default is a
 * guess that reads as a statement: `unit: province` on a doc about a metro area
 * is the false-contradiction machine `evidence.md` § scope keys exists to
 * prevent, and v2 already shipped an inference that tagged a 24-province panel
 * `metro | 1960–2026`. A blank makes a reader open the doc; a wrong value makes
 * them trust it. Nothing here is ever derived from the slug.
 */
function fillFrontmatter(template, id, today) {
  return template
    .replace(/^id: .*$/m, `id: ${id}`)
    .replace(/^date: .*$/m, `date: ${today}`)
    .replace(/^unit: \S+(\s+#.*)?$/m, (_, c) => `unit:${c ? ` ${c.trim()}` : ''}`)
    .replace(/^geography: .*$/m, 'geography:')
    .replace(/^period: \S+(\s+#.*)?$/m, (_, c) => `period:${c ? ` ${c.trim()}` : ''}`);
}

export async function evidenceNew(rawSlug) {
  if (!rawSlug) {
    console.error('Error: slug is required.');
    console.error('Usage: r2p evidence new <slug>');
    console.error('Examples: formal_employment, export_concentration, wage_gradient');
    process.exit(1);
  }

  // Hyphens are the plan-slug convention; evidence docs use underscores
  // (`research/evidence/NN_<short_slug>.md`). Convert rather than reject, but
  // say so — a silently renamed file is worse than a slower one.
  const slug = rawSlug.replace(/-/g, '_');
  if (slug !== rawSlug) console.log(`  ~ slug "${rawSlug}" -> "${slug}" (evidence slugs use underscores)`);

  if (!SLUG_PATTERN.test(slug)) {
    console.error(
      `Error: slug "${slug}" must be lowercase letters, digits or underscores, starting with a letter.`,
    );
    process.exit(1);
  }

  const target = process.cwd();
  const evDir = join(target, 'research/evidence');
  const counter = join(evDir, '.next-id');

  try {
    await stat(evDir);
  } catch {
    console.error(`Error: ${evDir} does not exist. Run this from a project root scaffolded by \`r2p init\`.`);
    process.exit(1);
  }

  let template;
  try {
    template = await readFile(TEMPLATE, 'utf8');
  } catch {
    console.error(`Error: cannot read the evidence template at ${TEMPLATE}.`);
    process.exit(1);
  }

  let created;
  try {
    created = await withCounterLock(evDir, async () => {
      let raw;
      try {
        raw = await readFile(counter, 'utf8');
      } catch {
        throw new Error(
          `${counter} is missing, and this command will not guess the next id — deriving it ` +
            'from a directory listing is how the pilot produced three colliding ids. ' +
            'Run `r2p init --upgrade`, or create the file holding one more than your highest id.',
        );
      }

      const id = parseInt(raw.trim(), 10);
      if (!Number.isInteger(id) || id < 1) {
        throw new Error(`${counter} holds "${raw.trim()}", which is not a positive integer.`);
      }

      // Lint invariant 11, enforced where it can still prevent something rather
      // than report it. If the counter is behind the corpus, allocating from it
      // hands out an id that is already taken.
      const highest = await highestIdOnDisk(evDir);
      if (id <= highest) {
        throw new Error(
          `${counter} is ${id} but the highest id on disk is ${highest}, so allocating from it ` +
            `would collide. Set the counter to ${highest + 1} and retry.`,
        );
      }

      const name = `${String(id).padStart(2, '0')}_${slug}.md`;
      const docPath = join(evDir, name);
      const today = new Date().toISOString().slice(0, 10);

      // 'wx' again: never overwrite an evidence doc. The corpus is append-only.
      let fh;
      try {
        fh = await open(docPath, 'wx');
      } catch (err) {
        if (err.code === 'EEXIST') throw new Error(`${docPath} already exists; refusing to overwrite.`);
        throw err;
      }
      try {
        await fh.writeFile(fillFrontmatter(template, id, today));
      } finally {
        await fh.close();
      }

      // Bump last. If the doc write failed we have not moved the counter, so a
      // retry gets the same id rather than burning one.
      await writeFile(counter, `${id + 1}\n`);
      return { id, docPath, name };
    });
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  }

  console.log(`  + research/evidence/${created.name}  (id ${created.id}, .next-id now ${created.id + 1})`);
  console.log('    Fill headline, unit, geography and period by hand — nothing infers them.');
  console.log(`    Add its row to research/evidence/INDEX.md when the headline is written.`);
}
