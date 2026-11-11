import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fingerprintWeb } from '../../scripts/web/fingerprint.mjs';

const player = `<link href="site.css"><link href="game-loader.css">
<script type="module">
import { bootGame } from './game-loader.mjs';
import { bindGameViewport } from './game-viewport.mjs';
script.src = 'play.js';
const config = {"executable":"play","fileSizes":{"play.pck":100,"play.wasm":200}};
</script>`;
const staticNames = ['site.css', 'game-loader.css', 'game-loader.mjs', 'game-viewport.mjs'];
const runtimeNames = ['play.js', 'play.wasm', 'play.pck', 'play.audio.worklet.js', 'play.audio.position.worklet.js'];

async function fixture(t) {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'paper-warrior-cache-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  await writeFile(path.join(dir, 'play.html'), player);
  for (const name of [...staticNames, ...runtimeNames]) await writeFile(path.join(dir, name), name);
  return dir;
}

test('runtime filenames, executable and size keys agree without changing virtual pack syntax', async (t) => {
  const dir = await fixture(t);
  await fingerprintWeb(dir);
  const html = await readFile(path.join(dir, 'play.html'), 'utf8');
  const config = JSON.parse(html.match(/const config = (.*);/)[1]);
  assert.match(config.executable, /^play-[a-f0-9]{16}$/);
  const files = await readdir(dir);
  for (const name of runtimeNames) {
    const renamed = name.replace('play', config.executable);
    assert.ok(files.includes(renamed), renamed);
    assert.ok(!files.includes(name), `unversioned runtime leaked: ${name}`);
  }
  assert.ok(html.includes(`'${config.executable}.js'`));
  assert.deepEqual(config.fileSizes, { [`${config.executable}.pck`]: 100, [`${config.executable}.wasm`]: 200 });
  assert.doesNotMatch(html, /\.pck\?/);
  for (const name of staticNames) assert.match(html, new RegExp(`${name.replaceAll('.', '\\.')}\\?v=[a-f0-9]{16}`));
});

test('changed builds cannot reuse cached runtime or loader URLs', async (t) => {
  const first = await fixture(t);
  const next = await fixture(t);
  await fingerprintWeb(first);
  const before = await readFile(path.join(first, 'play.html'), 'utf8');
  await writeFile(path.join(next, 'play.pck'), 'changed game pack');
  await writeFile(path.join(next, 'game-loader.mjs'), 'changed loader');
  await fingerprintWeb(next);
  const after = await readFile(path.join(next, 'play.html'), 'utf8');
  assert.notEqual(before.match(/"executable":"(.*?)"/)[1], after.match(/"executable":"(.*?)"/)[1]);
  assert.notEqual(before.match(/game-loader\.mjs\?v=(.*?)'/)[1], after.match(/game-loader\.mjs\?v=(.*?)'/)[1]);
});
