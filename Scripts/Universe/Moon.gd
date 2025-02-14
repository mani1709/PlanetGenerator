extends Node3D

var config := ConfigFile.new()

var d = -200.0

func _ready():
	config.load("res://Configs/BaseConfig.ini")
	
func _process(delta):
	d += delta * config.get_value("moon", "moon_rotation_speed")
	
	var moon_position = Vector3(
		sin(d * config.get_value("moon", "moon_rotation_position")) * config.get_value("moon", "moon_distance_from_center"),
		sin(d * config.get_value("moon", "moon_rotation_position")) * config.get_value("moon", "moon_distance_from_center"),
		cos(d * config.get_value("moon", "moon_rotation_position")) * config.get_value("moon", "moon_distance_from_center")
	) + config.get_value("moon", "moon_rotation_center")
	
	$MoonMesh.position = moon_position
	
	var moon_direction = (Vector3(0, 0, 0) - $MoonMesh.global_transform.origin).normalized()
	$MoonMesh.global_transform.basis = Basis.looking_at(moon_direction.normalized(), Vector3(0, 1, 0))
