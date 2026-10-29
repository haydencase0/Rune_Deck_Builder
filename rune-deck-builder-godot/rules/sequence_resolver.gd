class_name SequenceResolver
extends RefCounted

## Resolves the fixed 14-forward / 14-return route used by Mirror Archive.
## The route is derived from the opening player, so placement and resolution
## remain deterministic for a seeded match.

func resolution_route(first_player: int) -> Array[Dictionary]:
	var counts := [0, 0]
	var forward: Array[Dictionary] = []
	var seat := first_player
	var batch := 1
	while counts[0] < RuneDefinitions.SLOT_COUNT or counts[1] < RuneDefinitions.SLOT_COUNT:
		for _step in range(batch):
			if counts[seat] >= RuneDefinitions.SLOT_COUNT:
				break
			forward.append({"player": seat, "slot": counts[seat], "direction": 1})
			counts[seat] += 1
		seat = 1 - seat
		batch = 2
	var route := forward.duplicate(true)
	for index in range(forward.size() - 1, -1, -1):
		var entry: Dictionary = forward[index].duplicate(true)
		entry["direction"] = -1
		route.append(entry)
	return route

func resolve(boards: Array, resources: Array[Dictionary], log: EventLog, first_player: int = 0) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var route := resolution_route(first_player)
	for event_index in range(route.size()):
		events.append(resolve_step(route[event_index], event_index + 1, boards, resources, log))
	return events

func resolve_step(step: Dictionary, event_number: int, boards: Array, resources: Array[Dictionary], log: EventLog) -> Dictionary:
	var player_index := int(step["player"])
	var slot_index := int(step["slot"])
	var event := {"event": event_number, "player": player_index, "slot": slot_index + 1, "direction": step["direction"], "effects": []}
	log.record("activation", "Activation %d: Player %d, slot %d." % [event_number, player_index + 1, slot_index + 1], event)
	var rune: Dictionary = boards[player_index][slot_index]
	if not rune.is_empty():
		var effect := _apply_rune(rune, player_index, slot_index, boards, resources)
		event["effects"].append(effect)
		log.record("effect", effect["message"], effect)
	return event

func _apply_rune(rune: Dictionary, player_index: int, slot_index: int, boards: Array, resources: Array[Dictionary]) -> Dictionary:
	var key := str(rune.get("key", rune.get("id", "")))
	var cost: Dictionary = rune.get("cost", {})
	var message := "Player %d used %s." % [player_index + 1, RuneDefinitions.display_name(rune)]
	if not RuneDefinitions.can_pay(resources[player_index], rune):
		var reason := "its cost could not be paid."
		var mana_cost := int(cost.get("mana", 0))
		if mana_cost > 0 and int(resources[player_index].get("mana", 0)) <= mana_cost:
			reason = "paying its mana cost would leave mana at zero or below."
		return {"player": player_index, "rune_id": rune.get("instance_id", ""), "fizzled": true, "message": "%s fizzled: %s" % [RuneDefinitions.display_name(rune), reason]}
	_pay(resources[player_index], cost)
	var target := 1 - player_index
	match key:
		"secondstrike": _damage(resources, target, 8 if _adjacent_second_strike(boards[player_index], slot_index) else 2)
		"vitalshot": _damage(resources, target, 12)
		"evenstrike":
			if slot_index % 2 == 1: _damage(resources, target, 2)
		"ultimatum": _damage(resources, target, 10 if _count_key(boards, "ultimatum") == 1 else 2)
		"roar": _change(resources, target, "mana", -5); _change(resources, target, "sanity", -7)
		"poison": _change(resources, target, "mana", -10)
		"blind": _change(resources, target, "sanity", -14)
		"bandage", "mend": _change(resources, player_index, "health", 4)
		"drink": _gain_mana(resources[player_index], 10)
		"anchor": _change(resources, player_index, "sanity", 5)
		"inspiration": _change(resources, player_index, "sanity", 7)
		"boast": _gain_mana(resources[player_index], 10)
		"counsel": _gain_mana(resources[player_index], 5)
		"ponder": _gain_mana(resources[player_index], 3)
		"study": _change(resources, player_index, "sanity", 5)
		"siphon": _damage(resources, target, 4); _change(resources, target, "sanity", -7)
		"outwit": _damage(resources, target, 4); _change(resources, target, "mana", -5)
		"bite": _damage(resources, target, 1); _change(resources, player_index, "health", 1)
		"mirror": _damage(resources, target, 3)
		"dodge", "ward", "cancel", "copy", "swap", "scry", "negate", "echo", "flatter", "traumatize", "lie", "investigate", "dictate", "reiterate", "blindstrike", "bloodlet", "burn":
			pass # State-heavy effects are added in the next rules pass.
	return {"player": player_index, "rune_id": rune.get("instance_id", ""), "fizzled": false, "message": message}

func _pay(resource: Dictionary, cost: Dictionary) -> void:
	resource["health"] = int(resource.get("health", 0)) - int(cost.get("health", 0))
	resource["mana"] = int(resource.get("mana", 0)) - int(cost.get("mana", 0))
	resource["sanity"] = clampi(int(resource.get("sanity", 0)) - int(cost.get("sanity", 0)), 0, RuneDefinitions.RULES.sanity_limit)

func _damage(resources: Array[Dictionary], target: int, amount: int) -> void:
	resources[target]["health"] = int(resources[target].get("health", 0)) - amount
	resources[target]["life_lost"] = int(resources[target].get("life_lost", 0)) + amount

func _change(resources: Array[Dictionary], index: int, field: String, amount: int) -> void:
	resources[index][field] = int(resources[index].get(field, 0)) + amount
	if field == "sanity": resources[index][field] = clampi(int(resources[index][field]), 0, RuneDefinitions.RULES.sanity_limit)

func _gain_mana(resource: Dictionary, amount: int) -> void:
	var before := int(resource.get("mana", 0))
	resource["mana"] = mini(RuneDefinitions.RULES.mana_limit, before + amount)
	resource["health"] = int(resource.get("health", 0)) - maxi(0, before + amount - RuneDefinitions.RULES.mana_limit)

func _count_key(boards: Array, key: String) -> int:
	var count := 0
	for board in boards:
		for rune in board:
			if not rune.is_empty() and str(rune.get("key", rune.get("id", ""))) == key: count += 1
	return count

func _adjacent_second_strike(board: Array, slot: int) -> bool:
	return (slot > 0 and str(board[slot - 1].get("key", "")) == "secondstrike") or (slot < board.size() - 1 and str(board[slot + 1].get("key", "")) == "secondstrike")
