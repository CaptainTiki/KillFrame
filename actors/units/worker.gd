extends Node3D

@export var display_name: String = "Worker"
@export var supply_cost: int = 1
@export var harvest_amount: int = 10
@export var harvest_interval: float = 0.75
@export var harvest_range: float = 1.2
@export var dropoff_range: float = 1.8
@export var build_range: float = 1.4
@export var build_repair_rate: float = 2.0

var _selection_ring: MeshInstance3D = null

@onready var _unit_actions: UnitActionsComponent = $UnitActions as UnitActionsComponent


func _ready() -> void:
	name = display_name
	add_to_group("player_units")
	add_to_group("player_targets")
	add_to_group("player_selectables")
	_create_selection_ring()
	_configure_actions()


func _process(delta: float) -> void:
	if _unit_actions != null:
		_unit_actions.process_actions(delta)


func set_move_target(target: Vector3) -> void:
	if _unit_actions != null:
		_unit_actions.issue_move(target)


func set_harvest_target(target: ResourceNode) -> void:
	if target == null or _unit_actions == null:
		return

	_unit_actions.issue_harvest(target)


func set_selected(is_selected: bool) -> void:
	if _selection_ring != null:
		_selection_ring.visible = is_selected


func get_selection_actions(action_context: String, economy: MissionEconomy) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if action_context == "root":
		actions.append({
			"id": "open_worker_build_menu",
			"label": "Build",
			"kind": "submenu",
			"next_context": "worker_build",
			"next_context_label": "Worker Build",
		})
		return actions

	if action_context != "worker_build" or economy == null:
		return actions

	actions.append({
		"id": "build_barracks",
		"label": "Construct Barracks (%s)" % economy.format_cost(economy.get_structure_cost("barracks")),
		"kind": "placement",
		"structure_id": "barracks",
	})
	actions.append({
		"id": "build_vehicle_factory",
		"label": "Construct Vehicle Factory (%s)" % economy.format_cost(economy.get_structure_cost("vehicle_factory")),
		"kind": "placement",
		"structure_id": "vehicle_factory",
	})
	actions.append({
		"id": "build_bandwidth_relay",
		"label": "Build Bandwidth Relay (%s)" % economy.format_cost(economy.get_structure_cost("bandwidth_relay")),
		"kind": "placement",
		"structure_id": "bandwidth_relay",
	})

	return actions


func set_construction_target(target: Node3D) -> void:
	if target == null or _unit_actions == null:
		return

	_unit_actions.issue_construct(target)


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

	var harvest_action: HarvestAction = HarvestAction.new()
	harvest_action.configure({
		"harvest_amount": harvest_amount,
		"harvest_interval": harvest_interval,
		"harvest_range": harvest_range,
		"dropoff_range": dropoff_range,
	})
	_unit_actions.register_action(harvest_action)

	var construct_action: ConstructAction = ConstructAction.new()
	construct_action.configure({
		"build_repair_rate": build_repair_rate,
		"stop_distance": 0.08,
	})
	_unit_actions.register_action(construct_action)


func _create_selection_ring() -> void:
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.45
	ring_mesh.bottom_radius = 0.45
	ring_mesh.height = 0.03

	var ring_material: StandardMaterial3D = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.1, 0.8, 1.0, 0.9)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.1, 0.8, 1.0, 1.0)
	ring_material.emission_energy_multiplier = 0.5
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_selection_ring = MeshInstance3D.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.mesh = ring_mesh
	_selection_ring.material_override = ring_material
	_selection_ring.position = Vector3(0.0, 0.05, 0.0)
	_selection_ring.visible = false
	add_child(_selection_ring)
