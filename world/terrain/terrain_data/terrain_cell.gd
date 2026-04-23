extends RefCounted

const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")

var height_level: int = 0
var walkable: bool = true
var buildable: bool = true
var ramp_dir: int = TerrainDefs.INVALID_RAMP_DIR
var blocker_type: int = TerrainDefs.BlockerType.NONE
var surface_type: int = TerrainDefs.SurfaceType.DIRT


func _init(
	p_height_level: int = 0,
	p_walkable: bool = true,
	p_buildable: bool = true,
	p_ramp_dir: int = TerrainDefs.INVALID_RAMP_DIR,
	p_blocker_type: int = TerrainDefs.BlockerType.NONE,
	p_surface_type: int = TerrainDefs.SurfaceType.DIRT
) -> void:
	height_level = p_height_level
	walkable = p_walkable
	buildable = p_buildable
	ramp_dir = p_ramp_dir
	blocker_type = p_blocker_type
	surface_type = p_surface_type


func _to_string() -> String:
	return "TerrainCell(height=%d, walkable=%s, buildable=%s, ramp_dir=%d, blocker_type=%d, surface_type=%d)" % [
		height_level,
		str(walkable),
		str(buildable),
		ramp_dir,
		blocker_type,
		surface_type,
	]
