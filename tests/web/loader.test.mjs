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

test('finished downloads do not claim the engine has finished initializing', async () => {
  const ui = elements();
  let finish;
  class Engine {
    static getMissingFeatures() { return []; }
    startGame({ onProgress }) {
      onProgress(100, 100);
      return new Promise((resolve) => { finish = resolve; });
    }
  }
  const result = bootGame(Engine, {}, ui);
  assert.equal('value' in ui.progress, false);
  assert.doesNotMatch(ui.status.textContent, /100%/);
  assert.equal(ui.overlay.hidden, false);
  finish();
  assert.equal(await result, true);
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

test('duplicate startup calls share the same engine, including after success', async () => {
  const ui = elements();
  let created = 0;
  let finish;
  class Engine {
    static getMissingFeatures() { return []; }
    constructor() { created++; }
    startGame() { return new Promise((resolve) => { finish = resolve; }); }
  }
  const first = bootGame(Engine, {}, ui);
  const second = bootGame(Engine, {}, ui);
  assert.equal(created, 1);
  finish();
  assert.equal(await first, true);
  assert.equal(await second, true);
  assert.equal(await bootGame(Engine, {}, ui), true);
  assert.equal(created, 1);
});

test('stalled startup times out and late progress cannot overwrite the error', async () => {
  const ui = elements();
  let progress;
  class Engine {
    static getMissingFeatures() { return []; }
    startGame({ onProgress }) {
      progress = onProgress;
      return new Promise(() => {});
    }
  }
  assert.equal(await bootGame(Engine, {}, ui, { timeoutMs: 5 }), false);
  const failure = ui.status.textContent;
  progress(80, 100);
  assert.equal(ui.status.textContent, failure);
  assert.equal(ui.overlay.hidden, false);
  assert.equal(ui.retry.hidden, false);
});

test('a fresh attempt restores loading controls after a failure', async () => {
  const ui = elements();
  class Failed {
    static getMissingFeatures() { return []; }
    async startGame() { throw new Error('injected failure'); }
  }
  await bootGame(Failed, {}, ui);
  class Recovered {
    static getMissingFeatures() { return []; }
    async startGame({ onProgress }) {
      assert.equal(ui.retry.hidden, true);
      assert.equal(ui.progress.hidden, false);
      onProgress(50, 100);
    }
  }
  assert.equal(await bootGame(Recovered, {}, ui), true);
  assert.equal(ui.overlay.hidden, true);
});

test('engine script download shares the boot deadline and cannot start late', async () => {
  const ui = elements();
  let downloaded;
  let created = 0;
  const script = new Promise((resolve) => { downloaded = resolve; });
  assert.equal(await bootGame(script, {}, ui, { timeoutMs: 5 }), false);
  assert.match(ui.status.textContent, /시간/);
  assert.equal(ui.retry.hidden, false);
  const failure = ui.status.textContent;
  downloaded(class Engine {
    static getMissingFeatures() { return []; }
    constructor() { created++; }
    async startGame() {}
  });
  await Promise.resolve();
  assert.equal(created, 0);
  assert.equal(ui.status.textContent, failure);
});
