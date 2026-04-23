extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/StartMissionButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/TestMapButton.pressed.connect(_on_test_map_pressed)
	$CenterContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://world/missions/mission01.tscn")


func _on_test_map_pressed() -> void:
	get_tree().change_scene_to_file("res://world/levels/test_level/test_level.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
