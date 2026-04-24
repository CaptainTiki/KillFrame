@tool
extends Node3D
class_name TerrainManager

const TERRAIN_MESH_LIBRARY: MeshLibrary = preload("res://world/terrain/terrain_meshes/terrain_mesh_library.tres")
const LevelTerrainData = preload("res://world/terrain/terrain_data/level_terrain_data.gd")
const TerrainTileData = preload("res://world/terrain/terrain_data/terrain_tile_data.gd")
const TERRAIN_CELL_SIZE: Vector3 = Vector3.ONE
const DEFAULT_BAKED_DATA_SUFFIX: String = "_terrain_data.tres"

const TILE_KIND_FLOOR: String = "terrain_floor_cube_1x1x1"
const TILE_KIND_SLOPE_STRAIGHT: String = "terrain_slope_straight_1x1"
const TILE_KIND_SLOPE_OUTER_CORNER: String = "terrain_slope_outer_corner_1x1"
const TILE_KIND_SLOPE_INNER_CORNER: String = "terrain_slope_inner_corner_1x1"

const DIRECTION_INVALID: int = -1
const DIRECTION_NORTH: int = 0
const DIRECTION_EAST: int = 1
const DIRECTION_SOUTH: int = 2
const DIRECTION_WEST: int = 3

const EXIT_NORTH: int = TerrainTileData.ExitMask.NORTH
const EXIT_EAST: int = TerrainTileData.ExitMask.EAST
const EXIT_SOUTH: int = TerrainTileData.ExitMask.SOUTH
const EXIT_WEST: int = TerrainTileData.ExitMask.WEST
const EXIT_ALL: int = EXIT_NORTH | EXIT_EAST | EXIT_SOUTH | EXIT_WEST

@export_file("*.tres") var baked_terrain_data_path: String = ""
@export var baked_terrain_data: LevelTerrainData = null
@export_tool_button("Bake Terrain Data") var _bake_terrain_data_action: Callable = _editor_bake_terrain_data

@onready var gm_terrain: GridMap = $GM_Terrain as GridMap

var map_width: int = 0
var map_height: int = 0
var map_origin: Vector2i = Vector2i.ZERO
var _tile_by_cell: Dictionary = {}
var _path_astar: AStar2D = AStar2D.new()
var _path_point_id_by_cell: Dictionary = {}


func _ready() -> void:
	add_to_group("terrain_manager")
	_configure_terrain_gridmap()
	if Engine.is_editor_hint():
		return
	refresh_runtime_data()


func refresh_runtime_data() -> void:
	if refresh_from_baked_data():
		return
	refresh_from_gridmap()


func refresh_from_gridmap() -> void:
	_apply_terrain_data(_build_terrain_data_from_gridmap())


func refresh_from_baked_data() -> bool:
	var terrain_data: LevelTerrainData = _load_baked_terrain_data()
	if terrain_data == null or not terrain_data.is_valid():
		return false

	_apply_terrain_data(terrain_data)
	return true


func has_terrain_cell(x: int, z: int) -> bool:
	return _tile_by_cell.has(Vector2i(x, z))


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
	var tile: TerrainTileData = _get_tile(x, z)
	return tile != null and tile.walkable


func is_cell_buildable(x: int, z: int) -> bool:
	var tile: TerrainTileData = _get_tile(x, z)
	return tile != null and tile.buildable


func get_nearest_walkable_cell(x: int, z: int) -> Vector2i:
	return _resolve_walkable_cell(Vector2i(x, z))


func get_nearest_walkable_cell_from_world(world_position: Vector3) -> Vector2i:
	var requested_cell: Vector2i = get_cell_coords_from_world(world_position)
	return get_nearest_walkable_cell(requested_cell.x, requested_cell.y)


func request_path_world(start_world: Vector3, target_world: Vector3) -> Dictionary:
	var start_cell: Vector2i = get_cell_coords_from_world(start_world)
	var target_cell: Vector2i = get_cell_coords_from_world(target_world)
	var result: Dictionary = request_path_cells(start_cell, target_cell)
	if not result.get("success", false):
		return result

	var world_points: Array[Vector3] = []
	var cell_path: Array[Vector2i] = result.get("cell_path", [])
	for cell: Vector2i in cell_path:
		world_points.append(get_cell_surface_world_position(cell.x, cell.y, 0.0))

	result["world_points"] = world_points
	return result


