shader_type spatial;
render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 color = vec3(1.0, 0.92, 0.016);
    ALBEDO = color;
}
