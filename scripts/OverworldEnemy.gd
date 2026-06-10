extends Node2D
class_name OverworldEnemy

# OverworldEnemy — Patrol/aggro/chase enemy that roams the floor map
# Patrols a loop of 8 hex positions, aggros at 3-hex radius, forces combat on contact

enum State {
	PATROLLING,    # Cycling through patrol hexes
	ALERTED,       # Player entered aggro radius — brief pause before chase
	CHASING,       # Moving toward player each tick
	RETURNING      # Player escaped — returning to patrol route
}

# Config
var enemy_id: int = 0
var faction: String = "Construct"
var patrol_center_hex: Vector2i = Vector2i.ZERO  # Room center or anchor point
var patrol_hexes: Array[Vector2i] = []          # 8-position loop
var current_patrol_index: int = 0
var current_hex: Vector2i = Vector2i.ZERO

# Aggro / Combat
var aggro_range: int = 3       # Hexes — player detected
var combat_range: int = 0      # Hexes — same hex = combat (0 = must share hex)
var los_required: bool = false # If true, need line of sight (walls block)

# Movement timing
var state: State = State.PATROLLING
var move_timer: float = 0.0
var patrol_interval: float = 2.0  # Seconds between patrol moves
var chase_interval: float = 0.8   # Seconds between chase moves (faster)
var alert_duration: float = 0.5   # Seconds paused when spotting player
var alert_timer: float = 0.0

# Return behavior
var return_patrol_threshold: int = 6  # If player gets this far away, give up chase
var last_known_player_hex: Vector2i = Vector2i.ZERO

# Visual
var visual_node: Node2D = null
var sprite_path: String = ""
var enemy_name: String = "Patrol"

# Combat data (for when combat triggers)
var combat_template_name: String = "Piston Assembly"

# Movement validation (set by floor controller)
var can_move_to: Callable = func(_hex: Vector2i) -> bool: return true
var patrol_radius: int = 5  # Max distance from patrol center for random wander


# Signals
signal enemy_moved(enemy_id: int, new_hex: Vector2i)
signal enemy_spotted_player(enemy_id: int, distance: int)
signal enemy_lost_player(enemy_id: int)
signal enemy_combat_triggered(enemy_id: int, template_name: String)

func _ready():
	# Create visual node
	_create_visual()
	_update_position()

func _process(delta: float):
	match state:
		State.PATROLLING:
			_process_patrol(delta)
		State.ALERTED:
			_process_alert(delta)
		State.CHASING:
			_process_chase(delta)
		State.RETURNING:
			_process_return(delta)

func _process_patrol(delta: float):
	move_timer += delta
	if move_timer >= patrol_interval:
		move_timer = 0.0
		_advance_patrol()

func _process_alert(delta: float):
	alert_timer += delta
	if alert_timer >= alert_duration:
		alert_timer = 0.0
		state = State.CHASING
		_update_visual_state()

func _process_chase(delta: float):
	move_timer += delta
	if move_timer >= chase_interval:
		move_timer = 0.0
		_step_toward_player()

func _process_return(delta: float):
	move_timer += delta
	if move_timer >= patrol_interval:
		move_timer = 0.0
		_step_toward_patrol()

# ============================================================================
# PUBLIC API
# ============================================================================

func setup(id: int, room_center: Vector2i, faction_name: String, template: String, sprite: String):
	"""Initialize enemy with patrol route around a room."""
	enemy_id = id
	patrol_center_hex = room_center
	faction = faction_name
	combat_template_name = template
	sprite_path = sprite
	
	# Generate 8-hex patrol loop around room center
	# Offset patrol center 2-3 hexes outward so enemies don't walk through room
	_generate_patrol_hexes()
	
	# Start at first patrol position
	if patrol_hexes.size() > 0:
		current_hex = patrol_hexes[0]
		current_patrol_index = 0
	
	enemy_name = template  # Default to template name
	_update_position()
	_update_visual_state()

