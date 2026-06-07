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
const TILE_WATER: int = 5

# Directions for pointy-top hexes
const DIRECTIONS = [
	Vector2i(0, -1),   # NW
	Vector2i(1, -1),   # NE
	Vector2i(-1, 0),   # W
	Vector2i(1, 0),    # E
	Vector2i(-1, 1),   # SW
	Vector2i(0, 1),    # SE
]

# Tile colors/textures
@export var tile_texture_floor: Texture2D
@export var tile_texture_wall: Texture2D
@export var tile_texture_object: Texture2D
@export var tile_texture_void: Texture2D
@export var tile_texture_water: Texture2D

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

static func _hex_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	"""Get all hexes in a line from a to b"""
	var N = _hex_distance(a, b)
	if N == 0:
		return [a]
	
	var results: Array[Vector2i] = []
	for i in range(N + 1):
		var t = float(i) / N
		var interpolated = Vector2(
			lerp(a.x, b.x, t),
			lerp(a.y, b.y, t)
		)
		results.append(_hex_round(interpolated))
	return results

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
	
	# Add collision for walls and water
	if tile_type == TILE_WALL or tile_type == TILE_WATER:
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
		TILE_WATER: return tile_texture_water if tile_texture_water else tile_texture_void
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
	"""Generate the hex layout for Floor 1 — expanded with corridors and patrol zones"""
	clear_grid()
	
	# Room definitions: center, radius, list of portal hexes (direction from center)
	# All rooms have radius 5-6 with corridors connecting them
	
	# === ENTRY ROOM (central hub) ===
	_generate_room("entry", Vector2i(0, 0), 6, [
		Vector2i(0, -7),   # North portal -> upper corridor
		Vector2i(7, 0),    # East portal -> middle corridor  
		Vector2i(0, 7),    # South portal -> lower corridor
		Vector2i(-4, -4),  # Northwest portal (locked initially)
	])
	
	# === NORTH CORRIDOR (entry to upper) ===
	# 3-hex wide corridor, length ~10 hexes
	_generate_corridor("north_corridor", Vector2i(0, -8), Vector2i(0, -18), 2)
	# Patrol zone in middle of corridor
	_generate_patrol_zone("north_patrol", Vector2i(0, -13), 3)
	
	# === UPPER ROOM ===
	_generate_room("upper", Vector2i(0, -24), 6, [
		Vector2i(0, -18),  # South portal (back to corridor)
		Vector2i(0, -30),  # North portal (to boss, locked)
	])
	
	# === EAST CORRIDOR (entry to middle) ===
	_generate_corridor("east_corridor", Vector2i(8, 0), Vector2i(18, 0), 2)
	# Patrol zone
	_generate_patrol_zone("east_patrol", Vector2i(13, 0), 3)
	
	# === MIDDLE ROOM ===
	_generate_room("middle", Vector2i(24, 0), 6, [
		Vector2i(18, 0),   # West portal (back to corridor)
		Vector2i(30, 0),   # East portal (to spore corridor)
	])
	
	# === SOUTH CORRIDOR (entry to lower) ===
	_generate_corridor("south_corridor", Vector2i(0, 8), Vector2i(0, 18), 2)
	# Patrol zone
	_generate_patrol_zone("south_patrol", Vector2i(0, 13), 3)
	
	# === LOWER ROOM ===
	_generate_room("lower", Vector2i(0, 24), 6, [
		Vector2i(0, 18),   # North portal (back to corridor)
		Vector2i(0, 30),   # South portal (to secret corridor)
	])
	
	# === SECRET CORRIDOR (lower to secret) ===
	_generate_corridor("secret_corridor", Vector2i(0, 31), Vector2i(0, 38), 2)
	
	# === SECRET ROOM ===
	_generate_room("secret", Vector2i(0, 44), 5, [
		Vector2i(0, 38),   # North portal (back to corridor)
	])
	
	# === SPORE CORRIDOR (middle to spore heart) ===
	_generate_corridor("spore_corridor", Vector2i(31, 0), Vector2i(38, 0), 2)
	
	# === SPORE HEART ROOM ===
	_generate_room("spore_heart", Vector2i(44, 0), 5, [
		Vector2i(38, 0),   # West portal (back to corridor)
	])
	
	print("[HexTileMap] Floor 1 layout generated: 6 rooms + 5 corridors + 3 patrol zones")

