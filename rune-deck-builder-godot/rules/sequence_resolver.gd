class_name SequenceResolver
extends RefCounted

const ACTIVATION_ORDER: Array[int] = [0, 1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 0]

func resolve(boards: Array, resources: Array[Dictionary], log: EventLog) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for event_index in range(ACTIVATION_ORDER.size()):
		var slot_index: int = ACTIVATION_ORDER[event_index]
		var event := {"event": event_index + 1, "slot": slot_index + 1, "effects": []}
		log.record("activation", "Activation %d: slot %d." % [event_index + 1, slot_index + 1], event)
		for player_index in range(2):
			var rune: Dictionary = boards[player_index][slot_index]
			if rune.is_empty():
				continue
			var effect := _apply_rune(rune, player_index, resources)
			event["effects"].append(effect)
			log.record("effect", effect["message"], effect)
		events.append(event)
	return events

func _apply_rune(rune: Dictionary, player_index: int, resources: Array[Dictionary]) -> Dictionary:
	var kind := str(rune.get("kind", "nothing"))
	var value := int(rune.get("value", 0))
	var target := 1 - player_index
	var message := "%s had no effect." % RuneDefinitions.display_name(rune)
	match kind:
		"damage":
			resources[target]["health"] = int(resources[target]["health"]) - value
			resources[target]["life_lost"] = int(resources[target].get("life_lost", 0)) + value
			message = "Player %d used %s: %d damage to Player %d." % [player_index + 1, RuneDefinitions.display_name(rune), value, target + 1]
		"heal":
			resources[player_index]["health"] = int(resources[player_index]["health"]) + value
			message = "Player %d used %s: %d health restored." % [player_index + 1, RuneDefinitions.display_name(rune), value]
		"mana":
			resources[player_index]["mana"] = int(resources[player_index]["mana"]) + value
			message = "Player %d used %s: +%d mana." % [player_index + 1, RuneDefinitions.display_name(rune), value]
		"sanity":
			resources[player_index]["sanity"] = int(resources[player_index]["sanity"]) + value
			message = "Player %d used %s: +%d sanity." % [player_index + 1, RuneDefinitions.display_name(rune), value]
		"mirror":
			message = "Player %d used %s: mirror placeholder triggered." % [player_index + 1, RuneDefinitions.display_name(rune)]
	return {"player": player_index, "rune_id": rune.get("instance_id", ""), "message": message}
