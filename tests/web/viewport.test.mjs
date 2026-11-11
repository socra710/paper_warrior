import assert from 'node:assert/strict';
import test from 'node:test';
import { bindGameViewport } from '../../web/game-viewport.mjs';

test('orientation changes resize the same canvas without losing running state', () => {
  const state = { scene: 'game', menu: 'equipment' };
  const canvas = { width: 480, height: 640, state };
  let bounds = { width: 480, height: 640 };
  canvas.getBoundingClientRect = () => bounds;
  const host = {
    devicePixelRatio: 1,
    addEventListener() {},
    removeEventListener() {},
    ResizeObserver: class { observe() {} disconnect() {} },
  };
  let listener;
  let notifications = 0;
  const media = {
    matches: false,
    addEventListener(_type, callback) { listener = callback; },
    removeEventListener(_type, callback) { assert.equal(callback, listener); listener = null; },
  };
  const dispose = bindGameViewport(canvas, media, () => { notifications++; }, host);
  assert.equal(notifications, 0);
  media.matches = true;
  bounds = { width: 960, height: 540 };
  listener();
  assert.deepEqual([canvas.width, canvas.height], [960, 540]);
  assert.equal(canvas.state, state);
  assert.equal(canvas.state.menu, 'equipment');
  listener();
  assert.equal(notifications, 1);
  media.matches = false;
  bounds = { width: 480, height: 640 };
  listener();
  assert.deepEqual([canvas.width, canvas.height], [480, 640]);
  assert.equal(notifications, 2);
  dispose();
  assert.equal(listener, null);
});

test('compact high-DPI canvas follows displayed pixels without replacing game state', () => {
  const state = { scene: 'game', menu: 'equipment' };
  const canvas = { width: 480, height: 640, state };
  let bounds = { width: 356, height: 474.65625 };
  canvas.getBoundingClientRect = () => bounds;
  const listeners = new Map();
  let resize;
  let disconnected = false;
  const host = {
    devicePixelRatio: 2,
    addEventListener(type, callback) { listeners.set(type, callback); },
    removeEventListener(type) { listeners.delete(type); },
    ResizeObserver: class {
      constructor(callback) { resize = callback; }
      observe(element) { assert.equal(element, canvas); }
      disconnect() { disconnected = true; }
    },
  };
  const media = { addEventListener() {}, removeEventListener() {} };
  let notifications = 0;
  const dispose = bindGameViewport(canvas, media, () => { notifications++; }, host);
  assert.deepEqual([canvas.width, canvas.height], [712, 949]);
  resize();
  assert.equal(notifications, 1);
  bounds = { width: 520.5, height: 292.78125 };
  resize();
  assert.deepEqual([canvas.width, canvas.height], [1041, 586]);
  host.devicePixelRatio = 1;
  listeners.get('resize')();
  assert.deepEqual([canvas.width, canvas.height], [521, 293]);
  assert.equal(canvas.state, state);
  assert.equal(canvas.state.menu, 'equipment');
  dispose();
  assert.equal(disconnected, true);
  assert.equal(listeners.size, 0);
});
