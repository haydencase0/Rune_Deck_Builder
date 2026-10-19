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
var event_log := EventLog.new()
var last_result: Dictionary = {}

func _init(seed_value: int = 1842) -> void:
	match_seed = seed_value
	decks = [DeckManager.new(match_seed), DeckManager.new(match_seed + 1)]
	hands = [HandManager.new(), HandManager.new()]
	resources = [_new_resources(), _new_resources()]

func start_match() -> void:
	round_number = 1
	event_log.clear()
	for player_index in range(2):
		hands[player_index].start_round(decks[player_index], event_log)
	phase = Phase.REROLL
	event_log.record("match", "Match started with seed %d." % match_seed)

func confirm_reroll_phase() -> void:
	for player_index in range(2):
		hands[player_index].resolve_reroll(decks[player_index], event_log)
	placement.start_round()
	phase = Phase.PLACE
	event_log.record("phase", "Placement phase started.")

func place_rune(player_index: int, hand_index: int, slot_index: int) -> bool:
	return placement.place_rune(player_index, hand_index, slot_index, hands, event_log)

func resolve_round() -> Dictionary:
	if not placement.is_complete():
		return {"result": "invalid", "reason": "Placement is not complete."}
	phase = Phase.RESOLVE
	var resolver := SequenceResolver.new()
	resolver.resolve(placement.boards, resources, event_log, placement.first_player)
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
