export async function bootGame(Engine, config, ui) {
  try {
    const missing = Engine.getMissingFeatures({ threads: false });
    if (missing.length) {
      throw new Error(`이 브라우저에서 필요한 기능을 사용할 수 없어요: ${missing.join(', ')}. 최신 Chrome 또는 Edge에서 열어 주세요.`);
    }
    const engine = new Engine({ ...config, canvas: ui.canvas });
    await engine.startGame({
      onProgress(current, total) {
        if (Number.isFinite(total) && total > 0 && Number.isFinite(current) && current >= 0) {
          ui.progress.max = total;
          ui.progress.value = Math.min(current, total);
          ui.status.textContent = `모험을 내려받는 중 · ${Math.floor(Math.min(current / total, 1) * 100)}%`;
        } else {
          ui.progress.removeAttribute('value');
          ui.status.textContent = '모험을 준비하고 있어요...';
        }
      },
    });
    ui.overlay.hidden = true;
    return true;
  } catch (error) {
    ui.status.textContent = `게임을 열지 못했어요. ${error instanceof Error ? error.message : String(error)}`;
    ui.progress.hidden = true;
    ui.retry.hidden = false;
    return false;
  }
}