func _generate_corridor(corridor_id: String, start: Vector2i, end: Vector2i, width: int):
	"""Generate a corridor between two points, width in hexes"""
	var path = _hex_line(start, end)
	for hex in path:
		# Create a "width" around each path hex
		for dq in range(-width, width + 1):
			for dr in range(-width, width + 1):
				var check = Vector2i(hex.x + dq, hex.y + dr)
				# Only place floor if not already occupied by a room or wall
				var existing = get_tile(check)
				if existing == TILE_VOID or existing == TILE_PORTAL:
					set_tile(check, TILE_FLOOR)

func _generate_patrol_zone(zone_id: String, center: Vector2i, radius: int):
	"""Generate an open patrol zone where enemies can move"""
	for q in range(center.x - radius, center.x + radius + 1):
		for r in range(center.y - radius, center.y + radius + 1):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			if dist <= radius:
				var existing = get_tile(hex)
				if existing == TILE_VOID:
					set_tile(hex, TILE_FLOOR)
				elif existing == TILE_WALL:
					# Replace wall with floor in patrol zones
					set_tile(hex, TILE_FLOOR)

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
				# Edge: wall (with openings for portals)
				var near_portal = false
				for portal_hex in portal_positions:
					if _hex_distance(hex, portal_hex) <= 1:
						near_portal = true
						break
				if near_portal:
					set_tile(hex, TILE_FLOOR)
				else:
					set_tile(hex, TILE_WALL)
			# Don't override corridors that extend beyond room radius

func _generate_water_ring(water_id: String, center: Vector2i, inner_radius: int, thickness: int):
	"""Generate a ring of water tiles around a center point (non-walkable barrier)"""
	for q in range(center.x - inner_radius - thickness, center.x + inner_radius + thickness + 1):
		for r in range(center.y - inner_radius - thickness, center.y + inner_radius + thickness + 1):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			if dist >= inner_radius and dist < inner_radius + thickness:
				var existing = get_tile(hex)
				# Only place water on void tiles (don't overwrite rooms/corridors)
				if existing == TILE_VOID:
					set_tile(hex, TILE_WATER)

func _set_water_gap(center: Vector2i, radius: int):
	"""Place water in a small area to create a gap/hazard"""
	for q in range(center.x - radius, center.x + radius + 1):
		for r in range(center.y - radius, center.y + radius + 1):
			var hex = Vector2i(q, r)
			if _hex_distance(hex, center) <= radius:
				var existing = get_tile(hex)
				if existing == TILE_FLOOR:
					set_tile(hex, TILE_WATER)

# ===================================================================
# PORTAL / ROOM TRANSITION HELPERS
# ===================================================================

func get_room_center(room_id: String) -> Vector2i:
	"""Get the center hex of a room"""
	match room_id:
		# Floor 1
		"entry": return Vector2i(0, 0)
		"upper": return Vector2i(0, -24)
		"middle": return Vector2i(24, 0)
		"lower": return Vector2i(0, 24)
		"secret": return Vector2i(0, 44)
		"spore_heart": return Vector2i(44, 0)
		# Floor 2
		"f2_entry": return Vector2i(0, 0)
		"f2_upper": return Vector2i(0, -20)
		"f2_middle": return Vector2i(18, 0)
		"f2_lower": return Vector2i(0, 20)
		"f2_secret": return Vector2i(8, 32)
		"f2_spore_heart": return Vector2i(-18, 32)
		# Floor 3
		"f3_center": return Vector2i(0, 0)
		"f3_r01": return Vector2i(0, -20)
		"f3_r02": return Vector2i(10, -17)
		"f3_r03": return Vector2i(17, -10)
		"f3_r04": return Vector2i(20, 0)
		"f3_r05": return Vector2i(17, 10)
		"f3_r06": return Vector2i(10, 17)
		"f3_r07": return Vector2i(0, 20)
		"f3_r08": return Vector2i(-10, 17)
		"f3_r09": return Vector2i(-17, 10)
		"f3_r10": return Vector2i(-20, 0)
		"f3_r11": return Vector2i(-17, -10)
		"f3_r12": return Vector2i(-10, -17)
		# Floor 4
		"f4_main": return Vector2i(0, 0)
		"f4_undercroft": return Vector2i(0, 30)
		"f4_refectory": return Vector2i(0, -30)
		# Floor 5
		"f5_dock": return Vector2i(0, 0)
		"f5_breeze": return Vector2i(0, -20)
		"f5_boiler": return Vector2i(18, 0)
		"f5_gale": return Vector2i(0, 20)
		"f5_crow": return Vector2i(0, -40)
		"f5_cargo": return Vector2i(28, 0)
		_: return Vector2i.ZERO

