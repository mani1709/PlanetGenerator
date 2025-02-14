extends StaticBody3D
class_name QuadTreeMeshSimple

var mesh_instance = null
var collision_instance = null

var current_node_x = 0
var current_node_y = 0
var current_resolution = 0
var center_planet = Vector3(0.0, 0.0, 0.0)
var center_side = Vector3(0.0, 0.0, 0.0)
var base_normal = Vector3(0.0, 0.0, 0.0)
var base_range = 1.0
var base_radius = 0.0
var axis_a = Vector3(0.0, 0.0, 0.0)
var axis_b = Vector3(0.0, 0.0, 0.0)
var quad_noise_data = {}
var water_level_relative = 0.0
var planet_color = null
var max_height = 1000
var material = null
var low_u_coord = 0.0
var high_u_coord = 0.0
var low_v_coord = 0.0
var high_v_coord = 0.0
var forest_tree_scene = load("res://Planets/SimplePlanet/Scenes/ForestTree.tscn")
var palm_tree_scene = load("res://Planets/SimplePlanet/Scenes/PalmTree.tscn")

var quad_base_points = []

var quadtree_mesh_array = []
var config := ConfigFile.new()

var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var normals = PackedVector3Array()
var uvs = PackedVector2Array()
var heightValues = PackedVector4Array()

func interpolate(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float, v: float) -> Vector3:
	var top = p0.lerp(p2, u)
	var bottom = p1.lerp(p3, u)
	return top.lerp(bottom, v)
	
func get_random_position_on_mesh():
	var top_mesh_start = quad_base_points[0]
	var top_mesh_end = quad_base_points[1]
	var top_mesh_left = quad_base_points[2]
	var top_mesh_right = quad_base_points[3]

	# Randomly select u and v parameters within the grid bounds
	var u = randf()
	var v = randf()

	# Interpolate to get the random position on the top mesh
	var random_position = interpolate(top_mesh_start, top_mesh_end, top_mesh_left, top_mesh_right, u, v)
	
	return random_position


# Adding additional height depending on the fractional brownian motion to vertices
func update_vertex_and_save_data(vertex):
	var fbm = compute_fractional_brownian_motion(vertex.normalized())
	vertex += vertex * fbm
	heightValues.append(Vector4(vertex.length(), 0, 0, 0))
	if vertex.length() < self.base_radius * self.water_level_relative:
		vertex = vertex.normalized() * self.base_radius * self.water_level_relative
	return vertex
	
func update_base_vertex(vertex):
	vertex = vertex.normalized() * 10000
	heightValues.append(Vector4(vertex.length(), 0, 0, 0))
	return vertex

