class_name DamageText extends Node2D

@onready var label: Label = $Label

func setup(amount: float, is_critical: bool) -> void:
	var display_amount := roundi(amount)
	label.text = "%d!" % display_amount if is_critical else "%d" % display_amount
	label.add_theme_font_size_override("font_size", 24 if is_critical else 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.18, 1.0) if is_critical else Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 1.0))
	label.add_theme_constant_override("outline_size", 3 if is_critical else 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	scale = Vector2(1.25, 1.25) if is_critical else Vector2.ONE
	z_index = 1000

	var float_distance := 62.0 if is_critical else 44.0
	var side_drift := randf_range(-14.0, 14.0)
	var duration := 0.7 if is_critical else 0.55

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(side_drift, -float_distance), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.65).set_delay(duration * 0.35)
	if is_critical:
		tween.tween_property(self, "scale", Vector2(1.55, 1.55), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished
	queue_free()
