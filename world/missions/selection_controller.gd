extends Node
class_name MissionSelectionController

signal selection_changed(selected_entities: Array)

const DRAG_THRESHOLD_PIXELS: float = 8.0
const SELECT_TARGET_PIXEL_RADIUS: float = 42.0

var _selected_entities: Array[Node3D] = []
var _is_drag_selecting: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO

@onready var _camera_rig: MissionCameraRig = $"../CameraRig" as MissionCameraRig
@onready var _selection_box: ColorRect = $"../HUD/SelectionBox" as ColorRect


func _ready() -> void:
	_hide_selection_box()


func _process(_delta: float) -> void:
	if _prune_selected_entities():
		_emit_selection_changed()


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_start_drag_selection(mouse_event.position)
			return true
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_finish_drag_selection(mouse_event.position)
			return true

	if event is InputEventMouseMotion and _is_drag_selecting:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		_drag_current = motion_event.position
		_update_selection_box_visual()
		return true

	return false


func get_selected_entities() -> Array[Node3D]:
	var result: Array[Node3D] = []
	result.append_array(_selected_entities)
	return result


func get_selected_orderables() -> Array[Node3D]:
	var orderables: Array[Node3D] = []
	for entity: Node3D in _selected_entities:
		if not is_instance_valid(entity):
			continue
		if entity.has_method("set_move_target") or entity.has_method("set_attack_target") or entity.has_method("set_harvest_target"):
			orderables.append(entity)
	return orderables


func get_selected_builder() -> Node3D:
	for entity: Node3D in _selected_entities:
		if entity != null and is_instance_valid(entity) and entity.has_method("set_construction_target"):
			return entity
	return null


func set_selected_entities(entities: Array[Node3D]) -> void:
	for existing: Node3D in _selected_entities:
		if is_instance_valid(existing) and existing.has_method("set_selected"):
			existing.call("set_selected", false)

	_selected_entities.clear()
	for entity: Node3D in entities:
		if entity == null or not is_instance_valid(entity):
			continue
		_selected_entities.append(entity)
		if entity.has_method("set_selected"):
			entity.call("set_selected", true)

	_emit_selection_changed()


func _start_drag_selection(start_pos: Vector2) -> void:
	_is_drag_selecting = true
	_drag_start = start_pos
	_drag_current = start_pos
	_update_selection_box_visual()


func _finish_drag_selection(end_pos: Vector2) -> void:
	if not _is_drag_selecting:
		return

	_is_drag_selecting = false
	_drag_current = end_pos

	if _drag_start.distance_to(_drag_current) <= DRAG_THRESHOLD_PIXELS:
		_select_single_entity_at_mouse()
	else:
		var rect: Rect2 = Rect2(_drag_start, _drag_current - _drag_start).abs()
		_select_entities_in_screen_rect(rect)

	_hide_selection_box()


func _select_single_entity_at_mouse() -> void:
	var selectable: Node3D = null
	if _camera_rig != null:
		selectable = _camera_rig.get_target_under_mouse("player_selectables", SELECT_TARGET_PIXEL_RADIUS)

	if selectable != null:
		set_selected_entities([selectable])
		return

	set_selected_entities([])


func _select_entities_in_screen_rect(rect: Rect2) -> void:
	if _camera_rig == null:
		return

	var camera: Camera3D = _camera_rig.get_camera()
	if camera == null:
		return

	var selected: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group("player_selectables"):
		if node is not Node3D:
			continue

		var entity: Node3D = node as Node3D
		if not is_instance_valid(entity):
			continue
		if camera.is_position_behind(entity.global_position):
			continue

		var screen_pos: Vector2 = camera.unproject_position(entity.global_position)
		if rect.has_point(screen_pos):
			selected.append(entity)

	set_selected_entities(selected)


func _prune_selected_entities() -> bool:
	var changed: bool = false
	var pruned: Array[Node3D] = []
	for entity: Node3D in _selected_entities:
		if is_instance_valid(entity):
			pruned.append(entity)
		else:
			changed = true

	if changed:
		_selected_entities = pruned

	return changed


func _emit_selection_changed() -> void:
	selection_changed.emit(get_selected_entities())


func _update_selection_box_visual() -> void:
	if _selection_box == null:
		return

	var left: float = minf(_drag_start.x, _drag_current.x)
	var top: float = minf(_drag_start.y, _drag_current.y)
	var right: float = maxf(_drag_start.x, _drag_current.x)
	var bottom: float = maxf(_drag_start.y, _drag_current.y)

	_selection_box.visible = true
	_selection_box.position = Vector2(left, top)
	_selection_box.size = Vector2(right - left, bottom - top)


func _hide_selection_box() -> void:
	if _selection_box == null:
		return

	_selection_box.visible = false
	_selection_box.size = Vector2.ZERO