func create_mesh_and_collision(mesh_generation_data, root_node, node_id):
	self.current_node_x = mesh_generation_data["x"]
	self.current_node_y = mesh_generation_data["y"]
	self.current_resolution = mesh_generation_data["resolution"]
	self.center_planet = mesh_generation_data["center_planet"]
	self.base_normal = mesh_generation_data["normal"]
	self.base_range = mesh_generation_data["range_side"]
	self.base_radius = mesh_generation_data["radius"]
	self.axis_a = Vector3(base_normal.y, base_normal.z, base_normal.x)
	self.axis_b = base_normal.cross(axis_a)
	self.quad_noise_data = mesh_generation_data["noise_data"]
	self.water_level_relative = mesh_generation_data["water_level_relative"]
	self.planet_color = mesh_generation_data["planet_color"]
	self.max_height = mesh_generation_data["max_height"]
	self.material = mesh_generation_data["material"]
	self.low_u_coord = mesh_generation_data["low_u_coord"]
	self.high_u_coord = mesh_generation_data["high_u_coord"]
	self.low_v_coord = mesh_generation_data["low_v_coord"]
	self.high_v_coord = mesh_generation_data["high_v_coord"]
	
	config.load("res://Configs/SimplePlanetConfig.ini")
	var INNER_GRID_SIZE = config.get_value("quadtree", "inner_grid_size")
	var SIDE_GRID_SIZE = config.get_value("quadtree", "side_grid_size")
	var smallRadiusFactor = config.get_value("quadtree", "small_radius_factor")
	var index_offset = 0
	
	var percent_negative = Vector2(self.current_node_x,self.current_node_y) / (self.current_resolution-1)
	var percent_positive = Vector2(self.current_node_x+1,self.current_node_y+1) / (self.current_resolution-1)
	
	
	var point0 = (self.base_normal + (percent_negative.x - 0.5) * 2.0 * self.axis_a + (percent_negative.y - 0.5) * 2.0 * self.axis_b).normalized() * base_radius
	var point1 = (self.base_normal + (percent_negative.x - 0.5) * 2.0 * self.axis_a + (percent_positive.y - 0.5) * 2.0 * self.axis_b).normalized() * base_radius
	var point2 = (self.base_normal + (percent_positive.x - 0.5) * 2.0 * self.axis_a + (percent_negative.y - 0.5) * 2.0 * self.axis_b).normalized() * base_radius
	var point3 = (self.base_normal + (percent_positive.x - 0.5) * 2.0 * self.axis_a + (percent_positive.y - 0.5) * 2.0 * self.axis_b).normalized() * base_radius
	
	self.center_side = (point0 + point1 + point2 + point3) / 4
	
	index_offset = 0
	
	var point4 = point0 * smallRadiusFactor
	var point5 = point1 * smallRadiusFactor
	var point6 = point2 * smallRadiusFactor
	var point7 = point3 * smallRadiusFactor
	
	var uv_normalization_side_factor = 10.0 / 2000.0 # quick and dirty way to fix uv issues
	
	# Creation of quad face
	for i in range(INNER_GRID_SIZE):
		for j in range(INNER_GRID_SIZE):
			var vertex0 = interpolate(point0, point1, point2, point3, i / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex1 = interpolate(point0, point1, point2, point3, (i + 1) / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex2 = interpolate(point0, point1, point2, point3, i / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))
			var vertex3 = interpolate(point0, point1, point2, point3, (i + 1) / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))

			vertices.append(update_vertex_and_save_data(vertex0))
			vertices.append(update_vertex_and_save_data(vertex1))
			vertices.append(update_vertex_and_save_data(vertex2))
			vertices.append(update_vertex_and_save_data(vertex3))

			normals.append((vertex0 - self.center_planet).normalized())
			normals.append((vertex1 - self.center_planet).normalized())
			normals.append((vertex2 - self.center_planet).normalized())
			normals.append((vertex3 - self.center_planet).normalized())

			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord), low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord), low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord), low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord), low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))

			indices.append(index_offset)
			indices.append(index_offset + 2)
			indices.append(index_offset + 1)
			indices.append(index_offset + 1)
			indices.append(index_offset + 2)
			indices.append(index_offset + 3)

			index_offset += 4

	# Creation of the 4 quad sides
	for i in range(SIDE_GRID_SIZE):
		for j in range(INNER_GRID_SIZE):
			var vertex0 = interpolate(point0, point1, point4, point5, i / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex1 = interpolate(point0, point1, point4, point5, (i + 1) / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex2 = interpolate(point0, point1, point4, point5, i / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))
			var vertex3 = interpolate(point0, point1, point4, point5, (i + 1) / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))

			vertices.append(update_vertex_and_save_data(vertex0))
			vertices.append(update_base_vertex(vertex1))
			vertices.append(update_vertex_and_save_data(vertex2))
			vertices.append(update_base_vertex(vertex3))

			normals.append((vertex0 - self.center_planet).normalized())
			normals.append((vertex1 - self.center_planet).normalized())
			normals.append((vertex2 - self.center_planet).normalized())
			normals.append((vertex3 - self.center_planet).normalized())

			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))

			indices.append(index_offset)
			indices.append(index_offset + 1)
			indices.append(index_offset + 2)
			indices.append(index_offset + 1)
			indices.append(index_offset + 3)
			indices.append(index_offset + 2)

			index_offset += 4

	for i in range(SIDE_GRID_SIZE):
		for j in range(INNER_GRID_SIZE):
			var vertex0 = interpolate(point1, point3, point5, point7, i / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex1 = interpolate(point1, point3, point5, point7, (i + 1) / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex2 = interpolate(point1, point3, point5, point7, i / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))
			var vertex3 = interpolate(point1, point3, point5, point7, (i + 1) / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))

			vertices.append(update_vertex_and_save_data(vertex0))
			vertices.append(update_base_vertex(vertex1))
			vertices.append(update_vertex_and_save_data(vertex2))
			vertices.append(update_base_vertex(vertex3))

			normals.append((vertex0 - self.center_planet).normalized())
			normals.append((vertex1 - self.center_planet).normalized())
			normals.append((vertex2 - self.center_planet).normalized())
			normals.append((vertex3 - self.center_planet).normalized())

			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))

			indices.append(index_offset)
			indices.append(index_offset + 1)
			indices.append(index_offset + 2)
			indices.append(index_offset + 1)
			indices.append(index_offset + 3)
			indices.append(index_offset + 2)

			index_offset += 4
			
	for i in range(SIDE_GRID_SIZE):
		for j in range(INNER_GRID_SIZE):
			var vertex0 = interpolate(point3, point2, point7, point6, i / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex1 = interpolate(point3, point2, point7, point6, (i + 1) / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex2 = interpolate(point3, point2, point7, point6, i / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))
			var vertex3 = interpolate(point3, point2, point7, point6, (i + 1) / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))

			vertices.append(update_vertex_and_save_data(vertex0))
			vertices.append(update_base_vertex(vertex1))
			vertices.append(update_vertex_and_save_data(vertex2))
			vertices.append(update_base_vertex(vertex3))

			normals.append((vertex0 - self.center_planet).normalized())
			normals.append((vertex1 - self.center_planet).normalized())
			normals.append((vertex2 - self.center_planet).normalized())
			normals.append((vertex3 - self.center_planet).normalized())
