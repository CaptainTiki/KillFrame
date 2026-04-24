extends BaseAction
class_name MoveAction

var _has_target: bool = false
var _target: Vector3 = Vector3.ZERO
var _path_points: Array[Vector3] = []
var _path_index: int = -1


func get_action_id() -> String:
	return "move"


func issue(payload: Dictionary = {}) -> void:
	clear()

	var path_points_variant: Variant = payload.get("path_points", null)
	if path_points_variant is Array:
		for point_variant: Variant in path_points_variant:
			if point_variant is Vector3:
				_path_points.append(point_variant as Vector3)

	if _path_points.size() > 1:
		_path_index = 1
		_target = _path_points[_path_index]
		_has_target = true
		return
	elif _path_points.size() == 1:
		_path_index = 0
		_target = _path_points[0]
		_has_target = true
		return

	if not payload.has("target"):
		return

	_target = payload["target"]
	_has_target = true


func clear() -> void:
	_has_target = false
	_target = Vector3.ZERO
	_path_points.clear()
	_path_index = -1


func process(delta: float) -> bool:
	if not _has_target:
		return false

	if unit_actions.move_actor_towards(_target, delta):
		if _path_index >= 0 and _path_index < _path_points.size() - 1:
			_path_index += 1
			_target = _path_points[_path_index]
			return true

		_has_target = false

	return _has_target


func get_status_label() -> String:
	if _has_target and unit_actions.is_action_current(get_action_id()):
		return "Moving"
	return ""


func get_status_priority() -> int:
	return 100
