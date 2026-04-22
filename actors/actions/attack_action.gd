extends BaseAction
class_name AttackAction

var attack_range: float = 4.0
var aggro_range: float = 8.0

var _target: Node3D = null
var _manual_target: bool = false


func configure(config: Dictionary = {}) -> void:
	attack_range = float(config.get("attack_range", attack_range))
	aggro_range = float(config.get("aggro_range", aggro_range))


func get_action_id() -> String:
	return "attack"


func issue(payload: Dictionary = {}) -> void:
	_target = payload.get("target", null) as Node3D
	_manual_target = _target != null


func clear() -> void:
	_target = null
	_manual_target = false


func process(delta: float) -> bool:
	if _target == null or not is_instance_valid(_target):
		_manual_target = false
		_target = _find_nearest_enemy_target()
		if _target == null:
			return false

	_handle_attack_target(delta)
	return _target != null and is_instance_valid(_target)


func process_overlay(delta: float) -> void:
	if unit_actions.is_action_current(get_action_id()):
		return

	if _target == null or not is_instance_valid(_target):
		_manual_target = false
		_target = _find_nearest_enemy_target()
		if _target == null:
			return

	_handle_attack_target(delta)


func get_status_label() -> String:
	if _target == null or not is_instance_valid(_target):
		return ""

	var target_label: String = unit_actions.get_target_label(_target)
	if actor.global_position.distance_to(_target.global_position) > attack_range:
		return "Advancing on %s" % target_label
	return "Attacking %s" % target_label


func get_status_priority() -> int:
	return 300


func _find_nearest_enemy_target() -> Node3D:
	if actor == null:
		return null

	var group_name: String = "enemy_targets" if unit_actions.get_team() == "player" else "player_targets"
	var nearest: Node3D = null
	var nearest_dist: float = INF

	for node: Node in actor.get_tree().get_nodes_in_group(group_name):
		if node is not Node3D:
			continue
		var candidate: Node3D = node as Node3D
		var distance_to_candidate: float = actor.global_position.distance_to(candidate.global_position)
		if distance_to_candidate <= aggro_range and distance_to_candidate < nearest_dist:
			nearest = candidate
			nearest_dist = distance_to_candidate

	return nearest


func _handle_attack_target(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	var target_health: HealthComponent = _target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health == null:
		_target = null
		_manual_target = false
		return

	var distance_to_target: float = actor.global_position.distance_to(_target.global_position)
	if distance_to_target > attack_range:
		unit_actions.move_actor_towards(_target.global_position, delta)
		return

	var attack_component: AttackComponent = actor.get_node_or_null("AttackComponent") as AttackComponent
	if attack_component != null:
		attack_component.try_attack(target_health)
