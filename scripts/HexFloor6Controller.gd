extends Node2D

# ===================================================================
# FLOOR 6 CONTROLLER — Hex-Based — The Lunar University
# ===================================================================
# Quadrangle + 4 colleges + Undercroft + Clocktower (boss)
# Unique systems: Curriculum, Moonlight Beams, Clocktower Bell,
#                Toxic Ink, Lecture Hall Panic, Dean Boss, Goblin
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "f6_quadrangle"
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false
var is_paused: bool = false

# Click-to-Move path following state
var path_movement_active: bool = false
var path_movement_target: Array[Vector2i] = []
var path_movement_index: int = 0
var path_movement_timer: float = 0.0
const PATH_MOVE_STEP_INTERVAL: float = 0.12

# -------------------------------------------------------------------
# Floor 6 — Curriculum System
# -------------------------------------------------------------------
var assigned_courses: Array[Dictionary] = []
var course_progress: Dictionary = {}
var player_grades: Dictionary = {}
var audit_mode: bool = false
var graduate_status: bool = false
var all_courses_completed: bool = false

# -------------------------------------------------------------------
# Floor 6 — Moonlight Beams
# -------------------------------------------------------------------
var moonlight_turn_count: int = 0
var moonlight_beam_positions: Array[Vector2i] = []
var in_moonlight: bool = false
var moonlight_shift_interval: int = 5
var moonlight_beam_hexes: Array[Vector2i] = []  # Current hexes that are lit

# -------------------------------------------------------------------
# Floor 6 — Clocktower Bell
# -------------------------------------------------------------------
var clocktower_turn_count: int = 0
var clocktower_bell_interval: int = 10
var clocktower_sabotaged: bool = false

# -------------------------------------------------------------------
# Floor 6 — Lecture Hall Panic
# -------------------------------------------------------------------
var active_professors: Dictionary = {}  # room_id -> professor_entity_id
var panicking_students: Dictionary = {}  # room_id -> Array[student_ids]
var professor_defeated_in_combat: bool = false

# -------------------------------------------------------------------
# Floor 6 — Toxic Ink (College of Echoes)
# -------------------------------------------------------------------
var in_echoes_library: bool = false
var toxic_ink_attention_drain: int = 1
var toxic_ink_hexes: Array[Vector2i] = []

# -------------------------------------------------------------------
# Floor 6 — Boss State (The Dean)
# -------------------------------------------------------------------
var boss_current_phase: String = "administration"  # "administration" | "lunar"
var boss_phase_transitioned: bool = false
var dean_defeated: bool = false

# -------------------------------------------------------------------
# Floor 6 — Undercroft Goblin
# -------------------------------------------------------------------
var goblin_janitor_befriended: bool = false
var master_key_held: bool = false

# -------------------------------------------------------------------
# Floor 6 — Locks / Progress
# -------------------------------------------------------------------
var pacts_unlocked: bool = false
var dean_elevator_unlocked: bool = false
var gear_puzzle_aligned: int = 0
var gear_puzzle_total: int = 3
var books_read: int = 0
var thesis_defended: bool = false

# Hard mode / Disciplinary state
var hard_mode_active: bool = false
var hard_mode_passed_trigger: bool = false
var disciplinary_wall_hexes: Array[Vector2i] = [Vector2i(3, -18), Vector2i(3, -19), Vector2i(4, -18)]

# -------------------------------------------------------------------
# Room Data
# -------------------------------------------------------------------
var room_data: Dictionary = {
	"f6_quadrangle": {"center": Vector2i(0, 0),    "radius": 20, "encounter": "none",    "display": "The Quadrangle", "level": "quadrangle"},
	"f6_gears":      {"center": Vector2i(0, -40),   "radius": 14, "encounter": "construct", "display": "College of Gears", "level": "gears"},
	"f6_echoes":     {"center": Vector2i(40, 0),    "radius": 14, "encounter": "echoes",    "display": "College of Echoes", "level": "echoes"},
	"f6_aether":     {"center": Vector2i(0, 40),    "radius": 14, "encounter": "aether",    "display": "College of Aether", "level": "aether"},
	"f6_pacts":      {"center": Vector2i(-40, 0),   "radius": 14, "encounter": "pacts",     "display": "College of Pacts", "level": "pacts"},
	"f6_undercroft": {"center": Vector2i(10, 10),   "radius": 8,  "encounter": "none",      "display": "The Undercroft", "level": "undercroft"},
	"f6_detention":  {"center": Vector2i(3, -40),   "radius": 8,  "encounter": "security",  "display": "Disciplinary Wing", "level": "detention"},
	"f6_clocktower": {"center": Vector2i(0, -70),   "radius": 12, "encounter": "boss",      "display": "The Clocktower Apex", "level": "clocktower"},
}

# Portal / Stair connections
var portal_connections: Dictionary = {
	"f6_quadrangle": {"north": "f6_gears", "east": "f6_echoes", "south": "f6_aether", "west": "f6_pacts", "down": "f6_undercroft", "up": "f6_clocktower", "north_detention": "f6_detention"},
	"f6_gears":      {"south": "f6_quadrangle", "up": "f6_clocktower"},
	"f6_echoes":     {"west": "f6_quadrangle"},
	"f6_aether":     {"north": "f6_quadrangle"},
	"f6_pacts":      {"east": "f6_quadrangle"},
	"f6_undercroft": {"up": "f6_quadrangle"},
	"f6_detention":  {"south": "f6_quadrangle"},
	"f6_clocktower": {"down": "f6_gears"},
}

# Portal offsets from room center (direction -> offset)
var portal_offsets: Dictionary = {
	"north": Vector2i(0, -18), "south": Vector2i(0, 18),
	"east":  Vector2i(18, 0),  "west":  Vector2i(-18, 0),
	"up":    Vector2i(0, -12),  "down":  Vector2i(0, 12),
}

# Room encounter state
var room_cleared: Dictionary = {}
var room_encounter_spawned: Dictionary = {}

# Hex enemies on the grid
var hex_enemies: Array[HexEnemy] = []
var enemy_container: Node2D

# Ambush state
var ambush_bonus: bool = false

# UI
var interact_prompt: Label
var pause_menu: CanvasLayer
var curriculum_ui: Label
var moonlight_ui: Label
var clocktower_ui: Label
var grade_ui: Label
var boss_phase_ui: Label
var room_indicator: Label

