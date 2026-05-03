extends PanelContainer

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
			continue

		var choice: Dictionary = choices[index]
		button.disabled = false
		button.text = "Tier %d\n%s" % [
			choice["tier"],
			choice.get("summary", ""),
		]

func _on_level_up_message_changed(message: String) -> void:
	message_label.text = message

func _on_refresh_button_pressed() -> void:
	SignalBus.level_up_refresh_requested.emit()

func _on_choice_button_pressed(index: int) -> void:
	SignalBus.level_up_choice_selected.emit(index)
