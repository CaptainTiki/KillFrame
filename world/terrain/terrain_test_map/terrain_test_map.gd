extends Node3D

const TerrainManagerScript = preload("res://world/terrain/terrain_manager/terrain_manager.gd")
const TraversalTestControllerScript = preload("res://units/traversal_test_controller/traversal_test_controller.gd")

@onready var _terrain_manager: TerrainManagerScript = $TerrainManager as TerrainManagerScript
@onready var _traversal_controller: TraversalTestControllerScript = $TraversalTestController as TraversalTestControllerScript
@onready var _preview_camera: Camera3D = $PreviewCamera as Camera3D
@onready var _controls_label: Label = $CanvasLayer/MarginContainer/PanelContainer/VBoxContainer/ControlsLabel as Label
@onready var _inspect_label: Label = $CanvasLayer/MarginContainer/PanelContainer/VBoxContainer/InspectLabel as Label
@onready var _traversal_label: Label = $CanvasLayer/MarginContainer/PanelContainer/VBoxContainer/TraversalLabel as Label

var _hovered_cell_coords: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	_terrain_manager.initialize_map_data(128, 128)
	_terrain_manager.regenerate_sample_map()
	_position_preview_camera()
	_traversal_controller.initialize(_terrain_manager, _preview_camera)
	_refresh_debug_labels()
	_log_current_map_summary("Terrain test scene ready.")


func _unhandled_input(event: InputEvent) -> void:
	if _traversal_controller.handle_input(event):
		_refresh_debug_labels()
		return

	if event is InputEventKey:
		_handle_debug_key_input(event as InputEventKey)
		return

	if event is InputEventMouseMotion:
		_update_hovered_cell(false)
		return

	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			_update_hovered_cell(true)


