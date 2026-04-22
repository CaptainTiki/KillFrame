extends CanvasLayer
class_name MissionHud

signal shared_action_requested(action_id: String)
signal placement_requested(structure_id: String)

const ROOT_ACTION_CONTEXT: String = "root"

var _selected_entities: Array[Node3D] = []
var _action_context: String = ROOT_ACTION_CONTEXT
var _action_context_label: String = "Actions"
var _placement_structure_id: String = ""
var _placement_builder: Node3D = null

@onready var _economy: MissionEconomy = $"../MissionEconomy" as MissionEconomy
@onready var _command_panel: PanelContainer = $CommandPanel as PanelContainer
@onready var _resource_panel: MissionHudResourcePanel = $CommandPanel/MarginContainer/HBoxContainer/ResourcePanel as MissionHudResourcePanel
@onready var _selection_panel: MissionHudSelectionPanel = $CommandPanel/MarginContainer/HBoxContainer/SelectionPanel as MissionHudSelectionPanel
@onready var _action_panel: MissionHudActionPanel = $CommandPanel/MarginContainer/HBoxContainer/ActionPanel as MissionHudActionPanel
@onready var _hint_label: Label = $MarginContainer/VBoxContainer/HintLabel as Label
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel as Label


func _ready() -> void:
	MissionHudStyling.apply_panel_style(_command_panel, MissionHudStyling.HUD_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 12)
	_action_panel.action_pressed.connect(_on_action_button_pressed)
	refresh()


func _process(_delta: float) -> void:
	if _prune_selected_entities():
		_reset_action_context()
		refresh()
		return

	_update_selection_details()


func set_selected_entities(entities: Array[Node3D]) -> void:
	_selected_entities.clear()
	for entity: Node3D in entities:
		if entity != null and is_instance_valid(entity):
			_selected_entities.append(entity)

	_reset_action_context()
	refresh()


func set_placement_state(active: bool, structure_id: String, builder: Node3D) -> void:
	_placement_structure_id = structure_id if active else ""
	_placement_builder = builder if active else null
	refresh()


func refresh() -> void:
	_refresh_resource_panel()
	_selection_panel.set_selection_summary(_build_selection_summary())
	_update_selection_details()
	_selection_panel.update_tiles(_build_selection_tile_data())
	_refresh_action_panel()
	_update_hint_label()


func set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _refresh_resource_panel() -> void:
	if _economy == null or _resource_panel == null:
		return

	_resource_panel.update_resources(_economy.crystals, _economy.bits, _economy.get_committed_supply_used(), _economy.supply_cap)


func _refresh_action_panel() -> void:
	var shared_actions: Array[Dictionary] = _get_shared_actions()
	var context_text: String = "Actions"
	if _selected_entities.is_empty():
		context_text = "Select a worker or structure to view actions."
	elif _action_context != ROOT_ACTION_CONTEXT:
		context_text = _action_context_label
	elif shared_actions.is_empty():
		context_text = "No shared actions for this selection."

	_action_panel.set_context_text(context_text)
	_action_panel.update_actions(_build_displayed_actions(shared_actions))


func _build_displayed_actions(shared_actions: Array[Dictionary]) -> Array[Dictionary]:
	var displayed_actions: Array[Dictionary] = []
	if not _selected_entities.is_empty() and _action_context != ROOT_ACTION_CONTEXT:
		displayed_actions.append({
			"id": "__back",
			"label": "Back",
			"kind": "back",
		})

	for action: Dictionary in shared_actions:
		displayed_actions.append(action)

	return displayed_actions


func _build_selection_summary() -> String:
	if _selected_entities.is_empty():
		return "Selection: None"

	var counts: Dictionary = {}
	var order: Array[String] = []
	for entity: Node3D in _selected_entities:
		if entity == null or not is_instance_valid(entity):
			continue
		var label: String = _get_selection_name(entity)
		if not counts.has(label):
			counts[label] = 0
			order.append(label)
		counts[label] = int(counts[label]) + 1

	if order.is_empty():
		return "Selection: None"

	var parts: Array[String] = []
	for label: String in order:
		var count: int = int(counts[label])
		if count > 1:
			parts.append("%s x%d" % [label, count])
		else:
			parts.append(label)

	return "Selection: %s" % ", ".join(parts)


