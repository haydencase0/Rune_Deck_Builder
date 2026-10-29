extends Control

const INK := Color("#eee4d1")
const MUTED := Color("#aaa08f")
const DIM := Color("#766f64")
const BRASS := Color("#c2a16d")
const FELT := Color("#171b1c")
const DEEP := Color("#0d1011")
const HEALTH := Color("#bd7169")
const MANA := Color("#749db7")
const SANITY := Color("#a18db8")
const ACTIVATION_PAUSE_SECONDS := 1.0

var game_state: GameState
var status_label: Label
var event_label: Label
var hand_row: HBoxContainer
var battle_row: HBoxContainer
var opponent_hand_label: Label
var opponent_fan: HBoxContainer
var hand_title: Label
var reroll_label: Label
var footer_label: Label
var round_label: Label
var action_button: Button
var phase_labels: Array[Label] = []
var active_activation: Dictionary = {}

func _ready() -> void:
	game_state = GameState.new(1842)
	game_state.start_match()
	_build_ui()
	_refresh_view()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0a0b0d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var desk := PanelContainer.new()
	desk.add_theme_stylebox_override("panel", _box(Color("#171b1c"), Color("#8f7048"), 2, 16))
	margin.add_child(desk)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	desk.add_child(content)
	content.add_child(_top_bar())
	content.add_child(_phase_banner())
	content.add_child(_opponent_hand())
	content.add_child(_battle_area())
	content.add_child(_status_line())
	content.add_child(_player_area())
	content.add_child(_footer())

func _top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 32
	bar.add_theme_constant_override("separation", 18)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(_label("◉  THE MIRROR ARCHIVE", 16, BRASS))
	brand.add_child(_label("LOCAL RULES PROTOTYPE  ·  SEED %d" % game_state.match_seed, 9, DIM))
	bar.add_child(brand)
	round_label = _label("", 10, MUTED)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(round_label)
	var room := _label("LOCAL MATCH  ·  ◌", 9, MUTED)
	room.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(room)
	return bar