func request_path_cells(start_cell: Vector2i, target_cell: Vector2i) -> Dictionary:
	if _path_point_id_by_cell.is_empty():
		return {
			"success": false,
			"reason": "No walkable terrain cells are available.",
			"start_cell": start_cell,
			"target_cell": target_cell,
			"cell_path": [],
		}

	var resolved_start: Vector2i = _resolve_walkable_cell(start_cell)
	var resolved_target: Vector2i = _resolve_walkable_cell(target_cell)
	if not _has_path_point(resolved_start) or not _has_path_point(resolved_target):
		return {
			"success": false,
			"reason": "Unable to resolve a walkable start or target cell.",
			"start_cell": resolved_start,
			"target_cell": resolved_target,
			"cell_path": [],
		}

	var start_id: int = _path_point_id_by_cell[resolved_start]
	var target_id: int = _path_point_id_by_cell[resolved_target]
	var id_path: PackedInt64Array = _path_astar.get_id_path(start_id, target_id)
	if id_path.is_empty():
		return {
			"success": false,
			"reason": "No terrain path exists between the requested cells.",
			"start_cell": resolved_start,
			"target_cell": resolved_target,
			"cell_path": [],
		}

	var cell_path: Array[Vector2i] = []
	for point_id: int in id_path:
		cell_path.append(_get_cell_from_path_point_id(point_id))

	return {
		"success": true,
		"reason": "",
		"start_cell": resolved_start,
		"target_cell": resolved_target,
		"cell_path": cell_path,
	}


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
	var tile: TerrainTileData = _get_tile(x, z)
	return tile.height if tile != null else 0


func get_cell_debug_info(x: int, z: int) -> Dictionary:
	var valid: bool = has_terrain_cell(x, z)
	var tile: TerrainTileData = _get_tile(x, z)
	return {
		"valid": valid,
		"x": x,
		"z": z,
		"height_level": get_cell_height(x, z),
		"walkable": tile.walkable if tile != null else false,
		"buildable": tile.buildable if tile != null else false,
		"exit_mask": tile.exit_mask if tile != null else 0,
		"tile_kind": tile.tile_kind if tile != null else "",
		"rotation_degrees": tile.rotation_degrees if tile != null else 0,
		"world_position": get_cell_display_world_position(x, z, 0.06),
	}


func get_map_summary() -> Dictionary:
	var walkable_cells: int = 0
	var buildable_cells: int = 0
	var max_height_level: int = 0

	for tile_variant: Variant in _tile_by_cell.values():
		var tile: TerrainTileData = tile_variant as TerrainTileData
		if tile == null:
			continue
		if tile.walkable:
			walkable_cells += 1
		if tile.buildable:
			buildable_cells += 1
		max_height_level = maxi(max_height_level, tile.height)

	return {
		"width": map_width,
		"height": map_height,
		"total_cells": _tile_by_cell.size(),
		"walkable_cells": walkable_cells,
		"buildable_cells": buildable_cells,
		"max_height_level": max_height_level,
	}


func get_render_summary() -> Dictionary:
	return {
		"terrain_cells": gm_terrain.get_used_cells().size() if gm_terrain != null else 0,
	}


func _editor_bake_terrain_data() -> void:
	if not Engine.is_editor_hint():
		return

	var terrain_data: LevelTerrainData = _build_terrain_data_from_gridmap()
	if terrain_data == null or not terrain_data.is_valid():
		push_warning("TerrainManager: GM_Terrain is empty. Nothing to bake.")
		return

	var save_path: String = _resolve_baked_terrain_data_path()
	if save_path.is_empty():
		push_warning("TerrainManager: Save the level scene before baking terrain data.")
		return

	var save_result: int = ResourceSaver.save(terrain_data, save_path)
	if save_result != OK:
		push_error("TerrainManager: Failed to bake terrain data to %s (error %d)." % [save_path, save_result])
		return

	baked_terrain_data_path = save_path
	baked_terrain_data = ResourceLoader.load(save_path) as LevelTerrainData
	_apply_terrain_data(baked_terrain_data)
	print("TerrainManager: Baked %d terrain cells to %s. Save the level scene to persist the resource reference." % [
		terrain_data.get_cell_count(),
		save_path,
	])


func _apply_terrain_data(terrain_data: LevelTerrainData) -> void:
	_tile_by_cell.clear()
	map_width = 0
	map_height = 0
	map_origin = Vector2i.ZERO

	if terrain_data == null or not terrain_data.is_valid():
		return

	map_origin = terrain_data.origin
	map_width = terrain_data.width
	map_height = terrain_data.height

	for cell_coords: Vector2i in terrain_data.get_used_cells():
		var tile: TerrainTileData = terrain_data.get_cell(cell_coords.x, cell_coords.y)
		if tile == null:
			continue
		_tile_by_cell[cell_coords] = tile

	_rebuild_path_graph()


