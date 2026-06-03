extends TileMap
class_name HexTileMapBridge

# HexTileMapBridge — Bridges Kira's HexGrid math with Godot's TileMap editor
# Uses pointy-top hexes (matching Kira's HexGrid), 48px size
# Caleb can paint in the TileMap editor; this adds game logic on top

const HEX_SIZE: float = 48.0

# Tile atlas coordinates (column in atlas)
const ATLAS_FLOOR = Vector2i(0, 0)
const ATLAS_WALL = Vector2i(1, 0)
const ATLAS_DOOR = Vector2i(2, 0)
const ATLAS_STAIRS = Vector2i(3, 0)
const ATLAS_TRAP = Vector2i(4, 0)
const ATLAS_SPAWN = Vector2i(5, 0)
const ATLAS_EXIT = Vector2i(6, 0)

# Tile terrain IDs (used for walkable checks)
const TERRAIN_FLOOR = 0
const TERRAIN_WALL = 1
const TERRAIN_DOOR = 2
const TERRAIN_STAIRS = 3
const TERRAIN_TRAP = 4
const TERRAIN_SPAWN = 5
const TERRAIN_EXIT = 6

var player: Node2D

# Floor 3 room rotation data
var room_cells: Dictionary = {}  # room_id -> Array[Vector2i]
var room_rotations: Dictionary = {}  # room_id -> int (0-5)

func _ready():
	tile_set.tile_size = Vector2i(64, 64)  # Tile atlas cell size
	print("HexTileMapBridge: Ready with pointy-top hexes")

func _find_player() -> Node2D:
	# Look for player in scene
	var player_node = get_node_or_null("../Player")
	if player_node:
		return player_node
	# Search recursively
	for child in get_tree().root.get_children():
		var found = _find_player_in_node(child)
		if found:
			return found
	return null

func _find_player_in_node(node: Node) -> Node2D:
	if node.name == "Player" or node.is_in_group("player"):
		return node
	for child in node.get_children():
		var found = _find_player_in_node(child)
		if found:
			return found
	return null

# ==========================================
# WALKABLE CHECKS
# ==========================================

func is_walkable(hex: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex)
	if not tile_data:
		return false
	var terrain = tile_data.terrain
	return terrain in [TERRAIN_FLOOR, TERRAIN_SPAWN, TERRAIN_EXIT, TERRAIN_STAIRS, TERRAIN_DOOR]

func is_wall(hex: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex)
	if not tile_data:
		return true
	return tile_data.terrain == TERRAIN_WALL

func is_interactable(hex: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, hex)
	if not tile_data:
		return false
	return tile_data.terrain in [TERRAIN_DOOR, TERRAIN_STAIRS, TERRAIN_EXIT, TERRAIN_TRAP]

func get_spawn_hex() -> Vector2i:
	var cells = get_used_cells(0)
	for cell in cells:
		var tile_data = get_cell_tile_data(0, cell)
		if tile_data and tile_data.terrain == TERRAIN_SPAWN:
			return cell
	# Fallback: first walkable
	for cell in cells:
		if is_walkable(cell):
			return cell
	return Vector2i.ZERO

# ==========================================
# HEX NEIGHBORS
# ==========================================

func get_hex_neighbors(hex: Vector2i) -> Array[Vector2i]:
	# Pointy-top hex directions
	var directions = [
		Vector2i(0, -1),   # NW
		Vector2i(1, -1),   # NE
		Vector2i(-1, 0),   # W
		Vector2i(1, 0),    # E
		Vector2i(-1, 1),   # SW
		Vector2i(0, 1),    # SE
	]
	var neighbors: Array[Vector2i] = []
	for dir in directions:
		neighbors.append(hex + dir)
	return neighbors

func get_walkable_neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor in get_hex_neighbors(hex):
		if is_walkable(neighbor):
			result.append(neighbor)
	return result

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func world_to_hex(world_pos: Vector2) -> Vector2i:
	return local_to_map(world_pos)

func hex_to_world(hex: Vector2i) -> Vector2:
	return map_to_local(hex)

# ==========================================
# FLOOR 3: ROOM ROTATION SYSTEM
# ==========================================

func setup_floor3_rooms():
	"""Setup Floor 3's 12-room ring for rotation."""
	room_cells.clear()
	room_rotations.clear()
	
	# Room IDs: f3_r01 through f3_r12, plus f3_center
	var room_ids = ["f3_r01", "f3_r02", "f3_r03", "f3_r04", "f3_r05", "f3_r06",
		"f3_r07", "f3_r08", "f3_r09", "f3_r10", "f3_r11", "f3_r12", "f3_center"]
	
	for room_id in room_ids:
		var cells = get_cells_with_meta("room_id", room_id)
		if cells.size() > 0:
			room_cells[room_id] = cells
			room_rotations[room_id] = 0
			print("HexTileMapBridge: Room '%s' has %d cells" % [room_id, cells.size()])

