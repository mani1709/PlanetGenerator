extends Node
class_name QuadTreeMinecraft

var mesh : QuadTreeMeshMinecraft
var node_id = -1
var root_node = null
var mesh_generation_data = {}

const MAX_SPLITS = 5
const MIN_LOD_FOR_TREES = 5
const MIN_LOD_FOR_COLLISION = 3
const MIN_LOD_FOR_GOOD_TEXTURES = 3
const MAX_NUM_TREES = 5
const MIN_NUM_TREES = 1
const THRESHOLDS = [7.5, 0.5, 0.3, 0.2, 0.1, 0.01]

var current_split = 0
var quads = []
var b_is_split = false
var b_trees_spawned = false
var config := ConfigFile.new()

func _init(in_current_split, in_mesh_generation_data, in_root_node):
	self.current_split = in_current_split
	self.node_id = str(randi())
	self.mesh_generation_data = in_mesh_generation_data
	self.root_node = in_root_node
	config.load("res://Configs/MinecraftPlanetConfig.ini")
	mesh = QuadTreeMeshMinecraft.new()
	mesh.create_mesh_and_collision(mesh_generation_data, root_node, node_id)
	call_deferred("add_child", mesh)
	
func get_current_distance_from_player(camera_pos):
	if b_is_split:
		var min_value = INF
		for quad in quads:
			var distance_of_player_to_quad = quad.get_current_distance_from_player(camera_pos)
			if distance_of_player_to_quad < min_value:
				min_value = distance_of_player_to_quad
		return min_value
	return camera_pos.distance_to(mesh.center_side)

func get_node_count():
	if quads == []:
		return 1
	else:
		var sum = 0
		for quad in quads:
			sum += quad.get_node_count()
		return sum
	
func split_if_too_close(camera_pos):
	if b_is_split == false:
		if camera_pos.distance_to(mesh.center_side) < THRESHOLDS[current_split] * mesh.base_height:
			var new_resolution = (mesh.current_resolution - 1) * 2 + 1
			quads.append(QuadTreeMinecraft.new(current_split+1, 
				mesh.get_mesh_generation_data_for_next(mesh.current_node_x * 2, mesh.current_node_y * 2, new_resolution, 0, 0), root_node))
			quads.append(QuadTreeMinecraft.new(current_split+1, 
				mesh.get_mesh_generation_data_for_next(mesh.current_node_x * 2, mesh.current_node_y * 2 + 1, new_resolution, 0, 1), root_node))
			quads.append(QuadTreeMinecraft.new(current_split+1, 
				mesh.get_mesh_generation_data_for_next(mesh.current_node_x * 2 + 1, mesh.current_node_y * 2, new_resolution, 1, 0), root_node))
			quads.append(QuadTreeMinecraft.new(current_split+1, 
				mesh.get_mesh_generation_data_for_next(mesh.current_node_x * 2 + 1, mesh.current_node_y * 2 + 1, new_resolution, 1, 1), root_node))
			
			for quad in quads:
				call_deferred("add_child", quad)
			
			# this makes it so there is nothing in the water and in the snow biome
			if current_split + 1 >= MIN_LOD_FOR_TREES and mesh.center_side.length() > config.get_value("planet", "min_palm_tree_height") and mesh.center_side.length() < config.get_value("planet", "max_tree_height") and not b_trees_spawned:
				for quad in quads:
					quad.spawn_trees();
			
			b_is_split = true
			remove_mesh_and_collision()
			
		return true
	return false

func spawn_trees():
	b_trees_spawned = true
	var num_trees
	if mesh.center_side.length() < config.get_value("planet", "min_forest_normal_tree_height"):
		num_trees = randi() % (MAX_NUM_TREES + 1 - MIN_NUM_TREES) + MIN_NUM_TREES
	else:
		num_trees = (randi() % (MAX_NUM_TREES + 1 - MIN_NUM_TREES) + MIN_NUM_TREES) * 3
	for i in range(num_trees):
		var tree_position = Vector3(mesh.get_random_position_on_mesh())
		var tree_type = mesh.get_fitting_tree_type(tree_position)
		# make sure that they dont spawn in water
		if tree_position.length() < config.get_value("terrain", "ocean_level"):
			continue
		mesh.spawn_tree(tree_position, tree_type)
			
func remove_trees():
	if b_trees_spawned:
		b_trees_spawned = false
		mesh.remove_trees()
		
func remove_mesh_and_collision():
	mesh.remove_mesh_and_collision(root_node, node_id)
	
func final_remove_mesh_and_collision():
	if b_is_split:
		for quad in quads:
			quad.final_remove_mesh_and_collision()
	quads = []
	remove_trees()
	mesh.remove_mesh_and_collision(root_node, node_id)
		
func split_or_combine_tree_if_necessary(camera_pos):
	if not b_is_split:
		if current_split >= MAX_SPLITS: 
			return
		split_if_too_close(camera_pos)
	else:
		var b_can_merge = true
		for quad in quads:
			if camera_pos.distance_to(mesh.center_side) < THRESHOLDS[current_split] * mesh.center_side.length() or quad.b_is_split:
				b_can_merge = false
				
		if b_can_merge == true:
			mesh.create_mesh_and_collision(self.mesh_generation_data, root_node, node_id)
			for quad in quads:
				quad.remove_mesh_and_collision()
				call_deferred("remove_child", quad)
			quads = []
			b_is_split = false
		else:
			for quad in quads:
				quad.update_quad_tree(camera_pos)

func update_quad_tree(camera_pos):
	split_or_combine_tree_if_necessary(camera_pos)
