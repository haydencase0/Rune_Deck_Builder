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

var game_state: GameState
var status_label: Label
var event_label: Label
var hand_row: HBoxContainer
var board_row: HBoxContainer
var action_button: Button
var phase_labels: Array[Label] = []

func _ready() -> void:
	game_state = GameState.new(1842)
	game_state.start_match()
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#0a0b0d")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var desk := PanelContainer.new()
	desk.add_theme_stylebox_override("panel", _box(Color("#171b1c"), Color("#8f7048"), 2, 16))
	margin.add_child(desk)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
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
	bar.custom_minimum_size.y = 48
	bar.add_theme_constant_override("separation", 18)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(_label("◉  THE MIRROR ARCHIVE", 16, BRASS))
	brand.add_child(_label("LOCAL RULES PROTOTYPE  ·  SEED %d" % game_state.match_seed, 9, DIM))
	bar.add_child(brand)
	var round := _label("ROUND %02d   —   ◇" % game_state.round_number, 10, MUTED)
	round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(round)
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
		label.custom_minimum_size = Vector2(100, 28)
		row.add_child(label)
		phase_labels.append(label)
	_update_phase_labels()
	return panel

func _opponent_hand() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#101415"), Color("#353a3a"), 1, 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	var title := _label("ENEMY HAND  ·  %d RUNES" % game_state.hands[1].hand_count(), 9, MUTED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var fan := HBoxContainer.new()
	fan.alignment = BoxContainer.ALIGNMENT_CENTER
	fan.add_theme_constant_override("separation", -3)
	for _index in range(HandManager.HAND_SIZE):
		var card := Label.new()
		card.text = "✦"
		card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card.custom_minimum_size = Vector2(46, 45)
		card.add_theme_font_size_override("font_size", 19)
		card.add_theme_color_override("font_color", Color("#9b6b63"))
		card.add_theme_stylebox_override("normal", _box(Color("#542d42"), Color("#8f7048"), 1, 5))
		fan.add_child(card)
	column.add_child(fan)
	return panel

func _battle_area() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_player_lane(0, false))
	row.add_child(_mirror_spine())
	row.add_child(_player_lane(1, true))
	return row

func _player_lane(player_index: int, opponent: bool) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color("#111617"), Color("#4b5555") if opponent else Color("#536b78"), 1, 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	var head := HBoxContainer.new()
	var name := _label("OPPONENT" if opponent else "YOUR KEEPER", 14, INK)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name)
	head.add_child(_label("%d / 7 PLACED" % _placed_count(player_index), 9, DIM))
	column.add_child(head)
	column.add_child(_resources(player_index))
	column.add_child(_board(player_index, opponent))
	var note := _label("THE OPPOSING REFLECTION" if opponent else "YOUR RUNES · ALIGNED TO THE MIRROR", 8, DIM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)
	return panel