func get_cells_with_meta(meta_key: String, meta_value: String) -> Array[Vector2i]:
	"""Find all cells with custom data matching key=value."""
	var result: Array[Vector2i] = []
	var cells = get_used_cells(0)
	for cell in cells:
		var tile_data = get_cell_tile_data(0, cell)
		if tile_data:
			var val = tile_data.get_custom_data(meta_key)
			if val == meta_value:
				result.append(cell)
	return result

func rotate_room(room_id: String, steps: int) -> bool:
	"""Rotate a room by N steps (60 degrees each). Returns true if successful."""
	if not room_cells.has(room_id):
		push_warning("HexTileMapBridge: Room '%s' not found" % room_id)
		return false
	
	var cells = room_cells[room_id]
	var center = _get_room_center(cells)
	
	# Backup current tile data
	var tile_backup: Dictionary = {}
	for cell in cells:
		tile_backup[cell] = {
			"source_id": get_cell_source_id(0, cell),
			"atlas_coords": get_cell_atlas_coords(0, cell),
			"terrain": get_cell_tile_data(0, cell).terrain if get_cell_tile_data(0, cell) else 0
		}
	
	# Clear old cells
	for cell in cells:
		erase_cell(0, cell)
	
	# Calculate new rotated positions
	var new_cells: Array[Vector2i] = []
	for cell in cells:
		var relative = cell - center
		var rotated = _rotate_hex(relative, steps)
		var new_pos = rotated + center
		new_cells.append(new_pos)
	
	# Update room cells
	room_cells[room_id] = new_cells
	room_rotations[room_id] = (room_rotations[room_id] + steps) % 6
	
	# Place tiles at new positions
	for i in range(cells.size()):
		var old_cell = cells[i]
		var new_cell = new_cells[i]
		var data = tile_backup[old_cell]
		set_cell(0, new_cell, data.source_id, data.atlas_coords)
	
	print("HexTileMapBridge: Rotated room '%s' by %d steps (now at rotation %d)" % [room_id, steps, room_rotations[room_id]])
	return true

func _rotate_hex(hex: Vector2i, steps: int) -> Vector2i:
	"""Rotate a hex coordinate by N steps (60 degrees) around origin."""
	var q = hex.x
	var r = hex.y
	for _i in range(steps):
		var new_q = -r
		var new_r = q + r
		q = new_q
		r = new_r
	return Vector2i(q, r)

func _get_room_center(cells: Array[Vector2i]) -> Vector2i:
	var total_q = 0
	var total_r = 0
	for cell in cells:
		total_q += cell.x
		total_r += cell.y
	var count = cells.size()
	return Vector2i(total_q / count, total_r / count)

func get_room_at(hex: Vector2i) -> String:
	for room_id in room_cells.keys():
		if hex in room_cells[room_id]:
			return room_id
	return ""

func get_room_rotation(room_id: String) -> int:
	return room_rotations.get(room_id, 0)

# ==========================================
# FLOOR 3: DIAL INTERACTION
# ==========================================

func on_dial_turned(dial_steps: int):
	"""Called when the player turns the central dial."""
	print("HexTileMapBridge: Dial turned %d steps" % dial_steps)
	
	# Rotate all rooms except center
	for room_id in room_cells.keys():
		if room_id != "f3_center":
			rotate_room(room_id, dial_steps)
	
	# Check if player is in a rotated room and adjust if needed
	if player:
		var player_hex = world_to_hex(player.position)
		var player_room = get_room_at(player_hex)
		if player_room != "" and player_room != "f3_center":
			if not is_walkable(player_hex):
				# Player is now in a wall — push to nearest walkable hex
				var neighbors = get_hex_neighbors(player_hex)
				for neighbor in neighbors:
					if is_walkable(neighbor):
						player.position = hex_to_world(neighbor)
						print("HexTileMapBridge: Player pushed to walkable hex after rotation")
						break

# ==========================================
# COMBAT SPAWNING
# ==========================================

func get_random_walkable_hex(center: Vector2i, radius: int) -> Vector2i:
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
	var result: Array[Vector2i] = []
	var cells = get_used_cells(0)
	for cell in cells:
		if is_walkable(cell):
			result.append(cell)
	return result
