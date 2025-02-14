extends Node

class_name PerlinNoiseGenerator

var perlin_noise = FastNoiseLite.new()
var spline_points = []
var config_file := ConfigFile.new()

func _init(noise_type: String):
	config_file.load("res://Configs/MinecraftPlanetConfig.ini")
	perlin_noise.noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
	var fractal_type = config_file.get_value(noise_type, "fractal_type", "fbm")
	if (fractal_type == "fbm"):
		perlin_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	elif (fractal_type == "pingpong"):
		perlin_noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG
		perlin_noise.fractal_ping_pong_strength = config_file.get_value(noise_type, "ping_pong_strength", 3.0)
	elif (fractal_type == "ridged"):
		perlin_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	else:
		perlin_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	perlin_noise.frequency = config_file.get_value(noise_type, "frequency", 0.02)
	perlin_noise.fractal_octaves = config_file.get_value(noise_type, "octaves", 0.02)
	perlin_noise.fractal_lacunarity = config_file.get_value(noise_type, "lacunarity", 0.02)
	perlin_noise.fractal_gain = config_file.get_value(noise_type, "gain", 0.02)
	perlin_noise.fractal_weighted_strength = config_file.get_value(noise_type, "weighted_strength", 0.02)
	
	perlin_noise.seed = randi()

func add_spline_point(x: float, y: float) -> void:
	spline_points.append(Vector2(x, y))
	spline_points.sort()

func getValue(position: Vector3) -> float:
	var noiseValue = perlin_noise.get_noise_3dv(position / 100.0)
	var normalizedValue = (noiseValue + 1.0) / 2.0
	return interpolate_spline(normalizedValue)

func interpolate_spline(noise_value: float) -> float:
	if spline_points.is_empty():
		return 0.0

	for i in range(spline_points.size() - 1):
		var p1 = spline_points[i]
		var p2 = spline_points[i + 1]
		if noise_value >= p1.x and noise_value <= p2.x:
			var t = (noise_value - p1.x) / (p2.x - p1.x)
			return lerp(p1.y, p2.y, t)
	
	if noise_value < spline_points[0].x:
		return spline_points[0].y
	else:
		return spline_points[spline_points.size() - 1].y
