class_name RuneDefinitions
extends RefCounted

static func placeholder_definitions() -> Array[Dictionary]:
	return [
		{"id": "ember", "name": "Ember", "symbol": "✦", "kind": "damage", "value": 5},
		{"id": "mend", "name": "Mend", "symbol": "⊙", "kind": "heal", "value": 3},
		{"id": "tide", "name": "Tide", "symbol": "⌁", "kind": "mana", "value": 1},
		{"id": "thorn", "name": "Thorn", "symbol": "△", "kind": "damage", "value": 3},
		{"id": "veil", "name": "Veil", "symbol": "◌", "kind": "sanity", "value": 2},
		{"id": "mirror", "name": "Mirror", "symbol": "◈", "kind": "mirror", "value": 1},
		{"id": "null", "name": "Null", "symbol": "╳", "kind": "nothing", "value": 0}
	]

static func build_test_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	for copy_index in range(10):
		for definition in placeholder_definitions():
			var rune := definition.duplicate(true)
			rune["instance_id"] = "%s_%02d" % [str(rune["id"]), copy_index]
			deck.append(rune)
	return deck

static func display_name(rune: Dictionary) -> String:
	return "%s %s" % [str(rune.get("symbol", "?")), str(rune.get("name", "Unknown rune"))]
