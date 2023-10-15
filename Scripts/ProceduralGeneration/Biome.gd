extends Object

class_name Biome

enum Types {
	OCEAN = 0,
	SHALLOW_WATER = 1,
	BEACH = 2,
	SWAMP = 3,
	PLAINS = 4,
	FOREST = 5,
	HILLS = 6,
	MOUNTAIN = 7,
	SNOW = 8,
	DESERT= 9
}

var world_seed: int
var world_map: Array = []
var desert_tiles_count = 0

func _init(_world_seed: int, _world_map: Array):
	world_seed = _world_seed
	world_map = _world_map
	
func determine_biome(h, x, y):
	var noise_variation = FastNoiseLite.new()
	noise_variation.seed = world_seed + 100  # Different seed to introduce variability
	var noise_val = noise_variation.get_noise_2d(x, y)

	if h < 0.18:
		return Types.OCEAN
	elif h < 0.2:
		return Types.SHALLOW_WATER
	elif h < 0.225:
		if is_adjacent_to_biome(x, y, Types.SWAMP):
			return Types.PLAINS  # If it's adjacent to a swamp, return PLAINS instead of BEACH
		else:
			return Types.BEACH
	elif h < 0.25:
		return Types.SWAMP if noise_val > 0 else Types.PLAINS
	elif h < 0.4:
		return Types.PLAINS
	elif h < 0.55:
		return Types.FOREST
	elif h < 0.65:
		return Types.HILLS
	elif h < 0.78:
		return Types.MOUNTAIN
	else:
		return Types.SNOW
		
func is_adjacent_to_biome(x, y, biome):
	var adjacent_coords = [
		Vector2(x+1, y), Vector2(x-1, y),
		Vector2(x, y+1), Vector2(x, y-1),
		Vector2(x+1, y+1), Vector2(x-1, y-1),
		Vector2(x-1, y+1), Vector2(x+1, y-1)  # Check diagonals too for better spread
	]
	for coord in adjacent_coords:
		if is_inside_map(coord.x, coord.y) and world_map[coord.x][coord.y] == biome:
			return true
	return false

func is_inside_map(x, y):
	return x >= 0 and x < world_map.size() and y >= 0 and y < world_map[0].size()
	
func update_world_map(_world_map: Array):
		world_map = _world_map