# ===================================================================
# FLOOR 2 LAYOUT GENERATOR — The Fungal Cavern
# ===================================================================

func generate_floor2_layout():
	"""Generate hex layout for Floor 2 — organic cavern with fungal bridges"""
	clear_grid()
	
	# === ENTRY CAVERN (starting area, slightly irregular) ===
	_generate_irregular_room("f2_entry", Vector2i(0, 0), 7, [
		Vector2i(0, -8),   # North portal → upper
		Vector2i(8, 0),    # East portal → middle
		Vector2i(0, 8),    # South portal → lower
	])
	
	# === FUNGAL BRIDGE (entry to upper) ===
	_generate_organic_corridor("f2_bridge_n", Vector2i(0, -9), Vector2i(0, -16), 2)
	_generate_patrol_zone("f2_patrol_n", Vector2i(0, -12), 3)
	
	# === UPPER CAVERN (north, spore-heavy) ===
	_generate_irregular_room("f2_upper", Vector2i(0, -24), 7, [
		Vector2i(0, -17),   # South portal (back)
		Vector2i(0, -31),  # North portal → spore heart
	])
	
	# === FUNGAL BRIDGE (entry to middle) ===
	_generate_organic_corridor("f2_bridge_e", Vector2i(9, 0), Vector2i(16, 0), 2)
	_generate_patrol_zone("f2_patrol_e", Vector2i(12, 0), 3)
	
	# === MIDDLE CAVERN (east, fungal growth chamber) ===
	_generate_irregular_room("f2_middle", Vector2i(24, 0), 7, [
		Vector2i(17, 0),    # West portal (back)
		Vector2i(31, 0),   # East portal → spore heart
	])
	
	# === FUNGAL BRIDGE (entry to lower) ===
	_generate_organic_corridor("f2_bridge_s", Vector2i(0, 9), Vector2i(0, 16), 2)
	_generate_patrol_zone("f2_patrol_s", Vector2i(0, 12), 3)
	
	# === LOWER CAVERN (south, secret hidden here) ===
	_generate_irregular_room("f2_lower", Vector2i(0, 24), 7, [
		Vector2i(0, 17),    # North portal (back)
		Vector2i(8, 29),    # Secret portal (hidden)
		Vector2i(-8, 29),   # Spore heart portal
	])
	
	# === SECRET ROOM (hidden off lower, small) ===
	_generate_irregular_room("f2_secret", Vector2i(12, 34), 4, [
		Vector2i(8, 30),    # Portal back to lower
	])
	
	# === SPORE HEART (boss chamber, deep below) ===
	_generate_irregular_room("f2_spore_heart", Vector2i(-16, 36), 8, [
		Vector2i(-10, 28),  # Portal back to lower
		Vector2i(-22, 28),  # Portal back to middle
	])
	
	# Add some "fungal pillar" objects in caverns
	_add_fungal_pillars("f2_entry", Vector2i(0, 0), 7, 3)
	_add_fungal_pillars("f2_upper", Vector2i(0, -24), 7, 4)
	_add_fungal_pillars("f2_middle", Vector2i(24, 0), 7, 4)
	_add_fungal_pillars("f2_lower", Vector2i(0, 24), 7, 3)
	
	# === WATER FEATURES ===
	# Ring of water around the Lower Pool (non-walkable barrier)
	_generate_water_ring("f2_lower_pool", Vector2i(0, 24), 9, 2)
	# Water hazard in Spore Heart chamber (atmosphere)
	_generate_water_ring("f2_spore_pool", Vector2i(-16, 36), 10, 1)
	# Small water gap in east corridor (forces bridge or detour)
	_set_water_gap(Vector2i(12, 0), 2)
	
	print("[HexTileMap] Floor 2 layout generated: organic caverns + fungal bridges + water hazards")

