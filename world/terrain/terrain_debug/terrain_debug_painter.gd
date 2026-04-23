extends RefCounted


func clear_debug_nodes(_debug_root: Node3D) -> void:
	# Future terrain paint/debug passes can use this to clean temporary preview
	# geometry that should not persist in the main terrain GridMaps.
	for child: Node in _debug_root.get_children():
		if child.is_in_group("terrain_debug_preview"):
			child.queue_free()


func get_editable_cell(_map_data: RefCounted, x: int, z: int):
	# PASS 4+ can route editor-style paint operations through this helper.
	if _map_data == null or not _map_data.in_bounds(x, z):
		return null

	return _map_data.get_cell(x, z)


func preview_height_brush_stub(_debug_root: Node3D, _x: int, _z: int, _height_delta: int) -> void:
	# PASS 4+ hook: preview a height edit before committing it into TerrainMapData.
	push_warning("TerrainDebugPainter.preview_height_brush_stub() is reserved for a later painting pass.")


func preview_flag_brush_stub(_debug_root: Node3D, _x: int, _z: int, _walkable: bool, _buildable: bool) -> void:
	# PASS 4+ hook: preview metadata edits without changing the authoritative data yet.
	push_warning("TerrainDebugPainter.preview_flag_brush_stub() is reserved for a later painting pass.")
