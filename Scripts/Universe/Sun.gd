extends Node3D

var config := ConfigFile.new()

var d = -200.0
var sun_should_move = false

func _ready():
	config.load("res://Configs/BaseConfig.ini")
	sun_should_move = config.get_value("start", "start_sun_moving")
	move_sun(0)
	
func _process(delta):
	if (sun_should_move):
		move_sun(delta)
	
func move_sun(delta):
	d += delta * config.get_value("sun", "sun_rotation_speed")
	
	position = Vector3(
		sin(d * config.get_value("sun", "sun_rotation_position")) * config.get_value("sun", "sun_distance_from_center"),
		0,
		cos(d * config.get_value("sun", "sun_rotation_position")) * config.get_value("sun", "sun_distance_from_center")
	) + config.get_value("sun", "sun_rotation_center")
	
	var direction = (Vector3(0, 0, 0) - $DirectionalLight3D.global_transform.origin).normalized()
	$DirectionalLight3D.global_transform.basis = Basis.looking_at(direction.normalized(), Vector3(0, 1, 0))
