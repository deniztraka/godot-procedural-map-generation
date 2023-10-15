extends Object

class_name WorldDataGenerator

var world_seed: int
var width: int
var height: int
var scale: float
var is_generate_rivers: bool
var world_map: Array = []
var height_map: Array = []
var potential_starts: Array = []
var biomes_handler: Biome

func _init(starting_seed : String, world_dimensions : Vector2i, tile_scale: float, _generate_rivers: bool):
	world_seed = starting_seed.hash()
	width = world_dimensions.x
	height = world_dimensions.y
	scale = tile_scale
	is_generate_rivers = _generate_rivers
	biomes_handler = Biome.new(world_seed, world_map)
	seed(world_seed)

func generate():
	world_map = []
	height_map = []
	potential_starts.clear()

	for x in range(width):
		var row = []
		for y in range(height):
			row.append(Biome.Types.OCEAN)
		world_map.append(row)
		height_map.append(row.duplicate())

	var height_noise = FastNoiseLite.new()
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.seed = world_seed

	var center = Vector2(width / 2, height / 2)
	var max_distance = center.length()

	var height_values = []
	for x in range(width):
		for y in range(height):
			height_map[x][y] = height_noise.get_noise_2d(x * scale, y * scale)
			height_values.append(height_map[x][y])

	var min_h = height_values.min()
	var max_h = height_values.max()
	for x in range(width):
		for y in range(height):
			height_map[x][y] = normalize(height_map[x][y], min_h, max_h)

			var distance_to_center = center.distance_to(Vector2(x, y))
			var radial_factor = distance_to_center / max_distance
			radial_factor = pow(distance_to_center / max_distance, 1)

			height_map[x][y] = clamp(height_map[x][y] - radial_factor, 0, 1)
			world_map[x][y] = determine_biome(height_map[x][y], x, y)

			if world_map[x][y] in [Biome.Types.MOUNTAIN, Biome.Types.FOREST]:
				potential_starts.append(Vector2(x, y))

	generate_lakes(0.0003)
	biomes_handler.update_world_map(world_map)
	
	if is_generate_rivers:
		generate_rivers()
	biomes_handler.update_world_map(world_map)
	apply_beaches()
	biomes_handler.update_world_map(world_map)
	fix_beaches_near_swamps()
	biomes_handler.update_world_map(world_map)
	generate_deserts()
	biomes_handler.update_world_map(world_map)

	return world_map

func count_biome_tiles(biome_type):
	var count = 0
	for x in range(width):
		for y in range(height):
			if world_map[x][y] == biome_type:
				count += 1
	return count


func fix_beaches_near_swamps():
	for x in range(width):
		for y in range(height):
			if world_map[x][y] == biomes_handler.Types.BEACH and is_near_biome(x, y, 10, biomes_handler.Types.SWAMP):
				world_map[x][y] = biomes_handler.Types.PLAINS


func normalize(val, _min, _max):
	return (val - _min) / (_max - _min)

func determine_biome(h, x, y):
	return biomes_handler.determine_biome(h, x, y)

		
func is_river_tile(x, y):
	if world_map[x][y] != biomes_handler.Types.SHALLOW_WATER:
		return false
	return not is_adjacent_to_biome(x, y, biomes_handler.Types.OCEAN)

func apply_beaches():
	var max_beach_length = int(width * 0.1)  # 10% of the map width as the maximum length
	var max_beach_width = 2  # maximum width of the beach
	for x in range(width):
		for y in range(height):
			if world_map[x][y] == biomes_handler.Types.SHALLOW_WATER and is_adjacent_to_land(x, y) and not is_river_tile(x, y):
				var beach_probability = 0.3  # Adjust this value as needed
				if randf() < beach_probability and not is_adjacent_to_biome(x, y, biomes_handler.Types.SWAMP):
					var coast_direction = get_coast_direction(x, y)
					create_beach(x, y, max_beach_length, max_beach_width, coast_direction)

func get_coast_direction(x, y):
	var water_directions = []
	var adjacent_coords = [
		Vector2(x+1, y), Vector2(x-1, y),
		Vector2(x, y+1), Vector2(x, y-1)
	]
	for coord in adjacent_coords:
		if is_inside_map(coord.x, coord.y) and world_map[coord.x][coord.y] in [biomes_handler.Types.OCEAN, biomes_handler.Types.SHALLOW_WATER]:
			water_directions.append(coord - Vector2(x, y))
	if water_directions.size() == 0:
		return Vector2(0, 0)
	# Return the primary direction of water (can be enhanced to consider multiple water directions)
	return water_directions[0]

