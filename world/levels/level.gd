extends Node3D
class_name Level

@onready var terrain_manager: TerrainManager = $TerrainManager as TerrainManager
@onready var camera_rig: MissionCameraRig = $CameraRig as MissionCameraRig
@onready var camera_start: Node3D = $CameraStart as Node3D


func _ready() -> void:
	_initialize_terrain()
	_initialize_camera()
	_on_level_ready()


func _initialize_terrain() -> void:
	terrain_manager.refresh_runtime_data()


func _initialize_camera() -> void:
	camera_rig.global_transform = camera_start.global_transform
	camera_rig.configure_from_terrain(terrain_manager)


func _on_level_ready() -> void:
	pass


func is_buildable(x: int, z: int) -> bool:
	return terrain_manager.is_cell_buildable(x, z)


func is_walkable(x: int, z: int) -> bool:
	return terrain_manager.is_cell_walkable(x, z)
