class_name ProjectileManager extends Node2D

func _ready() -> void:
	add_to_group("projectile_manager")

func spawn_projectile(projectile_scene: PackedScene, spawn_position: Vector2, stats: Dictionary) -> void:
	var direction: Vector2 = stats.get("direction", Vector2.ZERO)
	if direction == Vector2.ZERO:
		return

	var projectile := projectile_scene.instantiate()
	add_child(projectile)
	projectile.global_position = spawn_position

	if projectile.has_method("setup"):
		projectile.setup(stats)
