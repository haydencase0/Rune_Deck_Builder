# The Mirror Archive

The Mirror Archive is a rune-based roguelike deck-building game in development. The current Godot project, titled **Rune Roguelike**, focuses on a local battle prototype presented as **The Mirror Archive**: two players arrange seven runes each and resolve their effects along a shared forward-and-return activation route.

Current work includes:

* A catalog of 37 runes across body, soul, mind, and generic families, with two copies of each in a 74-rune test deck per player.
* Seeded deck shuffling, ten-rune hands, batch rerolls, discard recycling, and hand refills.
* A deterministic rules layer with health, mana, and sanity costs, failed activations when costs cannot be paid, basic rune effects, mana overflow damage, and defeat resolution.
* Seven-slot boards with alternating placement turns and a fixed 28-activation route: 14 forward activations followed by 14 return activations. Every slot, including slot seven, activates once on each pass.
* A basic computer opponent that keeps its starting hand and automatically places its first available rune in its first empty slot during each turn.
* A mirror-themed Godot interface with resource meters, phase indicators, and an event log, based on the browser [battle wireframe](wireframe.html). Hand and board cards show their names, full effect descriptions, and resource costs directly on their faces, with family colors and wrapped text for readability.
* Animated resolution with a pulsing gold highlight on the active card and a one-second pause between activations. Resources and log messages update as each card activates.
* Smoke tests for deck and hand behavior, activation count and basic damage, seeded match setup, computer placement turns, round transitions, and animated resolution through the interface.

This is an early prototype. You can play successive rounds against the computer through the interface until the match ends. Strategic computer decisions, broader roguelike progression, and several rune effects are still being implemented.

## Instructions for Build and Use

Steps to build and/or run the software:

1. Download or clone this repository and install Godot matching the project's configured version, **4.7**.
2. In Godot's Project Manager, choose **Import** and select `rune-deck-builder-godot/project.godot`.
3. Open the project and press **F5** to run the main battle scene, `ui/battle_screen.tscn`. No separate build step or external packages are required to run it in the editor.

To run the existing smoke tests from the repository root, use the following commands with the Godot executable available as `godot` on your PATH. Substitute your executable's name or path if needed. The first command imports the project and registers its script classes.

```powershell
godot --headless --path rune-deck-builder-godot --editor --import
godot --headless --path rune-deck-builder-godot --script res://tests/test_runner.gd
```

The runner prints individual results and exits with code `0` when all smoke tests pass or `1` when a test fails.

Instructions for using the software:

1. Run the project to start a match with seed `1842`. Each player receives ten runes and starts with 100 health, 0 mana, and 50 sanity.
2. During **REROLL**, select up to four runes in your hand, then click **SEAL DRAW** to replace them and enter placement. **REDRAWS LEFT** shows the remaining choices. At the limit, unselected cards are disabled; click a selected card to deselect it and choose another. You can also keep your entire hand by sealing with no cards selected.
3. During **PLACE**, click a rune in your hand to place it in your next empty slot. The computer automatically takes its turns, following your `1 + 2 + 2 + 2` and its `2 + 2 + 2 + 1` schedule. Both boards show placed runes immediately, and hand counts and turn prompts update after each move.
4. Once both seven-slot boards are full, **RESOLVE ROUND** becomes available. Click it to watch the 28-activation sequence: the active card glows gold, its effect updates the resource meters and event log, and the next card activates after one second. Each slot, including slot seven, activates again on the return pass. Cards with a mana cost must leave mana above zero or they fizzle without paying any costs or applying effects. Cards without a mana cost still work at zero mana. Controls remain disabled until the animation finishes and the outcome appears. Scroll the event log to inspect placements and activations.
5. If both players survive, click **NEXT ROUND** to clear the boards and return to **REROLL**. Resources, decks, and unplayed runes carry over, both hands are refilled to ten, and reroll selections and locks reset. The round counter advances, and the computer takes its placement turns again after you seal the draw. A win or tie ends the match.

To view the original interface design separately, open `wireframe.html` in a web browser.

## Development Environment

To recreate the development environment, you need the following software and/or libraries with the specified versions:

* **Godot Engine 4.7**, as recorded in `project.godot`, with the Compatibility renderer. The game uses GDScript and Godot's built-in UI controls; it does not require the .NET edition or third-party libraries.
* **Godot's built-in script editor**, or a text editor of your choice, for editing GDScript and project files.
* **A web browser** to view the standalone HTML/CSS battle wireframe.

The Godot project is organized into `data/` for rune definitions, `rules/` for deterministic game logic independent of UI nodes, `ui/` for the battle screen, and `tests/` for the smoke-test runner and test cases.

## Useful Websites to Learn More

Useful references for continuing development:

* [Godot Project Manager](https://docs.godotengine.org/en/stable/tutorials/editor/project_manager.html) - importing and opening the project.
* [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) - the language used for game rules and UI scripts.
* [Godot Command Line Tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) - running the project and scripts in headless mode.

## Future Work

The following items I plan to fix, improve, and/or add to this project in the future:

* [x] Add opponent placement automation so a complete round can be played through the interface.
* [x] Refresh board contents, resource meters, hand counts, and turn prompts as the game state changes, and show reroll selections clearly.
* [ ] Improve the computer's rune selection and add reroll decisions.
* [x] Enforce the four-card redraw limit and let players revise their selections before sealing.
* [ ] Finish placement-time rune effects.
* [ ] Implement the remaining state-dependent rune effects, including Copy, Echo, Lie, defenses, and draft choices, and replace simplified effects with their full behavior.
* [x] Add round transitions that reset boards and rerolls while preserving match resources and decks.
* [ ] Add the broader deck-building and roguelike progression loop.
* [ ] Expand tests for placement validation, resource costs, failed activations, mana overflow, and simultaneous defeat.
