import { evidenceNew } from '../lib/evidence-new.js';

export async function evidenceNewCommand(slug) {
  await evidenceNew(slug);
}