# Signals
signal room_changed(room_id: String, room_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	call_deferred("_build_floor")

func _build_floor():
	_generate_hex_layout()
	print("[Floor6-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_enemies()
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(6)
	_enter_room("f6_quadrangle")

# ===================================================================
# HEX LAYOUT GENERATION
# ===================================================================

func _generate_hex_layout():
	"""Generate the complete Floor 6 hex layout."""
	hex_map.clear_grid()
	
	# === CENTRAL QUADRANGLE (large circular hub, radius 20) ===
	_generate_room_hex("f6_quadrangle", Vector2i(0, 0), 20, [
		Vector2i(0, -18),   # North portal -> Gears corridor
		Vector2i(18, 0),    # East portal -> Echoes corridor
		Vector2i(0, 18),    # South portal -> Aether corridor
		Vector2i(-18, 0),   # West portal -> Pacts corridor
		Vector2i(10, 10),   # Down portal -> Undercroft hatch
	])
	
	# Fountain at center (object tiles)
	hex_map.set_tile(Vector2i(0, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(1, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-1, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(0, 1), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(0, -1), HexTileMap.TILE_OBJECT)
	
	# Save Point near edge
	hex_map.set_tile(Vector2i(15, 0), HexTileMap.TILE_OBJECT)
	
	# The Registrar near center (object)
	hex_map.set_tile(Vector2i(3, 0), HexTileMap.TILE_OBJECT)
	
	# Portal to Floor 5 exit near quadrangle edge
	hex_map.set_tile(Vector2i(0, 22), HexTileMap.TILE_PORTAL)
	
	# === CORRIDORS (width 2-3 hexes, length 10-15 hexes) ===
	# North corridor to Gears
	_generate_corridor_hex(Vector2i(0, -18), Vector2i(0, -28), 2)
	# East corridor to Echoes
	_generate_corridor_hex(Vector2i(18, 0), Vector2i(28, 0), 2)
	# South corridor to Aether
	_generate_corridor_hex(Vector2i(0, 18), Vector2i(0, 28), 2)
	# West corridor to Pacts
	_generate_corridor_hex(Vector2i(-18, 0), Vector2i(-28, 0), 2)
	# Down corridor to Undercroft (short, hidden)
	_generate_corridor_hex(Vector2i(10, 10), Vector2i(10, 14), 2)
	# Up corridor to Clocktower (from Gears north)
	_generate_corridor_hex(Vector2i(0, -52), Vector2i(0, -60), 2)
	# North corridor to Disciplinary Wing (behind Registrar, blocked until hard mode)
	_generate_corridor_hex(Vector2i(3, -18), Vector2i(3, -28), 2)
	
	# === COLLEGE OF GEARS (north, radius 14) ===
	_generate_room_hex("f6_gears", Vector2i(0, -40), 14, [
		Vector2i(0, -26),   # South portal -> quadrangle corridor
		Vector2i(0, -52),   # Up portal -> Clocktower corridor
	])
	
	# Gear puzzle nodes (object tiles)
	var gear_nodes = [Vector2i(-5, -40), Vector2i(0, -45), Vector2i(5, -40)]
	for gear_hex in gear_nodes:
		hex_map.set_tile(gear_hex, HexTileMap.TILE_OBJECT)
	
	# Clock mechanism (object)
	hex_map.set_tile(Vector2i(0, -50), HexTileMap.TILE_OBJECT)
	
	# === COLLEGE OF ECHOES (east, radius 14) ===
	_generate_room_hex("f6_echoes", Vector2i(40, 0), 14, [
		Vector2i(26, 0),    # West portal -> quadrangle corridor
	])
	
	# Whispering/Screaming books (object tiles)
	var book_positions = [Vector2i(35, -5), Vector2i(45, -5), Vector2i(40, 8)]
	for book_hex in book_positions:
		hex_map.set_tile(book_hex, HexTileMap.TILE_OBJECT)
	
	# Research Tome (object)
	hex_map.set_tile(Vector2i(38, 5), HexTileMap.TILE_OBJECT)
	
	# Thesis Panel (object)
	hex_map.set_tile(Vector2i(42, 0), HexTileMap.TILE_OBJECT)
	
	# Toxic ink zones (dark purple floor — use water tile for visual)
	for q in range(33, 48):
		for r in range(-8, 8):
			var hex = Vector2i(q, r)
			var dist = HexTileMap._hex_distance(hex, Vector2i(40, 0))
			if dist >= 8 and dist <= 12 and hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				toxic_ink_hexes.append(hex)
	
	# Moonlight Inscription (hidden, only readable in moonlight)
	hex_map.set_tile(Vector2i(46, 2), HexTileMap.TILE_OBJECT)
	
	# Shadow Cache (hidden, only findable in shadow)
	hex_map.set_tile(Vector2i(34, -6), HexTileMap.TILE_OBJECT)
	
	# === COLLEGE OF AETHER (south, radius 14) ===
	_generate_room_hex("f6_aether", Vector2i(0, 40), 14, [
		Vector2i(0, 26),    # North portal -> quadrangle corridor
	])
	
	# Aether research equipment (object tiles)
	var aether_equipment = [Vector2i(-5, 40), Vector2i(5, 40), Vector2i(0, 45)]
	for equip_hex in aether_equipment:
		hex_map.set_tile(equip_hex, HexTileMap.TILE_OBJECT)
	
	# === COLLEGE OF PACTS (west, radius 14) — locked initially ===
	_generate_room_hex("f6_pacts", Vector2i(-40, 0), 14, [
		Vector2i(-26, 0),   # East portal -> quadrangle corridor
	])
	
	# Locked doors (object tiles at entrance)
	hex_map.set_tile(Vector2i(-28, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-28, 1), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-28, -1), HexTileMap.TILE_OBJECT)
	
	# === DISCIPLINARY WING (north-east of quadrangle, behind Registrar, blocked) ===
	_generate_room_hex("f6_detention", Vector2i(3, -40), 8, [
		Vector2i(3, -26),   # South portal -> quadrangle corridor
	])
	
	# Block the entrance with walls until hard mode triggers
	for wall_hex in disciplinary_wall_hexes:
		if hex_map.get_tile(wall_hex) == HexTileMap.TILE_FLOOR:
			hex_map.set_tile(wall_hex, HexTileMap.TILE_WALL)
	
	# Security office desk (object)
	hex_map.set_tile(Vector2i(3, -42), HexTileMap.TILE_OBJECT)
	
	# === UNDERCROFT (below quadrangle, small area radius 8) ===
	_generate_room_hex("f6_undercroft", Vector2i(10, 10), 8, [
		Vector2i(10, 14),   # Up portal -> quadrangle
	])
	
	# Sneak Thief / Maintenance Goblin (object tile)
	hex_map.set_tile(Vector2i(10, 10), HexTileMap.TILE_OBJECT)
	
	# Hatch to Undercroft (from quadrangle)
	hex_map.set_tile(Vector2i(10, 14), HexTileMap.TILE_PORTAL)
	
	# === CLOCKTOWER (north of Gears, elevated, radius 12, boss arena) ===
	_generate_room_hex("f6_clocktower", Vector2i(0, -70), 12, [
		Vector2i(0, -58),   # Down portal -> Gears corridor
	])
	
	# Dean's Door (locked, object)
	hex_map.set_tile(Vector2i(0, -62), HexTileMap.TILE_OBJECT)
	
	# Boss arena center (object — elevated platform visual)
	for offset in [Vector2i(0, -70), Vector2i(2, -70), Vector2i(-2, -70), Vector2i(0, -72), Vector2i(0, -68)]:
		hex_map.set_tile(offset, HexTileMap.TILE_OBJECT)
	
	# Elevator to Clocktower (from Gears)
	hex_map.set_tile(Vector2i(0, -58), HexTileMap.TILE_PORTAL)
	
	# Portal to Floor 7 after boss (placed at edge, hidden until boss defeated)
	# We'll reveal this by changing a tile after boss defeat
	
	# === MOONLIGHT BEAMS (initial positions) ===
	# Place 3 moonlight beams in quadrangle and nearby areas
	var initial_beams = [Vector2i(-10, -10), Vector2i(10, 10), Vector2i(-10, 10)]
	for beam_hex in initial_beams:
		if hex_map.get_tile(beam_hex) == HexTileMap.TILE_FLOOR:
			moonlight_beam_hexes.append(beam_hex)
	
	# === FLOOR 5 EXIT PORTAL ===
	# Near quadrangle edge
	hex_map.set_tile(Vector2i(0, 22), HexTileMap.TILE_PORTAL)
	
	print("[Floor6-Hex] Layout complete: Quadrangle + 4 colleges + Undercroft + Clocktower")

func _generate_room_hex(room_id: String, center: Vector2i, radius: int, portal_positions: Array[Vector2i]):
	"""Generate a roughly circular room with walls at edges."""
	for q in range(center.x - radius - 1, center.x + radius + 2):
		for r in range(center.y - radius - 1, center.y + radius + 2):
			var hex = Vector2i(q, r)
			var dist = HexTileMap._hex_distance(hex, center)
			
			var is_portal = false
			for portal_hex in portal_positions:
				if hex == portal_hex:
					is_portal = true
					break
			
			if is_portal:
				hex_map.set_tile(hex, HexTileMap.TILE_PORTAL)
			elif dist <= radius - 1:
				hex_map.set_tile(hex, HexTileMap.TILE_FLOOR)
			elif dist <= radius:
				var near_portal = false
				for portal_hex in portal_positions:
					if HexTileMap._hex_distance(hex, portal_hex) <= 1:
						near_portal = true
						break
				if near_portal:
					hex_map.set_tile(hex, HexTileMap.TILE_FLOOR)
				else:
					hex_map.set_tile(hex, HexTileMap.TILE_WALL)

func _generate_corridor_hex(start: Vector2i, end: Vector2i, width: int):
	"""Generate a corridor between two points."""
	var path = HexTileMap._hex_line(start, end)
	for hex in path:
		for dq in range(-width, width + 1):
			for dr in range(-width, width + 1):
				var check = Vector2i(hex.x + dq, hex.y + dr)
				var existing = hex_map.get_tile(check)
				if existing == HexTileMap.TILE_VOID or existing == HexTileMap.TILE_PORTAL:
					hex_map.set_tile(check, HexTileMap.TILE_FLOOR)

# ===================================================================
# PLAYER
# ===================================================================

func _setup_player():
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		player_node = CharacterBody2D.new()
		player_node.name = "Player"
		player_node.z_index = 100
		player_node.add_to_group("player")
		
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		collision.shape = circle
		player_node.add_child(collision)
		
		player_node.collision_layer = 2
		player_node.collision_mask = 1
		
		var player_sprite = Sprite2D.new()
		player_sprite.name = "PlayerSprite"
		player_sprite.centered = true
		player_sprite.scale = Vector2(3.0, 3.0)
		player_node.add_child(player_sprite)
		
		var animator = Node2D.new()
		animator.name = "PlayerAnimator"
		animator.set_script(preload("res://scripts/PlayerAnimator.gd"))
		player_node.add_child(animator)
		
		var shadow = Polygon2D.new()
		shadow.name = "Shadow"
		shadow.polygon = PackedVector2Array([
			Vector2(-15, 25), Vector2(15, 25),
			Vector2(10, 35), Vector2(-10, 35)
		])
		shadow.color = Color(0.0, 0.0, 0.0, 0.3)
		shadow.z_index = -1
		player_node.add_child(shadow)
		
		add_child(player_node)
		print("[Floor6-Hex] Player created")
	
	# Place at quadrangle center
	var quad_center = room_data["f6_quadrangle"]["center"]
	player_node.global_position = hex_map.hex_to_world(quad_center)
	print("[Floor6-Hex] Player placed at quadrangle: %s" % str(quad_center))

# ===================================================================
# ENEMIES
# ===================================================================

func _setup_enemies():
	"""Spawn enemies on the hex grid for each room."""
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)
	
	var enemy_spawns = {
		"f6_quadrangle": [],  # Security only in hard mode, spawned later
		"f6_gears": [
			{"name": "Gear Construct", "hex": Vector2i(-5, -38), "faction": "Construct"},
			{"name": "Gear Construct", "hex": Vector2i(5, -38), "faction": "Construct"},
			{"name": "Professor", "hex": Vector2i(0, -35), "faction": "Construct"},
		],
		"f6_echoes": [
			{"name": "Student Echo", "hex": Vector2i(35, -3), "faction": "Undead"},
			{"name": "Student Echo", "hex": Vector2i(45, 3), "faction": "Undead"},
			{"name": "Professor", "hex": Vector2i(40, -5), "faction": "Undead"},
		],
		"f6_aether": [
			{"name": "Aether Wisp", "hex": Vector2i(-5, 42), "faction": "Elemental"},
			{"name": "Aether Wisp", "hex": Vector2i(5, 42), "faction": "Elemental"},
			{"name": "Elemental", "hex": Vector2i(0, 45), "faction": "Elemental"},
		],
		"f6_pacts": [
			{"name": "Pact Guardian", "hex": Vector2i(-42, -2), "faction": "Demon"},
			{"name": "Pact Guardian", "hex": Vector2i(-42, 2), "faction": "Demon"},
		],
		"f6_undercroft": [],  # Goblin is an NPC, not an enemy
		"f6_clocktower": [
			{"name": "The Dean", "hex": Vector2i(0, -70), "faction": "Construct", "boss": true},
		],
	}
	
	for room_id in enemy_spawns.keys():
		for spawn_data in enemy_spawns[room_id]:
			var enemy = HexEnemy.new(
				spawn_data["name"] + "_%d" % hex_enemies.size(),
				spawn_data["name"],
				spawn_data["hex"],
				spawn_data.get("faction", "Unknown"),
				spawn_data.get("boss", false)
			)
			enemy.name = "HexEnemy_%d" % hex_enemies.size()
			
			# Configure stats
			if spawn_data.get("boss", false):
				enemy.max_hp = 70
				enemy.hp = 70
				enemy.attack = 8
				enemy.defense = 4
				enemy.is_boss = true
			elif spawn_data["name"] == "Pact Guardian":
				enemy.max_hp = 20
				enemy.hp = 20
				enemy.attack = 4
				enemy.defense = 2
			elif spawn_data["name"] == "Professor":
				enemy.max_hp = 18
				enemy.hp = 18
				enemy.attack = 4
				enemy.defense = 1
			else:
				enemy.max_hp = 12 + randi() % 6
				enemy.hp = enemy.max_hp
				enemy.attack = 3 + randi() % 3
				enemy.defense = randi() % 2
			
			enemy_container.add_child(enemy)
			enemy.set_hex_map_position(spawn_data["hex"], hex_map)
			
			# Connect signals
			enemy.combat_initiated.connect(_on_enemy_combat_initiated)
			
			hex_enemies.append(enemy)
			print("[Floor6-Hex] Spawned %s at %s" % [spawn_data["name"], str(spawn_data["hex"])])
	
	print("[Floor6-Hex] %d hex enemies spawned" % hex_enemies.size())

func _spawn_security_drones(count: int):
	"""Spawn security drones in quadrangle for hard mode."""
	var quad_center = room_data["f6_quadrangle"]["center"]
	for i in range(count):
		var angle = float(i) / count * TAU
		var dist = 12
		var hex = Vector2i(
			quad_center.x + int(round(cos(angle) * dist)),
			quad_center.y + int(round(sin(angle) * dist))
		)
		var enemy = HexEnemy.new(
			"CalibrationDrone_%d" % hex_enemies.size(),
			"Calibration Drone",
			hex,
			"Construct",
			false
		)
		enemy.max_hp = 10
		enemy.hp = 10
		enemy.attack = 3
		enemy.defense = 1
		_add_enemy(enemy, hex)
		print("[Floor6-Hex] Spawned security drone at %s" % str(hex))

func _add_enemy(enemy: HexEnemy, hex: Vector2i):
	"""Add an enemy to the world with proper setup."""
	enemy.name = "HexEnemy_%d" % hex_enemies.size()
	enemy_container.add_child(enemy)
	enemy.set_hex_map_position(hex, hex_map)
	enemy.combat_initiated.connect(_on_enemy_combat_initiated)
	hex_enemies.append(enemy)

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		combat_manager.turn_started.connect(_on_combat_turn_started)
		print("[Floor6-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	
	var enemies = _get_encounter_enemies(encounter_type)
	if enemies.is_empty():
		return
	
	in_combat = true
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.start_combat(enemies, GameState.player_deck)
		AudioManager.play_combat(6)
		print("[Floor6-Hex] Combat started: %s" % encounter_type)
		combat_turn_count = 0
		moonlight_turn_count = 0
		clocktower_turn_count = 0

var combat_turn_count: int = 0

func _get_encounter_enemies(encounter_type: String) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	match encounter_type:
		"construct": result = _spawn_enemies(["Gear Construct", "Gear Construct"])
		"echoes":    result = _spawn_enemies(["Student Echo", "Student Echo", "Professor"])
		"aether":    result = _spawn_enemies(["Aether Wisp", "Aether Wisp", "Elemental"])
		"pacts":     result = _spawn_enemies(["Pact Guardian", "Pact Guardian"])
		"boss":      result = _spawn_enemies(["The Dean"])
		"security":  result = _spawn_enemies(["Calibration Drone", "Calibration Drone"])
		"detention": result = _spawn_enemies(["Calibration Drone", "Calibration Drone", "Calibration Drone"])
		_:
			result = _spawn_enemies(["Gear Construct"])
	return result

func _spawn_enemies(enemy_names: Array[String]) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	for name in enemy_names:
		var template = RoomEnemyDatabase.ENEMIES.get(name)
		if template:
			result.append(template.to_combat_data())
	return result

func _on_combat_ended(victory: bool):
	in_combat = false
	AudioManager.play_floor_ambient(6)
	
	# Reset surviving enemies to unaware, clean up dead ones
	for enemy in hex_enemies:
		if enemy.hp > 0:
			enemy.reset_after_combat()
		else:
			enemy.queue_free()
	
	# Remove dead enemies from array
	var alive_enemies: Array[HexEnemy] = []
	for enemy in hex_enemies:
		if enemy.hp > 0:
			alive_enemies.append(enemy)
		else:
			# Check if professor was defeated
			if enemy.enemy_name == "Professor":
				professor_defeated_in_combat = true
				_trigger_lecture_hall_panic()
		hex_enemies = alive_enemies
	
	if victory:
		room_cleared[current_room_id] = true
		print("[Floor6-Hex] Room cleared: %s" % current_room_id)
		
		# Check faction kills for course progress
		var faction = _get_room_faction(current_room_id)
		if faction != "":
			_record_enemy_defeat(faction, false)
		
		# Check if boss defeated
		if current_room_id == "f6_clocktower":
			_on_dean_defeated()
			return
		
		# Check if all courses completed after combat
		_check_all_courses_complete()
	else:
		print("[Floor6-Hex] Combat lost — player respawned")
		GameState.player_hp = max(1, GameState.player_hp)
		player_node.global_position = hex_map.hex_to_world(room_data["f6_quadrangle"]["center"])
		current_room_id = "f6_quadrangle"
		for enemy in hex_enemies:
			enemy.reset_after_combat()
	
	professor_defeated_in_combat = false

func _on_enemy_combat_initiated(ambush: bool):
	"""Called when an enemy initiates or is ambushed into combat."""
	if in_combat:
		return
	
	ambush_bonus = ambush
	
	var ambush_msg = "AMBUSH! Player bonus turn!" if ambush else "Enemy spotted you!"
	_show_notification(ambush_msg, 3.0)
	
	# Find all enemies in combat range
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var combat_enemies: Array[CombatManager.EnemyData] = []
	
	for enemy in hex_enemies:
		if enemy.state == HexEnemy.State.IN_COMBAT or enemy.hp <= 0:
			continue
		var dist = HexTileMap._hex_distance(player_hex, enemy.hex_pos)
		if dist <= 3:
			combat_enemies.append(enemy.to_combat_data())
			enemy._set_state(HexEnemy.State.IN_COMBAT)
	
	if combat_enemies.is_empty():
		return
	
	# Start card combat
	in_combat = true
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		AudioManager.play_combat(6)
		print("[Floor6-Hex] Hex combat started! Enemies: %d, Ambush: %s" % [combat_enemies.size(), str(ambush)])
		
		if ambush:
			combat_manager.is_player_turn = true
			combat_manager.player_shield += 2
			print("[Floor6-Hex] Ambush bonus: +2 shield, player goes first")
		
		combat_turn_count = 0
		moonlight_turn_count = 0
		clocktower_turn_count = 0

func _check_enemy_sight():
	"""Check if any enemy can see the player."""
	if in_combat or not player_node or not hex_map:
		return
	
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	for enemy in hex_enemies:
		if enemy.state == HexEnemy.State.IN_COMBAT or enemy.hp <= 0:
			continue
		enemy.check_player_sight(player_hex)

func _try_ambush_at_hex(target_hex: Vector2i) -> bool:
	"""Check if player walked onto or adjacent to an enemy for ambush."""
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		var dist = HexTileMap._hex_distance(target_hex, enemy.hex_pos)
		if dist <= 1:
			if enemy.try_ambush(target_hex):
				return true
	return false

func _get_room_faction(room_id: String) -> String:
	match room_id:
		"f6_gears":  return "Construct"
		"f6_echoes": return "Undead"
		"f6_aether": return "Elemental"
		"f6_pacts":  return "Demon"
		_: return ""

# ===================================================================
# UI
# ===================================================================

func _setup_ui():
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(540, 650)
	interact_prompt.size = Vector2(200, 30)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.add_theme_font_size_override("font_size", 14)
	interact_prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	interact_prompt.visible = false
	add_child(interact_prompt)
	
	_pause_menu_setup()
	_curriculum_ui_setup()
	_moonlight_ui_setup()
	_clocktower_ui_setup()
	_grade_ui_setup()
	_boss_phase_ui_setup()
	_room_indicator_setup()

func _pause_menu_setup():
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.process_mode = PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.size = Vector2(1280, 720)
	pause_menu.add_child(bg)
	
	var container = VBoxContainer.new()
	container.position = Vector2(560, 320)
	container.size = Vector2(160, 150)
	pause_menu.add_child(container)
	
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause_menu)
	container.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): GameState.save_game(); _show_notification("Saved!"))
	container.add_child(save_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn"))
	container.add_child(quit_btn)

func _curriculum_ui_setup():
	curriculum_ui = Label.new()
	curriculum_ui.name = "CurriculumUI"
	curriculum_ui.position = Vector2(20, 20)
	curriculum_ui.size = Vector2(400, 80)
	curriculum_ui.add_theme_font_size_override("font_size", 13)
	add_child(curriculum_ui)
	_update_curriculum_display()

func _moonlight_ui_setup():
	moonlight_ui = Label.new()
	moonlight_ui.name = "MoonlightUI"
	moonlight_ui.position = Vector2(20, 110)
	moonlight_ui.size = Vector2(300, 30)
	moonlight_ui.add_theme_font_size_override("font_size", 12)
	add_child(moonlight_ui)
	_update_moonlight_display()

func _clocktower_ui_setup():
	clocktower_ui = Label.new()
	clocktower_ui.name = "ClocktowerUI"
	clocktower_ui.position = Vector2(20, 150)
	clocktower_ui.size = Vector2(300, 30)
	clocktower_ui.add_theme_font_size_override("font_size", 12)
	add_child(clocktower_ui)
	_update_clocktower_display()

func _grade_ui_setup():
	grade_ui = Label.new()
	grade_ui.name = "GradeUI"
	grade_ui.position = Vector2(20, 190)
	grade_ui.size = Vector2(300, 60)
	grade_ui.add_theme_font_size_override("font_size", 12)
	grade_ui.visible = false
	add_child(grade_ui)

func _boss_phase_ui_setup():
	boss_phase_ui = Label.new()
	boss_phase_ui.name = "BossPhaseUI"
	boss_phase_ui.position = Vector2(20, 260)
	boss_phase_ui.size = Vector2(300, 30)
	boss_phase_ui.add_theme_font_size_override("font_size", 12)
	boss_phase_ui.visible = false
	add_child(boss_phase_ui)

func _room_indicator_setup():
	room_indicator = Label.new()
	room_indicator.name = "RoomIndicator"
	room_indicator.position = Vector2(20, 300)
	room_indicator.size = Vector2(300, 30)
	room_indicator.add_theme_font_size_override("font_size", 12)
	add_child(room_indicator)
	_update_room_indicator()

func _update_room_indicator():
	if not room_indicator:
		return
	var data = room_data.get(current_room_id, {})
	room_indicator.text = "📍 %s" % data.get("display", "Unknown")
	match current_room_id:
		"f6_quadrangle": room_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		"f6_detention":  room_indicator.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		"f6_gears":      room_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6))
		"f6_echoes":     room_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		"f6_aether":     room_indicator.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
		"f6_pacts":      room_indicator.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
		"f6_undercroft": room_indicator.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		"f6_clocktower": room_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

