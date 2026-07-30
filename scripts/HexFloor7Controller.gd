extends Node2D

# ===================================================================
# FLOOR 7 CONTROLLER — Hex-Based — The Broken Pact
# ===================================================================
# Spiral bureaucracy: 11 rooms in concentric rings
# Outer → Middle → Inner → Center (Auditorium)
# Unique systems: Pacts, Void Cracks, Docket, The Denied (3-phase boss)
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "f7_office"
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
# Floor 7 — Pact System
# -------------------------------------------------------------------
var signed_pacts: Array[Dictionary] = []
var active_pact_effects: Dictionary = {}
var pact_offer_cooldown: int = 0

# -------------------------------------------------------------------
# Floor 7 — Void Cracks
# -------------------------------------------------------------------
var void_crack_hexes: Array[Vector2i] = []
var void_crack_stabilized: Array[bool] = []
var stabilizers_placed: int = 0
var near_void_crack: bool = false

# -------------------------------------------------------------------
# Floor 7 — Docket / Sin
# -------------------------------------------------------------------
var docket_sins: Dictionary = {}
var docket_total_weight: int = 0
var docket_calculated: bool = false

# -------------------------------------------------------------------
# Floor 7 — Boss (The Denied)
# -------------------------------------------------------------------
var boss_phase: int = 1  # 1=Hearing, 2=Verdict, 3=Appeal
var boss_hp: int = 60
var boss_max_hp: int = 60
var final_pact_offered: bool = false
var final_pact_signed: bool = false
var all_pacts_broken: bool = false

# -------------------------------------------------------------------
# Floor 7 — Goblin Forger
# -------------------------------------------------------------------
var goblin_forger_available: bool = false
var forgery_used: bool = false

# -------------------------------------------------------------------
# Room Data — Spiral layout
# -------------------------------------------------------------------
var room_data: Dictionary = {
	"f7_office":     {"center": Vector2i(0, 0),    "radius": 18, "encounter": "pact_demon", "display": "Office",          "level": "outer"},
	"f7_court":      {"center": Vector2i(0, -30),   "radius": 14, "encounter": "judge_imp",  "display": "Court",           "level": "outer"},
	"f7_break":      {"center": Vector2i(26, -15),  "radius": 12, "encounter": "none",       "display": "Break Room",      "level": "outer"},
	"f7_filing":     {"center": Vector2i(26, 15),   "radius": 14, "encounter": "pact_demon", "display": "Filing",          "level": "outer"},
	"f7_corridor":   {"center": Vector2i(0, 30),    "radius": 12, "encounter": "security",   "display": "Corridor",        "level": "middle"},
	"f7_laboratory": {"center": Vector2i(-26, 15),  "radius": 14, "encounter": "void_exp",   "display": "Laboratory",      "level": "middle"},
	"f7_storage":    {"center": Vector2i(-26, -15), "radius": 12, "encounter": "security",   "display": "Storage",         "level": "middle"},
	"f7_court_ii":   {"center": Vector2i(-40, 0),   "radius": 14, "encounter": "judge_imp",  "display": "Court II",        "level": "middle"},
	"f7_void_lab":   {"center": Vector2i(0, 50),    "radius": 12, "encounter": "void_exp",   "display": "Void Lab",        "level": "inner"},
	"f7_antechamber":{"center": Vector2i(0, -50),   "radius": 10, "encounter": "shadow",     "display": "Antechamber",     "level": "inner"},
	"f7_auditorium": {"center": Vector2i(0, 0),     "radius": 6,  "encounter": "boss",       "display": "The Auditorium",  "level": "center"},
}

# Portal connections (spiral path + shortcuts)
var portal_connections: Dictionary = {
	"f7_office":     {"north": "f7_court",      "east": "f7_filing",     "southeast": "f7_break",     "west": "f7_storage", "exit": "f7_floor6"},
	"f7_court":      {"south": "f7_office",     "east": "f7_break",      "southeast": "f7_corridor"},
	"f7_break":      {"west": "f7_court",       "southwest": "f7_office", "northwest": "f7_filing"},
	"f7_filing":     {"west": "f7_office",      "northwest": "f7_break",  "south": "f7_corridor"},
	"f7_corridor":   {"north": "f7_filing",     "south": "f7_void_lab", "west": "f7_laboratory", "east": "f7_storage"},
	"f7_laboratory": {"east": "f7_corridor",    "southwest": "f7_storage", "north": "f7_court_ii"},
	"f7_storage":    {"east": "f7_corridor",    "northeast": "f7_laboratory", "west": "f7_court_ii"},
	"f7_court_ii":   {"east": "f7_storage",     "northeast": "f7_laboratory", "south": "f7_antechamber"},
	"f7_void_lab":   {"north": "f7_corridor",    "south": "f7_auditorium"},
	"f7_antechamber":{"north": "f7_court_ii",    "south": "f7_auditorium"},
	"f7_auditorium": {"north": "f7_antechamber", "south": "f7_void_lab", "exit": "f7_floor8"},
}

