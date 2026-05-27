class_name HexGrid

# Hex grid utilities - Pointy-top hexes
# Axial coordinates (q, r)

const HEX_SIZE: float = 32.0  # Radius (center to corner)
const HEX_WIDTH: float = HEX_SIZE * 2.0
const HEX_HEIGHT: float = HEX_SIZE * sqrt(3.0)

# Directions for pointy-top hexes
# W = NW, E = NE, A = W, D = E, Z = SW, X = SE
const DIRECTIONS = [
	Vector2i(0, -1),   # 0: NW (W key)
	Vector2i(1, -1),   # 1: NE (E key)
	Vector2i(-1, 0),   # 2: W (A key)
	Vector2i(1, 0),    # 3: E (D key)
	Vector2i(-1, 1),   # 4: SW (Z key)
	Vector2i(0, 1),    # 5: SE (X key)
]

static func hex_to_world(hex: Vector2i) -> Vector2:
	"""Convert axial hex coordinates to world position"""
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

static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	"""Distance between two hex coordinates"""
	return (abs(a.x - b.x) + abs(a.x + a.y - b.x - b.y) + abs(a.y - b.y)) / 2

static func get_neighbors(hex: Vector2i) -> Array[Vector2i]:
	"""Get all 6 neighboring hex coordinates"""
	var neighbors: Array[Vector2i] = []
	for dir in DIRECTIONS:
		neighbors.append(hex + dir)
	return neighbors

static func hex_line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	"""Get all hexes in a line from a to b"""
	var N = hex_distance(a, b)
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

static func get_hex_polygon() -> PackedVector2Array:
	"""Get the 6 corner points of a hexagon"""
	var points = PackedVector2Array()
	for i in range(6):
		var angle_deg = 60 * i - 30  # Pointy-top
		var angle_rad = deg_to_rad(angle_deg)
		points.append(Vector2(
			HEX_SIZE * cos(angle_rad),
			HEX_SIZE * sin(angle_rad)
		))
	return points

static func get_direction_toward(from: Vector2i, to: Vector2i) -> int:
	"""Find the hex direction (0-5) that moves closest toward target. Returns -1 if already there."""
	if from == to:
		return -1
	
	var best_dir = 0
	var best_dist = 9999
	for i in range(6):
		var neighbor = from + DIRECTIONS[i]
		var dist = hex_distance(neighbor, to)
		if dist < best_dist:
			best_dist = dist
			best_dir = i
	return best_dir

static func get_direction_vector(direction: int) -> Vector2:
	"""Get the world direction vector for a hex direction (0-5)"""
	var angle_deg = 60 * direction - 30  # Pointy-top
	var angle_rad = deg_to_rad(angle_deg)
	return Vector2(cos(angle_rad), sin(angle_rad))
