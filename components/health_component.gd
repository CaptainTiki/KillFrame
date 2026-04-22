extends Node
class_name HealthComponent

signal died
signal damaged(amount: float)
signal repaired(amount: float)
signal health_changed(current_health: float, max_health: float)

@export var max_health: float = 100.0
var current_health: float = -1.0


func _ready() -> void:
	if current_health < 0.0:
		current_health = max_health
	else:
		current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)


func apply_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()
		if get_parent() != null:
			get_parent().queue_free()


func repair(amount: float) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0

	var new_health: float = clampf(current_health + amount, 0.0, max_health)
	var repaired_amount: float = new_health - current_health
	if repaired_amount <= 0.0:
		return 0.0

	current_health = new_health
	repaired.emit(repaired_amount)
	health_changed.emit(current_health, max_health)
	return repaired_amount


func is_full_health() -> bool:
	return current_health >= max_health


func set_current_health(value: float) -> void:
	current_health = clampf(value, 0.0, max_health)
	health_changed.emit(current_health, max_health)
