class_name ManaTests
extends RefCounted

static func run() -> Dictionary:
	var resolver := SequenceResolver.new()
	var catalog := RuneDefinitions.catalog()
	var checks := {}
	# Mirror spends all three resources, so a failed mana check must prevent
	# every cost as well as the effect. Cover zero, insufficient, and exact mana.
	for mana in [-1, 0, 4, 5]:
		var boards := [[catalog["mirror"], {}, {}, {}, {}, {}, {}], [{}, {}, {}, {}, {}, {}, {}]]
		var resources := _resources(mana)
		var before: Array = resources.duplicate(true)
		var log := EventLog.new()
		var event := resolver.resolve_step({"player": 0, "slot": 0, "direction": 1}, 1, boards, resources, log)
		checks["fizzles at mana %d" % mana] = event["effects"][0]["fizzled"] and not RuneDefinitions.can_pay(before[0], catalog["mirror"])
		checks["no costs or effects at mana %d" % mana] = resources == before
		checks["fizzle logged at mana %d" % mana] = log.messages()[1].contains("fizzled")
	var boards := [[catalog["mirror"], {}, {}, {}, {}, {}, {}], [{}, {}, {}, {}, {}, {}, {}]]
	var resources := _resources(6)
	var event := resolver.resolve_step({"player": 0, "slot": 0, "direction": 1}, 1, boards, resources, EventLog.new())
	checks["one mana left succeeds"] = not event["effects"][0]["fizzled"] and resources[0]["mana"] == 1 and resources[0]["health"] == 96 and resources[0]["sanity"] == 47 and resources[1]["health"] == 97
	var after_success: Array = resources.duplicate(true)
	event = resolver.resolve_step({"player": 0, "slot": 0, "direction": -1}, 2, boards, resources, EventLog.new())
	checks["cost rechecked on return"] = event["effects"][0]["fizzled"] and resources == after_success
	for key in ["anchor", "siphon"]:
		var cost := int(catalog[key]["cost"]["mana"])
		checks["exact cost rejected for %s" % key] = not RuneDefinitions.can_pay(_resources(cost)[0], catalog[key])
		checks["above cost allowed for %s" % key] = RuneDefinitions.can_pay(_resources(cost + 1)[0], catalog[key])
	for key in ["ponder", "drink", "boast", "counsel", "vitalshot", "outwit"]:
		boards = [[catalog[key], {}, {}, {}, {}, {}, {}], [{}, {}, {}, {}, {}, {}, {}]]
		resources = _resources(0)
		event = resolver.resolve_step({"player": 0, "slot": 0, "direction": 1}, 1, boards, resources, EventLog.new())
		checks["free rune works at zero mana: %s" % key] = not event["effects"][0]["fizzled"]
		if key == "ponder":
			checks["generate starting mana"] = resources[0]["mana"] == 3
		elif key == "vitalshot":
			checks["health cost works without mana"] = resources[0]["health"] == 94 and resources[1]["health"] == 88
		elif key == "outwit":
			checks["sanity cost works without mana"] = resources[0]["sanity"] == 43 and resources[1]["health"] == 96
	# A seventh-slot rune succeeds forward, then fizzles on the return when
	# paying again would use its last mana. The successful cost is paid once.
	boards = [[{}, {}, {}, {}, {}, {}, catalog["mirror"]], [{}, {}, {}, {}, {}, {}, {}]]
	resources = _resources(10)
	var events := resolver.resolve(boards, resources, EventLog.new())
	checks["seventh-slot exact-cost return fizzles"] = not events[12]["effects"][0]["fizzled"] and events[15]["effects"][0]["fizzled"] and resources[0]["mana"] == 5 and resources[0]["health"] == 96 and resources[0]["sanity"] == 47 and resources[1]["health"] == 97
	resources = _resources(11)
	events = resolver.resolve(boards, resources, EventLog.new())
	checks["seventh-slot funded return succeeds"] = not events[12]["effects"][0]["fizzled"] and not events[15]["effects"][0]["fizzled"] and resources[0]["mana"] == 1 and resources[1]["health"] == 94
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	return {
		"name": "mana_fizzle",
		"passed": failures.is_empty(),
		"details": "zero/exact/insufficient mana, unchanged fizzled costs, free runes, and return payments" if failures.is_empty() else ", ".join(failures)
	}

static func _resources(mana: int) -> Array[Dictionary]:
	return [
		{"health": 100, "mana": mana, "sanity": 50, "life_lost": 0},
		{"health": 100, "mana": 0, "sanity": 50, "life_lost": 0}
	]