func create_beach(x, y, length, beach_width, direction):
	var current_x = x
	var current_y = y
	for i in range(randi() % length):
		var offset = direction.normalized() * beach_width
		var start_x = int(current_x - offset.x)
		var start_y = int(current_y - offset.y)
		var end_x = int(current_x + offset.x)
		var end_y = int(current_y + offset.y)
		
		for nx in range(start_x, end_x + 1):
			for ny in range(start_y, end_y + 1):
				if is_inside_map(nx, ny) and world_map[nx][ny] == biomes_handler.Types.PLAINS:
					world_map[nx][ny] = biomes_handler.Types.BEACH

		current_x += direction.x
		current_y += direction.y

		if not is_inside_map(current_x, current_y) or world_map[current_x][current_y] in [biomes_handler.Types.MOUNTAIN, biomes_handler.Types.SNOW, biomes_handler.Types.HILLS]:
			break


func is_adjacent_to_biome(x, y, biome):
	return biomes_handler.is_adjacent_to_biome(x, y, biome)
	
func is_near_biome(x, y, proximity, biome):
	for dx in range(-proximity, proximity + 1):
		for dy in range(-proximity, proximity + 1):
			if is_inside_map(x + dx, y + dy) and world_map[x + dx][y + dy] == biome:
				return true
	return false

func is_adjacent_to_land(x, y):
	var adjacent_coords = [
		Vector2(x+1, y), Vector2(x-1, y),
		Vector2(x, y+1), Vector2(x, y-1)
	]
	for coord in adjacent_coords:
		if is_inside_map(coord.x, coord.y) and world_map[coord.x][coord.y] in [biomes_handler.Types.PLAINS, biomes_handler.Types.FOREST]:
			return true
	return false

func generate_rivers():
	var area = width * height
	var tiles_per_river = 5000
	var num_rivers = area / tiles_per_river

	if potential_starts.size() == 0:
		return

	for i in range(num_rivers):
		var random_index = randi() % potential_starts.size()
		var start_point = potential_starts[random_index]
		create_river(start_point.x, start_point.y)
		
# ... Your existing WorldDataGenerator class methods ...

func generate_deserts():
	var desert_starts = randi_range(1,3)  # Number of starting points for deserts reduced to 3
	var max_desert_size = width * height * 0.02  # 3% of the world size for each desert. Reduced from 0.1 to 0.03.
	
	var plain_tiles = []
	for x in range(width):
		for y in range(height):
			if world_map[x][y] == biomes_handler.Types.PLAINS:
				plain_tiles.append(Vector2(x, y))

	# Randomly choose starting points for the deserts
	for _i in range(desert_starts):
		if plain_tiles.size() == 0:
			break
		var start_index = randi() % plain_tiles.size()
		var start_tile = plain_tiles[start_index]
		plain_tiles.remove_at(start_index)
		
		grow_desert(start_tile, max_desert_size, plain_tiles)


func grow_desert(start_tile, _max_size, plain_tiles):
	var tiles_to_process = [start_tile]
	var processed_tiles = []
	var growth_directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1)
	]
	var max_desert_size = randf_range(0.05, _max_size)  # Increase minimum size for testing
	
	while tiles_to_process.size() > 0 and processed_tiles.size() < max_desert_size:
		var current_tile = tiles_to_process.pop_front()
		processed_tiles.append(current_tile)
		world_map[current_tile.x][current_tile.y] = biomes_handler.Types.DESERT

		# Randomize growth directions
		growth_directions.shuffle()
		
		for direction in growth_directions:
			# Commenting out random shift for now
			# var random_shift = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			# direction += random_shift
			direction = direction.normalized()

			var neighbor = current_tile + direction
			if neighbor in plain_tiles and (world_map[neighbor.x][neighbor.y] == biomes_handler.Types.PLAINS or world_map[neighbor.x][neighbor.y] == biomes_handler.Types.FOREST):
				tiles_to_process.append(neighbor)
				plain_tiles.erase(neighbor)

	# Adjust beaches nearby
	for tile in processed_tiles:
		adjust_beaches_near_desert(tile)

func adjust_beaches_near_desert(tile: Vector2):
	var adjacent_coords = [
		Vector2(tile.x+1, tile.y), Vector2(tile.x-1, tile.y),
		Vector2(tile.x, tile.y+1), Vector2(tile.x, tile.y-1)
	]
	for coord in adjacent_coords:
		if is_inside_map(coord.x, coord.y) and world_map[coord.x][coord.y] == biomes_handler.Types.SWAMP:
			world_map[coord.x][coord.y] = biomes_handler.Types.BEACH



