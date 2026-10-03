extends Control

var game_state: GameState
var status_label: Label
var event_label: Label

func _ready() -> void:
	game_state = GameState.new(1842)
	game_state.start_match()
	_build_placeholder_ui()

func _build_placeholder_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("201526")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var title := _label("RUNE ROGUELIKE", 24, Color("e3b86b"))
	column.add_child(title)
	column.add_child(_label("Rules-layer scaffold · Seed %d · Round %d" % [game_state.match_seed, game_state.round_number], 13, Color("c5b499")))

	status_label = _label("Phase: REROLL · Each player has %d runes" % HandManager.HAND_SIZE, 18, Color("f8ead2"))
	column.add_child(status_label)

	var separator := HSeparator.new()
	column.add_child(separator)

	var opponent_hand := _label("ENEMY HAND\n[ 01 ] [ 02 ] [ 03 ] [ 04 ] [ 05 ] [ 06 ] [ 07 ] [ 08 ] [ 09 ] [ 10 ]", 15, Color("c5b499"))
	opponent_hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(opponent_hand)

	var board_row := HBoxContainer.new()
	board_row.alignment = BoxContainer.ALIGNMENT_CENTER
	board_row.add_theme_constant_override("separation", 22)
	column.add_child(board_row)
	board_row.add_child(_label("YOUR PLAYED RUNES\n[ 1 ][ 2 ][ 3 ][ 4 ][ 5 ][ 6 ][ 7 ]", 16, Color("f8ead2")))
	board_row.add_child(_label("◆\nM I R R O R\n◆", 13, Color("9fb5ba")))
	board_row.add_child(_label("ENEMY PLAYED RUNES\n[ 7 ][ 6 ][ 5 ][ 4 ][ 3 ][ 2 ][ 1 ]", 16, Color("f8ead2")))

	var phase_button := Button.new()
	phase_button.text = "Confirm reroll phase"
	phase_button.pressed.connect(_on_confirm_reroll)
	column.add_child(phase_button)

	var hand_label := _label("YOUR HAND\n" + _hand_text(), 17, Color("f6ead1"))
	column.add_child(hand_label)

	event_label = _label("EVENT LOG\n" + "\n".join(game_state.event_log.messages()), 12, Color("8c7b70"))
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(event_label)

func _on_confirm_reroll() -> void:
	if game_state.phase == GameState.Phase.REROLL:
		game_state.confirm_reroll_phase()
		status_label.text = "Phase: PLACE · Player %d places %d rune(s)" % [game_state.placement.current_player() + 1, game_state.placement.block_remaining]
		event_label.text = "EVENT LOG\n" + "\n".join(game_state.event_log.messages())

func _hand_text() -> String:
	var labels: Array[String] = []
	for index in range(game_state.hands[0].slots.size()):
		var rune: Dictionary = game_state.hands[0].slots[index]
		labels.append("[%02d %s]" % [index + 1, str(rune.get("symbol", "--"))])
	return " ".join(labels)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
