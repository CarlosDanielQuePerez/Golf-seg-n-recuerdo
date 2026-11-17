shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// Césped con franjas de corte, green alrededor del hoyo y tierra en los costados.
uniform vec3 grass_a : source_color = vec3(0.29, 0.62, 0.25);
uniform vec3 grass_b : source_color = vec3(0.25, 0.55, 0.21);
uniform vec3 green_col : source_color = vec3(0.42, 0.76, 0.34);
uniform vec3 dirt_col : source_color = vec3(0.50, 0.33, 0.20);
uniform vec3 dirt_dark : source_color = vec3(0.36, 0.23, 0.14);
uniform vec3 hole_pos = vec3(0.0, -999.0, 0.0);
uniform float green_radius = 4.5;
uniform float stripe_scale = 0.22;
varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float up = abs(wnorm.y);
	float n = hash(floor(wpos.xz * 3.0)) * 0.025;
	float stripe = step(0.5, fract((wpos.x + wpos.z) * stripe_scale));
	vec3 g = mix(grass_a, grass_b, stripe) + n - 0.03;
	float d = distance(wpos.xz, hole_pos.xz);
	if (abs(wpos.y - hole_pos.y) < 1.5) {
		float ring = smoothstep(green_radius, green_radius - 0.25, d);
		float rings = step(0.5, fract(d * 0.9)) * 0.03;
		g = mix(g, green_col + rings + n * 0.5, ring);
	}
	float layers = step(0.5, fract(wpos.y * 1.6 + hash(floor(wpos.xz)) * 0.2));
	vec3 side = mix(dirt_col, dirt_dark, layers) + n;
	ALBEDO = mix(side, g, smoothstep(0.55, 0.8, up));
	ROUGHNESS = 1.0;
}