func _toggle_pause_menu():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

# ===================================================================
# MOVEMENT (WEADZX + Click-to-Move)
# ===================================================================

func _input(event: InputEvent):
	if in_combat or in_transition or in_ui:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_click_move(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_click_interact(event.position)
		return
	
	if event is InputEventKey and event.pressed:
		path_movement_active = false
		match event.keycode:
			KEY_ESCAPE:
				_toggle_pause_menu()
				return
			KEY_E:
				_hex_move(Vector2(0.5, -0.866))
			KEY_W:
				_hex_move(Vector2(-0.5, -0.866))
			KEY_A:
				_hex_move(Vector2(-1, 0))
			KEY_D:
				_hex_move(Vector2(1, 0))
			KEY_Z:
				_hex_move(Vector2(-0.5, 0.866))
			KEY_X:
				_hex_move(Vector2(0.5, 0.866))
			KEY_S, KEY_SPACE:
				_try_interact()
				return
			KEY_T:
				# End turn in combat (if implemented)
				return

func _on_click_move(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
	
	# Check if clicked on enemy for ambush
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if enemy.hex_pos == target_hex:
			if enemy.try_ambush(hex_map.world_to_hex(player_node.global_position)):
				return
	
	if not hex_map.is_walkable(target_hex):
		_show_notification("Can't move there!")
		return
	
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	if target_hex == current_hex:
		return
	
	var path = hex_map.find_path(current_hex, target_hex)
	if path.is_empty() or path.size() <= 1:
		_show_notification("No path!")
		return
	
	# Check if path goes near enemy for ambush
	for step_hex in path.slice(1):
		for enemy in hex_enemies:
			if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
				continue
			if HexTileMap._hex_distance(step_hex, enemy.hex_pos) <= 1:
				var ambush_path = path.slice(1, path.find(step_hex) + 1)
				path_movement_target = ambush_path
				path_movement_index = 0
				path_movement_timer = 0.0
				path_movement_active = true
				return
	
	path_movement_target = path.slice(1)
	path_movement_index = 0
	path_movement_timer = 0.0
	path_movement_active = true

func _on_click_interact(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var click_hex = hex_map.world_to_hex(world_pos)
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	# Check if clicked on/near enemy for ambush
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if HexTileMap._hex_distance(click_hex, enemy.hex_pos) <= 1:
			if enemy.try_ambush(player_hex):
				return
	
	var dist = HexTileMap._hex_distance(player_hex, click_hex)
	if dist <= 1:
		_try_interact()
	else:
		_show_notification("Too far to interact.")

func _hex_move(move_vec: Vector2):
	if not player_node:
		return
	
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	var direction = _vector_to_hex_dir(move_vec)
	var dirs = HexTileMap.DIRECTIONS
	var target_hex = current_hex + dirs[direction]
	
	if hex_map.is_wall(target_hex):
		return
	
	# Check if player walked onto/near an enemy for ambush
	if _try_ambush_at_hex(target_hex):
		return
	
	# Toxic ink check (Echoes library)
	if current_room_id == "f6_echoes":
		if target_hex in toxic_ink_hexes:
			_show_notification("☠ Toxic ink! Attention draining...", Color(0.5, 0.3, 0.5))
	
	player_node.global_position = hex_map.hex_to_world(target_hex)
	
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	
	_check_room_transition(target_hex)
	_check_interactables()
	_check_enemy_sight()
	_check_player_moonlight_position()
	_check_registrar_passed()

func _vector_to_hex_dir(velocity: Vector2) -> int:
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	if degrees >= -30 and degrees < 30:         return 3
	elif degrees >= 30 and degrees < 90:          return 5
	elif degrees >= 90 and degrees < 150:         return 4
	elif degrees >= 150 or degrees < -150:        return 2
	elif degrees >= -150 and degrees < -90:       return 0
	elif degrees >= -90 and degrees < -30:       return 1
	else:                                         return 3

func _velocity_to_direction(velocity: Vector2) -> String:
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	if degrees >= -22.5 and degrees < 22.5:       return "e"
	elif degrees >= 22.5 and degrees < 67.5:     return "se"
	elif degrees >= 67.5 and degrees < 112.5:    return "s"
	elif degrees >= 112.5 and degrees < 157.5:   return "sw"
	elif degrees >= 157.5 or degrees < -157.5:    return "w"
	elif degrees >= -157.5 and degrees < -112.5: return "nw"
	elif degrees >= -112.5 and degrees < -67.5:  return "n"
	else:                                         return "ne"

# ===================================================================
# ROOM / PORTAL TRANSITIONS
# ===================================================================

func _check_room_transition(player_hex: Vector2i):
	# Check if standing on a portal tile
	if hex_map.get_tile(player_hex) == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir:
			# Special checks for locked areas
			if portal_dir == "west" and current_room_id == "f6_quadrangle" and not pacts_unlocked:
				_show_notification("🔒 College of Pacts is locked. Need Master Key or course completion.")
				return
			if portal_dir == "up" and current_room_id == "f6_gears" and not dean_elevator_unlocked:
				_show_notification("🔒 Clocktower elevator locked. Complete courses or use Master Key.")
				return
			_try_portal_transition(portal_dir)
			return
	
	# Check if entered a new room region
	for room_id in room_data.keys():
		if room_id == current_room_id:
			continue
		var data = room_data[room_id]
		var dist = HexTileMap._hex_distance(player_hex, data["center"])
		if dist <= data["radius"]:
			_enter_room(room_id)
			return

func _get_portal_direction_from_hex(hex: Vector2i) -> String:
	var current_data = room_data.get(current_room_id)
	if not current_data:
		return ""
	var center = current_data["center"]
	for dir_name in portal_offsets.keys():
		var offset = portal_offsets[dir_name]
		var portal_hex = center + offset
		if hex == portal_hex:
			return dir_name
	return ""

func _try_portal_transition(direction: String):
	var connections = portal_connections.get(current_room_id, {})
	var target_room = connections.get(direction, "")
	if target_room.is_empty():
		return
	
	# Special transition checks
	if target_room == "f6_clocktower" and not dean_elevator_unlocked:
		_show_notification("The elevator is locked. Complete your courses or find the Master Key.")
		return
	
	if target_room == "f6_pacts" and not pacts_unlocked:
		_show_notification("The College of Pacts is sealed. A Master Key might open it...")
		return
	
	in_transition = true
	AudioManager.play_sfx("room_enter")
	
	var target_data = room_data[target_room]
	var target_hex = target_data["center"]
	var opposite_dir = _opposite_direction(direction)
	var entry_offset = portal_offsets.get(opposite_dir, Vector2i.ZERO)
	player_node.global_position = hex_map.hex_to_world(target_hex + entry_offset)
	
	var msg = ""
	match target_room:
		"f6_gears":      msg = "You enter the College of Gears..."
		"f6_echoes":     msg = "The library whispers around you..."
		"f6_aether":     msg = "Elemental energy crackles..."
		"f6_pacts":      msg = "Red light spills from the sealed college..."
		"f6_undercroft": msg = "You descend into the Undercroft..."
		"f6_detention":  msg = "You enter the Disciplinary Wing..."
		"f6_clocktower": msg = "The elevator rises to the Clocktower Apex..."
		"f6_quadrangle": msg = "You return to the Quadrangle."
	if msg != "":
		_show_notification(msg, 2.5)
	
	_enter_room(target_room)
	in_transition = false

func _enter_room(room_id: String):
	if room_id == current_room_id:
		return
	
	current_room_id = room_id
	var data = room_data[room_id]
	print("[Floor6-Hex] Entered room: %s" % data["display"])
	room_changed.emit(room_id, data["display"])
	
	_update_room_indicator()
	
	# Check for room-specific environmental messages
	match room_id:
		"f6_echoes":
			in_echoes_library = true
			_show_notification("📚 Toxic ink detected in the library.", Color(0.5, 0.3, 0.5))
		"f6_undercroft":
			_show_notification("🕳 The Undercroft smells of oil and secrets...", Color(0.4, 0.4, 0.5))
		"f6_clocktower":
			_show_notification("⏰ The Dean awaits at the Clocktower Apex...", Color(0.7, 0.7, 0.8))
		_:
			in_echoes_library = false
	
	# Spawn encounter if not cleared and not already spawned
	if not room_cleared.get(room_id, false) and not room_encounter_spawned.get(room_id, false):
		if data["encounter"] != "none":
			room_encounter_spawned[room_id] = true
			_start_combat(data["encounter"])

func _opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east":  return "west"
		"west":  return "east"
		"up":    return "down"
		"down":  return "up"
	return ""

# ===================================================================
# INTERACTION
# ===================================================================

func _check_interactables():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var player_pos = player_node.global_position
	
	match current_room_id:
		"f6_quadrangle":
			_check_interactables_quadrangle(player_hex)
		"f6_gears":
			_check_interactables_gears(player_hex)
		"f6_echoes":
			_check_interactables_echoes(player_hex)
		"f6_aether":
			_check_interactables_aether(player_hex)
		"f6_pacts":
			_check_interactables_pacts(player_hex)
		"f6_undercroft":
			_check_interactables_undercroft(player_hex)
		"f6_clocktower":
			_check_interactables_clocktower(player_hex)

func _check_interactables_quadrangle(player_hex: Vector2i):
	# The Registrar (near center)
	if HexTileMap._hex_distance(player_hex, Vector2i(3, 0)) <= 1:
		_show_interact_prompt("[S] Talk to Registrar")
		return
	
	# Save Point
	if HexTileMap._hex_distance(player_hex, Vector2i(15, 0)) <= 1:
		_show_interact_prompt("[S] Save Game")
		return
	
	# Fountain (center)
	if HexTileMap._hex_distance(player_hex, Vector2i(0, 0)) <= 1:
		_show_interact_prompt("[S] Inspect Fountain")
		return
	
	# Undercroft hatch
	if HexTileMap._hex_distance(player_hex, Vector2i(10, 14)) <= 1:
		_show_interact_prompt("[S] Enter Undercroft")
		return
	
	# Floor 5 exit portal
	if HexTileMap._hex_distance(player_hex, Vector2i(0, 22)) <= 1:
		_show_interact_prompt("[S] Return to Floor 5")
		return
	
	_hide_interact_prompt()

func _check_interactables_gears(player_hex: Vector2i):
	# Gear puzzle nodes
	var gear_nodes = [Vector2i(-5, -40), Vector2i(0, -45), Vector2i(5, -40)]
	for gear_hex in gear_nodes:
		if HexTileMap._hex_distance(player_hex, gear_hex) <= 1:
			_show_interact_prompt("[S] Align Gear")
			return
	
	# Clock mechanism
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -50)) <= 1:
		_show_interact_prompt("[S] Sabotage Clock / Speed Up")
		return
	
	# Elevator to Clocktower
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -52)) <= 1:
		if dean_elevator_unlocked:
			_show_interact_prompt("[S] Take Elevator to Clocktower")
		else:
			_show_interact_prompt("[S] Elevator (Locked)")
		return
	
	_hide_interact_prompt()

