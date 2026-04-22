extends BaseAction
class_name ConstructAction

var build_repair_rate: float = 2.0
var stop_distance: float = 0.08

var _target: Node3D = null


func configure(config: Dictionary = {}) -> void:
	build_repair_rate = float(config.get("build_repair_rate", build_repair_rate))
	stop_distance = float(config.get("stop_distance", stop_distance))


func get_action_id() -> String:
	return "construct"


func issue(payload: Dictionary = {}) -> void:
	_target = payload.get("target", null) as Node3D


func clear() -> void:
	_target = null


func process(delta: float) -> bool:
	if _target == null or not is_instance_valid(_target):
		return false

	var construction_health: HealthComponent = _target.get_node_or_null("HealthComponent") as HealthComponent
	if construction_health == null:
		_target = null
		return false

	var build_position: Vector3 = unit_actions.get_closest_position_outside_structure(_target)
	if not unit_actions.move_actor_towards(build_position, delta, stop_distance):
		return true

	construction_health.repair(build_repair_rate * delta)
	if not construction_health.is_full_health():
		return true

	if _target.has_method("set_under_construction"):
		_target.call("set_under_construction", false)

	var economy: MissionEconomy = unit_actions.get_economy()
	if economy != null:
		economy.notify_structure_constructed(_target)

	_target = null
	return false


func get_status_label() -> String:
	if _target != null and is_instance_valid(_target) and unit_actions.is_action_current(get_action_id()):
		return "Constructing %s" % unit_actions.get_target_label(_target)
	return ""


func get_status_priority() -> int:
	return 350
