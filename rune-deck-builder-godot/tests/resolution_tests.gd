class_name ResolutionTests
extends RefCounted

static func run() -> Dictionary:
	var state := _new_state()
	var reference := _new_state()
	var expected_result := reference.resolve_round()
	var before: Array = state.resources.duplicate(true)
	var checks := {}
	checks["begin without applying effects"] = state.begin_resolution() and state.resources == before and state.resolution_index == 0 and state.phase == GameState.Phase.RESOLVE
	checks["cannot finish early"] = state.finish_resolution().get("result") == "invalid" and state.last_result.is_empty()
	checks["cannot restart or advance mid-resolution"] = not state.begin_resolution() and not state.start_next_round() and state.resolve_round().get("result") == "invalid"
	checks["placement blocked"] = not state.place_rune(0, 7, 0) and state.play_computer_turn() == 0
	var activation_counts := {}
	for index in range(28):
		var event := state.resolve_next_activation()
		checks["activation %d" % index] = event.get("event") == index + 1 and state.resolution_index == index + 1 and state.phase == GameState.Phase.RESOLVE
		checks["direction %d" % index] = event.get("direction") == (1 if index < 14 else -1)
		checks["no early discard or refill %d" % index] = state.hands[0].hand_count() == 3 and state.hands[1].hand_count() == 3 and state.decks[0].discard_pile.is_empty() and state.decks[1].discard_pile.is_empty()
		var key := "%d/%d" % [event.get("player", -1), event.get("slot", -1)]
		activation_counts[key] = int(activation_counts.get(key, 0)) + 1
		if index == 0:
			checks["first card applies only its own effect"] = state.resources[0]["health"] == 101 and state.resources[1]["health"] == 99
			checks["only first activation logged"] = state.event_log.messages().has("Activation 1: Player 1, slot 1.") and not state.event_log.messages().has("Activation 2: Player 2, slot 1.")
	for player in range(2):
		for slot in range(1, 8):
			checks["forward and return %d/%d" % [player, slot]] = activation_counts.get("%d/%d" % [player, slot], 0) == 2
	checks["last card waits for finish"] = not state.has_pending_activations() and state.resolve_next_activation().is_empty() and state.phase == GameState.Phase.RESOLVE and state.last_result.is_empty()
	var result := state.finish_resolution()
	checks["same outcome as immediate resolution"] = result == expected_result and state.resources == reference.resources and state.event_log.entries == reference.event_log.entries
	checks["discard and refill after animation"] = state.phase == GameState.Phase.OUTCOME and state.hands[0].hand_count() == 10 and state.hands[1].hand_count() == 10 and state.decks[0].discard_pile.size() == 7 and state.decks[1].discard_pile.size() == 7
	checks["finish cannot repeat"] = state.finish_resolution().get("result") == "invalid" and state.decks[0].discard_pile.size() == 7
	checks["next round clears sequence"] = state.start_next_round() and state.resolution_route.is_empty() and state.resolution_index == 0
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "stepped_resolution",
		"passed": failures.is_empty(),
		"details": "per-card effects/logs, forward/return visits, delayed cleanup, and matching outcomes" if failures.is_empty() else ", ".join(failures)
	}

static func _new_state() -> GameState:
	var deck: Array[Dictionary] = []
	for index in range(20):
		var rune: Dictionary = RuneDefinitions.catalog()["bite"].duplicate(true)
		rune["instance_id"] = "bite_%d" % index
		deck.append(rune)
	var state := GameState.new(7)
	state.decks = [DeckManager.new(7, deck), DeckManager.new(8, deck)]
	state.start_match()
	state.confirm_reroll_phase()
	for index in range(RuneDefinitions.SLOT_COUNT):
		state.place_rune(0, index, index)
		state.play_computer_turn()
	return state
