extends Node2D
class_name HexTileMap

# Hex tile map for building floors out of individual hex tiles
# Each hex is a pointy-top hex with axial coordinates (q, r)

const HEX_SIZE: float = 48.0  # Radius (center to corner) - matches generated tiles
const HEX_WIDTH: float = HEX_SIZE * sqrt(3.0)  # ~83px
const HEX_HEIGHT: float = HEX_SIZE * 2.0  # ~96px

# Tile type constants
const TILE_FLOOR: int = 0
const TILE_WALL: int = 1
const TILE_OBJECT: int = 2
const TILE_VOID: int = 3
const TILE_PORTAL: int = 4

# Tile colors/textures
@export var tile_texture_floor: Texture2D
@export var tile_texture_wall: Texture2D
@export var tile_texture_object: Texture2D
@export var tile_texture_void: Texture2D

# Grid data: Vector2i(q, r) -> tile_type
var grid: Dictionary = {}

# Visual nodes
var tile_container: Node2D

# Signals
signal tile_clicked(hex: Vector2i, tile_type: int)
signal player_moved_to(hex: Vector2i)

func _ready():
	tile_container = Node2D.new()
	tile_container.name = "Tiles"
	add_child(tile_container)

func clear_grid():
	grid.clear()
	for child in tile_container.get_children():
		child.queue_free()

func set_tile(hex: Vector2i, tile_type: int):
	grid[hex] = tile_type
	_update_tile_visual(hex)

func get_tile(hex: Vector2i) -> int:
	return grid.get(hex, TILE_VOID)

func is_walkable(hex: Vector2i) -> bool:
	var tile = get_tile(hex)
	return tile == TILE_FLOOR or tile == TILE_PORTAL or tile == TILE_OBJECT

func is_wall(hex: Vector2i) -> bool:
	return get_tile(hex) == TILE_WALL

static func hex_to_world(hex: Vector2i) -> Vector2:
	"""Convert axial hex coordinates to world position (center of hex)"""
	var x = HEX_SIZE * (sqrt(3.0) * hex.x + sqrt(3.0) / 2.0 * hex.y)
	var y = HEX_SIZE * (3.0 / 2.0 * hex.y)
	return Vector2(x, y)

static func world_to_hex(world: Vector2) -> Vector2i:
	"""Convert world position to axial hex coordinates"""
	var q = (sqrt(3.0) / 3.0 * world.x - 1.0 / 3.0 * world.y) / HEX_SIZE
	var r = (2.0 / 3.0 * world.y) / HEX_SIZE
	return _hex_round(Vector2(q, r))

static func _hex_round(hex: Vector2) -> Vector2i:
	"""Round fractional hex coordinates to nearest hex"""
	var x = hex.x
	var z = hex.y
	var y = -x - z
	
	var rx = round(x)
	var rz = round(z)
	var ry = round(y)
	
	var x_diff = abs(rx - x)
	var y_diff = abs(ry - y)
	var z_diff = abs(rz - z)
	
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	
	return Vector2i(int(rx), int(rz))

static func snap_to_hex(world_pos: Vector2) -> Vector2:
	"""Snap a world position to the center of its hex"""
	return hex_to_world(world_to_hex(world_pos))

func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	"""Get all 6 neighboring hex coordinates that are walkable"""
	var dirs = [
		Vector2i(0, -1),   # NW
		Vector2i(1, -1),   # NE
		Vector2i(-1, 0),   # W
		Vector2i(1, 0),    # E
		Vector2i(-1, 1),   # SW
		Vector2i(0, 1),    # SE
	]
	var neighbors: Array[Vector2i] = []
	for dir in dirs:
		var neighbor = hex + dir
		if is_walkable(neighbor):
			neighbors.append(neighbor)
	return neighbors

func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	"""A* pathfinding between two hex coordinates"""
	if not is_walkable(end):
		return []
	
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: _hex_distance(start, end)}
	
	while open_set.size() > 0:
		# Find node with lowest f_score
		var current = open_set[0]
		var current_f = f_score.get(current, 9999)
		for node in open_set:
			if f_score.get(node, 9999) < current_f:
				current = node
				current_f = f_score[node]
		
		if current == end:
			return _reconstruct_path(came_from, end)
		
		open_set.erase(current)
		
		for neighbor in get_neighbors(current):
			var tentative_g = g_score[current] + 1
			if tentative_g < g_score.get(neighbor, 9999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _hex_distance(neighbor, end)
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	return []

static func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

static func _reconstruct_path(came_from: Dictionary, end: Vector2i) -> Array[Vector2i]:
	var path = [end]
	var current = end
	while current in came_from:
		current = came_from[current]
		path.push_front(current)
	return path

func _update_tile_visual(hex: Vector2i):
	"""Create or update the visual sprite for a hex"""
	var tile_type = get_tile(hex)
	var world_pos = hex_to_world(hex)
	
	# Remove existing visual for this hex if any
	var existing = tile_container.get_node_or_null("hex_%d_%d" % [hex.x, hex.y])
	if existing:
		existing.queue_free()
	
	var texture = _get_texture_for_tile(tile_type)
	if not texture:
		return
	
	var sprite = Sprite2D.new()
	sprite.name = "hex_%d_%d" % [hex.x, hex.y]
	sprite.texture = texture
	sprite.position = world_pos
	sprite.z_index = tile_type  # Walls on top, floor on bottom
	
	# Add collision for walls
	if tile_type == TILE_WALL:
		var static_body = StaticBody2D.new()
		var collision = CollisionPolygon2D.new()
		collision.polygon = _get_hex_polygon()
		static_body.add_child(collision)
		sprite.add_child(static_body)
	
	tile_container.add_child(sprite)

func _get_texture_for_tile(tile_type: int) -> Texture2D:
	match tile_type:
		TILE_FLOOR: return tile_texture_floor
		TILE_WALL: return tile_texture_wall
		TILE_OBJECT: return tile_texture_object
		TILE_VOID: return tile_texture_void
		TILE_PORTAL: return tile_texture_floor
		_: return tile_texture_void

func _get_hex_polygon() -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60 * i - 30  # Pointy-top
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(
			HEX_SIZE * cos(angle_rad),
			HEX_SIZE * sin(angle_rad)
		))
	return points

