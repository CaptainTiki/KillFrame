extends RefCounted

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")

var _astar: AStar3D = AStar3D.new()
var _map_data: TerrainMapData
var _terrain_manager
var _point_count: int = 0
var _connection_count: int = 0


func rebuild_navigation(map_data: TerrainMapData, terrain_manager: Node3D) -> Dictionary:
	clear_navigation()

	if map_data == null or terrain_manager == null:
		return {
			"success": false,
			"point_count": 0,
			"connection_count": 0,
			"reason": "Missing terrain data or terrain manager.",
		}

	_map_data = map_data
	_terrain_manager = terrain_manager

	for z: int in range(_map_data.height):
		for x: int in range(_map_data.width):
			if not _is_cell_navigable(x, z):
				continue

			var point_id: int = _cell_id(x, z)
			var point_position: Vector3 = _terrain_manager.get_cell_surface_world_position(x, z, 0.0)
			_astar.add_point(point_id, point_position)
			_point_count += 1

	for z: int in range(_map_data.height):
		for x: int in range(_map_data.width):
			if not _is_cell_navigable(x, z):
				continue

			for direction_offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var neighbor_x: int = x + direction_offset.x
				var neighbor_z: int = z + direction_offset.y
				if not _is_cell_navigable(neighbor_x, neighbor_z):
					continue
				if not _can_traverse_between_cells(x, z, neighbor_x, neighbor_z):
					continue

				_astar.connect_points(_cell_id(x, z), _cell_id(neighbor_x, neighbor_z))
				_connection_count += 1

	return {
		"success": true,
		"point_count": _point_count,
		"connection_count": _connection_count,
		"reason": "",
	}


func clear_navigation() -> void:
	_astar.clear()
	_map_data = null
	_terrain_manager = null
	_point_count = 0
	_connection_count = 0


func request_path_world(start_world: Vector3, target_world: Vector3) -> Dictionary:
	if _map_data == null or _terrain_manager == null:
		return _make_failed_result("Navigation has not been built yet.")

	var start_cell: Vector2i = _terrain_manager.get_cell_coords_from_world(start_world)
	var target_cell: Vector2i = _terrain_manager.get_cell_coords_from_world(target_world)
	return request_path_cells(start_cell, target_cell)


func request_path_cells(start_cell: Vector2i, target_cell: Vector2i) -> Dictionary:
	if _map_data == null or _terrain_manager == null:
		return _make_failed_result("Navigation has not been built yet.")
	if not _map_data.in_bounds(start_cell.x, start_cell.y):
		return _make_failed_result("Start cell is outside the map.")
	if not _map_data.in_bounds(target_cell.x, target_cell.y):
		return _make_failed_result("Target cell is outside the map.")

	var resolved_start: Vector2i = _find_nearest_navigable_cell(start_cell)
	if resolved_start == Vector2i(-1, -1):
		return _make_failed_result("No navigable start cell was found.")

	var resolved_target: Vector2i = _find_nearest_navigable_cell(target_cell)
	if resolved_target == Vector2i(-1, -1):
		return _make_failed_result("No navigable target cell was found.")

	var start_id: int = _cell_id(resolved_start.x, resolved_start.y)
	var target_id: int = _cell_id(resolved_target.x, resolved_target.y)
	if not _astar.has_point(start_id) or not _astar.has_point(target_id):
		return _make_failed_result("Start or target is missing from the nav graph.")

	var id_path: PackedInt64Array = _astar.get_id_path(start_id, target_id)
	if id_path.is_empty():
		return _make_failed_result("No path found between the selected cells.")

	var cell_path: Array[Vector2i] = []
	var world_path: Array[Vector3] = []
	for point_id: int in id_path:
		var cell_coords: Vector2i = _cell_from_id(point_id)
		cell_path.append(cell_coords)
		world_path.append(_terrain_manager.get_cell_surface_world_position(cell_coords.x, cell_coords.y, 0.0))

	return {
		"success": true,
		"reason": "",
		"start_cell": resolved_start,
		"target_cell": resolved_target,
		"cell_path": cell_path,
		"world_path": world_path,
		"path_length": world_path.size(),
	}


func get_navigation_summary() -> Dictionary:
	return {
		"point_count": _point_count,
		"connection_count": _connection_count,
	}


func _is_cell_navigable(x: int, z: int) -> bool:
	if _map_data == null or not _map_data.in_bounds(x, z):
		return false

	var cell = _map_data.get_cell(x, z)
	return cell != null and cell.walkable


func _can_traverse_between_cells(from_x: int, from_z: int, to_x: int, to_z: int) -> bool:
	var from_cell = _map_data.get_cell(from_x, from_z)
	var to_cell = _map_data.get_cell(to_x, to_z)
	if from_cell == null or to_cell == null:
		return false

	var height_delta: int = to_cell.height_level - from_cell.height_level
	if abs(height_delta) > 1:
		return false
	if height_delta == 0:
		return true

	var move_direction: int = _direction_from_offset(Vector2i(to_x - from_x, to_z - from_z))
	if move_direction == TerrainDefs.INVALID_RAMP_DIR:
		return false

	if height_delta == 1:
		return to_cell.ramp_dir == move_direction

	return from_cell.ramp_dir == _get_opposite_direction(move_direction)


func _find_nearest_navigable_cell(origin_cell: Vector2i, max_radius: int = 4) -> Vector2i:
	if _is_cell_navigable(origin_cell.x, origin_cell.y):
		return origin_cell

	for radius: int in range(1, max_radius + 1):
		for offset_z: int in range(-radius, radius + 1):
			for offset_x: int in range(-radius, radius + 1):
				if abs(offset_x) != radius and abs(offset_z) != radius:
					continue

				var candidate: Vector2i = origin_cell + Vector2i(offset_x, offset_z)
				if _is_cell_navigable(candidate.x, candidate.y):
					return candidate

	return Vector2i(-1, -1)


func _make_failed_result(reason: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"start_cell": Vector2i(-1, -1),
		"target_cell": Vector2i(-1, -1),
		"cell_path": [],
		"world_path": [],
		"path_length": 0,
	}


func _direction_from_offset(offset: Vector2i) -> int:
	match offset:
		Vector2i(0, -1):
			return TerrainDefs.RampDirection.NORTH
		Vector2i(1, 0):
			return TerrainDefs.RampDirection.EAST
		Vector2i(0, 1):
			return TerrainDefs.RampDirection.SOUTH
		Vector2i(-1, 0):
			return TerrainDefs.RampDirection.WEST
		_:
			return TerrainDefs.INVALID_RAMP_DIR


func _get_opposite_direction(direction: int) -> int:
	match direction:
		TerrainDefs.RampDirection.NORTH:
			return TerrainDefs.RampDirection.SOUTH
		TerrainDefs.RampDirection.EAST:
			return TerrainDefs.RampDirection.WEST
		TerrainDefs.RampDirection.SOUTH:
			return TerrainDefs.RampDirection.NORTH
		TerrainDefs.RampDirection.WEST:
			return TerrainDefs.RampDirection.EAST
		_:
			return TerrainDefs.INVALID_RAMP_DIR


func _cell_id(x: int, z: int) -> int:
	return z * _map_data.width + x


func _cell_from_id(point_id: int) -> Vector2i:
	return Vector2i(point_id % _map_data.width, int(point_id / _map_data.width))
