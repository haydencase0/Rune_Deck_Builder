class_name DeckManager
extends RefCounted

var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _init(seed_value: int = 1, starting_deck: Array[Dictionary] = []) -> void:
	rng.seed = seed_value
	if starting_deck.is_empty():
		draw_pile = RuneDefinitions.build_test_deck()
	else:
		for rune in starting_deck:
			draw_pile.append(rune.duplicate(true))
	shuffle_draw_pile()

func draw_one() -> Dictionary:
	if draw_pile.is_empty():
		recycle_discard()
	if draw_pile.is_empty():
		return {}
	return draw_pile.pop_back()

func draw_many(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for _index in range(count):
		var rune := draw_one()
		if rune.is_empty():
			break
		result.append(rune)
	return result

func discard(rune: Dictionary) -> void:
	if not rune.is_empty():
		discard_pile.append(rune)

func return_rerolled(rune: Dictionary) -> void:
	if not rune.is_empty():
		draw_pile.append(rune)
	shuffle_draw_pile()

func shuffle_draw_pile() -> void:
	for index in range(draw_pile.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := draw_pile[index]
		draw_pile[index] = draw_pile[swap_index]
		draw_pile[swap_index] = temporary

func recycle_discard() -> void:
	if discard_pile.is_empty():
		return
	for rune in discard_pile:
		draw_pile.append(rune)
	discard_pile.clear()
	shuffle_draw_pile()

func cards_remaining() -> int:
	return draw_pile.size()
