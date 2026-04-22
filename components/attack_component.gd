extends Node
class_name AttackComponent

@export var damage: float = 8.0
@export var attack_interval: float = 0.6

var _cooldown_left: float = 0.0


func _process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)


func try_attack(target_health: HealthComponent) -> bool:
	if _cooldown_left > 0.0 or target_health == null:
		return false

	target_health.apply_damage(damage)
	_cooldown_left = attack_interval
	return true
