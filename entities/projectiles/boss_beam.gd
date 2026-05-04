class_name BossBeam extends Beam

@export var beam_color := Color(1.0, 0.12, 0.08, 1.0)

func setup(stats: Dictionary) -> void:
	super(stats)
	if animated_beam:
		animated_beam.modulate = stats.get("color", beam_color)

