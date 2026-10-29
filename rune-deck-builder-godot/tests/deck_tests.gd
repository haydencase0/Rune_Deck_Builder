class_name DeckTests
extends RefCounted

static func run() -> Dictionary:
	var log := EventLog.new()
	var deck := DeckManager.new(7)
	var hand := HandManager.new()
	hand.start_round(deck, log)
	var before := hand.hand_count()
	hand.select_for_reroll(0)
	hand.select_for_reroll(1)
	hand.resolve_reroll(deck, log)
	var checks := {"draw and batch reroll": before == 10 and hand.hand_count() == 10 and deck.cards_remaining() == 64}
	var limited_deck := DeckManager.new(19)
	var limited_hand := HandManager.new()
	limited_hand.start_round(limited_deck, log)
	for index in range(10):
		checks["selection %d" % index] = limited_hand.select_for_reroll(index) == (index < 4)
	checks["four-card cap"] = limited_hand.reroll_selection == [0, 1, 2, 3] and limited_hand.rerolls_remaining() == 0
	checks["deselect at limit"] = limited_hand.select_for_reroll(2) and limited_hand.rerolls_remaining() == 1
	checks["replace selection"] = limited_hand.select_for_reroll(7) and limited_hand.reroll_selection == [0, 1, 3, 7]
	var selected := limited_hand.reroll_selection.duplicate()
	var original_hand: Array = limited_hand.slots.duplicate(true)
	limited_hand.resolve_reroll(limited_deck, log)
	for index in range(10):
		checks["only selected rune replaced %d" % index] = (limited_hand.slots[index] != original_hand[index]) == selected.has(index) and limited_hand.reroll_locks[index] == selected.has(index)
	checks["hand and deck conserved"] = limited_hand.hand_count() == 10 and limited_deck.cards_remaining() == 64 and limited_hand.reroll_selection.is_empty()
	checks["replacement stays locked"] = not limited_hand.select_for_reroll(0)
	limited_hand.start_round(limited_deck, log)
	checks["new round restores allowance"] = limited_hand.rerolls_remaining() == 4 and limited_hand.select_for_reroll(0)
	limited_hand.take_rune(8)
	checks["invalid and empty slots rejected"] = not limited_hand.select_for_reroll(-1) and not limited_hand.select_for_reroll(10) and not limited_hand.select_for_reroll(8)
	# Resolution also enforces the cap if a caller sets the public selection
	# array directly instead of using select_for_reroll().
	var oversized_deck := DeckManager.new(23)
	var oversized_hand := HandManager.new()
	oversized_hand.start_round(oversized_deck, log)
	var oversized_before: Array = oversized_hand.slots.duplicate(true)
	oversized_hand.reroll_selection.assign([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
	checks["remaining count cannot be negative"] = oversized_hand.rerolls_remaining() == 0
	oversized_hand.resolve_reroll(oversized_deck, log)
	var changed := 0
	for index in range(10):
		if oversized_hand.slots[index] != oversized_before[index]:
			changed += 1
	checks["batch cannot exceed four"] = changed == 4 and oversized_hand.hand_count() == 10 and oversized_deck.cards_remaining() == 64
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "deck_and_hand",
		"passed": failures.is_empty(),
		"details": "10-card hand, four-card redraw cap, deselection, batch limits, and round reset" if failures.is_empty() else ", ".join(failures)
	}