func _phase_banner() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#111516"), Color("#3e4140"), 1, 5))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	for phase in ["REROLL", "PLACE", "RESOLVE", "OUTCOME"]:
		var label := _label(phase, 9, DIM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(100, 22)
		row.add_child(label)
		phase_labels.append(label)
	_update_phase_labels()
	return panel

func _opponent_hand() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#101415"), Color("#353a3a"), 1, 5))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	opponent_hand_label = _label("", 9, MUTED)
	opponent_hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(opponent_hand_label)
	opponent_fan = HBoxContainer.new()
	opponent_fan.alignment = BoxContainer.ALIGNMENT_CENTER
	opponent_fan.add_theme_constant_override("separation", -3)
	row.add_child(opponent_fan)
	return panel

func _refresh_opponent_hand() -> void:
	var count := game_state.hands[1].hand_count()
	opponent_hand_label.text = "ENEMY HAND  ·  %d RUNES" % count
	_clear_children(opponent_fan)
	for _index in range(count):
		var card := Label.new()
		card.text = "✦"
		card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.custom_minimum_size = Vector2(26, 22)
		card.add_theme_font_size_override("font_size", 12)
		card.add_theme_color_override("font_color", Color("#9b6b63"))
		card.add_theme_stylebox_override("normal", _box(Color("#542d42"), Color("#8f7048"), 1, 5))
		opponent_fan.add_child(card)

func _battle_area() -> Control:
	battle_row = HBoxContainer.new()
	battle_row.add_theme_constant_override("separation", 13)
	battle_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return battle_row

func _refresh_battle_area() -> void:
	_clear_children(battle_row)
	battle_row.add_child(_player_lane(0, false))
	battle_row.add_child(_mirror_spine())
	battle_row.add_child(_player_lane(1, true))

func _player_lane(player_index: int, opponent: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color("#111617"), Color("#4b5555") if opponent else Color("#536b78"), 1, 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var head := HBoxContainer.new()
	var name := _label("COMPUTER" if opponent else "YOUR KEEPER", 14, INK)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name)
	head.add_child(_label("%d / 7 PLACED" % _placed_count(player_index), 9, DIM))
	column.add_child(head)
	column.add_child(_resources(player_index))
	column.add_child(_board(player_index, opponent))
	return panel

func _resources(player_index: int) -> Control:
	var row := HBoxContainer.new()
	row.name = "PlayerResources" if player_index == 0 else "ComputerResources"
	row.add_theme_constant_override("separation", 10)
	var resource: Dictionary = game_state.resources[player_index]
	row.add_child(_meter("HEALTH", int(resource["health"]), 100, HEALTH))
	row.add_child(_meter("MANA", int(resource["mana"]), 100, MANA))
	row.add_child(_meter("SANITY", int(resource["sanity"]), 100, SANITY))
	return row

func _meter(title: String, value: int, maximum: int, color: Color) -> Control:
	var box := VBoxContainer.new()
	box.name = title
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var caption := _label("%s  %02d" % [title, value], 8, color)
	box.add_child(caption)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maximum
	bar.value = clampi(value, 0, maximum)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	bar.add_theme_stylebox_override("background", _box(Color("#080a0b"), Color("#343a39"), 1, 3))
	bar.add_theme_stylebox_override("fill", _box(color, color, 0, 3))
	box.add_child(bar)
	return box

func _board(player_index: int, opponent: bool) -> Control:
	var row := HBoxContainer.new()
	row.name = "ComputerBoard" if opponent else "PlayerBoard"
	row.add_theme_constant_override("separation", 5)
	if opponent:
		row.alignment = BoxContainer.ALIGNMENT_END
	var board: Array = game_state.placement.boards[player_index] if not game_state.placement.boards.is_empty() else []
	for display_slot in range(RuneDefinitions.SLOT_COUNT):
		var slot_index := RuneDefinitions.SLOT_COUNT - 1 - display_slot if opponent else display_slot
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % slot_index
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(76, 180)
		var filled: bool = not board.is_empty() and not board[slot_index].is_empty()
		var color := Color("#252a2b")
		if filled:
			color = _rune_color(board[slot_index])
		var active: bool = game_state.phase == GameState.Phase.RESOLVE and int(active_activation.get("player", -1)) == player_index and int(active_activation.get("slot", 0)) == slot_index + 1
		var style := _box(color.lightened(0.18) if active else color, BRASS if active else (Color("#91744d") if filled else Color("#424847")), 3 if active else 1, 4)
		style.content_margin_left = 6
		style.content_margin_right = 6
		if active:
			style.shadow_color = Color(BRASS, 0.6)
			style.shadow_size = 8
		slot.add_theme_stylebox_override("panel", style)
		if filled:
			slot.tooltip_text = "%s\n%s" % [board[slot_index].get("name", "Rune"), board[slot_index].get("text", "")]
			slot.add_child(_card_face(board[slot_index], slot_index, true))
		else:
			var label := _label("%02d\n+" % [slot_index + 1], 12, DIM)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(label)
		row.add_child(slot)
	return row

func _mirror_spine() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 58
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	box.add_child(_label("◇", 18, BRASS))
	var glass := ColorRect.new()
	glass.custom_minimum_size = Vector2(3, 145)
	glass.color = Color("#7898a0")
	glass.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(glass)
	var caption := _label("MIRROR", 8, Color("#9fb5ba"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	box.add_child(_label("◇", 18, BRASS))
	return box

func _status_line() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#111415"), Color("#805e40"), 1, 4))
	status_label = _label("THE MIRROR OPENS  ·  DRAW TEN RUNES, THEN SHAPE YOUR HAND", 10, MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size.y = 26
	panel.add_child(status_label)
	return panel

func _player_area() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#121718"), Color("#536b78"), 1, 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var header := HBoxContainer.new()
	hand_title = _label("", 15, INK)
	hand_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hand_title)
	reroll_label = _label("", 9, MUTED)
	header.add_child(reroll_label)
	column.add_child(header)
	hand_row = HBoxContainer.new()
	hand_row.add_theme_constant_override("separation", 6)
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(hand_row)
	var controls := HBoxContainer.new()
	var hint := _label("Click a rune to select it during reroll, or place it into the next keeper slot.", 9, DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(hint)
	action_button = Button.new()
	action_button.text = "SEAL DRAW  ↗"
	action_button.custom_minimum_size = Vector2(145, 30)
	action_button.add_theme_color_override("font_color", Color("#211c15"))
	action_button.add_theme_stylebox_override("normal", _box(BRASS, Color("#d6b87c"), 1, 3))
	action_button.pressed.connect(_on_action_pressed)
	controls.add_child(action_button)
	column.add_child(controls)
	return panel

func _refresh_hand() -> void:
	if not hand_row: return
	_clear_children(hand_row)
	for index in range(game_state.hands[0].slots.size()):
		var rune: Dictionary = game_state.hands[0].slots[index]
		if rune.is_empty(): continue
		var button := Button.new()
		button.tooltip_text = "%s\n%s" % [rune.get("name", "Rune"), rune.get("text", "")]
		button.custom_minimum_size = Vector2(124, 186)
		button.focus_mode = Control.FOCUS_ALL
		var selected := game_state.phase == GameState.Phase.REROLL and game_state.hands[0].reroll_selection.has(index)
		var color := _rune_color(rune)
		button.add_theme_stylebox_override("normal", _box(color.lightened(0.12) if selected else color, BRASS if selected else Color("#806c4d"), 2 if selected else 1, 4))
		button.add_theme_stylebox_override("hover", _box(color.lightened(0.15), BRASS, 2, 4))
		button.add_theme_stylebox_override("disabled", _box(color.darkened(0.12), Color("#55534b"), 1, 4))
		button.disabled = game_state.phase != GameState.Phase.REROLL and not (game_state.phase == GameState.Phase.PLACE and game_state.placement.current_player() == PlacementController.PLAYER_ONE)
		if game_state.phase == GameState.Phase.REROLL:
			button.disabled = not selected and _rerolls_remaining() == 0
		var margin := MarginContainer.new()
		margin.name = "CardMargin"
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 8)
		margin.add_child(_card_face(rune, index, false))
		button.add_child(margin)
		button.pressed.connect(_on_hand_pressed.bind(index))
		hand_row.add_child(button)

func _card_face(rune: Dictionary, index: int, compact: bool) -> VBoxContainer:
	var face := VBoxContainer.new()
	face.name = "CardFace"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_constant_override("separation", 4)
	var heading := HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var number := _label("%02d" % [index + 1], 9, MUTED)
	number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(number)
	heading.add_child(_label(str(rune.get("symbol", "◇")), 16, BRASS))
	face.add_child(heading)
	var title := _label(str(rune.get("name", "Rune")), 12 if compact else 13, INK)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 30
	face.add_child(title)
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(divider)
	var effect := _label(str(rune.get("text", "")), 11 if compact else 12, INK)
	effect.name = "Effect"
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	face.add_child(effect)
	var costs: Array[String] = []
	var cost: Dictionary = rune.get("cost", {})
	for resource in ["health", "mana", "sanity"]:
		var amount := int(cost.get(resource, 0))
		if amount > 0:
			costs.append("%d %s" % [amount, str(resource).capitalize()])
	var cost_label := _label("Free" if costs.is_empty() else ("\n" if compact else " · ").join(costs), 10, BRASS)
	cost_label.name = "Cost"
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	face.add_child(cost_label)
	return face

func _rune_color(rune: Dictionary) -> Color:
	return {"body": Color("#482d31"), "soul": Color("#263b45"), "mind": Color("#3c3047"), "generic": Color("#3d382b")}.get(str(rune.get("family", "generic")), Color("#252a2b"))

func _footer() -> Control:
	var column := VBoxContainer.new()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 32
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	event_label = _label("", 9, MUTED)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(event_label)
	footer_label = _label("", 8, DIM)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer_label)
	return column

func _on_action_pressed() -> void:
	if game_state.phase == GameState.Phase.RESOLVE:
		return
	if game_state.phase == GameState.Phase.REROLL:
		game_state.confirm_reroll_phase()
	elif game_state.phase == GameState.Phase.PLACE and game_state.placement.is_complete():
		await _animate_resolution()
		return
	elif game_state.phase == GameState.Phase.OUTCOME:
		game_state.start_next_round()
	_refresh_view()

func _on_hand_pressed(index: int) -> void:
	if game_state.phase == GameState.Phase.RESOLVE:
		return
	if game_state.phase == GameState.Phase.REROLL:
		game_state.hands[0].select_for_reroll(index)
	elif game_state.phase == GameState.Phase.PLACE:
		var player := game_state.placement.current_player()
		if player == PlacementController.PLAYER_ONE:
			if game_state.place_rune(player, index, _placed_count(player)):
				game_state.play_computer_turn()
	_refresh_view()

func _animate_resolution() -> void:
	if not game_state.begin_resolution():
		return
	while game_state.has_pending_activations():
		active_activation = game_state.resolve_next_activation()
		_refresh_view()
		_pulse_active_card()
		await get_tree().create_timer(ACTIVATION_PAUSE_SECONDS).timeout
		if not is_inside_tree():
			return
	active_activation = {}
	game_state.finish_resolution()
	_refresh_view()

func _pulse_active_card() -> void:
	var board_name := "PlayerBoard" if int(active_activation["player"]) == 0 else "ComputerBoard"
	var board := battle_row.find_child(board_name, true, false)
	var slot: PanelContainer = board.get_node("Slot%d" % (int(active_activation["slot"]) - 1))
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel")
	var pulse := slot.create_tween()
	pulse.tween_property(style, "shadow_size", 18, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(style, "shadow_size", 8, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _refresh_view() -> void:
	_refresh_battle_area()
	_refresh_hand()
	_refresh_opponent_hand()
	round_label.text = "ROUND %02d   —   ◇" % game_state.round_number
	hand_title.text = "YOUR HAND  ·  %d RUNES" % game_state.hands[0].hand_count()
	reroll_label.text = "REDRAWS LEFT  %d" % _rerolls_remaining() if game_state.phase == GameState.Phase.REROLL else ""
	footer_label.text = "DECK %d  ·  DISCARD %d     |     ACTIVATION ORDER  ·  1 2 3 4 5 6 7  ·  RETURN 7 6 5 4 3 2 1" % [game_state.decks[0].cards_remaining(), game_state.decks[0].discard_pile.size()]
	event_label.text = "EVENT LOG\n" + "\n".join(game_state.event_log.messages())
	_update_phase_labels()
	match game_state.phase:
		GameState.Phase.REROLL:
			if _rerolls_remaining() == 0:
				status_label.text = "REDRAW LIMIT REACHED  ·  UNSELECT A CARD TO CHANGE YOUR PICKS, OR SEAL DRAW"
			else:
				status_label.text = "ROUND %02d  ·  SELECT UP TO %d CARDS TO REDRAW, THEN SEAL YOUR DRAW" % [game_state.round_number, HandManager.REROLL_LIMIT]
			action_button.text = "SEAL DRAW  ↗"
			action_button.disabled = false
		GameState.Phase.PLACE:
			var complete := game_state.placement.is_complete()
			if complete:
				status_label.text = "BOARDS COMPLETE  ·  RESOLVE THE ROUND"
			else:
				var turn := "YOUR TURN" if game_state.placement.current_player() == PlacementController.PLAYER_ONE else "COMPUTER TURN"
				status_label.text = "%s  ·  PLACE %d RUNE(S)" % [turn, game_state.placement.block_remaining]
			action_button.text = "RESOLVE ROUND  ↗"
			action_button.disabled = not complete
		GameState.Phase.RESOLVE:
			var player_name := "YOUR KEEPER" if int(active_activation.get("player", 0)) == 0 else "COMPUTER"
			var direction := "FORWARD" if int(active_activation.get("direction", 1)) == 1 else "RETURN"
			var effects: Array = active_activation.get("effects", [])
			var message := str(effects[0]["message"]) if not effects.is_empty() else "Empty slot."
			status_label.text = "%s %02d/%02d  ·  %s SLOT %02d  ·  %s" % [direction, game_state.resolution_index, game_state.resolution_route.size(), player_name, int(active_activation.get("slot", 0)), message]
			action_button.text = "RESOLVING..."
			action_button.disabled = true
		GameState.Phase.OUTCOME:
			status_label.text = "OUTCOME  ·  " + str(game_state.last_result.get("reason", "ROUND COMPLETE"))
			var can_continue: bool = game_state.last_result.get("result", "") == "continue"
			action_button.text = "NEXT ROUND  ↗" if can_continue else "MATCH COMPLETE"
			action_button.disabled = not can_continue

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _update_phase_labels() -> void:
	var current: String = ["REROLL", "PLACE", "RESOLVE", "OUTCOME"][game_state.phase]
	for label in phase_labels:
		label.add_theme_color_override("font_color", BRASS if label.text == current else DIM)

func _placed_count(player_index: int) -> int:
	if game_state.placement.boards.is_empty(): return 0
	var count := 0
	for rune in game_state.placement.boards[player_index]:
		if not rune.is_empty(): count += 1
	return count

func _rerolls_remaining() -> int:
	return game_state.hands[0].rerolls_remaining()

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
