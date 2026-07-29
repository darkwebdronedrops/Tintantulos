extends Node2D

# ===================================================================
# FLOOR 10 CONTROLLER — Hex-Based — The Dragon's Lair
# ===================================================================
# 11 Moments: Ghosts → Hoard → Aspects → Revelation → Throne
# Dragon boss with true/false endings, Cano Protocol meta-boss
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "f10_moment_01"
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false
var is_paused: bool = false

# Click-to-Move
var path_movement_active: bool = false
var path_movement_target: Array[Vector2i] = []
var path_movement_index: int = 0
var path_movement_timer: float = 0.0
const PATH_MOVE_STEP_INTERVAL: float = 0.12

# -------------------------------------------------------------------
# Floor 10 — Moment State
# -------------------------------------------------------------------
var current_moment: int = 1
var total_moments: int = 11
var moment_type: String = "ghost"

# -------------------------------------------------------------------
# Floor 10 — Ghost State
# -------------------------------------------------------------------
var ghosts_spoken: Dictionary = {
	"f10_moment_01": false,
	"f10_moment_02": false,
	"f10_moment_03": false,
}

# -------------------------------------------------------------------
# Floor 10 — Hoard State
# -------------------------------------------------------------------
var hoard_objects_touched: Dictionary = {}
var hoard_objects_altered: Dictionary = {}
var hoard_weight_revealed: bool = false

# -------------------------------------------------------------------
# Floor 10 — Aspect State
# -------------------------------------------------------------------
var aspects_defeated: Array[String] = []
var aspect_current: String = ""

# -------------------------------------------------------------------
# Floor 10 — Dragon State
# -------------------------------------------------------------------
var dragon_phase: int = 1
var dragon_hp: int = 50
var dragon_max_hp: int = 50
var player_attacked_in_phase_1: bool = false
var crack_revealed: bool = false
var final_choice_made: bool = false
var ending_chosen: String = ""

# -------------------------------------------------------------------
# Floor 10 — Weight Calculation
# -------------------------------------------------------------------
var player_weight: int = 0

# -------------------------------------------------------------------
# Floor 10 — Cano Protocol State
# -------------------------------------------------------------------
var cano_protocol_triggered: bool = false
var cano_hp: int = 50
var cano_archive_remaining: int = 50
var cano_ability_index: int = 0
var cano_phase: int = 1

# -------------------------------------------------------------------
# Room Data — 11 Moments in linear corridor
# -------------------------------------------------------------------
var room_data: Dictionary = {
	"f10_moment_01": {"center": Vector2i(-80, 0),   "radius": 12, "encounter": "ghost",   "display": "Moment 1 — Threshold",       "level": "ghost", "ghost_boss": "The Door"},
	"f10_moment_02": {"center": Vector2i(-60, 0),   "radius": 12, "encounter": "ghost",   "display": "Moment 2 — Witness",         "level": "ghost", "ghost_boss": "Spore Heart"},
	"f10_moment_03": {"center": Vector2i(-40, 0),   "radius": 12, "encounter": "ghost",   "display": "Moment 3 — Memory",          "level": "ghost", "ghost_boss": "Gear Mother"},
	"f10_moment_04": {"center": Vector2i(-20, 0),   "radius": 15, "encounter": "hoard",   "display": "Moment 4 — The Hoard",         "level": "hoard"},
	"f10_moment_05": {"center": Vector2i(-20, -25), "radius": 10, "encounter": "weight",  "display": "Moment 5 — The Weight",        "level": "weight"},
	"f10_moment_06": {"center": Vector2i(0, 0),     "radius": 12, "encounter": "aspect",  "display": "Moment 6 — Aspect of Time",    "level": "aspect", "aspect": "time"},
	"f10_moment_07": {"center": Vector2i(20, 0),     "radius": 12, "encounter": "aspect",  "display": "Moment 7 — Aspect of Greed",   "level": "aspect", "aspect": "greed"},
	"f10_moment_08": {"center": Vector2i(40, 0),     "radius": 12, "encounter": "aspect",  "display": "Moment 8 — Aspect of Transformation", "level": "aspect", "aspect": "transformation"},
	"f10_moment_09": {"center": Vector2i(60, 0),     "radius": 12, "encounter": "approach", "display": "Moment 9 — The Approach",     "level": "approach"},
	"f10_moment_10": {"center": Vector2i(80, 0),     "radius": 14, "encounter": "boss",    "display": "Moment 10 — The Revelation",   "level": "revelation"},
	"f10_moment_11": {"center": Vector2i(100, 0),    "radius": 12, "encounter": "throne",  "display": "Moment 11 — The Throne",       "level": "throne"},
	"f10_cano":      {"center": Vector2i(80, -30),   "radius": 10, "encounter": "cano",    "display": "The Cano Protocol",            "level": "hidden"},
}

# Portal connections (linear corridor + hoard branch)
var portal_connections: Dictionary = {
	"f10_moment_01": {"east": "f10_moment_02", "exit": "f10_floor9"},
	"f10_moment_02": {"west": "f10_moment_01", "east": "f10_moment_03"},
	"f10_moment_03": {"west": "f10_moment_02", "east": "f10_moment_04"},
	"f10_moment_04": {"west": "f10_moment_03", "north": "f10_moment_05", "east": "f10_moment_06"},
	"f10_moment_05": {"south": "f10_moment_04"},
	"f10_moment_06": {"west": "f10_moment_04", "east": "f10_moment_07"},
	"f10_moment_07": {"west": "f10_moment_06", "east": "f10_moment_08"},
	"f10_moment_08": {"west": "f10_moment_07", "east": "f10_moment_09"},
	"f10_moment_09": {"west": "f10_moment_08", "east": "f10_moment_10"},
	"f10_moment_10": {"west": "f10_moment_09", "east": "f10_moment_11", "down": "f10_cano"},
	"f10_moment_11": {"west": "f10_moment_10"},
	"f10_cano":      {"up": "f10_moment_10"},
}

var portal_offsets: Dictionary = {
	"east": Vector2i(10, 0), "west": Vector2i(-10, 0),
	"north": Vector2i(0, -10), "south": Vector2i(0, 10),
	"up": Vector2i(0, -8), "down": Vector2i(0, 8),
	"exit": Vector2i(-15, 0),
}

var room_cleared: Dictionary = {}
var room_encounter_spawned: Dictionary = {}

# Hex enemies on the grid (only Aspects, Dragon, and Cano Protocol)
var hex_enemies: Array[HexEnemy] = []
var enemy_container: Node2D
var ambush_bonus: bool = false

# UI
var interact_prompt: Label
var pause_menu: CanvasLayer
var moment_ui: Label
var hoard_ui: Label
var aspect_ui: Label
var dragon_ui: Label
var weight_ui: Label
var cano_ui: Label
var room_indicator: Label