# ===================================================================
# FLOOR 3 LAYOUT GENERATOR — The Gearworks
# ===================================================================

func generate_floor3_layout():
	"""Generate hex layout for Floor 3 — 12 rooms in a ring around Kami Shrine"""
	clear_grid()
	
	# === CENTRAL KAMI SHRINE (inner circle, radius 4) ===
	_generate_room("f3_center", Vector2i(0, 0), 4, [
		# No portals — accessed by solving water puzzle in rooms
	])
	# Mark center as special shrine tiles
	for q in range(-2, 3):
		for r in range(-2, 3):
			var hex = Vector2i(q, r)
			if _hex_distance(hex, Vector2i(0, 0)) <= 2:
				set_tile(hex, TILE_OBJECT)  # Shrine platform
	
	# === OUTER RING — 12 rooms ===
	# Ring radius: 20 hexes from center
	# Room 12 at top (12 o'clock), then 1-11 clockwise
	var ring_radius = 20
	var room_centers = [
		Vector2i(0, -ring_radius),      # 12: The Quench (start)
		Vector2i(10, -17),             # 1: The Reservoir
		Vector2i(17, -10),             # 2: The Spark
		Vector2i(20, 0),               # 3: The Governor
		Vector2i(17, 10),              # 4: The Draft
		Vector2i(10, 17),              # 5: The Temper
		Vector2i(0, ring_radius),       # 6: The Beacon (boss room)
		Vector2i(-10, 17),             # 7: The Escapement
		Vector2i(-17, 10),             # 8: The Bearing
		Vector2i(-20, 0),              # 9: The Flywheel (boss room)
		Vector2i(-17, -10),            # 10: The Counterweight
		Vector2i(-10, -17),            # 11: The Oiler (boss room)
	]
	
	var room_names = [
		"f3_r12", "f3_r01", "f3_r02", "f3_r03", "f3_r04", "f3_r05",
		"f3_r06", "f3_r07", "f3_r08", "f3_r09", "f3_r10", "f3_r11"
	]
	
	for i in range(12):
		var room_id = room_names[i]
		var center = room_centers[i]
		
		# Portals: connect to adjacent rooms in ring
		var portals = []
		var prev_idx = (i - 1 + 12) % 12
		var next_idx = (i + 1) % 12
		# Portal toward previous room
		var prev_dir = (room_centers[prev_idx] - center).normalized()
		portals.append(center + Vector2i(round(prev_dir.x * 5), round(prev_dir.y * 5)))
		# Portal toward next room  
		var next_dir = (room_centers[next_idx] - center).normalized()
		portals.append(center + Vector2i(round(next_dir.x * 5), round(next_dir.y * 5)))
		
		_generate_room(room_id, center, 5, portals)
	
	# === RING CORRIDORS ===
	# Connect each room to its neighbors
	for i in range(12):
		var a = room_centers[i]
		var b = room_centers[(i + 1) % 12]
		_generate_corridor("f3_ring_%d" % i, a, b, 1)
	
	# === PATROL ZONES ===
	# Between rooms on the ring
	for i in range(12):
		var mid = Vector2i((room_centers[i].x + room_centers[(i + 1) % 12].x) / 2,
		                   (room_centers[i].y + room_centers[(i + 1) % 12].y) / 2)
		_generate_patrol_zone("f3_patrol_%d" % i, mid, 2)
	
	print("[HexTileMap] Floor 3 layout generated: 12-room ring + Kami Shrine center")

