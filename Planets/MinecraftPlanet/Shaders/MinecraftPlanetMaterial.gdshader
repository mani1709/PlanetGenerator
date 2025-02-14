shader_type spatial;

varying vec3 vNoiseValues;
varying float world_height;
varying float temperature_random;
varying float temperature_sun_dependent;
uniform bool b_detailed_textures;

uniform vec3 water_albedo : source_color;
uniform vec3 water_albedo2 :source_color;
uniform float water_metallic : hint_range(0.0, 1.0, 0.1) = 0;
uniform float water_roughness : hint_range(0.0, 1.0, 0.01) = 0.02;
uniform sampler2D water_texture_normal;
uniform sampler2D water_texture_normal2;
uniform vec2 water_wave_direction = vec2(1.5, 0.0);
uniform vec2 water_wave_direction2 = vec2(0.0, 1.0);
uniform float water_time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float ocean_blend_height_distance = 1.0;

uniform vec3 lava_albedo : source_color;
uniform vec3 lava_albedo2 :source_color;
uniform float lava_metallic : hint_range(0.0, 1.0, 0.1) = 0;
uniform float lava_roughness : hint_range(0.0, 1.0, 0.01) = 0.02;
uniform sampler2D lava_texture_normal;
uniform sampler2D lava_texture_normal2;
uniform vec2 lava_wave_direction = vec2(1.5, 0.0);
uniform vec2 lava_wave_direction2 = vec2(0.0, 1.0);
uniform float lava_time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;

uniform sampler2D snowy_beach_texture_albedo;
uniform sampler2D snowy_beach_texture_roughness;
uniform sampler2D snowy_beach_texture_normal;

uniform sampler2D beach_texture_albedo;
uniform sampler2D beach_texture_roughness;
uniform sampler2D beach_texture_normal;

uniform sampler2D warm_beach_texture_albedo;
uniform sampler2D warm_beach_texture_roughness;
uniform sampler2D warm_beach_texture_normal;

uniform sampler2D grass_texture_albedo;
uniform sampler2D grass_texture_normal;

uniform sampler2D mountain_texture_albedo;
uniform sampler2D mountain_texture_roughness;
uniform sampler2D mountain_texture_normal;

uniform sampler2D snowy_mountain_texture_albedo;
uniform sampler2D snowy_mountain_texture_roughness;
uniform sampler2D snowy_mountain_texture_normal;

uniform sampler2D volcano_mountain_texture_albedo;
uniform sampler2D volcano_mountain_texture_roughness;
uniform sampler2D volcano_mountain_texture_normal;

uniform float base_height;
uniform float max_height_difference;
uniform float ocean_level;

