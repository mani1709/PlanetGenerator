shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec3 playerPosition;
uniform float radiusHalo;
uniform vec3 sun_center;
uniform vec3 color_day : source_color = vec3(0.2, 0.6, 0.922);
uniform vec3 color_sunset : source_color = vec3(1.0, 0.5, 0.0);
uniform float min_alpha = 0.0;
uniform float max_alpha = 1.0;

void fragment() {
	vec3 to_sun = normalize(sun_center);
    vec3 to_player = normalize(playerPosition);

    float angle_cos = dot(to_sun, to_player);

	vec3 atmosphere_color = color_day;

	float color_transition_start = 0.2f;
	float color_transition_end = -0.4f;
	if (angle_cos > color_transition_start) {
		atmosphere_color = color_day;
	} else if(angle_cos < color_transition_end) {
		atmosphere_color = color_sunset;
	} else {
		float mix_strength = smoothstep(color_transition_start, color_transition_end, angle_cos);
        atmosphere_color = mix(color_day, color_sunset, mix_strength);
	}


	float alpha = 0.0f;
	float alpha_transition_start = 0.1f;
	float alpha_transition_end = -0.2f;
	if (angle_cos > alpha_transition_start) {
		alpha = 1.0f;
	} else if(angle_cos < alpha_transition_end) {
		alpha = 0.0f;
	} else {
		alpha = smoothstep(alpha_transition_end, alpha_transition_start, angle_cos);
	}

    ALBEDO = atmosphere_color;
    ALPHA = alpha;
}

void light() {
	 vec3 light_direction = normalize(-LIGHT);

    float NdotL = max(dot(NORMAL, light_direction), 0.0);
    vec3 diffuse = vec3(0.2, 0.6, 0.922) * NdotL;
	
    DIFFUSE_LIGHT = diffuse;
}