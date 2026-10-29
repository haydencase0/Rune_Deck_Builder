class_name BattleScreenTests
extends RefCounted

static func run(tree: SceneTree) -> Dictionary:
	var scene: PackedScene = load("res://ui/battle_screen.tscn")
	var screen = scene.instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	var checks := {}
	checks["initial boards"] = _boards_match(screen)
	checks["readable hand effects"] = _hand_cards_match(screen)
	# Clicking the effect text must still activate the card beneath it.
	var effect: Label = screen.hand_row.get_child(0).get_node("CardMargin/CardFace/Effect")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = effect.get_global_rect().get_center()
	click.global_position = click.position
	click.pressed = true
	tree.root.push_input(click, true)
	var release: InputEventMouseButton = click.duplicate()
	release.pressed = false
	tree.root.push_input(release, true)
	await tree.process_frame
	checks["click through effect text"] = screen.game_state.hands[0].reroll_selection.has(0)
	if screen.game_state.hands[0].reroll_selection.has(0):
		screen.hand_row.get_child(0).pressed.emit()
	for index in range(4):
		screen.hand_row.get_child(index).pressed.emit()
	checks["four redraws selected"] = screen.game_state.hands[0].reroll_selection.size() == 4 and screen.reroll_label.text.ends_with("0") and screen.status_label.text.begins_with("REDRAW LIMIT REACHED")
	for index in range(10):
		checks["redraw button limit %d" % index] = screen.hand_row.get_child(index).disabled == (index >= 4)
	# A programmatic press of a disabled fifth card must also be rejected.
	screen.hand_row.get_child(4).pressed.emit()
	checks["fifth redraw rejected"] = screen.game_state.hands[0].reroll_selection.size() == 4 and not screen.game_state.hands[0].reroll_selection.has(4)
	screen.hand_row.get_child(1).pressed.emit()
	checks["deselect reopens redraw"] = screen.game_state.hands[0].reroll_selection.size() == 3 and not screen.hand_row.get_child(4).disabled and screen.reroll_label.text.ends_with("1")
	screen.hand_row.get_child(8).pressed.emit()
	checks["can swap redraw choice"] = screen.game_state.hands[0].reroll_selection.has(8) and screen.game_state.hands[0].reroll_selection.size() == 4
	var redraw_selection: Array = screen.game_state.hands[0].reroll_selection.duplicate()
	for index in redraw_selection:
		screen.hand_row.get_child(index).pressed.emit()
	checks["zero redraws allowed"] = screen.game_state.hands[0].reroll_selection.is_empty() and not screen.action_button.disabled
	screen.action_button.pressed.emit()
	checks["resolve waits for boards"] = screen.action_button.disabled
	for index in range(RuneDefinitions.SLOT_COUNT):
		var button: Button = screen.hand_row.get_child(0)
		button.pressed.emit()
		await tree.process_frame
		checks["visible placements %d" % index] = _boards_match(screen)
		checks["readable hand %d" % index] = _hand_cards_match(screen)
		checks["opponent hand %d" % index] = screen.opponent_fan.get_child_count() == screen.game_state.hands[1].hand_count()
		checks["human hand %d" % index] = screen.hand_row.get_child_count() == screen.game_state.hands[0].hand_count()
		checks["resolve availability %d" % index] = screen.action_button.disabled == (index < RuneDefinitions.SLOT_COUNT - 1)
		checks["placement log %d" % index] = screen.event_label.text.contains("placed")
	checks["opponent mirrored"] = screen.find_child("ComputerBoard", true, false).get_child(0).name == "Slot6"
	screen.action_button.pressed.emit()
	await _wait_for_resolution(screen, tree, checks, "first round", true)
	checks["visible boards after resolution"] = _boards_match(screen)
	checks["outcome"] = screen.game_state.phase == GameState.Phase.OUTCOME and not screen.action_button.disabled and screen.action_button.text.begins_with("NEXT ROUND") and screen.status_label.text.begins_with("OUTCOME")
	checks["refilled hands"] = screen.hand_row.get_child_count() == 10 and screen.opponent_fan.get_child_count() == 10
	checks["resolution log"] = screen.event_label.text.contains("Activation 28")
	checks["outcome input disabled"] = screen.hand_row.get_child(0).disabled
	for player in range(2):
		var resources := screen.find_child("PlayerResources" if player == 0 else "ComputerResources", true, false)
		for resource in ["health", "mana", "sanity"]:
			var meter := resources.get_node(str(resource).to_upper())
			var caption: Label = meter.get_child(0)
			checks["resource %d %s" % [player, resource]] = caption.text == "%s  %02d" % [str(resource).to_upper(), screen.game_state.resources[player][resource]]
	var resources_after_round: Array = screen.game_state.resources.duplicate(true)
	screen.action_button.pressed.emit()
	await tree.process_frame
	checks["second round reroll"] = screen.game_state.round_number == 2 and screen.game_state.phase == GameState.Phase.REROLL and screen.action_button.text.begins_with("SEAL DRAW") and not screen.action_button.disabled
	checks["round label updated"] = screen.round_label.text.begins_with("ROUND 02")
	checks["cleared boards visible"] = _boards_match(screen) and screen.game_state.placement.boards[0][0].is_empty() and screen.game_state.placement.boards[1][0].is_empty()
	checks["resources carried over"] = screen.game_state.resources == resources_after_round
	checks["hand enabled for redraw"] = not screen.hand_row.get_child(0).disabled
	checks["new round redraw counter"] = screen.reroll_label.text.ends_with("4")
	var redraw_button: Button = screen.hand_row.get_child(9)
	redraw_button.pressed.emit()
	checks["redraw selection"] = screen.game_state.hands[0].reroll_selection.has(9)
	screen.action_button.pressed.emit()
	checks["second round redraw resolved"] = screen.game_state.hands[0].reroll_locks[9] and screen.game_state.phase == GameState.Phase.PLACE
	for index in range(RuneDefinitions.SLOT_COUNT):
		var button: Button = screen.hand_row.get_child(0)
		button.pressed.emit()
		await tree.process_frame
		checks["second round visible placements %d" % index] = _boards_match(screen)
	checks["second round ready to resolve"] = screen.game_state.placement.is_complete() and not screen.action_button.disabled
	# Exercise the match-ending branch as well as the surviving first round.
	screen.game_state.resources[1]["health"] = -1000
	screen.action_button.pressed.emit()
	await _wait_for_resolution(screen, tree, checks, "second round")
	checks["second round resolves"] = screen.game_state.phase == GameState.Phase.OUTCOME and _boards_match(screen)
	checks["match complete"] = screen.action_button.disabled and screen.action_button.text == "MATCH COMPLETE"
	screen.action_button.pressed.emit()
	checks["finished match cannot advance"] = screen.game_state.phase == GameState.Phase.OUTCOME and screen.game_state.round_number == 2
	# Check every catalog description in a full hand and on full boards,
	# including the longest effects and the three-resource Mirror cost.
	var catalog: Array = RuneDefinitions.catalog().values()
	for batch in range(4):
		for index in range(10):
			screen.game_state.hands[0].slots[index] = catalog[(batch * 10 + index) % catalog.size()].duplicate(true)
		for player in range(2):
			for slot in range(RuneDefinitions.SLOT_COUNT):
				screen.game_state.placement.boards[player][slot] = catalog[(batch * 10 + player * 7 + slot) % catalog.size()].duplicate(true)
		screen.call("_refresh_view")
		await tree.process_frame
		await tree.process_frame
		checks["catalog hand layout %d" % batch] = _hand_cards_match(screen)
		checks["catalog board layout %d" % batch] = _boards_match(screen)
	var failures: Array[String] = []
	for check in checks:
		if not checks[check]:
			failures.append(check)
	screen.queue_free()
	await tree.process_frame
	return {
		"name": "battle_screen",
		"passed": failures.is_empty(),
		"details": "readable catalog cards, text clicks, two animated rounds, redraw, and match completion" if failures.is_empty() else ", ".join(failures)
	}

