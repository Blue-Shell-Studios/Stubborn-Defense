extends PanelContainer

const PLAYER_HEALTH_COLOR := Color(0.95, 0.12, 0.1, 1.0)
const PLAYER_EXP_COLOR := Color(1.0, 0.82, 0.12, 1.0)

@onready var health_bar: ProgressBar = %HealthBar
@onready var exp_bar: ProgressBar = %ExpBar
@onready var scrap_label: Label = %ScrapLabel
@onready var level_label: Label = %LevelLabel

func _ready() -> void:
	SignalBus.player_health_changed.connect(_on_player_health_changed)
	SignalBus.player_exp_changed.connect(_on_player_exp_changed)
	SignalBus.player_level_changed.connect(_on_player_level_changed)
	SignalBus.player_scrap_changed.connect(_on_player_scrap_changed)
	set_bar_fill_color(health_bar, PLAYER_HEALTH_COLOR)
	set_bar_fill_color(exp_bar, PLAYER_EXP_COLOR)

func _on_player_health_changed(current_health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.get_node("Label").text = "HP: %d / %d" % [roundi(current_health), roundi(max_health)]

func _on_player_exp_changed(current_exp: float, max_exp: float) -> void:
	exp_bar.max_value = max_exp
	exp_bar.value = current_exp
	exp_bar.get_node("Label").text = "EXP: %d / %d" % [roundi(current_exp), roundi(max_exp)]

func _on_player_scrap_changed(scrap_count: int) -> void:
	scrap_label.text = "Scrap: %d" % scrap_count

func _on_player_level_changed(level: int) -> void:
	level_label.text = "Level: %d" % level

func set_bar_fill_color(bar: ProgressBar, color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)