#
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))

			indices.append(index_offset)
			indices.append(index_offset + 1)
			indices.append(index_offset + 2)
			indices.append(index_offset + 1)
			indices.append(index_offset + 3)
			indices.append(index_offset + 2)

			index_offset += 4
			
	for i in range(SIDE_GRID_SIZE):
		for j in range(INNER_GRID_SIZE):
			var vertex0 = interpolate(point2, point0, point6, point4, i / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex1 = interpolate(point2, point0, point6, point4, (i + 1) / float(INNER_GRID_SIZE), j / float(INNER_GRID_SIZE))
			var vertex2 = interpolate(point2, point0, point6, point4, i / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))
			var vertex3 = interpolate(point2, point0, point6, point4, (i + 1) / float(INNER_GRID_SIZE), (j + 1) / float(INNER_GRID_SIZE))

			vertices.append(update_vertex_and_save_data(vertex0))
			vertices.append(update_base_vertex(vertex1))
			vertices.append(update_vertex_and_save_data(vertex2))
			vertices.append(update_base_vertex(vertex3))

			normals.append((vertex0 - self.center_planet).normalized())
			normals.append((vertex1 - self.center_planet).normalized())
			normals.append((vertex2 - self.center_planet).normalized())
			normals.append((vertex3 - self.center_planet).normalized())

			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + j / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + i / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))
			uvs.append(Vector2(low_u_coord + (i + 1) / float(INNER_GRID_SIZE) * (high_u_coord - low_u_coord) / uv_normalization_side_factor, low_v_coord + (j + 1) / float(INNER_GRID_SIZE) * (high_v_coord - low_v_coord)))

			indices.append(index_offset)
			indices.append(index_offset + 1)
			indices.append(index_offset + 2)
			indices.append(index_offset + 1)
			indices.append(index_offset + 3)
			indices.append(index_offset + 2)

			index_offset += 4
		
	quad_base_points = [point0 + point0 * compute_fractional_brownian_motion(point0.normalized()), 
						point1 + point1 * compute_fractional_brownian_motion(point1.normalized()), 
						point2 + point2 * compute_fractional_brownian_motion(point2.normalized()), 
						point3 + point3 * compute_fractional_brownian_motion(point3.normalized())]
	
	self.center_side = (quad_base_points[0] + quad_base_points[1] + quad_base_points[2] + quad_base_points[3]) / 4
	
	# Create actual mesh
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	
	for i in range(vertices.size()):
		surface_tool.set_normal(normals[i])
		surface_tool.set_uv(uvs[i])
		surface_tool.set_custom(0, Color(heightValues[i].x, heightValues[i].y, heightValues[i].z, heightValues[i].w))
		surface_tool.add_vertex(vertices[i])
		
	for i in range(indices.size()):
		surface_tool.add_index(indices[i])
		
	var mesh = surface_tool.commit()
	
	self.mesh_instance = MeshInstance3D.new()
	self.mesh_instance.name = "Mesh " + node_id
	self.mesh_instance.mesh = mesh
	self.mesh_instance.material_override = self.material
	
	var collision_shape = CollisionShape3D.new()
	var concave_shape = ConcavePolygonShape3D.new()
	
	var faces = PackedVector3Array()
	for i in range(0, indices.size(), 3):
		faces.append(vertices[indices[i]])
		faces.append(vertices[indices[i + 1]])
		faces.append(vertices[indices[i + 2]])
		
	concave_shape.set_faces(faces)
	collision_shape.shape = concave_shape
	
	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	self.mesh_instance.add_child(static_body)
	
	root_node.add_child.call_deferred(self.mesh_instance) # TODO maybe here?
	