func get_neighboring_tiles(x, y):
	var neighbors = []
	if x > 0:
		neighbors.append(Vector2(x - 1, y))
	if x < width - 1:
		neighbors.append(Vector2(x + 1, y))
	if y > 0:
		neighbors.append(Vector2(x, y - 1))
	if y < height - 1:
		neighbors.append(Vector2(x, y + 1))
	return neighbors

func create_river(x, y):
	var path = []
	var current_x = x
	var current_y = y

	var diagonal_length = sqrt(width * width + height * height)
	var river_length = int(diagonal_length * 0.5)
	var base_river_width = int(sqrt(river_length) * 0.1)

	for i in range(river_length):
		var current_width = get_river_width(base_river_width, world_map[current_x][current_y], i / float(river_length))
		for dx in range(-current_width, current_width + 1):
			for dy in range(-current_width, current_width + 1):
				var nx = current_x + dx
				var ny = current_y + dy
				if is_inside_map(nx, ny):
					path.append(Vector2(nx, ny))

		var neighbors = get_neighboring_tiles(x,y)
		
		neighbors.shuffle()

		var next_point = neighbors[0]
		for neighbor in neighbors:
			if is_inside_map(neighbor.x, neighbor.y) and height_map[neighbor.x][neighbor.y] < height_map[next_point.x][next_point.y]:
				next_point = neighbor

		if next_point == Vector2(current_x, current_y) or world_map[next_point.x][next_point.y] == biomes_handler.Types.OCEAN:
			break

		current_x = next_point.x
		current_y = next_point.y

	for point in path:
		world_map[point.x][point.y] = biomes_handler.Types.SHALLOW_WATER

func get_river_width(base_width, biome, progress):
	var width_multiplier = 1.0
	if biome == biomes_handler.Types.FOREST or biome == biomes_handler.Types.PLAINS:
		width_multiplier = 1.2
	elif biome == biomes_handler.Types.SWAMP:
		width_multiplier = 1.4
	elif biome == biomes_handler.Types.MOUNTAIN or biome == biomes_handler.Types.HILLS or biome == biomes_handler.Types.SNOW:
		width_multiplier = 0.8

	# As the river progresses, it can become wider. Let's say by a max of 50% more at the end.
	var progress_multiplier = 1.0 + progress * 0.5

	# Introduce a random fluctuation between 90% to 110%
	var random_multiplier = randf_range(0.9, 1.1)

	return int(base_width * width_multiplier * progress_multiplier * random_multiplier)

func is_inside_map(x, y):
	return x >= 0 and x < width and y >= 0 and y < height

func generate_lakes(multiplier):
	var num_lakes = int((width * height) * multiplier * 0.5)  # Reducing attempts by 50%
	for i in range(num_lakes):
		var x = randi() % width
		var y = randi() % height
		var size = randi() % 5 + 5
		if world_map[x][y] in [biomes_handler.Types.PLAINS, biomes_handler.Types.FOREST, biomes_handler.Types.SWAMP]:
			if sufficient_land_around(x, y, size) and average_height_around(x, y, size) < 0.4:  # The 0.4 threshold can be adjusted
				create_lake(x, y, size)

func average_height_around(x, y, radius):
	var total_height = 0.0
	var count = 0
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var nx = x + dx
			var ny = y + dy
			if is_inside_map(nx, ny) and Vector2(dx, dy).length() <= radius:
				total_height += height_map[nx][ny]
				count += 1
	return total_height / count


func sufficient_land_around(x, y, radius):
	var land_tiles_required = int(PI * radius * radius * 0.75)  # 75% of the tiles in the circle should be land
	var land_count = 0
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var nx = x + dx
			var ny = y + dy
			if is_inside_map(nx, ny) and Vector2(dx, dy).length() <= radius:
				if world_map[nx][ny] in [biomes_handler.Types.SWAMP, biomes_handler.Types.FOREST, biomes_handler.Types.MOUNTAIN, biomes_handler.Types.PLAINS, biomes_handler.Types.HILLS]:
					land_count += 1
	return land_count >= land_tiles_required


func create_lake(x, y, size):
	for dx in range(-size, size + 1):
		for dy in range(-size, size + 1):
			var nx = x + dx
			var ny = y + dy
			if is_inside_map(nx, ny) and Vector2(dx, dy).length() <= size:
				world_map[nx][ny] = biomes_handler.Types.SHALLOW_WATER
