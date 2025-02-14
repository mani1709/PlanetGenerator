@tool
extends MeshInstance3D

var QuadTreeScript = load("res://Planets/SimplePlanet/Scripts/QuadTree.gd")
var planet_color = load("res://Planets/SimplePlanet/Materials/SimplePlanetGradient.tres")
var config := ConfigFile.new()

var material = ShaderMaterial.new()
var center = Vector3(0, 0, 0)
var noise_map_center = Vector3(0.0, 0.0, 0.0)
var quad_tree_nodes = {}
var time_since_last_update = 0.0
var threads = []

func create_new_planet():
	var radius = config.get_value("planet", "radius")
	var noise_function = FastNoiseLite.new()
	noise_function.noise_type = FastNoiseLite.TYPE_PERLIN
	var noise_data = {
		"noise_map_center": noise_map_center,
		"size_of_noise_map": config.get_value("planet", "size_of_noise_map")/float(radius),
		"number_of_octaves": config.get_value("planet", "number_of_octaves"),
		"noise_function": noise_function,
		"persistence": config.get_value("planet", "persistence"),
		"lacunarity": config.get_value("planet", "lacunarity"),
		"exponentiation": config.get_value("planet", "exponentiation"),
		"start_octave": config.get_value("planet", "start_octave")
	}
	
	material = ShaderMaterial.new()
	material.shader = load("res://Planets/SimplePlanet/Shaders/SimplePlanetMaterial.gdshader")
	material.set_shader_parameter("ocean_level", radius * config.get_value("planet", "water_level_relative"))
	material.set_shader_parameter("ocean_blend_height_distance", config.get_value("water", "ocean_blend_height_distance"))
	material.set_shader_parameter("max_height", radius * 1.4)
	material.set_shader_parameter("height_color", planet_color)
	
	material.set_shader_parameter("sand_texture_albedo", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_Color.png"))
	material.set_shader_parameter("sand_texture_roughness", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_Roughness.png"))
	material.set_shader_parameter("sand_texture_normal", load("res://Assets/PlanetTextures/Sand/Ground054_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("grass_texture_albedo", load("res://Assets/PlanetTextures/Grass/Grass001_2K-PNG_Color.png"))
	material.set_shader_parameter("grass_texture_normal", load("res://Assets/PlanetTextures/Grass/Grass001_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("forest_texture_albedo", load("res://Assets/PlanetTextures/Forest/SandyGravel01_2K_BaseColor.png"))
	material.set_shader_parameter("forest_texture_roughness", load("res://Assets/PlanetTextures/Forest/SandyGravel01_2K_Roughness.png"))
	material.set_shader_parameter("forest_texture_normal", load("res://Assets/PlanetTextures/Forest/SandyGravel01_2K_Normal.png"))
	
	material.set_shader_parameter("snow_texture_albedo", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_Color.png"))
	material.set_shader_parameter("snow_texture_roughness", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_Roughness.png"))
	material.set_shader_parameter("snow_texture_normal", load("res://Assets/PlanetTextures/Snow/Snow010A_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("rock_texture_albedo",load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_Color.png"))
	material.set_shader_parameter("rock_texture_roughness", load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_Roughness.png"))
	material.set_shader_parameter("rock_texture_normal", load("res://Assets/PlanetTextures/Rock/Rock045_2K-PNG_NormalDX.png"))
	
	material.set_shader_parameter("b_detailed_textures", false)
	material.set_shader_parameter("sun_direction", Vector3(0, 1, 0))
	
	material.set_shader_parameter("water_albedo", Color(config.get_value("water", "water_albedo")))
	material.set_shader_parameter("water_albedo2", Color(config.get_value("water", "water_albedo2")))
	material.set_shader_parameter("water_metallic", config.get_value("water", "water_metallic"))
	material.set_shader_parameter("water_roughness", config.get_value("water", "water_roughness"))
	material.set_shader_parameter("water_wave_direction", config.get_value("water", "water_wave_direction"))
	material.set_shader_parameter("water_wave_direction2", config.get_value("water", "water_wave_direction2"))
	material.set_shader_parameter("water_time_scale", config.get_value("water", "water_time_scale"))
	
	var texture_normal = NoiseTexture2D.new()
	texture_normal.seamless = true
	texture_normal.as_normal_map = true
	texture_normal.bump_strength = 1.5
	texture_normal.noise = FastNoiseLite.new()
	texture_normal.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	texture_normal.noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_RIDGED
	material.set_shader_parameter("water_texture_normal", texture_normal)
	
	var texture_normal2 = NoiseTexture2D.new()
	texture_normal2.seamless = true
	texture_normal2.as_normal_map = true
	texture_normal2.bump_strength = 1.5
	texture_normal2.noise = FastNoiseLite.new()
	texture_normal2.noise.seed = 10
	texture_normal2.noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	texture_normal2.noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	material.set_shader_parameter("water_texture_normal2", texture_normal2)
	
	# Up, Down, Left, Right, Front, Back
	var normals = [Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, 1)]
	var resolution = config.get_value("planet", "resolution")
	var curr_side_id = 0
	for normal in normals:
		var thread = Thread.new()
		threads.append(thread)
		thread.start(_generate_side.bind({
			"normal": normal,
			"noise_data": noise_data,
			"radius": radius,
			"resolution": resolution,
			"material": material,
			"curr_side_id": curr_side_id
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
	var noise_data = data["noise_data"]
	var radius = data["radius"]
	var resolution = data["resolution"]
	var planet_material = data["material"]
	var curr_side_id = data["curr_side_id"]
	var side_nodes = []

	for y in range(resolution-1):
		for x in range(resolution-1):
			var mesh_generation_data = {
				"noise_data": noise_data,
				"x": x,
				"y": y,
				"resolution": resolution,
				"normal": normal,
				"radius": radius,
				"center_planet": center,
				"range_side": 1.0/float(resolution-1),
				"water_level_relative": config.get_value("planet", "water_level_relative"),
				"planet_color": planet_color,
				"max_height": config.get_value("planet", "max_height"),
				"material": planet_material,
				"low_u_coord": 0.0,
				"high_u_coord": config.get_value("planet", "uv_size"),
				"low_v_coord": 0.0,
				"high_v_coord": config.get_value("planet", "uv_size")
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
	noise_map_center = Vector3(randf_range(0, 1000), randf_range(0, 1000), randf_range(0, 1000))
	create_new_planet()

func _ready():
	config.load("res://Configs/SimplePlanetConfig.ini")
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
