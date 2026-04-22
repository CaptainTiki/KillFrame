extends RefCounted
class_name BaseAction

var actor: Node3D = null
var unit_actions: UnitActionsComponent = null


func setup(actor_ref: Node3D, unit_actions_ref: UnitActionsComponent) -> void:
	actor = actor_ref
	unit_actions = unit_actions_ref


func get_action_id() -> String:
	return ""


func issue(_payload: Dictionary = {}) -> void:
	pass


func interrupt(_next_action_id: String) -> void:
	clear()


func clear() -> void:
	pass


func process(_delta: float) -> bool:
	return false


func process_overlay(_delta: float) -> void:
	pass


func get_status_label() -> String:
	return ""


func get_status_priority() -> int:
	return 0
