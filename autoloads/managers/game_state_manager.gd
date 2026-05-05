extends Node

const STAGES : Dictionary[GameStage.Type, Resource] = {
	GameStage.Type.MAIN_MENU: preload("uid://ckhr8suodxb6g"),
	GameStage.Type.GAME: preload("uid://dthbymiy3ytwv")
}

@onready var current_scene := get_tree().current_scene

var current_stage : GameStage

func _ready() -> void:
	call_deferred("_load_initial_stage")

func _load_initial_stage() -> void:
	current_scene = get_tree().current_scene
	if not current_scene:
		current_scene = get_tree().root
	switch_stage(GameStage.Type.MAIN_MENU)

func switch_stage(stage_type: GameStage.Type) ->void:
	if current_stage and current_stage.type == stage_type:
		return
	
	print("Switched to: " + str(stage_type))

	if current_stage:
		current_stage.queue_free()
	
	current_stage = STAGES[stage_type].instantiate()
	current_scene.add_child(current_stage)
	GameFlowManager.on_stage_switched(stage_type)