func _check_interactables_echoes(player_hex: Vector2i):
	# Books
	var book_positions = [Vector2i(35, -5), Vector2i(45, -5), Vector2i(40, 8)]
	for book_hex in book_positions:
		if HexTileMap._hex_distance(player_hex, book_hex) <= 1:
			_show_interact_prompt("[S] Read Book")
			return
	
	# Research Tome
	if HexTileMap._hex_distance(player_hex, Vector2i(38, 5)) <= 1:
		_show_interact_prompt("[S] Study Tome")
		return
	
	# Thesis Panel
	if HexTileMap._hex_distance(player_hex, Vector2i(42, 0)) <= 1:
		_show_interact_prompt("[S] Defend Thesis")
		return
	
	# Moonlight Inscription
	if HexTileMap._hex_distance(player_hex, Vector2i(46, 2)) <= 1:
		_show_interact_prompt("[S] Read Inscription")
		return
	
	# Shadow Cache
	if HexTileMap._hex_distance(player_hex, Vector2i(34, -6)) <= 1:
		_show_interact_prompt("[S] Search Cache")
		return
	
	_hide_interact_prompt()

func _check_interactables_aether(player_hex: Vector2i):
	# Aether equipment
	var aether_equipment = [Vector2i(-5, 40), Vector2i(5, 40), Vector2i(0, 45)]
	for equip_hex in aether_equipment:
		if HexTileMap._hex_distance(player_hex, equip_hex) <= 1:
			_show_interact_prompt("[S] Examine Equipment")
			return
	
	_hide_interact_prompt()

