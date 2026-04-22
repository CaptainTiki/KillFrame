extends Node
class_name MissionPlacementController

signal status_message_requested(text: String)
signal placement_state_changed(active: bool, structure_id: String, builder: Node3D)

const BUILD_GRID_SIZE: float = 2.0
const HUD_ACCENT: Color = Color(0.18, 0.87, 1.0, 1.0)
const HUD_INVALID: Color = Color(1.0, 0.3, 0.32, 1.0)

var _placement_structure_id: String = ""
var _placement_preview: Node3D = null
var _placement_builder: Node3D = null
var _placement_preview_is_valid: bool = true

@onready var _economy: MissionEconomy = $"../MissionEconomy" as MissionEconomy
@onready var _camera_rig: MissionCameraRig = $"../CameraRig" as MissionCameraRig


func _process(_delta: float) -> void:
	if _placement_builder != null and not is_instance_valid(_placement_builder):
		cancel_structure_placement(false)
		return

	_update_placement_preview()


func handle_input(event: InputEvent) -> bool:
	if not is_active():
		return false
	if event is not InputEventMouseButton:
		return false

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_confirm_structure_placement()
		return true
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		cancel_structure_placement()
		return true

	return false


func is_active() -> bool:
	return not _placement_structure_id.is_empty()


func is_builder_selected(selected_entities: Array[Node3D]) -> bool:
	if _placement_builder == null or not is_instance_valid(_placement_builder):
		return false

	for entity: Node3D in selected_entities:
		if entity == _placement_builder:
			return true

	return false


func begin_structure_placement(structure_id: String, builder: Node3D) -> void:
	if builder == null or not is_instance_valid(builder):
		status_message_requested.emit("Select a worker before placing a structure.")
		return
	if _economy == null:
		status_message_requested.emit("Economy system unavailable.")
		return

	var validation: Dictionary = _economy.can_start_structure_placement(structure_id)
	if not validation.get("success", false):
		status_message_requested.emit(str(validation.get("message", "Unable to start placement.")))
		return

	cancel_structure_placement(false)

	_placement_structure_id = structure_id
	_placement_builder = builder
	_placement_preview = _economy.instantiate_structure_preview(structure_id)
	if _placement_preview == null:
		_placement_structure_id = ""
		_placement_builder = null
		status_message_requested.emit("Failed to create build preview.")
		_emit_placement_state_changed()
		return

	get_parent().add_child(_placement_preview)
	_economy.configure_structure_preview(_placement_preview)
	_placement_preview_is_valid = true
	_set_placement_preview_validity(true)
	_update_placement_preview()
	status_message_requested.emit("Placing %s. Left click to place, right click to cancel." % _get_structure_label(structure_id))
	_emit_placement_state_changed()


func cancel_structure_placement(show_message: bool = true) -> void:
	if _placement_preview != null and is_instance_valid(_placement_preview):
		_placement_preview.queue_free()

	_placement_preview = null
	_placement_structure_id = ""
	_placement_builder = null
	_placement_preview_is_valid = true

	_emit_placement_state_changed()

	if show_message:
		status_message_requested.emit("Structure placement cancelled.")


func get_structure_id() -> String:
	return _placement_structure_id


func get_builder() -> Node3D:
	return _placement_builder


func _confirm_structure_placement() -> void:
	if _placement_preview == null or not is_instance_valid(_placement_preview):
		cancel_structure_placement(false)
		return

	if _placement_builder == null or not is_instance_valid(_placement_builder):
		cancel_structure_placement(false)
		status_message_requested.emit("The selected worker is no longer available.")
		return

	var result: Dictionary = _economy.place_structure(_placement_structure_id, _placement_preview.global_position)
	if not result.get("success", false):
		status_message_requested.emit(str(result.get("message", "Unable to place structure.")))
		return

	var placed_structure: Node3D = result.get("structure", null) as Node3D
	if placed_structure != null and _placement_builder.has_method("set_construction_target"):
		_placement_builder.call("set_construction_target", placed_structure)

	status_message_requested.emit(str(result.get("message", "Structure placed.")))
	cancel_structure_placement(false)


func _update_placement_preview() -> void:
	if _placement_preview == null or not is_instance_valid(_placement_preview) or _camera_rig == null:
		return

	var hit: Variant = _camera_rig.get_mouse_ground_position()
	if hit == null:
		_placement_preview.visible = false
		return

	var snapped_position: Vector3 = _snap_to_build_grid(hit as Vector3)
	_placement_preview.visible = true
	_placement_preview.global_position = snapped_position

	var validation: Dictionary = _economy.can_place_structure_at(_placement_structure_id, snapped_position)
	var is_valid: bool = bool(validation.get("success", false))
	if is_valid != _placement_preview_is_valid:
		_placement_preview_is_valid = is_valid
		_set_placement_preview_validity(is_valid)


func _snap_to_build_grid(world_position: Vector3) -> Vector3:
	return Vector3(
		roundf(world_position.x / BUILD_GRID_SIZE) * BUILD_GRID_SIZE,
		0.0,
		roundf(world_position.z / BUILD_GRID_SIZE) * BUILD_GRID_SIZE
	)


func _emit_placement_state_changed() -> void:
	placement_state_changed.emit(is_active(), _placement_structure_id, _placement_builder)


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


func _set_placement_preview_validity(is_valid: bool) -> void:
	if _placement_preview == null or not is_instance_valid(_placement_preview):
		return

	_apply_preview_validity_recursive(_placement_preview, is_valid)


func _apply_preview_validity_recursive(node: Node, is_valid: bool) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var material: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
		if material != null:
			material.albedo_color = Color(0.18, 0.85, 1.0, 0.28) if is_valid else Color(1.0, 0.3, 0.32, 0.3)
			material.emission_enabled = true
			material.emission = HUD_ACCENT if is_valid else HUD_INVALID
			material.emission_energy_multiplier = 0.55 if is_valid else 0.72

	for child: Node in node.get_children():
		_apply_preview_validity_recursive(child, is_valid)
