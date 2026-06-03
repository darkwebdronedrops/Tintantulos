@tool
extends TileMap
class_name HexFloorGenerator

# HexFloorGenerator — Generates floor layouts into the TileMap for editor preview
# Run in editor to paint hex layouts; modify by hand in TileMap editor after generation

@export var generate_floor: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			match floor_number:
				1: generate_floor1()
				2: generate_floor2()
				3: generate_floor3()
				4: generate_floor4()
				_:
					push_warning("HexFloorGenerator: Unknown floor number %d" % floor_number)
			generate_floor = false

@export var floor_number: int = 3
@export var clear_first: bool = true

# Tile atlas coordinates
const ATLAS_FLOOR = Vector2i(0, 0)
const ATLAS_WALL = Vector2i(1, 0)
const ATLAS_DOOR = Vector2i(2, 0)
const ATLAS_STAIRS = Vector2i(3, 0)
const ATLAS_TRAP = Vector2i(4, 0)
const ATLAS_SPAWN = Vector2i(5, 0)
const ATLAS_EXIT = Vector2i(6, 0)

func _ready():
	if not Engine.is_editor_hint():
		# In game, just ensure tile_set is set
		if not tile_set:
			push_error("HexFloorGenerator: No TileSet assigned!")

func clear_map():
	clear()

func set_tile(hex: Vector2i, atlas: Vector2i, room_id: String = ""):
	set_cell(0, hex, 0, atlas)
	if room_id != "" and tile_set and tile_set.get_custom_data_layer_by_name("room_id") >= 0:
		var tile_data = get_cell_tile_data(0, hex)
		if tile_data:
			tile_data.set_custom_data("room_id", room_id)

# ==========================================
# FLOOR 1: The Entry Hall
# ==========================================

func generate_floor1():
	if clear_first: clear_map()
	print("HexFloorGenerator: Generating Floor 1...")
	
	# Central hub (5-hex radius)
	_generate_room("f1_hub", Vector2i(0, 0), 5, [Vector2i(0, -6), Vector2i(6, 0), Vector2i(0, 6), Vector2i(-6, 0)])
	
	# North corridor
	_generate_corridor("f1_n", Vector2i(0, -7), Vector2i(0, -12), 1)
	_generate_room("f1_north", Vector2i(0, -18), 4, [Vector2i(0, -14)])
	
	# East corridor
	_generate_corridor("f1_e", Vector2i(7, 0), Vector2i(12, 0), 1)
	_generate_room("f1_east", Vector2i(18, 0), 4, [Vector2i(14, 0)])
	
	# South corridor
	_generate_corridor("f1_s", Vector2i(0, 7), Vector2i(0, 12), 1)
	_generate_room("f1_south", Vector2i(0, 18), 4, [Vector2i(0, 14)])
	
	# West corridor
	_generate_corridor("f1_w", Vector2i(-7, 0), Vector2i(-12, 0), 1)
	_generate_room("f1_west", Vector2i(-18, 0), 4, [Vector2i(-14, 0)])
	
	# Spawn point in hub
	set_tile(Vector2i(0, 0), ATLAS_SPAWN, "f1_hub")
	
	print("HexFloorGenerator: Floor 1 complete")

# ==========================================
# FLOOR 3: The Gearworks (12-Room Ring)
# ==========================================

