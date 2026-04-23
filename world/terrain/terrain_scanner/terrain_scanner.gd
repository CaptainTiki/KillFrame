extends RefCounted

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")

const ITEM_GROUND_FLAT: int = 0
const ITEM_GROUND_FLAT_VAR_A: int = 1
const ITEM_GROUND_FLAT_VAR_B: int = 2
const ITEM_CLIFF_LIP_STRAIGHT: int = 3
const ITEM_CLIFF_LIP_OUTER_CORNER: int = 4
const ITEM_CLIFF_LIP_INNER_CORNER: int = 5
const ITEM_CLIFF_WALL_STRAIGHT: int = 6
const ITEM_CLIFF_WALL_OUTER_CORNER: int = 7
const ITEM_CLIFF_WALL_INNER_CORNER: int = 8
const ITEM_RAMP_UP: int = 9
const ITEM_BLOCKER_ROCK: int = 13
const ITEM_BLOCKER_WRECK: int = 14
const ITEM_BLOCKER_LARGE: int = 15


# ── Single-GridMap scan (primary path for the simplified terrain system) ──────

func scan_from_single_gridmap(gm: GridMap) -> TerrainMapData:
	if gm == null or gm.get_used_cells().is_empty():
		return null

	var bounds: Dictionary = _build_bounds([gm])
	if not bool(bounds.get("has_cells", false)):
		return null

	var map_width: int = int(bounds["max_x"]) - int(bounds["min_x"]) + 1
	var map_height: int = int(bounds["max_z"]) - int(bounds["min_z"]) + 1
	var map_data: TerrainMapData = TerrainMapData.new(map_width, map_height)
	map_data.set_origin(int(bounds["min_x"]), int(bounds["min_z"]))
	_initialize_empty_cells(map_data)

	_scan_single_layer(map_data, gm)
	_finalize_cell_flags(map_data)

	return map_data


func _scan_single_layer(map_data: TerrainMapData, gm: GridMap) -> void:
	for used_cell_variant: Variant in gm.get_used_cells():
		var used_cell: Vector3i = used_cell_variant as Vector3i
		var cell_coords: Vector2i = _to_local_cell_coords(map_data, used_cell)
		var terrain_cell: Variant = map_data.get_cell(cell_coords.x, cell_coords.y)
		if terrain_cell == null:
			continue

		var item_id: int = gm.get_cell_item(used_cell)

		if _is_ground_item(item_id):
			if terrain_cell.walkable and used_cell.y < terrain_cell.height_level:
				continue
			var surface_type: int = _surface_type_from_item(used_cell.y, item_id)
			terrain_cell.height_level = used_cell.y
			terrain_cell.walkable = true
			terrain_cell.buildable = _is_surface_buildable(surface_type)
			terrain_cell.surface_type = surface_type
			terrain_cell.ramp_dir = TerrainDefs.INVALID_RAMP_DIR

		elif item_id == ITEM_RAMP_UP:
			if used_cell.y < terrain_cell.height_level:
				continue
			terrain_cell.height_level = used_cell.y
			terrain_cell.walkable = true
			terrain_cell.buildable = false
			terrain_cell.ramp_dir = _ramp_dir_from_orientation(
				gm, gm.get_cell_item_orientation(used_cell)
			)

		elif _is_blocker_item(item_id):
			terrain_cell.height_level = max(terrain_cell.height_level, used_cell.y)
			terrain_cell.blocker_type = _blocker_type_from_item(item_id)
			terrain_cell.walkable = false
			terrain_cell.buildable = false

		# Cliff items (3–8) and ramp caps/fillers (10–12) are visual only — no game logic.


func _is_ground_item(item_id: int) -> bool:
	return item_id == ITEM_GROUND_FLAT or item_id == ITEM_GROUND_FLAT_VAR_A or item_id == ITEM_GROUND_FLAT_VAR_B

