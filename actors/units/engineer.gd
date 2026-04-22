extends Node3D

signal deployed(hq: Node3D)

@export var hq_scene: PackedScene
@export var deploy_delay: float = 1.2

var _deployed := false


func _ready() -> void:
	var timer := get_tree().create_timer(deploy_delay)
	timer.timeout.connect(_deploy_into_hq)


func _deploy_into_hq() -> void:
	if _deployed or hq_scene == null:
		return

	_deployed = true
	var hq_instance := hq_scene.instantiate() as Node3D
	if hq_instance == null:
		return

	hq_instance.global_transform = global_transform
	get_parent().add_child(hq_instance)
	deployed.emit(hq_instance)
	queue_free()
