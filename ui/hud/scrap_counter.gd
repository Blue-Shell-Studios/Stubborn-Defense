extends PanelContainer

@onready var scrap_label: Label = %ScrapLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.player_scrap_changed.connect(_on_player_scrap_changed)

func _on_player_scrap_changed(scrap_count: int) -> void:
	if scrap_label:
		scrap_label.text = "Scrap: %d" % scrap_count