func generate_floor3():
	if clear_first: clear_map()
	print("HexFloorGenerator: Generating Floor 3...")
	
	# Central Kami Shrine (radius 3)
	for q in range(-3, 4):
		for r in range(-3, 4):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, Vector2i(0, 0))
			if dist <= 2:
				set_tile(hex, ATLAS_FLOOR, "f3_center")
			elif dist <= 3:
				set_tile(hex, ATLAS_WALL, "f3_center")
	
	# 12 rooms in a ring (radius 18)
	var ring_radius = 18
	var room_positions = [
		Vector2i(0, -ring_radius),      # 12: The Quench (start/spawn)
		Vector2i(9, -16),               # 1
		Vector2i(16, -9),               # 2
		Vector2i(ring_radius, 0),       # 3
		Vector2i(16, 9),                # 4
		Vector2i(9, 16),                # 5
		Vector2i(0, ring_radius),         # 6: The Beacon
		Vector2i(-9, 16),               # 7
		Vector2i(-16, 9),               # 8
		Vector2i(-ring_radius, 0),        # 9
		Vector2i(-16, -9),              # 10
		Vector2i(-9, -16),              # 11
	]
	
	var room_names = [
		"f3_r12", "f3_r01", "f3_r02", "f3_r03", "f3_r04", "f3_r05",
		"f3_r06", "f3_r07", "f3_r08", "f3_r09", "f3_r10", "f3_r11"
	]
	
	for i in range(12):
		var room_id = room_names[i]
		var center = room_positions[i]
		
		# Generate room
		_generate_room(room_id, center, 4, [])
		
		# Connect to neighbors with corridors
		var next_idx = (i + 1) % 12
		var next_center = room_positions[next_idx]
		_generate_corridor("f3_ring_%d" % i, center, next_center, 1)
	
	# Spawn in Room 12
	set_tile(room_positions[0], ATLAS_SPAWN, "f3_r12")
	
	print("HexFloorGenerator: Floor 3 complete (12-room ring + Kami Shrine)")

# ==========================================
# GENERIC ROOM/CORRIDIDOR GENERATORS
# ==========================================

func _generate_room(room_id: String, center: Vector2i, radius: int, portal_dirs: Array):
	"""Generate a roughly circular room with walls at edges."""
	for q in range(center.x - radius - 1, center.x + radius + 2):
		for r in range(center.y - radius - 1, center.y + radius + 2):
			var hex = Vector2i(q, r)
			var dist = _hex_distance(hex, center)
			
			if dist <= radius - 1:
				# Floor
				set_tile(hex, ATLAS_FLOOR, room_id)
			elif dist <= radius:
				# Wall (with portal openings)
				var is_portal = false
				for portal_dir in portal_dirs:
					if _hex_distance(hex, center + portal_dir) <= 1:
						is_portal = true
						break
				if is_portal:
					set_tile(hex, ATLAS_DOOR, room_id)
				else:
					set_tile(hex, ATLAS_WALL, room_id)

func _generate_corridor(corridor_id: String, start: Vector2i, end: Vector2i, width: int):
	"""Generate a corridor between two points."""
	var path = _hex_line(start, end)
	for hex in path:
		for dq in range(-width, width + 1):
			for dr in range(-width, width + 1):
				var check = Vector2i(hex.x + dq, hex.y + dr)
				var dist = _hex_distance(check, hex)
				if dist <= width:
					# Only place floor if not already occupied
					var existing = get_cell_atlas_coords(0, check)
					if existing == Vector2i(-1, -1):
						set_tile(check, ATLAS_FLOOR, corridor_id)

func _hex_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	"""Get all hexes in a line from a to b."""
	var N = _hex_distance(a, b)
	if N == 0:
		return [a]
	
	var results: Array[Vector2i] = []
	for i in range(N + 1):
		var t = float(i) / N if N > 0 else 0.0
		var interpolated = Vector2(
			lerp(a.x, b.x, t),
			lerp(a.y, b.y, t)
		)
		results.append(_hex_round(interpolated))
	return results

func _hex_round(hex: Vector2) -> Vector2i:
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

func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

func _hex_distance_f(a: Vector2, b: Vector2) -> float:
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2.0

# Placeholder generators for other floors
func generate_floor2():
	if clear_first: clear_map()
	print("HexFloorGenerator: Floor 2 generation not yet implemented")

func generate_floor4():
	if clear_first: clear_map()
	print("HexFloorGenerator: Floor 4 generation not yet implemented")
