extends Node
class_name ConstructionComponent

@export var visual_path: NodePath = ^"../Visual"
@export var under_construction_alpha: float = 0.45
@export var emission_color: Color = Color(0.1, 0.8, 1.0, 1.0)
@export var emission_energy: float = 0.3

var _visual: MeshInstance3D = null
var _base_material: BaseMaterial3D = null
var _is_under_construction: bool = false


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as MeshInstance3D
	if _visual != null and _visual.material_override != null:
		_base_material = _visual.material_override.duplicate(true) as BaseMaterial3D
	_apply_visual_state()


func set_under_construction(value: bool) -> void:
	_is_under_construction = value
	_apply_visual_state()


func is_under_construction() -> bool:
	return _is_under_construction


func get_current_action_label(fallback: String = "Online") -> String:
	if _is_under_construction:
		return "Under Construction"
	return fallback


func _apply_visual_state() -> void:
	if _visual == null or _base_material == null:
		return

	var material_copy: BaseMaterial3D = _base_material.duplicate(true) as BaseMaterial3D
	if material_copy is StandardMaterial3D:
		var standard_material: StandardMaterial3D = material_copy as StandardMaterial3D
		if _is_under_construction:
			standard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			standard_material.albedo_color.a = under_construction_alpha
			standard_material.emission_enabled = true
			standard_material.emission = emission_color
			standard_material.emission_energy_multiplier = emission_energy
		else:
			standard_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			standard_material.albedo_color.a = 1.0
			standard_material.emission_enabled = false

	_visual.material_override = material_copy
