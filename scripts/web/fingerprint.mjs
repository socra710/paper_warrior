import { createHash } from 'node:crypto';
import { readFile, readdir, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';

export async function fingerprintWeb(output) {
  const runtimeNames = (await readdir(output))
    .filter((name) => /^play\.(?:js|wasm|pck|audio(?:\.position)?\.worklet\.js)$/.test(name))
    .sort();
  const hash = createHash('sha256');
  for (const name of runtimeNames) hash.update(name).update(await readFile(path.join(output, name)));
  const executable = `play-${hash.digest('hex').slice(0, 16)}`;
  let html = await readFile(path.join(output, 'play.html'), 'utf8');
  html = html.replaceAll('"executable":"play"', `"executable":"${executable}"`);
  for (const name of runtimeNames) {
    const renamed = executable + name.slice(4);
    html = html.replaceAll(`"${name}"`, `"${renamed}"`).replaceAll(`'${name}'`, `'${renamed}'`);
    await rename(path.join(output, name), path.join(output, renamed));
  }
  for (const name of ['site.css', 'game-loader.css', 'game-loader.mjs', 'game-viewport.mjs']) {
    const id = createHash('sha256').update(await readFile(path.join(output, name))).digest('hex').slice(0, 16);
    html = html.replaceAll(`"${name}"`, `"${name}?v=${id}"`)
      .replaceAll(`'./${name}'`, `'./${name}?v=${id}'`);
  }
  await writeFile(path.join(output, 'play.html'), html);
}
