extends PanelContainer

const TIER_TEXT_COLORS := {
	0: Color.WHITE,
	1: Color(0.35, 1.0, 0.45, 1.0),
	2: Color(0.35, 0.65, 1.0, 1.0),
	3: Color(0.78, 0.38, 1.0, 1.0),
	4: Color(1.0, 0.22, 0.18, 1.0),
}
const TIER_BG_COLORS := {
	1: Color(0.03, 0.14, 0.06, 1.0),
	2: Color(0.03, 0.08, 0.18, 1.0),
	3: Color(0.12, 0.05, 0.18, 1.0),
	4: Color(0.18, 0.04, 0.03, 1.0),
}
const GOOD_COLOR := Color(0.35, 1.0, 0.45, 1.0)
const BAD_COLOR := Color(1.0, 0.25, 0.2, 1.0)
const BASE_COLOR := Color.WHITE

@onready var message_label: Label = %LevelUpMessageLabel
@onready var refresh_button: Button = %LevelUpRefreshButton
@onready var choice_buttons := [%LevelChoiceButton1, %LevelChoiceButton2, %LevelChoiceButton3, %LevelChoiceButton4]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	SignalBus.level_up_visibility_changed.connect(_on_level_up_visibility_changed)
	SignalBus.level_up_choices_changed.connect(_on_level_up_choices_changed)
	SignalBus.level_up_message_changed.connect(_on_level_up_message_changed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_button_pressed.bind(index))

func _on_level_up_visibility_changed(is_visible: bool) -> void:
	visible = is_visible

func _on_level_up_choices_changed(choices: Array, refresh_cost: int) -> void:
	refresh_button.text = "Refresh - %d Scrap" % refresh_cost
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index] as Button
		if index >= choices.size():
			button.text = "-"
			button.disabled = true
			apply_tier_to_button(button, 0)
			apply_button_text_color(button, BASE_COLOR)
			continue

		var choice: Dictionary = choices[index]
		button.disabled = false
		button.text = choice.get("summary", "")
		apply_tier_to_button(button, int(choice.get("tier", 0)))
		apply_button_text_color(button, get_modifier_text_color(choice.get("stat_modifiers", {})))

func _on_level_up_message_changed(message: String) -> void:
	message_label.text = message

func _on_refresh_button_pressed() -> void:
	SignalBus.level_up_refresh_requested.emit()

func _on_choice_button_pressed(index: int) -> void:
	SignalBus.level_up_choice_selected.emit(index)

func apply_tier_to_button(button: Button, tier: int) -> void:
	if tier <= 0:
		for style_name in ["normal", "hover", "pressed", "disabled"]:
			button.remove_theme_stylebox_override(style_name)
		return

	var bg_color: Color = TIER_BG_COLORS.get(tier, Color(0.08, 0.08, 0.1, 1.0))
	var border_color: Color = TIER_TEXT_COLORS.get(tier, BASE_COLOR)
	button.add_theme_stylebox_override("normal", create_button_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", create_button_style(bg_color.lightened(0.08), border_color))
	button.add_theme_stylebox_override("pressed", create_button_style(bg_color.darkened(0.08), border_color))
	button.add_theme_stylebox_override("disabled", create_button_style(bg_color.darkened(0.18), border_color.darkened(0.3)))

func create_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style

func apply_button_text_color(button: Button, color: Color) -> void:
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, color)

func get_modifier_text_color(stat_modifiers: Dictionary) -> Color:
	var has_upgrade := false
	for stat_key in stat_modifiers:
		var value: float = stat_modifiers[stat_key]
		if value < 0.0:
			return BAD_COLOR
		if value > 0.0:
			has_upgrade = true

	return GOOD_COLOR if has_upgrade else BASE_COLOR