# Idea and code from https://github.com/simondevyoutube/ProceduralTerrain_Part1/blob/master/src/noise.js
# Additional start_octave is used to generate less/more complicated terrain
func compute_fractional_brownian_motion(position_normalized):
	var amplitude = 1.0
	var frequency = 1.0
	amplitude *= pow(self.quad_noise_data["persistence"], self.quad_noise_data["start_octave"])
	frequency *= pow(self.quad_noise_data["lacunarity"], self.quad_noise_data["start_octave"])
		
	var normalization = 0
	var total = 0
	var position_in_noisemap = (position_normalized * self.quad_noise_data["noise_map_center"]) * self.quad_noise_data["size_of_noise_map"]
	for o in range(self.quad_noise_data["number_of_octaves"]):
		var noiseValue = self.quad_noise_data["noise_function"].get_noise_3dv(position_in_noisemap * frequency) * 0.5 + 0.5 # value between 0 and 1
		total += noiseValue * amplitude
		normalization += amplitude
		amplitude *= self.quad_noise_data["persistence"]
		frequency *= self.quad_noise_data["lacunarity"]
	total /= normalization
	return pow(total, self.quad_noise_data["exponentiation"])
	
func get_mesh_generation_data_for_next(x, y, resolution, u_pos, v_pos):
	var u_low
	if u_pos == 0:
		u_low = self.low_u_coord
	else:
		u_low = (self.low_u_coord + self.high_u_coord) / 2.0
		
	var u_high
	if u_pos == 0:
		u_high = (self.low_u_coord + self.high_u_coord) / 2.0
	else:
		u_high = self.high_u_coord
		
	var v_low
	if v_pos == 0:
		v_low = self.low_v_coord
	else:
		v_low = (self.low_v_coord + self.high_v_coord) / 2.0
		
	var v_high
	if v_pos == 0:
		v_high = (self.low_v_coord + self.high_v_coord) / 2.0
	else:
		v_high = self.high_v_coord

	return {
		"noise_data": self.quad_noise_data,
		"x": x,
		"y": y,
		"resolution": resolution,
		"normal": self.base_normal,
		"radius": self.base_radius,
		"center_planet": self.center_planet,
		"range_side": self.base_range,
		"water_level_relative": self.water_level_relative,
		"planet_color": self.planet_color,
		"max_height": self.max_height,
		"material": self.material,
		"low_u_coord": u_low,
		"high_u_coord": u_high,
		"low_v_coord": v_low,
		"high_v_coord": v_high
	}
	
func remove_mesh_and_collision(_root_node, _node_id):
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null

func spawn_tree(tree_position, tree_type):
	var random_size = randf_range(0.5, 1.5)
	
	var tree_instance
	if tree_type == "normal":
		tree_instance = forest_tree_scene.instantiate()
	else:
		tree_instance = palm_tree_scene.instantiate()
	
	# since planet is at 0 0 0 and we want the trees to be basically normal to center
	var tree_normal = tree_position
	tree_instance.transform.origin = tree_position
	
	var rotation_matrix = Basis()
	rotation_matrix = rotation_matrix.orthonormalized()

	var perpendicular_vector = tree_normal.cross(Vector3.UP)
	rotation_matrix.y = tree_normal.normalized()
	rotation_matrix.x = perpendicular_vector.normalized()
	rotation_matrix.z = rotation_matrix.x.cross(rotation_matrix.y).normalized()
	tree_instance.basis = rotation_matrix
	tree_instance.basis *= random_size

	call_deferred("add_child", tree_instance)
	tree_instance.add_to_group("Trees")
	
func remove_trees():
	var children_to_remove = []
	for child in get_children():
		if child.is_in_group("Trees"):
			children_to_remove.append(child)
	
	for child in children_to_remove:
		if has_node(child.get_path()):
			call_deferred("remove_child", child)
			child.call_deferred("queue_free")