func _check_interactables_pacts(player_hex: Vector2i):
	# Locked doors at entrance
	if HexTileMap._hex_distance(player_hex, Vector2i(-28, 0)) <= 1:
		_show_interact_prompt("[S] College of Pacts Door")
		return
	
	_hide_interact_prompt()

func _check_interactables_undercroft(player_hex: Vector2i):
	# Sneak Thief
	if HexTileMap._hex_distance(player_hex, Vector2i(10, 10)) <= 1:
		_show_interact_prompt("[S] Talk to Janitor")
		return
	
	_hide_interact_prompt()

func _check_interactables_clocktower(player_hex: Vector2i):
	# Dean's Door
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -62)) <= 1:
		if not dean_defeated:
			_show_interact_prompt("[S] Dean's Door (Boss)")
		else:
			_show_interact_prompt("[S] Ascend to Floor 7")
		return
	
	_hide_interact_prompt()

func _try_interact():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	match current_room_id:
		"f6_quadrangle":
			_try_interact_quadrangle(player_hex)
		"f6_gears":
			_try_interact_gears(player_hex)
		"f6_echoes":
			_try_interact_echoes(player_hex)
		"f6_aether":
			_try_interact_aether(player_hex)
		"f6_pacts":
			_try_interact_pacts(player_hex)
		"f6_undercroft":
			_try_interact_undercroft(player_hex)
		"f6_clocktower":
			_try_interact_clocktower(player_hex)

func _try_interact_quadrangle(player_hex: Vector2i):
	# The Registrar
	if HexTileMap._hex_distance(player_hex, Vector2i(3, 0)) <= 1:
		_interact_registrar()
		return
	
	# Save Point
	if HexTileMap._hex_distance(player_hex, Vector2i(15, 0)) <= 1:
		if GameState.has_method("save_game"):
			GameState.save_game()
		_show_dialogue("Save Point", "Progress saved.")
		return
	
	# Fountain
	if HexTileMap._hex_distance(player_hex, Vector2i(0, 0)) <= 1:
		_show_dialogue("Fountain", "Water flows upward. The moon is reflected in its surface.")
		return
	
	# Undercroft hatch
	if HexTileMap._hex_distance(player_hex, Vector2i(10, 14)) <= 1:
		_try_portal_transition("down")
		return
	
	# Floor 5 exit
	if HexTileMap._hex_distance(player_hex, Vector2i(0, 22)) <= 1:
		_show_dialogue("The Tower", "Descend to Floor 5?")
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/Floor5.tscn")
		return

func _try_interact_gears(player_hex: Vector2i):
	# Gear puzzle nodes
	var gear_nodes = [Vector2i(-5, -40), Vector2i(0, -45), Vector2i(5, -40)]
	for i in range(gear_nodes.size()):
		if HexTileMap._hex_distance(player_hex, gear_nodes[i]) <= 1:
			_align_gear(i)
			return
	
	# Clock mechanism
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -50)) <= 1:
		_interact_clock_mechanism()
		return
	
	# Elevator
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -52)) <= 1:
		if dean_elevator_unlocked:
			_try_portal_transition("up")
		else:
			_show_dialogue("Elevator", "Locked. The Dean's permission is required... or a Master Key.")
		return

