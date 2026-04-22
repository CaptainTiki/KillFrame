extends Node

@export var hub_scene_path: String = "res://ui/menusystem/menus/hub/hub.tscn"

var player_hq: Node3D
var hq_registered: bool = false
var mission_ended: bool = false


func register_player_hq(hq: Node3D) -> void:
	player_hq = hq
	hq_registered = true

	var health: HealthComponent = hq.get_node_or_null("HealthComponent") as HealthComponent
	if health != null and not health.died.is_connected(_on_player_hq_destroyed):
		health.died.connect(_on_player_hq_destroyed)

	_set_status("HQ online. Harvest resources, expand your base, and destroy the enemy core.")


func _ready() -> void:
	_set_status("Deploying engineer...")


func _process(_delta: float) -> void:
	if mission_ended:
		return

	# Do not evaluate loss state before the initial HQ exists.
	if not hq_registered:
		return

	if not is_instance_valid(player_hq):
		_on_player_hq_destroyed()
		return

	var enemy_core: Node = get_node_or_null("../EnemyCore")
	if enemy_core == null:
		_on_mission_won()


func _on_player_hq_destroyed() -> void:
	if mission_ended:
		return
	mission_ended = true
	_set_status("Mission failed. Main HQ destroyed. Returning to hub...")
	_return_to_hub()


func _on_mission_won() -> void:
	if mission_ended:
		return
	mission_ended = true
	_set_status("Mission complete. Enemy core destroyed. Returning to hub...")
	_return_to_hub()


func _set_status(text: String) -> void:
	var label: Label = get_node_or_null("../HUD/MarginContainer/VBoxContainer/StatusLabel") as Label
	if label == null:
		label = get_node_or_null("../UI/MarginContainer/VBoxContainer/StatusLabel") as Label
	if label != null:
		label.text = text


func _return_to_hub() -> void:
	if not is_inside_tree():
		return

	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var timer: SceneTreeTimer = tree.create_timer(2.0)
	timer.timeout.connect(Callable(tree, "change_scene_to_file").bind(hub_scene_path))
