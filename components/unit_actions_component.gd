extends Node
class_name UnitActionsComponent

var _actions: Dictionary = {}
var _action_order: Array[String] = []
var _current_action_id: String = ""
var _economy: MissionEconomy = null
var _terrain_manager: TerrainManager = null


func _ready() -> void:
	_cache_economy()
	_cache_terrain_manager()


func register_action(action: BaseAction) -> void:
	if action == null:
		return

	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return

	action.setup(actor, self)

	var action_id: String = action.get_action_id()
	if action_id.is_empty():
		return

	_actions[action_id] = action
	if not _action_order.has(action_id):
		_action_order.append(action_id)


func clear_registered_actions() -> void:
	for action_variant: Variant in _actions.values():
		var action: BaseAction = action_variant as BaseAction
		if action != null:
			action.clear()

	_actions.clear()
	_action_order.clear()
	_current_action_id = ""


func has_action(action_id: String) -> bool:
	return _actions.has(action_id)


func process_actions(delta: float) -> void:
	if _economy == null:
		_cache_economy()

	var current_action: BaseAction = _get_action(_current_action_id)
	if current_action != null:
		if not current_action.process(delta):
			_current_action_id = ""

	for action_id: String in _action_order:
		if action_id == _current_action_id:
			continue

		var action: BaseAction = _get_action(action_id)
		if action != null:
			action.process_overlay(delta)


func issue_move(target: Vector3) -> bool:
	var payload: Dictionary = {"target": target}
	var path_result: Dictionary = _request_move_path(target)
	if path_result.get("success", false):
		var world_points: Array[Vector3] = []
		for point_variant: Variant in path_result.get("world_points", []):
			if point_variant is Vector3:
				world_points.append(point_variant as Vector3)

		if not world_points.is_empty():
			payload["path_points"] = world_points
			payload["target"] = world_points[world_points.size() - 1]

	return _issue_action("move", payload)


func issue_attack(target: Node3D) -> bool:
	return _issue_action("attack", {"target": target})


func issue_harvest(target: ResourceNode) -> bool:
	return _issue_action("harvest", {"target": target})


func issue_construct(target: Node3D) -> bool:
	return _issue_action("construct", {"target": target})


func get_current_action_label() -> String:
	var best_label: String = ""
	var best_priority: int = -1

	for action_id: String in _action_order:
		var action: BaseAction = _get_action(action_id)
		if action == null:
			continue

		var status_label: String = action.get_status_label()
		if status_label.is_empty():
			continue

		var status_priority: int = action.get_status_priority()
		if status_priority > best_priority:
			best_priority = status_priority
			best_label = status_label

	return best_label if best_priority >= 0 else "Idle"


func is_action_current(action_id: String) -> bool:
	return _current_action_id == action_id


func has_current_action() -> bool:
	return not _current_action_id.is_empty()


func get_economy() -> MissionEconomy:
	if _economy == null:
		_cache_economy()
	return _economy


func get_terrain_manager() -> TerrainManager:
	if _terrain_manager == null or not is_instance_valid(_terrain_manager):
		_cache_terrain_manager()
	return _terrain_manager


func get_team() -> String:
	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return "player"

	for property_info in actor.get_property_list():
		if str(property_info.get("name", "")) == "team":
			return str(actor.get("team"))

	return "player"


func get_target_label(target: Node3D) -> String:
	if target == null:
		return "Target"

	for property_info in target.get_property_list():
		if str(property_info.get("name", "")) == "display_name":
			return str(target.get("display_name"))

	return target.name


func move_actor_towards(target: Vector3, delta: float, stop_distance: float = 0.2) -> bool:
	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return false

	var movement: MovementComponent = actor.get_node_or_null("MovementComponent") as MovementComponent
	if movement == null:
		return false

	var flattened_target: Vector3 = Vector3(target.x, actor.global_position.y, target.z)
	var remaining_distance: float = actor.global_position.distance_to(flattened_target)
	if remaining_distance <= stop_distance:
		return true

	movement.move_towards(actor, flattened_target, delta)
	return actor.global_position.distance_to(flattened_target) <= stop_distance


