class_name Torpedo extends Area2D

var direction := Vector2.RIGHT
var damage := 1.0
var is_critical := false
var speed := 450.0
var max_range := 500.0
var explosion_radius := 80.0
var distance_traveled := 0.0
var has_exploded := false

func setup(stats: Dictionary) -> void:
	direction = (stats.get("direction", Vector2.RIGHT) as Vector2).normalized()
	damage = stats.get("damage", damage)
	is_critical = stats.get("is_critical", is_critical)
	max_range = stats.get("range", max_range)
	speed = stats.get("speed", speed)
	explosion_radius = stats.get("aoe_radius", explosion_radius)
	distance_traveled = 0.0
	has_exploded = false
	global_rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= max_range:
		explode()

func _on_area_entered(area: Area2D) -> void:
	explode()

func explode() -> void:
	if has_exploded:
		return

	has_exploded = true

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var hits := get_world_2d().direct_space_state.intersect_shape(query)
	for hit in hits:
		var area := hit["collider"] as Area2D
		if not area:
			continue

		var target := area.get_parent()
		if target and target.has_method("take_damage"):
			target.take_damage(damage, is_critical)

	queue_free()
