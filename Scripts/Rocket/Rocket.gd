extends CharacterBody3D

var config := ConfigFile.new()

var mouse_sensitivity := 0.0001
var twist_input := 0.0
var pitch_input := 0.0

@onready var rocket := $RocketModel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	config.load("res://Configs/BaseConfig.ini")
	$CameraRoot/TwistPivot/PitchPivot/Camera.make_current()
	
func _physics_process(delta):
	var movement = Vector3()
	if Input.is_action_pressed("move_forward"):
		movement += -transform.basis.z
	if Input.is_action_pressed("move_backward"):
		movement += transform.basis.z
	if Input.is_action_pressed("move_left"):
		movement += -transform.basis.x
	if Input.is_action_pressed("move_right"):
		movement += transform.basis.x
	if Input.is_action_pressed("move_up"):
		movement += transform.basis.y
	if Input.is_action_pressed("move_down"):
		movement += -transform.basis.y
		
	var current_speed = config.get_value("rocket", "rocket_base_speed")
	if Input.is_action_pressed("speed_up"):
		current_speed = config.get_value("rocket", "rocket_fast_speed")

	velocity = movement.normalized() * current_speed * delta


	move_and_slide()
	
	if Input.is_action_just_pressed("focus_game"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_pressed("unfocus_game"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
