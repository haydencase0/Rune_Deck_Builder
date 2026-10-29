class_name SequenceTests
extends RefCounted

static func run() -> Dictionary:
	var log := EventLog.new()
	var resolver := SequenceResolver.new()
	var boards := [
		[RuneDefinitions.catalog()["secondstrike"], {}, {}, {}, {}, {}, {}],
		[{}, {}, {}, {}, {}, {}, {}]
	]
	var resources: Array[Dictionary] = [
		{"health": 100, "mana": 5, "sanity": 50, "life_lost": 0},
		{"health": 100, "mana": 5, "sanity": 50, "life_lost": 0}
	]
	var events := resolver.resolve(boards, resources, log)
	var checks := {}
	checks["28 activations"] = events.size() == 28
	checks["first slot applies twice"] = resources[1]["health"] == 96
	var expected_forward := [[0, 0], [1, 0], [1, 1], [0, 1], [0, 2], [1, 2], [1, 3], [0, 3], [0, 4], [1, 4], [1, 5], [0, 5], [0, 6], [1, 6]]
	for first_player in range(2):
		var route := resolver.resolution_route(first_player)
		checks["route size for opener %d" % first_player] = route.size() == 28
		for index in range(14):
			checks["forward %d/%d" % [first_player, index]] = route[index] == {"player": int(expected_forward[index][0]) ^ first_player, "slot": expected_forward[index][1], "direction": 1}
			var reverse_index := 27 - index
			checks["return %d/%d" % [first_player, index]] = route[reverse_index] == {"player": route[index]["player"], "slot": route[index]["slot"], "direction": -1}
	# The last slots must apply their effects on both passes, not just appear
	# in the route or receive an animation highlight.
	boards = [[{}, {}, {}, {}, {}, {}, RuneDefinitions.catalog()["secondstrike"]], [{}, {}, {}, {}, {}, {}, {}]]
	resources = [{"health": 100, "mana": 5, "sanity": 50, "life_lost": 0}, {"health": 100, "mana": 5, "sanity": 50, "life_lost": 0}]
	events = resolver.resolve(boards, resources, EventLog.new())
	checks["seventh rune applies twice"] = resources[1]["health"] == 96 and resources[0]["health"] == 96
	checks["seventh rune returns"] = events[15]["player"] == 0 and events[15]["slot"] == 7 and events[15]["direction"] == -1
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "sequence_order",
		"passed": failures.is_empty(),
		"details": "28 activations, exact routes for both openers, and seventh-slot effects twice" if failures.is_empty() else ", ".join(failures)
	}
