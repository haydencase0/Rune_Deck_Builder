# The Mirror Archive

The Mirror Archive is a rune-based roguelike deck-building game in development. The current Godot project, titled **Rune Roguelike**, focuses on a local battle prototype presented as **The Mirror Archive**: two players arrange seven runes each and resolve their effects along a shared forward-and-return activation route.

Current work includes:

* A catalog of 37 runes across body, soul, mind, and generic families, with two copies of each in a 74-rune test deck per player.
* Seeded deck shuffling, ten-rune hands, batch rerolls, discard recycling, and hand refills.
* A deterministic rules layer with health, mana, and sanity costs, failed activations when costs cannot be paid, basic rune effects, mana overflow damage, and defeat resolution.
* Seven-slot boards with alternating placement turns and a fixed 26-activation route: 14 forward activations followed by 12 return activations.
* A mirror-themed Godot interface with resource meters, rune tooltips, phase indicators, and an event log, based on the browser [battle wireframe](wireframe.html).
* Smoke tests for deck and hand behavior, activation count and basic damage, and seeded match setup.

This is an early prototype. Opponent placement controls, a complete round-to-round flow, and several rune effects are still being implemented. The rules layer supports both players, but the current interface only accepts hand input for Player 1, so a full battle cannot yet be completed through the UI.

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
2. During **REROLL**, click runes in your hand to toggle their selection, then click **SEAL DRAW** to replace the selected runes and enter placement. The UI displays a four-reroll allowance, but the selection limit is not yet enforced.
3. During **PLACE**, click a rune in your hand to place it in your next empty slot when it is Player 1's turn. Placement follows Player 1's `1 + 2 + 2 + 2` and Player 2's `2 + 2 + 2 + 1` schedule. The UI currently stops accepting placements when Player 2's first turn begins because opponent input is unfinished.
4. Once both boards are populated through the rules layer, the **RESOLVE ROUND** action can resolve the sequence and display the outcome and event log. Continuing into another round is still future work.

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

* [ ] Add opponent placement input or automation so a complete battle can be played through the interface.
* [ ] Refresh board contents, resource meters, hand counts, and turn prompts as the game state changes, and show reroll selections clearly.
* [ ] Enforce reroll allowances and finish placement-time rune effects.
* [ ] Implement the remaining state-dependent rune effects, including Copy, Echo, Lie, defenses, and draft choices, and replace simplified effects with their full behavior.
* [ ] Add round transitions and the broader deck-building and roguelike progression loop.
* [ ] Expand tests for placement validation, resource costs, failed activations, mana overflow, and simultaneous defeat.
