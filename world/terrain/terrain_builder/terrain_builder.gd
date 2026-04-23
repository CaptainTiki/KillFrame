extends RefCounted

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")

const ITEM_GROUND_FLAT: int = 0
const ITEM_GROUND_FLAT_VAR_A: int = 1
const ITEM_GROUND_FLAT_VAR_B: int = 2
const ITEM_CLIFF_LIP_STRAIGHT: int = 3
const ITEM_CLIFF_WALL_STRAIGHT: int = 6
const ITEM_RAMP_UP: int = 9
const ITEM_BLOCKER_ROCK: int = 13
const ITEM_BLOCKER_WRECK: int = 14
const ITEM_BLOCKER_LARGE: int = 15

const DIRECTION_NORTH: Vector3i = Vector3i(0, 0, -1)
const DIRECTION_EAST: Vector3i = Vector3i(1, 0, 0)
const DIRECTION_SOUTH: Vector3i = Vector3i(0, 0, 1)
const DIRECTION_WEST: Vector3i = Vector3i(-1, 0, 0)

const DIRECTIONS: Array[Dictionary] = [
	{"dir": TerrainDefs.RampDirection.NORTH, "delta": DIRECTION_NORTH, "degrees": 0.0},
	{"dir": TerrainDefs.RampDirection.EAST, "delta": DIRECTION_EAST, "degrees": -90.0},
	{"dir": TerrainDefs.RampDirection.SOUTH, "delta": DIRECTION_SOUTH, "degrees": 180.0},
	{"dir": TerrainDefs.RampDirection.WEST, "delta": DIRECTION_WEST, "degrees": 90.0},
]


func build_from_data(map_data: TerrainMapData, terrain_root: Node3D) -> void:
	if map_data == null or terrain_root == null:
		return

	var gridmaps: Dictionary = _get_gridmaps(terrain_root)
	clear_all(gridmaps)
	build_surfaces(map_data, gridmaps)
	build_cliffs(map_data, gridmaps)
	build_ramps(map_data, gridmaps)
	build_blockers(map_data, gridmaps)


func rebuild_from_data(terrain_root: Node3D, map_data: TerrainMapData) -> void:
	build_from_data(map_data, terrain_root)


func clear_all(gridmaps: Dictionary) -> void:
	for gridmap: GridMap in gridmaps.values():
		gridmap.clear()


func build_surfaces(map_data: TerrainMapData, gridmaps: Dictionary) -> void:
	var surface_gridmap: GridMap = gridmaps["surface"] as GridMap

	for z: int in range(map_data.height):
		for x: int in range(map_data.width):
			var cell = map_data.get_cell(x, z)
			if cell == null:
				continue

			if cell.ramp_dir != TerrainDefs.INVALID_RAMP_DIR:
				continue

			var item_id: int = _get_surface_item_id(cell.surface_type)
			surface_gridmap.set_cell_item(Vector3i(x, cell.height_level, z), item_id)


func build_cliffs(map_data: TerrainMapData, gridmaps: Dictionary) -> void:
	var cliff_gridmap: GridMap = gridmaps["cliffs"] as GridMap

	for z: int in range(map_data.height):
		for x: int in range(map_data.width):
			var cell = map_data.get_cell(x, z)
			if cell == null:
				continue

			for direction_info: Dictionary in DIRECTIONS:
				var delta: Vector3i = direction_info["delta"] as Vector3i
				var neighbor = map_data.get_cell(x + delta.x, z + delta.z)
				if neighbor == null:
					continue

				if neighbor.height_level >= cell.height_level:
					continue

				var direction: int = int(direction_info["dir"])
				if _ramp_opens_toward(cell.ramp_dir, direction):
					continue

				var low_cell_direction: int = _get_opposite_direction(direction)
				var orientation: int = _get_direction_orientation(cliff_gridmap, low_cell_direction)
				var low_cell_x: int = x + delta.x
				var low_cell_z: int = z + delta.z
				cliff_gridmap.set_cell_item(
					Vector3i(low_cell_x, cell.height_level, low_cell_z),
					ITEM_CLIFF_LIP_STRAIGHT,
					orientation
				)

				for wall_level: int in range(neighbor.height_level, cell.height_level):
					cliff_gridmap.set_cell_item(
						Vector3i(low_cell_x, wall_level, low_cell_z),
						ITEM_CLIFF_WALL_STRAIGHT,
						orientation
					)