# Authored terrain conventions:
# - Terrain is authored directly into GridMaps inside a level scene.
# - GridMap cell Y == TerrainCell.height_level.
# - One height_level maps to TerrainDefs.HEIGHT_STEP_METERS in world space.
# - GM_Surface / GM_Ramps define traversable floor cells.
# - GM_Blockers overrides cells to non-walkable / non-buildable.
# - GM_Cliffs is primarily a visual support layer; it expands bounds and keeps
#   cliff-only cells non-traversable without trying to infer mesh geometry.
func scan_from_gridmaps(
	surface_gm: GridMap,
	cliffs_gm: GridMap,
	ramps_gm: GridMap,
	blockers_gm: GridMap
) -> TerrainMapData:
	var bounds: Dictionary = _build_bounds([surface_gm, cliffs_gm, ramps_gm, blockers_gm])
	if not bool(bounds.get("has_cells", false)):
		return null

	var map_width: int = int(bounds["max_x"]) - int(bounds["min_x"]) + 1
	var map_height: int = int(bounds["max_z"]) - int(bounds["min_z"]) + 1
	var map_data: TerrainMapData = TerrainMapData.new(map_width, map_height)
	map_data.set_origin(int(bounds["min_x"]), int(bounds["min_z"]))
	_initialize_empty_cells(map_data)

	_scan_surface_layer(map_data, surface_gm)
	_scan_ramp_layer(map_data, ramps_gm)
	_scan_blocker_layer(map_data, blockers_gm)
	_scan_cliff_layer(map_data, cliffs_gm)
	_finalize_cell_flags(map_data)

	return map_data


func _build_bounds(gridmaps: Array) -> Dictionary:
	var has_cells: bool = false
	var min_x: int = 0
	var max_x: int = 0
	var min_z: int = 0
	var max_z: int = 0

	for gridmap_variant: Variant in gridmaps:
		var gridmap: GridMap = gridmap_variant as GridMap
		if gridmap == null:
			continue

		for used_cell_variant: Variant in gridmap.get_used_cells():
			var used_cell: Vector3i = used_cell_variant as Vector3i
			if not has_cells:
				has_cells = true
				min_x = used_cell.x
				max_x = used_cell.x
				min_z = used_cell.z
				max_z = used_cell.z
				continue

			min_x = min(min_x, used_cell.x)
			max_x = max(max_x, used_cell.x)
			min_z = min(min_z, used_cell.z)
			max_z = max(max_z, used_cell.z)

	return {
		"has_cells": has_cells,
		"min_x": min_x,
		"max_x": max_x,
		"min_z": min_z,
		"max_z": max_z,
	}


func _initialize_empty_cells(map_data: TerrainMapData) -> void:
	for cell_variant: Variant in map_data.cells:
		var cell = cell_variant
		if cell == null:
			continue

		cell.height_level = 0
		cell.walkable = false
		cell.buildable = false
		cell.ramp_dir = TerrainDefs.INVALID_RAMP_DIR
		cell.blocker_type = TerrainDefs.BlockerType.NONE
		cell.surface_type = TerrainDefs.SurfaceType.DIRT


func _scan_surface_layer(map_data: TerrainMapData, surface_gm: GridMap) -> void:
	if surface_gm == null:
		return

	for used_cell_variant: Variant in surface_gm.get_used_cells():
		var used_cell: Vector3i = used_cell_variant as Vector3i
		var cell_coords: Vector2i = _to_local_cell_coords(map_data, used_cell)
		var terrain_cell = map_data.get_cell(cell_coords.x, cell_coords.y)
		if terrain_cell == null:
			continue
		if terrain_cell.walkable and used_cell.y < terrain_cell.height_level:
			continue

		var surface_type: int = _surface_type_from_item(used_cell.y, surface_gm.get_cell_item(used_cell))
		terrain_cell.height_level = used_cell.y
		terrain_cell.walkable = true
		terrain_cell.buildable = _is_surface_buildable(surface_type)
		terrain_cell.surface_type = surface_type
		terrain_cell.ramp_dir = TerrainDefs.INVALID_RAMP_DIR


func _scan_ramp_layer(map_data: TerrainMapData, ramps_gm: GridMap) -> void:
	if ramps_gm == null:
		return

	for used_cell_variant: Variant in ramps_gm.get_used_cells():
		var used_cell: Vector3i = used_cell_variant as Vector3i
		var cell_coords: Vector2i = _to_local_cell_coords(map_data, used_cell)
		var terrain_cell = map_data.get_cell(cell_coords.x, cell_coords.y)
		if terrain_cell == null:
			continue
		if used_cell.y < terrain_cell.height_level:
			continue

		terrain_cell.height_level = used_cell.y
		terrain_cell.walkable = true
		terrain_cell.buildable = false
		terrain_cell.ramp_dir = _ramp_dir_from_orientation(
			ramps_gm,
			ramps_gm.get_cell_item_orientation(used_cell)
		)


