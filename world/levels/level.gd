@tool
extends Node3D
class_name Level

const TerrainManagerScript = preload("res://world/terrain/terrain_manager/terrain_manager.gd")
const TerrainScannerScript = preload("res://world/terrain/terrain_scanner/terrain_scanner.gd")
const TerrainMapResource = preload("res://world/terrain/terrain_data/terrain_map_resource.gd")

# Assign a pre-baked .tres to skip the GridMap scan at runtime.
# Leave null and the TerrainManager will scan GM_Terrain on its own _ready().
@export var terrain_resource: TerrainMapResource

@export_tool_button("Bake Terrain Data") var _bake_btn: Callable = _bake_terrain_data

@onready var terrain_manager: TerrainManagerScript = $TerrainManager as TerrainManagerScript


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_initialize_terrain()
	_on_level_ready()


func _initialize_terrain() -> void:
	# terrain_manager already scanned GM_Terrain in its own _ready().
	# Only override if a pre-baked resource is assigned (faster load, no scan).
	if terrain_resource == null or not terrain_resource.is_valid():
		return
	terrain_manager.map_data = terrain_resource.to_map_data()
	terrain_manager.map_width = terrain_resource.map_width
	terrain_manager.map_height = terrain_resource.map_height
	terrain_manager.rebuild_navigation()


func _on_level_ready() -> void:
	pass


func is_buildable(x: int, z: int) -> bool:
	if terrain_manager == null or terrain_manager.map_data == null:
		return false
	var cell: Variant = terrain_manager.map_data.get_cell(x, z)
	return cell != null and cell.buildable


func is_walkable(x: int, z: int) -> bool:
	if terrain_manager == null:
		return false
	return terrain_manager.is_cell_walkable(x, z)


# ── Editor bake tool ──────────────────────────────────────────────────────────

func _bake_terrain_data() -> void:
	if not Engine.is_editor_hint():
		return

	var tm: Node3D = get_node_or_null("TerrainManager") as Node3D
	if tm == null:
		push_error("Level: No 'TerrainManager' child node.")
		return

	var terrain_gm: GridMap = tm.get_node_or_null("GM_Terrain") as GridMap
	if terrain_gm == null:
		push_error("Level: TerrainManager has no GM_Terrain child.")
		return

	var scanner: TerrainScannerScript = TerrainScannerScript.new()
	var scanned: Variant = scanner.scan_from_single_gridmap(terrain_gm)
	if scanned == null:
		push_error("Level: Bake failed — GM_Terrain is empty. Generate or paint tiles first.")
		return

	var resource: TerrainMapResource = TerrainMapResource.new()
	resource.populate_from_map_data(scanned)

	if scene_file_path.is_empty():
		push_error("Level: Save the scene before baking.")
		return

	var save_path: String = scene_file_path.get_base_dir().path_join("terrain_data.tres")
	var err: int = ResourceSaver.save(resource, save_path)
	if err != OK:
		push_error("Level: ResourceSaver.save failed (error %d) → %s" % [err, save_path])
		return

	terrain_resource = load(save_path) as TerrainMapResource
	print("Level: Baked %dx%d terrain → %s" % [resource.map_width, resource.map_height, save_path])
