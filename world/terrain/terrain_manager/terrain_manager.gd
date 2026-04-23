@tool
extends Node3D
class_name TerrainManager

const TERRAIN_MESH_LIBRARY: MeshLibrary = preload("res://world/terrain/terrain_meshes/terrain_mesh_library.tres")
const TERRAIN_CELL_SIZE: Vector3 = Vector3.ONE

@onready var gm_terrain: GridMap = $GM_Terrain as GridMap

var map_width: int = 0
var map_height: int = 0
var map_origin: Vector2i = Vector2i.ZERO
var _height_by_cell: Dictionary = {}


func _ready() -> void:
	_configure_terrain_gridmap()
	if Engine.is_editor_hint():
		return
	refresh_from_gridmap()


func refresh_from_gridmap() -> void:
	_height_by_cell.clear()
	map_width = 0
	map_height = 0
	map_origin = Vector2i.ZERO

	if gm_terrain == null:
		return

	var used_cells: Array[Vector3i] = gm_terrain.get_used_cells()
	if used_cells.is_empty():
		return

	var min_x: int = used_cells[0].x
	var max_x: int = used_cells[0].x
	var min_z: int = used_cells[0].z
	var max_z: int = used_cells[0].z

	for used_cell: Vector3i in used_cells:
		var cell_key: Vector2i = Vector2i(used_cell.x, used_cell.z)
		if not _height_by_cell.has(cell_key) or used_cell.y > int(_height_by_cell[cell_key]):
			_height_by_cell[cell_key] = used_cell.y

		min_x = mini(min_x, used_cell.x)
		max_x = maxi(max_x, used_cell.x)
		min_z = mini(min_z, used_cell.z)
		max_z = maxi(max_z, used_cell.z)

	map_origin = Vector2i(min_x, min_z)
	map_width = max_x - min_x + 1
	map_height = max_z - min_z + 1


func has_terrain_cell(x: int, z: int) -> bool:
	return _height_by_cell.has(Vector2i(x, z))


func has_terrain_bounds() -> bool:
	return map_width > 0 and map_height > 0


func get_min_cell_coords() -> Vector2i:
	return map_origin


func get_max_cell_coords() -> Vector2i:
	if not has_terrain_bounds():
		return map_origin
	return map_origin + Vector2i(map_width - 1, map_height - 1)


func get_world_bounds_2d() -> Dictionary:
	if not has_terrain_bounds():
		return {"valid": false}

	var min_cell: Vector2i = get_min_cell_coords()
	var max_cell: Vector2i = get_max_cell_coords()
	var min_world: Vector3 = get_cell_surface_world_position(min_cell.x, min_cell.y, 0.0)
	var max_world: Vector3 = get_cell_surface_world_position(max_cell.x, max_cell.y, 0.0)
	var min_bounds: Vector2 = Vector2(
		minf(min_world.x, max_world.x),
		minf(min_world.z, max_world.z)
	)
	var max_bounds: Vector2 = Vector2(
		maxf(min_world.x, max_world.x),
		maxf(min_world.z, max_world.z)
	)

	return {
		"valid": true,
		"min": min_bounds,
		"max": max_bounds,
		"center": (min_bounds + max_bounds) * 0.5,
	}


func is_cell_walkable(x: int, z: int) -> bool:
	return has_terrain_cell(x, z)


func is_cell_buildable(x: int, z: int) -> bool:
	return has_terrain_cell(x, z)


func get_cell_coords_from_world(world_position: Vector3) -> Vector2i:
	if gm_terrain == null:
		return Vector2i.ZERO
	var local_position: Vector3 = gm_terrain.to_local(world_position)
	var map_position: Vector3i = gm_terrain.local_to_map(local_position)
	return Vector2i(map_position.x, map_position.z)


func get_cell_surface_world_position(x: int, z: int, y_offset: float = 0.0) -> Vector3:
	if gm_terrain == null:
		return global_position

	var height_level: int = get_cell_height(x, z)
	var local_position: Vector3 = gm_terrain.map_to_local(Vector3i(x, height_level, z))
	return gm_terrain.to_global(local_position + Vector3(0.0, y_offset, 0.0))


func get_cell_display_world_position(x: int, z: int, y_offset: float = 0.06) -> Vector3:
	return get_cell_surface_world_position(x, z, y_offset)


func get_cell_height(x: int, z: int) -> int:
	return int(_height_by_cell.get(Vector2i(x, z), 0))


func get_cell_debug_info(x: int, z: int) -> Dictionary:
	var valid: bool = has_terrain_cell(x, z)
	return {
		"valid": valid,
		"x": x,
		"z": z,
		"height_level": get_cell_height(x, z),
		"walkable": valid,
		"buildable": valid,
		"world_position": get_cell_display_world_position(x, z, 0.06),
	}


func get_map_summary() -> Dictionary:
	return {
		"width": map_width,
		"height": map_height,
		"total_cells": _height_by_cell.size(),
		"walkable_cells": _height_by_cell.size(),
		"buildable_cells": _height_by_cell.size(),
		"max_height_level": _get_max_height_level(),
	}


func get_render_summary() -> Dictionary:
	return {
		"terrain_cells": gm_terrain.get_used_cells().size() if gm_terrain != null else 0,
	}


func _get_max_height_level() -> int:
	var max_height_level: int = 0
	for height_variant: Variant in _height_by_cell.values():
		max_height_level = maxi(max_height_level, int(height_variant))
	return max_height_level


func _configure_terrain_gridmap() -> void:
	if gm_terrain == null:
		return
	gm_terrain.mesh_library = TERRAIN_MESH_LIBRARY
	gm_terrain.cell_size = TERRAIN_CELL_SIZE
	gm_terrain.bake_navigation = false
