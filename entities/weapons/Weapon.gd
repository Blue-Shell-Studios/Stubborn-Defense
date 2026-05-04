class_name Weapon extends Node2D

const OutlineShader := preload("res://shaders/sprite_outline.gdshader")
const TIER_OUTLINE_COLORS := {
	1: Color(0.1, 1.0, 0.25, 1.0),
	2: Color(0.15, 0.55, 1.0, 1.0),
	3: Color(0.72, 0.25, 1.0, 1.0),
	4: Color(1.0, 0.12, 0.08, 1.0),
}
const TIER_DAMAGE_MULTIPLIERS := {
	0: 1.0,
	1: 1.2,
	2: 1.5,
	3: 1.9,
	4: 2.5,
}
const TIER_COOLDOWN_MULTIPLIERS := {
	0: 1.0,
	1: 0.92,
	2: 0.82,
	3: 0.7,
	4: 0.6,
}

@export_range(0, 4, 1) var tier := 0:
	set(value):
		tier = clampi(value, 0, 4)
		update_tier_outline()
		update_cooldown_timer()
@export var weapon_id := ""
@export var display_name := "Weapon"
@export var shop_cost := 10
@export var projectile_scene: PackedScene = preload("res://entities/projectiles/bullet.tscn")
@export var damage := 5.0
@export var cooldown := 0.25:
	set(value):
		cooldown = value
		update_cooldown_timer()
@export_range(0.0, 1.0, 0.01) var critical_rate := 0.0
@export var critical_damage_multiplier := 2.0
@export var range := 300.0:
	set(value):
		range = value
		update_range_shape()
@export var projectile_speed := 900.0
@export var projectile_aoe_radius := 80.0
@export var projectile_width := 14.0
@export var projectile_lifetime := 0.12
@export var rotation_speed := 12.0

@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var output: Node2D = $Output
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	cooldown_timer.one_shot = true

	update_cooldown_timer()
	update_range_shape()
	update_tier_outline()

func _process(delta: float) -> void:
	if not is_instance_valid(range_area):
		return

	update_range_shape()
	var target := get_nearest_enemy_in_range()
	if not target:
		return

	var target_angle := global_position.angle_to_point(target.global_position)
	global_rotation = lerp_angle(global_rotation, target_angle, rotation_speed * delta)

	if cooldown_timer.is_stopped():
		fire_at(target)

func get_nearest_enemy_in_range() -> Area2D:
	var nearest_enemy: Area2D
	var nearest_distance := INF

	for area in range_area.get_overlapping_areas():
		if not area is Area2D:
			continue

		var distance := global_position.distance_squared_to(area.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = area

	return nearest_enemy

func fire_at(target: Area2D) -> void:
	var projectile_manager := get_tree().get_first_node_in_group("projectile_manager") as ProjectileManager
	if not projectile_manager:
		return

	var direction := output.global_position.direction_to(target.global_position)
	var final_damage := get_effective_damage()
	var is_critical := randf() < get_effective_critical_rate()
	if is_critical:
		final_damage *= get_effective_critical_damage_multiplier()

	projectile_manager.spawn_projectile(projectile_scene, output.global_position, get_projectile_stats(direction, final_damage, is_critical))
	cooldown_timer.start(get_effective_cooldown())

func get_projectile_stats(direction: Vector2, final_damage: float, is_critical: bool) -> Dictionary:
	return {
		"direction": direction,
		"damage": final_damage,
		"is_critical": is_critical,
		"range": get_effective_range(),
		"speed": projectile_speed,
		"aoe_radius": projectile_aoe_radius,
		"width": projectile_width,
		"lifetime": projectile_lifetime,
	}

func update_range_shape() -> void:
	if not is_node_ready():
		return

	if range_shape.shape is CircleShape2D:
		range_shape.shape.radius = get_effective_range()

func get_effective_damage() -> float:
	return damage * TIER_DAMAGE_MULTIPLIERS.get(tier, 1.0) * get_player_damage_multiplier()

func get_effective_cooldown() -> float:
	return cooldown * TIER_COOLDOWN_MULTIPLIERS.get(tier, 1.0) / get_player_attack_speed_multiplier()

func get_effective_critical_rate() -> float:
	var player := get_player()
	var player_crit_chance := player.crit_chance if player else 0.0
	return clampf(critical_rate + player_crit_chance, 0.0, 1.0)

func get_effective_critical_damage_multiplier() -> float:
	var player := get_player()
	var player_crit_multiplier := player.crit_damage_multiplier if player else 1.0
	return maxf(1.0, critical_damage_multiplier * player_crit_multiplier)

func get_effective_range() -> float:
	var player := get_player()
	var player_range := player.range if player else 0.0
	return maxf(1.0, range + player_range)

func get_player_damage_multiplier() -> float:
	var player := get_player()
	return player.get_damage_multiplier() if player else 1.0

func get_player_attack_speed_multiplier() -> float:
	var player := get_player()
	return player.get_attack_speed_multiplier() if player else 1.0

func get_player() -> Player:
	return get_tree().get_first_node_in_group("player_target") as Player

func update_cooldown_timer() -> void:
	if not is_node_ready():
		return

	cooldown_timer.wait_time = get_effective_cooldown()

func update_tier_outline() -> void:
	if not is_node_ready():
		return

	for sprite in get_visual_sprites():
		if tier <= 0:
			sprite.material = null
			continue

		var material := ShaderMaterial.new()
		material.shader = OutlineShader
		material.set_shader_parameter("outline_color", TIER_OUTLINE_COLORS.get(tier, Color.WHITE))
		sprite.material = material

func get_visual_sprites() -> Array[CanvasItem]:
	var sprites: Array[CanvasItem] = []
	collect_visual_sprites(self, sprites)
	return sprites

func collect_visual_sprites(node: Node, sprites: Array[CanvasItem]) -> void:
	for child in node.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			sprites.append(child)
			continue

		collect_visual_sprites(child, sprites)
