extends CharacterBody2D
class_name HexPlayer

# HexPlayer — Movement controller for hex-based floors
# Snaps to hex grid, 6-directional movement, interacts with HexMapController

@export var hex_speed: float = 200.0
@export var snap_distance: float = 5.0

var hex_map: HexMapController
var current_hex: Vector2i
var target_hex: Vector2i
var is_moving: bool = false
var move_direction: Vector2

func _ready():
	# Find the HexMapController in the scene
	hex_map = _find_hex_map()
	if hex_map:
		# Snap to nearest hex
		current_hex = hex_map.world_to_hex(position)
		position = hex_map.hex_to_world(current_hex)
		print("HexPlayer: Spawned at hex %s" % current_hex)
	else:
		push_error("HexPlayer: No HexMapController found in scene!")

func _find_hex_map() -> HexMapController:
	# Search siblings and parent for HexMapController
	var parent = get_parent()
	if parent is HexMapController:
		return parent
	for child in parent.get_children():
		if child is HexMapController:
			return child
	return null

func _physics_process(delta):
	if is_moving:
		# Move toward target hex center
		var target_pos = hex_map.hex_to_world(target_hex)
		var direction = (target_pos - position).normalized()
		var distance = position.distance_to(target_pos)
		
		if distance <= snap_distance:
			# Reached target
			position = target_pos
			current_hex = target_hex
			is_moving = false
			_on_hex_entered(current_hex)
		else:
			velocity = direction * hex_speed
			move_and_slide()
	else:
		velocity = Vector2.ZERO

func move_to_hex(hex_coord: Vector2i) -> bool:
	"""Move to an adjacent hex. Returns true if movement started."""
	if is_moving:
		return false
	
	if not hex_map.is_walkable(hex_coord):
		return false
	
	# Check if it's a neighbor
	var neighbors = hex_map.get_hex_neighbors(current_hex)
	if not hex_coord in neighbors:
		push_warning("HexPlayer: Can only move to adjacent hexes")
		return false
	
	target_hex = hex_coord
	is_moving = true
	return true

func move_direction(dir: int) -> bool:
	"""Move in one of 6 directions (0-5). Returns true if movement started."""
	var neighbors = hex_map.get_hex_neighbors(current_hex)
	if dir < 0 or dir >= neighbors.size():
		return false
	return move_to_hex(neighbors[dir])

func _input(event):
	if is_moving:
		return
	
	# Hex movement: Q/W/E/A/S/D for 6 directions
	# (or numpad, or arrow keys + diagonals)
	if event.is_action_pressed("hex_ne"):
		move_direction(1)
	elif event.is_action_pressed("hex_e"):
		move_direction(0)
	elif event.is_action_pressed("hex_se"):
		move_direction(5)
	elif event.is_action_pressed("hex_sw"):
		move_direction(4)
	elif event.is_action_pressed("hex_w"):
		move_direction(3)
	elif event.is_action_pressed("hex_nw"):
		move_direction(2)

func _on_hex_entered(hex_coord: Vector2i):
	"""Called when player enters a new hex. Check for interactions."""
	if hex_map.is_interactable(hex_coord):
		var tile_data = hex_map.get_cell_tile_data(0, hex_coord)
		if tile_data:
			var terrain = tile_data.terrain
			match terrain:
				4:  # Trap
					print("HexPlayer: Stepped on trap!")
					# Trigger trap effect
				2:  # Door
					print("HexPlayer: Found door")
					# Open door
				3:  # Stairs
					print("HexPlayer: Found stairs")
					# Go to next floor
				6:  # Exit
					print("HexPlayer: Found exit")
					# End floor

func get_current_hex() -> Vector2i:
	return current_hex

func is_walkable_in_direction(dir: int) -> bool:
	"""Check if movement in direction is possible."""
	var neighbors = hex_map.get_hex_neighbors(current_hex)
	if dir < 0 or dir >= neighbors.size():
		return false
	return hex_map.is_walkable(neighbors[dir])

# ==========================================
# COMBAT INTEGRATION
# ==========================================

func get_hex_for_combat_spawn() -> Vector2i:
	"""Get a nearby hex for spawning enemies in combat."""
	var radius = 2
	return hex_map.get_random_walkable_hex(current_hex, radius)

func get_adjacent_enemies() -> Array[Vector2i]:
	"""Get hex coordinates of adjacent enemies (if any)."""
	# This would check for enemy nodes on adjacent hexes
	# Implementation depends on enemy placement system
	return []

# ==========================================
# FLOOR 3: ROOM ROTATION
# ==========================================

func on_room_rotated(room_id: String, new_rotation: int):
	"""Called when a room rotates. Check if player is in that room."""
	var player_room = hex_map.get_room_at(current_hex)
	if player_room == room_id:
		print("HexPlayer: Room %s rotated to %d" % [room_id, new_rotation])
		# Player may need to adjust position or may be moved automatically
		# Check if current hex is still walkable after rotation
		if not hex_map.is_walkable(current_hex):
			# Find nearest walkable hex
			var neighbors = hex_map.get_hex_neighbors(current_hex)
			for neighbor in neighbors:
				if hex_map.is_walkable(neighbor):
					current_hex = neighbor
					position = hex_map.hex_to_world(current_hex)
					print("HexPlayer: Adjusted position due to room rotation")
					break
