extends Node3D

const TerrainBuilder = preload("res://world/terrain/terrain_builder/terrain_builder.gd")
const TerrainDebugMarkerScript = preload("res://world/terrain/terrain_debug/terrain_debug_marker.gd")
const TerrainDebugOverlayScript = preload("res://world/terrain/terrain_debug/terrain_debug_overlay.gd")
const TerrainNavBuilder = preload("res://world/terrain/terrain_nav/terrain_nav_builder.gd")
const TerrainNavDebugScript = preload("res://world/terrain/terrain_nav/terrain_nav_debug.gd")
const TerrainDefs = preload("res://world/terrain/terrain_data/terrain_defs.gd")
const TerrainMapData = preload("res://world/terrain/terrain_data/terrain_map_data.gd")
const TERRAIN_MESH_LIBRARY = preload("res://world/terrain/terrain_meshes/terrain_mesh_library.tres")

@export_range(1, 512, 1) var map_width: int = 128
@export_range(1, 512, 1) var map_height: int = 128

@onready var gm_surface: GridMap = $GM_Surface as GridMap
@onready var gm_cliffs: GridMap = $GM_Cliffs as GridMap
@onready var gm_ramps: GridMap = $GM_Ramps as GridMap
@onready var gm_blockers: GridMap = $GM_Blockers as GridMap
@onready var _debug_overlay: TerrainDebugOverlayScript = $DebugLayers/TerrainDebugOverlay as TerrainDebugOverlayScript
@onready var _inspect_marker: TerrainDebugMarkerScript = $DebugLayers/InspectMarker as TerrainDebugMarkerScript
@onready var _nav_debug: TerrainNavDebugScript = $DebugLayers/TerrainNavDebug as TerrainNavDebugScript

var map_data: TerrainMapData
var _terrain_builder: TerrainBuilder = TerrainBuilder.new()
var _terrain_nav_builder: TerrainNavBuilder = TerrainNavBuilder.new()
var _debug_overlay_enabled: bool = false
var _navigation_summary: Dictionary = {
	"success": false,
	"point_count": 0,
	"connection_count": 0,
	"reason": "Navigation has not been built yet.",
}


func _ready() -> void:
	_configure_gridmaps()
	_inspect_marker.set_marker_enabled(false)
	_debug_overlay.set_overlay_visible(false)
	_nav_debug.clear_path()


func initialize_map_data(width_override: int = -1, height_override: int = -1) -> TerrainMapData:
	var target_width: int = map_width if width_override <= 0 else width_override
	var target_height: int = map_height if height_override <= 0 else height_override

	map_width = target_width
	map_height = target_height
	map_data = TerrainMapData.new(target_width, target_height)
	return map_data


func generate_sample_test_layout() -> void:
	regenerate_sample_map()


func regenerate_sample_map() -> void:
	var target_width: int = map_width
	var target_height: int = map_height
	if map_data != null:
		target_width = map_data.width
		target_height = map_data.height

	initialize_map_data(target_width, target_height)

	_populate_sample_map_data()
	rebuild_terrain()


func rebuild_terrain() -> void:
	if map_data == null:
		push_warning("TerrainManager.rebuild_terrain() called before map data exists.")
		return

	_configure_gridmaps()
	_terrain_builder.build_from_data(map_data, self)
	rebuild_navigation()

	if _debug_overlay_enabled:
		_debug_overlay.build_overlay(map_data, gm_surface)
		_debug_overlay.set_overlay_visible(true)
	else:
		_debug_overlay.clear_overlay()


func rebuild_terrain_visuals() -> void:
	rebuild_terrain()


func rebuild_navigation() -> void:
	# PASS 4 uses a data-driven AStar3D graph so the terrain model remains the
	# authoritative traversal source instead of deriving nav from placeholder meshes.
	_navigation_summary = _terrain_nav_builder.rebuild_navigation(map_data, self)
	if bool(_navigation_summary.get("success", false)):
		print("Terrain navigation rebuilt: %d points, %d connections." % [
			_navigation_summary["point_count"],
			_navigation_summary["connection_count"],
		])
	else:
		push_warning("Terrain navigation rebuild failed: %s" % [_navigation_summary.get("reason", "Unknown reason.")])


