class_name RoundTests
extends RefCounted

static func run() -> Dictionary:
	var state := _new_state()
	var checks := {}
	checks["cannot skip initial reroll"] = not state.start_next_round() and state.round_number == 1
	for round_number in range(1, 4):
		checks["round number %d" % round_number] = state.round_number == round_number
		checks["reroll available %d" % round_number] = state.hands[0].select_for_reroll(9)
		state.confirm_reroll_phase()
		checks["reroll locks selected slot %d" % round_number] = state.hands[0].reroll_locks[9]
		var retained_runes: Array = state.hands[0].slots.slice(7, 10).duplicate(true)
		checks["cannot skip placement %d" % round_number] = not state.start_next_round()
		checks["complete placements %d" % round_number] = _fill_boards(state)
		# A repeated phase confirmation must not erase the completed boards.
		state.confirm_reroll_phase()
		checks["placement retained %d" % round_number] = state.placement.is_complete()
		var result := state.resolve_round()
		checks["surviving outcome %d" % round_number] = result.get("result") == "continue"
		var resources: Array = state.resources.duplicate(true)
		var deck_counts: Array[int] = []
		for player in range(2):
			deck_counts.append(state.decks[player].cards_remaining())
			deck_counts.append(state.decks[player].discard_pile.size())
			checks["cards conserved %d/%d" % [round_number, player]] = state.hands[player].hand_count() + state.decks[player].cards_remaining() + state.decks[player].discard_pile.size() == 16
		checks["cannot resolve twice %d" % round_number] = state.resolve_round().get("result") == "invalid" and state.resources == resources
		checks["next round starts %d" % round_number] = state.start_next_round() and state.phase == GameState.Phase.REROLL and state.last_result.is_empty()
		checks["resources persist %d" % round_number] = state.resources == resources
		checks["unplayed runes persist %d" % round_number] = state.hands[0].slots.slice(7, 10) == retained_runes
		checks["placement reset %d" % round_number] = not state.placement.is_complete() and state.placement.current_player() == -1 and state.placement.block_remaining == 0
		for player in range(2):
			var empty_board := true
			for rune in state.placement.boards[player]:
				empty_board = empty_board and rune.is_empty()
			checks["empty board %d/%d" % [round_number, player]] = empty_board
			checks["rerolls reset %d/%d" % [round_number, player]] = not state.hands[player].reroll_locks.has(true) and state.hands[player].reroll_selection.is_empty()
			checks["no extra draws or discards %d/%d" % [round_number, player]] = state.hands[player].hand_count() == 10 and state.decks[player].cards_remaining() == deck_counts[player * 2] and state.decks[player].discard_pile.size() == deck_counts[player * 2 + 1]
		checks["cannot advance twice %d" % round_number] = not state.start_next_round() and state.round_number == round_number + 1
	for terminal_result in ["win", "tie"]:
		var finished := _new_state()
		finished.confirm_reroll_phase()
		_fill_boards(finished)
		finished.resources[1]["health"] = -1000
		if terminal_result == "tie":
			finished.resources[0]["health"] = -1000
			finished.resources[1]["life_lost"] = finished.resources[0]["life_lost"]
		var result := finished.resolve_round()
		checks["match ends on %s" % terminal_result] = result.get("result") == terminal_result and not finished.start_next_round() and finished.phase == GameState.Phase.OUTCOME and finished.round_number == 1
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "round_transitions",
		"passed": failures.is_empty(),
		"details": "three rounds, board/reroll resets, persistent resources/cards, and terminal outcomes" if failures.is_empty() else ", ".join(failures)
	}

static func _new_state() -> GameState:
	# Free healing runes let this fixture exercise multiple surviving rounds and
	# discard recycling without depending on the balance of the full catalog.
	var deck: Array[Dictionary] = []
	for index in range(16):
		var rune: Dictionary = RuneDefinitions.catalog()["bandage"].duplicate(true)
		rune["instance_id"] = "bandage_%d" % index
		deck.append(rune)
	var state := GameState.new(7)
	state.decks = [DeckManager.new(7, deck), DeckManager.new(8, deck)]
	state.resources[0] = {"health": 71, "mana": 17, "sanity": 39, "life_lost": 4}
	state.start_match()
	return state

static func _fill_boards(state: GameState) -> bool:
	for index in range(RuneDefinitions.SLOT_COUNT):
		if not state.place_rune(0, index, index):
			return false
		state.play_computer_turn()
	return state.placement.is_complete()
