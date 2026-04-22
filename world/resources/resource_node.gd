extends Node3D
class_name ResourceNode

signal depleted(resource_type: String)

@export_enum("crystals", "bits") var resource_type: String = "crystals"
@export var max_amount: int = 120
@export var harvest_chunk: int = 10

var remaining_amount: int = 0
var _visual: MeshInstance3D = null


func _ready() -> void:
	add_to_group("resource_nodes")
	remaining_amount = max_amount
	_ensure_visual()
	_refresh_visual()


func harvest(requested_amount: int) -> int:
	if remaining_amount <= 0:
		return 0

	var harvested_amount: int = mini(requested_amount, remaining_amount)
	remaining_amount -= harvested_amount
	_refresh_visual()

	if remaining_amount <= 0:
		depleted.emit(resource_type)
		queue_free()

	return harvested_amount


func _ensure_visual() -> void:
	_visual = get_node_or_null("Visual") as MeshInstance3D
	if _visual == null:
		_visual = MeshInstance3D.new()
		_visual.name = "Visual"
		add_child(_visual)

	_visual.position = Vector3(0.0, 0.7, 0.0)

	if resource_type == "bits":
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = Vector3(1.1, 0.65, 1.1)
		_visual.mesh = box_mesh
	else:
		var crystal_mesh: CylinderMesh = CylinderMesh.new()
		crystal_mesh.top_radius = 0.18
		crystal_mesh.bottom_radius = 0.42
		crystal_mesh.height = 1.4
		_visual.mesh = crystal_mesh


func _refresh_visual() -> void:
	if _visual == null:
		return

	var ratio: float = clampf(float(remaining_amount) / maxf(float(max_amount), 1.0), 0.0, 1.0)
	var scale_multiplier: float = lerpf(0.35, 1.0, ratio)
	_visual.scale = Vector3.ONE * scale_multiplier
	_visual.position.y = 0.35 + scale_multiplier * 0.35

	var material: StandardMaterial3D = StandardMaterial3D.new()
	if resource_type == "bits":
		material.albedo_color = Color(0.28, 0.85, 0.52, 1.0)
		material.emission = Color(0.12, 0.7, 0.36, 1.0)
	else:
		material.albedo_color = Color(0.18, 0.85, 1.0, 1.0)
		material.emission = Color(0.08, 0.6, 0.95, 1.0)

	material.emission_enabled = true
	material.emission_energy_multiplier = 1.1
	material.roughness = 0.32
	material.metallic = 0.12
	_visual.material_override = material
