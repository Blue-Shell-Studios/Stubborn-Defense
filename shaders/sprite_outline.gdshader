shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float outline_size = 1.5;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * COLOR;
	float alpha = base_color.a;

	float outline_alpha = 0.0;
	for (float x = -1.0; x <= 1.0; x += 1.0) {
		for (float y = -1.0; y <= 1.0; y += 1.0) {
			if (x == 0.0 && y == 0.0) {
				continue;
			}

			vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE * outline_size;
			outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
		}
	}

	vec4 final_outline = vec4(outline_color.rgb, outline_color.a * outline_alpha);
	COLOR = mix(final_outline, base_color, alpha);
}
