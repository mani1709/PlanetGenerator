shader_type spatial;

uniform vec3 color_light_side : source_color = vec3(0.8, 0.8, 0.8);
uniform vec3 color_dark_side : source_color = vec3(0.2, 0.2, 0.2);
uniform vec3 sun_center;
uniform vec3 moon_center;

void fragment() {
    vec3 to_sun = normalize(sun_center - moon_center);
    vec3 normal = normalize(NORMAL);
    float light_intensity = max(dot(normal, to_sun), 0.0);
    vec3 surface_color = mix(color_dark_side, color_light_side, light_intensity);
    ALBEDO = surface_color;
    ALPHA = 1.0;
}
