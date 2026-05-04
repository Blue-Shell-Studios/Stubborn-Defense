extends CanvasLayer

@onready var shop_hint_label: Label = %ShopHintLabel
@onready var revive_countdown_label: Label = %ReviveCountdownLabel
@onready var game_over_button: Button = %GameOverButton
@onready var game_win_button: Button = %GameWinButton
@onready var cinematic_label: Label = %CinematicLabel
@onready var damage_vignette: ColorRect = %DamageVignette

var _cinematic_tween: Tween
var _hit_vignette_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.shop_available_changed.connect(_on_shop_available_changed)
	SignalBus.player_revive_countdown_changed.connect(_on_player_revive_countdown_changed)
	SignalBus.game_over_triggered.connect(_on_game_over_triggered)
	SignalBus.game_win_triggered.connect(_on_game_win_triggered)
	SignalBus.cinematic_message_requested.connect(_on_cinematic_message_requested)
	SignalBus.player_hit.connect(_on_player_hit)
	game_over_button.pressed.connect(_on_game_over_button_pressed)
	game_win_button.pressed.connect(_on_game_win_button_pressed)
	shop_hint_label.visible = false
	revive_countdown_label.visible = false
	game_over_button.visible = false
	game_win_button.visible = false
	cinematic_label.visible = false
	if damage_vignette:
		damage_vignette.visible = true
		_set_vignette_intensity(0.0)
	SignalBus.player_stats_requested.emit()

func _on_shop_available_changed(is_available: bool) -> void:
	shop_hint_label.visible = is_available

func _on_player_revive_countdown_changed(seconds_left: int) -> void:
	revive_countdown_label.visible = seconds_left > 0
	revive_countdown_label.text = "Player reviving in %d..." % seconds_left

func _on_game_over_triggered() -> void:
	revive_countdown_label.visible = false
	game_over_button.visible = true
	get_tree().paused = true

func _on_game_over_button_pressed() -> void:
	get_tree().paused = false
	GameStateManager.switch_stage(GameStage.Type.MAIN_MENU)

func _on_game_win_triggered() -> void:
	revive_countdown_label.visible = false
	game_win_button.visible = true
	get_tree().paused = true

func _on_game_win_button_pressed() -> void:
	get_tree().paused = false
	GameStateManager.switch_stage(GameStage.Type.MAIN_MENU)

func _on_cinematic_message_requested(message: String, duration: float) -> void:
	if _cinematic_tween:
		_cinematic_tween.kill()

	cinematic_label.text = message
	cinematic_label.visible = true
	cinematic_label.modulate = Color(1, 1, 1, 0.0)

	_cinematic_tween = create_tween()
	_cinematic_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_cinematic_tween.tween_property(cinematic_label, "modulate:a", 1.0, 0.25)
	_cinematic_tween.tween_interval(maxf(0.1, duration))
	_cinematic_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_cinematic_tween.tween_property(cinematic_label, "modulate:a", 0.0, 0.35)
	_cinematic_tween.tween_callback(func() -> void:
		cinematic_label.visible = false
	)

func _on_player_hit(damage: float) -> void:
	if not damage_vignette:
		return

	if _hit_vignette_tween:
		_hit_vignette_tween.kill()

	# Stronger flash for bigger hits, capped.
	var peak := clampf(0.55 + damage * 0.03, 0.55, 1.0)
	damage_vignette_intensity = peak

	_hit_vignette_tween = create_tween()
	_hit_vignette_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hit_vignette_tween.tween_property(self, "damage_vignette_intensity", 0.0, 0.45)

var damage_vignette_intensity := 0.0:
	set(value):
		damage_vignette_intensity = clampf(value, 0.0, 1.0)
		_set_vignette_intensity(damage_vignette_intensity)

func _set_vignette_intensity(value: float) -> void:
	if not damage_vignette:
		return

	var mat := damage_vignette.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", clampf(value, 0.0, 1.0))
	else:
		# Some scenes may have the material assigned via material_override.
		var override_mat := damage_vignette.material_override as ShaderMaterial
		if override_mat:
			override_mat.set_shader_parameter("intensity", clampf(value, 0.0, 1.0))
