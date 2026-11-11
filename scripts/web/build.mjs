import { copyFile, mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { fingerprintWeb } from './fingerprint.mjs';

const root = fileURLToPath(new URL('../..', import.meta.url));
const output = path.join(root, 'build', 'web');
const godot = process.argv[2] || process.env.GODOT_BIN || 'godot';
await mkdir(path.join(output, 'assets'), { recursive: true });
await writeFile(path.join(root, 'build', '.gdignore'), '');
for (const name of await readdir(output)) {
  if (/^play-[a-f0-9]{16}\.(?:js|wasm|pck|audio(?:\.position)?\.worklet\.js)$/.test(name)) {
    await rm(path.join(output, name));
  }
}
for (const name of [
  'index.js', 'index.wasm', 'index.pck', 'index.png', 'index.icon.png',
  'index.apple-touch-icon.png', 'index.audio.worklet.js', 'index.audio.position.worklet.js',
]) {
  await rm(path.join(output, name), { force: true });
  await rm(path.join(output, `${name}.import`), { force: true });
}

for (const args of [
  ['--headless', '--path', root, '--editor', '--import', '--quit'],
  ['--headless', '--path', root, '--export-release', 'Web', path.join(output, 'play.html')],
  [
    '--headless', '--path', root, '--main-pack', path.join(output, 'play.pck'),
    '--script', path.join(root, 'tests', 'export', 'StartupLayoutCheck.gd'),
  ],
]) {
  const result = spawnSync(godot, args, { stdio: 'inherit' });
  if (result.error) {
    console.error(`Godot를 실행할 수 없습니다: ${result.error.message}\nGODOT_BIN 또는 첫 번째 인자로 Godot 실행 파일을 지정해 주세요.`);
    process.exit(1);
  }
  if (result.status !== 0) process.exit(result.status || 1);
}

const project = await readFile(path.join(root, 'project.godot'), 'utf8');
const version = project.match(/^config\/version="([0-9]+\.[0-9]+\.[0-9]+)"$/m)?.[1];
if (!version) throw new Error('project.godot에 올바른 application/config/version이 필요합니다.');
const playerPath = path.join(output, 'play.html');
await writeFile(playerPath, (await readFile(playerPath, 'utf8')).replaceAll('%GAME_VERSION%', version));
for (const name of ['index.html', 'site.css', 'game-loader.css', 'game-loader.mjs', 'game-viewport.mjs']) {
  await copyFile(path.join(root, 'web', name), path.join(output, name));
}
for (const name of ['Pretendard-Regular.otf', 'Galmuri11-Bold.ttf', 'LICENSE-Galmuri.txt', 'LICENSE-Pretendard.txt']) {
  await copyFile(path.join(root, 'assets', 'fonts', name), path.join(output, 'assets', name));
}
await copyFile(
  path.join(root, 'assets', 'characters', 'warrior', 'warrior_key_art.svg'),
  path.join(output, 'assets', 'warrior_key_art.svg'),
);
await copyFile(
  path.join(root, 'assets', 'characters', 'warrior', 'warrior_idle_walk.png'),
  path.join(output, 'assets', 'warrior_idle_walk.png'),
);
for (const name of [
  'logo_symbol.png', 'logo_wordmark.png', 'favicon_16.png', 'favicon_32.png',
  'favicon_48.png', 'apple_touch_icon.png',
]) {
  await copyFile(path.join(root, 'assets', 'branding', name), path.join(output, 'assets', name));
}
await copyFile(path.join(root, 'assets', 'branding', 'favicon.ico'), path.join(output, 'favicon.ico'));
await writeFile(path.join(output, '.nojekyll'), '');
await fingerprintWeb(output);
console.log(`웹 빌드 완료: ${output}\n로컬 실행: node scripts\\web\\serve.mjs`);
