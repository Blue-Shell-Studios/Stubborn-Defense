class_name ShieldStackBar extends Control

# Draws the planet shield as a single bar with 1-3 stacked layers.
# Outer (red) depletes first, then mid (violet), then inner (blue).

const COLOR_INNER := Color(0.15, 0.55, 1.0, 1.0) # blue
const COLOR_MID := Color(0.72, 0.25, 1.0, 1.0) # violet
const COLOR_OUTER := Color(1.0, 0.12, 0.08, 1.0) # red
const COLOR_REPAIR := Color(0.45, 0.48, 0.52, 1.0)

@export var bg_color := Color(0.06, 0.07, 0.1, 1.0)
@export var border_color := Color(0.35, 0.55, 0.75, 0.9)
@export var border_width := 1.0

@export var anim_speed := 10.0 # higher = snappier

var shield_active := true
var dire_threat_active := false

var inner_current := 0.0
var inner_max := 1.0
var mid_current := 0.0
var mid_max := 0.0
var outer_current := 0.0
var outer_max := 0.0

var _d_inner := 0.0
var _d_mid := 0.0
var _d_outer := 0.0

func _ready() -> void:
	_d_inner = inner_current
	_d_mid = mid_current
	_d_outer = outer_current

func set_shields(
	new_shield_active: bool,
	new_dire_threat_active: bool,
	new_inner_current: float,
	new_inner_max: float,
	new_mid_current: float,
	new_mid_max: float,
	new_outer_current: float,
	new_outer_max: float
) -> void:
	shield_active = new_shield_active
	dire_threat_active = new_dire_threat_active
	inner_current = new_inner_current
	inner_max = maxf(0.001, new_inner_max)
	mid_current = new_mid_current
	mid_max = maxf(0.0, new_mid_max)
	outer_current = new_outer_current
	outer_max = maxf(0.0, new_outer_max)
	queue_redraw()

func _process(delta: float) -> void:
	var t := clampf(delta * anim_speed, 0.0, 1.0)
	_d_inner = lerpf(_d_inner, inner_current, t)
	_d_mid = lerpf(_d_mid, mid_current, t)
	_d_outer = lerpf(_d_outer, outer_current, t)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, bg_color, true)
	draw_rect(rect, border_color, false, border_width)

	if not shield_active:
		# When the base shield is down, show a muted "repair" bar.
		var total := inner_max
		var remaining := clampf(_d_inner, 0.0, inner_max)
		_draw_fill_segment(0.0, remaining, total, COLOR_REPAIR)
		return

	# Build a single stacked bar in durability-units:
	# [inner blue][mid violet][outer red]
	var total_max := inner_max
	if dire_threat_active:
		total_max = inner_max + mid_max + outer_max
	var total_remaining := clampf(_d_inner, 0.0, inner_max)
	if dire_threat_active:
		total_remaining += clampf(_d_mid, 0.0, mid_max) + clampf(_d_outer, 0.0, outer_max)

	# Draw contiguous segments from the left.
	var inner_len := clampf(_d_inner, 0.0, inner_max)
	var mid_len := clampf(_d_mid, 0.0, mid_max) if dire_threat_active else 0.0
	var outer_len := clampf(_d_outer, 0.0, outer_max) if dire_threat_active else 0.0

	var x := 0.0
	x = _draw_segment_units(x, inner_len, total_max, COLOR_INNER)
	x = _draw_segment_units(x, mid_len, total_max, COLOR_MID)
	x = _draw_segment_units(x, outer_len, total_max, COLOR_OUTER)

	# Safety: if something goes out of sync, cap to total_remaining.
	if (inner_len + mid_len + outer_len) > total_remaining + 0.5:
		pass

func _draw_segment_units(x_units: float, units: float, total_units: float, color: Color) -> float:
	if units <= 0.0:
		return x_units
	var w := size.x * (units / maxf(0.001, total_units))
	var rect := Rect2(Vector2(size.x * (x_units / maxf(0.001, total_units)), 0.0), Vector2(w, size.y))
	draw_rect(rect, color, true)
	return x_units + units

func _draw_fill_segment(start_units: float, units: float, total_units: float, color: Color) -> void:
	if units <= 0.0:
		return
	var x := size.x * (start_units / maxf(0.001, total_units))
	var w := size.x * (units / maxf(0.001, total_units))
	draw_rect(Rect2(Vector2(x, 0.0), Vector2(w, size.y)), color, true)

