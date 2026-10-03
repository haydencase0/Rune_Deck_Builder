class_name MatchTests
extends RefCounted

static func run() -> Dictionary:
	var state := GameState.new(1842)
	state.start_match()
	var passed := state.hands.size() == 2 and state.hands[0].hand_count() == 10 and state.hands[1].hand_count() == 10
	return {
		"name": "match_setup",
		"passed": passed,
		"details": "seeded two-player match setup"
	}