# ===================================================================
# FLOOR 4 LAYOUT GENERATOR — The Curio Bazaar
# ===================================================================

func generate_floor4_layout():
	"""Generate hex layout for Floor 4 — circular bazaar with 12 booths"""
	clear_grid()
	
	# === MAIN BAZAAR (large open oval, radius 14) ===
	_generate_room("f4_main", Vector2i(0, 0), 14, [
		Vector2i(0, -15),   # North portal → refectory
		Vector2i(0, 15),   # South portal → undercroft
	])
	
	# Great Lifter center object
	set_tile(Vector2i(0, 0), TILE_OBJECT)
	set_tile(Vector2i(1, 0), TILE_OBJECT)
	set_tile(Vector2i(-1, 0), TILE_OBJECT)
	set_tile(Vector2i(0, 1), TILE_OBJECT)
	set_tile(Vector2i(0, -1), TILE_OBJECT)
	
	# === UNDERCOFT (below bazaar, dungeon-like) ===
	_generate_room("f4_undercroft", Vector2i(0, 30), 10, [
		Vector2i(0, 20),   # Portal back to bazaar
	])
	
	# === PART OBJECTS (visible gear parts in undercroft) ===
	# Place 3 part objects as visible tiles
	var part_positions = [Vector2i(-4, 28), Vector2i(4, 32), Vector2i(0, 36)]
	for part_hex in part_positions:
		set_tile(part_hex, TILE_OBJECT)
	
	# Aether slick zones (water tiles in undercroft)
	for q in range(-3, 4):
		for r in range(27, 34):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, Vector2i(0, 30))
			if dist >= 3 and dist <= 6:
				set_tile(hex, TILE_WATER)
	
	# === REFECTORY (above bazaar, dining hall) ===
	_generate_room("f4_refectory", Vector2i(0, -30), 10, [
		Vector2i(0, -20),  # Portal back to bazaar
	])
	
	# Food station objects around refectory perimeter
	for q in range(-8, 9):
		for r in range(-38, -23):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, Vector2i(0, -30))
			if dist >= 6 and dist <= 8:
				set_tile(hex, TILE_OBJECT)
	
	# === BOOTH POSITIONS (12 positions around bazaar perimeter) ===
	# Like a clock: booth_12 at top, then 1-11 clockwise
	var booth_positions = [
		Vector2i(0, -14),    # 12
		Vector2i(7, -12),     # 1
		Vector2i(12, -7),     # 2
		Vector2i(14, 0),      # 3
		Vector2i(12, 7),      # 4
		Vector2i(7, 12),      # 5
		Vector2i(0, 14),      # 6
		Vector2i(-7, 12),     # 7
		Vector2i(-12, 7),     # 8
		Vector2i(-14, 0),     # 9
		Vector2i(-12, -7),    # 10
		Vector2i(-7, -12),    # 11
	]
	
	# Place booth objects (interactive, not walls)
	for pos in booth_positions:
		set_tile(pos, TILE_OBJECT)
		# Make surrounding walkable
		for dir in DIRECTIONS:
			var neighbor = pos + dir
			if get_tile(neighbor) == TILE_VOID:
				set_tile(neighbor, TILE_FLOOR)
	
	# === CORRIDORS ===
	_generate_corridor("f4_to_undercroft", Vector2i(0, 15), Vector2i(0, 20), 2)
	_generate_corridor("f4_to_refectory", Vector2i(0, -15), Vector2i(0, -20), 2)
	
	print("[HexTileMap] Floor 4 layout generated: bazaar + 12 booths + undercroft + refectory + Great Lifter + Aether Slick")

# ===================================================================
# FLOOR 5 LAYOUT GENERATOR — The Airship Docks
# ===================================================================

