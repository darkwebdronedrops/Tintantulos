extends TileMap
class_name HexMapController

# HexMapController — Manages hex-based floors, player movement, room rotation
# For Floor 3: Rooms rotate around a central axis when dial is turned

enum HexShape {FLAT_TOP, POINTY_TOP}

@export var hex_shape: HexShape = HexShape.FLAT_TOP
@export var tile_size: int = 64

var player: Node2D
var current_room_cells: Dictionary = {}  # room_id -> Array[Vector2i] of hex coords
var rotated_rooms: Dictionary = {}  # room_id -> int (rotation steps, 0-5)

# TileSet tile IDs (set these in editor)
var TILE_FLOOR: int = 0
var TILE_WALL: int = 1
var TILE_DOOR: int = 2
var TILE_STAIRS: int = 3
var TILE_TRAP: int = 4
var TILE_SPAWN: int = 5
var TILE_EXIT: int = 6

# Floor 3 specific: Central dial room
var DIAL_CENTER: Vector2i = Vector2i(0, 0)
var ROOM_RADIUS: int = 3

func _ready():
	# Ensure tile size matches
	if tile_set:
		tile_set.tile_size = Vector2i(tile_size, tile_size)
	
	print("HexMapController: Ready with %s hexes, size %d" % [
		"flat-top" if hex_shape == HexShape.FLAT_TOP else "pointy-top",
		tile_size
	])

func get_spawn_position() -> Vector2:
	# Find tile with TILE_SPAWN
	var cells = get_used_cells(0)
	for cell in cells:
		var tile_data = get_cell_tile_data(0, cell)
		if tile_data:
			var tile_id = tile_data.terrain
			if tile_id == TILE_SPAWN:
				return map_to_local(cell)
	
	# Fallback: first walkable cell
	for cell in cells:
		if is_walkable(cell):
			return map_to_local(cell)
	
	return Vector2.ZERO

func is_walkable(hex_coord: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex_coord)
	if not tile_data:
		return false
	var tile_id = tile_data.terrain
	return tile_id in [TILE_FLOOR, TILE_SPAWN, TILE_EXIT, TILE_STAIRS]

func is_wall(hex_coord: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex_coord)
	if not tile_data:
		return true  # Empty = wall
	var tile_id = tile_data.terrain
	return tile_id == TILE_WALL

func is_interactable(hex_coord: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex_coord)
	if not tile_data:
		return false
	var tile_id = tile_data.terrain
	return tile_id in [TILE_DOOR, TILE_STAIRS, TILE_EXIT]

func get_hex_neighbors(hex_coord: Vector2i) -> Array[Vector2i]:
	# Axial directions for flat-top hexes
	var directions = [
		Vector2i(1, 0),   # East
		Vector2i(1, -1),  # Northeast
		Vector2i(0, -1),  # Northwest
		Vector2i(-1, 0),  # West
		Vector2i(-1, 1),  # Southwest
		Vector2i(0, 1),   # Southeast
	]
	
	var neighbors: Array[Vector2i] = []
	for dir in directions:
		neighbors.append(hex_coord + dir)
	return neighbors

