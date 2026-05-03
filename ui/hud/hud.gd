extends CanvasLayer

@onready var shop_hint_label: Label = %ShopHintLabel
@onready var revive_countdown_label: Label = %ReviveCountdownLabel
@onready var game_over_button: Button = %GameOverButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.shop_available_changed.connect(_on_shop_available_changed)
	SignalBus.player_revive_countdown_changed.connect(_on_player_revive_countdown_changed)
	SignalBus.game_over_triggered.connect(_on_game_over_triggered)
	game_over_button.pressed.connect(_on_game_over_button_pressed)
	shop_hint_label.visible = false
	revive_countdown_label.visible = false
	game_over_button.visible = false
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
