import assert from 'node:assert/strict';
import test from 'node:test';
import { bootGame } from '../../web/game-loader.mjs';

function elements() {
  return {
    canvas: {},
    overlay: { hidden: false },
    progress: {
      value: 0,
      max: 1,
      removeAttribute(name) { delete this[name]; },
    },
    status: { textContent: '' },
    retry: { hidden: true },
  };
}

test('download uses actual byte progress and hides the overlay only after startup', async () => {
  const ui = elements();
  let finish;
  const started = new Promise((resolve) => { finish = resolve; });
  class Engine {
    static getMissingFeatures() { return []; }
    startGame({ onProgress }) {
      onProgress(25, 100);
      return started;
    }
  }
  const result = bootGame(Engine, {}, ui);
  assert.equal(ui.overlay.hidden, false);
  assert.equal(ui.progress.value, 25);
  assert.equal(ui.progress.max, 100);
  assert.match(ui.status.textContent, /25%/);
  finish();
  assert.equal(await result, true);
  assert.equal(ui.overlay.hidden, true);
});

test('unknown download size stays indeterminate', async () => {
  const ui = elements();
  class Engine {
    static getMissingFeatures() { return []; }
    async startGame({ onProgress }) { onProgress(0, 0); }
  }
  await bootGame(Engine, {}, ui);
  assert.equal('value' in ui.progress, false);
  assert.doesNotMatch(ui.status.textContent, /%/);
});

test('unsupported browsers keep a readable error instead of a black canvas', async () => {
  const ui = elements();
  class Engine {
    static getMissingFeatures() { return ['WebGL 2']; }
    startGame() { assert.fail('unsupported engine must not start'); }
  }
  assert.equal(await bootGame(Engine, {}, ui), false);
  assert.equal(ui.overlay.hidden, false);
  assert.equal(ui.retry.hidden, false);
  assert.match(ui.status.textContent, /WebGL 2/);
});

test('download failures remain visible and allow retry', async () => {
  const ui = elements();
  class Engine {
    static getMissingFeatures() { return []; }
    async startGame() { throw new Error('Network unavailable'); }
  }
  assert.equal(await bootGame(Engine, {}, ui), false);
  assert.equal(ui.overlay.hidden, false);
  assert.equal(ui.retry.hidden, false);
  assert.match(ui.status.textContent, /Network unavailable/);
});
