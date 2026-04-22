extends RefCounted
class_name MissionHudStyling

const HUD_BG: Color = Color(0.03, 0.08, 0.14, 0.95)
const HUD_PANEL_BG: Color = Color(0.05, 0.11, 0.18, 0.94)
const HUD_PANEL_ALT_BG: Color = Color(0.04, 0.09, 0.15, 0.92)
const HUD_TILE_BG: Color = Color(0.07, 0.14, 0.23, 0.96)
const HUD_TILE_HOVER_BG: Color = Color(0.1, 0.2, 0.31, 0.98)
const HUD_TILE_PRESSED_BG: Color = Color(0.05, 0.11, 0.18, 0.98)
const HUD_TILE_DISABLED_BG: Color = Color(0.04, 0.08, 0.12, 0.72)
const HUD_ACCENT: Color = Color(0.18, 0.87, 1.0, 1.0)
const HUD_ACCENT_SOFT: Color = Color(0.14, 0.56, 0.72, 1.0)
const HUD_TEXT_PRIMARY: Color = Color(0.88, 0.97, 1.0, 1.0)
const HUD_TEXT_MUTED: Color = Color(0.63, 0.79, 0.88, 1.0)


static func apply_panel_style(panel: PanelContainer, background: Color, border: Color, border_width: int, corner_radius: int) -> void:
	if panel != null:
		panel.add_theme_stylebox_override("panel", make_stylebox(background, border, border_width, corner_radius))


static func apply_progress_bar_style(progress_bar: ProgressBar) -> void:
	if progress_bar == null:
		return

	progress_bar.add_theme_stylebox_override("background", make_stylebox(HUD_TILE_DISABLED_BG, HUD_ACCENT_SOFT.darkened(0.45), 1, 7))
	progress_bar.add_theme_stylebox_override("fill", make_stylebox(HUD_ACCENT, HUD_ACCENT, 1, 7))
	progress_bar.add_theme_color_override("font_color", HUD_TEXT_PRIMARY)


static func style_action_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", make_stylebox(HUD_TILE_BG, HUD_ACCENT_SOFT, 1, 8))
	button.add_theme_stylebox_override("hover", make_stylebox(HUD_TILE_HOVER_BG, HUD_ACCENT, 1, 8))
	button.add_theme_stylebox_override("pressed", make_stylebox(HUD_TILE_PRESSED_BG, HUD_ACCENT, 1, 8))
	button.add_theme_stylebox_override("disabled", make_stylebox(HUD_TILE_DISABLED_BG, HUD_ACCENT_SOFT.darkened(0.45), 1, 8))
	button.add_theme_stylebox_override("focus", make_stylebox(HUD_TILE_HOVER_BG, HUD_ACCENT, 1, 8))


static func make_stylebox(background: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = background
	style_box.border_color = border
	style_box.set_border_width_all(border_width)
	style_box.set_corner_radius_all(corner_radius)
	return style_box
