extends Node3D

@onready var _economy: MissionEconomy = $MissionEconomy as MissionEconomy
@onready var _selection_controller: MissionSelectionController = $SelectionController as MissionSelectionController
@onready var _order_controller: MissionOrderController = $OrderController as MissionOrderController
@onready var _placement_controller: MissionPlacementController = $PlacementController as MissionPlacementController
@onready var _hud: MissionHud = $HUD as MissionHud


func _ready() -> void:
	var engineer: Node3D = $PlayerStart/Engineer
	var mission_controller: Node = $MissionController

	engineer.deployed.connect(mission_controller.register_player_hq)
	engineer.deployed.connect(_economy.register_player_hq)

	_economy.state_changed.connect(_hud.refresh)
	_selection_controller.selection_changed.connect(_on_selection_changed)
	_order_controller.status_message_requested.connect(_hud.set_status_text)
	_placement_controller.status_message_requested.connect(_hud.set_status_text)
	_placement_controller.placement_state_changed.connect(_on_placement_state_changed)
	_hud.shared_action_requested.connect(_on_shared_action_requested)
	_hud.placement_requested.connect(_on_placement_requested)

	_hud.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _placement_controller.handle_input(event):
		return

	if _selection_controller.handle_input(event):
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_order_controller.issue_group_order()
			return

	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://ui/menusystem/menus/hub/hub.tscn")


func _on_selection_changed(selected_entities: Array) -> void:
	var typed_selection: Array[Node3D] = []
	for entity: Variant in selected_entities:
		if entity is Node3D:
			typed_selection.append(entity as Node3D)

	if _placement_controller.is_active() and not _placement_controller.is_builder_selected(typed_selection):
		_placement_controller.cancel_structure_placement(false)

	_hud.set_selected_entities(typed_selection)


func _on_placement_requested(structure_id: String) -> void:
	_placement_controller.begin_structure_placement(structure_id, _selection_controller.get_selected_builder())


func _on_placement_state_changed(active: bool, structure_id: String, builder: Node3D) -> void:
	_hud.set_placement_state(active, structure_id, builder)


func _on_shared_action_requested(action_id: String) -> void:
	var result: Dictionary = _perform_shared_action(action_id)
	_hud.refresh()
	if result.has("message"):
		_hud.set_status_text(str(result["message"]))


func _perform_shared_action(action_id: String) -> Dictionary:
	for entity: Node3D in _selection_controller.get_selected_entities():
		if entity == null or not is_instance_valid(entity):
			continue
		if not entity.has_method("perform_selection_action"):
			continue

		var result: Variant = entity.call("perform_selection_action", action_id, _economy)
		if result is Dictionary:
			return result

	return {"success": false, "message": "Action unavailable for the current selection."}
