class_name Player extends CharacterBody2D

enum State {IDLE, MOVING}

@export var speed := 800.0
@export var acceleration := 800.0
@export var deceleration := 600.0
@export var rotation_speed := 10.0
@export var max_hp := 100.0
@export var damage_bonus_percent := 0.0
@export var attack_speed_bonus_percent := 0.0
@export_range(0.0, 1.0, 0.01) var crit_chance := 0.0
@export var crit_damage_multiplier := 1.0
@export var range := 0.0
@export var armor := 0.0
@export_range(0.0, 1.0, 0.01) var dodge := 0.0
@export var luck := 0.0
@export var max_exp := 100.0
@export var exp_growth_multiplier := 1.2
@export var exp_growth_flat := 20.0
@export var exp_gain_bonus := 0.0
@export var shop_interaction_range := 260.0
@export var revive_delay := 5.0

@export var out_of_valid_area_damage_per_second := 12.0

@onready var vessel: Area2D = $Vessel
@onready var vessel_collision: CollisionShape2D = $Vessel/CollisionShape2D
@onready var engine_sprite: AnimatedSprite2D = $Vessel/EngineSprite
@onready var body_sprite: AnimatedSprite2D = $Vessel/BodySprite
@onready var scrap_suction_area: Area2D = $ScrapSuctionArea
@onready var scrap_suction_collision: CollisionShape2D = $ScrapSuctionArea/CollisionShape2D
@onready var weapon_manager: WeaponManager = $Weapons

var state: State = State.IDLE
var num_weapons: int
var health := 100.0
var exp := 0.0
var scrap_count := 0
var level := 1
var pending_level_ups := 0
var can_open_shop := false
var is_downed := false
var _is_outside_valid_area := false

func _ready() -> void:
	add_to_group("player_target")
	health = max_hp
	SignalBus.player_stats_requested.connect(_on_player_stats_requested)
	call_deferred("emit_all_stats")

func _physics_process(delta: float) -> void:
	if is_downed:
		velocity = Vector2.ZERO
		_update_movement_visuals()
		SignalBus.player_position_changed.emit(global_position)
		return

	if _is_outside_valid_area and out_of_valid_area_damage_per_second > 0.0:
		_apply_environment_damage(out_of_valid_area_damage_per_second * delta)

	manage_movement(delta)
	move_and_slide()
	_update_movement_visuals()
	update_shop_availability()
	SignalBus.player_position_changed.emit(global_position)

func _update_movement_visuals() -> void:
	if not is_instance_valid(engine_sprite) or not engine_sprite.sprite_frames:
		return

	var is_moving := velocity.length_squared() > 400.0 # ~20px/s
	if is_moving and engine_sprite.sprite_frames.has_animation("moving"):
		engine_sprite.visible = true
		if engine_sprite.animation != &"moving" or not engine_sprite.is_playing():
			engine_sprite.play("moving")
		return

	# Idle: hide engine (default animation is a blank frame in our sheet setup).
	engine_sprite.visible = false
	if engine_sprite.sprite_frames.has_animation("default") and engine_sprite.animation != &"default":
		engine_sprite.play("default")

	if is_instance_valid(body_sprite) and body_sprite.sprite_frames:
		# Keep body on its base animation unless it's currently exploding.
		if body_sprite.animation != &"explode":
			if body_sprite.sprite_frames.has_animation("default") and body_sprite.animation != &"default":
				body_sprite.play("default")

func _unhandled_input(event: InputEvent) -> void:
	if is_downed:
		return

	if event.is_action_pressed("shop_toggle") and can_open_shop:
		SignalBus.shop_toggle_requested.emit()

func collect_scrap(value: int) -> void:
	add_scrap(value)
	gain_exp(value * get_exp_gain_multiplier())

func spend_scrap(amount: int) -> bool:
	if scrap_count < amount:
		return false

	scrap_count -= amount
	SignalBus.player_scrap_changed.emit(scrap_count)
	return true

