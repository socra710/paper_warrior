import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

test('landing uses the same concept sprite sheet as the game and crops its first frame', async () => {
  const [html, css, build, scene] = await Promise.all([
    readFile(new URL('../../web/index.html', import.meta.url), 'utf8'),
    readFile(new URL('../../web/site.css', import.meta.url), 'utf8'),
    readFile(new URL('../../scripts/web/build.mjs', import.meta.url), 'utf8'),
    readFile(new URL('../../scenes/characters/concept_warrior.tscn', import.meta.url), 'utf8'),
  ]);
  assert.match(scene, /res:\/\/assets\/characters\/warrior\/concept_idle_walk_run\.png/);
  assert.match(html, /src="assets\/concept_idle_walk_run\.png"/);
  assert.match(html, /class="hero-art"/);
  assert.match(css, /\.hero-art\s*\{[^}]*overflow:\s*hidden/);
  assert.match(css, /\.hero-sprite\s*\{[^}]*width:\s*1600%/);
  assert.match(build, /'concept_idle_walk_run\.png'/);
});
