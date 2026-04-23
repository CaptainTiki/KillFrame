extends SceneTree


func _init() -> void:
	var root := Node3D.new()
	root.name = "GridMapSerializationProbe"

	var gridmap := GridMap.new()
	gridmap.name = "GM_Surface"
	gridmap.cell_size = Vector3(1.0, 2.0, 1.0)
	gridmap.set_cell_item(Vector3i(0, 0, 0), 0)
	gridmap.set_cell_item(Vector3i(1, 0, 0), 1)
	gridmap.set_cell_item(Vector3i(2, 1, 0), 9, gridmap.get_orthogonal_index_from_basis(Basis.from_euler(Vector3(0.0, deg_to_rad(90.0), 0.0))))
	root.add_child(gridmap)
	gridmap.owner = root

	var packed_scene := PackedScene.new()
	var pack_result: int = packed_scene.pack(root)
	if pack_result != OK:
		printerr("Failed to pack probe scene: %d" % pack_result)
		quit(pack_result)
		return

	var save_result: int = ResourceSaver.save(packed_scene, "res://tools/gridmap_serialization_probe.tscn")
	if save_result != OK:
		printerr("Failed to save probe scene: %d" % save_result)
		quit(save_result)
		return

	print("Saved probe scene to res://tools/gridmap_serialization_probe.tscn")
	quit()