# ===================================================================
# FLOOR 1 LAYOUT GENERATOR
# ===================================================================

func generate_floor1_layout():
	"""Generate the hex layout for Floor 1"""
	clear_grid()
	
	# Entry room: roughly 7x7 hex area centered at (0,0)
	# Let's make a roughly circular room with walls around the edges
	_generate_room("entry", Vector2i(0, 0), 4, [
		Vector2i(0, -4),  # Portal North
		Vector2i(4, 0),   # Portal East
		Vector2i(0, 4),   # Portal South
	])
	
	# Upper room (North of entry)
	_generate_room("upper", Vector2i(0, -12), 4, [
		Vector2i(0, -16), # Portal North (to boss)
		Vector2i(0, -8),  # Portal South (back to entry)
	])
	
	# Middle room (East of entry)
	_generate_room("middle", Vector2i(12, 0), 4, [
		Vector2i(8, 0),   # Portal West (back to entry)
		Vector2i(16, 0),  # Portal East
	])
	
	# Lower room (South of entry)
	_generate_room("lower", Vector2i(0, 12), 4, [
		Vector2i(0, 8),   # Portal North (back to entry)
		Vector2i(0, 16),  # Portal South (to secret)
	])
	
	# Secret room (South of lower)
	_generate_room("secret", Vector2i(0, 24), 3, [
		Vector2i(0, 20),  # Portal North (back to lower)
	])
	
	# Spore heart room (East of middle)
	_generate_room("spore_heart", Vector2i(24, 0), 3, [
		Vector2i(20, 0),  # Portal West (back to middle)
	])

func _generate_room(room_id: String, center: Vector2i, radius: int, portal_positions: Array[Vector2i]):
	"""Generate a roughly circular room with walls at edges"""
	for q in range(center.x - radius - 1, center.x + radius + 2):
		for r in range(center.y - radius - 1, center.y + radius + 2):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			
			# Check if this hex is a portal
			var is_portal = false
			for portal_hex in portal_positions:
				if hex == portal_hex:
					is_portal = true
					break
			
			if is_portal:
				set_tile(hex, TILE_PORTAL)
			elif dist <= radius - 1:
				# Inner area: floor
				set_tile(hex, TILE_FLOOR)
			elif dist <= radius:
				# Edge: wall (with some openings for portals)
				var near_portal = false
				for portal_hex in portal_positions:
					if _hex_distance(hex, portal_hex) <= 1:
						near_portal = true
						break
				if near_portal:
					set_tile(hex, TILE_FLOOR)
				else:
					set_tile(hex, TILE_WALL)
			else:
				# Outside room: void
				set_tile(hex, TILE_VOID)

# ===================================================================
# PORTAL / ROOM TRANSITION HELPERS
# ===================================================================

func get_room_center(room_id: String) -> Vector2i:
	"""Get the center hex of a room"""
	match room_id:
		"entry": return Vector2i(0, 0)
		"upper": return Vector2i(0, -12)
		"middle": return Vector2i(12, 0)
		"lower": return Vector2i(0, 12)
		"secret": return Vector2i(0, 24)
		"spore_heart": return Vector2i(24, 0)
		_: return Vector2i.ZERO

func get_portal_destination(from_hex: Vector2i, direction: int) -> Vector2i:
	"""Given a hex and direction, find the connected portal hex"""
	var dirs = [
		Vector2i(0, -1),   # NW (0)
		Vector2i(1, -1),   # NE (1)
		Vector2i(-1, 0),   # W (2)
		Vector2i(1, 0),    # E (3)
		Vector2i(-1, 1),   # SW (4)
		Vector2i(0, 1),    # SE (5)
	]
	
	var neighbor = from_hex + dirs[direction]
	if get_tile(neighbor) == TILE_PORTAL:
		return neighbor
	return Vector2i(-9999, -9999)