func _build_terrain_data_from_gridmap() -> LevelTerrainData:
	var terrain_data: LevelTerrainData = LevelTerrainData.new()
	if gm_terrain == null:
		return terrain_data

	var used_cells: Array[Vector3i] = gm_terrain.get_used_cells()
	if used_cells.is_empty():
		return terrain_data

	var min_x: int = used_cells[0].x
	var max_x: int = used_cells[0].x
	var min_z: int = used_cells[0].z
	var max_z: int = used_cells[0].z
	var top_cell_by_coords: Dictionary = {}

	for used_cell: Vector3i in used_cells:
		var cell_coords: Vector2i = Vector2i(used_cell.x, used_cell.z)
		if not top_cell_by_coords.has(cell_coords):
			top_cell_by_coords[cell_coords] = used_cell
		else:
			var existing_top_cell: Vector3i = top_cell_by_coords[cell_coords]
			if used_cell.y > existing_top_cell.y:
				top_cell_by_coords[cell_coords] = used_cell

		min_x = mini(min_x, used_cell.x)
		max_x = maxi(max_x, used_cell.x)
		min_z = mini(min_z, used_cell.z)
		max_z = maxi(max_z, used_cell.z)

	terrain_data.origin = Vector2i(min_x, min_z)
	terrain_data.width = max_x - min_x + 1
	terrain_data.height = max_z - min_z + 1

	for cell_coords_variant: Variant in top_cell_by_coords.keys():
		var cell_coords: Vector2i = cell_coords_variant
		var top_cell: Vector3i = top_cell_by_coords[cell_coords]
		var tile: TerrainTileData = _build_tile_data_for_cell(top_cell)
		if tile == null:
			continue
		terrain_data.set_cell(cell_coords.x, cell_coords.y, tile)

	return terrain_data


func _build_tile_data_for_cell(map_cell: Vector3i) -> TerrainTileData:
	if gm_terrain == null:
		return null

	var item_id: int = gm_terrain.get_cell_item(map_cell)
	if item_id < 0:
		return null

	var tile_kind: String = _get_mesh_library_item_name(item_id)
	var rise_direction: int = _get_rise_direction_for_orientation(
		gm_terrain.get_cell_item_orientation(map_cell)
	)
	var tile: TerrainTileData = TerrainTileData.new()
	tile.height = map_cell.y
	tile.tile_kind = tile_kind
	tile.rotation_degrees = _get_rotation_degrees_for_direction(rise_direction)

	match tile_kind:
		TILE_KIND_FLOOR:
			tile.walkable = true
			tile.buildable = true
			tile.exit_mask = EXIT_ALL
		TILE_KIND_SLOPE_STRAIGHT:
			tile.walkable = true
			tile.buildable = false
			tile.exit_mask = _get_straight_slope_exit_mask(rise_direction)
		TILE_KIND_SLOPE_OUTER_CORNER, TILE_KIND_SLOPE_INNER_CORNER:
			tile.walkable = true
			tile.buildable = false
			# Corner pieces are intentionally permissive until pathfinding is wired in.
			tile.exit_mask = EXIT_ALL
		_:
			tile.walkable = true
			tile.buildable = true
			tile.exit_mask = EXIT_ALL

	return tile


func _load_baked_terrain_data() -> LevelTerrainData:
	if baked_terrain_data != null and baked_terrain_data.is_valid():
		return baked_terrain_data

	if baked_terrain_data_path.is_empty():
		return null
	if not ResourceLoader.exists(baked_terrain_data_path):
		return null

	var loaded_resource: Resource = ResourceLoader.load(baked_terrain_data_path)
	var terrain_data: LevelTerrainData = loaded_resource as LevelTerrainData
	if terrain_data == null or not terrain_data.is_valid():
		return null

	baked_terrain_data = terrain_data
	return terrain_data


func _resolve_baked_terrain_data_path() -> String:
	if not baked_terrain_data_path.is_empty():
		return baked_terrain_data_path
	if baked_terrain_data != null and not baked_terrain_data.resource_path.is_empty():
		return baked_terrain_data.resource_path

	var owning_scene_path: String = _get_owning_scene_path()
	if owning_scene_path.is_empty():
		return ""

	var scene_dir: String = owning_scene_path.get_base_dir()
	var scene_name: String = owning_scene_path.get_file().get_basename()
	return "%s/%s%s" % [scene_dir, scene_name, DEFAULT_BAKED_DATA_SUFFIX]


