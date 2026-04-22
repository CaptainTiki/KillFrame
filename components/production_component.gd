extends Node
class_name ProductionComponent

@export var spawn_anchor_path: NodePath = ^"../SpawnAnchor"

var _offers: Dictionary = {}
var _offer_order: Array[String] = []
var _active_action_id: String = ""
var _active_unit_id: String = ""
var _active_status_label: String = ""
var _remaining_time: float = 0.0


func register_offer(config: Dictionary) -> void:
	var action_id: String = str(config.get("action_id", ""))
	var unit_id: String = str(config.get("unit_id", ""))
	if action_id.is_empty() or unit_id.is_empty():
		return

	_offers[action_id] = {
		"action_id": action_id,
		"unit_id": unit_id,
		"verb": str(config.get("verb", "Produce")),
		"status_label": str(config.get("status_label", "Producing")),
		"build_time": float(config.get("build_time", 0.0)),
	}
	if not _offer_order.has(action_id):
		_offer_order.append(action_id)


func clear_offers() -> void:
	_offers.clear()
	_offer_order.clear()
	_active_action_id = ""
	_active_unit_id = ""
	_active_status_label = ""
	_remaining_time = 0.0


func get_selection_actions(action_context: String, economy: MissionEconomy, blocked: bool) -> Array[Dictionary]:
	if action_context != "root" or economy == null or blocked:
		return []

	var actions: Array[Dictionary] = []
	for action_id: String in _offer_order:
		var offer: Dictionary = _offers.get(action_id, {})
		var unit_id: String = str(offer.get("unit_id", ""))
		actions.append({
			"id": action_id,
			"label": "%s %s (%s)" % [
				str(offer.get("verb", "Produce")),
				economy.get_unit_label(unit_id),
				economy.format_cost(economy.get_unit_cost(unit_id)),
			],
			"kind": "command",
			"disabled": is_producing(),
		})

	return actions


func perform_action(action_id: String, economy: MissionEconomy) -> Dictionary:
	if economy == null:
		return {"success": false, "message": "Economy system unavailable."}
	if not _offers.has(action_id):
		return {"success": false, "message": "That structure action is unavailable."}
	if is_producing():
		return {"success": false, "message": "Production already in progress."}

	var building: Node3D = get_parent() as Node3D
	if building == null:
		return {"success": false, "message": "Production source unavailable."}

	var offer: Dictionary = _offers[action_id]
	var unit_id: String = str(offer.get("unit_id", ""))
	var begin_result: Dictionary = economy.begin_unit_production(unit_id, building)
	if not begin_result.get("success", false):
		return begin_result

	_active_action_id = action_id
	_active_unit_id = unit_id
	_active_status_label = str(offer.get("status_label", "Producing"))
	_remaining_time = maxf(float(offer.get("build_time", 0.0)), economy.get_unit_build_time(unit_id))

	return {
		"success": true,
		"message": "%s %s." % [str(offer.get("verb", "Producing")), economy.get_unit_label(unit_id)],
	}


func get_current_action_label(fallback: String = "Online") -> String:
	if is_producing():
		return "%s %s" % [_active_status_label, _get_unit_label(_active_unit_id)]
	return fallback


func is_producing() -> bool:
	return not _active_unit_id.is_empty()


func process_production(delta: float) -> void:
	if not is_producing():
		return

	var building: Node3D = get_parent() as Node3D
	if building == null or not is_instance_valid(building):
		_clear_active_production()
		return

	var economy: MissionEconomy = building.get_tree().get_first_node_in_group("mission_economy") as MissionEconomy
	if economy == null:
		return

	_remaining_time = maxf(0.0, _remaining_time - delta)
	if _remaining_time > 0.0:
		return
	
	print("producing")
	economy.complete_unit_production(_active_unit_id, building, _get_spawn_position(economy, building))
	_clear_active_production()


func _get_spawn_position(economy: MissionEconomy, building: Node3D) -> Vector3:
	var anchor: Node3D = get_node_or_null(spawn_anchor_path) as Node3D
	if anchor != null:
		return anchor.global_position
	return building.global_position


func _clear_active_production() -> void:
	_active_action_id = ""
	_active_unit_id = ""
	_active_status_label = ""
	_remaining_time = 0.0


func _get_unit_label(unit_id: String) -> String:
	var building: Node3D = get_parent() as Node3D
	if building == null:
		return "Unit"

	var economy: MissionEconomy = building.get_tree().get_first_node_in_group("mission_economy") as MissionEconomy
	if economy == null:
		return "Unit"
	return economy.get_unit_label(unit_id)
