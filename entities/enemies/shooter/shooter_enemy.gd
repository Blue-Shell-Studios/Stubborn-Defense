class_name ShooterEnemy extends Enemy

@export var projectile_scene: PackedScene = preload("res://entities/projectiles/enemy_round_projectile.tscn")
@export var projectile_speed := 360.0
@export var projectile_range := 620.0
@export var projectile_spawn_distance := 22.0

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	tick_enemy(delta)

	var target := get_current_target()
	if not target:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_direction := global_position.direction_to(target.global_position)
	var target_distance := global_position.distance_to(target.global_position)

	face_direction(target_direction, delta)

	if target_distance <= attack_range:
		velocity = Vector2.ZERO
		try_attack(target)
	else:
		velocity = target_direction * move_speed

	move_and_slide()

func try_attack(target: Node2D) -> void:
	if attack_cooldown_remaining > 0.0:
		return

	var direction := global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		return

	attack_cooldown_remaining = attack_cooldown
	spawn_projectile(direction)

func spawn_projectile(direction: Vector2) -> void:
	var projectile_manager := get_tree().get_first_node_in_group("projectile_manager") as ProjectileManager
	if not projectile_manager:
		return

	projectile_manager.spawn_projectile(
		projectile_scene,
		global_position + direction * projectile_spawn_distance,
		{
			"direction": direction,
			"damage": attack_damage,
			"range": projectile_range,
			"speed": projectile_speed,
		}
	)
