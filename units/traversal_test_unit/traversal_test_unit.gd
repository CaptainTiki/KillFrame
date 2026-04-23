extends Node3D

signal move_started(target_world_position: Vector3, waypoint_count: int)
signal move_finished(final_world_position: Vector3)
signal move_stopped()

@export_range(0.5, 10.0, 0.1) var move_speed: float = 3.0
@export_range(0.01, 1.0, 0.01) var arrive_distance: float = 0.05

var _path_points: Array[Vector3] = []
var _current_path_index: int = 0
var _target_world_position: Vector3 = Vector3.ZERO
var _moving: bool = false


func _process(delta: float) -> void:
	if not _moving or _path_points.is_empty():
		return

	var next_point: Vector3 = _path_points[_current_path_index]
	var new_position: Vector3 = global_position.move_toward(next_point, move_speed * delta)
	global_position = new_position
	_orient_toward(next_point)

	if global_position.distance_to(next_point) > arrive_distance:
		return

	_current_path_index += 1
	if _current_path_index < _path_points.size():
		return

	global_position = next_point
	_moving = false
	emit_signal("move_finished", _target_world_position)


func set_move_target(target_world_position: Vector3, path_points: Array[Vector3] = []) -> void:
	_target_world_position = target_world_position
	_path_points = path_points.duplicate()
	if _path_points.is_empty():
		_path_points.append(target_world_position)

	_current_path_index = 0
	_moving = true
	emit_signal("move_started", target_world_position, _path_points.size())


func snap_to_world_position(world_position: Vector3) -> void:
	global_position = world_position
	_target_world_position = world_position
	_path_points.clear()
	_current_path_index = 0
	_moving = false


func stop() -> void:
	_path_points.clear()
	_current_path_index = 0
	_moving = false
	emit_signal("move_stopped")


func get_status_text() -> String:
	if _moving:
		return "Moving to (%.1f, %.1f, %.1f)" % [
			_target_world_position.x,
			_target_world_position.y,
			_target_world_position.z,
		]

	return "Idle"


func _orient_toward(target_position: Vector3) -> void:
	var facing_target: Vector3 = target_position - global_position
	facing_target.y = 0.0
	if facing_target.length_squared() <= 0.0001:
		return

	look_at(global_position + facing_target.normalized(), Vector3.UP)
