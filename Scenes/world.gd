extends Node2D

@export var world_seed = "DTWorldz"
@export var width : int = 100
@export var height : int = 100
@export var tile_scale : float = 1.0
@export var use_island_noise : bool = false
@export var generate_rivers : bool = false

var tile_atlas_mapping = {
	0:Vector2i(16,16),
	1:Vector2i(8,16),
	2:Vector2i(16,21),
	3:Vector2i(10,21),
	4:Vector2i(0,4),
	5:Vector2i(2,0),
	6:Vector2i(3,3),
	7:Vector2i(15,3),
	8:Vector2i(17,1),
	9:Vector2i(7,0)
}

var world_map: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$TileMap.clear()
	generate_world()
	render_world()
	
	
func generate_world():
	var mapDataGenerator = WorldDataGenerator.new(world_seed, Vector2i(width, height), tile_scale, generate_rivers)
	world_map = mapDataGenerator.generate();
	
func render_world():
	for x in range(width):
		for y in range(height):
			$TileMap.set_cell(0, Vector2i(x,y), 0, tile_atlas_mapping[world_map[x][y]])
	pass