func _handle_debug_key_input(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_R:
			_terrain_manager.rebuild_terrain()
			_traversal_controller.sync_after_terrain_change(false)
			_refresh_debug_labels()
			_log_current_map_summary("Terrain rebuilt from current data.")
		KEY_G:
			_terrain_manager.regenerate_sample_map()
			_traversal_controller.sync_after_terrain_change(true)
			_position_preview_camera()
			_refresh_debug_labels()
			_update_hovered_cell(false)
			_log_current_map_summary("Sample terrain regenerated and rebuilt.")
		KEY_O:
			var overlay_enabled: bool = _terrain_manager.toggle_debug_overlay()
			_refresh_debug_labels()
			print("Terrain debug overlay: %s (%d markers)." % [
				"enabled" if overlay_enabled else "disabled",
				_terrain_manager.get_debug_overlay_marker_count(),
			])


func _process(_delta: float) -> void:
	_traversal_label.text = _traversal_controller.get_status_text()


func _update_hovered_cell(print_to_log: bool) -> void:
	var cell_coords: Variant = _get_mouse_cell_coords()
	if cell_coords == null:
		_hovered_cell_coords = Vector2i(-1, -1)
		_terrain_manager.hide_debug_marker()
		_inspect_label.text = "Hover the map to inspect a terrain cell."
		return

	var hovered_cell: Vector2i = cell_coords as Vector2i
	if hovered_cell == _hovered_cell_coords and not print_to_log:
		return

	_hovered_cell_coords = hovered_cell
	var cell_info: Dictionary = _terrain_manager.get_cell_debug_info(hovered_cell.x, hovered_cell.y)
	if not bool(cell_info.get("valid", false)):
		_terrain_manager.hide_debug_marker()
		_inspect_label.text = "Mouse is outside the terrain bounds."
		return

	_terrain_manager.show_debug_marker_for_cell(hovered_cell.x, hovered_cell.y)
	_inspect_label.text = _format_cell_info_multiline(cell_info)

	if print_to_log:
		print(_format_cell_info_single_line(cell_info))


func _get_mouse_cell_coords():
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _preview_camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = _preview_camera.project_ray_normal(mouse_position)
	var ground_plane: Plane = Plane(Vector3.UP, 0.0)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
	if intersection == null:
		return null

	var world_position: Vector3 = intersection as Vector3
	var cell_coords: Vector2i = _terrain_manager.get_cell_coords_from_world(world_position)
	if not _terrain_manager.map_data.in_bounds(cell_coords.x, cell_coords.y):
		return null

	return cell_coords


func _refresh_debug_labels() -> void:
	var summary: Dictionary = _terrain_manager.get_map_summary()
	var render_summary: Dictionary = _terrain_manager.get_render_summary()
	var navigation_summary: Dictionary = _terrain_manager.get_navigation_summary()
	var controls_text: String = (
		"Terrain PASS 4 Debug\n"
		+ "R rebuilds terrain from current data\n"
		+ "G regenerates the sample map and rebuilds\n"
		+ "O toggles the walkable/buildable overlay\n"
		+ "Hover highlights a cell, left click prints it\n"
		+ "Right click moves the traversal test unit\n\n"
		+ "Map %dx%d | cells %d | blockers %d | overlay %s (%d)\n"
		+ "GridMaps surface=%d cliffs=%d ramps=%d blockers=%d\n"
		+ "Nav graph points=%d connections=%d path markers=%d"
	)
	_controls_label.text = controls_text % [
		summary["width"],
		summary["height"],
		summary["total_cells"],
		summary["blocker_cells"],
		"on" if _terrain_manager.is_debug_overlay_enabled() else "off",
		render_summary["debug_overlay_markers"],
		render_summary["surface_cells"],
		render_summary["cliff_cells"],
		render_summary["ramp_cells"],
		render_summary["blocker_cells"],
		navigation_summary["point_count"],
		navigation_summary["connection_count"],
		render_summary["nav_debug_markers"],
	]


func _log_current_map_summary(reason: String) -> void:
	var summary: Dictionary = _terrain_manager.get_map_summary()
	var render_summary: Dictionary = _terrain_manager.get_render_summary()
	var navigation_summary: Dictionary = _terrain_manager.get_navigation_summary()
	print("")
	print("=== Terrain PASS 4 Test Map ===")
	print(reason)
	print("Map initialized: %dx%d cells" % [summary["width"], summary["height"]])
	print(
		"Cells total=%d walkable=%d buildable=%d blockers=%d max_height_level=%d" % [
			summary["total_cells"],
			summary["walkable_cells"],
			summary["buildable_cells"],
			summary["blocker_cells"],
			summary["max_height_level"],
		]
	)
	print(
		"GridMaps surface=%d cliffs=%d ramps=%d blockers=%d debug_overlay=%d nav_path_markers=%d" % [
			render_summary["surface_cells"],
			render_summary["cliff_cells"],
			render_summary["ramp_cells"],
			render_summary["blocker_cells"],
			render_summary["debug_overlay_markers"],
			render_summary["nav_debug_markers"],
		]
	)
	print(
		"Navigation points=%d connections=%d success=%s" % [
			navigation_summary["point_count"],
			navigation_summary["connection_count"],
			str(navigation_summary["success"]),
		]
	)
	for probe: Dictionary in _traversal_controller.probe_preset_paths():
		var probe_cell: Vector2i = probe["target_cell"]
		print(
			"Traversal probe %s target=(%d,%d) success=%s waypoints=%d reason=%s" % [
				probe["label"],
				probe_cell.x,
				probe_cell.y,
				str(probe["success"]),
				probe["path_length"],
				probe["reason"],
			]
		)


func _format_cell_info_multiline(cell_info: Dictionary) -> String:
	var info_text: String = (
		"Cell (%d, %d)\n"
		+ "height=%d walkable=%s buildable=%s\n"
		+ "ramp_dir=%d blocker_type=%d surface_type=%d"
	)
	return info_text % [
		cell_info["x"],
		cell_info["z"],
		cell_info["height_level"],
		str(cell_info["walkable"]),
		str(cell_info["buildable"]),
		cell_info["ramp_dir"],
		cell_info["blocker_type"],
		cell_info["surface_type"],
	]


func _format_cell_info_single_line(cell_info: Dictionary) -> String:
	return "Inspect cell (%d,%d) height=%d walkable=%s buildable=%s ramp_dir=%d blocker_type=%d surface_type=%d" % [
		cell_info["x"],
		cell_info["z"],
		cell_info["height_level"],
		str(cell_info["walkable"]),
		str(cell_info["buildable"]),
		cell_info["ramp_dir"],
		cell_info["blocker_type"],
		cell_info["surface_type"],
	]


func _position_preview_camera() -> void:
	var center: Vector3 = Vector3(_terrain_manager.map_width * 0.5, 0.0, _terrain_manager.map_height * 0.5)
	var map_extent: float = float(max(_terrain_manager.map_width, _terrain_manager.map_height))
	_preview_camera.position = center + Vector3(-map_extent * 0.28, map_extent * 0.78, map_extent * 0.82)
	_preview_camera.look_at(center + Vector3(0.0, 6.0, 0.0), Vector3.UP)
