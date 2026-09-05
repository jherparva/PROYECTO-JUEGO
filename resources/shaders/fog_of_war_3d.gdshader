shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D fog_texture : hint_default_black, filter_linear;
uniform vec4 terra_incognita_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 shroud_color : source_color = vec4(0.04, 0.05, 0.08, 0.72);

void fragment() {
	vec4 fog_sample = texture(fog_texture, UV);
	float active_vision = fog_sample.r;
	float explored = fog_sample.g;

	if (active_vision > 0.35) {
		// Visión activa actual -> Completamente Transparente
		ALPHA = 0.0;
	} else if (explored > 0.35) {
		// Penumbra / Terreno explorado sin visión activa -> Gris Oscuro Semitransparente
		ALBEDO = shroud_color.rgb;
		ALPHA = shroud_color.a;
	} else {
		// Terra Incognita (Nunca explorado) -> Negro Opaco
		ALBEDO = terra_incognita_color.rgb;
		ALPHA = terra_incognita_color.a;
	}
}
