extends Node3D

const TerrainManagerScript = preload("res://world/terrain/terrain_manager/terrain_manager.gd")
const TraversalTestUnitScene = preload("res://units/traversal_test_unit/traversal_test_unit.tscn")
const TraversalTestUnitScript = preload("res://units/traversal_test_unit/traversal_test_unit.gd")

var _terrain_manager: TerrainManagerScript
var _camera: Camera3D
var _unit: TraversalTestUnitScript
var _status_text: String = "Traversal unit not initialized."
var _default_spawn_cell: Vector2i = Vector2i(18, 18)
var _preset_destinations: Array[Dictionary] = [
	{"key": "1", "label": "Flat ground", "cell": Vector2i(34, 28)},
	{"key": "2", "label": "Choke corridor", "cell": Vector2i(56, 50)},
	{"key": "3", "label": "Ramp top", "cell": Vector2i(70, 82)},
	{"key": "4", "label": "Natural expansion", "cell": Vector2i(88, 30)},
]


func initialize(terrain_manager: TerrainManagerScript, camera: Camera3D) -> void:
	_terrain_manager = terrain_manager
	_camera = camera
	_ensure_unit()
	reset_unit_to_default_spawn()
	_status_text = "Traversal unit ready. Right click to issue a move command."


func handle_input(event: InputEvent) -> bool:
	if _terrain_manager == null:
		return false

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			match key_event.keycode:
				KEY_1:
					_issue_preset_move(0)
					return true
				KEY_2:
					_issue_preset_move(1)
					return true
				KEY_3:
					_issue_preset_move(2)
					return true
				KEY_4:
					_issue_preset_move(3)
					return true

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			var target_cell: Variant = _pick_mouse_cell()
			if target_cell == null:
				_status_text = "Move target is outside the terrain bounds."
				print("Traversal move ignored: mouse target is outside the terrain.")
				return true

			_issue_move_to_cell(target_cell as Vector2i, "Right click")
			return true

	return false


func sync_after_terrain_change(reset_to_spawn: bool) -> void:
	_ensure_unit()
	_unit.stop()
	_terrain_manager.clear_navigation_debug()

	if reset_to_spawn:
		reset_unit_to_default_spawn()
		_status_text = "Traversal unit reset to spawn after terrain regeneration."
		return

	var current_cell: Vector2i = _terrain_manager.get_cell_coords_from_world(_unit.global_position)
	if _terrain_manager.is_cell_walkable(current_cell.x, current_cell.y):
		_snap_unit_to_cell(current_cell)
		_status_text = "Traversal unit snapped back to the rebuilt terrain."
	else:
		reset_unit_to_default_spawn()
		_status_text = "Traversal unit respawned because its previous cell is no longer walkable."


func reset_unit_to_default_spawn() -> void:
	_ensure_unit()
	_snap_unit_to_cell(_default_spawn_cell)
	_terrain_manager.clear_navigation_debug()
	_status_text = "Traversal unit spawned at (%d, %d)." % [_default_spawn_cell.x, _default_spawn_cell.y]


func get_status_text() -> String:
	var unit_status: String = _unit.get_status_text() if _unit != null else "No unit"
	var path_marker_count: int = _terrain_manager.get_navigation_debug_marker_count() if _terrain_manager != null else 0
	var status_text: String = (
		"Traversal Sandbox\n"
		+ "Right click issues a move command\n"
		+ "Keys 1-4 run preset traversal tests\n"
		+ "1 flat | 2 choke | 3 ramp | 4 expansion\n\n"
		+ "Unit: %s\n"
		+ "Status: %s\n"
		+ "Path markers: %d"
	)
	return status_text % [unit_status, _status_text, path_marker_count]


