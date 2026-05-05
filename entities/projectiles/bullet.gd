class_name Bullet extends Area2D

var direction := Vector2.RIGHT
var damage := 1.0
var is_critical := false
var speed := 900.0
var max_range := 400.0
var distance_traveled := 0.0

func setup(stats: Dictionary) -> void:
	direction = (stats.get("direction", Vector2.RIGHT) as Vector2).normalized()
	damage = stats.get("damage", damage)
	is_critical = stats.get("is_critical", is_critical)
	max_range = stats.get("range", max_range)
	speed = stats.get("speed", speed)
	distance_traveled = 0.0
	global_rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target and target.has_method("take_damage"):
		target.take_damage(damage, is_critical)

	queue_free()
