extends PanelContainer

const PLANET_HEALTH_COLOR := Color(1.0, 0.45, 0.08, 1.0)
const PLANET_SHIELD_COLOR := Color(0.15, 0.52, 1.0, 1.0)
const PLANET_SHIELD_REPAIR_COLOR := Color(0.45, 0.48, 0.52, 1.0)

@onready var planet_health_bar: ProgressBar = %PlanetHealthBar
@onready var planet_shield_bar: Control = %PlanetShieldBar
@onready var planet_shield_stack_bar: ShieldStackBar = %PlanetShieldStackBar

var shield_fill_color := Color(0.0, 0.0, 0.0, 0.0)

func _ready() -> void:
	SignalBus.planet_status_changed.connect(_on_planet_status_changed)
	set_bar_fill_color(planet_health_bar, PLANET_HEALTH_COLOR)
	# Planet shield is drawn by ShieldStackBar.

func _on_planet_status_changed(
	current_health: float,
	max_health: float,
	current_shield: float,
	max_shield: float,
	shield_active: bool,
	shield_shutdown_time_left: float,
	shield_shutdown_duration: float,
	dire_threat_active: bool,
	current_shield_mid: float,
	max_shield_mid: float,
	current_shield_outer: float,
	max_shield_outer: float
) -> void:
	planet_health_bar.max_value = max_health
	planet_health_bar.value = current_health
	planet_health_bar.get_node("Label").text = "HP: %d / %d" % [roundi(current_health), roundi(max_health)]

	planet_shield_stack_bar.set_shields(
		shield_active,
		dire_threat_active,
		current_shield,
		max_shield,
		current_shield_mid,
		max_shield_mid,
		current_shield_outer,
		max_shield_outer
	)

	var label := planet_shield_bar.get_node("Label") as Label
	if label:
		if not shield_active:
			label.text = "Shield Repairing"
		elif dire_threat_active:
			var total_current := current_shield + current_shield_mid + current_shield_outer
			var total_max := max_shield + max_shield_mid + max_shield_outer
			label.text = "Shield: %d / %d" % [roundi(total_current), roundi(total_max)]
		else:
			label.text = "Shield: %d / %d" % [roundi(current_shield), roundi(max_shield)]

func set_shield_fill_color(color: Color) -> void:
	if shield_fill_color == color:
		return

	shield_fill_color = color
	# Planet shield is rendered by ShieldStackBar now.

func set_bar_fill_color(bar: ProgressBar, color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)
