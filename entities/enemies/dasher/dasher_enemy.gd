class_name DasherEnemy extends Enemy

const OutlineShader := preload("res://shaders/sprite_outline.gdshader")

enum State { CHASE, CHARGE, DASH, RECOVER }

@export var charge_time := 0.55
@export var dash_speed := 560.0
@export var dash_distance := 240.0
@export var recover_time := 0.55

@export var hit_radius := 42.0

@export var charging_modulate := Color(1.0, 0.25, 0.22, 1.0)
@export var dash_outline_color := Color(1.0, 0.12, 0.08, 1.0)
@export var dash_outline_size := 1.8

var state := State.CHASE
var charge_remaining := 0.0
var recover_remaining := 0.0
var dash_remaining_distance := 0.0
var dash_direction := Vector2.ZERO
var dash_has_hit := false

var _dash_outline_material: ShaderMaterial

func _ready() -> void:
	super()
	_dash_outline_material = ShaderMaterial.new()
	_dash_outline_material.shader = OutlineShader
	_dash_outline_material.set_shader_parameter("outline_color", dash_outline_color)
	_dash_outline_material.set_shader_parameter("outline_size", dash_outline_size)

func on_spawn(init: Dictionary = {}) -> void:
	super(init)
	state = State.CHASE
	charge_remaining = 0.0
	recover_remaining = 0.0
	dash_remaining_distance = 0.0
	dash_direction = Vector2.ZERO
	dash_has_hit = false
	_set_charging_visuals(false)
	_set_dash_outline(false)

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	tick_enemy(delta)

	var target := get_current_target()
	if not target:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match state:
		State.CHASE:
			_set_charging_visuals(false)
			_set_dash_outline(false)

			var dir := global_position.direction_to(target.global_position)
			face_direction(dir, delta)

			var dist := global_position.distance_to(target.global_position)
			if attack_cooldown_remaining <= 0.0 and dist <= attack_range:
				_start_charge(dir)
			else:
				velocity = dir * move_speed
				update_movement_visuals()
				move_and_slide()

		State.CHARGE:
			velocity = Vector2.ZERO
			update_movement_visuals()

			var dir := global_position.direction_to(target.global_position)
			face_direction(dir, delta)

			charge_remaining = maxf(charge_remaining - delta, 0.0)
			if charge_remaining <= 0.0:
				_start_dash(dir)

		State.DASH:
			_set_charging_visuals(false)
			_set_dash_outline(true)

			if dash_direction == Vector2.ZERO:
				_end_dash()
				return

			velocity = dash_direction * dash_speed
			update_movement_visuals()
			move_and_slide()

			dash_remaining_distance = maxf(dash_remaining_distance - (dash_speed * delta), 0.0)

			# The dash always travels a fixed distance (can overshoot the target).
			# If we pass close enough during the dash, deal damage once, but do not stop early.
			if not dash_has_hit and global_position.distance_to(target.global_position) <= hit_radius:
				_try_damage_target(target)
				dash_has_hit = true

			if dash_remaining_distance <= 0.0:
				_end_dash()

		State.RECOVER:
			_set_charging_visuals(false)
			_set_dash_outline(false)
			velocity = Vector2.ZERO
			update_movement_visuals()
			move_and_slide()

			recover_remaining = maxf(recover_remaining - delta, 0.0)
			if recover_remaining <= 0.0:
				state = State.CHASE

func _start_charge(direction: Vector2) -> void:
	state = State.CHARGE
	charge_remaining = charge_time
	dash_direction = direction.normalized()
	dash_has_hit = false

	_set_dash_outline(false)
	_set_charging_visuals(true)

func _start_dash(direction: Vector2) -> void:
	state = State.DASH
	attack_cooldown_remaining = attack_cooldown

	dash_direction = direction.normalized()
	dash_remaining_distance = dash_distance
	dash_has_hit = false

	_set_charging_visuals(false)
	_set_dash_outline(true)

func _end_dash() -> void:
	state = State.RECOVER
	recover_remaining = recover_time

	_set_dash_outline(false)

func _set_charging_visuals(enabled: bool) -> void:
	if not body_sprite:
		return
	body_sprite.modulate = charging_modulate if enabled else Color.WHITE

func _set_dash_outline(enabled: bool) -> void:
	if not body_sprite:
		return

	if enabled:
		# Re-apply in case exported values changed (e.g. in editor).
		_dash_outline_material.set_shader_parameter("outline_color", dash_outline_color)
		_dash_outline_material.set_shader_parameter("outline_size", dash_outline_size)
		body_sprite.material = _dash_outline_material
	else:
		body_sprite.material = null

func _try_damage_target(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
