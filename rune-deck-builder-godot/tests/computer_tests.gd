class_name ComputerTests
extends RefCounted

static func run() -> Dictionary:
	var state := GameState.new(1842)
	state.start_match()
	var checks := {}
	checks["no moves outside placement"] = state.play_computer_turn() == 0 and not state.place_rune(0, 0, 0)
	state.confirm_reroll_phase()
	checks["waits for human"] = state.play_computer_turn() == 0 and not state.place_rune(1, 0, 0)
	var expected_computer_counts := [2, 2, 4, 4, 6, 6, 7]
	for index in range(RuneDefinitions.SLOT_COUNT):
		var chosen_rune: Dictionary = state.hands[0].slots[index].duplicate(true)
		var placed := state.place_rune(0, index, index)
		checks["human move %d" % index] = placed and state.placement.boards[0][index] == chosen_rune
		state.play_computer_turn()
		var computer_count := 0
		for rune in state.placement.boards[1]:
			if not rune.is_empty():
				computer_count += 1
		checks["computer batch %d" % index] = computer_count == expected_computer_counts[index]
		checks["hand counts %d" % index] = state.hands[0].hand_count() == 9 - index and state.hands[1].hand_count() == 10 - computer_count
		if index == 0:
			var first_rune: Dictionary = state.placement.boards[0][0].duplicate(true)
			checks["occupied slot rejected"] = not state.place_rune(0, 1, 0) and state.placement.boards[0][0] == first_rune
	checks["placement complete"] = state.placement.is_complete() and state.play_computer_turn() == 0
	var final_boards: Array = state.placement.boards.duplicate(true)
	var repeat := GameState.new(1842)
	repeat.start_match()
	repeat.confirm_reroll_phase()
	for index in range(RuneDefinitions.SLOT_COUNT):
		repeat.place_rune(0, index, index)
		repeat.play_computer_turn()
	checks["repeatable decisions"] = repeat.placement.boards == final_boards
	var result := state.resolve_round()
	checks["round resolves"] = state.phase == GameState.Phase.OUTCOME and result.has("winner") and state.hands[0].hand_count() == 10 and state.hands[1].hand_count() == 10
	checks["no moves after outcome"] = state.play_computer_turn() == 0 and not state.place_rune(0, 7, 0)
	var empty_hand := HandManager.new()
	checks["empty hand stops"] = state.computer.choose_placement(empty_hand, [{}, {}]).is_empty()
	checks["full board stops"] = state.computer.choose_placement(state.hands[1], final_boards[1]).is_empty()
	var blocked := GameState.new(7)
	blocked.start_match()
	blocked.confirm_reroll_phase()
	blocked.place_rune(0, 0, 0)
	blocked.hands[1].slots.clear()
	checks["no legal move stops turn"] = blocked.play_computer_turn() == 0
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "computer_placement",
		"passed": failures.is_empty(),
		"details": "legal turns, all placement batches, repeatability, and full round" if failures.is_empty() else ", ".join(failures)
	}