func _update_selection_details() -> void:
	if _selection_panel == null:
		return

	if _selected_entities.is_empty():
		_selection_panel.update_health(0.0, 1.0, 0, "Health: --")
		_selection_panel.set_current_action("Action: None")
		return

	var health_snapshot: Dictionary = _get_selection_health_snapshot()
	_selection_panel.update_health(
		float(health_snapshot.get("current", 0.0)),
		float(health_snapshot.get("max", 0.0)),
		int(health_snapshot.get("count", 0)),
		_build_selection_health_text()
	)
	_selection_panel.set_current_action(_build_selection_action_text())


func _build_selection_health_text() -> String:
	var health_snapshot: Dictionary = _get_selection_health_snapshot()
	var total_current: float = float(health_snapshot.get("current", 0.0))
	var total_max: float = float(health_snapshot.get("max", 0.0))
	var health_count: int = int(health_snapshot.get("count", 0))

	if health_count == 0:
		return "Health: N/A"

	if health_count == 1:
		return "Health: %s / %s" % [_format_health_value(total_current), _format_health_value(total_max)]

	return "Health: %s / %s total" % [_format_health_value(total_current), _format_health_value(total_max)]


func _get_selection_health_snapshot() -> Dictionary:
	var total_current: float = 0.0
	var total_max: float = 0.0
	var health_count: int = 0

	for entity: Node3D in _selected_entities:
		if entity == null or not is_instance_valid(entity):
			continue

		var health: HealthComponent = entity.get_node_or_null("HealthComponent") as HealthComponent
		if health == null:
			continue

		total_current += health.current_health
		total_max += health.max_health
		health_count += 1

	return {
		"current": total_current,
		"max": total_max,
		"count": health_count,
	}


func _build_selection_action_text() -> String:
	var counts: Dictionary = {}
	var order: Array[String] = []
	var valid_count: int = 0

	for entity: Node3D in _selected_entities:
		if entity == null or not is_instance_valid(entity):
			continue
		var action_label: String = _get_entity_action_label(entity)
		if not counts.has(action_label):
			counts[action_label] = 0
			order.append(action_label)
		counts[action_label] = int(counts[action_label]) + 1
		valid_count += 1

	if order.is_empty():
		return "Action: Unknown"

	if order.size() == 1 and valid_count == 1:
		return "Action: %s" % order[0]

	var parts: Array[String] = []
	for action_label: String in order:
		var count: int = int(counts[action_label])
		if count > 1:
			parts.append("%s x%d" % [action_label, count])
		else:
			parts.append(action_label)

	return "Action: %s" % ", ".join(parts)


func _build_selection_tile_data() -> Array[Dictionary]:
	var counts: Dictionary = {}
	var order: Array[String] = []
	var icons: Dictionary = {}

	for entity: Node3D in _selected_entities:
		if entity == null or not is_instance_valid(entity):
			continue

		var label: String = _get_selection_name(entity)
		if not counts.has(label):
			counts[label] = 0
			order.append(label)
			icons[label] = _get_selection_icon_text(entity)
		counts[label] = int(counts[label]) + 1

	var tile_data: Array[Dictionary] = []
	for label: String in order:
		tile_data.append({
			"label": label,
			"icon": str(icons.get(label, _abbreviate_text(label, 3))),
			"count": int(counts[label]),
		})

	return tile_data


func _get_shared_actions() -> Array[Dictionary]:
	var first_entity: Node3D = _get_first_valid_selected_entity()
	if first_entity == null:
		return []

	var first_actions: Array = _get_entity_actions(first_entity, _action_context)
	if first_actions.is_empty():
		return []

	var shared_ids: Dictionary = {}
	for action_variant: Variant in first_actions:
		var action: Dictionary = action_variant as Dictionary
		shared_ids[str(action.get("id", ""))] = true

	for i: int in range(1, _selected_entities.size()):
		var entity: Node3D = _selected_entities[i]
		if entity == null or not is_instance_valid(entity):
			continue
		var entity_actions: Array = _get_entity_actions(entity, _action_context)
		var entity_ids: Dictionary = {}
		for action_variant: Variant in entity_actions:
			var action: Dictionary = action_variant as Dictionary
			entity_ids[str(action.get("id", ""))] = true

		for action_id: Variant in shared_ids.keys():
			if not entity_ids.has(action_id):
				shared_ids.erase(action_id)

	if shared_ids.is_empty():
		return []

	var shared_actions: Array[Dictionary] = []
	for action_variant: Variant in first_actions:
		var action: Dictionary = action_variant as Dictionary
		if shared_ids.has(str(action.get("id", ""))):
			shared_actions.append(action)

	return shared_actions


