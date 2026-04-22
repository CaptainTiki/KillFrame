extends PanelContainer
class_name MissionHudSelectionPanel

const SELECTION_GRID_COLUMNS: int = 4
const SELECTION_GRID_SLOT_COUNT: int = 8

@onready var _selection_label: Label = $MarginContainer/VBoxContainer/SelectionLabel as Label
@onready var _current_action_label: Label = $MarginContainer/VBoxContainer/CurrentActionLabel as Label
@onready var _health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar as ProgressBar
@onready var _health_label: Label = $MarginContainer/VBoxContainer/HealthLabel as Label
@onready var _selection_grid: GridContainer = $MarginContainer/VBoxContainer/SelectionGrid as GridContainer


func _ready() -> void:
	MissionHudStyling.apply_panel_style(self, MissionHudStyling.HUD_PANEL_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 10)
	MissionHudStyling.apply_progress_bar_style(_health_bar)
	_selection_grid.columns = SELECTION_GRID_COLUMNS

	_selection_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_PRIMARY)
	_selection_label.add_theme_font_size_override("font_size", 15)
	_current_action_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_MUTED)
	_health_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_MUTED)


func set_selection_summary(text: String) -> void:
	_selection_label.text = text


func set_current_action(text: String) -> void:
	_current_action_label.text = text


func update_health(current: float, max_health: float, count: int, label_text: String) -> void:
	if count > 0:
		_health_bar.max_value = maxf(1.0, max_health)
		_health_bar.value = clampf(current, 0.0, _health_bar.max_value)
	else:
		_health_bar.max_value = 1.0
		_health_bar.value = 0.0

	_health_label.text = label_text


func update_tiles(tile_data: Array[Dictionary]) -> void:
	_clear_grid_container()

	var slot_count: int = 0
	for tile: Dictionary in tile_data:
		if slot_count >= SELECTION_GRID_SLOT_COUNT:
			break
		_selection_grid.add_child(_create_selection_tile(tile))
		slot_count += 1

	while slot_count < SELECTION_GRID_SLOT_COUNT:
		_selection_grid.add_child(_create_blank_tile(Vector2(86.0, 72.0)))
		slot_count += 1


func _clear_grid_container() -> void:
	for child: Node in _selection_grid.get_children():
		child.queue_free()


func _create_blank_tile(size: Vector2) -> PanelContainer:
	var tile: PanelContainer = PanelContainer.new()
	tile.custom_minimum_size = size
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionHudStyling.apply_panel_style(tile, MissionHudStyling.HUD_TILE_DISABLED_BG, MissionHudStyling.HUD_ACCENT_SOFT.darkened(0.45), 1, 8)
	return tile


func _create_selection_tile(tile_data: Dictionary) -> PanelContainer:
	var tile: PanelContainer = PanelContainer.new()
	tile.custom_minimum_size = Vector2(86.0, 72.0)
	MissionHudStyling.apply_panel_style(tile, MissionHudStyling.HUD_TILE_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 8)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)

	var icon_label: Label = Label.new()
	icon_label.text = str(tile_data.get("icon", "SEL"))
	icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.add_theme_color_override("font_color", MissionHudStyling.HUD_ACCENT)

	var count_label: Label = Label.new()
	count_label.text = "x%d" % int(tile_data.get("count", 1))
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_PRIMARY)

	var name_label: Label = Label.new()
	name_label.text = str(tile_data.get("label", "Selection"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", MissionHudStyling.HUD_TEXT_MUTED)

	top_row.add_child(icon_label)
	top_row.add_child(count_label)
	vbox.add_child(top_row)
	vbox.add_child(name_label)
	margin.add_child(vbox)
	tile.add_child(margin)
	return tile
