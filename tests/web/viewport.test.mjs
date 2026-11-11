import assert from 'node:assert/strict';
import test from 'node:test';
import { bindGameViewport } from '../../web/game-viewport.mjs';

test('orientation changes resize the same canvas without losing running state', () => {
  const state = { scene: 'game', menu: 'equipment' };
  const canvas = { width: 480, height: 640, state };
  let listener;
  let notifications = 0;
  const media = {
    matches: false,
    addEventListener(_type, callback) { listener = callback; },
    removeEventListener(_type, callback) { assert.equal(callback, listener); listener = null; },
  };
  const dispose = bindGameViewport(canvas, media, () => { notifications++; });
  assert.equal(notifications, 0);
  media.matches = true;
  listener();
  assert.deepEqual([canvas.width, canvas.height], [960, 540]);
  assert.equal(canvas.state, state);
  assert.equal(canvas.state.menu, 'equipment');
  listener();
  assert.equal(notifications, 1);
  media.matches = false;
  listener();
  assert.deepEqual([canvas.width, canvas.height], [480, 640]);
  assert.equal(notifications, 2);
  dispose();
  assert.equal(listener, null);
});