func generate_floor5_layout():
	"""Generate hex layout for Floor 5 — airship docks with moorings and storm"""
	clear_grid()
	
	# === MAIN DOCK (center hub, radius 8) ===
	_generate_room("f5_dock", Vector2i(0, 0), 8, [
		Vector2i(0, -8),    # North bridge start
		Vector2i(8, 0),     # East bridge start
		Vector2i(0, 8),     # South bridge start
	])
	
	# === WOODEN BRIDGES (walkable, not portals) ===
	# Bridge to Breeze (north)
	_generate_bridge("f5_bridge_n", Vector2i(0, -8), Vector2i(0, -14), TILE_FLOOR)
	# Bridge to Boiler (east)
	_generate_bridge("f5_bridge_e", Vector2i(8, 0), Vector2i(12, 0), TILE_FLOOR)
	# Bridge to Gale (south)
	_generate_bridge("f5_bridge_s", Vector2i(0, 8), Vector2i(0, 14), TILE_FLOOR)
	# Bridge to Crow's Nest (north-high, locked)
	_generate_bridge("f5_bridge_crow", Vector2i(0, -26), Vector2i(0, -32), TILE_FLOOR)
	
	# === BREEZE SHIP (north, wind-themed) ===
	_generate_ship("f5_breeze", Vector2i(0, -20), 6, "wind")
	# Portals at ship edge
	set_tile(Vector2i(0, -14), TILE_PORTAL)  # Back to bridge
	set_tile(Vector2i(0, -26), TILE_PORTAL)  # Up to crow (locked)
	
	# === BOILER SHIP (east, steam-themed) ===
	_generate_ship("f5_boiler", Vector2i(18, 0), 6, "steam")
	set_tile(Vector2i(12, 0), TILE_PORTAL)   # Back to bridge
	set_tile(Vector2i(24, 0), TILE_PORTAL)   # Secret → cargo
	
	# === GALE SHIP (south, storm-themed) ===
	_generate_ship("f5_gale", Vector2i(0, 20), 6, "storm")
	set_tile(Vector2i(0, 14), TILE_PORTAL)   # Back to bridge
	set_tile(Vector2i(0, 26), TILE_PORTAL)   # Up to crow
	
	# === CROW'S NEST (boss arena, north high, locked until valves) ===
	_generate_room("f5_crow", Vector2i(0, -40), 8, [
		Vector2i(0, -32),   # Down to bridge
	])
	# Boss altar objects
	for offset in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		set_tile(Vector2i(0, -40) + offset, TILE_OBJECT)
	
	# === SECRET CARGO HOLD (hidden off boiler ship) ===
	_generate_room("f5_cargo", Vector2i(28, 0), 4, [
		Vector2i(22, 0),    # Exit to boiler
	])
	# Cargo objects
	set_tile(Vector2i(28, 0), TILE_OBJECT)
	set_tile(Vector2i(28, 2), TILE_OBJECT)
	
	# === HAZARD ZONES (storm tiles around ships) ===
	# Storm around Gale ship
	for q in range(-4, 5):
		for r in range(22, 28):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, Vector2i(0, 20))
			if dist >= 5 and dist <= 7:
				set_tile(hex, TILE_WATER)
	# Wind around Breeze ship
	for q in range(-4, 5):
		for r in range(-28, -22):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, Vector2i(0, -20))
			if dist >= 5 and dist <= 7:
				set_tile(hex, TILE_WATER)
	
	print("[HexTileMap] Floor 5 layout generated: dock + 3 ships + wooden bridges + boss arena + cargo hold")

func _generate_bridge(bridge_id: String, start: Vector2i, end: Vector2i, tile_type: int = TILE_FLOOR):
	"""Generate a straight bridge between two points. Walkable (not portals)."""
	var path = _hex_line(start, end)
	for hex in path:
		if get_tile(hex) == TILE_VOID or get_tile(hex) == TILE_WATER:
			set_tile(hex, tile_type)
		# Add 1-hex width on either side for stability
		for dir in DIRECTIONS:
			var neighbor = hex + dir
			if get_tile(neighbor) == TILE_VOID:
				set_tile(neighbor, tile_type)

