class_name HandManager
extends RefCounted

const HAND_SIZE := RuneDefinitions.RULES.hand_size

var slots: Array[Dictionary] = []
var reroll_locks: Array[bool] = []
var reroll_selection: Array[int] = []

func start_round(deck: DeckManager, log: EventLog) -> void:
	reroll_locks.clear()
	reroll_selection.clear()
	for _index in range(slots.size()):
		reroll_locks.append(false)
	refill(deck)
	log.record("hand", "Hand prepared with %d runes." % hand_count())

func refill(deck: DeckManager) -> void:
	while hand_count() < HAND_SIZE:
		var rune := deck.draw_one()
		if rune.is_empty():
			break
		var empty_index := _find_empty_slot()
		if empty_index == -1:
			slots.append(rune)
			reroll_locks.append(false)
		else:
			slots[empty_index] = rune
			reroll_locks[empty_index] = false

func select_for_reroll(index: int) -> bool:
	if not _valid_index(index) or reroll_locks[index]:
		return false
	if reroll_selection.has(index):
		reroll_selection.erase(index)
	else:
		reroll_selection.append(index)
	return true

func resolve_reroll(deck: DeckManager, log: EventLog) -> void:
	var selected := reroll_selection.duplicate()
	selected.sort()
	var returned_runes: Array[Dictionary] = []
	for index in selected:
		if not _valid_index(index) or reroll_locks[index]:
			continue
		returned_runes.append(slots[index])
		var replacement := deck.draw_one()
		if replacement.is_empty():
			continue
		slots[index] = replacement
		reroll_locks[index] = true
	for rune in returned_runes:
		deck.return_rerolled(rune)
	log.record("reroll", "Rerolled %d hand slot(s) as one batch." % selected.size(), {"slots": selected})
	reroll_selection.clear()

func take_rune(index: int) -> Dictionary:
	if not _valid_index(index) or slots[index].is_empty():
		return {}
	var rune := slots[index]
	slots[index] = {}
	return rune

func hand_count() -> int:
	var count := 0
	for rune in slots:
		if not rune.is_empty():
			count += 1
	return count

func _valid_index(index: int) -> bool:
	return index >= 0 and index < slots.size()

func _find_empty_slot() -> int:
	for index in range(slots.size()):
		if slots[index].is_empty():
			return index
	return -1
