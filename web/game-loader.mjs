const startups = new WeakMap();

export function bootGame(Engine, config, ui, { timeoutMs = 90000 } = {}) {
  const existing = startups.get(ui.canvas);
  if (existing) return existing;
  const startup = startGame(Engine, config, ui, timeoutMs);
  startups.set(ui.canvas, startup);
  startup.then((started) => {
    if (!started && startups.get(ui.canvas) === startup) startups.delete(ui.canvas);
  });
  return startup;
}

async function startGame(Engine, config, ui, timeoutMs) {
  let active = true;
  let timer;
  try {
    ui.overlay.hidden = false;
    ui.progress.hidden = false;
    ui.progress.removeAttribute('value');
    ui.retry.hidden = true;
    ui.status.textContent = '종이 숲으로 가는 길을 열어요...';
    const deadline = new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error('게임 준비 응답 시간이 초과됐어요. 네트워크를 확인하고 다시 시도해 주세요.')), timeoutMs);
    });
    if (typeof Engine?.then === 'function') Engine = await Promise.race([Engine, deadline]);
    if (typeof Engine?.getMissingFeatures !== 'function') {
      throw new Error('게임 엔진 파일을 받지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.');
    }
    const missing = Engine.getMissingFeatures({ threads: false });
    if (missing.length) {
      throw new Error(`이 브라우저에서 필요한 기능을 사용할 수 없어요: ${missing.join(', ')}. 최신 Chrome 또는 Edge에서 열어 주세요.`);
    }
    const engine = new Engine({ ...config, canvas: ui.canvas });
    const started = engine.startGame({
      onProgress(current, total) {
        if (!active) return;
        if (Number.isFinite(total) && total > 0 && Number.isFinite(current) && current >= 0) {
          if (current < total) {
            ui.progress.max = total;
            ui.progress.value = current;
            ui.status.textContent = `모험을 담고 있어요 · ${Math.floor(current / total * 100)}%`;
          } else {
            ui.progress.removeAttribute('value');
            ui.status.textContent = '첫 장을 펼치고 있어요...';
          }
        } else {
          ui.progress.removeAttribute('value');
          ui.status.textContent = '종이 숲으로 가는 길을 열어요...';
        }
      },
    });
    await Promise.race([started, deadline]);
    active = false;
    ui.overlay.hidden = true;
    return true;
  } catch (error) {
    active = false;
    ui.overlay.hidden = false;
    ui.status.textContent = `첫 장을 펼치지 못했어요. ${error instanceof Error ? error.message : String(error)}`;
    ui.progress.hidden = true;
    ui.retry.hidden = false;
    return false;
  } finally {
    clearTimeout(timer);
  }
}
