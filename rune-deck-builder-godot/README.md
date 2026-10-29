# Rune Roguelike — Godot scaffold

This folder is the first Godot 4 project for the Rune Roguelike battle prototype.

The rules layer now includes the 37-rune catalog and the deterministic core
ported from `../silly-things`: 10-rune draws, the 74-rune test pool, live
health/mana/sanity costs, fizzle checks, mana overflow damage, and the fixed
28-activation forward/return route, with every slot activating on both passes.
Mana-spending runes must leave a positive mana balance or fizzle without paying
any costs; runes without a mana cost can still activate at zero mana.
State-heavy effects such as Copy, Echo,
Lie, defenses, and draft choices remain queued for the next rules pass.

The project is intentionally split into two layers:

- `rules/` contains deterministic match logic and does not depend on UI nodes.
- `ui/` contains the temporary presentation layer that will eventually become the mirror battle screen from `../wireframe.html`.
- `data/` contains placeholder rune definitions for the first simulator pass.
- `tests/` contains smoke tests for deck, sequence, match, computer placement, round transitions, stepped resolution, and animated battle-screen behavior.

Open this folder as a project in Godot 4.7 and run the project. Select up to four redraws,
click **SEAL DRAW**, then click hand runes to place them in your next empty slot.
At the redraw limit, deselect a chosen card to make room for another choice.
`rules/computer_player.gd` chooses the computer's first available rune and empty
slot; `GameState.play_computer_turn()` applies its placement batch through the
same rules as human moves. The computer keeps its starting hand without rerolls.

Both boards, hand counts, turn prompts, and the event log refresh after moves.
Cards in your hand and on both boards display their full effect descriptions
and resource costs without hovering. Family colors, wrapped text, and larger
card faces keep those details readable while preserving click-to-play input.
Once both boards contain seven runes, click **RESOLVE ROUND** to watch each rune
activate with a pulsing gold highlight and a one-second pause before the next
activation. Resource meters and log messages update with each effect, and
controls stay disabled until all 28 activations finish and the outcome appears.
If both players survive, click **NEXT ROUND** to clear
both boards, reset reroll selections and locks, and return to the redraw phase.
Resources, decks, and unplayed runes carry over; hands refill to ten and the
round counter advances. A win or tie ends the match. Strategic computer
decisions and broader roguelike progression remain future work.

The placement schedule is:

```text
Player 1: 1 + 2 + 2 + 2
Player 2: 2 + 2 + 2 + 1
```