func build_ramps(map_data: TerrainMapData, gridmaps: Dictionary) -> void:
	var ramp_gridmap: GridMap = gridmaps["ramps"] as GridMap

	for z: int in range(map_data.height):
		for x: int in range(map_data.width):
			var cell = map_data.get_cell(x, z)
			if cell == null:
				continue

			if cell.ramp_dir == TerrainDefs.INVALID_RAMP_DIR:
				continue

			var orientation: int = _get_ramp_orientation(ramp_gridmap, cell.ramp_dir)
			ramp_gridmap.set_cell_item(Vector3i(x, cell.height_level, z), ITEM_RAMP_UP, orientation)


func build_blockers(map_data: TerrainMapData, gridmaps: Dictionary) -> void:
	var blocker_gridmap: GridMap = gridmaps["blockers"] as GridMap

	for z: int in range(map_data.height):
		for x: int in range(map_data.width):
			var cell = map_data.get_cell(x, z)
			if cell == null:
				continue

			if cell.blocker_type == TerrainDefs.BlockerType.NONE:
				continue

			var cell_position: Vector3i = Vector3i(x, cell.height_level, z)
			var blocker_item_id: int = _get_blocker_item_id(cell.blocker_type)
			var orientation: int = 0
			if blocker_item_id == ITEM_BLOCKER_WRECK:
				orientation = _get_orientation(blocker_gridmap, -90.0 if (x + z) % 2 == 0 else 0.0)

			blocker_gridmap.set_cell_item(cell_position, blocker_item_id, orientation)


func _get_gridmaps(terrain_root: Node3D) -> Dictionary:
	var gm: GridMap = terrain_root.get_node("GM_Terrain") as GridMap
	return {
		"surface": gm,
		"cliffs": gm,
		"ramps": gm,
		"blockers": gm,
	}


func _get_surface_item_id(surface_type: int) -> int:
	match surface_type:
		TerrainDefs.SurfaceType.BASE_PAD:
			return ITEM_GROUND_FLAT_VAR_A
		TerrainDefs.SurfaceType.ROUGH_GROUND:
			return ITEM_GROUND_FLAT_VAR_B
		TerrainDefs.SurfaceType.PLATEAU_ROCK:
			return ITEM_GROUND_FLAT_VAR_A
		_:
			return ITEM_GROUND_FLAT


func _get_blocker_item_id(blocker_type: int) -> int:
	match blocker_type:
		TerrainDefs.BlockerType.DEBRIS:
			return ITEM_BLOCKER_WRECK
		TerrainDefs.BlockerType.STRUCTURE:
			return ITEM_BLOCKER_LARGE
		_:
			return ITEM_BLOCKER_ROCK


func _ramp_opens_toward(ramp_dir: int, edge_direction: int) -> bool:
	if ramp_dir == TerrainDefs.INVALID_RAMP_DIR:
		return false

	return _get_opposite_direction(ramp_dir) == edge_direction


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


func _get_ramp_orientation(gridmap: GridMap, ramp_dir: int) -> int:
	match ramp_dir:
		TerrainDefs.RampDirection.NORTH:
			return _get_orientation(gridmap, 180.0)
		TerrainDefs.RampDirection.EAST:
			return _get_orientation(gridmap, -90.0)
		TerrainDefs.RampDirection.SOUTH:
			return _get_orientation(gridmap, 0.0)
		TerrainDefs.RampDirection.WEST:
			return _get_orientation(gridmap, 90.0)
		_:
			return 0


func _get_direction_orientation(gridmap: GridMap, direction: int) -> int:
	match direction:
		TerrainDefs.RampDirection.NORTH:
			return _get_orientation(gridmap, 0.0)
		TerrainDefs.RampDirection.EAST:
			return _get_orientation(gridmap, -90.0)
		TerrainDefs.RampDirection.SOUTH:
			return _get_orientation(gridmap, 180.0)
		TerrainDefs.RampDirection.WEST:
			return _get_orientation(gridmap, 90.0)
		_:
			return 0


func _get_orientation(gridmap: GridMap, y_rotation_degrees: float) -> int:
	var basis: Basis = Basis.from_euler(Vector3(0.0, deg_to_rad(y_rotation_degrees), 0.0))
	return gridmap.get_orthogonal_index_from_basis(basis)
