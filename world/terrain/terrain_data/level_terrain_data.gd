@tool
extends Resource
class_name LevelTerrainData

const TerrainTileData = preload("res://world/terrain/terrain_data/terrain_tile_data.gd")

@export var origin: Vector2i = Vector2i.ZERO
@export_range(0, 4096, 1) var width: int = 0
@export_range(0, 4096, 1) var height: int = 0
@export var cell_map: Dictionary = {}


func clear() -> void:
	origin = Vector2i.ZERO
	width = 0
	height = 0
	cell_map.clear()


func is_valid() -> bool:
	return width > 0 and height > 0 and not cell_map.is_empty()


func has_cell(x: int, z: int) -> bool:
	return cell_map.has(make_cell_key(x, z))


func get_cell(x: int, z: int) -> TerrainTileData:
	return cell_map.get(make_cell_key(x, z), null) as TerrainTileData


func set_cell(x: int, z: int, tile: TerrainTileData) -> void:
	if tile == null:
		return
	cell_map[make_cell_key(x, z)] = tile


func erase_cell(x: int, z: int) -> void:
	cell_map.erase(make_cell_key(x, z))


func get_used_cells() -> Array[Vector2i]:
	var used_cells: Array[Vector2i] = []
	for cell_key_variant: Variant in cell_map.keys():
		used_cells.append(parse_cell_key(str(cell_key_variant)))
	return used_cells


func get_cell_count() -> int:
	return cell_map.size()


static func make_cell_key(x: int, z: int) -> String:
	return "%d,%d" % [x, z]


static func parse_cell_key(cell_key: String) -> Vector2i:
	var parts: PackedStringArray = cell_key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))
