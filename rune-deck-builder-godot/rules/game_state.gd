class_name GameState
extends RefCounted

enum Phase { REROLL, PLACE, RESOLVE, OUTCOME }

var match_seed := 1842
var round_number := 0
var phase: int = Phase.REROLL
var decks: Array[DeckManager] = []
var hands: Array[HandManager] = []
var resources: Array[Dictionary] = []
var placement := PlacementController.new()
var computer := ComputerPlayer.new()
var event_log := EventLog.new()
var last_result: Dictionary = {}
var resolution_route: Array[Dictionary] = []
var resolution_index := 0
var sequence_resolver := SequenceResolver.new()

func _init(seed_value: int = 1842) -> void:
	match_seed = seed_value
	decks = [DeckManager.new(match_seed), DeckManager.new(match_seed + 1)]
	hands = [HandManager.new(), HandManager.new()]
	resources = [_new_resources(), _new_resources()]

func start_match() -> void:
	round_number = 1
	event_log.clear()
	_prepare_round()
	event_log.record("match", "Match started with seed %d." % match_seed)

func start_next_round() -> bool:
	if phase != Phase.OUTCOME or last_result.get("result", "") != "continue":
		return false
	round_number += 1
	_prepare_round()
	return true

func _prepare_round() -> void:
	placement.reset()
	last_result = {}
	resolution_route.clear()
	resolution_index = 0
	for player_index in range(2):
		hands[player_index].start_round(decks[player_index], event_log)
	phase = Phase.REROLL
	event_log.record("round", "Round %d started. Select runes to reroll." % round_number)

func confirm_reroll_phase() -> void:
	if phase != Phase.REROLL:
		return
	for player_index in range(2):
		hands[player_index].resolve_reroll(decks[player_index], event_log)
	placement.start_round()
	phase = Phase.PLACE
	event_log.record("phase", "Placement phase started.")

func place_rune(player_index: int, hand_index: int, slot_index: int) -> bool:
	if phase != Phase.PLACE:
		return false
	return placement.place_rune(player_index, hand_index, slot_index, hands, event_log)

func play_computer_turn() -> int:
	if phase != Phase.PLACE:
		return 0
	var player := PlacementController.PLAYER_TWO
	var placed := 0
	for _move in range(RuneDefinitions.SLOT_COUNT):
		if placement.is_complete() or placement.current_player() != player:
			break
		var move := computer.choose_placement(hands[player], placement.boards[player])
		if move.is_empty():
			break
		if not place_rune(player, int(move["hand_index"]), int(move["slot_index"])):
			break
		placed += 1
	return placed

func resolve_round() -> Dictionary:
	if not begin_resolution():
		return {"result": "invalid", "reason": "Round is not ready to resolve."}
	while has_pending_activations():
		resolve_next_activation()
	return finish_resolution()

func begin_resolution() -> bool:
	if phase != Phase.PLACE or not placement.is_complete():
		return false
	resolution_route = sequence_resolver.resolution_route(placement.first_player)
	resolution_index = 0
	phase = Phase.RESOLVE
	return true

func has_pending_activations() -> bool:
	return phase == Phase.RESOLVE and resolution_index < resolution_route.size()

func resolve_next_activation() -> Dictionary:
	if not has_pending_activations():
		return {}
	var event := sequence_resolver.resolve_step(resolution_route[resolution_index], resolution_index + 1, placement.boards, resources, event_log)
	resolution_index += 1
	return event

func finish_resolution() -> Dictionary:
	if phase != Phase.RESOLVE or has_pending_activations():
		return {"result": "invalid", "reason": "Activations are not complete."}
	last_result = DefeatResolver.determine_result(resources)
	event_log.record("outcome", str(last_result.get("reason", "Round complete.")), last_result)
	_discard_played_runes()
	for player_index in range(2):
		hands[player_index].refill(decks[player_index])
	phase = Phase.OUTCOME
	return last_result

func _discard_played_runes() -> void:
	for player_index in range(2):
		for rune in placement.boards[player_index]:
			decks[player_index].discard(rune)

func _new_resources() -> Dictionary:
	return {"health": RuneDefinitions.RULES.starting_health, "mana": RuneDefinitions.RULES.starting_mana, "sanity": RuneDefinitions.RULES.starting_sanity, "life_lost": 0}
