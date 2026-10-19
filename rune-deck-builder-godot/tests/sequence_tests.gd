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
	return {
		"name": "sequence_order",
		"passed": events.size() == 26 and resources[1]["health"] == 96,
		"details": "26 actor/slot activations in forward/reverse order"
	}