var portal_offsets: Dictionary = {
	"north": Vector2i(0, -15), "south": Vector2i(0, 15),
	"east":  Vector2i(15, 0),  "west":  Vector2i(-15, 0),
	"northeast": Vector2i(10, -10), "northwest": Vector2i(-10, -10),
	"southeast": Vector2i(10, 10),  "southwest": Vector2i(-10, 10),
	"up": Vector2i(0, -8), "down": Vector2i(0, 8),
	"exit": Vector2i(0, 20),
}

var room_cleared: Dictionary = {}
var room_encounter_spawned: Dictionary = {}

# Hex enemies
var hex_enemies: Array[HexEnemy] = []
var enemy_container: Node2D
var ambush_bonus: bool = false

# UI
var interact_prompt: Label
var pause_menu: CanvasLayer
var pact_ui: Label
var docket_ui: Label
var void_crack_ui: Label
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
	print("[Floor7-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_enemies()
	_setup_post_combat_ui()  # Post-combat reward screen
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(7)
	_enter_room("f7_office")

# ===================================================================
# HEX LAYOUT — Spiral Bureaucracy
# ===================================================================

func _generate_hex_layout():
	hex_map.clear_grid()
	
	# === OUTER RING ===
	_generate_room_hex("f7_office", Vector2i(0, 0), 18, [Vector2i(0, -18), Vector2i(18, 0), Vector2i(10, 15), Vector2i(-15, 0), Vector2i(0, 20)])
	_generate_room_hex("f7_court", Vector2i(0, -30), 14, [Vector2i(0, -16), Vector2i(10, -20), Vector2i(10, -40)])
	_generate_room_hex("f7_break", Vector2i(26, -15), 12, [Vector2i(14, -15), Vector2i(20, -5), Vector2i(20, -25)])
	_generate_room_hex("f7_filing", Vector2i(26, 15), 14, [Vector2i(14, 15), Vector2i(20, 5), Vector2i(0, 30)])
	
	# === MIDDLE RING ===
	_generate_room_hex("f7_corridor", Vector2i(0, 30), 12, [Vector2i(0, 18), Vector2i(0, 42), Vector2i(-15, 30), Vector2i(15, 30)])
	_generate_room_hex("f7_laboratory", Vector2i(-26, 15), 14, [Vector2i(-15, 15), Vector2i(-20, 5), Vector2i(-20, 25), Vector2i(-40, 0)])
	_generate_room_hex("f7_storage", Vector2i(-26, -15), 12, [Vector2i(-15, -15), Vector2i(-20, -5), Vector2i(-40, 0)])
	_generate_room_hex("f7_court_ii", Vector2i(-40, 0), 14, [Vector2i(-28, 0), Vector2i(-26, -15), Vector2i(0, -50)])
	
	# === INNER RING ===
	_generate_room_hex("f7_void_lab", Vector2i(0, 50), 12, [Vector2i(0, 38), Vector2i(0, 58)])
	_generate_room_hex("f7_antechamber", Vector2i(0, -50), 10, [Vector2i(0, -40), Vector2i(0, -58)])
	
	# === CENTER (AUDITORIUM) — small, elevated ===
	_generate_room_hex("f7_auditorium", Vector2i(0, 0), 6, [Vector2i(0, -8), Vector2i(0, 8)])
	
	# === CORRIDORS (connect spiral path) ===
	# Office -> Court
	_generate_corridor_hex(Vector2i(0, -18), Vector2i(0, -16), 2)
	# Office -> Break
	_generate_corridor_hex(Vector2i(10, 15), Vector2i(14, -15), 2)
	# Office -> Filing
	_generate_corridor_hex(Vector2i(18, 0), Vector2i(14, 15), 2)
	# Office -> Storage
	_generate_corridor_hex(Vector2i(-15, 0), Vector2i(-15, -15), 2)
	# Court -> Break
	_generate_corridor_hex(Vector2i(10, -20), Vector2i(20, -5), 2)
	# Break -> Filing
	_generate_corridor_hex(Vector2i(20, -25), Vector2i(20, 5), 2)
	# Filing -> Corridor
	_generate_corridor_hex(Vector2i(0, 30), Vector2i(0, 30), 2)
	# Corridor -> Laboratory
	_generate_corridor_hex(Vector2i(-15, 30), Vector2i(-15, 15), 2)
	# Corridor -> Storage
	_generate_corridor_hex(Vector2i(15, 30), Vector2i(-15, -15), 2)
	# Laboratory -> Storage
	_generate_corridor_hex(Vector2i(-20, 5), Vector2i(-20, -5), 2)
	# Laboratory -> Court II
	_generate_corridor_hex(Vector2i(-20, 25), Vector2i(-28, 0), 2)
	# Storage -> Court II
	_generate_corridor_hex(Vector2i(-20, -5), Vector2i(-28, 0), 2)
	# Court II -> Antechamber
	_generate_corridor_hex(Vector2i(0, -50), Vector2i(0, -40), 2)
	# Corridor -> Void Lab
	_generate_corridor_hex(Vector2i(0, 42), Vector2i(0, 38), 2)
	# Void Lab -> Auditorium
	_generate_corridor_hex(Vector2i(0, 58), Vector2i(0, 8), 2)
	# Antechamber -> Auditorium
	_generate_corridor_hex(Vector2i(0, -58), Vector2i(0, -8), 2)
	
	# === OBJECTS ===
	# Contract stations (office, corridor)
	hex_map.set_tile(Vector2i(5, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(5, 30), HexTileMap.TILE_OBJECT)
	
	# Docket terminals (court, court_ii)
	hex_map.set_tile(Vector2i(0, -30), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-40, 0), HexTileMap.TILE_OBJECT)
	
	# Void crack stabilizers (laboratory, void_lab)
	hex_map.set_tile(Vector2i(-26, 15), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(0, 50), HexTileMap.TILE_OBJECT)
	
	# Goblin forger (break room, if available)
	hex_map.set_tile(Vector2i(26, -15), HexTileMap.TILE_OBJECT)
	
	# Pact review station (antechamber)
	hex_map.set_tile(Vector2i(0, -50), HexTileMap.TILE_OBJECT)
	
	# Final pact altar (auditorium, hidden until boss phase 3)
	hex_map.set_tile(Vector2i(0, 0), HexTileMap.TILE_OBJECT)
	
	# Save points (office, break room)
	hex_map.set_tile(Vector2i(10, 0), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(20, -15), HexTileMap.TILE_OBJECT)
	
	# === VOID CRACKS (dark purple tiles) ===
	# Laboratory area
	for q in range(-30, -22):
		for r in range(10, 20):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.15:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				void_crack_hexes.append(hex)
				void_crack_stabilized.append(false)
	# Void Lab area
	for q in range(-8, 8):
		for r in range(42, 58):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.25:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				void_crack_hexes.append(hex)
				void_crack_stabilized.append(false)
	# Auditorium edges
	for q in range(-8, 8):
		for r in range(-8, 8):
			var hex = Vector2i(q, r)
			var dist = HexTileMap._hex_distance(hex, Vector2i(0, 0))
			if dist == 6 and randf() < 0.3:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				void_crack_hexes.append(hex)
				void_crack_stabilized.append(false)
	
	# === PORTALS ===
	# Floor 6 exit (office edge)
	hex_map.set_tile(Vector2i(0, 20), HexTileMap.TILE_PORTAL)
	# Floor 8 (auditorium after boss)
	hex_map.set_tile(Vector2i(0, -8), HexTileMap.TILE_PORTAL)
	
	print("[Floor7-Hex] Layout complete: Spiral bureaucracy + void cracks + %d rooms" % room_data.size())

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
	
	var start_room = room_data.get("f7_office")
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
		print("[Floor7-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		return
	var enemies = RoomEnemyDatabase.get_floor_composition(7, encounter_type)
	if enemies.is_empty():
		return
	in_combat = true
	AudioManager.play_combat(7)
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
	print("[Floor7-Hex] Combat started: %s" % encounter_type)

func _on_combat_ended(victory: bool):
	in_combat = false
		
		# Capture defeated faction BEFORE cleanup
		var defeated_faction = ""
		for enemy in hex_enemies:
			if enemy.state == HexEnemy.State.IN_COMBAT and enemy.hp <= 0:
				defeated_faction = enemy.faction
				break
		
		# Show overworld UI again
		var main_ui = get_node_or_null("MainUI")
		if main_ui:
			main_ui.visible = true
		
	AudioManager.play_floor_ambient(7)
	var ui = get_node_or_null("CombatUI")
	if ui:
		ui.visible = false
	if victory:
		room_cleared[current_room_id] = true

				# Show post-combat reward UI
				if post_combat_ui:
					var quiddity_earned = 0
					var combat_manager = get_node_or_null("CombatManager")
					if combat_manager:
						quiddity_earned = combat_manager.quiddity_this_combat
					post_combat_ui.show_post_combat(true, quiddity_earned, defeated_faction)
					in_ui = true
					print("[Floor7-Hex] Post-combat UI shown, faction: %s" % defeated_faction)
					return  # Wait for ui_closed signal
		if current_room_id == "f7_auditorium":
			_show_notification("🎉 THE DENIED IS DEFEATED!", Color(0.9, 0.9, 0.3), 3.0)
			GameState.add_card_to_deck("the_denied")
			GameState.gems += 100
			if GameState.has_signal("gems_changed"):
				GameState.gems_changed.emit(GameState.gems)
			_show_floor_transition_prompt()
			return
		if current_room_id == "f7_court" or current_room_id == "f7_court_ii":
			_lecture_hall_panic()
		# Check pact system progress
		_record_enemy_defeat_for_pacts()
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
	print("[Floor7-Hex] Combat ended. Victory: %s" % victory)

func _on_combat_turn_started(turn_number: int):
	pact_offer_cooldown += 1
	if pact_offer_cooldown >= 3 and randf() < 0.3:
		_offer_pact_in_combat()
	# Check void crack instability
	_check_void_crack_instability()
	# Update pact UI
	_update_pact_display()
	_update_docket_display()

func _offer_pact_in_combat():
	var pact_options = [
		{"name": "Blood for Power", "cost": 10, "effect": "+5 damage next turn", "sin_weight": 2},
		{"name": "Silence for Cards", "cost": 15, "effect": "Draw 2 cards", "sin_weight": 1},
		{"name": "Soul for Shield", "cost": 20, "effect": "+10 shield", "sin_weight": 3},
	]
	var pact = pact_options[randi() % pact_options.size()]
	_show_notification("📜 PACT OFFERED: %s (Cost: %d Quiddity)" % [pact["name"], pact["cost"]], Color(0.7, 0.3, 0.9), 3.0)
	# In a real implementation, this would pause combat and show a UI dialog
	# For now, we log it
	print("[Floor7-Hex] Pact offered: %s" % pact["name"])

func _record_enemy_defeat_for_pacts():
	for pact in signed_pacts:
		if pact.get("combat_trigger", false) and not pact.get("fulfilled", false):
			pact["fulfilled"] = true
			_show_notification("📜 Pact fulfilled: %s" % pact["name"], Color(0.7, 0.3, 0.9), 3.0)
			print("[Floor7-Hex] Pact fulfilled: %s" % pact["name"])

# ===================================================================
# ENEMIES
# ===================================================================


func _setup_post_combat_ui():
	"""Setup the post-combat reward UI."""
	var post_combat_scene = load("res://scenes/PostCombatUI.tscn")
	if post_combat_scene:
		post_combat_ui = post_combat_scene.instantiate()
		add_child(post_combat_ui)
		post_combat_ui.visible = false
		post_combat_ui.ui_closed.connect(_on_post_combat_closed)
		print("[Floor7-Hex] PostCombatUI ready")
	else:
		push_warning("[Floor7-Hex] PostCombatUI scene not found!")

func _setup_enemies():
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.z_index = 90
	add_child(enemy_container)
	
	var spawn_configs = {
		"f7_office": [
			{"name": "Pact Demon", "hex": Vector2i(5, 5), "faction": "Demon", "hp": 12, "atk": 3},
			{"name": "Pact Demon", "hex": Vector2i(-5, 5), "faction": "Demon", "hp": 12, "atk": 3},
		],
		"f7_court": [
			{"name": "Judge Imp", "hex": Vector2i(0, -30), "faction": "Demon", "hp": 20, "atk": 4, "boss": false, "stationary": true},
		],
		"f7_filing": [
			{"name": "Filing Demon", "hex": Vector2i(20, 10), "faction": "Demon", "hp": 10, "atk": 3},
			{"name": "Filing Demon", "hex": Vector2i(30, 20), "faction": "Demon", "hp": 10, "atk": 3},
		],
		"f7_corridor": [
			{"name": "Security Imp", "hex": Vector2i(5, 30), "faction": "Demon", "hp": 14, "atk": 4},
			{"name": "Security Imp", "hex": Vector2i(-5, 30), "faction": "Demon", "hp": 14, "atk": 4},
		],
		"f7_laboratory": [
			{"name": "Void Experiment", "hex": Vector2i(-30, 10), "faction": "Void", "hp": 15, "atk": 5},
			{"name": "Void Experiment", "hex": Vector2i(-20, 20), "faction": "Void", "hp": 15, "atk": 5},
		],
		"f7_storage": [
			{"name": "Storage Guard", "hex": Vector2i(-30, -10), "faction": "Demon", "hp": 12, "atk": 3},
			{"name": "Storage Guard", "hex": Vector2i(-20, -20), "faction": "Demon", "hp": 12, "atk": 3},
		],
		"f7_court_ii": [
			{"name": "Judge Imp II", "hex": Vector2i(-40, 0), "faction": "Demon", "hp": 25, "atk": 5, "boss": false, "stationary": true},
		],
		"f7_void_lab": [
			{"name": "Void Tendril", "hex": Vector2i(5, 50), "faction": "Void", "hp": 18, "atk": 5},
			{"name": "Void Tendril", "hex": Vector2i(-5, 50), "faction": "Void", "hp": 18, "atk": 5},
			{"name": "Void Tendril", "hex": Vector2i(0, 55), "faction": "Void", "hp": 18, "atk": 5},
		],
		"f7_antechamber": [
			{"name": "Shadow of Denied", "hex": Vector2i(0, -50), "faction": "Void", "hp": 20, "atk": 4, "view_range": 10},
		],
		"f7_auditorium": [
			{"name": "The Denied", "hex": Vector2i(0, 0), "faction": "Boss", "hp": 60, "atk": 6, "boss": true, "stationary": true, "view_range": 12, "combat_range": 2},
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
	
	print("[Floor7-Hex] %d hex enemies spawned" % hex_enemies.size())

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
		AudioManager.play_combat(7)
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		if ambush_bonus:
			_show_notification("🎯 AMBUSH! Player goes first!", Color(0.3, 0.9, 0.3), 3.0)
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
	print("[Floor7-Hex] Combat initiated (ambush: %s)" % ambush)

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
				pass  # Still in alert phase
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
# FLOOR 7 — VOID CRACKS
# ===================================================================

func _check_void_crack_instability():
	if void_crack_hexes.is_empty():
		return
	var unstable_count = 0
	for i in range(void_crack_hexes.size()):
		if not void_crack_stabilized[i]:
			unstable_count += 1
	if unstable_count > 5 and randf() < 0.1:
		_show_notification("💀 Void crack instability detected!", Color(0.5, 0.2, 0.7), 3.0)
		# Spawn extra void enemy near unstable crack
		for i in range(void_crack_hexes.size()):
			if not void_crack_stabilized[i] and randf() < 0.2:
				var crack_hex = void_crack_hexes[i]
				var enemy = HexEnemy.new("void_spawn_%d" % hex_enemies.size(), "Void Spawn", crack_hex, "Void")
				enemy.hp = 8
				enemy.max_hp = 8
				enemy.attack = 3
				_add_enemy(enemy, crack_hex)
				_show_notification("💀 Void spawn from crack!", Color(0.5, 0.2, 0.7), 3.0)
				break

func _stabilize_void_crack():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	for i in range(void_crack_hexes.size()):
		if not void_crack_stabilized[i]:
			var dist = HexTileMap._hex_distance(player_hex, void_crack_hexes[i])
			if dist <= 1:
				void_crack_stabilized[i] = true
				stabilizers_placed += 1
				_show_notification("🔧 Void crack stabilized! (%d/%d)" % [stabilizers_placed, void_crack_hexes.size()], Color(0.3, 0.7, 0.9), 3.0)
				return
	_show_notification("No unstable void crack nearby.", Color(0.7, 0.7, 0.7), 3.0)

func _check_player_near_void_crack():
	if not player_node:
		return
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var was_near = near_void_crack
	near_void_crack = false
	for i in range(void_crack_hexes.size()):
		if not void_crack_stabilized[i]:
			var dist = HexTileMap._hex_distance(player_hex, void_crack_hexes[i])
			if dist <= 2:
				near_void_crack = true
				break
	if near_void_crack and not was_near:
		_show_notification("☠ Near unstable void crack! Attention draining...", Color(0.5, 0.2, 0.7), 3.0)
	elif not near_void_crack and was_near:
		_show_notification("Safe from void cracks.", Color(0.3, 0.9, 0.3), 3.0)

# ===================================================================
# FLOOR 7 — DOCKET / SIN SYSTEM
# ===================================================================

func _calculate_docket():
	docket_sins.clear()
	docket_total_weight = 0
	# Calculate sins from past floors (placeholder — would integrate with GameState)
	var floor_sins = {
		"floor1": randi() % 3,
		"floor2": randi() % 3,
		"floor3": randi() % 3,
		"floor4": randi() % 3,
		"floor5": randi() % 3,
		"floor6": randi() % 3,
	}
	for floor in floor_sins:
		docket_sins[floor] = floor_sins[floor]
		docket_total_weight += floor_sins[floor]
	docket_calculated = true
	print("[Floor7-Hex] Docket calculated: %d sin weight" % docket_total_weight)

func _reduce_docket(amount: int):
	docket_total_weight = max(0, docket_total_weight - amount)
	_show_notification("📜 Docket reduced by %d. Current weight: %d" % [amount, docket_total_weight], Color(0.3, 0.9, 0.3), 3.0)
	_update_docket_display()

# ===================================================================
# FLOOR 7 — BOSS (The Denied)
# ===================================================================

func _check_boss_phase():
	if boss_phase >= 3:
		return
	var hp_percent = float(boss_hp) / boss_max_hp
	if boss_phase == 1 and hp_percent <= 0.6:
		boss_phase = 2
		_show_notification("⚖️ PHASE 2: VERDICT — The Denied passes judgment!", Color(0.9, 0.3, 0.3), 3.0)
		_boss_verdict_effects()
	elif boss_phase == 2 and hp_percent <= 0.3:
		boss_phase = 3
		_show_notification("⚖️ PHASE 3: APPEAL — All pacts are broken! Maximum damage!", Color(0.9, 0.1, 0.1), 3.0)
		_boss_appeal_effects()
		_offer_final_pact()

func _boss_verdict_effects():
	# Void crack explosions
	for i in range(void_crack_hexes.size()):
		if not void_crack_stabilized[i]:
			_show_notification("💀 Void crack explodes!", Color(0.5, 0.2, 0.7), 3.0)
	# All enemies heal slightly
	for enemy in hex_enemies:
		if enemy.hp > 0 and not enemy.is_boss:
			enemy.hp = min(enemy.max_hp, enemy.hp + 3)

func _boss_appeal_effects():
	# All signed pacts are broken
	for pact in signed_pacts:
		pact["broken"] = true
	all_pacts_broken = true
	_show_notification("📜 ALL PACTS BROKEN!", Color(0.9, 0.1, 0.1), 3.0)
	# Player takes damage if they had pacts
	if signed_pacts.size() > 0:
		_show_notification("💔 You feel the weight of broken pacts!", Color(0.9, 0.1, 0.1), 3.0)

func _offer_final_pact():
	if final_pact_offered:
		return
	final_pact_offered = true
	_show_notification("📜 FINAL PACT OFFERED by The Denied!", Color(0.9, 0.1, 0.9), 3.0)
	_show_dialogue("The Denied", "Sign the Final Pact and end this now. Or fight to the death. Your choice.")
	# In a real implementation, this would show a dialog with Sign/Refuse options

func _sign_final_pact():
	final_pact_signed = true
	_show_notification("📜 FINAL PACT SIGNED! Instant victory... at a cost.", Color(0.9, 0.1, 0.9), 3.0)
	# Heavy cost: lose half max HP, all gems, all pacts broken
	GameState.gems = 0
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(0)
	# Boss defeated instantly
	boss_hp = 0
	_on_combat_ended(true)

# ===================================================================
# FLOOR 7 — GOBLIN FORGER
# ===================================================================

func _interact_with_goblin_forger():
	if not goblin_forger_available:
		_show_dialogue("Empty Desk", "Nobody here. Maybe someone will show up later.")
		return
	if forgery_used:
		_show_dialogue("Goblin Forger", "Already forged your documents. Can't help more. Too risky.")
		return
	_show_dialogue("Goblin Forger", "Hey pal! I 'borrowed' some official stamps from Floor 6. Need a forged pact? Cheaper but riskier. Or I can forge a docket reduction. Your call.")
	# Options: Forge pact (cost 5 gems, cheaper but sin_weight +2), Forge docket (cost 10 gems, reduce docket by 3)
	# For now, just show notification
	_show_notification("🤝 Goblin Forger: Pact forging available!", Color(0.3, 0.9, 0.3), 3.0)

func _forge_pact():
	if forgery_used:
		return
	forgery_used = true
	var forged_pact = {
		"name": "Forged Pact of Power",
		"cost": 5,
		"effect": "+8 damage, +2 sin_weight",
		"sin_weight": 4,
		"forged": true,
	}
	signed_pacts.append(forged_pact)
	_show_notification("📜 Forged pact signed! +8 damage, +2 sin weight.", Color(0.9, 0.7, 0.3), 3.0)
	_update_pact_display()

func _forge_docket_reduction():
	if GameState.gems < 10:
		_show_notification("Not enough gems! Need 10 gems.", Color(0.9, 0.3, 0.3), 3.0)
		return
	GameState.gems -= 10
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	_reduce_docket(3)
	_show_notification("📜 Docket forged! -3 sin weight. Cost: 10 gems.", Color(0.3, 0.9, 0.3), 3.0)

# ===================================================================
# FLOOR 7 — PACT INTERACTIONS
# ===================================================================

func _interact_contract_station():
	if all_pacts_broken:
		_show_dialogue("Contract Station", "All contracts are void. The Denied has broken them.")
		return
	var pact_options = [
		{"name": "Pact of Swiftness", "cost": 10, "effect": "+2 moves per turn", "sin_weight": 1},
		{"name": "Pact of Strength", "cost": 15, "effect": "+3 damage", "sin_weight": 2},
		{"name": "Pact of Warding", "cost": 20, "effect": "+5 shield", "sin_weight": 1},
	]
	var pact = pact_options[randi() % pact_options.size()]
	# Check if player can afford
	if GameState.gems < pact["cost"]:
		_show_dialogue("Contract Station", "Not enough Quiddity. Need %d gems." % pact["cost"])
		return
	GameState.gems -= pact["cost"]
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	signed_pacts.append(pact)
	docket_total_weight += pact["sin_weight"]
	_show_notification("📜 Pact signed: %s! Sin weight +%d" % [pact["name"], pact["sin_weight"]], Color(0.7, 0.3, 0.9), 3.0)
	_update_pact_display()
	_update_docket_display()

func _interact_docket_terminal():
	var msg = "DOCKET:\n"
	for floor in docket_sins:
		msg += "%s: %d sin\n" % [floor, docket_sins[floor]]
	msg += "\nTotal weight: %d" % docket_total_weight
	msg += "\n\nOptions:\n1. Reduce sin (cost 20 gems)\n2. View pacts"
	_show_dialogue("Docket Terminal", msg)

func _interact_pact_review():
	if signed_pacts.is_empty():
		_show_dialogue("Pact Review", "No pacts signed yet.")
		return
	var msg = "SIGNED PACTS:\n"
	for pact in signed_pacts:
		var status = "✅" if not pact.get("broken", false) else "💔 BROKEN"
		msg += "%s %s (sin: %d)\n" % [status, pact["name"], pact.get("sin_weight", 0)]
	_show_dialogue("Pact Review", msg)

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
	
	# Pact UI
	pact_ui = Label.new()
	pact_ui.name = "PactUI"
	pact_ui.position = Vector2(20, 100)
	pact_ui.size = Vector2(300, 100)
	pact_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(pact_ui)
	
	# Docket UI
	docket_ui = Label.new()
	docket_ui.name = "DocketUI"
	docket_ui.position = Vector2(20, 210)
	docket_ui.size = Vector2(300, 80)
	docket_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(docket_ui)
	
	# Void crack UI
	void_crack_ui = Label.new()
	void_crack_ui.name = "VoidCrackUI"
	void_crack_ui.position = Vector2(20, 300)
	void_crack_ui.size = Vector2(300, 60)
	void_crack_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(void_crack_ui)
	
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
	
	_update_pact_display()
	_update_docket_display()
	_update_void_crack_display()

func _update_pact_display():
	if not pact_ui:
		return
	var text = "📜 PACTS: %d\n" % signed_pacts.size()
	for pact in signed_pacts:
		var status = "✅" if not pact.get("broken", false) else "💔"
		text += "%s %s\n" % [status, pact["name"]]
	pact_ui.text = text

func _update_docket_display():
	if not docket_ui:
		return
	var text = "⚖️ DOCKET:\nTotal sin weight: %d\n" % docket_total_weight
	if docket_total_weight > 5:
		text += "(High sin — pacts cost more)"
	elif docket_total_weight > 10:
		text += "(Very high sin — The Denied is stronger)"
	docket_ui.text = text

func _update_void_crack_display():
	if not void_crack_ui:
		return
	var stabilized = 0
	for s in void_crack_stabilized:
		if s:
			stabilized += 1
	var text = "💀 VOID CRACKS: %d/%d stabilized\n" % [stabilized, void_crack_hexes.size()]
	if near_void_crack:
		text += "☠ NEAR UNSTABLE CRACK!"
	void_crack_ui.text = text

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

func _show_floor_transition_prompt():
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 8 — The Hollow Crown"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

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
	_check_player_near_void_crack()
	_update_void_crack_display()

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
	print("[Floor7-Hex] Entered: %s" % display)
	if room_indicator:
		room_indicator.text = "📍 %s" % display
		var color = Color(0.7, 0.7, 0.7)
		match room_id:
			"f7_office":      color = Color(0.6, 0.6, 0.7)
			"f7_court":       color = Color(0.7, 0.5, 0.5)
			"f7_break":       color = Color(0.5, 0.7, 0.5)
			"f7_filing":      color = Color(0.6, 0.6, 0.7)
			"f7_corridor":    color = Color(0.7, 0.7, 0.6)
			"f7_laboratory":  color = Color(0.5, 0.3, 0.7)
			"f7_storage":     color = Color(0.6, 0.5, 0.6)
			"f7_court_ii":    color = Color(0.7, 0.5, 0.5)
			"f7_void_lab":    color = Color(0.4, 0.2, 0.6)
			"f7_antechamber": color = Color(0.5, 0.5, 0.6)
			"f7_auditorium":  color = Color(0.9, 0.3, 0.3)
		room_indicator.add_theme_color_override("font_color", color)

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
	if target_room == "f7_auditorium" and not room_cleared.get("f7_antechamber", false) and not room_cleared.get("f7_void_lab", false):
		_show_notification("🔒 The Auditorium is sealed. Clear the inner rooms first.")
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
		"f7_office":     msg = "You return to the Office."
		"f7_court":      msg = "The court is in session."
		"f7_break":      msg = "Break room. A moment of peace."
		"f7_filing":     msg = "Filing cabinets stretch to the ceiling."
		"f7_corridor":   msg = "The corridor echoes with footsteps."
		"f7_laboratory": msg = "Void experiments hum in the darkness."
		"f7_storage":    msg = "Storage crates stacked high."
		"f7_court_ii":   msg = "Court II. The judgment continues."
		"f7_void_lab":   msg = "The Void Lab. Reality is thin here."
		"f7_antechamber":msg = "The Antechamber. The Denied is near."
		"f7_auditorium": msg = "The Auditorium. The Denied awaits."
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
		"northeast": return "southwest"
		"northwest": return "southeast"
		"southeast": return "northwest"
		"southwest": return "northeast"
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
			"contract_station":   _show_interact_prompt("[S] Sign Contract")
			"docket_terminal":    _show_interact_prompt("[S] Access Docket")
			"void_stabilizer":    _show_interact_prompt("[S] Stabilize Void Crack")
			"goblin_forger":      _show_interact_prompt("[S] Talk to Goblin Forger")
			"pact_review":        _show_interact_prompt("[S] Review Pacts")
			"final_pact_altar":   _show_interact_prompt("[S] Final Pact")
			"save_point":         _show_interact_prompt("[S] Save Game")
			_:
				_hide_interact_prompt()
	elif tile == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir == "exit":
			if current_room_id == "f7_office":
				_show_interact_prompt("[S] Return to Floor 6")
			elif current_room_id == "f7_auditorium":
				_show_interact_prompt("[S] Ascend to Floor 8")
			else:
				_hide_interact_prompt()
		else:
			_hide_interact_prompt()
	else:
		_hide_interact_prompt()

func _get_object_id_at_hex(hex: Vector2i) -> String:
	# Map hex positions to object IDs
	var object_map = {
		Vector2i(5, 0):   "contract_station",
		Vector2i(5, 30):  "contract_station",
		Vector2i(0, -30): "docket_terminal",
		Vector2i(-40, 0): "docket_terminal",
		Vector2i(-26, 15):"void_stabilizer",
		Vector2i(0, 50):  "void_stabilizer",
		Vector2i(26, -15):"goblin_forger",
		Vector2i(0, -50): "pact_review",
		Vector2i(0, 0):   "final_pact_altar",
		Vector2i(10, 0):  "save_point",
		Vector2i(20, -15):"save_point",
	}
	return object_map.get(hex, "")

func _interact_at_hex(hex: Vector2i):
	var obj_id = _get_object_id_at_hex(hex)
	match obj_id:
		"contract_station":   _interact_contract_station()
		"docket_terminal":    _interact_docket_terminal()
		"void_stabilizer":    _stabilize_void_crack()
		"goblin_forger":      _interact_with_goblin_forger()
		"pact_review":        _interact_pact_review()
		"final_pact_altar":   if final_pact_offered and not final_pact_signed: _sign_final_pact()
		"save_point":         if GameState.has_method("save_game"): GameState.save_game(); _show_notification("Progress saved.")
	
	# Check for portal interaction
	if hex_map.get_tile(hex) == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(hex)
		if portal_dir == "exit":
			if current_room_id == "f7_office":
				get_tree().change_scene_to_file("res://scenes/Floor6.tscn")
			elif current_room_id == "f7_auditorium":
				get_tree().change_scene_to_file("res://scenes/Floor8.tscn")

# ===================================================================
# FLOOR SPECIFIC SETUP
# ===================================================================

func _setup_floor_specific():
	# Cross-floor bleed from Floor 6
	if GameState.get_value("floor6_graduate_status", "") == "graduate":
		_show_notification("🎓 Alumni Discount — Pacts cost 25% less", Color(0.3, 0.9, 0.3), 3.0)
	if GameState.get_value("floor6_goblin_janitor_befriended", false):
		goblin_forger_available = true
		_show_notification("🤝 Goblin Forger available in Break Room", Color(0.3, 0.9, 0.3), 3.0)
	if not docket_calculated:
		_calculate_docket()
	print("[Floor7-Hex] Setup complete. Sins: %d | Goblin: %s" % [docket_total_weight, goblin_forger_available])

func _lecture_hall_panic():
	_show_notification("⚖️ Judge defeated! Court panics!", Color(0.9, 0.9, 0.3), 3.0)
	for enemy in hex_enemies:
		if enemy.hp > 0 and not enemy.is_boss and enemy.current_room == current_room_id:
			var roll = randi() % 3
			match roll:
				0: enemy._set_state(HexEnemy.State.UNAWARE); enemy.patrol_radius = 0
				1: enemy.attack += 2
				2: enemy._set_state(HexEnemy.State.ALERT)
			print("[Floor7-Hex] %s panics: %d" % [enemy.enemy_name, roll])

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
				if not in_combat and not in_ui:
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
				_check_player_near_void_crack()
				_update_void_crack_display()
			else:
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
	
	_check_enemy_sight()
	_check_player_near_void_crack()
	
	if in_combat:
		var combat_manager = get_node_or_null("CombatManager")
		if combat_manager and combat_manager.has_method("process"):
			combat_manager.process(_delta)
		var ui = get_node_or_null("CombatUI")
var post_combat_ui: PostCombatUI
		if ui and ui.has_method("process"):
			ui.process(_delta)

func _on_post_combat_closed():
	in_ui = false
	print("[Floor7-Hex] Post-combat closed, resuming")

