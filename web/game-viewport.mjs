export function bindGameViewport(
  canvas,
  media = window.matchMedia('(orientation: landscape) and (max-height: 600px) and (min-width: 640px)'),
  notify = () => window.dispatchEvent(new Event('resize')),
  host = window,
) {
  const update = () => {
    const bounds = canvas.getBoundingClientRect();
    if (bounds.width < 1 || bounds.height < 1) return;
    const ratio = host.devicePixelRatio || 1;
    const width = Math.round(bounds.width * ratio);
    const height = Math.round(bounds.height * ratio);
    if (canvas.width === width && canvas.height === height) return;
    canvas.width = width;
    canvas.height = height;
    notify();
  };
  const observer = new host.ResizeObserver(update);
  observer.observe(canvas);
  host.addEventListener('resize', update);
  media.addEventListener('change', update);
  update();
  return () => {
    observer.disconnect();
    host.removeEventListener('resize', update);
    media.removeEventListener('change', update);
  };
}
