extends Node
class_name MovementComponent

@export var speed: float = 4.0


func move_towards(actor: Node3D, target: Vector3, delta: float) -> void:
	var direction := (target - actor.global_position)
	var distance: float = direction.length()
	if distance <= 0.05:
		return

	var step_distance: float = minf(speed * delta, distance)
	actor.global_position += direction.normalized() * step_distance
