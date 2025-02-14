shader_type spatial;

uniform vec3 color_day : source_color = vec3(0.2, 0.6, 0.922);

void fragment() {
	ALPHA = 0.5;
}

void light() {
	 vec3 light_direction = normalize(-LIGHT);

    float NdotL = max(dot(NORMAL, light_direction), 0.0);
    vec3 diffuse = vec3(0.2, 0.6, 0.922) * NdotL;

    DIFFUSE_LIGHT = diffuse;
}
