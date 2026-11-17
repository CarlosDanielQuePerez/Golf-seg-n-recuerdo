shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 hot : source_color = vec3(1.0, 0.85, 0.2);
uniform vec3 mid : source_color = vec3(1.0, 0.35, 0.05);
uniform vec3 crust : source_color = vec3(0.25, 0.05, 0.02);
varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(w.x * 0.8 + TIME) * 0.05;
	wpos = w;
}

void fragment() {
	vec2 p = wpos.xz * 0.6;
	float n = noise(p + vec2(TIME * 0.2, TIME * 0.13)) * 0.6 + noise(p * 2.3 - TIME * 0.3) * 0.4;
	vec3 c = mix(crust, mid, smoothstep(0.35, 0.55, n));
	c = mix(c, hot, smoothstep(0.62, 0.8, n));
	ALBEDO = c * 1.4;
}