func probe_preset_paths() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if _terrain_manager == null or _unit == null:
		return results

	var start_world: Vector3 = _unit.global_position
	for preset: Dictionary in _preset_destinations:
		var target_cell: Vector2i = preset["cell"]
		var target_world: Vector3 = _terrain_manager.get_cell_surface_world_position(target_cell.x, target_cell.y, 0.0)
		var path_result: Dictionary = _terrain_manager.request_navigation_path_world(start_world, target_world)
		results.append({
			"label": preset["label"],
			"target_cell": target_cell,
			"success": bool(path_result.get("success", false)),
			"path_length": int(path_result.get("path_length", 0)),
			"reason": str(path_result.get("reason", "")),
		})

	return results


func _ensure_unit() -> void:
	if _unit != null and is_instance_valid(_unit):
		return

	_unit = TraversalTestUnitScene.instantiate() as TraversalTestUnitScript
	add_child(_unit)
	_unit.move_started.connect(_on_unit_move_started)
	_unit.move_finished.connect(_on_unit_move_finished)
	_unit.move_stopped.connect(_on_unit_move_stopped)


func _issue_preset_move(index: int) -> void:
	var preset: Dictionary = _preset_destinations[index]
	_issue_move_to_cell(preset["cell"], "Preset %s (%s)" % [preset["key"], preset["label"]])


func _issue_move_to_cell(target_cell: Vector2i, source: String) -> void:
	if _unit == null or _terrain_manager == null:
		return

	var start_world: Vector3 = _unit.global_position
	var target_world: Vector3 = _terrain_manager.get_cell_surface_world_position(target_cell.x, target_cell.y, 0.0)
	var path_result: Dictionary = _terrain_manager.request_navigation_path_world(start_world, target_world)
	if not bool(path_result.get("success", false)):
		_status_text = "%s failed: %s" % [source, path_result.get("reason", "Unknown pathing error.")]
		_terrain_manager.clear_navigation_debug()
		print("Traversal path failed: %s" % [_status_text])
		return

	var world_path: Array[Vector3] = path_result["world_path"]
	_terrain_manager.show_navigation_path(world_path)
	_unit.set_move_target(target_world, world_path)

	var start_cell: Vector2i = path_result["start_cell"]
	var resolved_target_cell: Vector2i = path_result["target_cell"]
	_status_text = "%s path: (%d,%d) -> (%d,%d) using %d waypoints." % [
		source,
		start_cell.x,
		start_cell.y,
		resolved_target_cell.x,
		resolved_target_cell.y,
		int(path_result["path_length"]),
	]
	print("Traversal path found: %s" % [_status_text])


func _snap_unit_to_cell(cell_coords: Vector2i) -> void:
	var world_position: Vector3 = _terrain_manager.get_cell_surface_world_position(cell_coords.x, cell_coords.y, 0.0)
	_unit.snap_to_world_position(world_position)


func _pick_mouse_cell():
	if _camera == null:
		return null

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = _camera.project_ray_normal(mouse_position)
	var ground_plane: Plane = Plane(Vector3.UP, 0.0)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
	if intersection == null:
		return null

	var world_position: Vector3 = intersection as Vector3
	var cell_coords: Vector2i = _terrain_manager.get_cell_coords_from_world(world_position)
	if not _terrain_manager.map_data.in_bounds(cell_coords.x, cell_coords.y):
		return null

	return cell_coords


func _on_unit_move_started(_target_world_position: Vector3, waypoint_count: int) -> void:
	_status_text = "Unit moving along a %d-point path." % [waypoint_count]


func _on_unit_move_finished(final_world_position: Vector3) -> void:
	var final_cell: Vector2i = _terrain_manager.get_cell_coords_from_world(final_world_position)
	_status_text = "Unit reached destination cell (%d, %d)." % [final_cell.x, final_cell.y]
	print("Traversal move complete at cell (%d, %d)." % [final_cell.x, final_cell.y])


func _on_unit_move_stopped() -> void:
	if _status_text.begins_with("Traversal unit spawned") or _status_text.begins_with("Traversal unit ready"):
		return
	_status_text = "Traversal unit stopped."
