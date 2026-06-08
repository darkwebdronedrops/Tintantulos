class_name HexEnemy
extends Node2D

# ===================================================================
# HEX ENEMY — World-space enemy that patrols the hex grid
# ===================================================================
# States: UNaware → Alert → Aware (chasing) → Combat
# Ambush: if player attacks while enemy is UNaware, player gets bonus turn
# ===================================================================

enum State {UNAWARE, ALERT, AWARE, IN_COMBAT}

var enemy_id: String
var enemy_name: String
var faction: String
var hex_pos: Vector2i
var state: State = State.UNAWARE
var max_hp: int = 10
var hp: int = 10
var attack: int = 3
var defense: int = 0
var is_boss: bool = false  # Bosses don't move, can't be ambushed
var view_range: int = 6  # Hex distance for sight
var combat_range: int = 1  # Hex distance to trigger combat
var patrol_radius: int = 3
var patrol_center: Vector2i
var patrol_timer: float = 0.0
var alert_timer: float = 0.0
var move_interval: float = 1.5
var alert_duration: float = 3.0

# Sprite
var sprite: Sprite2D
var state_indicator: Label

# Signals
signal state_changed(new_state: State)
signal spotted_player
signal combat_initiated(ambush: bool)

func _init(id: String, name_: String, start_hex: Vector2i, faction_: String = "Unknown", boss: bool = false):
	enemy_id = id
	enemy_name = name_
	hex_pos = start_hex
	patrol_center = start_hex
	faction = faction_
	is_boss = boss
	if is_boss:
		view_range = 10
		combat_range = 2

func _ready():
	z_index = 90
	
	# Create sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = true
	sprite.scale = Vector2(2.5, 2.5)
	add_child(sprite)
	
	# Try to load enemy sprite
	var base_name = enemy_name.to_lower().replace(" ", "_").replace("-", "_")
	for suffix in ["_idle", "_walk", "", "_f0"]:
		var try_path = "res://assets/sprites/enemies/enemy_" + base_name + suffix + ".png"
		if ResourceLoader.exists(try_path):
			sprite.texture = load(try_path)
			break
	
	# Fallback: colored circle
	if not sprite.texture:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var color = _get_faction_color(faction)
		img.fill(color)
		# Draw circle
		for x in range(32):
			for y in range(32):
				var dx = x - 16
				var dy = y - 16
				if dx * dx + dy * dy > 225:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
		sprite.texture = ImageTexture.create_from_image(img)
	
	# State indicator (small dot above enemy)
	state_indicator = Label.new()
	state_indicator.name = "StateIndicator"
	state_indicator.position = Vector2(-20, -30)
	state_indicator.size = Vector2(40, 15)
	state_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_indicator.add_theme_font_size_override("font_size", 10)
	add_child(state_indicator)
	_update_state_indicator()

func _get_faction_color(faction_name: String) -> Color:
	match faction_name:
		"Construct": return Color(0.7, 0.75, 0.8)
		"Goblin": return Color(0.5, 0.75, 0.45)
		"Undead": return Color(0.6, 0.55, 0.7)
		"Elemental": return Color(0.9, 0.6, 0.35)
		"Demon": return Color(0.8, 0.35, 0.3)
		"Aberration": return Color(0.7, 0.4, 0.75)
		"Dragon": return Color(0.85, 0.7, 0.35)
		_: return Color(0.8, 0.2, 0.2)

func _update_state_indicator():
	match state:
		State.UNAWARE:
			state_indicator.text = "·"
			state_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		State.ALERT:
			state_indicator.text = "?"
			state_indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		State.AWARE:
			state_indicator.text = "!"
			state_indicator.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		State.IN_COMBAT:
			state_indicator.text = "⚔"
			state_indicator.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))

func _process(delta: float):
	match state:
		State.UNAWARE:
			if not is_boss:
				_patrol(delta)
		State.ALERT:
			_alert_behavior(delta)
		State.AWARE:
			if not is_boss:
				_chase(delta)
		State.IN_COMBAT:
			pass  # Combat manager handles this

func _patrol(delta: float):
	patrol_timer += delta
	if patrol_timer < move_interval:
		return
	patrol_timer = 0.0
	
	# Random walk within patrol radius
	var directions = HexTileMap.DIRECTIONS
	var random_dir = directions[randi() % directions.size()]
	var target = hex_pos + random_dir
	var dist = HexTileMap._hex_distance(target, patrol_center)
	
	if dist <= patrol_radius:
		# Check if walkable
		var hex_map = _get_hex_map()
		if hex_map and hex_map.is_walkable(target):
			hex_pos = target
			_update_position()

