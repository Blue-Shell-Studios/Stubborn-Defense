extends Node

enum State {
	MENU,
	PLAYING,
	SHOP,
	LEVEL_UP,
	WIN,
	LOSE,
}

var state: State = State.MENU

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.shop_visibility_changed.connect(_on_shop_visibility_changed)
	SignalBus.level_up_visibility_changed.connect(_on_level_up_visibility_changed)
	SignalBus.game_over_triggered.connect(func() -> void: set_state(State.LOSE))
	SignalBus.game_win_triggered.connect(func() -> void: set_state(State.WIN))

func on_stage_switched(stage_type: GameStage.Type) -> void:
	match stage_type:
		GameStage.Type.MAIN_MENU:
			set_state(State.MENU)
		GameStage.Type.GAME:
			set_state(State.PLAYING)

func set_state(next: State) -> void:
	if state == next:
		return
	state = next
	_apply_state()

func _apply_state() -> void:
	match state:
		State.MENU, State.PLAYING:
			get_tree().paused = false
		State.SHOP, State.LEVEL_UP, State.WIN, State.LOSE:
			get_tree().paused = true

func _on_shop_visibility_changed(is_visible: bool) -> void:
	# SHOP takes precedence over PLAYING, but don't override terminal states.
	if state == State.WIN or state == State.LOSE:
		return

	if is_visible:
		set_state(State.SHOP)
	else:
		# If level-up is open, keep that state.
		# Otherwise we resume gameplay.
		set_state(State.PLAYING)

func _on_level_up_visibility_changed(is_visible: bool) -> void:
	if state == State.WIN or state == State.LOSE:
		return

	if is_visible:
		set_state(State.LEVEL_UP)
	else:
		set_state(State.PLAYING)