func _try_interact_echoes(player_hex: Vector2i):
	# Books
	var book_positions = [Vector2i(35, -5), Vector2i(45, -5), Vector2i(40, 8)]
	for book_hex in book_positions:
		if HexTileMap._hex_distance(player_hex, book_hex) <= 1:
			_read_book()
			return
	
	# Research Tome
	if HexTileMap._hex_distance(player_hex, Vector2i(38, 5)) <= 1:
		_study_tome()
		return
	
	# Thesis Panel
	if HexTileMap._hex_distance(player_hex, Vector2i(42, 0)) <= 1:
		_defend_thesis()
		return
	
	# Moonlight Inscription
	if HexTileMap._hex_distance(player_hex, Vector2i(46, 2)) <= 1:
		if in_moonlight:
			_show_dialogue("Inscription", "The moonlight reveals hidden text:\n'Knowledge consumes those who seek it. The Dean was once a student too.'")
		else:
			_show_dialogue("Inscription", "Just scratched stone. Nothing readable.")
		return
	
	# Shadow Cache
	if HexTileMap._hex_distance(player_hex, Vector2i(34, -6)) <= 1:
		if not in_moonlight:
			_show_notification("🔍 Found hidden cache! 10 Gems!", Color(0.9, 0.7, 0.3))
			GameState.gems += 10
			if GameState.has_signal("gems_changed"):
				GameState.gems_changed.emit(GameState.gems)
		else:
			_show_notification("Nothing here. Too bright to hide anything.", Color(0.7, 0.7, 0.7))
		return

func _try_interact_aether(player_hex: Vector2i):
	_show_dialogue("Research", "Aether equipment hums with elemental energy. You gain insight into Elemental Theory.")
	# Bonus for Elemental course if assigned
	if not assigned_courses.is_empty():
		for i in range(assigned_courses.size()):
			if assigned_courses[i]["type"] == "Elemental" and not assigned_courses[i]["completed"]:
				_show_notification("📚 Elemental research bonus! Course progress +1", Color(0.3, 0.9, 0.3))
				assigned_courses[i]["defeated_count"] += 1
				_update_course_grade(i)
				_update_curriculum_display()
				break

func _try_interact_pacts(player_hex: Vector2i):
	if HexTileMap._hex_distance(player_hex, Vector2i(-28, 0)) <= 1:
		if master_key_held or pacts_unlocked:
			pacts_unlocked = true
			_show_dialogue("College of Pacts", "The Master Key turns. The heavy doors groan open. Red light spills out.")
		else:
			_show_dialogue("College of Pacts", "LOCKED. Requires Dean's Permission and Signed Waiver.\n...or a really good key.")
		return

func _try_interact_undercroft(player_hex: Vector2i):
	if HexTileMap._hex_distance(player_hex, Vector2i(10, 10)) <= 1:
		_interact_goblin()
		return

func _try_interact_clocktower(player_hex: Vector2i):
	if HexTileMap._hex_distance(player_hex, Vector2i(0, -62)) <= 1:
		if not dean_defeated:
			if master_key_held or dean_elevator_unlocked:
				_start_combat("boss")
			else:
				_show_dialogue("Dean's Door", "Locked. The Dean awaits those who have proven themselves... or those with a key.")
		else:
			_ascend_to_floor7()
		return

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

# ===================================================================
# FLOOR 6 — CURRICULUM SYSTEM
# ===================================================================

func _interact_registrar():
	"""Talk to The Registrar — assign courses, audit, or refuse."""
	if graduate_status:
		_show_dialogue("The Registrar", "Welcome back, Graduate. All courses waived. The Dean awaits.")
		return
	
	if audit_mode:
		_show_dialogue("The Registrar", "Audit status confirmed. Proceed safely.")
		return
	
	if not assigned_courses.is_empty():
		_show_dialogue("The Registrar", "Courses in progress. Complete your curriculum.")
		return
	
	# First interaction — present choices
	_show_dialogue("The Registrar", "Welcome to the Lunar University.\n\n1. Enroll (3 courses — Construct, Undead, Elemental)\n2. Audit (safe passage, no rewards)\n3. Refuse (hard mode — security drones activated)")
	
	# For simplicity, auto-enroll in the hex version (could be expanded with UI choices)
	_assign_courses()

func _assign_courses():
	"""The Registrar assigns 3 courses."""
	if graduate_status or audit_mode or not assigned_courses.is_empty():
		return
	
	var course_types = ["Construct", "Undead", "Elemental"]
	course_types.shuffle()
	assigned_courses.clear()
	course_progress.clear()
	
	for i in range(3):
		var course_type = course_types[i]
		var course = {
			"id": i,
			"type": course_type,
			"defeated_count": 0,
			"damage_taken": false,
			"completed": false
		}
		assigned_courses.append(course)
		course_progress[i] = 0
		player_grades[i] = "F"
	
	_show_dialogue("The Registrar", "You are enrolled in 3 courses:\n1. Engineering (Construct)\n2. History (Undead)\n3. Elemental Theory (Elemental)\n\nDefeat the required enemies. Take no damage for an A. Fail and face detention.")
	_update_curriculum_display()
	print("[Floor6-Hex] 3 courses assigned")

func _audit_courses():
	audit_mode = true
	_show_dialogue("The Registrar", "Audit status confirmed. No requirements. No rewards. Safe passage granted.")
	_update_curriculum_display()

func _refuse_courses():
	_show_dialogue("The Registrar", "UNENROLLED. All campus security to quadrangle. DISCIPLINARY ACTION INITIATED.")
	_trigger_hard_mode()
	_update_curriculum_display()

func _trigger_hard_mode():
	"""Open the disciplinary hallway and spawn security drones."""
	if hard_mode_active:
		return
	hard_mode_active = true
	
	# Open the disciplinary wall — restore portal tile for the entrance
	for wall_hex in disciplinary_wall_hexes:
		if hex_map.get_tile(wall_hex) == HexTileMap.TILE_WALL:
			if wall_hex == Vector2i(3, -18):
				hex_map.set_tile(wall_hex, HexTileMap.TILE_PORTAL)
			else:
				hex_map.set_tile(wall_hex, HexTileMap.TILE_FLOOR)
	
	_show_notification("🚨 DISCIPLINARY HALLWAY OPENED! Security drones deployed!", Color(0.9, 0.2, 0.2))
	
	# Spawn security drones in the disciplinary wing
	var detention_center = room_data["f6_detention"]["center"]
	for i in range(4):
		var offset = Vector2i(randi() % 10 - 5, randi() % 10 - 5)
		var spawn_hex = detention_center + offset
		if hex_map.get_tile(spawn_hex) == HexTileMap.TILE_FLOOR:
			var enemy = HexEnemy.new("detention_drone_%d" % i, "Calibration Drone", spawn_hex, "Construct")
			enemy.hp = 12
			enemy.attack = 4
			enemy.view_range = 8
			enemy.combat_range = 1
			enemy.patrol_radius = 5
			_add_enemy(enemy, spawn_hex)
	
	# Also spawn security in quadrangle
	_spawn_security_drones(2)
	
	print("[Floor6-Hex] Hard mode activated — disciplinary wing open, security deployed")

func _check_registrar_passed():
	"""Check if player walked past the Registrar (north of him) without enrolling."""
	if not player_node or hard_mode_active or assigned_courses.size() > 0 or audit_mode or graduate_status:
		return
	
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	# Registrar is at (3, 0). Walking past him means entering hexes north of him (y < 0, x near 3)
	if player_hex.y <= -5 and player_hex.x >= 0 and player_hex.x <= 6 and current_room_id == "f6_quadrangle":
		if not hard_mode_passed_trigger:
			hard_mode_passed_trigger = true
			_show_dialogue("The Registrar", "Passing by without enrolling? You think you can just WALK past the curriculum?")
			await get_tree().create_timer(1.5).timeout
			_trigger_hard_mode()
	else:
		# Reset trigger if player moves away (prevents false trigger from just being nearby)
		if player_hex.y > -5 or player_hex.x < -2 or player_hex.x > 9:
			hard_mode_passed_trigger = false


func _record_enemy_defeat(faction: String, damage_taken: bool):
	"""Record an enemy defeat for course progress."""
	if audit_mode or graduate_status or assigned_courses.is_empty():
		return
	
	for i in range(assigned_courses.size()):
		var course = assigned_courses[i]
		if course["type"] == faction and not course["completed"]:
			course["defeated_count"] += 1
			if damage_taken:
				course["damage_taken"] = true
			
			_update_course_grade(i)
			print("[Floor6-Hex] Course %d progress: %d defeats, grade: %s" % [
				i, course["defeated_count"], player_grades[i]
			])
	
	_update_curriculum_display()
	_check_all_courses_complete()

func _update_course_grade(course_id: int):
	var course = assigned_courses[course_id]
	var count = course["defeated_count"]
	var no_damage = not course["damage_taken"]
	
	if count >= 5 and no_damage:
		player_grades[course_id] = "A"
	elif count >= 3:
		player_grades[course_id] = "B"
	elif count >= 1:
		player_grades[course_id] = "C"
	else:
		player_grades[course_id] = "F"
	
	assigned_courses[course_id]["completed"] = (player_grades[course_id] != "F")

func _check_all_courses_complete():
	if assigned_courses.is_empty():
		return
	
	var all_passed = true
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		if grade == "F":
			all_passed = false
	
	if all_passed and not all_courses_completed:
		all_courses_completed = true
		_show_dialogue("The Registrar", "ALL COURSES PASSED. Graduation requirements met. The Dean's elevator is now accessible.")
		_unlock_dean_elevator()

func _apply_course_rewards():
	if audit_mode:
		return
	
	var total_gems = 0
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		match grade:
			"A": total_gems += 50
			"B": total_gems += 25
			"C": total_gems += 0
			"F": _trigger_detention()
	
	if total_gems > 0:
		GameState.gems += total_gems
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
		_show_notification("🎓 Course rewards: %d Gems!" % total_gems, Color(0.3, 0.9, 0.3))

func _trigger_detention():
	_show_notification("⚠ DETENTION! Campus security incoming!", Color(0.9, 0.3, 0.3))
	_start_combat("detention")

