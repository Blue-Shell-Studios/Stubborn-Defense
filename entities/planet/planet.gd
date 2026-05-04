class_name Planet extends StaticBody2D

@export var max_health := 1000.0
@export var max_shield := 250.0
@export var shield_repair_delay := 10.0
@export var shield_repair_duration := 10.0
@export var shield_shutdown_duration := 18.0

@onready var shield_visual := get_node_or_null("Shield") as CanvasItem
@onready var shield_visual_mid := get_node_or_null("ShieldMid") as CanvasItem
@onready var shield_visual_outer := get_node_or_null("ShieldOuter") as CanvasItem

# Emergency reinforcement shields (dire threat mode).
@export var dire_shield_mid_max := 250.0
@export var dire_shield_outer_max := 350.0

var health := 0.0
var shield := 0.0
var dire_shield_mid := 0.0
var dire_shield_outer := 0.0
var seconds_since_damage := 0.0
var shield_active := true
var shield_shutdown_time_left := 0.0
var is_destroyed := false
var dire_threat_active := false
var _dire_protocol_running := false
var _dire_protocol_tween: Tween
var _dire_casting_mid := false
var _dire_casting_outer := false

func _ready() -> void:
	add_to_group("minimap_planet")
	add_to_group("planet_objective")
	health = max_health
	shield = max_shield
	update_shield_visual()
	call_deferred("emit_status")

func set_dire_threat_active(active: bool) -> void:
	if dire_threat_active == active:
		return

	dire_threat_active = active
	if not active:
		dire_shield_mid = 0.0
		dire_shield_outer = 0.0
		_dire_casting_mid = false
		_dire_casting_outer = false
		_dire_protocol_running = false
		if _dire_protocol_tween:
			_dire_protocol_tween.kill()
	else:
		# Start empty and "cast" the shields in, mid then outer.
		dire_shield_mid = 0.0
		dire_shield_outer = 0.0
		call_deferred("_run_dire_protocol")
	update_shield_visual()
	emit_status()

func _run_dire_protocol() -> void:
	if _dire_protocol_running or not dire_threat_active or is_destroyed:
		return

	_dire_protocol_running = true
	SignalBus.cinematic_message_requested.emit("Dire situation. Initiating STUBBORN DEFENSE protocol.", 2.2)

	# Cast middle shield first.
	await _cast_shield_layer("mid")
	await get_tree().create_timer(0.45).timeout

	# Then cast outer shield.
	await _cast_shield_layer("outer")

	_dire_protocol_running = false

func _cast_shield_layer(layer: String) -> void:
	if not dire_threat_active or is_destroyed:
		return

	var visual: CanvasItem
	var target_value := 0.0

	if layer == "mid":
		_dire_casting_mid = true
		visual = shield_visual_mid
		target_value = dire_shield_mid_max
	elif layer == "outer":
		_dire_casting_outer = true
		visual = shield_visual_outer
		target_value = dire_shield_outer_max
	else:
		return

	if visual:
		visual.visible = true
		visual.modulate.a = 0.0
		visual.scale *= 0.92

	if _dire_protocol_tween:
		_dire_protocol_tween.kill()
	_dire_protocol_tween = create_tween()
	_dire_protocol_tween.set_parallel(true)

	# Fill the durability while the visual fades/scales in.
	var duration := 0.65
	var start_scale: Vector2 = (visual.scale if visual else Vector2.ONE)
	var end_scale: Vector2 = (start_scale / 0.92) if visual else Vector2.ONE

	if layer == "mid":
		_dire_protocol_tween.tween_property(self, "dire_shield_mid", target_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_dire_protocol_tween.tween_property(self, "dire_shield_outer", target_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_dire_protocol_tween.tween_callback(func() -> void:
		update_shield_visual()
		emit_status()
	).set_delay(0.0)

	# Keep HUD/visuals responsive during the fill.
	_dire_protocol_tween.tween_callback(func() -> void:
		update_shield_visual()
		emit_status()
	).set_delay(duration * 0.5)

	if visual:
		_dire_protocol_tween.tween_property(visual, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_dire_protocol_tween.tween_property(visual, "scale", end_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await _dire_protocol_tween.finished
	if layer == "mid":
		_dire_casting_mid = false
	elif layer == "outer":
		_dire_casting_outer = false
	update_shield_visual()
	emit_status()

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

func take_damage(amount: float, _is_critical: bool = false) -> void:
	if is_destroyed:
		return

	seconds_since_damage = 0.0

	var remaining_damage := amount

	# Dire threat mode adds 2 extra shield layers that absorb damage first.
	if dire_threat_active and remaining_damage > 0.0:
		if dire_shield_outer > 0.0:
			var outer_damage := minf(dire_shield_outer, remaining_damage)
			dire_shield_outer -= outer_damage
			remaining_damage -= outer_damage
		if remaining_damage > 0.0 and dire_shield_mid > 0.0:
			var mid_damage := minf(dire_shield_mid, remaining_damage)
			dire_shield_mid -= mid_damage
			remaining_damage -= mid_damage
		update_shield_visual()

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
	dire_shield_mid = 0.0
	dire_shield_outer = 0.0
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

	var inner_visible := shield_active and shield > 0.0
	shield_visual.visible = inner_visible
	if inner_visible:
		var shield_percent := shield / max_shield
		# Tier colors: red outermost, violet middle, blue final (innermost).
		shield_visual.modulate = Color(0.15, 0.55, 1.0, lerp(0.25, 0.75, shield_percent)) # blue

	if shield_visual_mid:
		var mid_visible := dire_threat_active and (dire_shield_mid > 0.0 or _dire_casting_mid)
		shield_visual_mid.visible = mid_visible
		if mid_visible:
			if not _dire_casting_mid:
				var mid_percent := dire_shield_mid / maxf(1.0, dire_shield_mid_max)
				shield_visual_mid.modulate = Color(0.72, 0.25, 1.0, lerp(0.20, 0.65, mid_percent)) # violet

	if shield_visual_outer:
		var outer_visible := dire_threat_active and (dire_shield_outer > 0.0 or _dire_casting_outer)
		shield_visual_outer.visible = outer_visible
		if outer_visible:
			if not _dire_casting_outer:
				var outer_percent := dire_shield_outer / maxf(1.0, dire_shield_outer_max)
				shield_visual_outer.modulate = Color(1.0, 0.12, 0.08, lerp(0.16, 0.55, outer_percent)) # red

func emit_status() -> void:
	SignalBus.planet_status_changed.emit(
		health,
		max_health,
		shield,
		max_shield,
		shield_active,
		shield_shutdown_time_left,
		shield_shutdown_duration,
		dire_threat_active,
		dire_shield_mid,
		dire_shield_mid_max,
		dire_shield_outer,
		dire_shield_outer_max
	)