static func _wait_for_resolution(screen: Control, tree: SceneTree, checks: Dictionary, prefix: String, verify_timing: bool = false) -> void:
	var state: GameState = screen.get("game_state")
	var started_at := Time.get_ticks_msec()
	var original_time_scale := Engine.time_scale
	var observed := 0
	var previous_resources: Array = state.resources.duplicate(true)
	checks[prefix + " starts resolving"] = state.phase == GameState.Phase.RESOLVE and state.resolution_index == 1 and state.last_result.is_empty()
	checks[prefix + " cards remain in play"] = state.hands[0].hand_count() == 3 and state.hands[1].hand_count() == 3
	# Even programmatic presses cannot restart resolution or play another rune.
	screen.get("action_button").pressed.emit()
	screen.call("_on_hand_pressed", 7)
	checks[prefix + " duplicate input ignored"] = state.resolution_index == 1 and state.phase == GameState.Phase.RESOLVE
	if not verify_timing:
		Engine.time_scale = 40.0
	while state.phase == GameState.Phase.RESOLVE:
		await tree.process_frame
		if state.phase != GameState.Phase.RESOLVE:
			break
		if state.resolution_index != observed:
			checks[prefix + " sequential activation %d" % state.resolution_index] = state.resolution_index == observed + 1
			observed = state.resolution_index
			checks[prefix + " active highlight %d" % observed] = _highlight_matches(screen, state.resolution_route[observed - 1]) and _boards_match(screen)
			checks[prefix + " locked controls %d" % observed] = screen.get("action_button").disabled and screen.get("hand_row").get_child(0).disabled
			checks[prefix + " live log %d" % observed] = screen.get("event_label").text.contains("Activation %d:" % observed)
			var effects: Array = screen.get("active_activation").get("effects", [])
			if observed > 1 and not effects.is_empty() and effects[0].get("fizzled", false):
				checks[prefix + " fizzle leaves resources unchanged %d" % observed] = state.resources == previous_resources
			for player in range(2):
				var resources := screen.find_child("PlayerResources" if player == 0 else "ComputerResources", true, false)
				var mana_meter := resources.get_node("MANA")
				checks[prefix + " mana meter %d/%d" % [observed, player]] = mana_meter.get_child(0).text == "MANA  %02d" % state.resources[player]["mana"] and mana_meter.get_child(1).value == clampi(int(state.resources[player]["mana"]), 0, 100)
			previous_resources = state.resources.duplicate(true)
			if verify_timing and observed == 2:
				checks["one-second activation interval"] = Time.get_ticks_msec() - started_at >= 950
				# Check the real default delay once, then accelerate the remaining
				# animation so the smoke suite does not wait for two full rounds.
				Engine.time_scale = 40.0
		if Time.get_ticks_msec() - started_at > 10000:
			checks[prefix + " animation timeout"] = false
			break
	Engine.time_scale = original_time_scale
	checks[prefix + " all activations shown"] = observed == 28
	checks[prefix + " highlight cleared"] = screen.get("active_activation").is_empty()
	await tree.process_frame

