class_name BossEnemy extends Enemy

@export var red_ball_scene: PackedScene = preload("res://entities/projectiles/boss_red_ball_projectile.tscn")
@export var red_beam_scene: PackedScene = preload("res://entities/projectiles/boss_beam.tscn")

# Boss stops at this distance from the planet and starts firing relentlessly.
@export var siege_range := 430.0
@export var projectile_spawn_distance := 40.0

@export var red_ball_damage := 14.0
@export var red_ball_speed := 260.0
@export var red_ball_range := 1000.0
@export var red_ball_radius := 14.0
@export var red_ball_interval := 0.33

@export var beam_damage := 22.0
@export var beam_range := 540.0
@export var beam_width := 34.0
@export var beam_lifetime := 0.22
@export var beam_interval := 1.1

var _red_ball_timer := 0.0
var _beam_timer := 0.0

func _ready() -> void:
	super()
	add_to_group("boss_enemy")
	# Don't show as a regular enemy marker on the minimap.
	remove_from_group("minimap_enemy")
	add_to_group("minimap_boss")
	_emit_boss_status(true)

func get_current_target() -> Node2D:
	# Boss is a dire threat heading straight for the planet; player cannot aggro it.
	return get_tree().get_first_node_in_group("planet_objective") as Node2D

func take_damage(amount: float, is_critical: bool = false) -> void:
	super(amount, is_critical)
	_emit_boss_status(not is_destroyed)

func destroy() -> void:
	remove_from_group("minimap_boss")
	super()
	_emit_boss_status(false)

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	tick_enemy(delta)

	var target := get_current_target()
	if not target:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := global_position.direction_to(target.global_position)
	var dist := global_position.distance_to(target.global_position)

	face_direction(dir, delta)

	if dist > siege_range:
		velocity = dir * move_speed
		move_and_slide()
		return

	# Siege stance: stop and fire relentlessly.
	velocity = Vector2.ZERO
	move_and_slide()

	_red_ball_timer = maxf(_red_ball_timer - delta, 0.0)
	_beam_timer = maxf(_beam_timer - delta, 0.0)

	if _red_ball_timer <= 0.0:
		_red_ball_timer = red_ball_interval
		_fire_red_ball(dir)

	if _beam_timer <= 0.0:
		_beam_timer = beam_interval
		_fire_red_beam(dir)

func _fire_red_ball(direction: Vector2) -> void:
	var projectile_manager := get_tree().get_first_node_in_group("projectile_manager") as ProjectileManager
	if not projectile_manager:
		return
	if direction == Vector2.ZERO:
		return

	projectile_manager.spawn_projectile(
		red_ball_scene,
		global_position + direction * projectile_spawn_distance,
		{
			"direction": direction,
			"damage": red_ball_damage,
			"range": red_ball_range,
			"speed": red_ball_speed,
			"radius": red_ball_radius,
		}
	)

func _fire_red_beam(direction: Vector2) -> void:
	var projectile_manager := get_tree().get_first_node_in_group("projectile_manager") as ProjectileManager
	if not projectile_manager:
		return
	if direction == Vector2.ZERO:
		return

	projectile_manager.spawn_projectile(
		red_beam_scene,
		global_position + direction * projectile_spawn_distance,
		{
			"direction": direction,
			"damage": beam_damage,
			"is_critical": false,
			"range": beam_range,
			"width": beam_width,
			"lifetime": beam_lifetime,
			"color": Color(1.0, 0.12, 0.08, 1.0),
		}
	)

func _emit_boss_status(is_visible: bool) -> void:
	SignalBus.boss_status_changed.emit(health, max_health, is_visible)
