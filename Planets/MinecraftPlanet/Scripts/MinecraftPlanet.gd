@tool
extends MeshInstance3D

var QuadTreeScript = load("res://Planets/MinecraftPlanet/Scripts/QuadTree.gd")
var PerlinNoiseScript = load("res://Planets/MinecraftPlanet/Scripts/PerlinNoiseGenerator.gd")
var config := ConfigFile.new()

var material = ShaderMaterial.new()
var center = Vector3(0, 0, 0)
var quad_tree_nodes = {}
var time_since_last_update = 0.0
var threads = []

func create_new_planet():
	material = ShaderMaterial.new()
	material.shader = load("res://Planets/MinecraftPlanet/Shaders/MinecraftPlanetMaterial.gdshader")
	material.set_shader_parameter("ocean_level", config.get_value("terrain", "ocean_level"))
	material.set_shader_parameter("base_height", config.get_value("terrain", "base_height"))
	material.set_shader_parameter("max_height_difference", config.get_value("terrain", "max_height_difference"))
	
	material.set_shader_parameter("snowy_beach_texture_albedo", load("res://Assets/PlanetTextures/SnowyBeach/Snow006_2K-PNG_Color.png"))
	material.set_shader_parameter("snowy_beach_texture_roughness", load("res://Assets/PlanetTextures/SnowyBeach/Snow006_2K-PNG_Roughness.png"))
	material.set_shader_parameter("snowy_beach_texture_normal", load("res://Assets/PlanetTextures/SnowyBeach/Snow006_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("beach_texture_albedo", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_Color.png"))
	material.set_shader_parameter("beach_texture_roughness", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_Roughness.png"))
	material.set_shader_parameter("beach_texture_normal", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("warm_beach_texture_albedo", load("res://Assets/PlanetTextures/BeachSand/Ground034_2K-PNG_Color.png"))
	material.set_shader_parameter("warm_beach_texture_roughness", load("res://Assets/PlanetTextures/BeachSand/Ground034_2K-PNG_Roughness.png"))
	material.set_shader_parameter("warm_beach_texture_normal", load("res://Assets/PlanetTextures/BeachSand/Ground034_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("grass_texture_albedo", load("res://Assets/PlanetTextures/Grass/Grass001_2K-PNG_Color.png"))
	material.set_shader_parameter("grass_texture_normal", load("res://Assets/PlanetTextures/Grass/Grass001_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("mountain_texture_albedo", load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_Color.png"))
	material.set_shader_parameter("mountain_texture_roughness", load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_Roughness.png"))
	material.set_shader_parameter("mountain_texture_normal", load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("snowy_mountain_texture_albedo", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_Color.png"))
	material.set_shader_parameter("snowy_mountain_texture_roughness", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_Roughness.png"))
	material.set_shader_parameter("snowy_mountain_texture_normal", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("volcano_mountain_texture_albedo", load("res://Assets/PlanetTextures/VolcanoStone/Rock035_2K-PNG_Color.png"))
	material.set_shader_parameter("volcano_mountain_texture_roughness", load("res://Assets/PlanetTextures/VolcanoStone/Rock035_2K-PNG_Roughness.png"))
	material.set_shader_parameter("volcano_mountain_texture_normal", load("res://Assets/PlanetTextures/VolcanoStone/Rock035_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("b_detailed_textures", false)
	
	material.set_shader_parameter("water_albedo", Color(config.get_value("water", "water_albedo")))
	material.set_shader_parameter("water_albedo2", Color(config.get_value("water", "water_albedo2")))
	material.set_shader_parameter("water_metallic", config.get_value("water", "water_metallic"))
	material.set_shader_parameter("water_roughness", config.get_value("water", "water_roughness"))
	material.set_shader_parameter("water_wave_direction", config.get_value("water", "water_wave_direction"))
	material.set_shader_parameter("water_wave_direction2", config.get_value("water", "water_wave_direction2"))
	material.set_shader_parameter("water_time_scale", config.get_value("water", "water_time_scale"))
	material.set_shader_parameter("ocean_blend_height_distance", config.get_value("water", "ocean_blend_height_distance"))
	
	material.set_shader_parameter("lava_albedo", Color(config.get_value("lava", "lava_albedo")))
	material.set_shader_parameter("lava_albedo2", Color(config.get_value("lava", "lava_albedo2")))
	material.set_shader_parameter("lava_metallic", config.get_value("lava", "lava_metallic"))
	material.set_shader_parameter("lava_roughness", config.get_value("lava", "lava_roughness"))
	material.set_shader_parameter("lava_wave_direction", config.get_value("lava", "lava_wave_direction"))
	material.set_shader_parameter("lava_wave_direction2", config.get_value("lava", "lava_wave_direction2"))
	material.set_shader_parameter("lava_time_scale", config.get_value("lava", "lava_time_scale"))
	
	var water_texture_normal = NoiseTexture2D.new()
	water_texture_normal.seamless = true
	water_texture_normal.as_normal_map = true
	water_texture_normal.bump_strength = 1.5
	water_texture_normal.noise = FastNoiseLite.new()
	water_texture_normal.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	water_texture_normal.noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_RIDGED
	material.set_shader_parameter("water_texture_normal", water_texture_normal)
	
	var water_texture_normal2 = NoiseTexture2D.new()
	water_texture_normal2.seamless = true
	water_texture_normal2.as_normal_map = true
	water_texture_normal2.bump_strength = 1.5
	water_texture_normal2.noise = FastNoiseLite.new()
	water_texture_normal2.noise.seed = 10
	water_texture_normal2.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	water_texture_normal2.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	material.set_shader_parameter("water_texture_normal2", water_texture_normal2)
	
	var lava_texture_normal = NoiseTexture2D.new()
	lava_texture_normal.seamless = true
	lava_texture_normal.as_normal_map = true
	lava_texture_normal.bump_strength = 1.5
	lava_texture_normal.noise = FastNoiseLite.new()
	lava_texture_normal.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	lava_texture_normal.noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_RIDGED
	material.set_shader_parameter("lava_texture_normal", lava_texture_normal)
	
	var lava_texture_normal2 = NoiseTexture2D.new()
	lava_texture_normal2.seamless = true
	lava_texture_normal2.as_normal_map = true
	lava_texture_normal2.bump_strength = 1.5
	lava_texture_normal2.noise = FastNoiseLite.new()
	lava_texture_normal2.noise.seed = 10
	lava_texture_normal2.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	lava_texture_normal2.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	material.set_shader_parameter("lava_texture_normal2", lava_texture_normal2)
	
	var continentalness = PerlinNoiseScript.new("noise_continentalness")
	continentalness.add_spline_point(0.0, 0.0)
	continentalness.add_spline_point(0.4, 0.3)
	continentalness.add_spline_point(0.6, 0.4)
	continentalness.add_spline_point(0.7, 0.6)
	continentalness.add_spline_point(1.0, 1.0)
	
	var erosion = PerlinNoiseScript.new("noise_erosion")
	erosion.add_spline_point(0.0, 0.1)
	erosion.add_spline_point(0.4, 0.05)
	erosion.add_spline_point(0.6, 0.01)
	erosion.add_spline_point(0.7, 0.05)
	erosion.add_spline_point(1.0, 0.00625)
	
	var peaks_valleys = PerlinNoiseScript.new("noise_peaksValleys")
	peaks_valleys.add_spline_point(0.0, 0.0)
	peaks_valleys.add_spline_point(0.25, 0.01)
	peaks_valleys.add_spline_point(0.4, 0.05)
	peaks_valleys.add_spline_point(0.5, 0.1)
	peaks_valleys.add_spline_point(0.65, 0.05)
	peaks_valleys.add_spline_point(0.8, 0.1)
	peaks_valleys.add_spline_point(0.85, 0.1)
	peaks_valleys.add_spline_point(0.9, 0.09)
	peaks_valleys.add_spline_point(1.0, 0.1)
	
	var temperature = PerlinNoiseScript.new("noise_temperature")
	temperature.add_spline_point(0.0, 0.0)
	temperature.add_spline_point(0.3, 0.1)
	temperature.add_spline_point(0.4, 0.45)
	temperature.add_spline_point(0.6, 0.55)
	temperature.add_spline_point(0.7, 0.9)
	temperature.add_spline_point(1.0, 1.0)
	
	var perlin_noise_generators = {
		"continentalness": continentalness,
		"erosion": erosion, 
		"peaks_valleys": peaks_valleys,
		"temperature": temperature
	}
	
	# Up, Down, Left, Right, Front, Back
	var normals = [Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, 1)]
	var resolution = config.get_value("terrain", "resolution")
	var curr_side_id = 0
	for normal in normals:
		var thread = Thread.new()
		threads.append(thread)
		thread.start(_generate_side.bind({
			"normal": normal,
			"resolution": resolution,
			"curr_side_id": curr_side_id,
			"perlin_noise_generators": perlin_noise_generators
		}))
		curr_side_id += 1
		
	var finished_threads = []
	for thread in threads:
		thread.wait_to_finish()
		finished_threads.append(thread)
		
	for thread in finished_threads:
		threads.erase(thread)

func _generate_side(data):
	var normal = data["normal"]
	var resolution = data["resolution"]
	var curr_side_id = data["curr_side_id"]
	var perlin_noise_generators = data["perlin_noise_generators"]
	var side_nodes = []

	for y in range(resolution-1):
		for x in range(resolution-1):
			var mesh_generation_data = {
				"x": x,
				"y": y,
				"resolution": resolution,
				"normal": normal,
				"center_planet": center,
				"material": material,
				"range_side": 1.0/float(resolution-1),
				"low_u_coord": 0.0,
				"high_u_coord": config.get_value("planet", "uv_size"),
				"low_v_coord": 0.0,
				"high_v_coord": config.get_value("planet", "uv_size"),
				"ocean_level": config.get_value("terrain", "ocean_level"),
				"base_height": config.get_value("terrain", "base_height"),
				"max_height_difference": config.get_value("terrain", "max_height_difference"),
				"perlin_noise_generators": perlin_noise_generators,
				"equator_plane_normal": Vector3(0.0, 1.0, 0.0)
			}
			var quad_tree_node = QuadTreeScript.new(0, mesh_generation_data, self)
			call_deferred("add_child", quad_tree_node)
			side_nodes.append(quad_tree_node)
	quad_tree_nodes[curr_side_id] = side_nodes

func randomize_planet():
	for side_id in quad_tree_nodes.keys():
		var node_list = quad_tree_nodes[side_id]
		for node in node_list:
			node.final_remove_mesh_and_collision()
			call_deferred("remove_child", node)
			
	quad_tree_nodes = {}
	create_new_planet()

func _ready():
	config.load("res://Configs/MinecraftPlanetConfig.ini")
	randomize_planet()
	
	for i in range(quad_tree_nodes.keys().size()):
		threads.append(null)

func get_nodes_loaded_count():
	var node_count = 0
	for side_id in quad_tree_nodes.keys():
		var side_nodes = quad_tree_nodes[side_id]
		for side_node in side_nodes:
			node_count += side_node.get_node_count()
	return node_count

func _process(_delta):
	if not has_node("../../Rocket"):
		return
	var camera_pos = $"../.."/Rocket.position
	$Halo.mesh.material.set_shader_parameter("playerPosition", camera_pos)
	$Halo.mesh.material.set_shader_parameter("radiusHalo", config.get_value("planet", "radius_halo"))
	$Halo.mesh.material.set_shader_parameter("sun_center", $"../.."/Sun.position)
	if camera_pos.length() < config.get_value("planet", "radius_halo"):
		$Halo.visible = true;
	else:
		$Halo.visible = false;
		
	if camera_pos.length() > config.get_value("planet", "radius_halo"):
		$HaloOutside.visible = true;
	else:
		$HaloOutside.visible = false;
		
	if get_distance_to_rocket() > config.get_value("water", "min_distance_for_good_water"):
		material.set_shader_parameter("b_detailed_textures", false)
	else:
		material.set_shader_parameter("b_detailed_textures", true)
	
	material.set_shader_parameter("sun_direction", -$"../.."/Sun.position)
	
	var i = 0
	for side_id in quad_tree_nodes.keys():
		if threads[i] == null or !threads[i].is_alive():
			if threads[i] != null:
				threads[i].wait_to_finish()  # Ensure the previous thread is completely finished
			threads[i] = Thread.new()
			var side_nodes = quad_tree_nodes[side_id]
			threads[i].start(update_side.bind(side_nodes, camera_pos))
		i += 1
		
			
func update_side(side_nodes, camera_pos):
	for i in range(len(side_nodes)):
		side_nodes[i].update_quad_tree(camera_pos)

func get_distance_to_rocket():
	var camera_pos = $"../.."/Rocket.position
	var min_distance = INF
	
	for side_id in quad_tree_nodes.keys():
		var node_list = quad_tree_nodes[side_id]
		for node in node_list:
			var distance_to_node = node.get_current_distance_from_player(camera_pos)
			min_distance = min(min_distance, distance_to_node)
	
	return min_distance
	
func _exit_tree():
	for thread in threads:
		thread.wait_to_finish()

	threads.clear()