func get_walkable_neighbors(hex_coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor in get_hex_neighbors(hex_coord):
		if is_walkable(neighbor):
			result.append(neighbor)
	return result

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	# Axial distance formula
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func world_to_hex(world_pos: Vector2) -> Vector2i:
	return local_to_map(world_pos)

func hex_to_world(hex_coord: Vector2i) -> Vector2:
	return map_to_local(hex_coord)

# ==========================================
# FLOOR 3: ROOM ROTATION SYSTEM
# ==========================================

func setup_floor3_rooms(room_configs: Array[Dictionary]):
	"""Setup rooms that can rotate around the central dial.
	room_configs: [{id: String, center: Vector2i, radius: int, tile_data: Array}]
	"""
	for config in room_configs:
		var room_id = config.id
		var center = config.center
		var radius = config.radius
		
		# Store all cells in this room
		var cells: Array[Vector2i] = []
		for q in range(-radius, radius + 1):
			for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
				var hex = center + Vector2i(q, r)
				cells.append(hex)
		
		current_room_cells[room_id] = cells
		rotated_rooms[room_id] = 0

func rotate_room(room_id: String, steps: int):
	"""Rotate a room around the dial center by N steps (60 degrees each).
	Returns true if rotation successful."""
	if not current_room_cells.has(room_id):
		push_warning("HexMapController: Room '%s' not found" % room_id)
		return false
	
	var cells = current_room_cells[room_id]
	var room_center = _get_room_center(cells)
	
	# Store current tile data before rotation
	var tile_data_backup: Dictionary = {}
	for cell in cells:
		var td = get_cell_tile_data(0, cell)
		if td:
			tile_data_backup[cell] = {
				"source_id": get_cell_source_id(0, cell),
				"atlas_coords": get_cell_atlas_coords(0, cell),
				"terrain": td.terrain
			}
		else:
			tile_data_backup[cell] = null
	
	# Clear old cells
	for cell in cells:
		erase_cell(0, cell)
	
	# Calculate new rotated positions
	var new_cells: Array[Vector2i] = []
	for cell in cells:
		var relative = cell - room_center
		var rotated = _rotate_hex(relative, steps)
		var new_pos = rotated + room_center
		new_cells.append(new_pos)
	
	# Update room cells
	current_room_cells[room_id] = new_cells
	rotated_rooms[room_id] = (rotated_rooms[room_id] + steps) % 6
	
	# Place tiles at new positions
	for i in range(cells.size()):
		var old_cell = cells[i]
		var new_cell = new_cells[i]
		var data = tile_data_backup[old_cell]
		if data:
			set_cell(0, new_cell, data.source_id, data.atlas_coords)
	
	print("HexMapController: Rotated room '%s' by %d steps" % [room_id, steps])
	return true

func _rotate_hex(hex: Vector2i, steps: int) -> Vector2i:
	"""Rotate a hex coordinate by N steps (60 degrees) around origin."""
	var q = hex.x
	var r = hex.y
	
	for _i in range(steps):
		# 60 degree rotation: (q, r) -> (-r, q + r)
		var new_q = -r
		var new_r = q + r
		q = new_q
		r = new_r
	
	return Vector2i(q, r)

func _get_room_center(cells: Array[Vector2i]) -> Vector2i:
	"""Calculate center of a room from its cells."""
	var total_q = 0
	var total_r = 0
	for cell in cells:
		total_q += cell.x
		total_r += cell.y
	
	var count = cells.size()
	return Vector2i(total_q / count, total_r / count)

func get_room_at(hex_coord: Vector2i) -> String:
	"""Get room ID that contains this hex, or empty string."""
	for room_id in current_room_cells.keys():
		if hex_coord in current_room_cells[room_id]:
			return room_id
	return ""

func get_room_rotation(room_id: String) -> int:
	"""Get current rotation of a room (0-5, representing 60° steps)."""
	return rotated_rooms.get(room_id, 0)

# ==========================================
# COMBAT SPAWNING
# ==========================================

func get_random_walkable_hex(center: Vector2i, radius: int) -> Vector2i:
	"""Find a random walkable hex within radius of center."""
	var attempts = 0
	while attempts < 50:
		var q = randi_range(-radius, radius)
		var r = randi_range(-radius, radius)
		var hex = center + Vector2i(q, r)
		if is_walkable(hex):
			return hex
		attempts += 1
	
	return center

func get_all_walkable_hexes() -> Array[Vector2i]:
	"""Get all walkable hexes on the map."""
	var result: Array[Vector2i] = []
	var cells = get_used_cells(0)
	for cell in cells:
		if is_walkable(cell):
			result.append(cell)
	return result
