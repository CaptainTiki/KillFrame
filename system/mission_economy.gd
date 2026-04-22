extends Node
class_name MissionEconomy

signal state_changed

const BUILDING_COSTS := {
	"barracks": {"crystals": 80, "bits": 0},
	"vehicle_factory": {"crystals": 110, "bits": 25},
	"bandwidth_relay": {"crystals": 50, "bits": 0},
}

const UNIT_COSTS := {
	"worker": {"crystals": 20, "bits": 0, "supply": 1},
	"rifle": {"crystals": 25, "bits": 0, "supply": 1},
	"scout": {"crystals": 45, "bits": 15, "supply": 2},
}

const UNIT_BUILD_TIMES := {
	"worker": 3.0,
	"rifle": 4.0,
	"scout": 5.5,
}

const UNIT_LABELS := {
	"worker": "Worker",
	"rifle": "Rifle Infantry",
	"scout": "Scout",
}

const STRUCTURE_LABELS := {
	"barracks": "Barracks",
	"vehicle_factory": "Vehicle Factory",
	"bandwidth_relay": "Bandwidth Relay",
}

const STRUCTURE_FOOTPRINT_RADII := {
	"hq": 1.8,
	"barracks": 2.0,
	"vehicle_factory": 2.3,
	"bandwidth_relay": 1.1,
	"resource_node": 1.0,
	"enemy_core": 1.9,
}

const SPAWN_OFFSETS := [
	Vector3(-1.6, 0.0, 3.2),
	Vector3(0.0, 0.0, 3.8),
	Vector3(1.6, 0.0, 3.2),
	Vector3(-0.9, 0.0, 4.8),
	Vector3(0.9, 0.0, 4.8),
]

@export var starting_crystals: int = 120
@export var starting_bits: int = 20

var crystals: int = 0
var bits: int = 0
var supply_cap: int = 0
var supply_used: int = 0
var _reserved_supply: int = 0

var player_hq: Node3D = null

var _registered_units: Dictionary = {}
var _structures: Dictionary = {}
var _relay_supply_bonuses: Dictionary = {}
var _spawn_counters: Dictionary = {}


func _ready() -> void:
	add_to_group("mission_economy")
	crystals = starting_crystals
	bits = starting_bits


func register_player_hq(hq: Node3D) -> void:
	if hq == null or not is_instance_valid(hq):
		return

	if player_hq != null and is_instance_valid(player_hq):
		var old_bonus: int = _read_int_property(player_hq, "supply_bonus", 0)
		supply_cap = maxi(0, supply_cap - old_bonus)

	player_hq = hq
	supply_cap += _read_int_property(hq, "supply_bonus", 0)
	_register_existing_player_units()
	state_changed.emit()


func request_build_barracks() -> Dictionary:
	return _result(false, "Select a worker and place the Barracks on the grid.")


func request_build_vehicle_factory() -> Dictionary:
	return _result(false, "Select a worker and place the Vehicle Factory on the grid.")


func request_build_bandwidth_relay() -> Dictionary:
	return _result(false, "Select a worker and place the Bandwidth Relay on the grid.")


func request_train_worker(source: Node3D = null) -> Dictionary:
	return _request_unit("worker", source)


func request_train_rifle(source: Node3D = null) -> Dictionary:
	return _request_unit("rifle", source)


func request_train_scout(source: Node3D = null) -> Dictionary:
	return _request_unit("scout", source)


func begin_unit_production(unit_id: String, source: Node3D = null) -> Dictionary:
	if source == null:
		source = _get_production_source(unit_id)
	if source == null:
		return _result(false, _get_missing_source_message(unit_id))

	if source.has_method("is_under_construction") and bool(source.call("is_under_construction")):
		return _result(false, "Finish construction before using this structure.")

	var cost: Dictionary = get_unit_cost(unit_id)
	var validation: Dictionary = _validate_cost(cost)
	if not validation["success"]:
		return validation

	_spend_cost(cost)
	_reserved_supply += int(cost.get("supply", 0))
	state_changed.emit()
	return _result(true, "%s production started." % get_unit_label(unit_id))