func clear_navigation() -> void:
	_terrain_nav_builder.clear_navigation()
	_navigation_summary = {
		"success": false,
		"point_count": 0,
		"connection_count": 0,
		"reason": "Navigation was cleared.",
	}


func get_navigation_summary() -> Dictionary:
	return _navigation_summary.duplicate(true)


func request_navigation_path_world(start_world: Vector3, target_world: Vector3) -> Dictionary:
	return _terrain_nav_builder.request_path_world(start_world, target_world)


func request_navigation_path_cells(start_cell: Vector2i, target_cell: Vector2i) -> Dictionary:
	return _terrain_nav_builder.request_path_cells(start_cell, target_cell)


func set_debug_overlay_enabled(enabled: bool) -> void:
	_debug_overlay_enabled = enabled
	if not enabled:
		_debug_overlay.clear_overlay()
		_debug_overlay.set_overlay_visible(false)
		return

	if map_data == null:
		return

	_debug_overlay.build_overlay(map_data, gm_surface)
	_debug_overlay.set_overlay_visible(true)


func toggle_debug_overlay() -> bool:
	set_debug_overlay_enabled(not _debug_overlay_enabled)
	return _debug_overlay_enabled


func is_debug_overlay_enabled() -> bool:
	return _debug_overlay_enabled


func get_debug_overlay_marker_count() -> int:
	return _debug_overlay.get_marker_count()


func get_navigation_debug_marker_count() -> int:
	return _nav_debug.get_path_marker_count()


func show_navigation_path(world_points: Array[Vector3]) -> void:
	_nav_debug.show_path(world_points)


func clear_navigation_debug() -> void:
	_nav_debug.clear_path()


func get_cell_coords_from_world(world_position: Vector3) -> Vector2i:
	var local_position: Vector3 = gm_surface.to_local(world_position)
	var map_position: Vector3i = gm_surface.local_to_map(local_position)
	return Vector2i(map_position.x, map_position.z)


func get_cell_debug_info(x: int, z: int) -> Dictionary:
	if map_data == null or not map_data.in_bounds(x, z):
		return {"valid": false}

	var cell = map_data.get_cell(x, z)
	return {
		"valid": true,
		"x": x,
		"z": z,
		"height_level": cell.height_level,
		"walkable": cell.walkable,
		"buildable": cell.buildable,
		"ramp_dir": cell.ramp_dir,
		"blocker_type": cell.blocker_type,
		"surface_type": cell.surface_type,
		"world_position": get_cell_display_world_position(x, z, 0.06),
	}


func is_cell_walkable(x: int, z: int) -> bool:
	if map_data == null or not map_data.in_bounds(x, z):
		return false

	var cell = map_data.get_cell(x, z)
	return cell != null and cell.walkable


func get_cell_surface_world_position(x: int, z: int, y_offset: float = 0.0) -> Vector3:
	if map_data == null:
		return global_position

	var cell = map_data.get_cell(x, z)
	if cell == null:
		return global_position

	var local_position: Vector3 = gm_surface.map_to_local(Vector3i(x, cell.height_level, z))
	return gm_surface.to_global(local_position + Vector3(0.0, TerrainDefs.HEIGHT_STEP_METERS * 0.5 + y_offset, 0.0))


func get_cell_display_world_position(x: int, z: int, y_offset: float = 0.06) -> Vector3:
	return get_cell_surface_world_position(x, z, y_offset)


func show_debug_marker_for_cell(x: int, z: int) -> void:
	var cell_info: Dictionary = get_cell_debug_info(x, z)
	if not bool(cell_info.get("valid", false)):
		hide_debug_marker()
		return

	_inspect_marker.configure_marker(
		Color(0.15, 0.95, 1.0, 0.45),
		Vector3(1.04, 0.06, 1.04),
		cell_info["world_position"]
	)


