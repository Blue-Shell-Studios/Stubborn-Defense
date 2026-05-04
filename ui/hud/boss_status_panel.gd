extends PanelContainer

@onready var boss_health_bar: ProgressBar = %BossHealthBar

const BOSS_HEALTH_COLOR := Color(1.0, 0.12, 0.08, 1.0)

func _ready() -> void:
	SignalBus.boss_status_changed.connect(_on_boss_status_changed)
	_set_bar_fill_color(boss_health_bar, BOSS_HEALTH_COLOR)
	visible = false

func _on_boss_status_changed(current_health: float, max_health: float, is_visible: bool) -> void:
	visible = is_visible
	if not is_visible:
		return

	boss_health_bar.max_value = max_health
	boss_health_bar.value = current_health
	boss_health_bar.get_node("Label").text = "BOSS: %d / %d" % [roundi(current_health), roundi(max_health)]

func _set_bar_fill_color(bar: ProgressBar, color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)

