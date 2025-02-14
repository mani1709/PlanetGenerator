extends Node3D

var cloud_scene = load("res://Planets/SimplePlanet/Scenes/CloudSpawner.tscn")
var config := ConfigFile.new()

func _ready():
	config.load("res://Configs/SimplePlanetConfig.ini")
	$Planet.cast_shadow = false
	
	# Spawning all cloudspawners
	var distanceFromPlanet = config.get_value("clouds", "distance_from_planet_center")
	for i in range(config.get_value("clouds", "amount_of_spawners")):
		var random_theta = randf() * TAU
		var random_phi = acos(2.0 * randf() - 1.0)
		var x = sin(random_phi) * cos(random_theta)
		var y = sin(random_phi) * sin(random_theta)
		var z = cos(random_phi)
		var random_direction = Vector3(x, y, z)
		
		var cloud_instance = cloud_scene.instantiate()
		cloud_instance.position = random_direction * distanceFromPlanet
	
		add_child(cloud_instance)
		cloud_instance.add_to_group("Cloud " + str(i))
	
func get_nodes_loaded_count():
	return $Planet.get_nodes_loaded_count()

func get_center():
	return $Planet.center
	
func get_distance_to_rocket():
	return $Planet.get_distance_to_rocket()
	
func get_radius():
	return $Planet.radius
	
func randomize_planet():
	$Planet.randomize_planet()

func _exit_tree():
	$Planet._exit_tree()