func _get_owning_scene_path() -> String:
	if not scene_file_path.is_empty():
		return scene_file_path

	if not is_inside_tree():
		return ""

	var edited_scene_root: Node = get_tree().edited_scene_root
	if edited_scene_root != null and (edited_scene_root == self or edited_scene_root.is_ancestor_of(self)):
		return edited_scene_root.scene_file_path

	return ""


func _get_tile(x: int, z: int) -> TerrainTileData:
	return _tile_by_cell.get(Vector2i(x, z), null) as TerrainTileData


func _rebuild_path_graph() -> void:
	_path_astar.clear()
	_path_point_id_by_cell.clear()

	var next_point_id: int = 1
	for cell_coords_variant: Variant in _tile_by_cell.keys():
		var cell_coords: Vector2i = cell_coords_variant
		var tile: TerrainTileData = _tile_by_cell[cell_coords] as TerrainTileData
		if tile == null or not tile.walkable:
			continue

		_path_astar.add_point(next_point_id, Vector2(cell_coords.x, cell_coords.y))
		_path_point_id_by_cell[cell_coords] = next_point_id
		next_point_id += 1

	for cell_coords_variant: Variant in _path_point_id_by_cell.keys():
		var cell_coords: Vector2i = cell_coords_variant
		_try_connect_cardinal_neighbor(cell_coords, DIRECTION_EAST)
		_try_connect_cardinal_neighbor(cell_coords, DIRECTION_SOUTH)
		_try_connect_diagonal_neighbor(cell_coords, DIRECTION_EAST, DIRECTION_SOUTH)
		_try_connect_diagonal_neighbor(cell_coords, DIRECTION_WEST, DIRECTION_SOUTH)


func _try_connect_cardinal_neighbor(from_cell: Vector2i, direction: int) -> void:
	var to_cell: Vector2i = from_cell + _get_direction_delta(direction)
	if not _has_path_point(to_cell):
		return
	if not _can_traverse_cardinal(from_cell, to_cell, direction):
		return

	_path_astar.connect_points(_path_point_id_by_cell[from_cell], _path_point_id_by_cell[to_cell], true)


func _try_connect_diagonal_neighbor(from_cell: Vector2i, horizontal_direction: int, vertical_direction: int) -> void:
	var to_cell: Vector2i = from_cell + _get_direction_delta(horizontal_direction) + _get_direction_delta(vertical_direction)
	if not _has_path_point(to_cell):
		return
	if not _can_traverse_diagonal(from_cell, to_cell, horizontal_direction, vertical_direction):
		return

	_path_astar.connect_points(_path_point_id_by_cell[from_cell], _path_point_id_by_cell[to_cell], true)


func _can_traverse_cardinal(from_cell: Vector2i, to_cell: Vector2i, direction: int) -> bool:
	var from_tile: TerrainTileData = _get_tile(from_cell.x, from_cell.y)
	var to_tile: TerrainTileData = _get_tile(to_cell.x, to_cell.y)
	if from_tile == null or to_tile == null:
		return false
	if not from_tile.walkable or not to_tile.walkable:
		return false
	if not _tile_has_exit_in_direction(from_tile, direction):
		return false

	var opposite_direction: int = _get_opposite_direction(direction)
	if not _tile_has_exit_in_direction(to_tile, opposite_direction):
		return false

	return _get_cell_edge_height(from_cell, direction) == _get_cell_edge_height(to_cell, opposite_direction)


func _can_traverse_diagonal(
	from_cell: Vector2i,
	to_cell: Vector2i,
	horizontal_direction: int,
	vertical_direction: int
) -> bool:
	var horizontal_cell: Vector2i = from_cell + _get_direction_delta(horizontal_direction)
	var vertical_cell: Vector2i = from_cell + _get_direction_delta(vertical_direction)
	if not _has_path_point(horizontal_cell) or not _has_path_point(vertical_cell):
		return false

	return (
		_can_traverse_cardinal(from_cell, horizontal_cell, horizontal_direction)
		and _can_traverse_cardinal(horizontal_cell, to_cell, vertical_direction)
		and _can_traverse_cardinal(from_cell, vertical_cell, vertical_direction)
		and _can_traverse_cardinal(vertical_cell, to_cell, horizontal_direction)
	)


func _get_cell_edge_height(cell_coords: Vector2i, direction: int) -> int:
	var tile: TerrainTileData = _get_tile(cell_coords.x, cell_coords.y)
	if tile == null:
		return 0

	if tile.tile_kind == TILE_KIND_FLOOR:
		return tile.height

	var neighbor_coords: Vector2i = cell_coords + _get_direction_delta(direction)
	var neighbor_tile: TerrainTileData = _get_tile(neighbor_coords.x, neighbor_coords.y)
	if neighbor_tile != null and neighbor_tile.walkable and abs(neighbor_tile.height - tile.height) <= 1:
		return neighbor_tile.height

	return tile.height


