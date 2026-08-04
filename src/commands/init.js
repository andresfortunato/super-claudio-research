import { installProject, printNextSteps } from '../lib/install-project.js';
import { installGlobals } from '../lib/install-globals.js';
import { upgradeProject } from '../lib/upgrade.js';

export async function initCommand(options = {}) {
  const target = process.cwd();

  if (options.upgrade) {
    const ok = await upgradeProject(target, { withWiki: !!options.withWiki });
    if (!ok) return;
    await installGlobals();
    return;
  }

  const ok = await installProject(target, { withWiki: !!options.withWiki });
  if (!ok) return;

  await installGlobals();
  printNextSteps();
}
