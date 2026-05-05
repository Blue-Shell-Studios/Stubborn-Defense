class_name BossRedBallProjectile extends Area2D

@export var radius := 12.0

var direction := Vector2.RIGHT
var damage := 1.0
var speed := 240.0
var max_range := 900.0
var distance_traveled := 0.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.06, 0.03, 1.0))
	draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, 28, Color(1.0, 0.35, 0.25, 1.0), 2.5)

func setup(stats: Dictionary) -> void:
	direction = (stats.get("direction", Vector2.RIGHT) as Vector2).normalized()
	damage = stats.get("damage", damage)
	speed = stats.get("speed", speed)
	max_range = stats.get("range", max_range)
	radius = stats.get("radius", radius)
	distance_traveled = 0.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	_damage_target(area.get_parent())

func _on_body_entered(body: Node2D) -> void:
	_damage_target(body)

func _damage_target(target: Node) -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

	queue_free()