static func _highlight_matches(screen: Control, step: Dictionary) -> bool:
	var highlighted := 0
	for player in range(2):
		var row := screen.find_child("PlayerBoard" if player == 0 else "ComputerBoard", true, false)
		for slot in row.get_children():
			var style: StyleBoxFlat = slot.get_theme_stylebox("panel")
			if style.border_width_left == 3:
				highlighted += 1
				if player != int(step["player"]) or slot.name != "Slot%d" % int(step["slot"]):
					return false
	return highlighted == 1

static func _boards_match(screen: Control) -> bool:
	var state: GameState = screen.get("game_state")
	for player in range(2):
		var row := screen.find_child("PlayerBoard" if player == 0 else "ComputerBoard", true, false)
		if row == null or row.get_child_count() != RuneDefinitions.SLOT_COUNT:
			return false
		for slot_index in range(RuneDefinitions.SLOT_COUNT):
			var slot := row.get_node("Slot%d" % slot_index)
			if not slot.is_visible_in_tree() or not screen.get_global_rect().encloses(slot.get_global_rect()):
				return false
			var rune: Dictionary = state.placement.boards[player][slot_index] if not state.placement.boards.is_empty() else {}
			if rune.is_empty():
				var label: Label = slot.get_child(0)
				if not label.text.contains("+"):
					return false
			else:
				var face: VBoxContainer = slot.get_node("CardFace")
				if not _face_matches(face, rune, slot.get_global_rect()):
					return false
	return true

static func _hand_cards_match(screen: Control) -> bool:
	var state: GameState = screen.get("game_state")
	var hand: HBoxContainer = screen.get("hand_row")
	var card_index := 0
	for rune in state.hands[0].slots:
		if rune.is_empty():
			continue
		var button: Button = hand.get_child(card_index)
		var face: VBoxContainer = button.get_node("CardMargin/CardFace")
		if not screen.get_global_rect().encloses(button.get_global_rect()) or not _face_matches(face, rune, button.get_global_rect()):
			return false
		card_index += 1
	return card_index == hand.get_child_count()

static func _face_matches(face: VBoxContainer, rune: Dictionary, card_rect: Rect2) -> bool:
	var title: Label = face.get_node("Title")
	var effect: Label = face.get_node("Effect")
	var cost: Label = face.get_node("Cost")
	return title.text == str(rune["name"]) and effect.text == str(rune["text"]) and effect.is_visible_in_tree() and not cost.text.is_empty() and card_rect.encloses(face.get_global_rect()) and card_rect.encloses(effect.get_global_rect()) and card_rect.encloses(cost.get_global_rect()) and effect.size.y >= effect.get_minimum_size().y
