extends Node
class_name MissionOrderController

signal status_message_requested(text: String)

const FORMATION_SPACING: float = 1.3
const ORDER_TARGET_PIXEL_RADIUS: float = 60.0

@onready var _camera_rig: MissionCameraRig = $"../CameraRig" as MissionCameraRig
@onready var _selection_controller: MissionSelectionController = $"../SelectionController" as MissionSelectionController


func issue_group_order() -> void:
	if _camera_rig == null or _selection_controller == null:
		return

	var orderables: Array[Node3D] = _selection_controller.get_selected_orderables()
	if orderables.is_empty():
		return

	var clicked_enemy: Node3D = _camera_rig.get_target_under_mouse("enemy_targets", ORDER_TARGET_PIXEL_RADIUS)
	if clicked_enemy != null:
		for unit: Node3D in orderables:
			if is_instance_valid(unit) and unit.has_method("set_attack_target"):
				unit.call("set_attack_target", clicked_enemy)
		status_message_requested.emit("Attack order issued.")
		return

	var clicked_resource: ResourceNode = _camera_rig.get_target_under_mouse("resource_nodes", ORDER_TARGET_PIXEL_RADIUS) as ResourceNode
	if clicked_resource != null:
		var workers_assigned: int = 0
		for unit: Node3D in orderables:
			if is_instance_valid(unit) and unit.has_method("set_harvest_target"):
				unit.call("set_harvest_target", clicked_resource)
				workers_assigned += 1
		if workers_assigned > 0:
			status_message_requested.emit("%d worker(s) harvesting %s." % [workers_assigned, clicked_resource.resource_type])
			return

	var clicked_structure: Node3D = _camera_rig.get_target_under_mouse("player_structures", ORDER_TARGET_PIXEL_RADIUS)
	if _structure_needs_construction(clicked_structure):
		var builders_assigned: int = 0
		for unit: Node3D in orderables:
			if is_instance_valid(unit) and unit.has_method("set_construction_target"):
				unit.call("set_construction_target", clicked_structure)
				builders_assigned += 1
		if builders_assigned > 0:
			status_message_requested.emit("%d worker(s) assisting %s." % [builders_assigned, _get_selection_name(clicked_structure)])
			return

	var hit: Variant = _camera_rig.get_mouse_ground_position()
	if hit == null:
		return

	var target: Vector3 = hit as Vector3
	var unit_count: int = orderables.size()
	var columns: int = int(ceil(sqrt(float(unit_count))))
	for i: int in range(unit_count):
		var row: int = i / columns
		var col: int = i % columns
		var offset_x: float = (float(col) - float(columns - 1) * 0.5) * FORMATION_SPACING
		var offset_z: float = float(row) * FORMATION_SPACING
		var move_target: Vector3 = target + Vector3(offset_x, 0.0, offset_z)
		var unit: Node3D = orderables[i]
		if is_instance_valid(unit) and unit.has_method("set_move_target"):
			unit.call("set_move_target", move_target)

	status_message_requested.emit("Move order issued.")


func _structure_needs_construction(structure: Node3D) -> bool:
	if structure == null or not is_instance_valid(structure):
		return false

	if structure.has_method("is_under_construction") and bool(structure.call("is_under_construction")):
		return true

	var health: HealthComponent = structure.get_node_or_null("HealthComponent") as HealthComponent
	return health != null and not health.is_full_health()


func _get_selection_name(entity: Node3D) -> String:
	if entity == null:
		return "Unknown"

	for property_info in entity.get_property_list():
		if str(property_info.get("name", "")) == "display_name":
			return str(entity.get("display_name"))

	return entity.name