func _scan_blocker_layer(map_data: TerrainMapData, blockers_gm: GridMap) -> void:
	if blockers_gm == null:
		return

	for used_cell_variant: Variant in blockers_gm.get_used_cells():
		var used_cell: Vector3i = used_cell_variant as Vector3i
		var cell_coords: Vector2i = _to_local_cell_coords(map_data, used_cell)
		var terrain_cell = map_data.get_cell(cell_coords.x, cell_coords.y)
		if terrain_cell == null:
			continue

		terrain_cell.height_level = max(terrain_cell.height_level, used_cell.y)
		terrain_cell.blocker_type = _blocker_type_from_item(blockers_gm.get_cell_item(used_cell))
		terrain_cell.walkable = false
		terrain_cell.buildable = false


func _scan_cliff_layer(map_data: TerrainMapData, cliffs_gm: GridMap) -> void:
	if cliffs_gm == null:
		return

	for used_cell_variant: Variant in cliffs_gm.get_used_cells():
		var used_cell: Vector3i = used_cell_variant as Vector3i
		var cell_coords: Vector2i = _to_local_cell_coords(map_data, used_cell)
		var terrain_cell = map_data.get_cell(cell_coords.x, cell_coords.y)
		if terrain_cell == null:
			continue

		terrain_cell.height_level = max(terrain_cell.height_level, used_cell.y)
		if terrain_cell.walkable:
			continue

		var cliff_item_id: int = cliffs_gm.get_cell_item(used_cell)
		if _is_cliff_item(cliff_item_id):
			terrain_cell.walkable = false
			terrain_cell.buildable = false


func _finalize_cell_flags(map_data: TerrainMapData) -> void:
	for cell_variant: Variant in map_data.cells:
		var terrain_cell = cell_variant
		if terrain_cell == null:
			continue

		if terrain_cell.blocker_type != TerrainDefs.BlockerType.NONE:
			terrain_cell.walkable = false
			terrain_cell.buildable = false
			continue

		if terrain_cell.ramp_dir != TerrainDefs.INVALID_RAMP_DIR:
			terrain_cell.walkable = true
			terrain_cell.buildable = false
			continue

		if not terrain_cell.walkable:
			terrain_cell.buildable = false


func _to_local_cell_coords(map_data: TerrainMapData, used_cell: Vector3i) -> Vector2i:
	return Vector2i(used_cell.x - map_data.origin_x, used_cell.z - map_data.origin_z)


func _surface_type_from_item(height_level: int, item_id: int) -> int:
	match item_id:
		ITEM_GROUND_FLAT_VAR_A:
			return TerrainDefs.SurfaceType.PLATEAU_ROCK if height_level > 0 else TerrainDefs.SurfaceType.BASE_PAD
		ITEM_GROUND_FLAT_VAR_B:
			return TerrainDefs.SurfaceType.ROUGH_GROUND
		_:
			return TerrainDefs.SurfaceType.DIRT


func _is_surface_buildable(surface_type: int) -> bool:
	match surface_type:
		TerrainDefs.SurfaceType.ROUGH_GROUND, TerrainDefs.SurfaceType.PLATEAU_ROCK:
			return false
		_:
			return true


func _blocker_type_from_item(item_id: int) -> int:
	match item_id:
		ITEM_BLOCKER_WRECK:
			return TerrainDefs.BlockerType.DEBRIS
		ITEM_BLOCKER_LARGE:
			return TerrainDefs.BlockerType.STRUCTURE
		_:
			return TerrainDefs.BlockerType.ROCKS


func _is_cliff_item(item_id: int) -> bool:
	return item_id in [
		ITEM_CLIFF_LIP_STRAIGHT,
		ITEM_CLIFF_LIP_OUTER_CORNER,
		ITEM_CLIFF_LIP_INNER_CORNER,
		ITEM_CLIFF_WALL_STRAIGHT,
		ITEM_CLIFF_WALL_OUTER_CORNER,
		ITEM_CLIFF_WALL_INNER_CORNER,
	]


func _ramp_dir_from_orientation(gridmap: GridMap, orientation: int) -> int:
	var north_orientation: int = gridmap.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(180.0), 0.0))
	)
	var east_orientation: int = gridmap.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(-90.0), 0.0))
	)
	var south_orientation: int = gridmap.get_orthogonal_index_from_basis(Basis.IDENTITY)
	var west_orientation: int = gridmap.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(90.0), 0.0))
	)

	if orientation == north_orientation:
		return TerrainDefs.RampDirection.NORTH
	if orientation == east_orientation:
		return TerrainDefs.RampDirection.EAST
	if orientation == west_orientation:
		return TerrainDefs.RampDirection.WEST
	if orientation == south_orientation:
		return TerrainDefs.RampDirection.SOUTH

	return TerrainDefs.INVALID_RAMP_DIR