func complete_unit_production(unit_id: String, source: Node3D, spawn_position: Variant = null) -> Dictionary:
	var reserved_supply_cost: int = int(get_unit_cost(unit_id).get("supply", 0))
	if source == null or not is_instance_valid(source):
		_reserved_supply = maxi(0, _reserved_supply - reserved_supply_cost)
		state_changed.emit()
		return _result(false, "Production source unavailable.")

	var unit: Node3D = _instantiate_unit(unit_id)
	if unit == null:
		_reserved_supply = maxi(0, _reserved_supply - reserved_supply_cost)
		state_changed.emit()
		return _result(false, "%s failed to instantiate." % get_unit_label(unit_id))

	get_parent().add_child(unit)
	unit.global_position = get_unit_spawn_position(source, spawn_position)
	_reserved_supply = maxi(0, _reserved_supply - reserved_supply_cost)
	register_player_unit(unit)
	state_changed.emit()
	return _result(true, "%s deployed." % get_unit_label(unit_id))


func get_unit_spawn_position(source: Node3D, spawn_origin: Variant = null) -> Vector3:
	var origin: Vector3 = source.global_position
	if spawn_origin is Vector3:
		origin = spawn_origin as Vector3
	return origin + _get_next_spawn_offset(source)


func register_player_unit(unit: Node3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var unit_id: int = unit.get_instance_id()
	if _registered_units.has(unit_id):
		return

	var unit_supply: int = _read_int_property(unit, "supply_cost", 0)
	_registered_units[unit_id] = unit_supply
	supply_used += unit_supply
	unit.tree_exited.connect(_on_registered_unit_exited.bind(unit_id), CONNECT_ONE_SHOT)
	state_changed.emit()


func add_resource(resource_type: String, amount: int) -> void:
	if amount <= 0:
		return

	match resource_type:
		"crystals":
			crystals += amount
		"bits":
			bits += amount
		_:
			return

	state_changed.emit()


func get_primary_dropoff_position() -> Variant:
	if not has_hq():
		return null
	return player_hq.global_position


func has_hq() -> bool:
	return player_hq != null and is_instance_valid(player_hq)


func has_structure(structure_id: String) -> bool:
	return _find_player_structure(structure_id, true) != null


func has_free_relay_slot() -> bool:
	return true


func get_structure_cost(structure_id: String) -> Dictionary:
	if not BUILDING_COSTS.has(structure_id):
		return {}
	return BUILDING_COSTS[structure_id].duplicate(true)


func get_unit_cost(unit_id: String) -> Dictionary:
	if not UNIT_COSTS.has(unit_id):
		return {}
	return UNIT_COSTS[unit_id].duplicate(true)


func get_unit_label(unit_id: String) -> String:
	return str(UNIT_LABELS.get(unit_id, "Unit"))


func get_unit_build_time(unit_id: String) -> float:
	return float(UNIT_BUILD_TIMES.get(unit_id, 0.0))


func get_committed_supply_used() -> int:
	return supply_used + _reserved_supply


func format_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var crystal_cost: int = int(cost.get("crystals", 0))
	var bit_cost: int = int(cost.get("bits", 0))
	var supply_cost: int = int(cost.get("supply", 0))

	if crystal_cost > 0:
		parts.append("%dC" % crystal_cost)
	if bit_cost > 0:
		parts.append("%dB" % bit_cost)
	if supply_cost > 0:
		parts.append("%d Supply" % supply_cost)

	if parts.is_empty():
		return "Free"
	return " / ".join(parts)


func can_start_structure_placement(structure_id: String) -> Dictionary:
	if not has_hq():
		return _result(false, "Deploy the HQ before constructing buildings.")

	if not BUILDING_COSTS.has(structure_id):
		return _result(false, "Unknown structure request.")

	return _validate_cost(get_structure_cost(structure_id))


func can_place_structure_at(structure_id: String, world_position: Vector3) -> Dictionary:
	if not STRUCTURE_LABELS.has(structure_id):
		return _result(false, "Unknown structure request.")

	var footprint_radius: float = _get_structure_footprint_radius(structure_id)
	for blocker: Node3D in _get_placement_blockers():
		if blocker == null or not is_instance_valid(blocker):
			continue
		var blocker_radius: float = _get_blocker_radius(blocker)
		var separation: float = footprint_radius + blocker_radius
		if blocker.global_position.distance_to(world_position) < separation:
			return _result(false, "%s needs a clearer build tile." % STRUCTURE_LABELS[structure_id])

	return _result(true, "")


func place_structure(structure_id: String, world_position: Vector3) -> Dictionary:
	var validation: Dictionary = can_start_structure_placement(structure_id)
	if not validation["success"]:
		return validation

	validation = can_place_structure_at(structure_id, world_position)
	if not validation["success"]:
		return validation

	var structure: Node3D = _instantiate_structure(structure_id)
	if structure == null:
		return _result(false, "%s failed to instantiate." % STRUCTURE_LABELS.get(structure_id, "Structure"))

	var health: HealthComponent = structure.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.current_health = 1.0

	_spend_cost(get_structure_cost(structure_id))
	get_parent().add_child(structure)
	structure.global_position = world_position

	if structure.has_method("set_under_construction"):
		structure.call("set_under_construction", true)

	var structure_instance_id: int = structure.get_instance_id()
	_structures[structure_instance_id] = structure_id
	structure.tree_exited.connect(_on_structure_exited.bind(structure_instance_id), CONNECT_ONE_SHOT)
	if structure_id == "bandwidth_relay":
		structure.tree_exited.connect(_on_relay_exited.bind(structure_instance_id), CONNECT_ONE_SHOT)
	state_changed.emit()

	return {
		"success": true,
		"message": "%s placed. Worker en route to build." % STRUCTURE_LABELS.get(structure_id, "Structure"),
		"structure": structure,
	}


func notify_structure_constructed(structure: Node3D) -> void:
	if structure == null or not is_instance_valid(structure):
		return

	var structure_id: String = _get_structure_id(structure)
	if structure_id == "bandwidth_relay":
		var relay_id: int = structure.get_instance_id()
		if not _relay_supply_bonuses.has(relay_id):
			var supply_bonus: int = _read_int_property(structure, "supply_bonus", 0)
			_relay_supply_bonuses[relay_id] = supply_bonus
			supply_cap += supply_bonus

	state_changed.emit()


func instantiate_structure_preview(structure_id: String) -> Node3D:
	var preview: Node3D = _instantiate_structure(structure_id)
	if preview == null:
		return null

	return preview


func configure_structure_preview(preview: Node3D) -> void:
	if preview == null:
		return

	_remove_preview_groups(preview)
	_apply_preview_visuals(preview)

	var selection_ring: Node = preview.get_node_or_null("SelectionRing")
	if selection_ring is Node3D:
		(selection_ring as Node3D).visible = false

	var health: Node = preview.get_node_or_null("HealthComponent")
	if health != null:
		health.queue_free()


func _register_existing_player_units() -> void:
	for node: Node in get_tree().get_nodes_in_group("player_units"):
		if node is Node3D:
			register_player_unit(node as Node3D)
	state_changed.emit()


func _request_unit(unit_id: String, source: Node3D = null) -> Dictionary:
	var begin_result: Dictionary = begin_unit_production(unit_id, source)
	if not begin_result.get("success", false):
		return begin_result

	if source == null:
		source = _get_production_source(unit_id)
	return complete_unit_production(unit_id, source)


func _get_missing_source_message(unit_id: String) -> String:
	match unit_id:
		"worker":
			return "The HQ must be online before workers can deploy."
		"rifle":
			return "Build a Barracks before training Rifle Infantry."
		"scout":
			return "Build a Vehicle Factory before assembling Scouts."
		_:
			return "The required production structure is not online."


func _get_production_source(unit_id: String) -> Node3D:
	match unit_id:
		"worker":
			return player_hq if has_hq() else null
		"rifle":
			return _find_player_structure("barracks", true)
		"scout":
			return _find_player_structure("vehicle_factory", true)
	return null


func _get_structure_slot(structure_id: String) -> Node3D:
	return null


func _get_next_open_relay_slot() -> Node3D:
	return null


func _instantiate_structure(structure_id: String) -> Node3D:
	match structure_id:
		"barracks":
			return BuildingPrefabs.BARRACKS.instantiate() as Node3D
		"vehicle_factory":
			return BuildingPrefabs.VEHICLE_FACTORY.instantiate() as Node3D
		"bandwidth_relay":
			return BuildingPrefabs.BANDWIDTH_RELAY.instantiate() as Node3D
	return null


func _instantiate_unit(unit_id: String) -> Node3D:
	match unit_id:
		"worker":
			return UnitPrefabs.WORKER.instantiate() as Node3D
		"rifle":
			return UnitPrefabs.RIFLE.instantiate() as Node3D
		"scout":
			return UnitPrefabs.SCOUT.instantiate() as Node3D
	return null


func _validate_cost(cost: Dictionary) -> Dictionary:
	var crystal_cost: int = int(cost.get("crystals", 0))
	var bit_cost: int = int(cost.get("bits", 0))
	var supply_cost: int = int(cost.get("supply", 0))

	if crystals < crystal_cost:
		return _result(false, "Need %d more Crystals." % (crystal_cost - crystals))
	if bits < bit_cost:
		return _result(false, "Need %d more Bits." % (bit_cost - bits))
	if supply_cost > 0 and get_committed_supply_used() + supply_cost > supply_cap:
		return _result(false, "Supply capped. Build a Bandwidth Relay.")

	return _result(true, "")


func _spend_cost(cost: Dictionary) -> void:
	crystals -= int(cost.get("crystals", 0))
	bits -= int(cost.get("bits", 0))


func _get_next_spawn_offset(source: Node3D) -> Vector3:
	var source_id: int = source.get_instance_id()
	var spawn_index: int = int(_spawn_counters.get(source_id, 0))
	_spawn_counters[source_id] = spawn_index + 1
	return SPAWN_OFFSETS[spawn_index % SPAWN_OFFSETS.size()]


func _read_int_property(object: Object, property_name: String, fallback: int) -> int:
	for property_info in object.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return int(object.get(property_name))
	return fallback


func _on_registered_unit_exited(unit_id: int) -> void:
	if not _registered_units.has(unit_id):
		return

	supply_used = maxi(0, supply_used - int(_registered_units[unit_id]))
	_registered_units.erase(unit_id)
	state_changed.emit()


func _on_structure_exited(instance_id: int) -> void:
	if not _structures.has(instance_id):
		return

	_structures.erase(instance_id)
	state_changed.emit()


func _on_relay_exited(relay_id: int) -> void:
	if _relay_supply_bonuses.has(relay_id):
		supply_cap = maxi(0, supply_cap - int(_relay_supply_bonuses[relay_id]))
		_relay_supply_bonuses.erase(relay_id)

	state_changed.emit()


func _get_structure_id(structure: Node3D) -> String:
	if structure == null:
		return ""
	if structure.has_method("get_structure_id"):
		return str(structure.call("get_structure_id"))

	for property_info in structure.get_property_list():
		if str(property_info.get("name", "")) == "structure_id":
			return str(structure.get("structure_id"))

	return ""


func _find_player_structure(structure_id: String, require_completed: bool) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group("player_structures"):
		if node is not Node3D:
			continue

		var structure: Node3D = node as Node3D
		if not is_instance_valid(structure):
			continue
		if _get_structure_id(structure) != structure_id:
			continue
		if require_completed and structure.has_method("is_under_construction") and bool(structure.call("is_under_construction")):
			continue
		return structure

	return null


func _get_placement_blockers() -> Array[Node3D]:
	var blockers: Array[Node3D] = []

	for node: Node in get_tree().get_nodes_in_group("player_structures"):
		if node is Node3D:
			blockers.append(node as Node3D)

	for node: Node in get_tree().get_nodes_in_group("resource_nodes"):
		if node is Node3D:
			blockers.append(node as Node3D)

	for node: Node in get_tree().get_nodes_in_group("enemy_targets"):
		if node is not Node3D:
			continue
		var blocker: Node3D = node as Node3D
		if blocker.has_method("set_move_target"):
			continue
		blockers.append(blocker)

	return blockers


func _get_structure_footprint_radius(structure_id: String) -> float:
	return float(STRUCTURE_FOOTPRINT_RADII.get(structure_id, 1.5))


func _get_blocker_radius(blocker: Node3D) -> float:
	if blocker.is_in_group("resource_nodes"):
		return float(STRUCTURE_FOOTPRINT_RADII["resource_node"])

	var structure_id: String = _get_structure_id(blocker)
	if not structure_id.is_empty():
		return _get_structure_footprint_radius(structure_id)

	if blocker.is_in_group("enemy_targets"):
		return float(STRUCTURE_FOOTPRINT_RADII["enemy_core"])

	return 1.5


func _remove_preview_groups(node: Node) -> void:
	var preview_groups: Array[String] = [
		"player_targets",
		"player_structures",
		"player_selectables",
	]
	for group_name: String in preview_groups:
		node.remove_from_group(group_name)

	for child: Node in node.get_children():
		_remove_preview_groups(child)


func _apply_preview_visuals(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var source_material: BaseMaterial3D = mesh_instance.material_override as BaseMaterial3D
		if source_material != null:
			var material_copy: BaseMaterial3D = source_material.duplicate()
			if material_copy is StandardMaterial3D:
				var standard_material: StandardMaterial3D = material_copy as StandardMaterial3D
				standard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				standard_material.albedo_color.a = 0.28
				standard_material.emission_enabled = true
				standard_material.emission = Color(0.1, 0.8, 1.0, 1.0)
				standard_material.emission_energy_multiplier = 0.55
			mesh_instance.material_override = material_copy

	for child: Node in node.get_children():
		_apply_preview_visuals(child)


func _result(success: bool, message: String) -> Dictionary:
	return {
		"success": success,
		"message": message,
	}