float fresnel(float amount, vec3 fresnel_normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(fresnel_normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	vNoiseValues = CUSTOM0.rgb;
	world_height = CUSTOM1.r;
	temperature_random = CUSTOM0.a;
	temperature_sun_dependent = CUSTOM1.g;
}

void fragment() {
	vec3 noiseValues = vNoiseValues;

	vec3 surfaceColor = vec3(0.0, 0.0, 0.0);
	
	float temperature = (temperature_random * 0.5 + temperature_sun_dependent * 0.5) / 2.0;
	
	float blendFactor = smoothstep(ocean_level, ocean_level + ocean_blend_height_distance, world_height);
	vec3 waterColor = water_albedo;
	if (world_height > ocean_level) {
		if (noiseValues.x < 0.37) { // beach
			if (temperature < 0.2) { // cold beach
				if (b_detailed_textures) {
					surfaceColor = texture(snowy_beach_texture_albedo, UV).rgb;
					ROUGHNESS = texture(snowy_beach_texture_roughness, UV).r;
					NORMAL_MAP = texture(snowy_beach_texture_normal, UV).rgb;
				} else {
					surfaceColor = vec3(0.784, 0.788, 0.788);
				}
			} else if (temperature < 0.35) { // beach
				if (b_detailed_textures) {
					surfaceColor = texture(beach_texture_albedo, UV).rgb;
					ROUGHNESS = texture(beach_texture_roughness, UV).r;
					NORMAL_MAP = texture(beach_texture_normal, UV).rgb;
				} else {
					surfaceColor = vec3(0.612, 0.545, 0.427);
				}
			} else { // desert / warm beach?
				if (b_detailed_textures) {
					surfaceColor = texture(warm_beach_texture_albedo, UV).rgb;
					ROUGHNESS = texture(warm_beach_texture_roughness, UV).r;
					NORMAL_MAP = texture(warm_beach_texture_normal, UV).rgb;
				} else {
					surfaceColor = vec3(0.858, 0.749, 0.592);
				}
			}
		} else if (noiseValues.x < 0.45) { // grass
			if (b_detailed_textures) {
				surfaceColor = texture(grass_texture_albedo, UV).rgb;
				NORMAL_MAP = texture(grass_texture_normal, UV).rgb;
			} else {
				surfaceColor = vec3(0.373, 0.498, 0.161);
			}
		} else if (noiseValues.x < 0.57) {
			if (b_detailed_textures) { // mountain
				surfaceColor = texture(mountain_texture_albedo, UV).rgb;
				ROUGHNESS = texture(mountain_texture_roughness, UV).r;
				NORMAL_MAP = texture(mountain_texture_normal, UV).rgb;
			} else {
				surfaceColor = vec3(0.498, 0.486, 0.412);
			}
		} else { // very high
			if (temperature < 0.25) { //cold mountain / with snow
				if (b_detailed_textures) { // mountain
					surfaceColor = texture(snowy_mountain_texture_albedo, UV).rgb;
					ROUGHNESS = texture(snowy_mountain_texture_roughness, UV).r;
					NORMAL_MAP = texture(snowy_mountain_texture_normal, UV).rgb;
				} else {
					surfaceColor = vec3(0.894, 0.957, 0.988);
				}
			} else {
				if (noiseValues.x < 0.61) { // volcano base
					if (b_detailed_textures) {
						surfaceColor = texture(volcano_mountain_texture_albedo, UV).rgb;
						ROUGHNESS = texture(volcano_mountain_texture_roughness, UV).r;
						NORMAL_MAP = texture(volcano_mountain_texture_normal, UV).rgb;
					} else {
						surfaceColor = vec3(0.259, 0.306, 0.318);
					}
				} else { // lava
					if (b_detailed_textures) {
						vec2 time = (TIME * lava_wave_direction) * lava_time_scale;
						vec2 time2 = (TIME * lava_wave_direction2) * lava_time_scale;

						vec3 normal_blend = mix(texture(lava_texture_normal, UV + time).rgb, texture(lava_texture_normal2, UV + time2).rgb, 0.5);

						float fresnel = fresnel(5.0, NORMAL, VIEW);
						vec3 surface_color = mix(lava_albedo, lava_albedo2, fresnel);

						surfaceColor = surface_color;
						METALLIC = lava_metallic;
						ROUGHNESS = lava_roughness;
						NORMAL_MAP = normal_blend;
					} else {
						surfaceColor = vec3(1.0, 0.271, 0.0);
					}
				}
			}
		}
	} else {
		if (b_detailed_textures) {
			vec2 time = (TIME * water_wave_direction) * water_time_scale;
			vec2 time2 = (TIME * water_wave_direction2) * water_time_scale;

			vec3 normal_blend = mix(texture(water_texture_normal, UV + time).rgb, texture(water_texture_normal2, UV + time2).rgb, 0.5);

			float fresnel = fresnel(5.0, NORMAL, VIEW);
			
			waterColor = mix(water_albedo, water_albedo2, fresnel);
			METALLIC = water_metallic;
			ROUGHNESS = water_roughness;
			NORMAL_MAP = normal_blend;
		}
	}
	
	ALBEDO = mix(waterColor, surfaceColor, blendFactor);

	//DEBUG:
	//ALBEDO = vec3(noiseValues.y, noiseValues.y, noiseValues.y);
}