extends MeshInstance3D

var _box_mesh: BoxMesh
var _marker_material: StandardMaterial3D


func _ready() -> void:
	_ensure_unique_resources()


func configure_marker(color: Color, size: Vector3, world_position: Vector3) -> void:
	_ensure_unique_resources()
	_box_mesh.size = size
	_marker_material.albedo_color = color
	global_position = world_position
	visible = true


func set_marker_enabled(enabled: bool) -> void:
	visible = enabled


func _ensure_unique_resources() -> void:
	if _box_mesh == null:
		_box_mesh = (mesh as BoxMesh).duplicate() as BoxMesh
		mesh = _box_mesh

	if _marker_material == null:
		_marker_material = (material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		material_override = _marker_material