func hide_debug_marker() -> void:
	_inspect_marker.set_marker_enabled(false)


func _populate_sample_map_data() -> void:
	_apply_main_base()
	_apply_natural_expansion()
	_apply_raised_plateau()
	_apply_plateau_ramp()
	_apply_choke()


func get_map_summary() -> Dictionary:
	var walkable_cells: int = 0
	var buildable_cells: int = 0
	var blocker_cells: int = 0
	var max_height_level: int = 0

	if map_data == null:
		return {
			"width": 0,
			"height": 0,
			"total_cells": 0,
			"walkable_cells": 0,
			"buildable_cells": 0,
			"blocker_cells": 0,
			"max_height_level": 0,
		}

	for cell: Variant in map_data.cells:
		var terrain_cell = cell
		if terrain_cell == null:
			continue

		if terrain_cell.walkable:
			walkable_cells += 1
		if terrain_cell.buildable:
			buildable_cells += 1
		if terrain_cell.blocker_type != TerrainDefs.BlockerType.NONE:
			blocker_cells += 1
		max_height_level = max(max_height_level, terrain_cell.height_level)

	return {
		"width": map_data.width,
		"height": map_data.height,
		"total_cells": map_data.width * map_data.height,
		"walkable_cells": walkable_cells,
		"buildable_cells": buildable_cells,
		"blocker_cells": blocker_cells,
		"max_height_level": max_height_level,
	}


func get_render_summary() -> Dictionary:
	return {
		"surface_cells": gm_surface.get_used_cells().size(),
		"cliff_cells": gm_cliffs.get_used_cells().size(),
		"ramp_cells": gm_ramps.get_used_cells().size(),
		"blocker_cells": gm_blockers.get_used_cells().size(),
		"debug_overlay_markers": get_debug_overlay_marker_count(),
		"nav_debug_markers": get_navigation_debug_marker_count(),
	}


func _apply_main_base() -> void:
	map_data.fill_rect_surface_type(12, 12, 28, 28, TerrainDefs.SurfaceType.BASE_PAD)
	map_data.fill_rect_flags(12, 12, 28, 28, true, true)


func _apply_natural_expansion() -> void:
	map_data.fill_rect_surface_type(78, 24, 22, 18, TerrainDefs.SurfaceType.BASE_PAD)
	map_data.fill_rect_flags(78, 24, 22, 18, true, true)


func _apply_raised_plateau() -> void:
	map_data.raise_plateau(50, 72, 24, 20, 1)
	map_data.fill_rect_surface_type(50, 72, 24, 20, TerrainDefs.SurfaceType.PLATEAU_ROCK)
	map_data.fill_rect_flags(50, 72, 24, 20, true, false)


func _apply_plateau_ramp() -> void:
	for ramp_z: int in range(80, 84):
		map_data.set_cell_ramp_dir(73, ramp_z, TerrainDefs.RampDirection.WEST)


func _apply_choke() -> void:
	map_data.fill_rect_surface_type(46, 42, 20, 18, TerrainDefs.SurfaceType.ROUGH_GROUND)
	map_data.fill_rect_flags(46, 42, 20, 18, true, false)
	map_data.place_blocker_rect(46, 42, 8, 18, TerrainDefs.BlockerType.ROCKS)
	map_data.place_blocker_rect(58, 42, 8, 18, TerrainDefs.BlockerType.ROCKS)


func _configure_gridmaps() -> void:
	var gridmaps: Array[GridMap] = [gm_surface, gm_cliffs, gm_ramps, gm_blockers]
	for gridmap: GridMap in gridmaps:
		gridmap.mesh_library = TERRAIN_MESH_LIBRARY
		gridmap.cell_size = Vector3(
			TerrainDefs.CELL_SIZE_XZ_METERS,
			TerrainDefs.HEIGHT_STEP_METERS,
			TerrainDefs.CELL_SIZE_XZ_METERS
		)
		gridmap.bake_navigation = false
