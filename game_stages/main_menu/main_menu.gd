extends GameStage

@onready var start_screen: Control = $StartScreen

func _ready() -> void:
	type = Type.MAIN_MENU
	#get_viewport().size_changed.connect(update_start_screen_rect)
	#update_start_screen_rect()

func update_start_screen_rect() -> void:
	start_screen.position = Vector2.ZERO
	start_screen.size = get_viewport_rect().size

func _on_play_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("ui_click")
	GameStateManager.switch_stage(Type.GAME)

func _on_exit_button_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_sfx("ui_click")
	get_tree().quit()
