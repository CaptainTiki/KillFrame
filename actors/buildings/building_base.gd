extends Node3D
class_name BuildingBase

@export var display_name: String = "Building"
@export var structure_id: String = ""
@export var selection_radius: float = 1.4
@export var supply_bonus: int = 0

var _selection_ring: MeshInstance3D = null

@onready var _construction_component: ConstructionComponent = $ConstructionComponent as ConstructionComponent
@onready var _production_component: ProductionComponent = get_node_or_null("ProductionComponent") as ProductionComponent


func _ready() -> void:
	name = display_name
	add_to_group("player_targets")
	add_to_group("player_structures")
	add_to_group("player_selectables")
	_create_selection_ring()
	_configure_production()


func _process(delta: float) -> void:
	if _production_component != null:
		_production_component.process_production(delta)


func set_selected(is_selected: bool) -> void:
	if _selection_ring != null:
		_selection_ring.visible = is_selected


func get_selection_actions(action_context: String, economy: MissionEconomy) -> Array[Dictionary]:
	if _production_component == null:
		return []
	return _production_component.get_selection_actions(action_context, economy, is_under_construction())


func perform_selection_action(action_id: String, economy: MissionEconomy) -> Dictionary:
	if _production_component == null:
		return {"success": false, "message": "That structure action is unavailable."}
	return _production_component.perform_action(action_id, economy)


func set_under_construction(value: bool) -> void:
	set_meta("under_construction", value)
	if _construction_component != null:
		_construction_component.set_under_construction(value)


func is_under_construction() -> bool:
	return _construction_component != null and _construction_component.is_under_construction()


func get_structure_id() -> String:
	return structure_id


func get_current_action_label() -> String:
	if _construction_component != null and _construction_component.is_under_construction():
		return _construction_component.get_current_action_label()
	if _production_component != null:
		return _production_component.get_current_action_label("Online")
	return "Online"


func _configure_production() -> void:
	pass


func _create_selection_ring() -> void:
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = selection_radius
	ring_mesh.bottom_radius = selection_radius
	ring_mesh.height = 0.04

	var ring_material: StandardMaterial3D = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.1, 0.8, 1.0, 0.9)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.1, 0.8, 1.0, 1.0)
	ring_material.emission_energy_multiplier = 0.55
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_selection_ring = MeshInstance3D.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.mesh = ring_mesh
	_selection_ring.material_override = ring_material
	_selection_ring.position = Vector3(0.0, 0.05, 0.0)
	_selection_ring.visible = false
	add_child(_selection_ring)
