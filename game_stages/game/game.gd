extends GameStage

const FodderScene := preload("res://entities/enemies/basic/fodder.tscn")
const ShooterEnemyScene := preload("res://entities/enemies/shooter/shooter_enemy.tscn")

@export var map_size := Vector2(3000.0, 3000.0)
@export var spawn_interval := 2.5
@export var initial_spawn_count := 5
@export var edge_spawn_padding := 32.0
@export_range(0.0, 1.0, 0.01) var shooter_spawn_chance := 0.25

var spawn_timer := 0.0

func _ready() -> void:
	type = Type.GAME
	randomize()
	spawn_timer = spawn_interval

	for index in range(initial_spawn_count):
		spawn_enemy()

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_interval

func spawn_enemy() -> void:
	if randf() <= shooter_spawn_chance:
		spawn_shooter()
	else:
		spawn_fodder()

func spawn_fodder() -> void:
	var fodder := FodderScene.instantiate()
	add_child(fodder)
	fodder.global_position = get_random_edge_position()

func spawn_shooter() -> void:
	var shooter := ShooterEnemyScene.instantiate()
	add_child(shooter)
	shooter.global_position = get_random_edge_position()

func get_random_edge_position() -> Vector2:
	var edge := randi_range(0, 3)

	match edge:
		0:
			return Vector2(randf_range(0.0, map_size.x), -edge_spawn_padding)
		1:
			return Vector2(map_size.x + edge_spawn_padding, randf_range(0.0, map_size.y))
		2:
			return Vector2(randf_range(0.0, map_size.x), map_size.y + edge_spawn_padding)
		_:
			return Vector2(-edge_spawn_padding, randf_range(0.0, map_size.y))
