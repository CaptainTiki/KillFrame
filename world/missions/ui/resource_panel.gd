extends PanelContainer
class_name MissionHudResourcePanel

@onready var _minimap_stub: PanelContainer = $MarginContainer/VBoxContainer/MiniMapStub as PanelContainer
@onready var _minimap_title: Label = $MarginContainer/VBoxContainer/MiniMapTitle as Label
@onready var _resource_label: Label = $MarginContainer/VBoxContainer/ResourceLabel as Label
@onready var _supply_label: Label = $MarginContainer/VBoxContainer/SupplyLabel as Label


func _ready() -> void:
	MissionHudStyling.apply_panel_style(self, MissionHudStyling.HUD_PANEL_ALT_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 10)
	MissionHudStyling.apply_panel_style(_minimap_stub, MissionHudStyling.HUD_TILE_DISABLED_BG, MissionHudStyling.HUD_ACCENT_SOFT, 1, 10)

	for label: Label in [_minimap_title, _resource_label, _supply_label]:
		if label != null:
			label.add_theme_color_override("font_color", MissionHudStyling.HUD_ACCENT)


func update_resources(crystals: int, bits: int, supply_used: int, supply_cap: int) -> void:
	_resource_label.text = "Crystals: %d   Bits: %d" % [crystals, bits]
	_supply_label.text = "Supply: %d / %d" % [supply_used, supply_cap]