func get_closest_position_outside_structure(structure: Node3D) -> Vector3:
	var actor: Node3D = get_parent() as Node3D
	if actor == null or structure == null:
		return Vector3.ZERO

	var visual: MeshInstance3D = structure.get_node_or_null("Visual") as MeshInstance3D
	if visual == null or visual.mesh == null:
		var fallback_direction: Vector3 = actor.global_position - structure.global_position
		fallback_direction.y = 0.0
		if fallback_direction.length() <= 0.05:
			fallback_direction = Vector3.FORWARD
		return structure.global_position + fallback_direction.normalized() * (get_actor_radius() + 0.08)

	var local_bounds: AABB = visual.get_aabb()
	var clearance: float = get_actor_radius() + 0.08
	var min_x: float = local_bounds.position.x - clearance
	var max_x: float = local_bounds.position.x + local_bounds.size.x + clearance
	var min_z: float = local_bounds.position.z - clearance
	var max_z: float = local_bounds.position.z + local_bounds.size.z + clearance
	var actor_local: Vector3 = structure.to_local(actor.global_position)
	var target_local_x: float = clampf(actor_local.x, min_x, max_x)
	var target_local_z: float = clampf(actor_local.z, min_z, max_z)
	var inside_x: bool = actor_local.x > min_x and actor_local.x < max_x
	var inside_z: bool = actor_local.z > min_z and actor_local.z < max_z

	if inside_x and inside_z:
		var distance_to_left: float = absf(actor_local.x - min_x)
		var distance_to_right: float = absf(max_x - actor_local.x)
		var distance_to_top: float = absf(actor_local.z - min_z)
		var distance_to_bottom: float = absf(max_z - actor_local.z)
		var nearest_edge_distance: float = distance_to_left
		target_local_x = min_x
		target_local_z = actor_local.z

		if distance_to_right < nearest_edge_distance:
			nearest_edge_distance = distance_to_right
			target_local_x = max_x
			target_local_z = actor_local.z
		if distance_to_top < nearest_edge_distance:
			nearest_edge_distance = distance_to_top
			target_local_x = actor_local.x
			target_local_z = min_z
		if distance_to_bottom < nearest_edge_distance:
			target_local_x = actor_local.x
			target_local_z = max_z

	return structure.to_global(Vector3(target_local_x, 0.0, target_local_z))


func get_actor_radius() -> float:
	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return 0.25

	var visual: MeshInstance3D = actor.get_node_or_null("Visual") as MeshInstance3D
	if visual != null and visual.mesh != null:
		var bounds: AABB = visual.get_aabb()
		return maxf(bounds.size.x, bounds.size.z) * 0.5

	return 0.25


func _issue_action(action_id: String, payload: Dictionary = {}) -> bool:
	var action: BaseAction = _get_action(action_id)
	if action == null:
		return false

	for other_action_id: String in _action_order:
		if other_action_id == action_id:
			continue

		var other_action: BaseAction = _get_action(other_action_id)
		if other_action != null:
			other_action.interrupt(action_id)

	action.issue(payload)
	_current_action_id = action_id
	return true


func _get_action(action_id: String) -> BaseAction:
	if action_id.is_empty() or not _actions.has(action_id):
		return null
	return _actions[action_id] as BaseAction


func _request_move_path(target: Vector3) -> Dictionary:
	var actor: Node3D = get_parent() as Node3D
	var terrain_manager: TerrainManager = get_terrain_manager()
	if actor == null or terrain_manager == null:
		return {}

	return terrain_manager.request_path_world(actor.global_position, target)


func _cache_economy() -> void:
	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return

	_economy = actor.get_tree().get_first_node_in_group("mission_economy") as MissionEconomy


func _cache_terrain_manager() -> void:
	var actor: Node3D = get_parent() as Node3D
	if actor == null:
		return

	_terrain_manager = actor.get_tree().get_first_node_in_group("terrain_manager") as TerrainManager