func _unlock_dean_elevator():
	dean_elevator_unlocked = true
	_show_notification("🛗 Dean's elevator unlocked!", Color(0.3, 0.9, 0.3))
	print("[Floor6-Hex] Dean's elevator unlocked!")

func _update_curriculum_display():
	if not curriculum_ui:
		return
	
	if audit_mode:
		curriculum_ui.text = "📝 AUDIT MODE — Safe Passage"
		curriculum_ui.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		return
	
	if graduate_status:
		curriculum_ui.text = "🎓 GRADUATE — No Courses Required"
		curriculum_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		return
	
	if assigned_courses.is_empty():
		curriculum_ui.text = "📝 No Courses Assigned\nTalk to The Registrar"
		curriculum_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		return
	
	var text = "📝 CURRICULUM:\n"
	for i in range(assigned_courses.size()):
		var course = assigned_courses[i]
		var grade = player_grades.get(i, "F")
		var target = 5 if grade == "A" else (3 if grade == "B" else 1)
		text += "%d. %s: %d/%d [%s]\n" % [i + 1, course["type"], course["defeated_count"], target, grade]
	
	curriculum_ui.text = text
	curriculum_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	grade_ui.visible = true
	_update_grade_display()

func _update_grade_display():
	if not grade_ui:
		return
	
	var text = "GRADES:\n"
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		text += "Course %d: %s\n" % [i + 1, grade]
	
	grade_ui.text = text

# ===================================================================
# FLOOR 6 — MOONLIGHT BEAM SYSTEM
# ===================================================================

func _shift_moonlight_beams():
	"""Move moonlight beams to new random positions."""
	moonlight_beam_hexes.clear()
	
	# Pick 3 random floor hexes in/near quadrangle and colleges
	var possible_hexes: Array[Vector2i] = []
	for hex in hex_map.grid.keys():
		if hex_map.grid[hex] == HexTileMap.TILE_FLOOR:
			possible_hexes.append(hex)
	
	possible_hexes.shuffle()
	for i in range(min(3, possible_hexes.size())):
		moonlight_beam_hexes.append(possible_hexes[i])
	
	_show_notification("🌙 Moonlight shifts...", Color(0.7, 0.7, 0.9))
	print("[Floor6-Hex] Moonlight beams shifted to %d positions" % moonlight_beam_hexes.size())

func _check_player_moonlight_position():
	"""Check if player is standing in moonlight or shadow."""
	if moonlight_beam_hexes.is_empty():
		return
	
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var in_light = false
	
	for beam_hex in moonlight_beam_hexes:
		if HexTileMap._hex_distance(player_hex, beam_hex) <= 2:
			in_light = true
			break
	
	if in_light and not in_moonlight:
		in_moonlight = true
		_show_notification("🌙 MOONLIGHT — Text revealed! Enemies can see you!", Color(0.7, 0.7, 0.9))
	elif not in_light and in_moonlight:
		in_moonlight = false
		_show_notification("🌑 SHADOW — Hidden from enemies.", Color(0.3, 0.3, 0.4))
	
	_update_moonlight_display()

func _update_moonlight_display():
	if not moonlight_ui:
		return
	
	var next_shift = moonlight_shift_interval - (moonlight_turn_count % moonlight_shift_interval)
	var status = "🌙 Moonlight: %s | Next shift: %d" % [
		"LIGHT" if in_moonlight else "SHADOW",
		next_shift
	]
	
	var color = Color(0.7, 0.7, 0.9) if in_moonlight else Color(0.3, 0.3, 0.4)
	moonlight_ui.text = status
	moonlight_ui.add_theme_color_override("font_color", color)

# ===================================================================
# FLOOR 6 — CLOCKTOWER BELL SYSTEM
# ===================================================================

func _ring_clocktower_bell():
	"""The bell rings — all enemies in combat heal 5 HP."""
	_show_notification("🔔 BELL RINGS — Classes resume! Enemies heal 5 HP!", Color(0.9, 0.7, 0.3))
	
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager and "enemies" in combat_manager:
		for enemy in combat_manager.enemies:
			if enemy.hp > 0:
				enemy.hp = min(enemy.max_hp, enemy.hp + 5)
	
	print("[Floor6-Hex] Clocktower bell — all enemies healed 5 HP")

func _interact_clock_mechanism():
	"""Sabotage or speed up the clock."""
	_show_dialogue("Clock Mechanism", "1. Sabotage (stop bell, trigger security)\n2. Speed Up (enemies age, take DOT)")
	
	# For simplicity, sabotage is the primary interaction
	_sabotage_clocktower()

func _sabotage_clocktower():
	if clocktower_sabotaged:
		_show_notification("Clock already sabotaged.", Color(0.7, 0.7, 0.7))
		return
	
	clocktower_sabotaged = true
	GameState.floor6_clocktower_sabotaged = true
	
	_show_notification("🔧 CLOCK SABOTAGED — Bell silenced forever!", Color(0.9, 0.3, 0.3))
	_show_dialogue("The Tower", "The clocktower mechanism grinds to a halt. The bell will never ring again. But campus security has been alerted...")
	_trigger_detention()
	_update_clocktower_display()
	print("[Floor6-Hex] Clocktower sabotaged!")

func _speed_up_clock():
	_show_notification("⏱ CLOCK ACCELERATED — Enemies age rapidly!", Color(0.9, 0.5, 0.2))
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager and "enemies" in combat_manager:
		for enemy in combat_manager.enemies:
			if enemy.hp > 0:
				var dot = CombatManager.DoTData.new("aging", 3, 3, "clock", Color(0.5, 0.5, 0.3))
				enemy.add_dot(dot)

func _check_boss_phase_in_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager or combat_manager.enemies.is_empty():
		return
	
	var boss = combat_manager.enemies[0]  # The Dean is first enemy
	var boss_hp = boss.hp
	var max_hp = boss.max_hp
	_check_boss_phase(boss_hp, max_hp)

func _update_clocktower_display():
	if not clocktower_ui:
		return
	
	if clocktower_sabotaged:
		clocktower_ui.text = "🔧 CLOCK: SABOTAGED"
		clocktower_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		var next_bell = clocktower_bell_interval - (clocktower_turn_count % clocktower_bell_interval)
		clocktower_ui.text = "🔔 Bell: %d turns" % next_bell
		clocktower_ui.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

# ===================================================================
# FLOOR 6 — LECTURE HALL PANIC
# ===================================================================

func _trigger_lecture_hall_panic():
	"""When a professor is defeated, nearby student enemies panic."""
	_show_notification("📚 PROFESSOR DEFEATED! Students panic!", Color(0.9, 0.9, 0.3))
	
	for enemy in hex_enemies:
		if enemy.enemy_name == "Student Echo" or enemy.enemy_name == "Gear Construct":
			var roll = randi() % 3
			match roll:
				0:
					print("[Floor6-Hex] Student %s flees!" % enemy.enemy_name)
					enemy.patrol_center = enemy.hex_pos + Vector2i(randi() % 5 - 2, randi() % 5 - 2)
				1:
					print("[Floor6-Hex] Student %s attacks wildly!" % enemy.enemy_name)
				2:
					print("[Floor6-Hex] Student %s freezes in panic!" % enemy.enemy_name)
					# Skip next turn effect handled by AI state

# ===================================================================
# FLOOR 6 — TOXIC INK (College of Echoes)
# ===================================================================

func _check_toxic_ink():
	"""Check if player is in toxic ink and drain attention."""
	if not in_echoes_library:
		return
	
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	if player_hex in toxic_ink_hexes:
		var drain = toxic_ink_attention_drain
		if GameState.get_value("has_spore_filter", false):
			drain = max(1, drain / 2)
		# TODO: Reduce Attention by drain (when attention system exists)
		print("[Floor6-Hex] Toxic ink drains %d Attention" % drain)

# ===================================================================
# FLOOR 6 — BOSS PHASE SYSTEM (The Dean)
# ===================================================================

func _check_boss_phase(boss_hp: int, max_hp: int = 70) -> String:
	var hp_percent = float(boss_hp) / max_hp
	var new_phase = "administration"
	if hp_percent <= 0.5:
		new_phase = "lunar"
	
	if new_phase != boss_current_phase and not boss_phase_transitioned:
		boss_current_phase = new_phase
		boss_phase_transitioned = true
		_on_boss_phase_transition(new_phase)
	
	return new_phase

func _on_boss_phase_transition(new_phase: String):
	match new_phase:
		"lunar":
			_show_notification("🌙 PHASE 2: LUNAR CONSTRUCT — Moonlight floods the arena!", Color(0.7, 0.7, 0.9))
			_show_dialogue("The Dean", "The clocktower glass shatters. Moonlight floods the arena. I become the night.")
			print("[Floor6-Hex] Dean enters Lunar phase — immune to debuffs")
			
			# Update boss display
			if boss_phase_ui:
				boss_phase_ui.text = "BOSS: The Dean [LUNAR PHASE]"
				boss_phase_ui.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
				boss_phase_ui.visible = true

func _on_dean_defeated():
	dean_defeated = true
	_show_dialogue("The Tower", "The Dean falls. The clocktower bell rings one final time — a graduation chime. The Dean's Key materializes. The path to Floor 7 opens.")
	
	GameState.add_card_to_deck("the_dean")
	GameState.gems += 100
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	
	graduate_status = true
	GameState.floor6_graduate_status = "graduate"
	GameState.save_game()
	
	# Reveal Floor 7 portal in clocktower
	_show_notification("🌟 Floor 7 portal revealed! Interact with Dean's Door to ascend.", Color(0.3, 0.9, 0.3))