func _generate_ship(ship_id: String, center: Vector2i, radius: int, ship_type: String):
	"""Generate a ship deck with thematic objects."""
	# Ship deck is walkable floor
	for q in range(center.x - radius, center.x + radius + 1):
		for r in range(center.y - radius, center.y + radius + 1):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			if dist <= radius - 1:
				set_tile(hex, TILE_FLOOR)
			elif dist <= radius:
				# Ship edge (railings)
				set_tile(hex, TILE_OBJECT)
	
	# Ship-specific objects
	match ship_type:
		"wind":
			# Sail masts and windcatchers
			set_tile(center + Vector2i(0, 0), TILE_OBJECT)
			set_tile(center + Vector2i(2, 0), TILE_OBJECT)
			set_tile(center + Vector2i(-2, 0), TILE_OBJECT)
		"steam":
			# Smokestacks and valves
			set_tile(center + Vector2i(0, 0), TILE_OBJECT)
			set_tile(center + Vector2i(0, 2), TILE_OBJECT)
			set_tile(center + Vector2i(0, -2), TILE_OBJECT)
		"storm":
			# Lightning rods and coils
			set_tile(center + Vector2i(0, 0), TILE_OBJECT)
			set_tile(center + Vector2i(3, 0), TILE_OBJECT)
			set_tile(center + Vector2i(-3, 0), TILE_OBJECT)

# ===================================================================
# HELPER: Irregular room for organic cavern shapes (Floor 2)
# ===================================================================

func _generate_irregular_room(room_id: String, center: Vector2i, base_radius: int, portal_positions: Array[Vector2i]):
	"""Generate an organic blob-shaped room (slightly irregular edges)"""
	for q in range(center.x - base_radius - 2, center.x + base_radius + 3):
		for r in range(center.y - base_radius - 2, center.y + base_radius + 3):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			
			# Irregularity: add noise to edge
			var noise = randf() * 1.5 - 0.75
			var effective_radius = base_radius + noise
			
			# Check portal
			var is_portal = false
			for portal_hex in portal_positions:
				if hex == portal_hex:
					is_portal = true
					break
			
			if is_portal:
				set_tile(hex, TILE_PORTAL)
			elif dist <= effective_radius - 1.5:
				set_tile(hex, TILE_FLOOR)
			elif dist <= effective_radius:
				# Irregular wall — some gaps
				var near_portal = false
				for portal_hex in portal_positions:
					if _hex_distance(hex, portal_hex) <= 1:
						near_portal = true
						break
				if near_portal or randf() > 0.3:  # 30% chance of gap
					set_tile(hex, TILE_FLOOR)
				else:
					set_tile(hex, TILE_WALL)

func _generate_organic_corridor(corridor_id: String, start: Vector2i, end: Vector2i, width: int):
	"""Generate a winding, slightly irregular corridor"""
	# Add some randomness to path
	var mid1 = Vector2i((start.x + end.x) / 2 + randi() % 5 - 2, (start.y + end.y) / 2 + randi() % 5 - 2)
	
	# Two segments with a bend
	var path1 = _hex_line(start, mid1)
	var path2 = _hex_line(mid1, end)
	
	var all_hexes = path1.duplicate()
	for hex in path2:
		if hex not in all_hexes:
			all_hexes.append(hex)
	
	for hex in all_hexes:
		for dq in range(-width, width + 1):
			for dr in range(-width, width + 1):
				var check = Vector2i(hex.x + dq, hex.y + dr)
				var existing = get_tile(check)
				if existing == TILE_VOID or existing == TILE_PORTAL:
					set_tile(check, TILE_FLOOR)

func _add_fungal_pillars(room_id: String, center: Vector2i, room_radius: int, count: int):
	"""Add mushroom-pillar objects inside a room"""
	for i in range(count):
		var offset_q = randi() % (room_radius * 2 + 1) - room_radius
		var offset_r = randi() % (room_radius * 2 + 1) - room_radius
		var hex = Vector2i(center.x + offset_q, center.y + offset_r)
		var dist = _hex_distance(hex, center)
		if dist <= room_radius - 2 and get_tile(hex) == TILE_FLOOR:
			set_tile(hex, TILE_OBJECT)  # Fungal pillar = object tile
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
