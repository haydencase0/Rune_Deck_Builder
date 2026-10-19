class_name MatchTests
extends RefCounted

static func run() -> Dictionary:
	var state := GameState.new(1842)
	state.start_match()
	var passed: bool = state.hands.size() == 2 and state.hands[0].hand_count() == 10 and state.hands[1].hand_count() == 10 and state.resources[0]["mana"] == 0 and state.resources[0]["sanity"] == 50 and RuneDefinitions.catalog().size() == 37
	return {
		"name": "match_setup",
		"passed": passed,
		"details": "seeded match setup with live defaults and 37-rune catalog"
	}
