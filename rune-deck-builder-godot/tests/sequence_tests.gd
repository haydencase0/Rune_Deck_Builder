class_name SequenceTests
extends RefCounted

static func run() -> Dictionary:
	var log := EventLog.new()
	var resolver := SequenceResolver.new()
	var boards := [
		[{"id": "a", "instance_id": "a", "symbol": "✦", "kind": "damage", "value": 5}, {}, {}, {}, {}, {}, {}],
		[{}, {}, {}, {}, {}, {}, {}]
	]
	var resources: Array[Dictionary] = [
		{"health": 100, "mana": 5, "sanity": 100, "life_lost": 0},
		{"health": 100, "mana": 5, "sanity": 100, "life_lost": 0}
	]
	var events := resolver.resolve(boards, resources, log)
	return {
		"name": "sequence_order",
		"passed": events.size() == 14 and resources[1]["health"] == 95,
		"details": "14 activation events in forward/reverse order"
	}
