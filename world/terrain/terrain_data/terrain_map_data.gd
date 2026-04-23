extends RefCounted

const TerrainCell = preload("res://world/terrain/terrain_data/terrain_cell.gd")
const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")

var width: int = 0
var height: int = 0
var cells: Array[TerrainCell] = []


func _init(map_width: int = 0, map_height: int = 0) -> void:
	if map_width > 0 and map_height > 0:
		initialize(map_width, map_height)


func initialize(map_width: int, map_height: int) -> void:
	width = max(map_width, 0)
	height = max(map_height, 0)
	cells.clear()
	cells.resize(width * height)

	for index: int in range(cells.size()):
		cells[index] = TerrainCell.new()


func in_bounds(x: int, z: int) -> bool:
	return x >= 0 and x < width and z >= 0 and z < height


func get_cell(x: int, z: int) -> TerrainCell:
	if not in_bounds(x, z):
		return null

	return cells[_index(x, z)]


func set_cell(x: int, z: int, cell: TerrainCell) -> void:
	if not in_bounds(x, z):
		return

	if cell == null:
		return

	cells[_index(x, z)] = cell


func fill_rect_height(x: int, z: int, rect_width: int, rect_height: int, height_level: int) -> void:
	for current_z: int in range(z, z + rect_height):
		for current_x: int in range(x, x + rect_width):
			var cell: TerrainCell = get_cell(current_x, current_z)
			if cell == null:
				continue

			cell.height_level = height_level


func fill_rect_flags(
	x: int,
	z: int,
	rect_width: int,
	rect_height: int,
	walkable: bool,
	buildable: bool
) -> void:
	for current_z: int in range(z, z + rect_height):
		for current_x: int in range(x, x + rect_width):
			var cell: TerrainCell = get_cell(current_x, current_z)
			if cell == null:
				continue

			cell.walkable = walkable
			cell.buildable = buildable


func fill_rect_surface_type(x: int, z: int, rect_width: int, rect_height: int, surface_type: int) -> void:
	for current_z: int in range(z, z + rect_height):
		for current_x: int in range(x, x + rect_width):
			var cell: TerrainCell = get_cell(current_x, current_z)
			if cell == null:
				continue

			cell.surface_type = surface_type


func set_cell_ramp_dir(x: int, z: int, ramp_dir: int) -> void:
	var cell: TerrainCell = get_cell(x, z)
	if cell == null:
		return

	cell.ramp_dir = ramp_dir


func raise_plateau(x: int, z: int, rect_width: int, rect_height: int, height_delta: int) -> void:
	for current_z: int in range(z, z + rect_height):
		for current_x: int in range(x, x + rect_width):
			var cell: TerrainCell = get_cell(current_x, current_z)
			if cell == null:
				continue

			cell.height_level += height_delta


func place_blocker_rect(x: int, z: int, rect_width: int, rect_height: int, blocker_type: int) -> void:
	for current_z: int in range(z, z + rect_height):
		for current_x: int in range(x, x + rect_width):
			var cell: TerrainCell = get_cell(current_x, current_z)
			if cell == null:
				continue

			cell.blocker_type = blocker_type

			# PASS 1 keeps blockers simple: blocker cells are not usable.
			if blocker_type != TerrainDefs.BlockerType.NONE:
				cell.walkable = false
				cell.buildable = false


func _index(x: int, z: int) -> int:
	return z * width + x
