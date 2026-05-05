class_name Beam extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var animated_beam: AnimatedSprite2D = $AnimatedSprite2D

var direction := Vector2.RIGHT
var damage := 1.0
var is_critical := false
var max_range := 400.0
var beam_width := 14.0
var lifetime := 0.12
var damaged_targets: Array[Node] = []

func setup(stats: Dictionary) -> void:
	direction = (stats.get("direction", Vector2.RIGHT) as Vector2).normalized()
	damage = stats.get("damage", damage)
	is_critical = stats.get("is_critical", is_critical)
	max_range = stats.get("range", max_range)
	beam_width = stats.get("width", beam_width)
	lifetime = stats.get("lifetime", lifetime)
	damaged_targets.clear()
	global_rotation = direction.angle()
	
	stretch_animated_beam()

	var shape := collision_shape.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(max_range, beam_width)
		collision_shape.position = Vector2(max_range * 0.5, 0.0)

	lifetime_timer.start(lifetime)
	call_deferred("damage_overlapping_enemies")

func stretch_animated_beam() -> void:
	if not animated_beam.sprite_frames:
		return

	var texture := animated_beam.sprite_frames.get_frame_texture(animated_beam.animation, 0)
	if not texture:
		return

	animated_beam.position = Vector2(max_range * 0.5, 0.0)
	animated_beam.rotation = PI * 0.5
	animated_beam.scale = Vector2(beam_width / texture.get_width(), max_range / texture.get_height())
	animated_beam.play()

func damage_overlapping_enemies() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(max_range, beam_width)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(global_rotation, global_position + direction * max_range * 0.5)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var hits := get_world_2d().direct_space_state.intersect_shape(query)
	for hit in hits:
		var area := hit["collider"] as Area2D
		if area:
			damage_area(area)

func damage_area(area: Area2D) -> void:
	var target := area.get_parent()
	if not target or damaged_targets.has(target):
		return

	if target.has_method("take_damage"):
		damaged_targets.append(target)
		target.take_damage(damage, is_critical)
		if is_instance_valid(SoundManager):
			SoundManager.play_sfx("projectile_hit")

func _on_area_entered(area: Area2D) -> void:
	damage_area(area)

func _on_lifetime_timer_timeout() -> void:
	queue_free()
