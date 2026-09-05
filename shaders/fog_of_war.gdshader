shader_type spatial;
render_mode unshaded, blend_mix;

uniform sampler2D fog_texture : hint_default_black, filter_linear;
uniform vec3 map_origin = vec3(-100.0, 0.0, -100.0);
uniform vec2 map_size = vec2(200.0, 200.0);
uniform vec4 unexplored_color : source_color = vec4(0.02, 0.02, 0.04, 1.0);
uniform vec4 shrouded_color : source_color = vec4(0.04, 0.04, 0.08, 0.65);

void fragment() {
	// Mapear coordenadas 3D del mundo a coordenadas UV 2D de la textura de Niebla
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = (world_pos.xz - map_origin.xz) / map_size;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	// Leer visibilidad de la textura: 0.0 = Unexplored, 0.5 = Shrouded, 1.0 = Visible
	float vis = texture(fog_texture, uv).r;

	if (vis >= 0.9) {
		ALPHA = 0.0; // Totalmente visible y transparente
	} else if (vis >= 0.4) {
		ALBEDO = shrouded_color.rgb;
		ALPHA = shrouded_color.a; // Semivisible (Gris de memoria)
	} else {
		ALBEDO = unexplored_color.rgb;
		ALPHA = unexplored_color.a; // Negro absoluto (No explorado)
	}
}
