class_name Planet extends StaticBody2D

@export var max_health := 1000.0
@export var max_shield := 250.0
@export var shield_repair_delay := 10.0
@export var shield_repair_duration := 10.0
@export var shield_shutdown_duration := 18.0

@onready var shield_visual := get_node_or_null("Shield") as CanvasItem

var health := 0.0
var shield := 0.0
var seconds_since_damage := 0.0
var shield_active := true
var shield_shutdown_time_left := 0.0
var is_destroyed := false

func _ready() -> void:
	add_to_group("minimap_planet")
	add_to_group("planet_objective")
	health = max_health
	shield = max_shield
	update_shield_visual()
	call_deferred("emit_status")

func _process(delta: float) -> void:
	if is_destroyed:
		return

	if not shield_active:
		shield_shutdown_time_left = maxf(shield_shutdown_time_left - delta, 0.0)
		if shield_shutdown_time_left <= 0.0:
			shield_active = true
			shield = max_shield
			update_shield_visual()
		emit_status()
		return

	if shield >= max_shield:
		return

	seconds_since_damage += delta
	if seconds_since_damage < shield_repair_delay:
		return

	var repair_rate := max_shield / shield_repair_duration
	shield = minf(shield + repair_rate * delta, max_shield)
	update_shield_visual()
	emit_status()

func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	seconds_since_damage = 0.0

	var remaining_damage := amount
	if shield_active and shield > 0.0:
		var shield_damage := minf(shield, remaining_damage)
		shield -= shield_damage
		remaining_damage -= shield_damage
		if shield <= 0.0:
			break_shield()
		update_shield_visual()
	elif not shield_active:
		shield_shutdown_time_left = shield_shutdown_duration

	if remaining_damage > 0.0:
		health = maxf(health - remaining_damage, 0.0)

	emit_status()
	if health <= 0.0:
		destroy_planet()

func destroy_planet() -> void:
	is_destroyed = true
	remove_from_group("planet_objective")
	remove_from_group("minimap_planet")
	shield = 0.0
	shield_active = false
	update_shield_visual()
	SignalBus.game_over_triggered.emit()

func break_shield() -> void:
	shield = 0.0
	shield_active = false
	shield_shutdown_time_left = shield_shutdown_duration

func update_shield_visual() -> void:
	if not shield_visual:
		return

	shield_visual.visible = shield_active and shield > 0.0
	if shield_visual.visible:
		var shield_percent := shield / max_shield
		shield_visual.modulate.a = lerp(0.25, 0.75, shield_percent)

func emit_status() -> void:
	SignalBus.planet_status_changed.emit(
		health,
		max_health,
		shield,
		max_shield,
		shield_active,
		shield_shutdown_time_left,
		shield_shutdown_duration
	)
