extends Resource
class_name TerrainMapResource

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")
const TerrainCell = preload("res://world/terrain/terrain_data/terrain_cell.gd")

# INVALID_RAMP_DIR is -1; encode as 255 in the byte array.
const INVALID_RAMP_ENCODED: int = 255

@export var map_width: int = 0
@export var map_height: int = 0
@export var origin_x: int = 0
@export var origin_z: int = 0

@export var height_levels: PackedInt32Array = PackedInt32Array()
@export var walkable: PackedByteArray = PackedByteArray()
@export var buildable: PackedByteArray = PackedByteArray()
@export var ramp_dirs: PackedByteArray = PackedByteArray()
@export var blocker_types: PackedByteArray = PackedByteArray()
@export var surface_types: PackedByteArray = PackedByteArray()


func is_valid() -> bool:
	var expected: int = map_width * map_height
	return (
		map_width > 0
		and map_height > 0
		and height_levels.size() == expected
		and walkable.size() == expected
		and buildable.size() == expected
		and ramp_dirs.size() == expected
		and blocker_types.size() == expected
		and surface_types.size() == expected
	)


func populate_from_map_data(data: TerrainMapData) -> void:
	map_width = data.width
	map_height = data.height
	origin_x = data.origin_x
	origin_z = data.origin_z

	var cell_count: int = map_width * map_height
	height_levels.resize(cell_count)
	walkable.resize(cell_count)
	buildable.resize(cell_count)
	ramp_dirs.resize(cell_count)
	blocker_types.resize(cell_count)
	surface_types.resize(cell_count)

	for i: int in range(cell_count):
		var cell: TerrainCell = data.cells[i]
		if cell == null:
			height_levels[i] = 0
			walkable[i] = 0
			buildable[i] = 0
			ramp_dirs[i] = INVALID_RAMP_ENCODED
			blocker_types[i] = TerrainDefs.BlockerType.NONE
			surface_types[i] = TerrainDefs.SurfaceType.DIRT
		else:
			height_levels[i] = cell.height_level
			walkable[i] = 1 if cell.walkable else 0
			buildable[i] = 1 if cell.buildable else 0
			ramp_dirs[i] = INVALID_RAMP_ENCODED if cell.ramp_dir == TerrainDefs.INVALID_RAMP_DIR else cell.ramp_dir
			blocker_types[i] = cell.blocker_type
			surface_types[i] = cell.surface_type


func to_map_data() -> TerrainMapData:
	if not is_valid():
		return null

	var data: TerrainMapData = TerrainMapData.new(map_width, map_height)
	data.set_origin(origin_x, origin_z)

	for i: int in range(map_width * map_height):
		var cell: TerrainCell = data.cells[i]
		cell.height_level = height_levels[i]
		cell.walkable = walkable[i] != 0
		cell.buildable = buildable[i] != 0
		cell.ramp_dir = TerrainDefs.INVALID_RAMP_DIR if ramp_dirs[i] == INVALID_RAMP_ENCODED else int(ramp_dirs[i])
		cell.blocker_type = blocker_types[i]
		cell.surface_type = surface_types[i]

	return data
