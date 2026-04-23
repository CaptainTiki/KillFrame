extends Node3D

const TerrainDebugMarkerScene = preload("res://world/terrain/terrain_debug/terrain_debug_marker.tscn")
const TerrainDebugMarkerScript = preload("res://world/terrain/terrain_debug/terrain_debug_marker.gd")


func show_path(world_points: Array[Vector3]) -> void:
	clear_path()

	if world_points.is_empty():
		return

	for index: int in range(world_points.size()):
		var marker: TerrainDebugMarkerScript = TerrainDebugMarkerScene.instantiate() as TerrainDebugMarkerScript
		add_child(marker)

		var marker_color: Color = Color(0.22, 0.92, 0.42, 0.45)
		if index == 0:
			marker_color = Color(0.22, 0.72, 1.0, 0.55)
		elif index == world_points.size() - 1:
			marker_color = Color(1.0, 0.28, 0.78, 0.55)

		marker.configure_marker(
			marker_color,
			Vector3(0.38, 0.05, 0.38),
			world_points[index] + Vector3(0.0, 0.12, 0.0)
		)


func clear_path() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func get_path_marker_count() -> int:
	return get_child_count()
