extends Enemy

@export var attack_flash_duration := 0.18

var attack_flash_remaining := 0.0

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	tick_enemy(delta)
	attack_flash_remaining = maxf(attack_flash_remaining - delta, 0.0)
	queue_redraw()

	var target := get_current_target()
	if not target:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_position := target.global_position
	var target_direction := global_position.direction_to(target_position)
	var target_distance := global_position.distance_to(target_position)

	face_direction(target_direction, delta)

	if target_distance <= attack_range:
		velocity = Vector2.ZERO
		try_attack(target)
	else:
		velocity = target_direction * move_speed

	move_and_slide()

func _draw() -> void:
	if attack_flash_remaining <= 0.0:
		return

	var alpha := attack_flash_remaining / attack_flash_duration
	draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.05, 0.02, 0.28 * alpha))
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 48, Color(1.0, 0.12, 0.06, 0.9 * alpha), 2.0)

func try_attack(target: Node2D) -> void:
	if attack_cooldown_remaining > 0.0:
		return

	attack_cooldown_remaining = attack_cooldown
	attack_flash_remaining = attack_flash_duration
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