func check_player_proximity(player_hex: Vector2i) -> bool:
	"""Check if player is within aggro range. Returns true if state changed to alert/chase."""
	var dist = HexGrid.hex_distance(current_hex, player_hex)
	
	match state:
		State.PATROLLING:
			if dist <= aggro_range:
				# Player entered aggro zone
				state = State.ALERTED
				alert_timer = 0.0
				last_known_player_hex = player_hex
				_update_visual_state()
				enemy_spotted_player.emit(enemy_id, dist)
				return true
		
		State.ALERTED, State.CHASING:
			last_known_player_hex = player_hex
			# If player escaped far away, return to patrol
			if dist > return_patrol_threshold:
				state = State.RETURNING
				_update_visual_state()
				enemy_lost_player.emit(enemy_id)
				return false
			# If player is close, stay in chase
			return dist <= aggro_range
		
		State.RETURNING:
			if dist <= aggro_range:
				# Player re-entered during return
				state = State.CHASING
				last_known_player_hex = player_hex
				_update_visual_state()
				return true
			return false
	
	return false

func is_combat_triggered(player_hex: Vector2i) -> bool:
	"""Check if enemy and player share the same hex (combat collision)."""
	return current_hex == player_hex

func force_despawn():
	"""Remove enemy from world immediately."""
	if visual_node and is_instance_valid(visual_node):
		visual_node.queue_free()
	queue_free()

func get_save_data() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"current_hex": [current_hex.x, current_hex.y],
		"current_patrol_index": current_patrol_index,
		"state": state,
		"faction": faction,
		"template": combat_template_name,
		"sprite": sprite_path,
		"patrol_center": [patrol_center_hex.x, patrol_center_hex.y],
	}

func load_save_data(data: Dictionary):
	enemy_id = data.get("enemy_id", 0)
	var hex_arr = data.get("current_hex", [0, 0])
	current_hex = Vector2i(hex_arr[0], hex_arr[1])
	current_patrol_index = data.get("current_patrol_index", 0)
	state = data.get("state", State.PATROLLING) as State
	faction = data.get("faction", "Construct")
	combat_template_name = data.get("template", "Piston Assembly")
	sprite_path = data.get("sprite", "")
	var pc_arr = data.get("patrol_center", [0, 0])
	patrol_center_hex = Vector2i(pc_arr[0], pc_arr[1])
	
	# Regenerate patrol hexes from center
	_generate_patrol_hexes()
	_update_position()
	_update_visual_state()

# ============================================================================
# INTERNAL
# ============================================================================

func _generate_patrol_hexes():
	"""Random walk doesn't need a pre-generated loop. Just clear any old data."""
	patrol_hexes.clear()


func _advance_patrol():
	"""Move to a random valid adjacent hex, staying within patrol radius."""
	var valid = _get_valid_neighbors(current_hex)
	if valid.is_empty():
		return
	
	# Prefer hexes within patrol radius
	var within_radius: Array[Vector2i] = []
	for h in valid:
		if HexGrid.hex_distance(h, patrol_center_hex) <= patrol_radius:
			within_radius.append(h)
	
	var candidates = within_radius if within_radius.size() > 0 else valid
	current_hex = candidates[randi() % candidates.size()]
	_update_position()
	enemy_moved.emit(enemy_id, current_hex)


func _get_valid_neighbors(hex: Vector2i) -> Array[Vector2i]:
	"""Return all adjacent hexes that pass the can_move_to callback."""
	var valid: Array[Vector2i] = []
	for dir in HexGrid.DIRECTIONS:
		var neighbor = hex + dir
		if can_move_to.call(neighbor):
			valid.append(neighbor)
	return valid

func _step_toward_player():
	"""Move one hex toward last known player position, respecting bounds."""
	var dir = HexGrid.get_direction_toward(current_hex, last_known_player_hex)
	if dir >= 0 and dir < 6:
		var next_hex = current_hex + HexGrid.DIRECTIONS[dir]
		if can_move_to.call(next_hex):
			current_hex = next_hex
			_update_position()
			enemy_moved.emit(enemy_id, current_hex)
			return
	# If direct path is blocked, try any valid neighbor that gets closer
	var valid = _get_valid_neighbors(current_hex)
	if valid.is_empty():
		return
	valid.sort_custom(func(a, b): return HexGrid.hex_distance(a, last_known_player_hex) < HexGrid.hex_distance(b, last_known_player_hex))
	current_hex = valid[0]
	_update_position()
	enemy_moved.emit(enemy_id, current_hex)