func add_scrap(amount: int) -> void:
	scrap_count += amount
	SignalBus.player_scrap_changed.emit(scrap_count)

func gain_exp(value: float) -> void:
	exp += value
	while exp >= max_exp:
		exp -= max_exp
		level += 1
		pending_level_ups += 1
		max_exp = ceili(max_exp * exp_growth_multiplier + exp_growth_flat)
		SignalBus.player_level_changed.emit(level)

	SignalBus.player_exp_changed.emit(exp, max_exp)
	if pending_level_ups > 0:
		SignalBus.player_level_up_available.emit(level)

func get_exp_gain_multiplier() -> float:
	return 1.0 + exp_gain_bonus

func take_damage(amount: float, _is_critical: bool = false) -> void:
	if is_downed:
		return

	if randf() < dodge:
		return

	var final_damage := maxf(amount - armor, 0.0)
	if final_damage > 0.0:
		SignalBus.player_hit.emit(final_damage)
	health = maxf(health - final_damage, 0.0)
	SignalBus.player_health_changed.emit(health, max_hp)
	SignalBus.player_stats_changed.emit(get_stats_snapshot())
	if health <= 0.0:
		down_player()

func _apply_environment_damage(amount: float) -> void:
	# Environmental damage should not be dodged.
	if is_downed:
		return
	if amount <= 0.0:
		return

	var final_damage := maxf(amount - armor, 0.0)
	if final_damage <= 0.0:
		return

	SignalBus.player_hit.emit(final_damage)
	health = maxf(health - final_damage, 0.0)
	SignalBus.player_health_changed.emit(health, max_hp)
	SignalBus.player_stats_changed.emit(get_stats_snapshot())
	if health <= 0.0:
		down_player()

func heal(amount: float) -> float:
	if is_downed:
		return 0.0
	if amount <= 0.0:
		return 0.0

	var old_health := health
	health = clampf(health + amount, 0.0, max_hp)
	var healed := health - old_health
	if healed > 0.0:
		SignalBus.player_health_changed.emit(health, max_hp)
		SignalBus.player_stats_changed.emit(get_stats_snapshot())
	return healed

func down_player() -> void:
	if is_downed:
		return

	is_downed = true
	velocity = Vector2.ZERO
	can_open_shop = false
	SignalBus.shop_available_changed.emit(false)
	SignalBus.shop_visibility_changed.emit(false)
	remove_from_group("player_target")

	vessel.visible = false
	vessel.set_deferred("monitorable", false)
	vessel_collision.set_deferred("disabled", true)
	scrap_suction_area.set_deferred("monitoring", false)
	scrap_suction_collision.set_deferred("disabled", true)
	weapon_manager.set_active(false)

	var planet := get_tree().get_first_node_in_group("planet_objective") as Node2D
	if planet:
		global_position = planet.global_position
		SignalBus.player_position_changed.emit(global_position)

	await run_revive_countdown()
	revive_player()

func revive_player() -> void:
	health = max_hp
	is_downed = false
	add_to_group("player_target")

	vessel.visible = true
	vessel.set_deferred("monitorable", true)
	vessel_collision.set_deferred("disabled", false)
	scrap_suction_area.set_deferred("monitoring", true)
	scrap_suction_collision.set_deferred("disabled", false)
	weapon_manager.set_active(true)

	SignalBus.player_health_changed.emit(health, max_hp)
	SignalBus.player_stats_changed.emit(get_stats_snapshot())
	SignalBus.player_revive_countdown_changed.emit(0)

func run_revive_countdown() -> void:
	var time_left := revive_delay
	while time_left > 0.0:
		SignalBus.player_revive_countdown_changed.emit(ceili(time_left))
		await get_tree().create_timer(minf(1.0, time_left)).timeout
		time_left -= 1.0

func apply_item(item: ShopItem) -> void:
	if not item:
		return

	apply_stat_modifiers(item.get_scaled_stat_modifiers())

func resolve_level_up() -> bool:
	pending_level_ups = maxi(pending_level_ups - 1, 0)
	return pending_level_ups > 0

