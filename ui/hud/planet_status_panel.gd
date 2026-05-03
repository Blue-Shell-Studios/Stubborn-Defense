extends PanelContainer

const PLANET_HEALTH_COLOR := Color(1.0, 0.45, 0.08, 1.0)
const PLANET_SHIELD_COLOR := Color(0.15, 0.52, 1.0, 1.0)
const PLANET_SHIELD_REPAIR_COLOR := Color(0.45, 0.48, 0.52, 1.0)

@onready var planet_health_bar: ProgressBar = %PlanetHealthBar
@onready var planet_shield_bar: ProgressBar = %PlanetShieldBar

var shield_fill_color := Color(0.0, 0.0, 0.0, 0.0)

func _ready() -> void:
	SignalBus.planet_status_changed.connect(_on_planet_status_changed)
	set_bar_fill_color(planet_health_bar, PLANET_HEALTH_COLOR)
	set_shield_fill_color(PLANET_SHIELD_COLOR)

func _on_planet_status_changed(
	current_health: float,
	max_health: float,
	current_shield: float,
	max_shield: float,
	shield_active: bool,
	shield_shutdown_time_left: float,
	shield_shutdown_duration: float
) -> void:
	planet_health_bar.max_value = max_health
	planet_health_bar.value = current_health
	planet_health_bar.get_node("Label").text = "Planet HP: %d / %d" % [roundi(current_health), roundi(max_health)]

	planet_shield_bar.max_value = max_shield
	if shield_active:
		planet_shield_bar.value = current_shield
		planet_shield_bar.get_node("Label").text = "Shield: %d / %d" % [roundi(current_shield), roundi(max_shield)]
		set_shield_fill_color(PLANET_SHIELD_COLOR)
	else:
		var repair_progress := 1.0 - shield_shutdown_time_left / maxf(shield_shutdown_duration, 0.001)
		planet_shield_bar.value = max_shield * clampf(repair_progress, 0.0, 1.0)
		planet_shield_bar.get_node("Label").text = "Shield Repairing"
		set_shield_fill_color(PLANET_SHIELD_REPAIR_COLOR)

func set_shield_fill_color(color: Color) -> void:
	if shield_fill_color == color:
		return

	shield_fill_color = color
	set_bar_fill_color(planet_shield_bar, color)

func set_bar_fill_color(bar: ProgressBar, color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)