# Signals
signal room_changed(room_id: String, room_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	# Reset for replayability — selecting floor from menu should always be fresh
	room_cleared.clear()
	room_encounter_spawned.clear()
	call_deferred("_build_floor")

func _build_floor():
	_generate_hex_layout()
	print("[Floor10-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_enemies()
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(10)
	_enter_room("f10_moment_01")

# ===================================================================
# HEX LAYOUT — Linear Corridor with Hoard Branch
# ===================================================================

func _generate_hex_layout():
	hex_map.clear_grid()
	
	# === MOMENTS 1-3 — Ghost Rooms (west) ===
	_generate_room_hex("f10_moment_01", Vector2i(-80, 0), 12, [Vector2i(-70, 0)])
	_generate_room_hex("f10_moment_02", Vector2i(-60, 0), 12, [Vector2i(-50, 0), Vector2i(-70, 0)])
	_generate_room_hex("f10_moment_03", Vector2i(-40, 0), 12, [Vector2i(-30, 0), Vector2i(-50, 0)])
	
	# === MOMENT 4 — The Hoard (central, larger) ===
	_generate_room_hex("f10_moment_04", Vector2i(-20, 0), 15, [Vector2i(-10, 0), Vector2i(-30, 0), Vector2i(-20, -10)])
	
	# === MOMENT 5 — The Weight (north branch) ===
	_generate_room_hex("f10_moment_05", Vector2i(-20, -25), 10, [Vector2i(-20, -15)])
	
	# === MOMENTS 6-8 — Aspects (east) ===
	_generate_room_hex("f10_moment_06", Vector2i(0, 0), 12, [Vector2i(-10, 0), Vector2i(10, 0)])
	_generate_room_hex("f10_moment_07", Vector2i(20, 0), 12, [Vector2i(10, 0), Vector2i(30, 0)])
	_generate_room_hex("f10_moment_08", Vector2i(40, 0), 12, [Vector2i(30, 0), Vector2i(50, 0)])
	
	# === MOMENTS 9-11 — Dragon (far east) ===
	_generate_room_hex("f10_moment_09", Vector2i(60, 0), 12, [Vector2i(50, 0), Vector2i(70, 0)])
	_generate_room_hex("f10_moment_10", Vector2i(80, 0), 14, [Vector2i(70, 0), Vector2i(90, 0), Vector2i(80, -10)])
	_generate_room_hex("f10_moment_11", Vector2i(100, 0), 12, [Vector2i(90, 0)])
	
	# === HIDDEN — Cano Protocol (north of Revelation) ===
	_generate_room_hex("f10_cano", Vector2i(80, -30), 10, [Vector2i(80, -20)])
	
	# === CORRIDORS (linear path) ===
	_generate_corridor_hex(Vector2i(-70, 0), Vector2i(-50, 0), 2)
	_generate_corridor_hex(Vector2i(-50, 0), Vector2i(-30, 0), 2)
	_generate_corridor_hex(Vector2i(-30, 0), Vector2i(-10, 0), 2)
	_generate_corridor_hex(Vector2i(-20, -10), Vector2i(-20, -15), 2)  # Hoard to Weight
	_generate_corridor_hex(Vector2i(-10, 0), Vector2i(10, 0), 2)
	_generate_corridor_hex(Vector2i(10, 0), Vector2i(30, 0), 2)
	_generate_corridor_hex(Vector2i(30, 0), Vector2i(50, 0), 2)
	_generate_corridor_hex(Vector2i(50, 0), Vector2i(70, 0), 2)
	_generate_corridor_hex(Vector2i(70, 0), Vector2i(90, 0), 2)
	_generate_corridor_hex(Vector2i(80, -10), Vector2i(80, -20), 2)  # Revelation to Cano (hidden)
	
	# === GHOSTS (object tiles) ===
	hex_map.set_tile(Vector2i(-80, 0), HexTileMap.TILE_OBJECT)   # Ghost The Door
	hex_map.set_tile(Vector2i(-60, 0), HexTileMap.TILE_OBJECT)   # Ghost Spore Heart
	hex_map.set_tile(Vector2i(-40, 0), HexTileMap.TILE_OBJECT)   # Ghost Gear Mother
	
	# === HOARD OBJECTS (object tiles) ===
	hex_map.set_tile(Vector2i(-25, -5), HexTileMap.TILE_OBJECT)   # Blood Contract
	hex_map.set_tile(Vector2i(-15, -5), HexTileMap.TILE_OBJECT)   # Soul Gem
	hex_map.set_tile(Vector2i(-25, 5), HexTileMap.TILE_OBJECT)   # Reforged Blade
	hex_map.set_tile(Vector2i(-15, 5), HexTileMap.TILE_OBJECT)   # Graduate Scroll
	
	# === WEIGHT SCALES (object tile) ===
	hex_map.set_tile(Vector2i(-20, -25), HexTileMap.TILE_OBJECT)  # Weight Scales
	
	# === ASPECTS (object tiles) ===
	hex_map.set_tile(Vector2i(0, 0), HexTileMap.TILE_OBJECT)      # Aspect of Time
	hex_map.set_tile(Vector2i(20, 0), HexTileMap.TILE_OBJECT)     # Aspect of Greed
	hex_map.set_tile(Vector2i(40, 0), HexTileMap.TILE_OBJECT)     # Aspect of Transformation
	
	# === DRAGON (object tile) ===
	hex_map.set_tile(Vector2i(80, 0), HexTileMap.TILE_OBJECT)     # The Dragon
	
	# === THRONE CHOICES (object tiles) ===
	hex_map.set_tile(Vector2i(95, -3), HexTileMap.TILE_OBJECT)   # Destroy Dragon
	hex_map.set_tile(Vector2i(100, 0), HexTileMap.TILE_OBJECT)    # Become Dragon
	hex_map.set_tile(Vector2i(95, 3), HexTileMap.TILE_OBJECT)    # Walk Away
	hex_map.set_tile(Vector2i(105, 0), HexTileMap.TILE_OBJECT)   # Hidden Door (revealed later)
	
	# === CANO PROTOCOL (hidden, object tile) ===
	hex_map.set_tile(Vector2i(80, -30), HexTileMap.TILE_OBJECT)   # The Compiler
	
	# === SAVE POINTS ===
	hex_map.set_tile(Vector2i(-75, 5), HexTileMap.TILE_OBJECT)    # Save at Moment 1
	hex_map.set_tile(Vector2i(-15, 10), HexTileMap.TILE_OBJECT)   # Save at Hoard
	hex_map.set_tile(Vector2i(55, 5), HexTileMap.TILE_OBJECT)    # Save at Approach
	
	# === PORTALS ===
	hex_map.set_tile(Vector2i(-90, 0), HexTileMap.TILE_PORTAL)    # Return to Floor 9
	hex_map.set_tile(Vector2i(110, 0), HexTileMap.TILE_PORTAL)    # Ending portal
	
	# === THRONE CENTERPIECE ===
	for offset in [Vector2i(100, 0), Vector2i(99, 0), Vector2i(101, 0), Vector2i(100, -1), Vector2i(100, 1)]:
		hex_map.set_tile(offset, HexTileMap.TILE_OBJECT)
	
	print("[Floor10-Hex] Layout complete: 11 Moments + Cano Protocol")

func _generate_room_hex(room_id: String, center: Vector2i, radius: int, portal_positions: Array[Vector2i]):
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
			else:
				if hex_map.get_tile(hex) == HexTileMap.TILE_VOID:
					hex_map.set_tile(hex, HexTileMap.TILE_WALL)

func _generate_corridor_hex(start: Vector2i, end: Vector2i, width: int):
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
		shadow.polygon = PackedVector2Array([Vector2(-15, 25), Vector2(15, 25), Vector2(10, 35), Vector2(-10, 35)])
		shadow.color = Color(0, 0, 0, 0.3)
		player_node.add_child(shadow)
		add_child(player_node)
	else:
		if player_node.get_parent():
			player_node.get_parent().remove_child(player_node)
		add_child(player_node)
	
	var start_room = room_data.get("f10_moment_01")
	if start_room:
		player_node.global_position = hex_map.hex_to_world(start_room["center"] + Vector2i(5, 0))
	
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.global_position = player_node.global_position

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		combat_manager.turn_started.connect(_on_combat_turn_started)
		print("[Floor10-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		return
	var enemies = RoomEnemyDatabase.get_floor_composition(10, encounter_type)
	if enemies.is_empty():
		return
	in_combat = true
	AudioManager.play_combat(10)
	var combat_data = []
	for enemy in enemies:
		combat_data.append(enemy.to_combat_data())
	combat_manager.start_combat(combat_data, GameState.player_deck)
	if combat_manager.has_signal("combat_ended") and not combat_manager.combat_ended.is_connected(_on_combat_ended):
		combat_manager.combat_ended.connect(_on_combat_ended)
	if combat_manager.has_signal("turn_started") and not combat_manager.turn_started.is_connected(_on_combat_turn_started):
		combat_manager.turn_started.connect(_on_combat_turn_started)
	var ui = get_node_or_null("CombatUI")
	if ui:
		ui.setup(combat_manager)
		ui.visible = true
		if ui.has_signal("combat_ended") and not ui.combat_ended.is_connected(_on_combat_ended):
			ui.combat_ended.connect(_on_combat_ended)
	print("[Floor10-Hex] Combat started: %s" % encounter_type)

func _on_combat_ended(victory: bool):
	in_combat = false
	AudioManager.play_floor_ambient(10)
	var ui = get_node_or_null("CombatUI")
	if ui:
		ui.visible = false
	if victory:
		room_cleared[current_room_id] = true
		if current_room_id == "f10_moment_10":
			_show_notification("🐉 The Dragon is defeated! Proceed to the Throne.", Color(0.9, 0.9, 0.3), 3.0)
			# Unlock Throne
		elif current_room_id == "f10_moment_06":
			aspects_defeated.append("time")
			_show_notification("⏳ Aspect of Time defeated!", Color(0.3, 0.9, 0.3), 3.0)
		elif current_room_id == "f10_moment_07":
			aspects_defeated.append("greed")
			_show_notification("💰 Aspect of Greed defeated!", Color(0.3, 0.9, 0.3), 3.0)
		elif current_room_id == "f10_moment_08":
			aspects_defeated.append("transformation")
			_show_notification("🔄 Aspect of Transformation defeated!", Color(0.3, 0.9, 0.3), 3.0)
		elif current_room_id == "f10_cano":
			_show_notification("🔚 THE CANO PROTOCOL IS DEFEATED. TRUE ENDING.", Color(0.9, 0.9, 0.9), 3.0)
			_ending_true()
			return
		
		# Reset surviving enemies to UNAWARE, clean up dead
		for enemy in hex_enemies:
			if enemy.hp <= 0:
				enemy.queue_free()
			else:
				enemy._set_state(HexEnemy.State.UNAWARE)
				enemy.patrol_center = enemy.hex_pos
				enemy.alert_timer = 0.0
				enemy.patrol_timer = 0.0
		hex_enemies = hex_enemies.filter(func(e): return e.hp > 0)
		
		# If all aspects defeated, unlock approach
		if aspects_defeated.size() >= 3 and current_room_id in ["f10_moment_06", "f10_moment_07", "f10_moment_08"]:
			_show_notification("All Aspects defeated! The Dragon awaits.", Color(0.9, 0.9, 0.3), 3.0)
	
	print("[Floor10-Hex] Combat ended. Victory: %s" % victory)

func _on_combat_turn_started(turn_number: int):
	# Dragon phase logic
	if current_room_id == "f10_moment_10" and dragon_phase == 1:
		if turn_number >= 1:
			# Player took a turn = they attacked
			player_attacked_in_phase_1 = true
			crack_revealed = true
			_show_notification("💥 You attacked! A crack appears in the wall...", Color(0.9, 0.3, 0.3), 3.0)
			_show_notification("🔓 Hidden door revealed! (Cano Protocol accessible)", Color(0.3, 0.9, 0.3), 3.0)
			dragon_phase = 2
			_update_dragon_display()
	
	# Cano Protocol phase logic
	if current_room_id == "f10_cano":
		_cano_protocol_turn(turn_number)
	
	_update_moment_display()
	_update_aspect_display()
	_update_dragon_display()
	_update_cano_display()

# ===================================================================
# ENEMIES (Aspects, Dragon, Cano Protocol)
# ===================================================================

func _setup_enemies():
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.z_index = 90
	add_child(enemy_container)
	
	var spawn_configs = {
		"f10_moment_06": [
			{"name": "Aspect of Time", "hex": Vector2i(0, 0), "faction": "Dragon", "hp": 40, "atk": 4, "boss": false, "stationary": true, "view_range": 8, "combat_range": 2},
		],
		"f10_moment_07": [
			{"name": "Aspect of Greed", "hex": Vector2i(20, 0), "faction": "Dragon", "hp": 45, "atk": 5, "boss": false, "stationary": true, "view_range": 8, "combat_range": 2},
		],
		"f10_moment_08": [
			{"name": "Aspect of Transformation", "hex": Vector2i(40, 0), "faction": "Dragon", "hp": 40, "atk": 4, "boss": false, "stationary": true, "view_range": 8, "combat_range": 2},
		],
		"f10_moment_10": [
			{"name": "The Dragon", "hex": Vector2i(80, 0), "faction": "Boss", "hp": 50, "atk": 6, "boss": true, "stationary": true, "view_range": 12, "combat_range": 2},
		],
		"f10_cano": [
			{"name": "The Cano Protocol", "hex": Vector2i(80, -30), "faction": "Boss", "hp": 50, "atk": 5, "boss": true, "stationary": true, "view_range": 10, "combat_range": 2},
		],
	}
	
	for room_id in spawn_configs.keys():
		for spawn_data in spawn_configs[room_id]:
			var is_boss = spawn_data.get("boss", false)
			var enemy = HexEnemy.new(
				"%s_%d" % [room_id, hex_enemies.size()],
				spawn_data["name"],
				spawn_data["hex"],
				spawn_data["faction"],
				is_boss
			)
			enemy.hp = spawn_data.get("hp", 10)
			enemy.max_hp = spawn_data.get("hp", 10)
			enemy.attack = spawn_data.get("atk", 3)
			if spawn_data.get("stationary", false):
				enemy.patrol_radius = 0
			if spawn_data.has("view_range"):
				enemy.view_range = spawn_data["view_range"]
			if spawn_data.has("combat_range"):
				enemy.combat_range = spawn_data["combat_range"]
			_add_enemy(enemy, spawn_data["hex"])
	
	print("[Floor10-Hex] %d hex enemies spawned (Aspects + Dragon + Cano)" % hex_enemies.size())

func _add_enemy(enemy: HexEnemy, hex: Vector2i):
	enemy.name = "HexEnemy_%d" % hex_enemies.size()
	enemy_container.add_child(enemy)
	enemy.set_hex_map_position(hex, hex_map)
	enemy.combat_initiated.connect(_on_enemy_combat_initiated)
	hex_enemies.append(enemy)

func _on_enemy_combat_initiated(ambush: bool, enemy_id: String = ""):
	ambush_bonus = ambush
	var nearby_enemies = []
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		var dist = HexTileMap._hex_distance(player_hex, enemy.hex_pos)
		if dist <= 2:
			nearby_enemies.append(enemy)
	if nearby_enemies.is_empty():
		return
	var combat_enemies = []
	for enemy in nearby_enemies:
		combat_enemies.append(enemy.to_combat_data())
		enemy._set_state(HexEnemy.State.IN_COMBAT)
	if combat_enemies.is_empty():
		return
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		in_combat = true
		AudioManager.play_combat(10)
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		if ambush_bonus:
			_show_notification("🎯 AMBUSH! Player goes first!", Color(0.3, 0.9, 0.3), 3.0)
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
	print("[Floor10-Hex] Combat initiated (ambush: %s)" % ambush)

func _check_enemy_sight():
	if not player_node:
		return
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		var dist = HexTileMap._hex_distance(player_hex, enemy.hex_pos)
		if dist <= enemy.view_range:
			if enemy.state == HexEnemy.State.UNAWARE:
				enemy._set_state(HexEnemy.State.ALERT)
				enemy.alert_timer = 0.0
				_show_notification("👁 %s spotted you!" % enemy.enemy_name, Color(0.9, 0.3, 0.3), 3.0)
			elif enemy.state == HexEnemy.State.AWARE and dist <= enemy.combat_range:
				enemy._set_state(HexEnemy.State.IN_COMBAT)
				_on_enemy_combat_initiated(false, enemy.enemy_id)
				return
		else:
			if enemy.state == HexEnemy.State.ALERT and enemy.alert_timer < enemy.alert_duration:
				pass
			elif enemy.state == HexEnemy.State.ALERT:
				enemy._set_state(HexEnemy.State.UNAWARE)
				enemy.alert_timer = 0.0

func _try_ambush_at_hex(target_hex: Vector2i) -> bool:
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		var dist = HexTileMap._hex_distance(target_hex, enemy.hex_pos)
		if dist <= 1:
			if enemy.try_ambush(target_hex):
				return true
	return false

# ===================================================================
# FLOOR 10 — GHOST DIALOGUE
# ===================================================================

func _interact_ghost(moment_id: String, ghost_boss: String):
	if ghosts_spoken.get(moment_id, false):
		_show_dialogue(ghost_boss, "The ghost fades... Nothing more to say.")
		return
	
	ghosts_spoken[moment_id] = true
	
	match ghost_boss:
		"The Door":
			_show_dialogue("The Door", "You knocked. I opened. That was the first choice you made. All others followed.")
		"Spore Heart":
			_show_dialogue("Spore Heart", "You killed growth. I am what grows back. Stronger. Stranger.")
		"Gear Mother":
			_show_dialogue("Gear Mother", "Perfectionist. The tower was built by perfectionists. Look at us now.")
	
	_show_notification("👻 Ghost of %s has spoken." % ghost_boss, Color(0.7, 0.7, 0.9), 3.0)

# ===================================================================
# FLOOR 10 — HOARD
# ===================================================================

func _interact_hoard_object(object_id: String):
	if hoard_objects_touched.get(object_id, false):
		# Already touched, offer to alter
		if object_id == "blood_contract":
			_show_dialogue("Blood Contract", "Burn it? Cost: 10 HP. Effect: Remove all pact effects.")
		elif object_id == "soul_gem":
			_show_dialogue("Soul Gem", "Shatter it? Cost: Dragon +5 HP. Effect: Free all enslaved souls.")
		elif object_id == "reforged_blade":
			_show_dialogue("Reforged Blade", "Melt it? Cost: Lose buff. Effect: Keep all cards.")
		elif object_id == "graduate_scroll":
			_show_dialogue("Graduate Scroll", "Rewrite it? Cost: Affects Floor 7. Effect: Change your grade.")
		return
	
	hoard_objects_touched[object_id] = true
	
	match object_id:
		"blood_contract":
			var pacts = GameState.get_value("pacts_signed", 0)
			if pacts > 0:
				_show_dialogue("Blood Contract", "You signed %d pact(s). The ink is still wet. You can burn it." % pacts)
			else:
				_show_dialogue("Blood Contract", "No contracts. The page is blank. You walked clean through Floor 7.")
		"soul_gem":
			var freed = GameState.get_value("souls_freed", 0)
			var enslaved = GameState.get_value("souls_enslaved", 0)
			if enslaved > 0:
				_show_dialogue("Soul Gem", "%d souls trapped inside. They scream when you touch it." % enslaved)
			elif freed > 0:
				_show_dialogue("Soul Gem", "%d souls freed. The gem is warm. Grateful." % freed)
			else:
				_show_dialogue("Soul Gem", "Empty. You never touched the furnaces.")
		"reforged_blade":
			var reforged = GameState.get_value("reforging_accepted", false)
			if reforged:
				_show_dialogue("Reforged Blade", "You accepted the reforging. The blade is part of you now. Melt it?")
			else:
				_show_dialogue("Reforged Blade", "You refused. The blade is plain steel. You held yourself together.")
		"graduate_scroll":
			var grade = GameState.get_value("floor6_grade", "F")
			_show_dialogue("Graduate Scroll", "Your grade: %s. The Dean's seal is still wet." % grade)
	
	_update_hoard_display()

func _alter_hoard_object(object_id: String):
	match object_id:
		"blood_contract":
			# Burn contract: 10 HP cost, remove pact effects
			_show_notification("🔥 Blood Contract BURNED! -10 HP, all pacts removed.", Color(0.9, 0.3, 0.3), 3.0)
			# TODO: Apply HP damage, remove pact effects
		"soul_gem":
			# Shatter gem: Dragon +5 HP, free enslaved souls
			_show_notification("💎 Soul Gem SHATTERED! Dragon gains 5 HP, souls freed.", Color(0.9, 0.9, 0.3), 3.0)
			dragon_max_hp += 5
			dragon_hp += 5
		"reforged_blade":
			# Melt blade: lose buff, keep cards
			_show_notification("🔥 Reforged Blade MELTED! Buff lost, cards kept.", Color(0.9, 0.7, 0.3), 3.0)
		"graduate_scroll":
			# Rewrite scroll: change grade
			_show_notification("📝 Graduate Scroll REWRITTEN! Grade changed.", Color(0.3, 0.9, 0.3), 3.0)
	
	hoard_objects_altered[object_id] = true
	_update_hoard_display()

# ===================================================================
# FLOOR 10 — WEIGHT CALCULATION
# ===================================================================

func _calculate_player_weight():
	player_weight = 0
	
	# Heavy choices (positive weight)
	var pacts = GameState.get_value("pacts_signed", 0)
	if pacts >= 2:
		player_weight += 3
	var enslaved = GameState.get_value("souls_enslaved", 0)
	if enslaved >= 3:
		player_weight += 4
	var soul_debt = GameState.get_value("soul_debt", 0)
	if soul_debt >= 3:
		player_weight += 3
	var companions = GameState.get_value("companions_built", 0)
	if companions >= 5:
		player_weight += 1
	if GameState.get_value("void_bond_active", false):
		player_weight += 2
	if GameState.get_value("marked_debuff", false):
		player_weight += 2
	
	# Light choices (negative weight)
	if GameState.get_value("liberator_status", false):
		player_weight -= 5
	if GameState.get_value("all_pacts_refused", false):
		player_weight -= 3
	if GameState.get_value("all_furnaces_destroyed", false):
		player_weight -= 2
	if soul_debt == 0:
		player_weight -= 2
	if GameState.get_value("graduate_status", false):
		player_weight -= 1
	
	print("[Floor10-Hex] Player weight calculated: %d" % player_weight)

func _interact_weight_scales():
	if hoard_weight_revealed:
		_show_dialogue("The Scales", "Your weight is %d. Heavy = %d, Light = %d." % [player_weight, max(0, player_weight), max(0, -player_weight)])
		return
	
	hoard_weight_revealed = true
	
	var heavy = max(0, player_weight)
	var light = max(0, -player_weight)
	var msg = "THE WEIGHT OF YOUR CHOICES:\n\n"
	msg += "Heavy (corruption): %d\n" % heavy
	msg += "Light (purity): %d\n\n" % light
	
	if player_weight > 0:
		msg += "The Dragon sees kin. It will fight with sorrow, not fury.\n"
		msg += "Dragon HP: 35 (weakened)"
		dragon_max_hp = 35
		dragon_hp = 35
	else:
		msg += "The Dragon sees a threat. It will fight with everything.\n"
		msg += "Dragon HP: 70 (empowered)"
		dragon_max_hp = 70
		dragon_hp = 70
	
	_show_dialogue("The Scales", msg)
	_update_weight_display()

# ===================================================================
# FLOOR 10 — DRAGON PHASES
# ===================================================================

func _check_dragon_phase():
	if dragon_phase >= 3:
		return
	var hp_percent = float(dragon_hp) / dragon_max_hp
	if dragon_phase == 1 and hp_percent <= 0.5:
		dragon_phase = 2
		if player_attacked_in_phase_1:
			_show_notification("🐉 PHASE 2: The Dragon fights with FURY! (You attacked in Phase 1)", Color(0.9, 0.3, 0.3), 3.0)
		else:
			_show_notification("🐉 PHASE 2: The Dragon tests your patience. (You waited)", Color(0.3, 0.9, 0.3), 3.0)
	elif dragon_phase == 2 and hp_percent <= 0.25:
		dragon_phase = 3
		_show_notification("🐉 PHASE 3: The Dragon offers a FINAL CHOICE.", Color(0.9, 0.9, 0.3), 3.0)
		_show_dragon_final_choice()

func _show_dragon_final_choice():
	_show_dialogue("The Dragon", "I am defeated. But I am not gone. Choose:\n\n1. Destroy me. End the cycle.\n2. Become me. Ascend the throne.\n3. Walk away. (Only if you are pure)\n4. ...or is there another way?")

func _interact_dragon():
	match dragon_phase:
		1:
			_show_dialogue("The Dragon", "You have come far. Will you attack? Or listen?")
			# Phase 1: dragon doesn't attack, just speaks
			# If player attacks, it triggers combat and reveals crack
			_show_notification("The Dragon awaits your move. Attack or listen?", Color(0.9, 0.9, 0.3), 3.0)
		2:
			_show_dialogue("The Dragon", "The test is underway. You cannot turn back.")
		3:
			_show_dragon_final_choice()

func _interact_dragon_attack():
	if dragon_phase == 1:
		player_attacked_in_phase_1 = true
		crack_revealed = true
		_show_notification("💥 You attacked! The Dragon reveals its true form!", Color(0.9, 0.3, 0.3), 3.0)
		_show_notification("🔓 A crack appears in the wall... a hidden door.", Color(0.3, 0.9, 0.3), 3.0)
		dragon_phase = 2
		# Start combat with Dragon
		for enemy in hex_enemies:
			if enemy.enemy_name == "The Dragon":
				enemy._set_state(HexEnemy.State.IN_COMBAT)
				_on_enemy_combat_initiated(false, enemy.enemy_id)
				return

# ===================================================================
# FLOOR 10 — ENDINGS
# ===================================================================

func _ending_destroy_dragon():
	ending_chosen = "destroy"
	_show_notification("⚔️ ENDING: End the Cycle. NG+ unlocked. Knowledge only.", Color(0.9, 0.9, 0.3), 3.0)
	GameState.set_value("ending", "destroy")
	GameState.set_value("ng_plus_unlocked", true)
	_show_ending_screen("END THE CYCLE", "The Dragon dies. The tower collapses. A new tower appears on the horizon.")

func _ending_become_dragon():
	ending_chosen = "become"
	_show_notification("👑 ENDING: Become the Dragon. NG+ unlocked. Previous deck becomes Dragon.", Color(0.9, 0.3, 0.9), 3.0)
	GameState.set_value("ending", "become")
	GameState.set_value("ng_plus_unlocked", true)
	GameState.set_value("true_ending_locked", true)
	_show_ending_screen("BECOME THE DRAGON", "You ascend the throne. You become the new source of power. The cycle continues.")

func _ending_walk_away():
	var liberator = GameState.get_value("liberator_status", false)
	var pacts = GameState.get_value("pacts_signed", 0)
	var reforged = GameState.get_value("reforging_accepted", false)
	
	if not liberator or pacts > 0 or reforged:
		_show_notification("❌ Cannot walk away. You are not pure enough.", Color(0.9, 0.3, 0.3), 3.0)
		return
	
	ending_chosen = "walk"
	_show_notification("🚶 ENDING: Walk Away. Exile Mode unlocked.", Color(0.3, 0.9, 0.3), 3.0)
	GameState.set_value("ending", "walk")
	GameState.set_value("exile_mode_unlocked", true)
	_show_ending_screen("WALK AWAY", "You leave through the hidden door. The tower fades behind you. You are free.")

func _ending_true():
	ending_chosen = "true"
	_show_notification("🔚 TRUE ENDING: The Cano Protocol Defeated.", Color(0.9, 0.9, 0.9), 3.0)
	GameState.set_value("ending", "true")
	GameState.set_value("cano_protocol_defeated", true)
	_show_ending_screen("THE CANO PROTOCOL DEFEATED", "The tower was never a place. It was a question. You answered.")

func _show_ending_screen(title: String, text: String):
	_show_dialogue("ENDING", "%s\n\n%s" % [title, text])
	# Show portal to title screen
	_show_notification("Portal to Title Screen active. Press S to exit.", Color(0.9, 0.9, 0.3), 3.0)

# ===================================================================
# FLOOR 10 — CANO PROTOCOL
# ===================================================================

func _interact_cano_protocol():
	if not crack_revealed:
		_show_dialogue("The Wall", "Just a crack. Nothing special.")
		return
	
	_show_dialogue("The Cano Protocol", "You have found the hidden door. The true final boss awaits. This is not a dragon. This is the system that built the dragon.")
	_show_notification("🔓 Cano Protocol accessible! Enter the hidden door?", Color(0.9, 0.1, 0.9), 3.0)

func _cano_protocol_turn(turn_number: int):
	# Cano Protocol abilities cycle: MemoryLeak, StackOverflow, GarbageCollection
	var abilities = ["MEMORY_LEAK", "STACK_OVERFLOW", "GARBAGE_COLLECTION"]
	var ability = abilities[cano_ability_index % 3]
	
	match ability:
		"MEMORY_LEAK":
			_show_notification("☠️ MEMORY_LEAK: Your Quiddity becomes damage!", Color(0.9, 0.1, 0.1), 3.0)
		"STACK_OVERFLOW":
			_show_notification("☠️ STACK_OVERFLOW: Spawn process interrupt!", Color(0.9, 0.1, 0.1), 3.0)
		"GARBAGE_COLLECTION":
			_show_notification("☠️ GARBAGE_COLLECTION: Remove highest cost card!", Color(0.9, 0.1, 0.1), 3.0)
	
	cano_ability_index += 1
	
	if cano_hp <= 0:
		_show_notification("🔚 CONFIRM: END PROCESS?", Color(0.9, 0.9, 0.9), 3.0)
		_show_notification("YES = True Ending. NO = Reinitialize.", Color(0.9, 0.9, 0.9), 3.0)

func _interact_cano_choice(yes: bool):
	if yes:
		_show_notification("🔚 PROCESS ENDED. TRUE ENDING.", Color(0.9, 0.9, 0.9), 3.0)
		_ending_true()
	else:
		_show_notification("🔄 REINITIALIZING...", Color(0.9, 0.9, 0.3), 3.0)
		# Continue game

# ===================================================================
# CROSS-FLOOR DIALOGUE
# ===================================================================

func _dragon_cross_floor_dialogue():
	var messages = []
	
	# Floor 9
	if GameState.get_value("liberator_status", false):
		messages.append("You freed them all. Every soul. Every prisoner.")
	if GameState.get_value("soul_debt", 0) > 3:
		messages.append("You used them. You are the Foreman's heir.")
	if GameState.get_value("companions_built", 0) >= 5:
		messages.append("You build. I destroy. We are not so different.")
	
	# Floor 8
	if GameState.get_value("reforging_accepted", false):
		messages.append("You are already part of the tower's design.")
	if GameState.get_value("reforging_accepted", false) == false and GameState.get_value("floor8_completed", false):
		messages.append("You held yourself together. That is rare.")
	
	# Floor 7
	if GameState.get_value("signed_final_pact", false):
		messages.append("You are already mine. This is a formality.")
	if GameState.get_value("broke_all_pacts", false):
		messages.append("You cannot be bound. That makes you dangerous.")
	if GameState.get_value("void_bond_active", false):
		messages.append("You carry my cousin's mark.")
	
	# Floor 6
	if GameState.get_value("graduate_status", false):
		messages.append("Educated. But education is just another cage with prettier bars.")
	if GameState.get_value("dropout_status", false):
		messages.append("You could not finish. Neither could I. We are alike.")
	
	# Floor 5
	if GameState.get_value("elemental_core_defeated", false):
		messages.append("You killed the storm. I am what remains when storms die.")
	if GameState.get_value("goblin_janitor_befriended", false):
		messages.append("Your little friend told me you were coming.")
	
	# Floor 2
	if GameState.get_value("flesh_garden_killed", false):
		messages.append("You ended growth. I am what grows back.")
	
	# Floor 1
	if GameState.get_value("shortcut_maker_befriended", false):
		messages.append("Last chance to take the back door. I keep my promises.")
	
	if messages.is_empty():
		messages.append("You are... unremarkable. That is the most dangerous thing of all.")
	
	# Show one random message
	var msg = messages[randi() % messages.size()]
	_show_dialogue("The Dragon", msg)

# ===================================================================
# UI
# ===================================================================

func _setup_ui():
	var main_ui = get_node_or_null("MainUI")
	if not main_ui:
		main_ui = CanvasLayer.new()
		main_ui.name = "MainUI"
		add_child(main_ui)
	
	room_indicator = Label.new()
	room_indicator.name = "RoomIndicator"
	room_indicator.position = Vector2(20, 60)
	room_indicator.size = Vector2(400, 30)
	room_indicator.add_theme_font_size_override("font_size", 14)
	main_ui.add_child(room_indicator)
	
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(640, 650)
	interact_prompt.size = Vector2(400, 30)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.add_theme_font_size_override("font_size", 14)
	interact_prompt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	interact_prompt.visible = false
	main_ui.add_child(interact_prompt)
	
	moment_ui = Label.new()
	moment_ui.name = "MomentUI"
	moment_ui.position = Vector2(20, 100)
	moment_ui.size = Vector2(300, 60)
	moment_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(moment_ui)
	
	hoard_ui = Label.new()
	hoard_ui.name = "HoardUI"
	hoard_ui.position = Vector2(20, 170)
	hoard_ui.size = Vector2(300, 80)
	hoard_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(hoard_ui)
	
	weight_ui = Label.new()
	weight_ui.name = "WeightUI"
	weight_ui.position = Vector2(20, 260)
	weight_ui.size = Vector2(300, 60)
	weight_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(weight_ui)
	
	aspect_ui = Label.new()
	aspect_ui.name = "AspectUI"
	aspect_ui.position = Vector2(20, 330)
	aspect_ui.size = Vector2(300, 60)
	aspect_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(aspect_ui)
	
	dragon_ui = Label.new()
	dragon_ui.name = "DragonUI"
	dragon_ui.position = Vector2(20, 400)
	dragon_ui.size = Vector2(300, 60)
	dragon_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(dragon_ui)
	
	cano_ui = Label.new()
	cano_ui.name = "CanoUI"
	cano_ui.position = Vector2(20, 470)
	cano_ui.size = Vector2(300, 60)
	cano_ui.add_theme_font_size_override("font_size", 12)
	cano_ui.visible = false
	main_ui.add_child(cano_ui)
	
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	add_child(pause_menu)
	var pause_bg = ColorRect.new()
	pause_bg.color = Color(0, 0, 0, 0.7)
	pause_bg.size = Vector2(1280, 720)
	pause_menu.add_child(pause_bg)
	var pause_text = Label.new()
	pause_text.text = "PAUSED\n\n[ESC] Resume\n[S] Save\n[Q] Quit"
	pause_text.position = Vector2(540, 300)
	pause_text.add_theme_font_size_override("font_size", 20)
	pause_menu.add_child(pause_text)
	
	_update_moment_display()
	_update_hoard_display()
	_update_weight_display()
	_update_aspect_display()
	_update_dragon_display()

func _update_moment_display():
	if not moment_ui:
		return
	var text = "📜 MOMENT %d/%d\n%s" % [current_moment, total_moments, room_data.get(current_room_id, {}).get("display", "")]
	moment_ui.text = text

func _update_hoard_display():
	if not hoard_ui:
		return
	var text = "💎 HOARD:\n"
	for obj in ["blood_contract", "soul_gem", "reforged_blade", "graduate_scroll"]:
		var touched = "✓" if hoard_objects_touched.get(obj, false) else "○"
		var altered = " (altered)" if hoard_objects_altered.get(obj, false) else ""
		text += "%s %s%s\n" % [touched, obj.replace("_", " ").capitalize(), altered]
	hoard_ui.text = text

func _update_weight_display():
	if not weight_ui:
		return
	var text = "⚖️ WEIGHT: %d\n" % player_weight
	if player_weight > 0:
		text += "(Heavy — Dragon is kin)"
	elif player_weight < 0:
		text += "(Light — Dragon is threatened)"
	else:
		text += "(Balanced — Dragon is curious)"
	weight_ui.text = text

func _update_aspect_display():
	if not aspect_ui:
		return
	var text = "🐲 ASPECTS:\n"
	for aspect in ["time", "greed", "transformation"]:
		var status = "✅" if aspect in aspects_defeated else "○"
		text += "%s %s\n" % [status, aspect.capitalize()]
	aspect_ui.text = text

func _update_dragon_display():
	if not dragon_ui:
		return
	var text = "🐉 DRAGON: %d/%d HP\n" % [dragon_hp, dragon_max_hp]
	text += "Phase %d" % dragon_phase
	if player_attacked_in_phase_1:
		text += " (Crack revealed)"
	dragon_ui.text = text

func _update_cano_display():
	if not cano_ui:
		return
	var text = "🔚 CANO PROTOCOL: %d/%d\n" % [cano_hp, cano_archive_remaining]
	text += "Ability: %d | Phase %d" % [cano_ability_index, cano_phase]
	cano_ui.text = text

func _show_notification(msg: String, color: Color = Color(0.9, 0.9, 0.9), duration: float = 2.0):
	var label = Label.new()
	label.text = msg
	label.position = Vector2(640, 100)
	label.size = Vector2(600, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	await get_tree().create_timer(duration).timeout
	label.queue_free()

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

func _show_dialogue(speaker: String, text: String):
	var dialogue_ui = get_node_or_null("DialogueUI")
	if dialogue_ui and dialogue_ui.has_method("show_dialogue"):
		dialogue_ui.show_dialogue(speaker, text)
	else:
		_show_notification("%s: %s" % [speaker, text], Color(0.9, 0.9, 0.9), 3.0)

# ===================================================================
# MOVEMENT
# ===================================================================

func _hex_move(move_vec: Vector2):
	if not player_node:
		return
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	var direction = _vector_to_hex_dir(move_vec)
	var dirs = HexTileMap.DIRECTIONS
	var target_hex = current_hex + dirs[direction]
	if hex_map.is_wall(target_hex):
		return
	if _try_ambush_at_hex(target_hex):
		return
	player_node.global_position = hex_map.hex_to_world(target_hex)
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	_check_room_transition(target_hex)
	_check_interactables()
	_check_enemy_sight()

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

func _on_click_move(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if enemy.hex_pos == target_hex:
			if enemy.try_ambush(hex_map.world_to_hex(player_node.global_position)):
				return
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	var path = hex_map.find_path(current_hex, target_hex)
	if path.size() > 1:
		path_movement_target = path.slice(1)
		path_movement_index = 0
		path_movement_active = true

func _on_click_interact(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	if HexTileMap._hex_distance(target_hex, player_hex) > 1:
		return
	if _try_ambush_at_hex(target_hex):
		return
	_interact_at_hex(target_hex)

# ===================================================================
# ROOM TRANSITIONS
# ===================================================================

func _enter_room(room_id: String):
	current_room_id = room_id
	var data = room_data.get(room_id, {})
	var display = data.get("display", "Unknown")
	room_changed.emit(room_id, display)
	print("[Floor10-Hex] Entered: %s" % display)
	if room_indicator:
		room_indicator.text = "📍 %s" % display
		var color = Color(0.7, 0.7, 0.7)
		match room_id:
			"f10_moment_01": color = Color(0.6, 0.6, 0.7)
			"f10_moment_02": color = Color(0.6, 0.6, 0.7)
			"f10_moment_03": color = Color(0.6, 0.6, 0.7)
			"f10_moment_04": color = Color(0.9, 0.9, 0.3)
			"f10_moment_05": color = Color(0.9, 0.9, 0.9)
			"f10_moment_06": color = Color(0.3, 0.7, 0.9)
			"f10_moment_07": color = Color(0.9, 0.7, 0.3)
			"f10_moment_08": color = Color(0.7, 0.3, 0.9)
			"f10_moment_09": color = Color(0.9, 0.3, 0.3)
			"f10_moment_10": color = Color(0.9, 0.1, 0.1)
			"f10_moment_11": color = Color(0.9, 0.9, 0.9)
			"f10_cano":      color = Color(0.1, 0.1, 0.1)
		room_indicator.add_theme_color_override("font_color", color)
	
	# Update current moment
	match room_id:
		"f10_moment_01": current_moment = 1
		"f10_moment_02": current_moment = 2
		"f10_moment_03": current_moment = 3
		"f10_moment_04": current_moment = 4
		"f10_moment_05": current_moment = 5
		"f10_moment_06": current_moment = 6
		"f10_moment_07": current_moment = 7
		"f10_moment_08": current_moment = 8
		"f10_moment_09": current_moment = 9
		"f10_moment_10": current_moment = 10
		"f10_moment_11": current_moment = 11
		"f10_cano":      current_moment = 10
	
	_update_moment_display()

func _check_room_transition(player_hex: Vector2i):
	var current_data = room_data.get(current_room_id)
	if not current_data:
		return
	var center = current_data["center"]
	var radius = current_data["radius"]
	var dist_from_center = HexTileMap._hex_distance(player_hex, center)
	if dist_from_center > radius + 2:
		for room_id in room_data.keys():
			if room_id == current_room_id:
				continue
			var data = room_data[room_id]
			var d = HexTileMap._hex_distance(player_hex, data["center"])
			if d <= data["radius"]:
				_enter_room(room_id)
				return
	var portal_dir = _get_portal_direction_from_hex(player_hex)
	if portal_dir:
		_try_portal_transition(portal_dir)

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
	
	# Special checks
	if target_room == "f10_moment_06" and not room_cleared.get("f10_moment_04", false):
		_show_notification("🔒 The Aspects are sealed. Visit the Hoard first.")
		return
	if target_room == "f10_moment_09" and aspects_defeated.size() < 3:
		_show_notification("🔒 The Dragon awaits. Defeat all 3 Aspects first.")
		return
	if target_room == "f10_moment_10" and dragon_phase < 2:
		_show_notification("🔒 The Dragon is not ready to fight yet.")
		return
	if target_room == "f10_cano" and not crack_revealed:
		_show_notification("🔒 Nothing behind this crack. Yet.")
		return
	if target_room == "f10_moment_11" and dragon_hp > 0:
		_show_notification("🔒 The Dragon still lives. You cannot ascend the throne.")
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
		"f10_moment_01": msg = "The Threshold. The journey begins."
		"f10_moment_02": msg = "The Witness. The past watches you."
		"f10_moment_03": msg = "The Memory. What you did cannot be undone."
		"f10_moment_04": msg = "The Hoard. Your choices, made tangible."
		"f10_moment_05": msg = "The Weight. How heavy are you?"
		"f10_moment_06": msg = "The Aspect of Time. Your past attacks."
		"f10_moment_07": msg = "The Aspect of Greed. Your hunger consumes."
		"f10_moment_08": msg = "The Aspect of Transformation. You must change."
		"f10_moment_09": msg = "The Approach. The Dragon is close."
		"f10_moment_10": msg = "The Revelation. The Dragon speaks."
		"f10_moment_11": msg = "The Throne. Choose."
		"f10_cano":      msg = "The Cano Protocol. The true final test."
	if msg != "":
		_show_notification(msg, Color(0.9, 0.9, 0.9), 2.5)
	_enter_room(target_room)
	in_transition = false

func _opposite_direction(dir_name: String) -> String:
	match dir_name:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		"up": return "down"
		"down": return "up"
		"exit": return "exit"
		_:
			return ""

# ===================================================================
# INTERACTABLES
# ===================================================================

func _check_interactables():
	if not player_node or not hex_map:
		return
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var tile = hex_map.get_tile(player_hex)
	if tile == HexTileMap.TILE_OBJECT:
		var obj_id = _get_object_id_at_hex(player_hex)
		match obj_id:
			"ghost_01":       _show_interact_prompt("[S] Speak to Ghost of The Door")
			"ghost_02":       _show_interact_prompt("[S] Speak to Ghost of Spore Heart")
			"ghost_03":       _show_interact_prompt("[S] Speak to Ghost of Gear Mother")
			"blood_contract": _show_interact_prompt("[S] Touch Blood Contract")
			"soul_gem":       _show_interact_prompt("[S] Touch Soul Gem")
			"reforged_blade": _show_interact_prompt("[S] Touch Reforged Blade")
			"graduate_scroll":_show_interact_prompt("[S] Touch Graduate Scroll")
			"weight_scales":  _show_interact_prompt("[S] Reveal Weight")
			"aspect_time":    _show_interact_prompt("[S] Face Aspect of Time")
			"aspect_greed":   _show_interact_prompt("[S] Face Aspect of Greed")
			"aspect_transformation": _show_interact_prompt("[S] Face Aspect of Transformation")
			"dragon":         _show_interact_prompt("[S] Face the Dragon")
			"destroy_dragon": _show_interact_prompt("[S] Destroy the Dragon")
			"become_dragon":  _show_interact_prompt("[S] Become the Dragon")
			"walk_away":      _show_interact_prompt("[S] Walk Away")
			"hidden_door":    _show_interact_prompt("[S] Enter Hidden Door")
			"cano_protocol":  _show_interact_prompt("[S] Face the Cano Protocol")
			"save_point":     _show_interact_prompt("[S] Save Game")
			_:
				_hide_interact_prompt()
	elif tile == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir == "exit":
			if current_room_id == "f10_moment_01":
				_show_interact_prompt("[S] Return to Floor 9")
			elif current_room_id == "f10_moment_11":
				_show_interact_prompt("[S] Exit to Title Screen")
			else:
				_hide_interact_prompt()
		else:
			_hide_interact_prompt()
	else:
		_hide_interact_prompt()

func _get_object_id_at_hex(hex: Vector2i) -> String:
	var object_map = {
		Vector2i(-80, 0):   "ghost_01",
		Vector2i(-60, 0):   "ghost_02",
		Vector2i(-40, 0):   "ghost_03",
		Vector2i(-25, -5):  "blood_contract",
		Vector2i(-15, -5):  "soul_gem",
		Vector2i(-25, 5):   "reforged_blade",
		Vector2i(-15, 5):   "graduate_scroll",
		Vector2i(-20, -25): "weight_scales",
		Vector2i(0, 0):     "aspect_time",
		Vector2i(20, 0):    "aspect_greed",
		Vector2i(40, 0):    "aspect_transformation",
		Vector2i(80, 0):    "dragon",
		Vector2i(95, -3):   "destroy_dragon",
		Vector2i(100, 0):   "become_dragon",
		Vector2i(95, 3):    "walk_away",
		Vector2i(105, 0):   "hidden_door",
		Vector2i(80, -30):  "cano_protocol",
		Vector2i(-75, 5):   "save_point",
		Vector2i(-15, 10):  "save_point",
		Vector2i(55, 5):    "save_point",
	}
	return object_map.get(hex, "")

func _interact_at_hex(hex: Vector2i):
	var obj_id = _get_object_id_at_hex(hex)
	match obj_id:
		"ghost_01":       _interact_ghost("f10_moment_01", "The Door")
		"ghost_02":       _interact_ghost("f10_moment_02", "Spore Heart")
		"ghost_03":       _interact_ghost("f10_moment_03", "Gear Mother")
		"blood_contract": _interact_hoard_object("blood_contract")
		"soul_gem":       _interact_hoard_object("soul_gem")
		"reforged_blade": _interact_hoard_object("reforged_blade")
		"graduate_scroll":_interact_hoard_object("graduate_scroll")
		"weight_scales":  _interact_weight_scales()
		"aspect_time":    _interact_aspect("time")
		"aspect_greed":   _interact_aspect("greed")
		"aspect_transformation": _interact_aspect("transformation")
		"dragon":         _interact_dragon()
		"destroy_dragon": _ending_destroy_dragon()
		"become_dragon":  _ending_become_dragon()
		"walk_away":      _ending_walk_away()
		"hidden_door":    _interact_cano_protocol()
		"cano_protocol":  _interact_cano_protocol()
		"save_point":     if GameState.has_method("save_game"): GameState.save_game(); _show_notification("Progress saved.")
	
	if hex_map.get_tile(hex) == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(hex)
		if portal_dir == "exit":
			if current_room_id == "f10_moment_01":
				get_tree().change_scene_to_file("res://scenes/Floor9.tscn")
			elif current_room_id == "f10_moment_11":
				get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")

func _interact_aspect(aspect_name: String):
	if aspect_name in aspects_defeated:
		_show_notification("Aspect already defeated.")
		return
	aspect_current = aspect_name
	# Trigger combat with the aspect
	for enemy in hex_enemies:
		if enemy.enemy_name == "Aspect of %s" % aspect_name.capitalize():
			enemy._set_state(HexEnemy.State.IN_COMBAT)
			_on_enemy_combat_initiated(false, enemy.enemy_id)
			return

# ===================================================================
# FLOOR SPECIFIC SETUP
# ===================================================================

func _setup_floor_specific():
	_calculate_player_weight()
	print("[Floor10-Hex] Setup complete. Weight: %d | Dragon HP: %d" % [player_weight, dragon_max_hp])

# ===================================================================
# INPUT
# ===================================================================

func _input(event: InputEvent):
	if is_paused:
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					is_paused = false
					pause_menu.visible = false
				KEY_S:
					if GameState.has_method("save_game"):
						GameState.save_game()
					_show_notification("Game saved.")
				KEY_Q:
					get_tree().quit()
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				is_paused = !is_paused
				pause_menu.visible = is_paused
				return
			KEY_S:
				if not in_combat and not in_ui and not in_transition:
					_interact_at_hex(hex_map.world_to_hex(player_node.global_position))
					return
			KEY_W, KEY_UP:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(0, -1))
					return
			KEY_S, KEY_DOWN:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(0, 1))
					return
			KEY_A, KEY_LEFT:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(-1, 0))
					return
			KEY_D, KEY_RIGHT:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(1, 0))
					return
			KEY_Z:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(-0.5, -0.866))
					return
			KEY_X:
				if not in_combat and not in_ui and not in_transition:
					_hex_move(Vector2(0.5, -0.866))
					return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not in_combat and not in_ui and not in_transition:
				_on_click_move(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not in_combat and not in_ui and not in_transition:
				_on_click_interact(event.position)

# ===================================================================
# PROCESS
# ===================================================================

func _process(_delta: float):
	if player_node:
		var camera = get_node_or_null("Camera2D")
		if camera:
			camera.global_position = player_node.global_position
	
	if path_movement_active and player_node and not in_combat and not in_transition:
		path_movement_timer += _delta
		if path_movement_timer >= PATH_MOVE_STEP_INTERVAL:
			path_movement_timer = 0.0
			if path_movement_index < path_movement_target.size():
				var step_hex = path_movement_target[path_movement_index]
				if hex_map.is_wall(step_hex):
					path_movement_active = false
					return
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
			else:
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
	
	_check_enemy_sight()
	
	if in_combat:
		var combat_manager = get_node_or_null("CombatManager")
		if combat_manager and combat_manager.has_method("process"):
			combat_manager.process(_delta)
		var ui = get_node_or_null("CombatUI")
		if ui and ui.has_method("process"):
			ui.process(_delta)
