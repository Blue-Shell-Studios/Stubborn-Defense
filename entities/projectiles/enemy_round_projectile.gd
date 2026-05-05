class_name EnemyRoundProjectile extends Area2D

var direction := Vector2.RIGHT
var damage := 1.0
var speed := 360.0
var max_range := 600.0
var distance_traveled := 0.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.06, 0.03, 1.0))
	draw_arc(Vector2.ZERO, 5.5, 0.0, TAU, 24, Color(1.0, 0.35, 0.25, 1.0), 1.5)

func setup(stats: Dictionary) -> void:
	direction = (stats.get("direction", Vector2.RIGHT) as Vector2).normalized()
	damage = stats.get("damage", damage)
	speed = stats.get("speed", speed)
	max_range = stats.get("range", max_range)
	distance_traveled = 0.0

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	damage_target(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	damage_target(body)

func damage_target(target: Node) -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

	queue_free()
