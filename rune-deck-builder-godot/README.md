# Rune Roguelike — Godot scaffold

This folder is the first Godot 4 project for the Rune Roguelike battle prototype.

The rules layer now includes the 37-rune catalog and the deterministic core
ported from `../silly-things`: 10-rune draws, the 74-rune test pool, live
health/mana/sanity costs, fizzle checks, mana overflow damage, and the fixed
26-activation forward/return route. State-heavy effects such as Copy, Echo,
Lie, defenses, and draft choices remain queued for the next rules pass.

The project is intentionally split into two layers:

- `rules/` contains deterministic match logic and does not depend on UI nodes.
- `ui/` contains the temporary presentation layer that will eventually become the mirror battle screen from `../wireframe.html`.
- `data/` contains placeholder rune definitions for the first simulator pass.
- `tests/` contains small smoke tests for deck, sequence, and match behavior.

Open this folder as a project in Godot 4.x and run the project. The starter scene displays the current rules state and creates a seeded ten-rune hand for each player.

The first implementation decision still to lock is the placement schedule. This scaffold uses the recommended schedule from the development plan:

```text
Player 1: 1 + 2 + 2 + 2
Player 2: 2 + 2 + 2 + 1
```
