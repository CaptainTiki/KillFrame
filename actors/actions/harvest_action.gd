extends BaseAction
class_name HarvestAction

var harvest_amount: int = 10
var harvest_interval: float = 0.75
var harvest_range: float = 1.2
var dropoff_range: float = 1.8

var _target: ResourceNode = null
var _cooldown_left: float = 0.0
var _carried_amount: int = 0
var _carried_resource_type: String = ""


func configure(config: Dictionary = {}) -> void:
	harvest_amount = int(config.get("harvest_amount", harvest_amount))
	harvest_interval = float(config.get("harvest_interval", harvest_interval))
	harvest_range = float(config.get("harvest_range", harvest_range))
	dropoff_range = float(config.get("dropoff_range", dropoff_range))


func get_action_id() -> String:
	return "harvest"


func issue(payload: Dictionary = {}) -> void:
	var target: ResourceNode = payload.get("target", null) as ResourceNode
	if target == null:
		return

	_target = target


func interrupt(_next_action_id: String) -> void:
	_target = null


func clear() -> void:
	_target = null
	_cooldown_left = 0.0
	_carried_amount = 0
	_carried_resource_type = ""


func process(delta: float) -> bool:
	var economy: MissionEconomy = unit_actions.get_economy()
	if economy == null:
		return false

	if _carried_amount > 0:
		var dropoff_target: Variant = economy.get_primary_dropoff_position()
		if dropoff_target == null:
			return true

		var dropoff_position: Vector3 = dropoff_target as Vector3
		if unit_actions.move_actor_towards(dropoff_position, delta, dropoff_range):
			economy.add_resource(_carried_resource_type, _carried_amount)
			_carried_amount = 0
			_carried_resource_type = ""

		return _target != null or _carried_amount > 0

	if _target == null or not is_instance_valid(_target):
		return false

	if not unit_actions.move_actor_towards(_target.global_position, delta, harvest_range):
		return true

	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	if _cooldown_left > 0.0:
		return true

	var harvested_amount: int = _target.harvest(harvest_amount)
	if harvested_amount <= 0:
		_target = null
		return false

	_carried_amount = harvested_amount
	_carried_resource_type = _target.resource_type
	_cooldown_left = harvest_interval
	return true


func get_status_label() -> String:
	if not unit_actions.is_action_current(get_action_id()):
		return ""

	if _carried_amount > 0:
		return "Returning %s" % _format_resource_type(_carried_resource_type)
	if _target != null and is_instance_valid(_target):
		return "Harvesting %s" % _format_resource_type(_target.resource_type)
	return ""


func get_status_priority() -> int:
	return 250


func _format_resource_type(resource_type: String) -> String:
	match resource_type:
		"crystals":
			return "Crystals"
		"bits":
			return "Bits"
		_:
			return resource_type.capitalize()
