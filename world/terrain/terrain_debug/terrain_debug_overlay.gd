extends Node3D

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")
const TerrainDebugMarkerScene = preload("res://world/terrain/terrain_debug/terrain_debug_marker.tscn")
const TerrainDebugMarkerScript = preload("res://world/terrain/terrain_debug/terrain_debug_marker.gd")

enum OverlayMode {
	WALKABLE,
	BUILDABLE,
	COMBINED,
}

var overlay_mode: int = OverlayMode.COMBINED
var _overlay_visible: bool = false


func build_overlay(map_data: TerrainMapData, surface_gridmap: GridMap) -> void:
	clear_overlay()

	if map_data == null or surface_gridmap == null:
		return

	# PASS 3 keeps the overlay readable by only marking cells whose metadata
	# differs from the common "walkable + buildable" default.
	for z: int in range(map_data.height):
		for x: int in range(map_data.width):
			var cell = map_data.get_cell(x, z)
			if cell == null:
				continue

			var marker_color: Color = _get_overlay_color(cell)
			if marker_color.a <= 0.0:
				continue

			var marker: TerrainDebugMarkerScript = TerrainDebugMarkerScene.instantiate() as TerrainDebugMarkerScript
			add_child(marker)
			var world_position: Vector3 = surface_gridmap.to_global(
				surface_gridmap.map_to_local(Vector3i(x, cell.height_level, z))
			)
			marker.configure_marker(
				marker_color,
				Vector3(0.72, 0.03, 0.72),
				world_position + Vector3(0.0, TerrainDefs.HEIGHT_STEP_METERS * 0.5 + 0.03, 0.0)
			)
			marker.set_marker_enabled(_overlay_visible)


func clear_overlay() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func set_overlay_visible(enabled: bool) -> void:
	_overlay_visible = enabled
	for child: Node in get_children():
		var marker: MeshInstance3D = child as MeshInstance3D
		if marker != null:
			marker.visible = enabled


func get_marker_count() -> int:
	return get_child_count()


func _get_overlay_color(cell) -> Color:
	match overlay_mode:
		OverlayMode.WALKABLE:
			return Color(1.0, 0.25, 0.2, 0.60) if not cell.walkable else Color(0.0, 0.0, 0.0, 0.0)
		OverlayMode.BUILDABLE:
			return Color(0.95, 0.82, 0.18, 0.60) if not cell.buildable else Color(0.0, 0.0, 0.0, 0.0)
		_:
			if not cell.walkable:
				return Color(1.0, 0.25, 0.2, 0.60)
			if not cell.buildable:
				return Color(0.95, 0.82, 0.18, 0.60)
			return Color(0.0, 0.0, 0.0, 0.0)
