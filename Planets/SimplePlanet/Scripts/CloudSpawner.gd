extends Node3D

var config := ConfigFile.new()

func _ready() -> void:
	config.load("res://Configs/SimplePlanetConfig.ini")
	
	# Cloud generation
	$GPUParticles3D.position = Vector3(0, 0, 0)
	
	$GPUParticles3D.process_material = $GPUParticles3D.process_material.duplicate()
	
	$GPUParticles3D.amount = randi_range(config.get_value("clouds", "min_amount"), config.get_value("clouds", "max_amount"))
	
	var extents_x = randf_range(config.get_value("clouds", "extent_x_min"), config.get_value("clouds", "extent_x_max"))
	var extents_y = randf_range(config.get_value("clouds", "extent_y_min"), config.get_value("clouds", "extent_y_max"))
	var extents_z = randf_range(config.get_value("clouds", "extent_z_min"), config.get_value("clouds", "extent_z_max"))
	$GPUParticles3D.process_material.emission_box_extents = Vector3(extents_x, extents_y, extents_z)

	$GPUParticles3D.draw_pass_1 = $GPUParticles3D.draw_pass_1.duplicate()

	var size_x = randf_range(config.get_value("clouds", "size_x_min"), config.get_value("clouds", "size_x_max"))
	var size_y = randf_range(config.get_value("clouds", "size_y_min"), config.get_value("clouds", "size_y_max"))
	$GPUParticles3D.draw_pass_1.size = Vector2(size_x, size_y)
	
