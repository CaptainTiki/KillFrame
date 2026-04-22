extends Node3D

@export var display_name: String = "Rifle Infantry"
@export var team: String = "player"
@export var attack_range: float = 4.0
@export var aggro_range: float = 8.0
@export var supply_cost: int = 1

var _selection_ring: MeshInstance3D = null

@onready var _unit_actions: UnitActionsComponent = $UnitActions as UnitActionsComponent


func _ready() -> void:
	name = display_name
	if team == "player":
		add_to_group("player_units")
		add_to_group("friendly_combat_units")
		add_to_group("player_targets")
		add_to_group("player_selectables")
	else:
		add_to_group("enemy_units")
		add_to_group("enemy_combat_units")
		add_to_group("enemy_targets")
	_create_selection_ring()
	_configure_actions()


func _process(delta: float) -> void:
	if _unit_actions != null:
		_unit_actions.process_actions(delta)


func set_move_target(target: Vector3) -> void:
	if _unit_actions != null:
		_unit_actions.issue_move(target)


func set_attack_target(target: Node3D) -> void:
	if target == null or _unit_actions == null:
		return

	_unit_actions.issue_attack(target)


func set_selected(is_selected: bool) -> void:
	if _selection_ring != null:
		_selection_ring.visible = is_selected


func get_selection_actions(_action_context: String, _economy: MissionEconomy) -> Array[Dictionary]:
	return []


func get_current_action_label() -> String:
	if _unit_actions != null:
		return _unit_actions.get_current_action_label()
	return "Idle"


func _configure_actions() -> void:
	if _unit_actions == null or _unit_actions.has_action("move"):
		return

	_unit_actions.clear_registered_actions()

	var move_action: MoveAction = MoveAction.new()
	_unit_actions.register_action(move_action)

	var attack_action: AttackAction = AttackAction.new()
	attack_action.configure({
		"attack_range": attack_range,
		"aggro_range": aggro_range,
	})
	_unit_actions.register_action(attack_action)


func _create_selection_ring() -> void:
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.5
	ring_mesh.bottom_radius = 0.5
	ring_mesh.height = 0.03

	var ring_material: StandardMaterial3D = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.1, 0.8, 1.0, 0.9)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.1, 0.8, 1.0, 1.0)
	ring_material.emission_energy_multiplier = 0.5
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_selection_ring = MeshInstance3D.new()
	selection_ring_setup(_selection_ring, ring_mesh, ring_material)
	add_child(_selection_ring)


func selection_ring_setup(ring: MeshInstance3D, ring_mesh: CylinderMesh, ring_material: StandardMaterial3D) -> void:
	ring.name = "SelectionRing"
	ring.mesh = ring_mesh
	ring.material_override = ring_material
	ring.position = Vector3(0.0, 0.05, 0.0)
	ring.visible = false
