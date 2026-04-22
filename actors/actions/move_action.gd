extends BaseAction
class_name MoveAction

var _has_target: bool = false
var _target: Vector3 = Vector3.ZERO


func get_action_id() -> String:
	return "move"


func issue(payload: Dictionary = {}) -> void:
	if not payload.has("target"):
		return

	_target = payload["target"]
	_has_target = true


func clear() -> void:
	_has_target = false
	_target = Vector3.ZERO


func process(delta: float) -> bool:
	if not _has_target:
		return false

	if unit_actions.move_actor_towards(_target, delta):
		_has_target = false

	return _has_target


func get_status_label() -> String:
	if _has_target and unit_actions.is_action_current(get_action_id()):
		return "Moving"
	return ""


func get_status_priority() -> int:
	return 100
