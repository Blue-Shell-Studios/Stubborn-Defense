shader_type canvas_item;
render_mode unshaded;

uniform vec4 flash_color : source_color = vec4(1.0, 0.12, 0.08, 1.0);
uniform float thickness = 0.14; // fraction of screen from edge
uniform float softness = 0.08;  // feathering width
uniform float intensity = 0.0;  // 0..1

void fragment() {
	// distance to nearest edge in UV space [0..0.5]
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));

	// high alpha near edges, fades toward the center
	float inner = max(thickness - softness, 0.0001);
	float a = 1.0 - smoothstep(inner, thickness, edge);
	a *= clamp(intensity, 0.0, 1.0);

	COLOR = vec4(flash_color.rgb, flash_color.a * a);
}
