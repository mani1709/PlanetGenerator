extends Node3D

var SIMPLE_PLANET_SCENE = load("res://Planets/SimplePlanet/Scenes/SimplePlanet.tscn")
var MINECRAFT_PLANET_SCENE = load("res://Planets/MinecraftPlanet/Scenes/MinecraftPlanet.tscn")
var config := ConfigFile.new()
var time_until_next_randomize_planet_possible = 0.0
var curr_planet = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	config.load("res://Configs/BaseConfig.ini")
	$UiUniverse.connect("_light_mode_changed", _on_light_mode_changed)
	$UiUniverse.connect("_shadow_mode_changed", _on_shadow_mode_changed)
	$UiUniverse.connect("_planet_changed", _on_planet_changed)
	$UiUniverse.connect("_randomize_planet_pressed", _on_randomize_planet_pressed)
	$UiUniverse.connect("_sun_move_mode_changed", _on_sun_move_mode_changed)
	curr_planet = config.get_value("start", "start_planet")
	_on_light_mode_changed(config.get_value("start", "start_light"))
	_on_shadow_mode_changed(config.get_value("start", "start_shadow"))
	_on_planet_changed(config.get_value("start", "start_planet"))
	_on_sun_move_mode_changed(config.get_value("start", "start_sun_moving"))

func _on_light_mode_changed(mode_index):
	if mode_index == 0:
		$WorldEnvironment.environment.ambient_light_source = 0
		$Sun/DirectionalLight3D.visible = true;
	else:
		$WorldEnvironment.environment.ambient_light_source = 2
		$Sun/DirectionalLight3D.visible = false;
		
func _on_shadow_mode_changed(mode_index):
	if mode_index == 0:
		$Sun/DirectionalLight3D.shadow_enabled = false;
	else:
		$Sun/DirectionalLight3D.shadow_enabled = true;
		
		
func _on_sun_move_mode_changed(mode_index):
	if mode_index == 0:
		$Sun.sun_should_move = false;
	else:
		$Sun.sun_should_move = true;
		
func _on_planet_changed(mode_index):
		if has_node("Planet"):
			$Planet.queue_free()
			remove_child($Planet)
			
		curr_planet = mode_index
			
		var new_node
		if mode_index == 0:
			print("creating normal planet")
			new_node = SIMPLE_PLANET_SCENE.instantiate()
		else:
			print("creating minecraft planet")
			new_node = MINECRAFT_PLANET_SCENE.instantiate()
		
		add_child(new_node)
		new_node.name = "Planet"
		time_until_next_randomize_planet_possible = config.get_value("advanced", "time_between_randomize_planet_calls")

func _process(delta: float) -> void:
	if time_until_next_randomize_planet_possible > 0.0:
		time_until_next_randomize_planet_possible -= delta
	var playerPosition = $Rocket.position
	$UiUniverse.updatePositionPlayerLabel(playerPosition)
	
	var sunPosition = $Sun.position
	$UiUniverse.updatePositionSunLabel(sunPosition)
	
	if $Planet:
		var planetPosition = $Planet.position
		$UiUniverse.updatePositionPlanetLabel(planetPosition)
		
	$Moon/MoonMesh.mesh.material.set_shader_parameter("moon_center", $Moon.position)
	$Moon/MoonMesh.mesh.material.set_shader_parameter("sun_center", $Sun.position)

func _on_randomize_planet_pressed() -> void:
	if time_until_next_randomize_planet_possible <= 0.0:
		if has_node("Planet"):
			$Planet.queue_free()
			remove_child($Planet)
		_on_planet_changed(curr_planet)
		time_until_next_randomize_planet_possible = config.get_value("advanced", "time_between_randomize_planet_calls")