func _alert_behavior(delta: float):
	alert_timer += delta
	if alert_timer >= alert_duration:
		if is_boss:
			# Boss just stays alert, doesn't chase
			alert_timer = 0.0
		else:
			# Transition to aware (chase)
			_set_state(State.AWARE)
			alert_timer = 0.0

func _chase(delta: float):
	patrol_timer += delta
	if patrol_timer < move_interval * 0.7:  # Chase faster than patrol
		return
	patrol_timer = 0.0
	
	var hex_map = _get_hex_map()
	var player = _get_player()
	if not hex_map or not player:
		return
	
	var player_hex = hex_map.world_to_hex(player.global_position)
	var dist = HexTileMap._hex_distance(hex_pos, player_hex)
	
	if dist <= combat_range:
		# Combat triggers!
		_set_state(State.IN_COMBAT)
		combat_initiated.emit(false)  # Not an ambush, enemy saw player
		return
	
	if dist > view_range:
		# Lost sight, return to patrol
		_set_state(State.UNAWARE)
		return
	
	# Move toward player using A*
	var path = hex_map.find_path(hex_pos, player_hex)
	if path.size() > 1:
		var next_hex = path[1]
		if hex_map.is_walkable(next_hex):
			hex_pos = next_hex
			_update_position()

func check_player_sight(player_hex: Vector2i) -> bool:
	"""Check if player is within sight range."""
	var dist = HexTileMap._hex_distance(hex_pos, player_hex)
	
	match state:
		State.UNAWARE:
			if dist <= view_range:
				# Player spotted! Transition to alert
				_set_state(State.ALERT)
				spotted_player.emit()
				return true
		State.ALERT:
			if dist > view_range:
				_set_state(State.UNAWARE)
				alert_timer = 0.0
			return dist <= view_range
		State.AWARE:
			return dist <= view_range
		State.IN_COMBAT:
			return false
	
	return false

func try_ambush(player_hex: Vector2i) -> bool:
	"""Player tries to ambush this enemy. Returns true if successful."""
	var dist = HexTileMap._hex_distance(hex_pos, player_hex)
	if dist > combat_range + 1:
		return false  # Too far
	
	if is_boss:
		# Boss cannot be ambushed — normal combat, no bonus
		_set_state(State.IN_COMBAT)
		combat_initiated.emit(false)
		return true
	
	if state == State.UNAWARE:
		# Ambush successful!
		_set_state(State.IN_COMBAT)
		combat_initiated.emit(true)  # Ambush = bonus turn
		return true
	else:
		# Enemy is already alert, normal combat
		_set_state(State.IN_COMBAT)
		combat_initiated.emit(false)
		return true

func _set_state(new_state: State):
	if state == new_state:
		return
	state = new_state
	_update_state_indicator()
	state_changed.emit(new_state)
	print("[HexEnemy] %s → %s" % [enemy_name, _state_name(new_state)])

func _state_name(s: State) -> String:
	match s:
		State.UNAWARE: return "UNAWARE"
		State.ALERT: return "ALERT"
		State.AWARE: return "AWARE"
		State.IN_COMBAT: return "IN_COMBAT"
	return "UNKNOWN"

func _update_position():
	var hex_map = _get_hex_map()
	if hex_map:
		global_position = hex_map.hex_to_world(hex_pos)

func _get_hex_map() -> HexTileMap:
	var parent = get_parent()
	if parent and parent.has_node("HexTileMap"):
		return parent.get_node("HexTileMap")
	return null

func _get_player() -> Node2D:
	var parent = get_parent()
	if parent and parent.has_node("Player"):
		return parent.get_node("Player")
	return null

func to_combat_data() -> CombatManager.EnemyData:
	"""Convert to CombatManager.EnemyData for card combat."""
	var data = CombatManager.EnemyData.new(
		enemy_name,
		max_hp,
		attack,
		defense,
		[CombatManager.EnemyAction.ATTACK],
		[]
	)
	data.hp = hp
	return data

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		hp = 0
		queue_free()

func reset_after_combat():
	"""Reset state after combat ends (return to patrol if alive)."""
	if hp > 0 and state == State.IN_COMBAT:
		_set_state(State.UNAWARE)
		patrol_center = hex_pos  # New patrol center after combat

func set_hex_map_position(new_hex: Vector2i, hex_map: HexTileMap):
	hex_pos = new_hex
	patrol_center = new_hex
	if hex_map:
		global_position = hex_map.hex_to_world(hex_pos)
