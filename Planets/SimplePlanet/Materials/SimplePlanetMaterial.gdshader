shader_type spatial;

uniform float ocean_level;
uniform float max_height;
uniform bool b_detailed_textures;
uniform bool b_halo_enabled;
uniform sampler2D height_color;
uniform sampler2D grass_texture;
uniform sampler2D forest_texture;
uniform sampler2D rock_texture;
uniform sampler2D sand_texture;
uniform sampler2D snow_texture;

uniform float atmosphere_density = 0.001;
uniform vec3 atmosphere_color = vec3(0.5, 0.5, 1.0);
uniform float sun_intensity = 1.0;
uniform vec3 sun_direction = vec3(0.0, 0.0, 1.0);

varying float world_height;
varying vec3 world_pos;
varying vec3 normal;

uniform vec3 water_albedo : source_color;
uniform vec3 water_albedo2 :source_color;
uniform float water_metallic : hint_range(0.0, 1.0, 0.1) = 0;
uniform float water_roughness : hint_range(0.0, 1.0, 0.01) = 0.02;
uniform sampler2D water_texture_normal;
uniform sampler2D water_texture_normal2;
uniform vec2 water_wave_direction = vec2(1.5, 0.0);
uniform vec2 water_wave_direction2 = vec2(0.0, 1.0);
uniform float water_time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;

float fresnel(float amount, vec3 fresnel_normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(fresnel_normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
    world_height = length(VERTEX);
	world_pos = VERTEX;
}

void fragment() {
	float distanceFromCenter = length(world_pos);
	float t = (world_height - ocean_level) / (max_height - ocean_level);
	t = clamp(t, 0, 0.99);
	
	float waterLevel = mix(ocean_level, max_height, t);
	
	vec3 surfaceColor;
	
	float blendFactor = smoothstep(ocean_level - 10.0, ocean_level + 1000.0, ocean_level);
	if (waterLevel > ocean_level) {
		if (b_detailed_textures) {
			if (t < 0.23) {
	            surfaceColor = texture(sand_texture, UV).rgb;
	        } else if (t < 0.5) {
	            surfaceColor = texture(grass_texture, UV).rgb;
	        } else if (t < 0.8) {
	            surfaceColor = texture(forest_texture, UV).rgb;
	        } else if (t < 0.95) {
	            surfaceColor = texture(rock_texture, UV).rgb;
	        } else {
	            surfaceColor = texture(snow_texture, UV).rgb;
	        }
		} else {
			if (t < 0.25) {
	            surfaceColor = vec3(0.76, 0.67, 0.50);
	        } else if (t < 0.5) {
	            surfaceColor = vec3(0.34, 0.43, 0.19);
	        } else if (t < 0.75) {
	            surfaceColor = vec3(0.6, 0.46, 0.33);
	        } else if (t < 0.9) {
	            surfaceColor = vec3(0.63, 0.64, 0.64);
	        } else {
	            surfaceColor = vec3(0.87, 0.93, 0.98);
	        }
		}
		
		if (waterLevel - 10.0 < ocean_level) {
			ALBEDO = surfaceColor;
		} else {
			ALBEDO = vec3(0.0, 1.0, 0.0);
		}
		
		
	} else { 
		if (b_detailed_textures) {
			vec2 time = (TIME * water_wave_direction) * water_time_scale;
			vec2 time2 = (TIME * water_wave_direction2) * water_time_scale;

			vec3 normal_blend = mix(texture(water_texture_normal, UV + time).rgb, texture(water_texture_normal2, UV + time2).rgb, 0.5);

			float fresnel = fresnel(5.0, NORMAL, VIEW);
			vec3 surface_color = mix(water_albedo, water_albedo2, fresnel);

			ALBEDO = surface_color;
			METALLIC = water_metallic;
			ROUGHNESS = water_roughness;
			NORMAL_MAP = normal_blend;
		} else {
			ALBEDO = water_albedo;
		}
	}
}