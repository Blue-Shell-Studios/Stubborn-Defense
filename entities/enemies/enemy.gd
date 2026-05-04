class_name Enemy extends CharacterBody2D

const ScrapScene := preload("res://entities/pickups/scrap/scrap.tscn")
const DamageTextScene := preload("res://ui/damage_text/damage_text.tscn")

@export var max_health := 50.0
@export var scrap_drop_count := 3
@export var move_speed := 130.0
@export var aggro_range := 360.0
@export var attack_range := 42.0
@export var attack_damage := 6.0
@export var attack_cooldown := 1.0
@export var rotation_speed := 8.0

@onready var vessel: Area2D = get_node_or_null("Vessel") as Area2D
@onready var body_sprite: AnimatedSprite2D = get_node_or_null("Vessel/BodySprite") as AnimatedSprite2D
@onready var vessel_collision: CollisionShape2D = get_node_or_null("Vessel/CollisionShape2D") as CollisionShape2D

var health := 0.0
var is_destroyed := false
var attack_cooldown_remaining := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("minimap_enemy")
	health = max_health
	setup_body_sprite()

func setup_body_sprite() -> void:
	if not body_sprite or not body_sprite.sprite_frames:
		return

	if body_sprite.sprite_frames.has_animation("explode"):
		body_sprite.sprite_frames.set_animation_loop("explode", false)
	if body_sprite.sprite_frames.has_animation("idle"):
		body_sprite.play("idle")
	elif body_sprite.sprite_frames.has_animation("default"):
		body_sprite.play("default")

func tick_enemy(delta: float) -> void:
	attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)

func get_current_target() -> Node2D:
	var planet := get_tree().get_first_node_in_group("planet_objective") as Node2D
	var player := get_tree().get_first_node_in_group("player_target") as Node2D

	if player and global_position.distance_to(player.global_position) <= aggro_range:
		return player

	return planet

func face_direction(direction: Vector2, delta: float) -> void:
	if not vessel or direction == Vector2.ZERO:
		return

	vessel.global_rotation = lerp_angle(vessel.global_rotation, direction.angle(), rotation_speed * delta)

func take_damage(amount: float, is_critical: bool = false) -> void:
	if is_destroyed:
		return

	spawn_damage_text(amount, is_critical)
	health -= amount
	if health <= 0.0:
		destroy()

func spawn_damage_text(amount: float, is_critical: bool) -> void:
	var damage_text := DamageTextScene.instantiate()
	var text_parent := get_tree().current_scene if get_tree().current_scene else get_parent()
	text_parent.add_child(damage_text)
	damage_text.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -18.0)
	damage_text.setup(amount, is_critical)

func destroy() -> void:
	is_destroyed = true
	remove_from_group("enemies")
	remove_from_group("minimap_enemy")
	disable_hitbox()
	call_deferred("drop_scrap", get_parent(), global_position)

	if body_sprite and body_sprite.sprite_frames and body_sprite.sprite_frames.has_animation("explode"):
		body_sprite.play("explode")
		await body_sprite.animation_finished
	else:
		await get_tree().process_frame

	queue_free()

func disable_hitbox() -> void:
	if vessel:
		vessel.set_deferred("monitorable", false)
		vessel.set_deferred("monitoring", false)
	if vessel_collision:
		vessel_collision.set_deferred("disabled", true)

func drop_scrap(drop_parent: Node, drop_position: Vector2) -> void:
	if not drop_parent:
		return

	for index in range(scrap_drop_count):
		var scrap := ScrapScene.instantiate()
		drop_parent.add_child(scrap)
		scrap.global_position = drop_position + Vector2.RIGHT.rotated(TAU * index / scrap_drop_count) * 12.0
