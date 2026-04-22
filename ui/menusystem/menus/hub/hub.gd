extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/StartMissionButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://world/missions/mission01.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
