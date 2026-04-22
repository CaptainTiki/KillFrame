extends PanelContainer
class_name MissionHudActionPanel

signal action_pressed(action_id: String, action_kind: String, next_context: String, next_context_label: String, structure_id: String)

const ACTION_GRID_COLUMNS: int = 4
const ACTION_GRID_SLOT_COUNT: int = 12

@onready var _action_context_label: Label = $MarginContainer/VBoxContainer/ActionContextLabel as Label
@onready var _actions_container: GridContainer = $MarginContainer/VBoxContainer/ActionsContainer as GridContainer


func _ready() -> void:
	MissionHudStyling.apply_panel_style(self, MissionHudStyling.HUD_PANEL_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 10)
	_actions_container.columns = ACTION_GRID_COLUMNS
	_action_context_label.add_theme_color_override("font_color", MissionHudStyling.HUD_ACCENT)


func set_context_text(text: String) -> void:
	_action_context_label.text = text


func update_actions(actions: Array[Dictionary]) -> void:
	_clear_grid_container()

	var slot_count: int = 0
	for action: Dictionary in actions:
		if slot_count >= ACTION_GRID_SLOT_COUNT:
			break
		_add_action_button(action)
		slot_count += 1

	while slot_count < ACTION_GRID_SLOT_COUNT:
		_actions_container.add_child(_create_blank_tile(Vector2(82.0, 82.0)))
		slot_count += 1


func _clear_grid_container() -> void:
	for child: Node in _actions_container.get_children():
		child.queue_free()


func _add_action_button(action: Dictionary) -> void:
	var button: Button = Button.new()
	button.text = ""
	button.disabled = bool(action.get("disabled", false))
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(82.0, 82.0)
	MissionHudStyling.style_action_button(button)
	button.pressed.connect(
		_emit_action_pressed.bind(
			str(action.get("id", "")),
			str(action.get("kind", "command")),
			str(action.get("next_context", "")),
			str(action.get("next_context_label", "")),
			str(action.get("structure_id", "")),
		)
	)

	var content: MarginContainer = MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 6)
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_right", 6)
	content.add_theme_constant_override("margin_bottom", 6)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)

	var split_label: Dictionary = _split_action_label(str(action.get("label", "Action")))
	var icon_label: Label = Label.new()
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_label.text = _get_action_icon_text(action)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 19)
	icon_label.add_theme_color_override("font_color", MissionHudStyling.HUD_ACCENT)

	var title_label: Label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = str(split_label.get("title", "Action"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_PRIMARY)

	var footer_label: Label = Label.new()
	footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_label.text = str(split_label.get("footer", ""))
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 9)
	footer_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_MUTED)

	vbox.add_child(icon_label)
	vbox.add_child(title_label)
	if not footer_label.text.is_empty():
		vbox.add_child(footer_label)

	content.add_child(vbox)
	button.add_child(content)
	_actions_container.add_child(button)


func _emit_action_pressed(action_id: String, action_kind: String, next_context: String, next_context_label: String, structure_id: String) -> void:
	action_pressed.emit(action_id, action_kind, next_context, next_context_label, structure_id)


func _create_blank_tile(size: Vector2) -> PanelContainer:
	var tile: PanelContainer = PanelContainer.new()
	tile.custom_minimum_size = size
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionHudStyling.apply_panel_style(tile, MissionHudStyling.HUD_TILE_DISABLED_BG, MissionHudStyling.HUD_ACCENT_SOFT.darkened(0.45), 1, 8)
	return tile


func _split_action_label(full_label: String) -> Dictionary:
	var title: String = full_label
	var footer: String = ""
	var paren_index: int = full_label.rfind(" (")
	if paren_index != -1 and full_label.ends_with(")"):
		title = full_label.substr(0, paren_index)
		footer = full_label.substr(paren_index + 2, full_label.length() - paren_index - 3)

	title = title.replace("Construct ", "")
	title = title.replace("Deploy ", "")
	title = title.replace("Train ", "")
	title = title.replace("Assemble ", "")
	title = title.strip_edges()

	return {
		"title": title,
		"footer": footer,
	}


func _get_action_icon_text(action: Dictionary) -> String:
	var action_id: String = str(action.get("id", ""))
	match action_id:
		"__back":
			return "BCK"
		"open_worker_build_menu":
			return "BLD"
		"build_barracks":
			return "BAR"
		"build_vehicle_factory":
			return "FAC"
		"build_bandwidth_relay":
			return "RLY"
		"train_worker":
			return "WRK"
		"train_rifle":
			return "RIF"
		"train_scout":
			return "SCT"
		_:
			return _abbreviate_text(str(action.get("label", "ACT")), 3)


func _abbreviate_text(text: String, max_length: int) -> String:
	var cleaned: String = text.replace("_", " ").strip_edges()
	var words: PackedStringArray = cleaned.split(" ", false)
	if words.size() > 1:
		var initialism: String = ""
		for word: String in words:
			if word.is_empty():
				continue
			initialism += word.substr(0, 1).to_upper()
			if initialism.length() >= max_length:
				return initialism.substr(0, max_length)
		if not initialism.is_empty():
			return initialism

	var compact: String = cleaned.replace(" ", "")
	return compact.substr(0, mini(max_length, compact.length())).to_upper()
