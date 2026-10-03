class_name PlacementController
extends RefCounted

const PLAYER_ONE := 0
const PLAYER_TWO := 1

var boards: Array = []
var schedule: Array[Dictionary] = [
	{"player": PLAYER_ONE, "count": 1},
	{"player": PLAYER_TWO, "count": 2},
	{"player": PLAYER_ONE, "count": 2},
	{"player": PLAYER_TWO, "count": 2},
	{"player": PLAYER_ONE, "count": 2},
	{"player": PLAYER_TWO, "count": 2},
	{"player": PLAYER_ONE, "count": 2},
	{"player": PLAYER_TWO, "count": 1}
]
var block_index := 0
var block_remaining := 0
var active_player := -1

func start_round() -> void:
	boards = [_empty_board(), _empty_board()]
	block_index = 0
	_load_block()

func place_rune(player_index: int, hand_index: int, slot_index: int, hands: Array, log: EventLog) -> bool:
	if player_index != active_player or block_remaining <= 0:
		return false
	if slot_index < 0 or slot_index >= 7 or not boards[player_index][slot_index].is_empty():
		return false
	if player_index < 0 or player_index >= hands.size():
		return false
	var rune: Dictionary = hands[player_index].take_rune(hand_index)
	if rune.is_empty():
		return false
	boards[player_index][slot_index] = rune
	block_remaining -= 1
	log.record("placement", "Player %d placed %s in slot %d." % [player_index + 1, RuneDefinitions.display_name(rune), slot_index + 1], {"player": player_index, "slot": slot_index})
	if block_remaining == 0:
		block_index += 1
		_load_block()
	return true

func is_complete() -> bool:
	return block_index >= schedule.size()

func current_player() -> int:
	return active_player

func _load_block() -> void:
	if block_index >= schedule.size():
		active_player = -1
		block_remaining = 0
		return
	active_player = int(schedule[block_index]["player"])
	block_remaining = int(schedule[block_index]["count"])

func _empty_board() -> Array[Dictionary]:
	var board: Array[Dictionary] = []
	for _index in range(7):
		board.append({})
	return board