func _tile_has_exit_in_direction(tile: TerrainTileData, direction: int) -> bool:
	if tile == null:
		return false

	match direction:
		DIRECTION_NORTH:
			return tile.has_exit(EXIT_NORTH)
		DIRECTION_EAST:
			return tile.has_exit(EXIT_EAST)
		DIRECTION_SOUTH:
			return tile.has_exit(EXIT_SOUTH)
		DIRECTION_WEST:
			return tile.has_exit(EXIT_WEST)
		_:
			return false


func _get_direction_delta(direction: int) -> Vector2i:
	match direction:
		DIRECTION_NORTH:
			return Vector2i(0, -1)
		DIRECTION_EAST:
			return Vector2i(1, 0)
		DIRECTION_SOUTH:
			return Vector2i(0, 1)
		DIRECTION_WEST:
			return Vector2i(-1, 0)
		_:
			return Vector2i.ZERO


func _get_opposite_direction(direction: int) -> int:
	match direction:
		DIRECTION_NORTH:
			return DIRECTION_SOUTH
		DIRECTION_EAST:
			return DIRECTION_WEST
		DIRECTION_SOUTH:
			return DIRECTION_NORTH
		DIRECTION_WEST:
			return DIRECTION_EAST
		_:
			return DIRECTION_INVALID


func _resolve_walkable_cell(requested_cell: Vector2i) -> Vector2i:
	if is_cell_walkable(requested_cell.x, requested_cell.y):
		return requested_cell
	if _path_point_id_by_cell.is_empty():
		return requested_cell

	var closest_point_id: int = _path_astar.get_closest_point(Vector2(requested_cell.x, requested_cell.y))
	if closest_point_id <= 0:
		return requested_cell

	return _get_cell_from_path_point_id(closest_point_id)


func _has_path_point(cell_coords: Vector2i) -> bool:
	return _path_point_id_by_cell.has(cell_coords)


func _get_cell_from_path_point_id(point_id: int) -> Vector2i:
	var point_position: Vector2 = _path_astar.get_point_position(point_id)
	return Vector2i(roundi(point_position.x), roundi(point_position.y))


func _get_mesh_library_item_name(item_id: int) -> String:
	var mesh_library: MeshLibrary = gm_terrain.mesh_library if gm_terrain != null else null
	if mesh_library == null:
		mesh_library = TERRAIN_MESH_LIBRARY
	if mesh_library == null:
		return ""
	return mesh_library.get_item_name(item_id)


func _get_rise_direction_for_orientation(orientation: int) -> int:
	if gm_terrain == null:
		return DIRECTION_INVALID

	var north_orientation: int = gm_terrain.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(180.0), 0.0))
	)
	var east_orientation: int = gm_terrain.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(-90.0), 0.0))
	)
	var south_orientation: int = gm_terrain.get_orthogonal_index_from_basis(Basis.IDENTITY)
	var west_orientation: int = gm_terrain.get_orthogonal_index_from_basis(
		Basis.from_euler(Vector3(0.0, deg_to_rad(90.0), 0.0))
	)

	if orientation == north_orientation:
		return DIRECTION_NORTH
	if orientation == east_orientation:
		return DIRECTION_EAST
	if orientation == south_orientation:
		return DIRECTION_SOUTH
	if orientation == west_orientation:
		return DIRECTION_WEST

	return DIRECTION_INVALID


func _get_rotation_degrees_for_direction(direction: int) -> int:
	match direction:
		DIRECTION_NORTH:
			return 180
		DIRECTION_EAST:
			return 270
		DIRECTION_SOUTH:
			return 0
		DIRECTION_WEST:
			return 90
		_:
			return 0


func _get_straight_slope_exit_mask(rise_direction: int) -> int:
	match rise_direction:
		DIRECTION_NORTH, DIRECTION_SOUTH:
			return EXIT_NORTH | EXIT_SOUTH
		DIRECTION_EAST, DIRECTION_WEST:
			return EXIT_EAST | EXIT_WEST
		_:
			return EXIT_ALL


func _configure_terrain_gridmap() -> void:
	if gm_terrain == null:
		return
	gm_terrain.mesh_library = TERRAIN_MESH_LIBRARY
	gm_terrain.cell_size = TERRAIN_CELL_SIZE
	gm_terrain.bake_navigation = false
