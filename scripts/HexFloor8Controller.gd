extends Node2D

# ===================================================================
# FLOOR 8 CONTROLLER — Hex-Based — The Overclock Forge
# ===================================================================
# Vertical factory stack: 5 levels of industrial hex grid
# Loading Bay → Lower Works → Middle Works → Upper Works → Control Room
# Unique systems: Overclock, Elemental Charge, Containment Vessels,
#                Goblin Morale, Blix Boss, Padlock Door, Hazard Zones
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "loading_bay"
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
# Floor 8 — Overclock Meter
# -------------------------------------------------------------------
var overclock: int = 0
var current_overclock_tier: String = "low"

# -------------------------------------------------------------------
# Floor 8 — Elemental Charge
# -------------------------------------------------------------------
var elemental_charge: Dictionary = {"fire": 0, "water": 0, "earth": 0, "air": 0}
const ELEMENTAL_CHARGE_MAX: int = 10

# -------------------------------------------------------------------
# Floor 8 — Hazard Zones (hex coords per type)
# -------------------------------------------------------------------
var fire_hazard_hexes: Array[Vector2i] = []
var water_hazard_hexes: Array[Vector2i] = []
var earth_hazard_hexes: Array[Vector2i] = []
var air_hazard_hexes: Array[Vector2i] = []

# -------------------------------------------------------------------
# Floor 8 — Containment Vessels
# -------------------------------------------------------------------
var vessel_states: Dictionary = {}  # room_id -> Array of vessel states
var vessels_vented: int = 0
var vessels_overclocked: int = 0
var vessels_patched: int = 0
var all_vessels_vented: bool = false

# -------------------------------------------------------------------
# Floor 8 — Goblin Morale
# -------------------------------------------------------------------
var goblin_morale: int = 50  # 0-100
var goblin_morale_broken: bool = false

# -------------------------------------------------------------------
# Floor 8 — Padlock Door
# -------------------------------------------------------------------
var padlocks_remaining: int = 17
var padlock_keys_found: Array[String] = []
var padlock_door_open: bool = false
var cache_looted: bool = false

# -------------------------------------------------------------------
# Floor 8 — Boss (Chief Engineer Blix)
# -------------------------------------------------------------------
var blix_phase: int = 1
var blix_hp: int = 55
var blix_max_hp: int = 55
var blix_surrendered: bool = false
var meltdown_timer: int = 10
var scram_pulled: bool = false
var reactor_critical: bool = false

# -------------------------------------------------------------------
# Floor 8 — Cross-Floor Bleed from Floor 7
# -------------------------------------------------------------------
var blix_recognizes_contracts: bool = false
var blix_indifferent: bool = false
var shaman_fascinated: bool = false
var elementals_angry: bool = false

# -------------------------------------------------------------------
# Room Data — Vertical Factory Stack
# -------------------------------------------------------------------
var room_data: Dictionary = {
	"loading_bay":     {"center": Vector2i(0, 0),    "radius": 15, "encounter": "none",       "display": "Loading Bay",     "level": "entry"},
	"lower_works":     {"center": Vector2i(0, -30),   "radius": 14, "encounter": "elemental",  "display": "Lower Works",     "level": "lower"},
	"break_room":      {"center": Vector2i(-20, -30), "radius": 10, "encounter": "none",       "display": "Break Room",      "level": "lower"},
	"containment_hall":{"center": Vector2i(20, -30),  "radius": 12, "encounter": "vessel",     "display": "Containment Hall","level": "lower"},
	"the_leak":        {"center": Vector2i(10, -50),  "radius": 10, "encounter": "water",      "display": "The Leak",        "level": "lower"},
	"middle_works":    {"center": Vector2i(0, -60),   "radius": 14, "encounter": "elemental",  "display": "Middle Works",    "level": "middle"},
	"union_hall":      {"center": Vector2i(-20, -60), "radius": 12, "encounter": "none",       "display": "Union Hall",      "level": "middle"},
	"the_crack":       {"center": Vector2i(20, -60),  "radius": 12, "encounter": "earth",      "display": "The Crack",       "level": "middle"},
	"upper_works":     {"center": Vector2i(0, -90),   "radius": 14, "encounter": "reactor",    "display": "Upper Works",     "level": "upper"},
	"padlock_door":    {"center": Vector2i(0, -110),  "radius": 8,  "encounter": "puzzle",     "display": "Padlock Door",    "level": "upper"},
	"control_room":    {"center": Vector2i(0, -130),  "radius": 12, "encounter": "boss",       "display": "Control Room",    "level": "boss"},
}

var portal_connections: Dictionary = {
	"loading_bay":     {"north": "lower_works",     "exit": "floor7_exit"},
	"lower_works":     {"south": "loading_bay",   "north": "break_room",      "east": "containment_hall"},
	"break_room":      {"south": "lower_works",   "east": "the_leak"},
	"containment_hall":{"west": "lower_works",    "north": "the_leak",        "northeast": "middle_works"},
	"the_leak":        {"south": "containment_hall","west": "break_room",      "north": "middle_works"},
	"middle_works":    {"southwest": "the_leak",   "west": "lower_works",     "north": "union_hall",      "east": "the_crack"},
	"union_hall":      {"south": "middle_works",   "east": "upper_works",      "north": "the_crack"},
	"the_crack":       {"west": "middle_works",    "south": "union_hall",      "north": "upper_works"},
	"upper_works":     {"southwest": "the_crack",  "west": "union_hall",      "north": "padlock_door"},
	"padlock_door":    {"south": "upper_works",    "up": "control_room"},
	"control_room":    {"down": "padlock_door",    "exit": "floor9_entrance"},
}