func apply_stat_modifiers(stat_modifiers: Dictionary) -> void:
	var old_max_hp := max_hp
	for stat_name in stat_modifiers:
		var value: float = stat_modifiers[stat_name]
		match stat_name:
			"max_hp":
				max_hp = maxf(1.0, max_hp + value)
			"damage_bonus_percent":
				damage_bonus_percent += value
			"attack_speed_bonus_percent":
				attack_speed_bonus_percent += value
			"crit_chance":
				crit_chance = clampf(crit_chance + value, 0.0, 1.0)
			"crit_damage_multiplier":
				crit_damage_multiplier = maxf(1.0, crit_damage_multiplier + value)
			"range":
				range += value
			"armor":
				armor = maxf(0.0, armor + value)
			"dodge":
				dodge = clampf(dodge + value, 0.0, 0.95)
			"speed":
				speed = maxf(50.0, speed + value)
			"luck":
				luck += value

	if max_hp > old_max_hp:
		health += max_hp - old_max_hp
	health = clampf(health, 0.0, max_hp)
	emit_all_stats()

func emit_all_stats() -> void:
	SignalBus.player_health_changed.emit(health, max_hp)
	SignalBus.player_exp_changed.emit(exp, max_exp)
	SignalBus.player_level_changed.emit(level)
	SignalBus.player_scrap_changed.emit(scrap_count)
	SignalBus.player_stats_changed.emit(get_stats_snapshot())

func get_damage_multiplier() -> float:
	return maxf(0.0, 1.0 + damage_bonus_percent / 100.0)

func get_attack_speed_multiplier() -> float:
	return maxf(0.05, 1.0 + attack_speed_bonus_percent / 100.0)

func get_stats_snapshot() -> Dictionary:
	return {
		"max_hp": max_hp,
		"damage_bonus_percent": damage_bonus_percent,
		"attack_speed_bonus_percent": attack_speed_bonus_percent,
		"crit_chance": crit_chance,
		"crit_damage_multiplier": crit_damage_multiplier,
		"range": range,
		"armor": armor,
		"dodge": dodge,
		"speed": speed,
		"luck": luck,
	}

func _on_player_stats_requested() -> void:
	emit_all_stats()

func _on_scrap_suction_area_area_entered(area: Area2D) -> void:
	if area.has_method("start_sucking"):
		area.start_sucking(self)

func update_shop_availability() -> void:
	var planet := get_tree().get_first_node_in_group("planet_objective") as Node2D
	var new_can_open_shop := planet and global_position.distance_to(planet.global_position) <= shop_interaction_range
	if new_can_open_shop == can_open_shop:
		return

	can_open_shop = new_can_open_shop
	SignalBus.shop_available_changed.emit(can_open_shop)
	if not can_open_shop:
		SignalBus.shop_visibility_changed.emit(false)

func manage_movement(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var net_force : Vector2 = Vector2.ZERO
	var stop_threshold : float = 10

	if direction == Vector2.ZERO:
		state = Player.State.IDLE
		
		if velocity.length() < stop_threshold:
			# hard stop
			velocity = Vector2.ZERO
			net_force = Vector2.ZERO
		else:
			# apply braking force
			net_force = -velocity.normalized() * deceleration
	else:
		state = State.MOVING
		# accelerate
		net_force = direction * acceleration

	velocity += net_force * delta
	
	# clamp velocity
	if velocity.length() > speed:
		velocity = velocity.normalized() * speed

	# Rotation
	if velocity.length() > 20:
		var target_angle = velocity.angle()
		vessel.global_rotation = lerp_angle(vessel.global_rotation, target_angle, rotation_speed * delta)


func _on_valid_area_area_exited(area: Area2D) -> void:
	if area == vessel:
		_is_outside_valid_area = true

func _on_bounds_area_area_exited(area: Area2D) -> void:
	if area == vessel and not is_downed:
		take_damage(health)
		down_player()


func _on_valid_area_area_entered(area: Area2D) -> void:
	if area == vessel:
		_is_outside_valid_area = false
