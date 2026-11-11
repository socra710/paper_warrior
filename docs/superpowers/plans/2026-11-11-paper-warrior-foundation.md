# Paper Warrior Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the supplied design into maintainable Markdown and establish a minimal Godot 4 project whose web build follows Splash → Loading → Title → empty Main Game.

**Architecture:** Keep the four destinations as separate scenes. Use small GDScript files only for timed Splash/Loading transitions and the Title start button; Main Game has no gameplay logic. Use Git-tracked empty content folders, Godot's Web export preset, and Korean project guidance.

**Tech Stack:** Godot 4, GDScript, Markdown, HTML5/WebAssembly export.

---

## Files and responsibilities

- `README.md`: project purpose, prerequisites, run, validation, and export commands.
- `.gitignore`: exclude Godot editor cache and generated web builds.
- `.github/copilot-instructions.md`: repository-specific agent constraints.
- `project.godot`, `export_presets.cfg`: project entry point, rendering defaults, Web preset.
- `scenes/main/splash.tscn`, `loading.tscn`, `title.tscn`, `game.tscn`: four distinct screens.
- `scripts/main/splash.gd`, `loading.gd`, `title.gd`, `game.gd`: flow transition, start input, and empty root scripts.
- `assets/characters/warrior/.gitkeep`, `assets/monsters/.gitkeep`, `assets/equipment/.gitkeep`, `assets/decorations/.gitkeep`, `assets/backgrounds/.gitkeep`, `assets/effects/.gitkeep`, `assets/icons/.gitkeep`, `assets/audio/.gitkeep`: future asset categories.
- `assets/fonts/NotoSansKR.ttf`, `OFL.txt`, `theme_korean.tres`: Korean UI font, its license, and shared theme.
- `data/items/.gitkeep`, `data/monsters/.gitkeep`, `data/stages/.gitkeep`, `data/growth/.gitkeep`: future data categories.
- `docs/GAME_DESIGN.md`: complete source design, with tables represented as Markdown.
- `docs/ART_GUIDE.md`: practical character, animation, asset, and metadata rules.
- `docs/TECHNICAL_DESIGN.md`: initial architecture and web workflow.
- `docs/TASKS.md`: roadmap with the foundation stage marked as the current scope.
- `docs/images/paper-warrior-concept-sheet.png`: image embedded in the supplied Word document.
- `docs/superpowers/specs/2026-11-11-paper-warrior-foundation-design.md`: agreed design rationale and boundaries.

## Task 1: Convert the source document

1. Extract the Word document's tables and prose into `docs/GAME_DESIGN.md`; preserve all 13 sections, numeric alternatives, MVP exclusions, data model fields, agent rules, and unresolved decisions.
2. Move actionable visual rules into `docs/ART_GUIDE.md`, retaining the concept-sheet image and explicitly labeling it as a reference rather than a game-ready sprite sheet.
3. Extract the embedded PNG to `docs/images/paper-warrior-concept-sheet.png`.
4. Review the Markdown for lost rows, malformed tables, and unresolved values incorrectly converted into decisions.

## Task 2: Create project and content layout

1. Add `.gitignore`, `project.godot`, and `export_presets.cfg`; set `scenes/main/splash.tscn` as the entry point, select Godot 4 Compatibility rendering, and define the Web preset output as `build/web/index.html`.
2. Add the eight content asset folders and four data folders with `.gitkeep` files; do not add sample gameplay assets or balance data.
3. Keep the renderer and export settings limited to those needed for a blank web-compatible 2D project.

## Task 3: Implement only the screen-flow skeleton

1. Create a full-rect Splash scene with a minimal title label and Korean theme; attach `scripts/main/splash.gd`. After a short timer, switch to Loading.
2. Create a full-rect Loading scene with a loading label and Korean theme; attach `scripts/main/loading.gd`. After a short timer, switch to Title.
3. Create a Title scene with the game title and one Start button; `scripts/main/title.gd` connects the button and switches to Main Game.
4. Create `scenes/main/game.tscn` as an otherwise empty full-rect Control and attach `scripts/main/game.gd`. Do not add a player, enemy, HUD, input gameplay, or simulated combat.
5. In each scene-switch call, check the returned `Error` and call `push_error` on failure.

## Task 4: Add operating documentation and agent rules

1. Write `README.md` with Godot 4 editor/run, headless validation, and Web export commands.
2. Write `.github/copilot-instructions.md` to require pre-reading, small scoped changes, listing files and validation before edits, separating rules from presentation, and reporting only checks actually run.
3. Write `docs/TECHNICAL_DESIGN.md` with scene paths, flow behavior, folder ownership, rendering choice, export requirements, and validation steps.
4. Write `docs/TASKS.md` with the source roadmap and a clear statement that only foundation setup is in scope.

## Task 5: Validate the project and exported screen flow

1. Run `godot --headless --path . --editor --quit`; expected result is exit code 0 without parse or resource errors.
2. Run `godot --headless --path . --export-release "Web" build/web/index.html`; expected result is an HTML/WebAssembly export at `build/web/index.html`.
3. Serve `build/web` over HTTP and open the exported `index.html` in Chrome or Edge. Confirm Splash advances to Loading and Title, then click Start and confirm Main Game is visually blank.
4. If Godot is missing, install/use a Godot 4 distribution and Web export templates before reporting validation. If templates or browser graphics prevent verification, report that specific blocker rather than claiming success.

## Self-review against the spec

- The scope boundary is repeated in project scenes, documentation, and validation.
- The scene flow has four explicit destinations; only its transitions and title input are implemented.
- Markdown retains all source design areas, while art guidance and the embedded visual reference remain discoverable.
- Web export and local browser verification are included. No unsupported gameplay data or unresolved design decision is invented.
