export function bindGameViewport(
  canvas,
  media = window.matchMedia('(orientation: landscape) and (max-height: 600px) and (min-width: 640px)'),
  notify = () => window.dispatchEvent(new Event('resize')),
) {
  const update = () => {
    const [width, height] = media.matches ? [960, 540] : [480, 640];
    if (canvas.width === width && canvas.height === height) return;
    canvas.width = width;
    canvas.height = height;
    notify();
  };
  media.addEventListener('change', update);
  update();
  return () => media.removeEventListener('change', update);
}