func _resources(player_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var resource: Dictionary = game_state.resources[player_index]
	row.add_child(_meter("HEALTH", int(resource["health"]), 100, HEALTH))
	row.add_child(_meter("MANA", int(resource["mana"]), 100, MANA))
	row.add_child(_meter("SANITY", int(resource["sanity"]), 100, SANITY))
	return row

func _meter(title: String, value: int, maximum: int, color: Color) -> Control:
	var box := VBoxContainer.new()
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
	row.add_theme_constant_override("separation", 5)
	if opponent:
		row.alignment = BoxContainer.ALIGNMENT_END
	var board: Array = game_state.placement.boards[player_index] if not game_state.placement.boards.is_empty() else []
	for display_slot in range(RuneDefinitions.SLOT_COUNT):
		var slot_index := RuneDefinitions.SLOT_COUNT - 1 - display_slot if opponent else display_slot
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(60, 92)
		var filled: bool = not board.is_empty() and not board[slot_index].is_empty()
		var color := Color("#252a2b")
		if filled:
			var family := str(board[slot_index].get("family", "generic"))
			color = {"body": Color("#482d31"), "soul": Color("#263b45"), "mind": Color("#3c3047"), "generic": Color("#3d382b")}.get(family, color)
		slot.add_theme_stylebox_override("panel", _box(color, Color("#91744d") if filled else Color("#424847"), 1, 4))
		var label := _label(str(display_slot + 1).pad_zeros(2), 8, DIM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if filled:
			label.text = "%02d\n%s\n%s" % [slot_index + 1, str(board[slot_index].get("symbol", "◇")), str(board[slot_index].get("name", "Rune"))]
			label.add_theme_font_size_override("font_size", 12)
			slot.add_child(label)
		else:
			label.text = "%02d\n+" % [slot_index + 1]
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
	status_label.custom_minimum_size.y = 30
	panel.add_child(status_label)
	return panel

func _player_area() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("#121718"), Color("#536b78"), 1, 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var header := HBoxContainer.new()
	var title := _label("YOUR HAND  ·  %d RUNES" % game_state.hands[0].hand_count(), 15, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_label("REROLLS  %d" % _rerolls_remaining(), 9, MUTED))
	column.add_child(header)
	hand_row = HBoxContainer.new()
	hand_row.add_theme_constant_override("separation", 6)
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(hand_row)
	_refresh_hand()
	var controls := HBoxContainer.new()
	var hint := _label("Click a rune to select it during reroll, or place it into the next keeper slot.", 9, DIM)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(hint)
	action_button = Button.new()
	action_button.text = "SEAL DRAW  ↗"
	action_button.custom_minimum_size = Vector2(145, 34)
	action_button.add_theme_color_override("font_color", Color("#211c15"))
	action_button.add_theme_stylebox_override("normal", _box(BRASS, Color("#d6b87c"), 1, 3))
	action_button.pressed.connect(_on_action_pressed)
	controls.add_child(action_button)
	column.add_child(controls)
	return panel

func _refresh_hand() -> void:
	if not hand_row: return
	for child in hand_row.get_children(): child.queue_free()
	for index in range(game_state.hands[0].slots.size()):
		var rune: Dictionary = game_state.hands[0].slots[index]
		if rune.is_empty(): continue
		var button := Button.new()
		button.text = "%02d\n%s\n%s" % [index + 1, str(rune.get("symbol", "◇")), str(rune.get("name", "Rune"))]
		button.tooltip_text = "%s\n%s" % [rune.get("name", "Rune"), rune.get("text", "")]
		button.custom_minimum_size = Vector2(85, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", INK)
		button.add_theme_stylebox_override("normal", _box(Color("#252b2b"), Color("#806c4d"), 1, 4))
		button.add_theme_stylebox_override("hover", _box(Color("#39433f"), BRASS, 2, 4))
		button.pressed.connect(_on_hand_pressed.bind(index))
		hand_row.add_child(button)

func _footer() -> Control:
	var column := VBoxContainer.new()
	event_label = _label("EVENT LOG\n" + "\n".join(game_state.event_log.messages()), 9, DIM)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size.y = 42
	column.add_child(event_label)
	var footer := _label("DECK %d  ·  DISCARD %d     |     ACTIVATION ORDER  ·  1 2 3 4 5 6 7  ·  RETURN 6 5 4 3 2 1", 8, DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)
	return column

func _on_action_pressed() -> void:
	if game_state.phase == GameState.Phase.REROLL:
		game_state.confirm_reroll_phase()
		status_label.text = "PLACEMENT PHASE  ·  PLAYER %d PLACES %d RUNE(S)" % [game_state.placement.current_player() + 1, game_state.placement.block_remaining]
		action_button.text = "RESOLVE ROUND  ↗"
	elif game_state.phase == GameState.Phase.PLACE and game_state.placement.is_complete():
		game_state.resolve_round()
		status_label.text = "OUTCOME  ·  " + str(game_state.last_result.get("reason", "ROUND COMPLETE"))
		action_button.text = "ROUND COMPLETE"
	_refresh_hand()
	_update_phase_labels()
	event_label.text = "EVENT LOG\n" + "\n".join(game_state.event_log.messages())

func _on_hand_pressed(index: int) -> void:
	if game_state.phase == GameState.Phase.REROLL:
		game_state.hands[0].select_for_reroll(index)
	elif game_state.phase == GameState.Phase.PLACE:
		var player := game_state.placement.current_player()
		if player == 0:
			game_state.place_rune(0, index, _placed_count(0))
	_refresh_hand()
	_update_phase_labels()

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
	return 4 - game_state.hands[0].reroll_selection.size()

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
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
