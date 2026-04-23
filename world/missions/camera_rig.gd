extends Node3D
class_name MissionCameraRig

const GROUND_PLANE: Plane = Plane(Vector3.UP, 0.0)

@export var camera_move_speed: float = 14.0
@export var movement_bounds_padding: Vector2 = Vector2.ZERO

@onready var _camera: Camera3D = $Camera3D as Camera3D

var _movement_bounds_enabled: bool = false
var _camera_min_x: float = 0.0
var _camera_max_x: float = 0.0
var _camera_min_z: float = 0.0
var _camera_max_z: float = 0.0


func _process(delta: float) -> void:
	_update_camera_movement(delta)


func get_camera() -> Camera3D:
	return _camera


func configure_from_terrain(terrain_manager: TerrainManager) -> void:
	var bounds: Dictionary = terrain_manager.get_world_bounds_2d()
	if not bool(bounds.get("valid", false)):
		clear_movement_bounds()
		return

	var min_bounds: Vector2 = bounds.get("min", Vector2.ZERO) as Vector2
	var max_bounds: Vector2 = bounds.get("max", Vector2.ZERO) as Vector2
	set_movement_bounds(min_bounds.x, max_bounds.x, min_bounds.y, max_bounds.y)


func set_movement_bounds(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	_movement_bounds_enabled = true
	_camera_min_x = minf(min_x, max_x) - movement_bounds_padding.x
	_camera_max_x = maxf(min_x, max_x) + movement_bounds_padding.x
	_camera_min_z = minf(min_z, max_z) - movement_bounds_padding.y
	_camera_max_z = maxf(min_z, max_z) + movement_bounds_padding.y
	_clamp_position_to_bounds()


func clear_movement_bounds() -> void:
	_movement_bounds_enabled = false


func get_mouse_ground_position() -> Variant:
	if _camera == null:
		return null

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	return GROUND_PLANE.intersects_ray(ray_origin, ray_normal)


func get_target_under_mouse(group_name: String, max_radius: float) -> Node3D:
	if _camera == null:
		return null

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var best_target: Node3D = null
	var best_screen_dist: float = max_radius

	for node: Node in get_tree().get_nodes_in_group(group_name):
		if node is not Node3D:
			continue

		var target: Node3D = node as Node3D
		if not is_instance_valid(target):
			continue
		if _camera.is_position_behind(target.global_position):
			continue

		var target_screen: Vector2 = _camera.unproject_position(target.global_position)
		var screen_dist: float = target_screen.distance_to(mouse_pos)
		if screen_dist <= best_screen_dist:
			best_target = target
			best_screen_dist = screen_dist

	return best_target


func _update_camera_movement(delta: float) -> void:
	if _camera == null:
		return

	var input_vector: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0

	if input_vector == Vector2.ZERO:
		return

	input_vector = input_vector.normalized()
	var next_position: Vector3 = position
	next_position.x += input_vector.x * camera_move_speed * delta
	next_position.z += input_vector.y * camera_move_speed * delta
	if _movement_bounds_enabled:
		next_position.x = clampf(next_position.x, _camera_min_x, _camera_max_x)
		next_position.z = clampf(next_position.z, _camera_min_z, _camera_max_z)
	position = next_position


func _clamp_position_to_bounds() -> void:
	if not _movement_bounds_enabled:
		return

	position.x = clampf(position.x, _camera_min_x, _camera_max_x)
	position.z = clampf(position.z, _camera_min_z, _camera_max_z)
