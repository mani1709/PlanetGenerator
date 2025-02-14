extends Node3D

var camera_rotation_horizontal = 0.0
var camera_rotation_vertical = 0.0
var sensitivity = 0.05

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			camera_rotation_horizontal = -event.relative.x * sensitivity
			camera_rotation_vertical = -event.relative.y * sensitivity

func _physics_process(_delta):
	var yaw = camera_rotation_horizontal
	var pitch = camera_rotation_vertical

	$"..".rotate_object_local(Vector3(0,1,0), deg_to_rad(yaw))
	$"..".rotate_object_local(Vector3(1,0,0), deg_to_rad(pitch))
	camera_rotation_horizontal = 0.0
	camera_rotation_vertical = 0.0
