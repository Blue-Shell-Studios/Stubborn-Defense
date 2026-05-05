class_name BossEnemy extends Enemy

enum State { APPROACH, SIEGE }

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

# Anti-player close-range pressure (variation).
@export var player_defense_range := 360.0
@export var player_shot_damage := 7.0
@export var player_shot_speed := 520.0
@export var player_shot_range := 700.0
@export var player_shot_radius := 7.0
@export var player_shot_interval := 0.18

@export var beam_damage := 22.0
@export var beam_range := 540.0
@export var beam_width := 34.0
@export var beam_lifetime := 0.22
@export var beam_interval := 1.1

var _red_ball_timer := 0.0
var _beam_timer := 0.0
var _player_shot_timer := 0.0
var state := State.APPROACH

func _ready() -> void:
	super()
	add_to_group("boss_enemy")
	# `on_spawn` handles minimap + timers so pooling is safe.

func on_spawn(init: Dictionary = {}) -> void:
	super(init)
	state = State.APPROACH
	_red_ball_timer = 0.0
	_beam_timer = 0.0
	_player_shot_timer = 0.0

	# Don't show as a regular enemy marker on the minimap.
	remove_from_group("minimap_enemy")
	add_to_group("minimap_boss")
	add_to_group("boss_enemy")
	_emit_boss_status(true)

func on_despawn() -> void:
	remove_from_group("minimap_boss")
	remove_from_group("boss_enemy")


func get_current_target() -> Node2D:
	# Boss is a dire threat heading straight for the planet; player cannot aggro it.
	return get_tree().get_first_node_in_group("planet_objective") as Node2D

func take_damage(amount: float, is_critical: bool = false) -> void:
	super(amount, is_critical)
	_emit_boss_status(not is_destroyed)

func destroy() -> void:
	remove_from_group("minimap_boss")
	remove_from_group("boss_enemy")
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

	if state == State.APPROACH:
		if dist > siege_range:
			velocity = dir * move_speed
			update_movement_visuals()
			move_and_slide()
			return
		state = State.SIEGE

	# Siege stance: stop and fire relentlessly.
	velocity = Vector2.ZERO
	update_movement_visuals()
	move_and_slide()

	_red_ball_timer = maxf(_red_ball_timer - delta, 0.0)
	_beam_timer = maxf(_beam_timer - delta, 0.0)
	_player_shot_timer = maxf(_player_shot_timer - delta, 0.0)

	if _red_ball_timer <= 0.0:
		_red_ball_timer = red_ball_interval
		_fire_red_ball(dir)

	if _beam_timer <= 0.0:
		_beam_timer = beam_interval
		_fire_red_beam(dir)

	# If the player gets too close, pepper them with smaller shots.
	var player := get_tree().get_first_node_in_group("player_target") as Node2D
	if player and global_position.distance_to(player.global_position) <= player_defense_range:
		if _player_shot_timer <= 0.0:
			_player_shot_timer = player_shot_interval
			_fire_small_shot(global_position.direction_to(player.global_position))

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

func _fire_small_shot(direction: Vector2) -> void:
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
			"damage": player_shot_damage,
			"range": player_shot_range,
			"speed": player_shot_speed,
			"radius": player_shot_radius,
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
