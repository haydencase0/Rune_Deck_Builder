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
	return {
		"name": "deck_and_hand",
		"passed": before == 10 and hand.hand_count() == 10 and deck.cards_remaining() == 64,
		"details": "10-card hand, batch reroll, and catalog deck"
	}