func _step_toward_patrol():
	"""Move one hex toward patrol center, respecting bounds."""
	var valid = _get_valid_neighbors(current_hex)
	if valid.is_empty():
		return
	
	# Sort by distance to patrol center (closest first)
	valid.sort_custom(func(a, b): return HexGrid.hex_distance(a, patrol_center_hex) < HexGrid.hex_distance(b, patrol_center_hex))
	current_hex = valid[0]
	_update_position()
	enemy_moved.emit(enemy_id, current_hex)
	
	# If we're back within 2 hexes of center, resume patrol mode
	if HexGrid.hex_distance(current_hex, patrol_center_hex) <= 2:
		state = State.PATROLLING
		_update_visual_state()


func _update_position():
	"""Sync visual node to current hex world position."""
	var world_pos = HexGrid.hex_to_world(current_hex)
	if visual_node:
		visual_node.position = world_pos
	position = world_pos

func _create_visual():
	"""Create the enemy's visual representation."""
	visual_node = Node2D.new()
	visual_node.name = "OverworldEnemy_%d" % enemy_id
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		sprite.scale = Vector2(0.7, 0.7)
	else:
		# Fallback: faction-colored hex
		var poly = Polygon2D.new()
		poly.color = _get_faction_color()
		poly.polygon = HexGrid.get_hex_polygon()
		poly.scale = Vector2(0.5, 0.5)
		visual_node.add_child(poly)
		# Don't add sprite if fallback used
		visual_node.add_child(sprite)  # Empty sprite as placeholder
		visual_node.remove_child(sprite)
		return visual_node
	
	visual_node.add_child(sprite)
	
	# State indicator (small dot above enemy)
	var indicator = Polygon2D.new()
	indicator.name = "StateIndicator"
	indicator.polygon = PackedVector2Array([
		Vector2(-4, -35), Vector2(4, -35),
		Vector2(4, -27), Vector2(-4, -27)
	])
	indicator.color = Color(0.3, 0.9, 0.3)  # Green = patrol
	visual_node.add_child(indicator)
	
	# Name label (small)
	var label = Label.new()
	label.name = "NameLabel"
	label.text = enemy_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -50)
	label.size = Vector2(80, 14)
	label.add_theme_font_size_override("font_size", 10)
	visual_node.add_child(label)
	
	add_child(visual_node)
	return visual_node

func _update_visual_state():
	"""Update visual indicator based on state."""
	if not visual_node:
		return
	
	var indicator = visual_node.get_node_or_null("StateIndicator")
	if not indicator:
		return
	
	match state:
		State.PATROLLING:
			indicator.color = Color(0.3, 0.9, 0.3)  # Green
			indicator.visible = true
		State.ALERTED:
			indicator.color = Color(0.9, 0.9, 0.2)  # Yellow flash
			indicator.visible = true
			# Pulse animation
			var tween = create_tween()
			tween.tween_property(indicator, "scale", Vector2(1.5, 1.5), 0.2)
			tween.tween_property(indicator, "scale", Vector2(1.0, 1.0), 0.2)
		State.CHASING:
			indicator.color = Color(0.9, 0.2, 0.2)  # Red
			indicator.visible = true
		State.RETURNING:
			indicator.color = Color(0.5, 0.5, 0.9)  # Blue
			indicator.visible = true

func _get_faction_color() -> Color:
	match faction:
		"Construct": return Color(0.7, 0.6, 0.4)  # Bronze
		"Elemental": return Color(0.9, 0.4, 0.1)  # Orange
		"Aberration": return Color(0.4, 0.2, 0.7)  # Purple
		"Goblin": return Color(0.3, 0.7, 0.3)      # Green
		"Demon": return Color(0.8, 0.1, 0.1)        # Red
		"Undead": return Color(0.5, 0.5, 0.5)       # Grey
		_: return Color(0.7, 0.3, 0.3)              # Default red
