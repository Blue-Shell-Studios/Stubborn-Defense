extends Control

@export var world_radius := 1200.0
@export var edge_padding := 7.0
@export var arrow_size := 7.0

var player_position := Vector2.ZERO

func _ready() -> void:
	SignalBus.player_position_changed.connect(_on_player_position_changed)

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var map_rect := Rect2(Vector2.ZERO, size)
	var center := size * 0.5
	var scale: float = min(size.x, size.y) / (world_radius * 2.0)

	draw_rect(map_rect, Color(0.02, 0.03, 0.06, 0.82), true)
	draw_rect(map_rect, Color(0.35, 0.55, 0.75, 0.9), false, 1.0)
	draw_circle(center, 4.0, Color(0.25, 0.78, 1.0))

	for planet in get_tree().get_nodes_in_group("minimap_planet"):
		if planet is Node2D:
			_draw_marker(planet.global_position, center, scale, Color(0.1, 0.68, 0.35), 6.0)

	for enemy in get_tree().get_nodes_in_group("minimap_enemy"):
		if enemy is Node2D:
			_draw_marker(enemy.global_position, center, scale, Color(1.0, 0.2, 0.18), 3.0)

	for boss in get_tree().get_nodes_in_group("minimap_boss"):
		if boss is Node2D:
			_draw_marker(boss.global_position, center, scale, Color(1.0, 0.12, 0.08), 5.0)

	for scrap in get_tree().get_nodes_in_group("minimap_scrap"):
		if scrap is Node2D:
			_draw_marker(scrap.global_position, center, scale, Color(1.0, 0.82, 0.22), 2.0)

func _draw_marker(world_position: Vector2, center: Vector2, scale: float, color: Color, radius: float) -> void:
	var offset := (world_position - player_position) * scale
	var max_offset: float = min(size.x, size.y) * 0.5 - edge_padding

	if offset.length() > max_offset:
		_draw_edge_arrow(offset, center, color)
		return

	draw_circle(center + offset, radius, color)

func _draw_edge_arrow(offset: Vector2, center: Vector2, color: Color) -> void:
	if offset == Vector2.ZERO:
		return

	var direction := offset.normalized()
	var half_size := size * 0.5 - Vector2(edge_padding, edge_padding)
	var edge_distance := INF
	if not is_zero_approx(direction.x):
		edge_distance = min(edge_distance, half_size.x / absf(direction.x))
	if not is_zero_approx(direction.y):
		edge_distance = min(edge_distance, half_size.y / absf(direction.y))

	var arrow_center := center + direction * maxf(edge_distance - arrow_size, 0.0)
	var side := Vector2(-direction.y, direction.x)
	var points := PackedVector2Array([
		arrow_center + direction * arrow_size,
		arrow_center - direction * arrow_size * 0.75 + side * arrow_size * 0.65,
		arrow_center - direction * arrow_size * 0.75 - side * arrow_size * 0.65,
	])
	draw_colored_polygon(points, color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color(0.02, 0.03, 0.06, 0.9), 1.0)

func _on_player_position_changed(new_position: Vector2) -> void:
	player_position = new_position
