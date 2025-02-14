extends Control

signal _light_mode_changed(mode_index)
signal _sun_move_mode_changed(mode_index)
signal _shadow_mode_changed(mode_index)
signal _planet_changed(mode_index)
signal _randomize_planet_pressed()
var config := ConfigFile.new()

func _ready() -> void:
	config.load("res://Configs/BaseConfig.ini")
	$CanvasLayer/VBoxContainer/OptionButtonPlanet.selected = config.get_value("start", "start_planet")
	$CanvasLayer/VBoxContainer/OptionButtonLight.selected = config.get_value("start", "start_light")
	$CanvasLayer/VBoxContainer/OptionButtonShadow.selected = config.get_value("start", "start_shadow")
	$CanvasLayer/VBoxContainer/OptionButtonMoveSun.selected = config.get_value("start", "start_sun_moving")

func updateFpsLabel() -> void:
	var fps = Engine.get_frames_per_second()
	$CanvasLayer/VBoxContainer/LabelFps.text = "FPS: " + str(fps)
	
func updatePositionPlayerLabel(playerPosition: Vector3) -> void:
	var formatted_position = "Player Position: (%.2f, %.2f, %.2f)" % [playerPosition.x, playerPosition.y, playerPosition.z]
	$CanvasLayer/VBoxContainer/LabelPositionPlayer.text = formatted_position
	var formated_distance = "Distance to Center: (%.2f)" % [playerPosition.length()]
	$CanvasLayer/VBoxContainer/LabelDistanceToCenter.text = formated_distance
	
func updatePositionSunLabel(sunPosition: Vector3) -> void:
	var formatted_position = "Sun Position: (%.2f, %.2f, %.2f)" % [sunPosition.x, sunPosition.y, sunPosition.z]
	$CanvasLayer/VBoxContainer/LabelPositionSun.text = formatted_position
	
func updatePositionPlanetLabel(planetPosition: Vector3) -> void:
	var formatted_position = "Planet Position: (%.2f, %.2f, %.2f)" % [planetPosition.x, planetPosition.y, planetPosition.z]
	$CanvasLayer/VBoxContainer/LabelPositionPlanet.text = formatted_position

func _process(_delta: float) -> void:
	updateFpsLabel()

func _on_option_button_item_selected(index: int) -> void:
	emit_signal("_light_mode_changed", index)
	
func _on_shadow_button_item_selected(index: int) -> void:
	emit_signal("_shadow_mode_changed", index)
	
func _on_sun_move_button_item_selected(index: int) -> void:
	emit_signal("_sun_move_mode_changed", index)

func _on_planet_option_button_item_selected(index: int) -> void:
	emit_signal("_planet_changed", index)

func _on_randomize_planet_button_pressed() -> void:
	emit_signal("_randomize_planet_pressed")
