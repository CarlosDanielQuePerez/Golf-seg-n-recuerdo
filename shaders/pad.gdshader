shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
// Disco brillante animado (pads de gravedad / turbo)
uniform vec3 color : source_color = vec3(0.7, 0.3, 1.0);
uniform float arrows = 0.0;

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float rings = 0.5 + 0.5 * sin(r * 18.0 - TIME * 6.0);
	float a = (1.0 - smoothstep(0.85, 1.0, r)) * (0.35 + 0.65 * rings);
	if (arrows > 0.5) {
		float chev = step(0.5, fract(UV.y * 3.0 + abs(uv.x) * 2.0 - TIME * 1.5));
		a = chev * (1.0 - smoothstep(0.45, 0.5, abs(uv.x)));
	}
	ALBEDO = color * a * 1.6;
	ALPHA = a;
}