var portal_offsets: Dictionary = {
	"north": Vector2i(0, -15), "south": Vector2i(0, 15),
	"east":  Vector2i(15, 0),   "west":  Vector2i(-15, 0),
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
var overclock_ui: Label
var elemental_ui: Label
var containment_ui: Label
var blix_ui: Label
var meltdown_ui: Label
var room_indicator: Label

# Signals
signal room_changed(room_id: String, room_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

var floor_cleared: bool = false
var floor_complete_notified: bool = false

func _ready():
	# Reset for replayability — selecting floor from menu should always be fresh
	room_cleared.clear()
	room_encounter_spawned.clear()
	floor_cleared = false
	floor_complete_notified = false
	call_deferred("_build_floor")

func _build_floor():
	GameState.set_current_floor(8)
	print("[Floor8-Hex] current_floor set to 8")
	_generate_hex_layout()
	print("[Floor8-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_enemies()
	_setup_post_combat_ui()  # Post-combat reward screen
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(8)
	_enter_room("loading_bay")

# ===================================================================
# HEX LAYOUT — Vertical Factory Stack
# ===================================================================

func _generate_hex_layout():
	hex_map.clear_grid()
	
	# === ENTRY LEVEL ===
	_generate_room_hex("loading_bay",     Vector2i(0, 0),    15, [Vector2i(0, -15), Vector2i(0, 16)])
	
	# === LOWER WORKS LEVEL ===
	_generate_room_hex("lower_works",     Vector2i(0, -30),   14, [Vector2i(0, -16), Vector2i(0, -44), Vector2i(15, -30), Vector2i(-15, -30)])
	_generate_room_hex("break_room",      Vector2i(-20, -30), 10, [Vector2i(-15, -30), Vector2i(-10, -20), Vector2i(-10, -40)])
	_generate_room_hex("containment_hall",Vector2i(20, -30),  12, [Vector2i(15, -30), Vector2i(20, -18), Vector2i(30, -40)])
	
	# === THE LEAK (water hazard) ===
	_generate_room_hex("the_leak",        Vector2i(10, -50),  10, [Vector2i(10, -40), Vector2i(10, -60), Vector2i(0, -50)])
	
	# === MIDDLE WORKS LEVEL ===
	_generate_room_hex("middle_works",    Vector2i(0, -60),   14, [Vector2i(0, -46), Vector2i(0, -74), Vector2i(15, -60), Vector2i(-15, -60)])
	_generate_room_hex("union_hall",      Vector2i(-20, -60), 12, [Vector2i(-15, -60), Vector2i(-20, -48), Vector2i(-20, -72), Vector2i(-10, -60)])
	_generate_room_hex("the_crack",       Vector2i(20, -60),  12, [Vector2i(15, -60), Vector2i(20, -48), Vector2i(20, -72), Vector2i(30, -60)])
	
	# === UPPER WORKS LEVEL ===
	_generate_room_hex("upper_works",     Vector2i(0, -90),   14, [Vector2i(0, -76), Vector2i(0, -104), Vector2i(-15, -90), Vector2i(15, -90)])
	_generate_room_hex("padlock_door",    Vector2i(0, -110),  8,  [Vector2i(0, -102), Vector2i(0, -118)])
	
	# === CONTROL ROOM (BOSS) ===
	_generate_room_hex("control_room",    Vector2i(0, -130),  12, [Vector2i(0, -118), Vector2i(0, -142)])
	
	# === CORRIDORS ===
	# Loading Bay -> Lower Works
	_generate_corridor_hex(Vector2i(0, -15), Vector2i(0, -16), 2)
	# Lower Works -> Break Room
	_generate_corridor_hex(Vector2i(-15, -30), Vector2i(-10, -30), 2)
	# Lower Works -> Containment Hall
	_generate_corridor_hex(Vector2i(15, -30), Vector2i(10, -30), 2)
	# Containment Hall -> The Leak
	_generate_corridor_hex(Vector2i(20, -18), Vector2i(10, -40), 2)
	# Break Room -> The Leak
	_generate_corridor_hex(Vector2i(-10, -40), Vector2i(0, -50), 2)
	# The Leak -> Middle Works
	_generate_corridor_hex(Vector2i(10, -60), Vector2i(0, -46), 2)
	# Middle Works -> Union Hall
	_generate_corridor_hex(Vector2i(-15, -60), Vector2i(-10, -60), 2)
	# Middle Works -> The Crack
	_generate_corridor_hex(Vector2i(15, -60), Vector2i(10, -60), 2)
	# Union Hall -> The Crack
	_generate_corridor_hex(Vector2i(-10, -60), Vector2i(15, -60), 2)
	# Union Hall -> Upper Works
	_generate_corridor_hex(Vector2i(-10, -60), Vector2i(-15, -90), 2)
	# The Crack -> Upper Works
	_generate_corridor_hex(Vector2i(30, -60), Vector2i(15, -90), 2)
	# Upper Works -> Padlock Door
	_generate_corridor_hex(Vector2i(0, -104), Vector2i(0, -102), 2)
	# Padlock Door -> Control Room
	_generate_corridor_hex(Vector2i(0, -118), Vector2i(0, -118), 2)
	
	# === OBJECTS ===
	# Shop/Save (Loading Bay)
	hex_map.set_tile(Vector2i(5, 0), HexTileMap.TILE_OBJECT)
	# Containment Vessels (Containment Hall)
	hex_map.set_tile(Vector2i(22, -30), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(18, -28), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(24, -32), HexTileMap.TILE_OBJECT)
	# Containment Vessels (Upper Works)
	hex_map.set_tile(Vector2i(2, -90), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-2, -92), HexTileMap.TILE_OBJECT)
	# Goblin Workers (Lower Works)
	hex_map.set_tile(Vector2i(-2, -30), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(2, -28), HexTileMap.TILE_OBJECT)
	# Goblin Workers (Middle Works)
	hex_map.set_tile(Vector2i(-2, -60), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(2, -62), HexTileMap.TILE_OBJECT)
	# Goblin Leader (Union Hall)
	hex_map.set_tile(Vector2i(-20, -60), HexTileMap.TILE_OBJECT)
	# Goblin Resting (Break Room - shop)
	hex_map.set_tile(Vector2i(-18, -30), HexTileMap.TILE_OBJECT)
	# Elemental Charge Stations
	hex_map.set_tile(Vector2i(-5, -30), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(-5, -60), HexTileMap.TILE_OBJECT)
	hex_map.set_tile(Vector2i(5, -90), HexTileMap.TILE_OBJECT)
	# Overclock Monitor (Upper Works)
	hex_map.set_tile(Vector2i(-5, -90), HexTileMap.TILE_OBJECT)
	# SCRAM Button (Control Room - hidden until phase 3)
	hex_map.set_tile(Vector2i(5, -130), HexTileMap.TILE_OBJECT)
	# Padlock Door (Padlock Door room)
	hex_map.set_tile(Vector2i(0, -110), HexTileMap.TILE_OBJECT)
	# Padlock Keys (one per room, scattered)
	hex_map.set_tile(Vector2i(8, 0), HexTileMap.TILE_OBJECT)       # Loading Bay
	hex_map.set_tile(Vector2i(-8, -30), HexTileMap.TILE_OBJECT)     # Break Room
	hex_map.set_tile(Vector2i(12, -30), HexTileMap.TILE_OBJECT)     # Containment Hall
	hex_map.set_tile(Vector2i(12, -50), HexTileMap.TILE_OBJECT)     # The Leak
	hex_map.set_tile(Vector2i(-8, -60), HexTileMap.TILE_OBJECT)     # Union Hall
	hex_map.set_tile(Vector2i(22, -60), HexTileMap.TILE_OBJECT)     # The Crack
	hex_map.set_tile(Vector2i(-8, -90), HexTileMap.TILE_OBJECT)     # Upper Works
	hex_map.set_tile(Vector2i(5, -110), HexTileMap.TILE_OBJECT)      # Padlock Door (master key chance)
	# Dimensional Anchor (Control Room, after boss)
	hex_map.set_tile(Vector2i(-5, -130), HexTileMap.TILE_OBJECT)
	
	# === HAZARD ZONES (TILE_WATER with separate type tracking) ===
	# Fire hazard (Upper Works - reactor heat)
	for q in range(-8, 9):
		for r in range(-98, -82):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.15:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				fire_hazard_hexes.append(hex)
	# Water hazard (The Leak)
	for q in range(2, 19):
		for r in range(-58, -42):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.25:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				water_hazard_hexes.append(hex)
	# Earth hazard (The Crack)
	for q in range(12, 29):
		for r in range(-68, -52):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.20:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				earth_hazard_hexes.append(hex)
	# Air hazard (Middle Works - ventilation)
	for q in range(-8, 9):
		for r in range(-68, -52):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.10:
				hex_map.set_tile(hex, HexTileMap.TILE_WATER)
				air_hazard_hexes.append(hex)
	
	# === PORTALS ===
	# Floor 7 exit (Loading Bay edge)
	hex_map.set_tile(Vector2i(0, 16), HexTileMap.TILE_PORTAL)
	# Floor 9 entrance (Control Room after boss)
	hex_map.set_tile(Vector2i(0, -142), HexTileMap.TILE_PORTAL)
	
	print("[Floor8-Hex] Layout complete: Factory stack + %d rooms" % room_data.size())

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
	
	var start_room = room_data.get("loading_bay")
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
		print("[Floor8-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		return
	var enemies = RoomEnemyDatabase.get_floor_composition(8, encounter_type)
	if enemies.is_empty():
		return
	in_combat = true
	AudioManager.play_combat(8)
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
	print("[Floor8-Hex] Combat started: %s" % encounter_type)

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
		
	AudioManager.play_floor_ambient(8)
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
					print("[Floor8-Hex] Post-combat UI shown, faction: %s" % defeated_faction)
					return  # Wait for ui_closed signal
		if current_room_id == "control_room":
			_show_notification("⚡ CHIEF ENGINEER BLIX DEFEATED!", Color(0.9, 0.9, 0.3))
			GameState.add_card_to_deck("chief_engineer_blix")
			GameState.gems += 100
			if GameState.has_signal("gems_changed"):
				GameState.gems_changed.emit(GameState.gems)
			_show_floor_transition_prompt()
			return
		# Check if Blix surrenders during regular combat (if player gets to 20+ OC before boss)
		if overclock > 20 and blix_phase == 0:
			_show_notification("⚡ Overclock critical! Blix might surrender if confronted!", Color(0.9, 0.2, 0.2))
		
		# Add overclock from combat victory
		_add_overclock(3)
		# Add elemental charge from elemental kills
		_add_elemental_charge(_random_elemental_type(), 2)
		if elementals_angry:
			_add_elemental_charge(_random_elemental_type(), 1)
		
		# Check hazard standing reward
		_check_hazard_rewards()
	
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
	print("[Floor8-Hex] Combat ended. Victory: %s" % victory)

func _on_combat_turn_started(turn_number: int):
	# Apply overclock tier effects
	if current_room_id == "control_room" and blix_phase == 3:
		_advance_meltdown_timer()
	
	# Check misfire
	if _check_misfire():
		pass
	
	# Apply hazard effects if player is in hazard zone
	_check_hazard_effects()
	
	# Update all UI
	_update_overclock_display()
	_update_elemental_display()
	_update_containment_display()
	if blix_phase > 1:
		_update_blix_display()
		_update_meltdown_display()

func _check_hazard_rewards():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	if player_hex in fire_hazard_hexes:
		_add_elemental_charge("fire", 1)
	if player_hex in water_hazard_hexes:
		_add_elemental_charge("water", 1)
	if player_hex in earth_hazard_hexes:
		_add_elemental_charge("earth", 1)
	if player_hex in air_hazard_hexes:
		_add_elemental_charge("air", 1)

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
		print("[Floor8-Hex] PostCombatUI ready")
	else:
		push_warning("[Floor8-Hex] PostCombatUI scene not found!")

func _setup_machinist_shop():
	"""Setup the Machinist's tabbed shop (equipment, overlays, consumables, upgrades)."""
	machinist_shop = MachinistShopUI.new()
	machinist_shop.name = "MachinistShopUI"
	add_child(machinist_shop)
	machinist_shop.shop_closed.connect(_on_machinist_shop_closed)
	print("[Floor8-Hex] MachinistShopUI ready")

func _open_machinist_shop():
	in_ui = true
	machinist_shop.show_shop()
	print("[Floor8-Hex] Machinist shop opened")

func _on_machinist_shop_closed():
	in_ui = false
	print("[Floor8-Hex] Machinist shop closed")

func _setup_enemies():
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.z_index = 90
	add_child(enemy_container)
	
	var spawn_configs = {
		"loading_bay": [
			{"name": "Security Drone", "hex": Vector2i(5, 5), "faction": "Construct", "hp": 10, "atk": 3},
			{"name": "Security Drone", "hex": Vector2i(-5, 5), "faction": "Construct", "hp": 10, "atk": 3},
		],
		"lower_works": [
			{"name": "Fire Elemental", "hex": Vector2i(5, -30), "faction": "Elemental", "hp": 14, "atk": 4},
			{"name": "Fire Elemental", "hex": Vector2i(-5, -30), "faction": "Elemental", "hp": 14, "atk": 4},
			{"name": "Water Elemental", "hex": Vector2i(0, -25), "faction": "Elemental", "hp": 12, "atk": 3},
			{"name": "Water Elemental", "hex": Vector2i(0, -35), "faction": "Elemental", "hp": 12, "atk": 3},
		],
		"containment_hall": [
			{"name": "Vessel Guardian", "hex": Vector2i(20, -30), "faction": "Construct", "hp": 25, "atk": 5, "stationary": true},
			{"name": "Elemental Worker", "hex": Vector2i(18, -28), "faction": "Elemental", "hp": 10, "atk": 3},
			{"name": "Elemental Worker", "hex": Vector2i(22, -32), "faction": "Elemental", "hp": 10, "atk": 3},
		],
		"the_leak": [
			{"name": "Water Sprite", "hex": Vector2i(10, -50), "faction": "Elemental", "hp": 8, "atk": 2},
			{"name": "Water Sprite", "hex": Vector2i(8, -48), "faction": "Elemental", "hp": 8, "atk": 2},
			{"name": "Water Sprite", "hex": Vector2i(12, -52), "faction": "Elemental", "hp": 8, "atk": 2},
		],
		"middle_works": [
			{"name": "Earth Golem", "hex": Vector2i(5, -60), "faction": "Elemental", "hp": 18, "atk": 4},
			{"name": "Earth Golem", "hex": Vector2i(-5, -60), "faction": "Elemental", "hp": 18, "atk": 4},
			{"name": "Air Wisp", "hex": Vector2i(0, -55), "faction": "Elemental", "hp": 10, "atk": 3},
			{"name": "Air Wisp", "hex": Vector2i(0, -65), "faction": "Elemental", "hp": 10, "atk": 3},
		],
		"the_crack": [
			{"name": "Earth Shambler", "hex": Vector2i(20, -60), "faction": "Elemental", "hp": 16, "atk": 4},
			{"name": "Earth Shambler", "hex": Vector2i(18, -58), "faction": "Elemental", "hp": 16, "atk": 4},
		],
		"upper_works": [
			{"name": "Fire Imp", "hex": Vector2i(5, -90), "faction": "Elemental", "hp": 12, "atk": 4},
			{"name": "Fire Imp", "hex": Vector2i(-5, -90), "faction": "Elemental", "hp": 12, "atk": 4},
			{"name": "Fire Imp", "hex": Vector2i(0, -85), "faction": "Elemental", "hp": 12, "atk": 4},
			{"name": "Reactor Core Guardian", "hex": Vector2i(0, -90), "faction": "Construct", "hp": 30, "atk": 6, "stationary": true},
		],
		"padlock_door": [
			{"name": "Padlock Guardian", "hex": Vector2i(0, -110), "faction": "Construct", "hp": 20, "atk": 4, "stationary": true},
		],
		"control_room": [
			{"name": "Chief Engineer Blix", "hex": Vector2i(0, -130), "faction": "Boss", "hp": 55, "atk": 6, "boss": true, "stationary": true, "view_range": 12, "combat_range": 2},
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
	
	print("[Floor8-Hex] %d hex enemies spawned" % hex_enemies.size())

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
		AudioManager.play_combat(8)
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		if ambush_bonus:
			_show_notification("🎯 AMBUSH! Player goes first!", Color(0.3, 0.9, 0.3))
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
	print("[Floor8-Hex] Combat initiated (ambush: %s)" % ambush)

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
				_show_notification("👁 %s spotted you!" % enemy.enemy_name, Color(0.9, 0.3, 0.3))
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
# OVERCLOCK METER SYSTEM
# ===================================================================

func _add_overclock(amount: int):
	overclock += amount
	_update_overclock_tier()
	_update_overclock_display()
	print("[Floor8] Overclock: %d (%s tier)" % [overclock, current_overclock_tier])

func _update_overclock_tier():
	var new_tier = "low"
	if overclock >= 800:
		new_tier = "critical"
	elif overclock >= 500:
		new_tier = "high"
	elif overclock >= 200:
		new_tier = "medium"
	
	if new_tier != current_overclock_tier:
		current_overclock_tier = new_tier
		_on_overclock_tier_change(new_tier)

func _on_overclock_tier_change(tier: String):
	match tier:
		"medium":
			_show_notification("⚡ OVERCLOCK 200+ — Misfires possible!", Color(0.9, 0.7, 0.3))
		"high":
			_show_notification("⚡ OVERCLOCK 500+ — Misfires common, cards cost +1!", Color(0.9, 0.5, 0.2))
		"critical":
			_show_notification("⚡ OVERCLOCK 800+ — REACTOR MELTDOWN IMMINENT!", Color(0.9, 0.2, 0.2))
			if blix_phase >= 3 and not blix_surrendered and not scram_pulled:
				reactor_critical = true
				meltdown_timer = 10
				_show_notification("⏱ MELTDOWN TIMER: 10 turns!", Color(0.9, 0.1, 0.1))
				_update_meltdown_display()

func _get_card_cost_penalty() -> int:
	match current_overclock_tier:
		"high", "critical": return 1
		_: return 0

func _get_misfire_chance() -> float:
	match current_overclock_tier:
		"medium": return 0.15
		"high": return 0.35
		"critical": return 0.50
		_: return 0.0

func _check_misfire() -> bool:
	if randf() < _get_misfire_chance():
		_show_notification("💥 MISFIRE! Random target!", Color(0.9, 0.5, 0.2))
		return true
	return false

func _update_overclock_display():
	if not overclock_ui:
		return
	var text = "⚡ OVERCLOCK: %d [%s]\n" % [overclock, current_overclock_tier.to_upper()]
	var penalty = _get_card_cost_penalty()
	var misfire = int(_get_misfire_chance() * 100)
	text += "Cards: +%d cost | Misfire: %d%%" % [penalty, misfire]
	
	var color = Color(0.8, 0.8, 0.8)
	match current_overclock_tier:
		"low": color = Color(0.5, 0.8, 0.5)
		"medium": color = Color(0.9, 0.7, 0.3)
		"high": color = Color(0.9, 0.5, 0.2)
		"critical": color = Color(0.9, 0.2, 0.2)
	
	overclock_ui.text = text
	overclock_ui.add_theme_color_override("font_color", color)

# ===================================================================
# ELEMENTAL CHARGE SYSTEM
# ===================================================================

func _add_elemental_charge(element: String, amount: int):
	if not elemental_charge.has(element):
		return
	elemental_charge[element] = mini(elemental_charge[element] + amount, ELEMENTAL_CHARGE_MAX)
	_update_elemental_display()
	print("[Floor8] %s charge: %d/%d" % [element, elemental_charge[element], ELEMENTAL_CHARGE_MAX])

func _consume_elemental_charge(element: String, amount: int) -> int:
	if not elemental_charge.has(element):
		return 0
	var consumed = mini(amount, elemental_charge[element])
	elemental_charge[element] -= consumed
	_update_elemental_display()
	return consumed

func _get_dominant_element() -> String:
	var max_charge = -1
	var dominant = "fire"
	for element in elemental_charge.keys():
		if elemental_charge[element] > max_charge:
			max_charge = elemental_charge[element]
			dominant = element
	return dominant

func _get_elemental_combat_bonus() -> Dictionary:
	return {
		"fire_damage_boost": elemental_charge["fire"] * 2,
		"water_healing": elemental_charge["water"] * 1,
		"earth_shield": elemental_charge["earth"] * 3,
		"air_speed": elemental_charge["air"] * 1,
	}

func _update_elemental_display():
	if not elemental_ui:
		return
	var text = "🔥%d 💧%d 🪨%d 🌪️%d" % [
		elemental_charge["fire"], elemental_charge["water"],
		elemental_charge["earth"], elemental_charge["air"]
	]
	var dominant = _get_dominant_element()
	var color = Color(0.8, 0.8, 0.8)
	match dominant:
		"fire": color = Color(0.9, 0.4, 0.2)
		"water": color = Color(0.2, 0.5, 0.9)
		"earth": color = Color(0.6, 0.4, 0.2)
		"air": color = Color(0.7, 0.8, 0.9)
	
	elemental_ui.text = text
	elemental_ui.add_theme_color_override("font_color", color)

# ===================================================================
# HAZARD ZONES
# ===================================================================

func _check_hazard_effects():
	if not player_node:
		return
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	if player_hex in fire_hazard_hexes:
		_show_notification("🔥 Fire hazard! Taking damage!", Color(0.9, 0.3, 0.2))
		if GameState.has_method("damage_player"):
			GameState.damage_player(2)
		_add_elemental_charge("fire", 1)
	
	if player_hex in water_hazard_hexes:
		# Slippery - random movement handled elsewhere
		_add_elemental_charge("water", 1)
	
	if player_hex in earth_hazard_hexes:
		# Slow movement - handled by reducing speed
		_add_elemental_charge("earth", 1)
		_show_notification("🪨 Earth hazard! Movement slowed!", Color(0.6, 0.4, 0.2))
	
	if player_hex in air_hazard_hexes:
		# Random push
		if randf() < 0.3:
			var dirs = HexTileMap.DIRECTIONS
			var push_dir = dirs[randi() % dirs.size()]
			var push_hex = player_hex + push_dir
			if hex_map.is_walkable(push_hex):
				player_node.global_position = hex_map.hex_to_world(push_hex)
				_show_notification("🌪️ Air gust pushes you!", Color(0.7, 0.8, 0.9))
		_add_elemental_charge("air", 1)

# ===================================================================
# CONTAINMENT VESSEL SYSTEM
# ===================================================================

func _init_vessels():
	vessel_states = {
		"containment_hall": [
			{"index": 0, "state": "contained", "elemental_type": "fire"},
			{"index": 1, "state": "contained", "elemental_type": "water"},
			{"index": 2, "state": "contained", "elemental_type": "earth"},
		],
		"upper_works": [
			{"index": 0, "state": "contained", "elemental_type": "air"},
			{"index": 1, "state": "contained", "elemental_type": "fire"},
		],
	}
	vessels_vented = 0
	vessels_overclocked = 0
	vessels_patched = 0
	all_vessels_vented = false

func _interact_with_vessel(vessel_index: int, action: String):
	if not vessel_states.has(current_room_id):
		return
	var vessels = vessel_states[current_room_id]
	if vessel_index >= vessels.size():
		return
	var vessel = vessels[vessel_index]
	if vessel["state"] != "contained":
		_show_notification("Vessel already %s" % vessel["state"], Color(0.7, 0.7, 0.7))
		return
	
	match action:
		"vent": _vent_vessel(vessel, vessel_index)
		"overclock": _overclock_vessel(vessel, vessel_index)
		"patch": _patch_vessel(vessel, vessel_index)

func _vent_vessel(vessel: Dictionary, index: int):
	vessel["state"] = "vented"
	vessels_vented += 1
	var elemental_type = vessel.get("elemental_type", "fire")
	_show_notification("💨 Vessel vented! %s elemental released!" % elemental_type, Color(0.5, 0.8, 0.5))
	_add_elemental_charge(elemental_type, 2)
	# Spawn combat with elemental
	var enemy_name = _elemental_type_to_enemy(elemental_type)
	_start_combat_with_enemies([enemy_name])
	_check_all_vessels_status()
	_update_containment_display()

func _overclock_vessel(vessel: Dictionary, index: int):
	vessel["state"] = "overclocked"
	vessels_overclocked += 1
	var elemental_type = vessel.get("elemental_type", "fire")
	_show_notification("⚡ OVERCLOCKED! %s elemental empowered (+4 CHARGE)!" % elemental_type, Color(0.9, 0.5, 0.2))
	_add_overclock(5)
	_add_elemental_charge(elemental_type, 4)
	# Spawn harder combat
	var enemy_name = _elemental_type_to_enemy(elemental_type)
	_start_combat_with_enemies([enemy_name, "Containment Goblin"])
	_update_overclock_display()
	_check_all_vessels_status()
	_update_containment_display()

func _patch_vessel(vessel: Dictionary, index: int):
	var gem_cost = 5
	if GameState.gems < gem_cost:
		_show_notification("Need %d Gems to patch vessel" % gem_cost, Color(0.9, 0.3, 0.3))
		return
	GameState.gems -= gem_cost
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	
	vessel["state"] = "patched"
	vessels_patched += 1
	_show_notification("🔧 Patched! Minor loot gained (%d gems spent)" % gem_cost, Color(0.3, 0.9, 0.3))
	# Give minor loot
	GameState.gems += 2
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	_check_all_vessels_status()
	_update_containment_display()

func _elemental_type_to_enemy(element: String) -> String:
	match element:
		"fire": return "Fire Imp"
		"water": return "Water Sprite"
		"earth": return "Earth Shambler"
		"air": return "Air Wisp"
		_: return "Fire Imp"

func _check_all_vessels_status():
	var total = 0
	var vented = 0
	for room in vessel_states.keys():
		for v in vessel_states[room]:
			total += 1
			if v["state"] == "vented":
				vented += 1
	if total > 0 and vented == total:
		all_vessels_vented = true
		_show_notification("💨 ALL VESSELS VENTED! Safe path to boss!", Color(0.9, 0.7, 0.3))

func _update_containment_display():
	if not containment_ui:
		return
	var current_room_vessels = vessel_states.get(current_room_id, [])
	var contained = 0
	for v in current_room_vessels:
		if v["state"] == "contained":
			contained += 1
	if current_room_vessels.is_empty():
		containment_ui.text = "🔧 No vessels in this room"
	else:
		containment_ui.text = "🔧 Vessels: %d contained | %d vented | %d overclocked | %d patched" % [
			contained, vessels_vented, vessels_overclocked, vessels_patched
		]

func _start_combat_with_enemies(enemy_names: Array):
	if in_combat:
		return
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		return
	var combat_data = []
	for name in enemy_names:
		var data = CombatManager.EnemyData.new(name, 12, 3, 0, [CombatManager.EnemyAction.ATTACK], [])
		combat_data.append(data)
	in_combat = true
	AudioManager.play_combat(8)
	combat_manager.start_combat(combat_data, GameState.player_deck)
	var ui = get_node_or_null("CombatUI")
	if ui:
		ui.setup(combat_manager)
		ui.visible = true

# ===================================================================
# GOBLIN MORALE SYSTEM
# ===================================================================

func _boost_goblin_morale(amount: int):
	goblin_morale = mini(goblin_morale + amount, 100)
	if goblin_morale >= 80:
		_show_notification("😊 Goblin morale HIGH! Shop discounts + combat help!", Color(0.3, 0.9, 0.3))
	elif goblin_morale <= 20:
		goblin_morale_broken = true
		_show_notification("😠 Goblin morale BROKEN! Goblins are now hostile!", Color(0.9, 0.3, 0.3))
		# Convert goblin NPCs to enemies
		_convert_goblins_to_enemies()
	else:
		_show_notification("😐 Goblin morale: %d/100" % goblin_morale, Color(0.8, 0.8, 0.5))

func _convert_goblins_to_enemies():
	# Spawn goblin enemies in Union Hall, Lower Works, Middle Works
	var goblin_spawns = [
		{"hex": Vector2i(-18, -30), "name": "Rogue Goblin"},
		{"hex": Vector2i(-22, -30), "name": "Rogue Goblin"},
		{"hex": Vector2i(-18, -60), "name": "Rogue Goblin"},
		{"hex": Vector2i(-22, -60), "name": "Rogue Goblin"},
	]
	for spawn in goblin_spawns:
		var enemy = HexEnemy.new(
			"goblin_rogue_%d" % hex_enemies.size(),
			spawn["name"],
			spawn["hex"],
			"Goblin"
		)
		enemy.hp = 10
		enemy.max_hp = 10
		enemy.attack = 3
		_add_enemy(enemy, spawn["hex"])
	_show_notification("😠 Goblins turn hostile!", Color(0.9, 0.3, 0.3))

func _get_shop_discount() -> float:
	if goblin_morale >= 80:
		return 0.75
	elif goblin_morale >= 50:
		return 0.90
	elif goblin_morale <= 20:
		return 1.25
	return 1.0

# ===================================================================
# BOSS SYSTEM — Chief Engineer Blix (3 Phases)
# ===================================================================

func _start_boss_fight():
	blix_phase = 1
	blix_hp = blix_max_hp
	blix_surrendered = false
	scram_pulled = false
	reactor_critical = false
	meltdown_timer = 10
	
	var intro = "Chief Engineer Blix, at your service!\nI've lost three arms, two legs, one eye, and my sense of fear to this reactor.\nAnd I've never been happier!\nNow — are you here to vent, overclock, or explode?"
	
	if blix_recognizes_contracts:
		intro += "\n\nOoh, contracts! I got a contract too! Wanna trade?"
	elif blix_indifferent:
		intro += "\n\nDemons are boring. They don't explode. I like exploding."
	
	if shaman_fascinated:
		intro += "\n\nThe Shaman told me about you. Something about... void? Fascinating!"
	
	_show_dialogue("Chief Engineer Blix", intro)
	
	blix_ui.visible = true
	_update_blix_display()
	_update_meltdown_display()
	print("[Floor8] Boss fight started — Phase 1: Normal Combat")

func _on_blix_damage_taken(damage: int):
	blix_hp -= damage
	if blix_hp <= 35 and blix_phase == 1:
		blix_phase = 2
		_on_blix_phase_2()
	elif blix_hp <= 15 and blix_phase == 2:
		blix_phase = 3
		_on_blix_phase_3()
	_update_blix_display()

func _on_blix_phase_2():
	_show_dialogue("Chief Engineer Blix", "The reactor's singing! That's bad!\nWhen it sings, it means it's about to hit the high note!\nPULL THE LEVER! SCRAM IT!\nUnless... you want to see what happens?")
	_show_notification("😈 Blix enters Phase 2 — The Meltdown!", Color(0.9, 0.5, 0.2))
	_add_overclock(5)

func _on_blix_phase_3():
	blix_phase = 3
	reactor_critical = true
	
	if overclock > 800 and not blix_surrendered:
		_blix_surrender()
		return
	
	_show_dialogue("Chief Engineer Blix", "PULL THE SCRAM LEVER!\nEverything stops!\nOr... let it blow. Ten turns.\nPure DPS race.")
	_show_notification("⏱ MELTDOWN TIMER: 10 turns! Pull SCRAM or defeat Blix!", Color(0.9, 0.2, 0.2))
	meltdown_ui.visible = true
	_update_meltdown_display()
	print("[Floor8] Phase 3: The Scram")

func _blix_surrender():
	blix_surrendered = true
	blix_hp = 0
	_show_dialogue("Chief Engineer Blix", "You're at... over eight HUNDRED?\nHow are you still standing?\nThe walls are melting just looking at you.\nOkay. You win. Take the core.\nI'm going to find a new job.\nSomewhere with fewer explosions.\nLike a volcano.")
	GameState.elemental_core_held = true
	_show_notification("🔥 ELEMENTAL CORE acquired! +1 fire damage all cards!", Color(0.9, 0.4, 0.2))
	_end_boss_combat(true)

func _pull_scram_lever():
	if scram_pulled or blix_phase < 3:
		return
	scram_pulled = true
	_show_notification("☢ SCRAM! Blix dies instantly! You take 15 radiation damage!", Color(0.9, 0.9, 0.3))
	if GameState.has_method("damage_player"):
		GameState.damage_player(15)
	blix_hp = 0
	_end_boss_combat(true)

func _advance_meltdown_timer():
	if not reactor_critical or scram_pulled or blix_surrendered:
		return
	meltdown_timer -= 1
	_show_notification("⏱ MELTDOWN: %d turns remaining!" % meltdown_timer, Color(0.9, 0.2, 0.2))
	if meltdown_timer <= 0:
		_meltdown_explosion()
	_update_meltdown_display()

func _meltdown_explosion():
	_show_notification("💥 REACTOR EXPLOSION!", Color(0.9, 0.1, 0.1))
	if GameState.has_method("damage_player"):
		GameState.damage_player(50)
	_show_notification("💥 Meltdown damage! -50 HP!", Color(0.9, 0.1, 0.1))

func _update_blix_display():
	if not blix_ui:
		return
	var text = ""
	match blix_phase:
		1: text = "BLIX: Phase 1 — The Shift | %d/%d HP" % [blix_hp, blix_max_hp]
		2: text = "BLIX: Phase 2 — The Meltdown | %d/%d HP" % [blix_hp, blix_max_hp]
		3:
			if blix_surrendered:
				text = "BLIX: SURRENDERED"
			elif scram_pulled:
				text = "BLIX: SCRAMMED"
			else:
				text = "BLIX: Phase 3 — The Scram | %d/%d HP" % [blix_hp, blix_max_hp]
	
	blix_ui.text = text
	blix_ui.visible = true
	
	var color = Color(0.9, 0.5, 0.2)
	if blix_surrendered:
		color = Color(0.3, 0.9, 0.3)
	elif scram_pulled:
		color = Color(0.9, 0.9, 0.3)
	blix_ui.add_theme_color_override("font_color", color)

func _update_meltdown_display():
	if not meltdown_ui:
		return
	if not reactor_critical or blix_phase < 3:
		meltdown_ui.visible = false
		return
	if blix_surrendered or scram_pulled:
		meltdown_ui.visible = false
		return
	
	meltdown_ui.text = "⏱ MELTDOWN: %d turns!" % meltdown_timer
	meltdown_ui.visible = true
	
	var color = Color(0.9, 0.7, 0.3)
	if meltdown_timer <= 5:
		color = Color(0.9, 0.3, 0.2)
	if meltdown_timer <= 3:
		color = Color(0.9, 0.1, 0.1)
	meltdown_ui.add_theme_color_override("font_color", color)

func _end_boss_combat(victory: bool):
	if victory:
		if blix_surrendered:
			_show_dialogue("The Tower", "Blix surrenders.\nThe elemental core is yours.\nThe path to Floor 9 opens.\nYou carry fire within you now.")
		elif scram_pulled:
			_show_dialogue("The Tower", "The reactor is dead.\nBlix is dead.\nThe forge is silent.\nThe path to Floor 9 opens — but something is missing.")
		else:
			_show_dialogue("The Tower", "Blix falls.\nThe reactor groans but holds.\nThe path to Floor 9 opens.\nRadiation lingers in your bones.")
		
		GameState.gems += 100
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
		
		# Apply cross-floor effects to Floor 9
		_apply_floor9_effects()
		GameState.save_game()
		_show_floor_transition_prompt()
		await get_tree().create_timer(3.0).timeout
		_ascend_to_next_floor()
	else:
		_show_notification("💀 Defeated by Chief Engineer Blix", Color(0.9, 0.3, 0.3))

func _apply_floor9_effects():
	if scram_pulled:
		GameState.floor9_no_power = true
		GameState.floor9_foreman_enraged = true
	if not scram_pulled and blix_hp <= 0:
		GameState.floor9_radiation_debuff = true
		GameState.floor9_elementals_kin = true
	if blix_surrendered:
		GameState.elemental_core_held = true
	if all_vessels_vented:
		GameState.floor9_elementals_loose = true

# ===================================================================
# PADLOCK DOOR SYSTEM
# ===================================================================

func _pick_padlock():
	if padlock_door_open:
		_show_notification("Door already open", Color(0.7, 0.7, 0.7))
		return
	if overclock < 5:
		_show_notification("Need 5 Overclock to pick a padlock", Color(0.9, 0.3, 0.3))
		return
	overclock -= 5
	padlocks_remaining -= 1
	_show_notification("🔓 Padlock picked! %d remaining" % padlocks_remaining, Color(0.3, 0.9, 0.3))
	if randf() < 0.3:
		_show_notification("🚨 ALARM! Security incoming!", Color(0.9, 0.3, 0.3))
		_start_combat_with_enemies(["Security Drone", "Security Drone"])
	if padlocks_remaining <= 0:
		_open_padlock_door()
	_update_overclock_display()

func _use_padlock_key(room_id: String):
	if room_id in padlock_keys_found:
		_show_notification("Key from %s already used" % room_id, Color(0.7, 0.7, 0.7))
		return
	padlock_keys_found.append(room_id)
	padlocks_remaining -= 1
	_show_notification("🔑 Key used! %d padlocks remaining" % padlocks_remaining, Color(0.3, 0.9, 0.3))
	if padlocks_remaining <= 0:
		_open_padlock_door()

func _open_padlock_door():
	padlock_door_open = true
	_show_notification("🚪 PADLOCK DOOR OPEN! Control Room accessible!", Color(0.3, 0.9, 0.3))
	var connections = portal_connections.get("padlock_door", {})
	connections["up"] = "control_room"

func _loot_padlock_cache():
	if cache_looted:
		_show_notification("Cache already looted", Color(0.7, 0.7, 0.7))
		return
	cache_looted = true
	_show_notification("💰 Cache looted! Overclocked cards + 25 gems!", Color(0.9, 0.7, 0.3))
	GameState.gems += 25
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)

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
	
	# Overclock UI
	overclock_ui = Label.new()
	overclock_ui.name = "OverclockUI"
	overclock_ui.position = Vector2(20, 20)
	overclock_ui.size = Vector2(400, 80)
	overclock_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(overclock_ui)
	
	# Elemental charge UI
	elemental_ui = Label.new()
	elemental_ui.name = "ElementalUI"
	elemental_ui.position = Vector2(20, 110)
	elemental_ui.size = Vector2(350, 60)
	elemental_ui.add_theme_font_size_override("font_size", 11)
	main_ui.add_child(elemental_ui)
	
	# Containment vessel UI
	containment_ui = Label.new()
	containment_ui.name = "ContainmentUI"
	containment_ui.position = Vector2(20, 180)
	containment_ui.size = Vector2(350, 40)
	containment_ui.add_theme_font_size_override("font_size", 11)
	main_ui.add_child(containment_ui)
	
	# Blix / boss UI
	blix_ui = Label.new()
	blix_ui.name = "BlixUI"
	blix_ui.position = Vector2(20, 230)
	blix_ui.size = Vector2(400, 40)
	blix_ui.add_theme_font_size_override("font_size", 12)
	blix_ui.visible = false
	main_ui.add_child(blix_ui)
	
	# Meltdown timer UI
	meltdown_ui = Label.new()
	meltdown_ui.name = "MeltdownUI"
	meltdown_ui.position = Vector2(20, 280)
	meltdown_ui.size = Vector2(400, 40)
	meltdown_ui.add_theme_font_size_override("font_size", 12)
	meltdown_ui.visible = false
	main_ui.add_child(meltdown_ui)
	
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
	
	_update_overclock_display()
	_update_elemental_display()
	_update_containment_display()

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
	prompt.text = "Press [S] to Ascend to Floor 9 — The Bone Forges"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

func _ascend_to_next_floor():
	print("[Floor8] Ascending to Floor 9...")
	get_tree().change_scene_to_file("res://scenes/Floor9.tscn")

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
	_check_hazard_effects()
	_check_hazard_rewards()

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
	print("[Floor8-Hex] Entered: %s" % display)
	if room_indicator:
		room_indicator.text = "📍 %s" % display
		var color = Color(0.7, 0.7, 0.7)
		match room_id:
			"loading_bay":      color = Color(0.6, 0.6, 0.7)
			"lower_works":      color = Color(0.9, 0.5, 0.3)
			"break_room":       color = Color(0.5, 0.7, 0.5)
			"containment_hall": color = Color(0.7, 0.6, 0.4)
			"the_leak":         color = Color(0.3, 0.5, 0.9)
			"middle_works":     color = Color(0.6, 0.6, 0.5)
			"union_hall":       color = Color(0.5, 0.7, 0.5)
			"the_crack":        color = Color(0.6, 0.4, 0.2)
			"upper_works":      color = Color(0.9, 0.4, 0.2)
			"padlock_door":     color = Color(0.7, 0.5, 0.7)
			"control_room":     color = Color(0.9, 0.3, 0.3)
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
	if target_room == "control_room" and not padlock_door_open:
		_show_notification("🔒 The Control Room is sealed. Open the Padlock Door first.")
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
		"loading_bay":      msg = "Loading Bay. The factory breathes."
		"lower_works":      msg = "Lower Works. Fire and water churn below."
		"break_room":       msg = "Break Room. Goblins rest here."
		"containment_hall": msg = "Containment Hall. Vessels hum with power."
		"the_leak":         msg = "The Leak. Water hisses against metal."
		"middle_works":     msg = "Middle Works. Earth and air meet."
		"union_hall":       msg = "Union Hall. Goblin voices echo."
		"the_crack":        msg = "The Crack. The floor is unstable."
		"upper_works":      msg = "Upper Works. The reactor core burns."
		"padlock_door":     msg = "Padlock Door. Seventeen locks."
		"control_room":     msg = "Control Room. Blix is waiting."
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
			"shop_save":          _show_interact_prompt("[S] Shop / Save")
			"vessel":             _show_interact_prompt("[S] Interact with Vessel")
			"goblin_worker":      _show_interact_prompt("[S] Talk to Goblin Worker")
			"goblin_leader":      _show_interact_prompt("[S] Talk to Goblin Leader")
			"goblin_resting":     _show_interact_prompt("[S] Shop (Goblin Resting)")
			"charge_station":     _show_interact_prompt("[S] Use Charge Station")
			"overclock_monitor":  _show_interact_prompt("[S] Check Overclock")
			"scram_button":       _show_interact_prompt("[S] PULL SCRAM LEVER")
			"padlock_door":       _show_interact_prompt("[S] Interact with Padlock Door")
			"padlock_key":        _show_interact_prompt("[S] Pick up Key")
			"dimensional_anchor": _show_interact_prompt("[S] Dimensional Anchor")
			_:
				_hide_interact_prompt()
	elif tile == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir == "exit":
			if current_room_id == "loading_bay":
				_show_interact_prompt("[S] Return to Floor 7")
			elif current_room_id == "control_room":
				_show_interact_prompt("[S] Ascend to Floor 9")
			else:
				_hide_interact_prompt()
		else:
			_hide_interact_prompt()
	else:
		_hide_interact_prompt()

func _get_object_id_at_hex(hex: Vector2i) -> String:
	var object_map = {
		Vector2i(5, 0):       "shop_save",
		Vector2i(22, -30):    "vessel",
		Vector2i(18, -28):    "vessel",
		Vector2i(24, -32):    "vessel",
		Vector2i(2, -90):     "vessel",
		Vector2i(-2, -92):    "vessel",
		Vector2i(-2, -30):    "goblin_worker",
		Vector2i(2, -28):     "goblin_worker",
		Vector2i(-2, -60):    "goblin_worker",
		Vector2i(2, -62):     "goblin_worker",
		Vector2i(-20, -60):   "goblin_leader",
		Vector2i(-18, -30):   "goblin_resting",
		Vector2i(-5, -30):    "charge_station",
		Vector2i(-5, -60):    "charge_station",
		Vector2i(5, -90):     "charge_station",
		Vector2i(-5, -90):    "overclock_monitor",
		Vector2i(5, -130):    "scram_button",
		Vector2i(0, -110):    "padlock_door",
		Vector2i(8, 0):       "padlock_key",
		Vector2i(-8, -30):    "padlock_key",
		Vector2i(12, -30):    "padlock_key",
		Vector2i(12, -50):    "padlock_key",
		Vector2i(-8, -60):    "padlock_key",
		Vector2i(22, -60):    "padlock_key",
		Vector2i(-8, -90):    "padlock_key",
		Vector2i(5, -110):    "padlock_key",
		Vector2i(-5, -130):   "dimensional_anchor",
	}
	return object_map.get(hex, "")

func _interact_at_hex(hex: Vector2i):
	var obj_id = _get_object_id_at_hex(hex)
	match obj_id:
		"shop_save":
			_open_machinist_shop()
			_save_game()
		"vessel":
			_show_vessel_menu()
		"goblin_worker":
			_show_dialogue("Goblin Worker", "We work hard! Don't make Blix mad!\n...she's already mad. But don't make her MADDER.")
			_boost_goblin_morale(5)
		"goblin_leader":
			_show_dialogue("Goblin Leader", "Listen up, greenskins!\nWe work together, we live together!\nAnyone flees, I PERSONALLY feed them to the reactor!\n...it's a good motivator.")
			_boost_goblin_morale(15)
		"goblin_resting":
			_open_machinist_shop()
		"charge_station":
			_spend_elemental_charge_at_station()
		"overclock_monitor":
			_show_notification("Overclock: %d | Tier: %s | Dominant Element: %s" % [overclock, current_overclock_tier, _get_dominant_element()], Color(0.3, 0.9, 0.3))
		"scram_button":
			if blix_phase >= 3:
				_pull_scram_lever()
			else:
				_show_notification("Scram lever locked — reactor not critical", Color(0.7, 0.7, 0.7))
		"padlock_door":
			_interact_padlock_door()
		"padlock_key":
			_use_padlock_key(current_room_id)
			_show_notification("🔑 Key found in %s!" % current_room_id, Color(0.3, 0.9, 0.3))
		"dimensional_anchor":
			_show_notification("Dimensional Anchor active. Floor 9 portal open.", Color(0.3, 0.9, 0.3))
	
	# Check for portal interaction
	if hex_map.get_tile(hex) == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(hex)
		if portal_dir == "exit":
			if current_room_id == "loading_bay":
				get_tree().change_scene_to_file("res://scenes/Floor7.tscn")
			elif current_room_id == "control_room":
				get_tree().change_scene_to_file("res://scenes/Floor9.tscn")

func _show_vessel_menu():
	var current_room_vessels = vessel_states.get(current_room_id, [])
	if current_room_vessels.is_empty():
		_show_notification("No vessels in this room.", Color(0.7, 0.7, 0.7))
		return
	var msg = "Vessel Menu:\n"
	for i in range(current_room_vessels.size()):
		var v = current_room_vessels[i]
		msg += "[%d] %s (%s) — %s\n" % [i+1, v["elemental_type"], v["state"], "[V]ent [O]verclock [P]atch"]
	_show_dialogue("Containment Vessel", msg)

func _interact_padlock_door():
	if padlock_door_open:
		_show_notification("Door is already open.", Color(0.7, 0.7, 0.7))
		return
	var msg = "Padlock Door: %d locks remaining.\n" % padlocks_remaining
	msg += "[K] Use Key | [P] Pick Lock (5 OC, 30%% alarm) | [C] Check Cache"
	_show_dialogue("Padlock Door", msg)

func _spend_elemental_charge_at_station():
	var dominant = _get_dominant_element()
	if elemental_charge[dominant] <= 0:
		_show_notification("No %s charge to spend!" % dominant, Color(0.9, 0.3, 0.3))
		return
	var cost = 3
	var consumed = _consume_elemental_charge(dominant, cost)
	match dominant:
		"fire": _show_notification("🔥 Fire buff! +%d damage next combat!" % (consumed * 2), Color(0.9, 0.4, 0.2))
		"water": _show_notification("💧 Water heal! +%d HP!" % consumed, Color(0.2, 0.5, 0.9))
		"earth": _show_notification("🪨 Earth shield! +%d armor!" % (consumed * 3), Color(0.6, 0.4, 0.2))
		"air": _show_notification("🌪️ Air speed! +%d moves!" % consumed, Color(0.7, 0.8, 0.9))

func _save_game():
	if GameState.has_method("save_game"):
		GameState.save_game()
		_show_notification("Progress saved.", Color(0.3, 0.9, 0.3))

func _random_elemental_type() -> String:
	var types = ["fire", "water", "earth", "air"]
	return types[randi() % types.size()]

# ===================================================================
# FLOOR SPECIFIC SETUP
# ===================================================================

func _setup_floor_specific():
	# Initialize overclock
	overclock = 0
	current_overclock_tier = "low"
	
	# Initialize elemental charge
	elemental_charge = {"fire": 0, "water": 0, "earth": 0, "air": 0}
	
	# Initialize vessels
	_init_vessels()
	
	# Check cross-floor bleed from Floor 7
	if GameState.get_value("marked_debuff_active", false):
		blix_recognizes_contracts = true
		_show_notification("📜 Blix recognizes your demon contracts", Color(0.9, 0.3, 0.9))
	
	if GameState.get_value("pacts_broken_count", 0) > 0:
		blix_indifferent = true
	
	if GameState.get_value("void_bond_active", false):
		shaman_fascinated = true
	
	if GameState.get_value("souls_enslaved_count", 0) > 0:
		elementals_angry = true
		_show_notification("⚠ Elementals are angrier (+1 CHARGE)", Color(0.9, 0.7, 0.3))
	
	# Padlock door
	padlocks_remaining = 17
	padlock_keys_found = []
	padlock_door_open = false
	cache_looted = false
	
	print("[Floor8] Setup complete. OC: %d | Vessels: %d | Blix contracts: %s" % [
		overclock, vessels_vented + vessels_overclocked + vessels_patched, blix_recognizes_contracts
	])

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
				_check_hazard_effects()
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
var post_combat_ui: PostCombatUI
var machinist_shop: MachinistShopUI
		if ui and ui.has_method("process"):
			ui.process(_delta)

func _on_post_combat_closed():
	in_ui = false
	print("[Floor8-Hex] Post-combat closed, resuming")

