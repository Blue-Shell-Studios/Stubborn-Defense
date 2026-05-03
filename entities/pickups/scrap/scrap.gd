class_name Scrap extends Area2D

@export var value := 1
@export var suction_speed := 420.0
@export var absorb_distance := 14.0

var target_player: Player

func _ready() -> void:
	add_to_group("minimap_scrap")

func start_sucking(player: Player) -> void:
	target_player = player

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	var distance := global_position.distance_to(target_player.global_position)
	if distance <= absorb_distance:
		target_player.collect_scrap(value)
		queue_free()
		return

	global_position = global_position.move_toward(target_player.global_position, suction_speed * delta)
