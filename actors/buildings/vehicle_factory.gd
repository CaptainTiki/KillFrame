extends BuildingBase


func _configure_production() -> void:
	if _production_component == null:
		return

	_production_component.clear_offers()
	_production_component.register_offer({
		"action_id": "train_scout",
		"unit_id": "scout",
		"verb": "Assemble",
		"status_label": "Assembling",
	})