# ===================================================================
# FLOOR 6 — UNDERCROFT GOBLIN (Sneak Thief)
# ===================================================================

func _interact_goblin():
	if goblin_janitor_befriended:
		_show_dialogue("Sneak Thief", "Hey pal! Need a key? I 'borrowed' one from the Dean's office. Take it — no strings attached.\n...okay, 5 Gems interest. Payable never.")
		
		if not master_key_held:
			master_key_held = true
			GameState.floor6_master_key = true
			_show_notification("🔑 MASTER KEY acquired! Opens any locked door!", Color(0.9, 0.7, 0.3))
			
			# Also offer to steal a card with IOU
			_show_dialogue("Sneak Thief", "Want me to 'borrow' a card from the Dean's desk? I'll leave an IOU. Returns in 3 turns + 5 Gems.")
	else:
		_show_dialogue("Sneak Thief", "Yo. I'm the union rep for maintenance goblins. You look like someone who needs doors opened. I can help. But you gotta be cool.")
		goblin_janitor_befriended = true
		GameState.floor6_goblin_janitor_befriended = true
		_show_notification("🤝 Goblin janitor befriended!", Color(0.3, 0.9, 0.3))

# ===================================================================
# FLOOR 6 — BOOKS / RESEARCH / GEAR PUZZLE / THESIS
# ===================================================================

func _read_book():
	var roll = randi() % 3
	match roll:
		0:
			_show_dialogue("Book", "Whispered lore: 'The Dean was once a student too. The Construct department built him first.'")
			books_read += 1
		1:
			_show_dialogue("Book", "The book SCREAMS! 2 damage from misinformation!")
			GameState.damage_player(2)
		2:
			_show_dialogue("Book", "Research notes on Construct vulnerabilities. Next course grade +1!")
			books_read += 1
			# Apply research bonus
			for i in range(assigned_courses.size()):
				if assigned_courses[i]["type"] == "Construct" and not assigned_courses[i]["completed"]:
					assigned_courses[i]["defeated_count"] += 1
					_update_course_grade(i)
					break
	
	_check_research_status()
	_update_curriculum_display()

func _study_tome():
	_show_dialogue("Tome", "Dense academic text. You gain 'Research' status.")
	books_read += 1
	_check_research_status()

func _check_research_status():
	if books_read >= 5:
		_show_notification("📚 RESEARCH STATUS — Next course grade +1!", Color(0.3, 0.9, 0.3))
		# Apply grade boost to incomplete courses
		for i in range(assigned_courses.size()):
			if not assigned_courses[i]["completed"]:
				assigned_courses[i]["defeated_count"] += 1
				_update_course_grade(i)
				break

func _align_gear(gear_index: int):
	gear_puzzle_aligned += 1
	_show_notification("⚙ Gear %d aligned! (%d/%d)" % [gear_index + 1, gear_puzzle_aligned, gear_puzzle_total], Color(0.7, 0.7, 0.7))
	
	if gear_puzzle_aligned >= gear_puzzle_total:
		_show_notification("⚙ All gears aligned! Shortcut to Echoes unlocked!", Color(0.3, 0.9, 0.3))
		# Unlock shortcut corridor between Gears and Echoes
		_generate_corridor_hex(Vector2i(0, -40), Vector2i(40, 0), 1)

func _defend_thesis():
	_show_dialogue("Thesis Panel", "Present your research.")
	
	var target_count = 0
	for course in assigned_courses:
		if course["completed"]:
			target_count += 1
	
	if target_count >= 2 or books_read >= 3:
		_show_dialogue("Thesis Panel", "THESIS ACCEPTED. Dean's Key fragment granted. College of Pacts partially unlocked.")
		pacts_unlocked = true
		if not master_key_held:
			master_key_held = true
			GameState.floor6_master_key = true
			_show_notification("🔑 Dean's Key fragment acquired!", Color(0.9, 0.7, 0.3))
	else:
		_show_dialogue("Thesis Panel", "THESIS REJECTED. Insufficient research. Detention combat initiated.")
		_trigger_detention()

# ===================================================================
# FLOOR COMPLETE / TRANSITION
# ===================================================================

func _ascend_to_floor7():
	if not dean_defeated:
		return
	
	_show_dialogue("The Tower", "The path to Floor 7 opens. The Broken Pact awaits...")
	await get_tree().create_timer(2.0).timeout
	AudioManager.play_sfx("floor_transition")
	get_tree().change_scene_to_file("res://scenes/Floor7.tscn")

func _descend_to_floor5():
	_show_dialogue("The Tower", "Descend to Floor 5...")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/Floor5.tscn")

# ===================================================================
# DIALOGUE / NOTIFICATIONS
# ===================================================================

func _show_dialogue(speaker: String, text: String):
	var dialogue = Label.new()
	dialogue.name = "DialogueBox"
	dialogue.text = "%s: %s" % [speaker, text]
	dialogue.position = Vector2(140, 550)
	dialogue.size = Vector2(1000, 100)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_font_size_override("font_size", 16)
	add_child(dialogue)
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(dialogue):
		dialogue.queue_free()

func _show_notification(text: String, color: Color = Color(0.3, 0.9, 0.3), duration: float = 3.0):
	var notif = Label.new()
	notif.text = text
	notif.position = Vector2(390, 300)
	notif.size = Vector2(500, 30)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", color)
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 250, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

# ===================================================================
# FLOOR SPECIFIC
# ===================================================================

func _setup_floor_specific():
	# Restore saved state
	if GameState.floor6_graduate_status == "graduate":
		graduate_status = true
		_show_notification("🎓 Graduate Status active — No course assignment needed.", Color(0.3, 0.9, 0.3))
	
	if GameState.floor6_clocktower_sabotaged:
		clocktower_sabotaged = true
	
	if GameState.floor6_master_key:
		master_key_held = true
	
	if GameState.floor6_goblin_janitor_befriended:
		goblin_janitor_befriended = true
	
	print("[Floor6-Hex] Floor 6 initialized — Curriculum, Moonlight, Clocktower, Toxic Ink, Dean Boss, Goblin")

# ===================================================================
# PROCESS LOOP
# ===================================================================

func _process(_delta: float):
	# Camera follows player
	if player_node:
		var camera = get_node_or_null("Camera2D")
		if camera:
			camera.global_position = player_node.global_position
	
	# Path movement (click-to-move)
	if path_movement_active and player_node and not in_combat and not in_transition:
		path_movement_timer += _delta
		if path_movement_timer >= PATH_MOVE_STEP_INTERVAL:
			path_movement_timer = 0.0
			if path_movement_index < path_movement_target.size():
				var step_hex = path_movement_target[path_movement_index]
				
				if hex_map.is_wall(step_hex):
					path_movement_active = false
					return
				
				# Check for ambush opportunity at each step
				for enemy in hex_enemies:
					if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
						continue
					if HexTileMap._hex_distance(step_hex, enemy.hex_pos) <= 1:
						player_node.global_position = hex_map.hex_to_world(step_hex)
						path_movement_active = false
						var animator = player_node.get_node_or_null("PlayerAnimator")
						if animator:
							animator.play_idle()
						_check_enemy_sight()
						return
				
				var prev_pos = player_node.global_position
				player_node.global_position = hex_map.hex_to_world(step_hex)
				
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					var dir_vec = player_node.global_position - prev_pos
					var dir_str = _velocity_to_direction(dir_vec)
					animator.play_walk(dir_str)
					animator.set_meta("move_timer", 0.2)
				
				_check_room_transition(step_hex)
				_check_interactables()
				path_movement_index += 1
				_check_enemy_sight()
				_check_registrar_passed()
			else:
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
				return
	
	# Enemy sight check every frame
	if not in_combat and not in_transition:
		_check_enemy_sight()
	
	# Movement idle timer
	if not path_movement_active:
		var animator = player_node.get_node_or_null("PlayerAnimator") if player_node else null
		if animator and animator.has_meta("move_timer"):
			var timer = animator.get_meta("move_timer") - _delta
			if timer <= 0:
				animator.play_idle()
				animator.set_meta("move_timer", 0.0)
			else:
				animator.set_meta("move_timer", timer)

# ===================================================================
# COMBAT TURN HANDLING (called by CombatManager or internal)
# ===================================================================

func _on_combat_turn_started(is_player_turn: bool):
	if not is_player_turn:
		return
	combat_turn_count += 1
	
	# Moonlight shift every 5 combat turns
	moonlight_turn_count += 1
	if moonlight_turn_count % moonlight_shift_interval == 0:
		_shift_moonlight_beams()
	_check_player_moonlight_position()
	
	# Clocktower bell every 10 combat turns
	clocktower_turn_count += 1
	if not clocktower_sabotaged and clocktower_turn_count % clocktower_bell_interval == 0:
		_ring_clocktower_bell()
	
	# Toxic ink check
	if in_echoes_library:
		_check_toxic_ink()
	
	# Update displays
	_update_moonlight_display()
	_update_clocktower_display()
	_update_curriculum_display()
	
	# Check boss phase (if in boss combat)
	if current_room_id == "f6_clocktower" and in_combat:
		_check_boss_phase_in_combat()

# ===================================================================
# PUBLIC API
# ===================================================================

func get_assigned_courses() -> Array:
	return assigned_courses.duplicate()

func get_grades() -> Dictionary:
	return player_grades.duplicate()

func is_graduate() -> bool:
	return graduate_status

func has_master_key() -> bool:
	return master_key_held

func is_clocktower_sabotaged() -> bool:
	return clocktower_sabotaged