func _get_entity_actions(entity: Node3D, action_context: String) -> Array:
	if entity == null or not is_instance_valid(entity):
		return []
	if not entity.has_method("get_selection_actions"):
		return []
	if _economy == null:
		return []

	var actions: Variant = entity.call("get_selection_actions", action_context, _economy)
	if actions is Array:
		return actions
	return []


func _get_first_valid_selected_entity() -> Node3D:
	for entity: Node3D in _selected_entities:
		if entity != null and is_instance_valid(entity):
			return entity
	return null


func _get_entity_action_label(entity: Node3D) -> String:
	if entity == null or not is_instance_valid(entity):
		return "Unavailable"

	if entity == _placement_builder and not _placement_structure_id.is_empty():
		return "Placing %s" % _get_structure_label(_placement_structure_id)

	if entity.has_method("get_current_action_label"):
		return str(entity.call("get_current_action_label"))

	if entity.has_method("is_under_construction") and bool(entity.call("is_under_construction")):
		return "Under Construction"

	return "Idle"


func _format_health_value(value: float) -> String:
	var rounded: float = roundf(value)
	if is_equal_approx(value, rounded):
		return str(int(rounded))
	return "%.1f" % value


func _get_selection_name(entity: Node3D) -> String:
	if entity == null:
		return "Unknown"
	for property_info in entity.get_property_list():
		if str(property_info.get("name", "")) == "display_name":
			return str(entity.get("display_name"))
	return entity.name


func _on_action_button_pressed(action_id: String, action_kind: String, next_context: String, next_context_label: String, structure_id: String) -> void:
	match action_kind:
		"submenu":
			_action_context = next_context
			_action_context_label = next_context_label if not next_context_label.is_empty() else "Actions"
			_refresh_action_panel()
			_update_hint_label()
		"placement":
			placement_requested.emit(action_id if structure_id.is_empty() else structure_id)
		"back":
			_reset_action_context()
			_refresh_action_panel()
			_update_hint_label()
		_:
			shared_action_requested.emit(action_id)


func _reset_action_context() -> void:
	_action_context = ROOT_ACTION_CONTEXT
	_action_context_label = "Actions"


func _get_selection_icon_text(entity: Node3D) -> String:
	if entity == null:
		return "SEL"

	if entity.has_method("get_structure_id"):
		match str(entity.call("get_structure_id")):
			"hq":
				return "HQ"
			"barracks":
				return "BAR"
			"vehicle_factory":
				return "FAC"
			"bandwidth_relay":
				return "RLY"

	var label: String = _get_selection_name(entity).to_lower()
	if label.contains("worker"):
		return "WRK"
	if label.contains("rifle"):
		return "RIF"
	if label.contains("scout"):
		return "SCT"
	if label.contains("engineer"):
		return "ENG"

	return _abbreviate_text(_get_selection_name(entity), 3)


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


func _get_structure_label(structure_id: String) -> String:
	match structure_id:
		"barracks":
			return "Barracks"
		"vehicle_factory":
			return "Vehicle Factory"
		"bandwidth_relay":
			return "Bandwidth Relay"
		_:
			return "Structure"


func _update_hint_label() -> void:
	if _hint_label == null:
		return

	if not _placement_structure_id.is_empty():
		_hint_label.text = "Build placement active. Left click to place on the grid, right click to cancel."
		return

	if _selected_entities.is_empty():
		_hint_label.text = "WASD moves camera. Left click units/buildings to select. Right click Bits/Crystals to harvest, enemies to attack, or ground to move. Esc = hub."
		return

	if _action_context != ROOT_ACTION_CONTEXT:
		_hint_label.text = "Selection actions are open. Choose a command from the HUD or press Back."
		return

	_hint_label.text = "Selection drives the HUD. Right click resources to harvest, enemies to attack, or ground to move orderable units."


func _prune_selected_entities() -> bool:
	var changed: bool = false
	var pruned: Array[Node3D] = []
	for entity: Node3D in _selected_entities:
		if is_instance_valid(entity):
			pruned.append(entity)
		else:
			changed = true

	if changed:
		_selected_entities = pruned

	return changed
