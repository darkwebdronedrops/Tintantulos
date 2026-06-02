extends Node2D
class_name HexFloorController

@export var floor_id: int = 1

var tile_map: TileMap

func _ready():
	tile_map = $TileMap
	print("HexFloorController: Floor %d loaded with TileMap" % floor_id)

func get_player_spawn() -> Vector2:
	# Find first walkable tile
	var cells = tile_map.get_used_cells(0)
	for cell in cells:
		var data = tile_map.get_cell_tile_data(0, cell)
		if data and data.get_custom_data("walkable"):
			return tile_map.map_to_local(cell)
	return Vector2.ZERO

func get_walkable_neighbors(pos: Vector2) -> Array[Vector2]:
	var cell = tile_map.local_to_map(pos)
	var neighbors = []
	var dirs = tile_map.get_surrounding_cells(cell)
	for n in dirs:
		var data = tile_map.get_cell_tile_data(0, n)
		if data and data.get_custom_data("walkable"):
			neighbors.append(tile_map.map_to_local(n))
	return neighbors
