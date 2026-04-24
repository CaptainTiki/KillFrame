@tool
extends Resource
class_name TerrainTileData

enum ExitMask {
	NONE = 0,
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8,
}

@export var height: int = 0
@export var walkable: bool = true
@export var buildable: bool = true
@export_range(0, 15, 1) var exit_mask: int = ExitMask.NONE
@export var tile_kind: String = ""
@export var rotation_degrees: int = 0


func has_exit(exit_flag: int) -> bool:
	return (exit_mask & exit_flag) != 0
