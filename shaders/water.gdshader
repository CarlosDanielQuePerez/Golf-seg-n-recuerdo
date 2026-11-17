shader_type spatial;
render_mode blend_mix, specular_schlick_ggx, cull_disabled;
uniform vec3 deep : source_color = vec3(0.05, 0.35, 0.55);
uniform vec3 shallow : source_color = vec3(0.25, 0.75, 0.85);
uniform float wave = 0.06;
varying vec3 wpos;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(w.x * 1.7 + TIME * 2.0) * wave + cos(w.z * 1.3 + TIME * 1.6) * wave;
	wpos = w;
}

void fragment() {
	float r = sin(wpos.x * 3.0 + TIME * 1.5) * cos(wpos.z * 2.7 - TIME * 1.2);
	float foam = smoothstep(0.85, 0.98, r);
	ALBEDO = mix(deep, shallow, 0.5 + 0.5 * r) + foam * 0.35;
	ALPHA = 0.82;
	ROUGHNESS = 0.15;
	METALLIC = 0.0;
}
