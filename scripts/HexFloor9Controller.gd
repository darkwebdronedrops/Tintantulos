extends Node2D

# ===================================================================
# FLOOR 9 CONTROLLER — Hex-Based — The Bone Forges
# ===================================================================
# Factory grid with conveyor belt flow from west to east
# 11 rooms: Loading Dock → Assembly Line → Break Station → Furnace Room
# → Foundry Pit → Foreman's Office, with north/south branches
# Unique systems: Salvage & Crafting, Soul Furnaces, Conveyor Belts,
#                The Foreman Eternal boss, Cross-floor bleed
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "loading_dock"
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
# Floor 9 — Salvage & Crafting
# -------------------------------------------------------------------
var bone_count: int = 0
var gear_count: int = 0
var companions_built: Array[Dictionary] = []
var companions_built_total: int = 0
var max_companions: int = 3

# -------------------------------------------------------------------
# Floor 9 — Soul Furnaces
# -------------------------------------------------------------------
var souls_freed: int = 0
var soul_debt: int = 0
var liberator_status: bool = false
var furnaces_destroyed: int = 0
var furnaces_used: int = 0
var all_furnaces_destroyed: bool = false

# -------------------------------------------------------------------
# Floor 9 — Conveyor Belts
# -------------------------------------------------------------------
var conveyor_direction: String = "east"
var on_conveyor: bool = false
var conveyor_speed: float = 2.0
var conveyor_maze_solved: bool = false
var conveyor_hexes: Dictionary = {}  # room_id -> Array[Vector2i]
var conveyor_switches: Dictionary = {} # room_id -> Array[Vector2i]

# -------------------------------------------------------------------
# Floor 9 — Boss (The Foreman Eternal)
# -------------------------------------------------------------------
var foreman_phase: int = 1
var foreman_hp: int = 65
var foreman_max_hp: int = 65
var foreman_enraged: bool = false
var foreman_start_hp_percent: float = 1.0
var inspection_turn_counter: int = 0
var skull_case_destroyed: bool = false
var skull_case_hp: int = 15
var strike_team_built: bool = false

# -------------------------------------------------------------------
# Floor 9 — Cross-Floor Bleed from Floor 8
# -------------------------------------------------------------------
var no_power: bool = false
var radiation_active: bool = false
var elemental_core_held: bool = false
var elementals_loose: bool = false
var goblin_refugees: bool = false
var radiation_hp_loss: int = 0

# -------------------------------------------------------------------
# Room Data — Factory Grid
# -------------------------------------------------------------------
var room_data: Dictionary = {
	"loading_dock":     {"center": Vector2i(-60, 0),   "radius": 15, "encounter": "none",       "display": "Loading Dock",      "safe": true},
	"assembly_line":    {"center": Vector2i(-30, 0),   "radius": 14, "encounter": "construct",  "display": "Assembly Line",     "safe": false},
	"break_station":    {"center": Vector2i(0, 0),      "radius": 14, "encounter": "none",       "display": "Break Station",     "safe": true},
	"furnace_room":     {"center": Vector2i(30, 0),     "radius": 14, "encounter": "undead",     "display": "Furnace Room",      "safe": false},
	"foundry_pit":      {"center": Vector2i(60, 0),      "radius": 14, "encounter": "elite",      "display": "Foundry Pit",       "safe": false},
	"foremans_office":  {"center": Vector2i(90, 0),     "radius": 12, "encounter": "boss",       "display": "Foreman's Office",  "safe": false},
	"gear_works":       {"center": Vector2i(-30, -30),  "radius": 12, "encounter": "construct",  "display": "Gear Works",        "safe": false},
	"bone_yard":        {"center": Vector2i(-30, 30),   "radius": 12, "encounter": "undead",     "display": "Bone Yard",         "safe": false},
	"quality_control":  {"center": Vector2i(0, -30),    "radius": 12, "encounter": "miniboss",   "display": "Quality Control",   "safe": false},
	"conveyor_maze":    {"center": Vector2i(30, 30),    "radius": 14, "encounter": "puzzle",     "display": "Conveyor Maze",     "safe": false},
	"locker_room":      {"center": Vector2i(60, 30),     "radius": 10, "encounter": "none",       "display": "Locker Room",       "safe": true},
}

var portal_connections: Dictionary = {
	"loading_dock":     {"east": "assembly_line",    "exit": "floor8_exit"},
	"assembly_line":    {"west": "loading_dock",   "east": "break_station",  "north": "gear_works",    "south": "bone_yard"},
	"break_station":    {"west": "assembly_line",  "east": "furnace_room",   "north": "quality_control"},
	"furnace_room":     {"west": "break_station",  "east": "foundry_pit",    "south": "conveyor_maze"},
	"foundry_pit":      {"west": "furnace_room", "south": "locker_room",  "east": "foremans_office"},
	"foremans_office":  {"west": "foundry_pit",  "southwest": "locker_room", "exit": "floor10_entrance"},
	"gear_works":       {"south": "assembly_line", "east": "quality_control"},
	"bone_yard":        {"north": "assembly_line", "east": "conveyor_maze"},
	"quality_control":  {"west": "gear_works",   "south": "break_station",  "east": "locker_room"},
	"conveyor_maze":    {"west": "bone_yard",    "north": "furnace_room",   "east": "locker_room"},
	"locker_room":      {"west": "conveyor_maze","north": "foundry_pit",    "northwest": "quality_control", "east": "foremans_office"},
}

var portal_offsets: Dictionary = {
	"north": Vector2i(0, -15), "south": Vector2i(0, 15),
	"east":  Vector2i(15, 0),   "west":  Vector2i(-15, 0),
	"northeast": Vector2i(10, -10), "northwest": Vector2i(-10, -10),
	"southeast": Vector2i(10, 10),  "southwest": Vector2i(-10, 10),
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
var salvage_ui: Label
var furnace_ui: Label
var conveyor_ui: Label
var foreman_ui: Label
var liberator_ui: Label
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
	GameState.set_current_floor(9)
	print("[Floor9-Hex] current_floor set to 9")
	_generate_hex_layout()
	print("[Floor9-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_enemies()
	_setup_post_combat_ui()  # Post-combat reward screen
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(9)
	_enter_room("loading_dock")

# ===================================================================
# HEX LAYOUT — Factory Grid
# ===================================================================

func _generate_hex_layout():
	hex_map.clear_grid()
	
	# === MAIN CONVEYOR LINE (west to east) ===
	_generate_room_hex("loading_dock",     Vector2i(-60, 0),   15, [Vector2i(-60, 15), Vector2i(-45, 0)])
	_generate_room_hex("assembly_line",    Vector2i(-30, 0),   14, [Vector2i(-45, 0), Vector2i(-15, 0), Vector2i(-30, -16), Vector2i(-30, 16)])
	_generate_room_hex("break_station",    Vector2i(0, 0),     14, [Vector2i(-15, 0), Vector2i(15, 0), Vector2i(0, -16)])
	_generate_room_hex("furnace_room",     Vector2i(30, 0),    14, [Vector2i(15, 0), Vector2i(45, 0), Vector2i(30, 16)])
	_generate_room_hex("foundry_pit",      Vector2i(60, 0),    14, [Vector2i(45, 0), Vector2i(75, 0), Vector2i(60, 16)])
	_generate_room_hex("foremans_office",  Vector2i(90, 0),    12, [Vector2i(75, 0), Vector2i(90, -14), Vector2i(80, 10)])
	
	# === NORTH BRANCH ===
	_generate_room_hex("gear_works",       Vector2i(-30, -30), 12, [Vector2i(-30, -16), Vector2i(-18, -30), Vector2i(-42, -30)])
	_generate_room_hex("quality_control",  Vector2i(0, -30),   12, [Vector2i(0, -16), Vector2i(12, -30), Vector2i(-12, -30)])
	
	# === SOUTH BRANCH ===
	_generate_room_hex("bone_yard",        Vector2i(-30, 30),  12, [Vector2i(-30, 16), Vector2i(-18, 30), Vector2i(-42, 30)])
	_generate_room_hex("conveyor_maze",    Vector2i(30, 30),   14, [Vector2i(30, 16), Vector2i(18, 30), Vector2i(42, 30)])
	_generate_room_hex("locker_room",      Vector2i(60, 30),   10, [Vector2i(60, 16), Vector2i(48, 30), Vector2i(72, 30)])
	
	# === CORRIDORS ===
	# Loading Dock -> Assembly Line
	_generate_corridor_hex(Vector2i(-60, 15), Vector2i(-45, 0), 2)
	# Assembly Line -> Break Station
	_generate_corridor_hex(Vector2i(-15, 0), Vector2i(0, 0), 2)
	# Break Station -> Furnace Room
	_generate_corridor_hex(Vector2i(15, 0), Vector2i(30, 0), 2)
	# Furnace Room -> Foundry Pit
	_generate_corridor_hex(Vector2i(45, 0), Vector2i(60, 0), 2)
	# Foundry Pit -> Foreman's Office
	_generate_corridor_hex(Vector2i(75, 0), Vector2i(90, 0), 2)
	# Assembly Line -> Gear Works (north)
	_generate_corridor_hex(Vector2i(-30, -16), Vector2i(-30, -18), 2)
	# Assembly Line -> Bone Yard (south)
	_generate_corridor_hex(Vector2i(-30, 16), Vector2i(-30, 18), 2)
	# Gear Works -> Quality Control
	_generate_corridor_hex(Vector2i(-18, -30), Vector2i(-12, -30), 2)
	# Quality Control -> Break Station
	_generate_corridor_hex(Vector2i(0, -16), Vector2i(0, -14), 2)
	# Bone Yard -> Conveyor Maze
	_generate_corridor_hex(Vector2i(-18, 30), Vector2i(18, 30), 2)
	# Furnace Room -> Conveyor Maze
	_generate_corridor_hex(Vector2i(30, 16), Vector2i(30, 18), 2)
	# Foundry Pit -> Locker Room
	_generate_corridor_hex(Vector2i(60, 16), Vector2i(60, 18), 2)
	# Quality Control -> Locker Room
	_generate_corridor_hex(Vector2i(12, -30), Vector2i(48, 30), 3)
	# Locker Room -> Foreman's Office (shortcut)
	_generate_corridor_hex(Vector2i(72, 30), Vector2i(80, 10), 2)
	
	# === CONVEYOR BELT TILES (tracked separately, rendered as TILE_FLOOR) ===
	# Assembly Line — conveyor pushes east
	conveyor_hexes["assembly_line"] = []
	for q in range(-40, -20):
		for r in range(-4, 5):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.4:
				conveyor_hexes["assembly_line"].append(hex)
	# Furnace Room — conveyor pushes east
	conveyor_hexes["furnace_room"] = []
	for q in range(20, 40):
		for r in range(-4, 5):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.4:
				conveyor_hexes["furnace_room"].append(hex)
	# Foundry Pit — conveyor pushes south
	conveyor_hexes["foundry_pit"] = []
	for q in range(50, 70):
		for r in range(-10, 10):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.3:
				conveyor_hexes["foundry_pit"].append(hex)
	# Gear Works — conveyor pushes south
	conveyor_hexes["gear_works"] = []
	for q in range(-40, -20):
		for r in range(-40, -20):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.3:
				conveyor_hexes["gear_works"].append(hex)
	# Bone Yard — conveyor pushes north
	conveyor_hexes["bone_yard"] = []
	for q in range(-40, -20):
		for r in range(20, 40):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.3:
				conveyor_hexes["bone_yard"].append(hex)
	# Conveyor Maze — random directions (hazard puzzle)
	conveyor_hexes["conveyor_maze"] = []
	for q in range(20, 40):
		for r in range(20, 40):
			var hex = Vector2i(q, r)
			if hex_map.get_tile(hex) == HexTileMap.TILE_FLOOR and randf() < 0.5:
				conveyor_hexes["conveyor_maze"].append(hex)
	
	# === CONVEYOR SWITCHES (object tiles) ===
	conveyor_switches["assembly_line"] = [Vector2i(-25, 0)]
	conveyor_switches["furnace_room"] = [Vector2i(25, 0)]
	conveyor_switches["conveyor_maze"] = [Vector2i(25, 25), Vector2i(35, 35)]
	for room in conveyor_switches.keys():
		for hex in conveyor_switches[room]:
			hex_map.set_tile(hex, HexTileMap.TILE_OBJECT)
	
	# === OBJECTS ===
	# Assembly Stations (Assembly Line, Break Station)
	hex_map.set_tile(Vector2i(-25, 0), HexTileMap.TILE_OBJECT)    # Assembly Line station
	hex_map.set_tile(Vector2i(0, -5), HexTileMap.TILE_OBJECT)     # Break Station station
	# Soul Furnaces (Furnace Room x2, Foundry Pit x2)
	hex_map.set_tile(Vector2i(25, -5), HexTileMap.TILE_OBJECT)    # Furnace Room 1
	hex_map.set_tile(Vector2i(35, 5), HexTileMap.TILE_OBJECT)     # Furnace Room 2
	hex_map.set_tile(Vector2i(55, -5), HexTileMap.TILE_OBJECT)    # Foundry Pit 1
	hex_map.set_tile(Vector2i(65, 5), HexTileMap.TILE_OBJECT)     # Foundry Pit 2
	# Skull Case (Foreman's Office)
	hex_map.set_tile(Vector2i(85, 0), HexTileMap.TILE_OBJECT)     # Skull Case
	# Save Points (Loading Dock, Break Station, Locker Room)
	hex_map.set_tile(Vector2i(-55, 5), HexTileMap.TILE_OBJECT)    # Loading Dock save
	hex_map.set_tile(Vector2i(5, 5), HexTileMap.TILE_OBJECT)     # Break Station save
	hex_map.set_tile(Vector2i(65, 25), HexTileMap.TILE_OBJECT)    # Locker Room save
	# Shop (Loading Dock, Break Station)
	hex_map.set_tile(Vector2i(-55, -5), HexTileMap.TILE_OBJECT)  # Loading Dock shop
	hex_map.set_tile(Vector2i(-5, -5), HexTileMap.TILE_OBJECT)   # Break Station shop
	# Salvage Bins (Gear Works, Bone Yard)
	hex_map.set_tile(Vector2i(-25, -25), HexTileMap.TILE_OBJECT)  # Gear Works bin
	hex_map.set_tile(Vector2i(-25, 25), HexTileMap.TILE_OBJECT)   # Bone Yard bin
	
	# === PORTALS ===
	# Floor 8 exit (Loading Dock west edge)
	hex_map.set_tile(Vector2i(-75, 0), HexTileMap.TILE_PORTAL)
	# Floor 10 entrance (Foreman's Office east edge, after boss)
	hex_map.set_tile(Vector2i(102, 0), HexTileMap.TILE_PORTAL)
	
	print("[Floor9-Hex] Layout complete: Factory grid + %d rooms" % room_data.size())

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
	
	var start_room = room_data.get("loading_dock")
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
		print("[Floor9-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	var combat_manager = get_node_or_null("CombatManager")
	if not combat_manager:
		return
	var enemies = RoomEnemyDatabase.get_floor_composition(9, encounter_type)
	if enemies.is_empty():
		return
	in_combat = true
	AudioManager.play_combat(9)
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
	print("[Floor9-Hex] Combat started: %s" % encounter_type)

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
		
	AudioManager.play_floor_ambient(9)
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
					print("[Floor9-Hex] Post-combat UI shown, faction: %s" % defeated_faction)
					return  # Wait for ui_closed signal
		if current_room_id == "foremans_office":
			_show_notification("⚡ THE FOREMAN ETERNAL DEFEATED!", Color(0.9, 0.9, 0.3))
			GameState.add_card_to_deck("the_foreman_eternal")
			GameState.gems += 100
			if GameState.has_signal("gems_changed"):
				GameState.gems_changed.emit(GameState.gems)
			_show_floor_transition_prompt()
			return
		# Salvage defeated enemies
		_salvage_combat_victory()
		# Check for Liberator buff
		if liberator_status:
			_show_notification("🕊 Liberator: Undead damage reduced!", Color(0.3, 0.9, 0.3))
		
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
		
		# Check radiation after room combat
		if radiation_active and current_room_id != "loading_dock":
			var damage = 2
			radiation_hp_loss += damage
			_show_notification("☢ Radiation: -%d HP! (Total: %d)" % [damage, radiation_hp_loss], Color(0.9, 0.5, 0.2))
			if GameState.has_method("damage_player"):
				GameState.damage_player(damage)
	
	print("[Floor9-Hex] Combat ended. Victory: %s" % victory)

func _on_combat_turn_started(turn_number: int):
	# Foreman phase logic
	if current_room_id == "foremans_office" and in_combat:
		var config = Floor9Template.new().get_boss_config() if has_node("Floor9Template") else {"phase_transition_hp_1": 45, "phase_transition_hp_2": 20, "inspection_interval": 3}
		var phase1_hp = 45
		var phase2_hp = 20
		var interval = 3
		
		if foreman_phase == 1:
			inspection_turn_counter += 1
			# Attack every 3rd turn (inspection)
			if inspection_turn_counter % interval == 0:
				var damage = 14 if foreman_enraged else 10
				_show_notification("💀 INSPECTION TIME! %d damage!" % damage, Color(0.9, 0.3, 0.3))
				if GameState.has_method("damage_player"):
					GameState.damage_player(damage)
			if foreman_hp <= phase1_hp:
				_on_foreman_phase_2()
		elif foreman_phase == 2:
			if foreman_hp <= phase2_hp:
				_on_foreman_phase_3()
		
		_update_foreman_display()
	
	# Update all UI
	_update_salvage_display()
	_update_furnace_display()
	_update_conveyor_display()
	_update_liberator_display()

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
		print("[Floor9-Hex] PostCombatUI ready")
	else:
		push_warning("[Floor9-Hex] PostCombatUI scene not found!")

func _setup_machinist_shop():
	"""Setup the Machinist's tabbed shop (equipment, overlays, consumables, upgrades)."""
	machinist_shop = MachinistShopUI.new()
	machinist_shop.name = "MachinistShopUI"
	add_child(machinist_shop)
	machinist_shop.shop_closed.connect(_on_machinist_shop_closed)
	print("[Floor9-Hex] MachinistShopUI ready")

func _open_machinist_shop():
	in_ui = true
	machinist_shop.show_shop()
	print("[Floor9-Hex] Machinist shop opened")

func _on_machinist_shop_closed():
	in_ui = false
	print("[Floor9-Hex] Machinist shop closed")

func _setup_enemies():
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.z_index = 90
	add_child(enemy_container)
	
	var spawn_configs = {
		"loading_dock": [
			{"name": "Security Drone", "hex": Vector2i(-55, 5), "faction": "Construct", "hp": 10, "atk": 3},
			{"name": "Security Drone", "hex": Vector2i(-65, -5), "faction": "Construct", "hp": 10, "atk": 3},
		],
		"assembly_line": [
			{"name": "Assembly Skeleton", "hex": Vector2i(-35, 5), "faction": "Undead", "hp": 12, "atk": 3},
			{"name": "Assembly Skeleton", "hex": Vector2i(-25, -5), "faction": "Undead", "hp": 12, "atk": 3},
			{"name": "Gear Construct", "hex": Vector2i(-30, 0), "faction": "Construct", "hp": 15, "atk": 4},
		],
		"gear_works": [
			{"name": "Gear Construct", "hex": Vector2i(-25, -25), "faction": "Construct", "hp": 15, "atk": 4},
			{"name": "Gear Construct", "hex": Vector2i(-35, -30), "faction": "Construct", "hp": 15, "atk": 4},
			{"name": "Gear Construct", "hex": Vector2i(-20, -35), "faction": "Construct", "hp": 15, "atk": 4},
			{"name": "Gear Guardian", "hex": Vector2i(-30, -30), "faction": "Construct", "hp": 30, "atk": 6, "stationary": true},
		],
		"bone_yard": [
			{"name": "Bone Shambler", "hex": Vector2i(-25, 25), "faction": "Undead", "hp": 14, "atk": 3},
			{"name": "Bone Shambler", "hex": Vector2i(-35, 30), "faction": "Undead", "hp": 14, "atk": 3},
			{"name": "Bone Shambler", "hex": Vector2i(-20, 35), "faction": "Undead", "hp": 14, "atk": 3},
			{"name": "Bone Hoarder", "hex": Vector2i(-30, 30), "faction": "Undead", "hp": 28, "atk": 5, "stationary": true},
		],
		"quality_control": [
			{"name": "Skull Machinist", "hex": Vector2i(0, -30), "faction": "Construct", "hp": 40, "atk": 5, "stationary": true, "view_range": 8},
		],
		"furnace_room": [
			{"name": "Soul Burner", "hex": Vector2i(25, 5), "faction": "Undead", "hp": 16, "atk": 4},
			{"name": "Soul Burner", "hex": Vector2i(35, -5), "faction": "Undead", "hp": 16, "atk": 4},
			{"name": "Furnace Guardian", "hex": Vector2i(30, 0), "faction": "Construct", "hp": 25, "atk": 5, "stationary": true},
		],
		"conveyor_maze": [
			{"name": "Conveyor Sprite", "hex": Vector2i(25, 25), "faction": "Construct", "hp": 10, "atk": 3},
			{"name": "Conveyor Sprite", "hex": Vector2i(35, 35), "faction": "Construct", "hp": 10, "atk": 3},
			{"name": "Conveyor Guardian", "hex": Vector2i(30, 30), "faction": "Construct", "hp": 22, "atk": 5, "stationary": true},
		],
		"foundry_pit": [
			{"name": "Soul Piston", "hex": Vector2i(55, 5), "faction": "Construct", "hp": 18, "atk": 5},
			{"name": "Soul Piston", "hex": Vector2i(65, -5), "faction": "Construct", "hp": 18, "atk": 5},
			{"name": "Foundry Elite", "hex": Vector2i(60, 0), "faction": "Construct", "hp": 35, "atk": 6, "stationary": true},
		],
		"foremans_office": [
			{"name": "The Foreman Eternal", "hex": Vector2i(90, 0), "faction": "Boss", "hp": 65, "atk": 8, "boss": true, "stationary": true, "view_range": 12, "combat_range": 2},
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
	
	print("[Floor9-Hex] %d hex enemies spawned" % hex_enemies.size())

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
		AudioManager.play_combat(9)
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		if ambush_bonus:
			_show_notification("🎯 AMBUSH! Player goes first!", Color(0.3, 0.9, 0.3))
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
	print("[Floor9-Hex] Combat initiated (ambush: %s)" % ambush)

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
# SALVAGE & CRAFTING SYSTEM
# ===================================================================

func _add_salvage(material: String, amount: int):
	var max_amount = 20
	match material:
		"bone":
			bone_count = mini(bone_count + amount, max_amount)
			_show_notification("🦴 +%d Bone! (Total: %d)" % [amount, bone_count], Color(0.8, 0.8, 0.7))
		"gear":
			gear_count = mini(gear_count + amount, max_amount)
			_show_notification("⚙ +%d Gear! (Total: %d)" % [amount, gear_count], Color(0.6, 0.6, 0.7))
	_update_salvage_display()
	print("[Floor9] Salvage: %d Bone, %d Gear" % [bone_count, gear_count])

func _build_companion(companion_type: String):
	var req_bone = 2
	var req_gear = 1
	
	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return
	if companions_built.size() >= max_companions:
		_show_notification("Max %d companions!" % max_companions, Color(0.9, 0.3, 0.3))
		return
	
	bone_count -= req_bone
	gear_count -= req_gear
	
	var companion = {
		"type": companion_type,
		"name": _companion_type_to_name(companion_type),
		"effect": _companion_type_to_effect(companion_type),
		"temporary": true,
		"combat_used": false
	}
	companions_built.append(companion)
	companions_built_total += 1
	
	_show_notification("🤖 Built: %s!" % companion["name"], Color(0.3, 0.9, 0.3))
	_update_salvage_display()

func _companion_type_to_name(companion_type: String) -> String:
	match companion_type:
		"bone_drone": return "Bone Drone"
		"gear_skeleton": return "Gear Skeleton"
		"soul_engine": return "Soul Engine"
		"stitch_walker": return "Stitch-Walker"
		_: return "Companion"

func _companion_type_to_effect(companion_type: String) -> String:
	match companion_type:
		"bone_drone": return "deal_4_block_2"
		"gear_skeleton": return "deal_6_draw_1"
		"soul_engine": return "deal_10_discard_buff"
		"stitch_walker": return "block_8_counter_5"
		_: return ""

func _repair_self():
	var req_bone = 1
	var req_gear = 2
	var heal = 10
	var block = 5
	
	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear to repair" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return
	
	bone_count -= req_bone
	gear_count -= req_gear
	
	if GameState.has_method("heal_player"):
		GameState.heal_player(heal)
	if GameState.has_method("add_player_shield"):
		GameState.add_player_shield(block)
	_show_notification("🔧 Repaired! +%d HP, +%d Block" % [heal, block], Color(0.3, 0.9, 0.3))
	_update_salvage_display()

func _salvage_combat_victory():
	# Determine salvage based on enemy types in current room
	var room_enemies = []
	for enemy in hex_enemies:
		if enemy.hp <= 0:
			room_enemies.append(enemy.enemy_name)
	
	var got_bone = false
	var got_gear = false
	for name in room_enemies:
		var lower = name.to_lower()
		if "undead" in lower or "skeleton" in lower or "bone" in lower or "shambler" in lower or "burner" in lower:
			if not got_bone:
				_add_salvage("bone", 1)
				got_bone = true
		elif "construct" in lower or "machinist" in lower or "golem" in lower or "drone" in lower or "gear" in lower or "piston" in lower or "sprite" in lower:
			if not got_gear:
				_add_salvage("gear", 1)
				got_gear = true
	
	# If nothing specific, add generic salvage
	if not got_bone and not got_gear:
		if randf() < 0.7:
			_add_salvage("bone", 1)
		if randf() < 0.5:
			_add_salvage("gear", 1)

func _salvage_defeated_enemy(enemy_name: String):
	var lower = enemy_name.to_lower()
	if "undead" in lower or "skeleton" in lower or "bone" in lower or "shambler" in lower or "burner" in lower:
		_add_salvage("bone", 1)
	elif "construct" in lower or "machinist" in lower or "golem" in lower or "drone" in lower or "gear" in lower or "piston" in lower or "sprite" in lower:
		_add_salvage("gear", 1)

func _update_salvage_display():
	if not salvage_ui:
		return
	var text = "🦴 Bone: %d | ⚙ Gear: %d\n" % [bone_count, gear_count]
	text += "🤖 Companions: %d/%d" % [companions_built.size(), max_companions]
	if companions_built_total >= 5:
		text += " [BUILDER]"
	salvage_ui.text = text
	salvage_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))

# ===================================================================
# SOUL FURNACE SYSTEM
# ===================================================================

func _interact_with_furnace(action: String):
	match action:
		"free_souls":
			_free_souls_from_furnace()
		"burn_souls":
			_burn_souls_in_furnace()
		"drain_soul_piston":
			_drain_soul_piston()

func _free_souls_from_furnace():
	var alarm_chance = 0.7
	
	souls_freed += 1
	furnaces_destroyed += 1
	
	_show_notification("✨ Souls freed! Total: %d" % souls_freed, Color(0.3, 0.9, 0.3))
	
	# Alarm chance
	if randf() < alarm_chance:
		_show_notification("🚨 Alarm! Enemies incoming!", Color(0.9, 0.3, 0.3))
		_start_combat_with_enemies(["Security Drone", "Security Drone"])
	
	# Check Liberator threshold
	if souls_freed >= 5 and not liberator_status:
		liberator_status = true
		GameState.liberator_status = true
		_show_notification("🕊 LIBERATOR STATUS! Undead deal -2 damage!", Color(0.3, 0.9, 0.3))
	
	# Check all furnaces destroyed
	if furnaces_destroyed >= 4:
		all_furnaces_destroyed = true
		_show_notification("🔥 ALL FURNACES DESTROYED! Factory power failing!", Color(0.9, 0.5, 0.2))
	
	_update_furnace_display()
	print("[Floor9] Furnace destroyed. Souls freed: %d" % souls_freed)

func _burn_souls_in_furnace():
	var cost_bone = 3
	
	if bone_count < cost_bone:
		_show_notification("Need %d Bone to burn" % cost_bone, Color(0.9, 0.3, 0.3))
		return
	
	bone_count -= cost_bone
	soul_debt += 1
	furnaces_used += 1
	GameState.soul_debt_count = soul_debt
	
	_show_notification("🔥 Souls burned! Door powered. Soul Debt: %d" % soul_debt, Color(0.9, 0.3, 0.3))
	_update_salvage_display()
	_update_furnace_display()

func _drain_soul_piston():
	var cost = 2
	if GameState.gems < cost:
		_show_notification("Need %d Gems to drain soul" % cost, Color(0.9, 0.3, 0.3))
		return
	
	GameState.gems -= cost
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	
	_show_notification("💎 Soul freed! Construct deactivates!", Color(0.3, 0.9, 0.3))
	# Find nearest construct enemy and deactivate
	for enemy in hex_enemies:
		if enemy.hp > 0 and enemy.enemy_name in ["Soul Piston", "Gear Construct", "Gear Guardian", "Conveyor Sprite", "Conveyor Guardian", "Foundry Elite", "Furnace Guardian"]:
			enemy.hp = 0
			enemy.queue_free()
			_show_notification("⚙ %s deactivated!" % enemy.enemy_name, Color(0.3, 0.9, 0.3))
			break

func _update_furnace_display():
	if not furnace_ui:
		return
	var text = "🔥 Furnaces: %d freed | %d used\n" % [furnaces_destroyed, furnaces_used]
	text += "💀 Soul Debt: %d | Souls Freed: %d\n" % [soul_debt, souls_freed]
	
	if liberator_status:
		text += "🕊 LIBERATOR"
		furnace_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif soul_debt > 0:
		text += "☠ DEBTOR"
		furnace_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		furnace_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	
	furnace_ui.text = text

func _update_liberator_display():
	if not liberator_ui:
		return
	if liberator_status:
		liberator_ui.text = "🕊 LIBERATOR — Undead deal -2 damage"
		liberator_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		liberator_ui.visible = true
	elif soul_debt > 3:
		liberator_ui.text = "☠ SOUL DEBT: %d — Dragon will be disgusted" % soul_debt
		liberator_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		liberator_ui.visible = true
	else:
		liberator_ui.visible = false

# ===================================================================
# CONVEYOR BELT SYSTEM
# ===================================================================

func _update_conveyor_direction():
	var directions = {
		"assembly_line": "east",
		"furnace_room": "east",
		"foundry_pit": "south",
		"gear_works": "south",
		"bone_yard": "north",
		"conveyor_maze": "random"
	}
	conveyor_direction = directions.get(current_room_id, "east")

func _ride_conveyor():
	var speed = 2.0
	
	on_conveyor = true
	_show_notification("🏭 Riding conveyor... Direction: %s" % conveyor_direction, Color(0.6, 0.6, 0.7))
	
	# Check for hazards
	if randf() < 0.3:
		var damage = 3
		_show_notification("💥 Conveyor hazard! %d damage!" % damage, Color(0.9, 0.3, 0.3))
		if GameState.has_method("damage_player"):
			GameState.damage_player(damage)

func _flip_conveyor_switch():
	match conveyor_direction:
		"east": conveyor_direction = "west"
		"west": conveyor_direction = "east"
		"north": conveyor_direction = "south"
		"south": conveyor_direction = "north"
		"random": conveyor_direction = "east"
	
	_show_notification("🔀 Conveyor switched to %s!" % conveyor_direction, Color(0.3, 0.9, 0.3))
	_update_conveyor_display()

func _time_conveyor_jump():
	var window = 2.0
	_show_notification("⏱ Time your jump! Window: %.1f seconds!" % window, Color(0.9, 0.7, 0.3))
	_show_notification("⏱ Jump successful!", Color(0.3, 0.9, 0.3))
	conveyor_maze_solved = true
	_show_notification("🔓 Conveyor Maze solved! Locker Room shortcut open!", Color(0.3, 0.9, 0.3))

func _check_conveyor_push():
	if not player_node or not hex_map:
		return
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var room_conveyors = conveyor_hexes.get(current_room_id, [])
	if player_hex not in room_conveyors:
		on_conveyor = false
		return
	
	on_conveyor = true
	var dirs = HexTileMap.DIRECTIONS
	var push_dir: Vector2i
	match conveyor_direction:
		"east": push_dir = dirs[3]   # q+1, r
		"west": push_dir = dirs[0]   # q-1, r
		"north": push_dir = dirs[5]  # q, r-1
		"south": push_dir = dirs[2]  # q, r+1
		"random": push_dir = dirs[randi() % dirs.size()]
		_: push_dir = dirs[3]
	
	var push_hex = player_hex + push_dir
	if hex_map.is_walkable(push_hex):
		player_node.global_position = hex_map.hex_to_world(push_hex)
		_show_notification("🏭 Conveyor pushes you %s!" % conveyor_direction, Color(0.6, 0.6, 0.7))
		_check_room_transition(push_hex)
		_check_interactables()
		_check_enemy_sight()
	else:
		var damage = 3
		_show_notification("💥 Conveyor collision! %d damage!" % damage, Color(0.9, 0.3, 0.3))
		if GameState.has_method("damage_player"):
			GameState.damage_player(damage)

func _update_conveyor_display():
	if not conveyor_ui:
		return
	if current_room_id in ["assembly_line", "furnace_room", "foundry_pit", "gear_works", "bone_yard", "conveyor_maze"]:
		conveyor_ui.text = "🏭 Conveyor: %s" % conveyor_direction
		if on_conveyor:
			conveyor_ui.text += " [RIDING]"
		conveyor_ui.visible = true
	else:
		conveyor_ui.visible = false

# ===================================================================
# BOSS SYSTEM — The Foreman Eternal (3 Phases)
# ===================================================================

func _start_boss_fight():
	foreman_phase = 1
	foreman_hp = foreman_max_hp
	inspection_turn_counter = 0
	skull_case_destroyed = false
	strike_team_built = false
	
	var intro = "You are unprocessed material.\nDesignation: unknown.\nValue: uncalculated.\nPlease submit to nearest assembly station for evaluation.\nResistance will be logged."
	
	if liberator_status:
		intro = "You have damaged factory property.\nFreed souls represent lost labor hours.\nHowever: efficiency analysis suggests vengeance is non-productive.\nI will simply... process you faster."
	
	if foreman_enraged:
		intro += "\n\nPOWER FAILURE DETECTED.\nFOREMAN OVERRIDE: ENRAGED."
	
	_show_dialogue("The Foreman Eternal", intro)
	
	foreman_ui.visible = true
	_update_foreman_display()
	print("[Floor9] Boss fight started — Phase 1: The Shift. HP: %d/%d" % [foreman_hp, foreman_max_hp])

func _on_foreman_phase_2():
	foreman_phase = 2
	_show_dialogue("The Foreman Eternal", "Quality metrics: unacceptable.\nProductivity: below threshold.\nInitiating... Quality Control.\n\nAll constructs gain +2 ATK.\nConveyor speed increased.")
	_show_notification("🔍 FOREMAN: Phase 2 — Quality Control!", Color(0.9, 0.5, 0.2))
	conveyor_speed = 3.0
	# Buff all construct enemies
	for enemy in hex_enemies:
		if enemy.faction == "Construct" and enemy.hp > 0:
			enemy.attack += 2
			_show_notification("⚙ %s buffed! +2 ATK" % enemy.enemy_name, Color(0.9, 0.7, 0.3))
	print("[Floor9] Phase 2: Quality Control")

func _on_foreman_phase_3():
	foreman_phase = 3
	
	_show_dialogue("The Foreman Eternal", "Efficiency dropping.\nInitiating overtime protocols.\nAll breaks cancelled.\nProduction must continue.\n\nEFFICIENCY MEASURES ENGAGED.")
	
	if liberator_status and not skull_case_destroyed:
		_show_dialogue("The Skull", "Thank you. End this.\nThe machine does not know what it does.\nBut I remember.\nI remember being human.\nPlease.")
	
	_show_notification("⏱ FOREMAN OVERTIME! Attacks every turn!", Color(0.9, 0.2, 0.2))
	print("[Floor9] Phase 3: Efficiency Measures")

func _destroy_skull_case():
	if skull_case_destroyed:
		_show_notification("Skull case already destroyed", Color(0.7, 0.7, 0.7))
		return
	
	skull_case_destroyed = true
	
	_show_notification("💀 SKULL CASE DESTROYED! Foreman +50% damage taken!", Color(0.9, 0.3, 0.3))
	
	if liberator_status:
		_show_notification("🕊 The skull whispers: 'Thank you...'", Color(0.3, 0.9, 0.3))

func _build_strike_team():
	var req_bone = 6
	var req_gear = 3
	
	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear for Strike Team!" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return
	
	bone_count -= req_bone
	gear_count -= req_gear
	
	# Build 3 companions at once
	var types = ["bone_drone", "gear_skeleton", "soul_engine"]
	for i in range(3):
		if companions_built.size() < max_companions:
			_build_companion(types[i])
	
	strike_team_built = true
	_show_notification("🤖 STRIKE TEAM BUILT! 3 companions ready!", Color(0.3, 0.9, 0.3))
	_update_salvage_display()

func _update_foreman_display():
	if not foreman_ui:
		return
	var text = ""
	match foreman_phase:
		1:
			text = "FOREMAN: Phase 1 — The Shift | %d/%d HP" % [foreman_hp, foreman_max_hp]
			if foreman_enraged:
				text += " [ENRAGED]"
		2:
			text = "FOREMAN: Phase 2 — Quality Control | %d/%d HP" % [foreman_hp, foreman_max_hp]
		3:
			text = "FOREMAN: Phase 3 — Efficiency | %d/%d HP" % [foreman_hp, foreman_max_hp]
			if skull_case_destroyed:
				text += " [SKULL BROKEN]"
	
	foreman_ui.text = text
	foreman_ui.visible = true
	
	var color = Color(0.9, 0.3, 0.3)
	if foreman_phase == 3:
		color = Color(0.9, 0.1, 0.1)
	foreman_ui.add_theme_color_override("font_color", color)

func _end_boss_combat(victory: bool):
	if victory:
		if liberator_status and skull_case_destroyed:
			_show_dialogue("The Tower", "The Foreman falls.\nThe skull is silent now.\nA mercy, at the end.\nThe path to Floor 10 opens.\nThe dragon awaits.")
		elif liberator_status:
			_show_dialogue("The Tower", "The Foreman falls.\nBut the skull still whispers.\n'Free them. Free them all.'\nThe path to Floor 10 opens.")
		elif soul_debt > 3:
			_show_dialogue("The Tower", "The Foreman falls.\nThe debt is paid in blood.\nThe dragon will smell it on you.\nThe path to Floor 10 opens.")
		else:
			_show_dialogue("The Tower", "The Foreman falls.\nThe factory groans but holds.\nThe path to Floor 10 opens.\nThe dragon awaits your weight.")
		
		GameState.gems += 100
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
		
		_apply_floor10_effects()
		GameState.save_game()
		
		_show_notification("🏰 Ascending to Floor 10...", Color(0.9, 0.7, 0.3))
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(_ascend_to_next_floor)
		add_child(timer)
		timer.start()
	else:
		_show_notification("💀 Defeated by The Foreman Eternal", Color(0.9, 0.3, 0.3))

func _apply_floor10_effects():
	if liberator_status:
		GameState.floor10_dragon_compassion = true
	if soul_debt > 3:
		GameState.floor10_dragon_disgust = true
		GameState.floor10_soul_debt = soul_debt
	if companions_built_total >= 5:
		GameState.floor10_secret_ending_path = true
	if all_furnaces_destroyed:
		GameState.floor10_freed_souls_follow = true

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
	
	# Salvage UI
	salvage_ui = Label.new()
	salvage_ui.name = "SalvageUI"
	salvage_ui.position = Vector2(20, 20)
	salvage_ui.size = Vector2(400, 100)
	salvage_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(salvage_ui)
	
	# Furnace UI
	furnace_ui = Label.new()
	furnace_ui.name = "FurnaceUI"
	furnace_ui.position = Vector2(20, 130)
	furnace_ui.size = Vector2(350, 80)
	furnace_ui.add_theme_font_size_override("font_size", 11)
	main_ui.add_child(furnace_ui)
	
	# Conveyor UI
	conveyor_ui = Label.new()
	conveyor_ui.name = "ConveyorUI"
	conveyor_ui.position = Vector2(20, 220)
	conveyor_ui.size = Vector2(300, 40)
	conveyor_ui.add_theme_font_size_override("font_size", 11)
	main_ui.add_child(conveyor_ui)
	
	# Liberator UI
	liberator_ui = Label.new()
	liberator_ui.name = "LiberatorUI"
	liberator_ui.position = Vector2(20, 270)
	liberator_ui.size = Vector2(300, 40)
	liberator_ui.add_theme_font_size_override("font_size", 12)
	main_ui.add_child(liberator_ui)
	
	# Foreman UI
	foreman_ui = Label.new()
	foreman_ui.name = "ForemanUI"
	foreman_ui.position = Vector2(20, 320)
	foreman_ui.size = Vector2(400, 40)
	foreman_ui.add_theme_font_size_override("font_size", 12)
	foreman_ui.visible = false
	main_ui.add_child(foreman_ui)
	
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
	
	_update_salvage_display()
	_update_furnace_display()
	_update_conveyor_display()
	_update_liberator_display()

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
	prompt.text = "Press [S] to Ascend to Floor 10 — The Dragon"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

func _floor_complete():
	if floor_complete_notified:
		return
	floor_complete_notified = true
	floor_cleared = true
	_show_dialogue("The Tower", "The Foreman Eternal rests. Press [S] to ascend to Floor 10.")
	GameState.gems += 20
	GameState.save_game()

func _ascend_to_next_floor():
	print("[Floor9] Ascending to Floor 10...")
	get_tree().change_scene_to_file("res://scenes/Floor10.tscn")

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
	_check_conveyor_push()

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
	print("[Floor9-Hex] Entered: %s" % display)
	if room_indicator:
		room_indicator.text = "📍 %s" % display
		var color = Color(0.7, 0.7, 0.7)
		match room_id:
			"loading_dock":     color = Color(0.6, 0.6, 0.7)
			"assembly_line":    color = Color(0.7, 0.6, 0.5)
			"break_station":    color = Color(0.5, 0.7, 0.5)
			"furnace_room":     color = Color(0.9, 0.4, 0.2)
			"foundry_pit":      color = Color(0.8, 0.3, 0.2)
			"foremans_office":  color = Color(0.9, 0.2, 0.2)
			"gear_works":       color = Color(0.6, 0.6, 0.7)
			"bone_yard":        color = Color(0.8, 0.8, 0.7)
			"quality_control":  color = Color(0.7, 0.5, 0.7)
			"conveyor_maze":    color = Color(0.5, 0.5, 0.6)
			"locker_room":      color = Color(0.5, 0.7, 0.5)
		room_indicator.add_theme_color_override("font_color", color)
	
	# Update conveyor direction for new room
	_update_conveyor_direction()
	_update_conveyor_display()

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
	if target_room == "foremans_office" and not room_cleared.get("foundry_pit", false):
		_show_notification("🔒 The Foreman's Office is sealed. Clear the Foundry Pit first.")
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
		"loading_dock":     msg = "Loading Dock. The factory breathes."
		"assembly_line":    msg = "Assembly Line. Conveyor belts hum."
		"break_station":    msg = "Break Station. A rare quiet."
		"furnace_room":     msg = "Furnace Room. Souls burn below."
		"foundry_pit":      msg = "Foundry Pit. Soul-pistons pound."
		"foremans_office":  msg = "Foreman's Office. The machine waits."
		"gear_works":       msg = "Gear Works. Metal grinds."
		"bone_yard":        msg = "Bone Yard. The dead assemble."
		"quality_control":  msg = "Quality Control. Defects are purged."
		"conveyor_maze":    msg = "Conveyor Maze. Ride or be ridden."
		"locker_room":      msg = "Locker Room. Final preparations."
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
			"assembly_station":     _show_interact_prompt("[S] Use Assembly Station")
			"soul_furnace":         _show_interact_prompt("[S] Interact with Furnace")
			"conveyor_switch":      _show_interact_prompt("[S] Flip Conveyor Switch")
			"skull_case":           _show_interact_prompt("[S] Destroy Skull Case")
			"save_point":           _show_interact_prompt("[S] Save Game")
			"shop":                 _show_interact_prompt("[S] Shop")
			"salvage_bin":          _show_interact_prompt("[S] Salvage Bin")
			_:
				_hide_interact_prompt()
	elif tile == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir == "exit":
			if current_room_id == "loading_dock":
				_show_interact_prompt("[S] Return to Floor 8")
			elif current_room_id == "foremans_office":
				_show_interact_prompt("[S] Ascend to Floor 10")
			else:
				_hide_interact_prompt()
		else:
			_hide_interact_prompt()
	else:
		# Check if player is on a conveyor hex
		var room_conveyors = conveyor_hexes.get(current_room_id, [])
		if player_hex in room_conveyors:
			_show_interact_prompt("[S] Ride Conveyor / [Jump] Jump Off")
		else:
			_hide_interact_prompt()

func _get_object_id_at_hex(hex: Vector2i) -> String:
	var object_map = {
		Vector2i(-25, 0):   "assembly_station",    # Assembly Line
		Vector2i(0, -5):    "assembly_station",    # Break Station
		Vector2i(25, -5):   "soul_furnace",        # Furnace Room 1
		Vector2i(35, 5):    "soul_furnace",        # Furnace Room 2
		Vector2i(55, -5):   "soul_furnace",        # Foundry Pit 1
		Vector2i(65, 5):    "soul_furnace",        # Foundry Pit 2
		Vector2i(85, 0):    "skull_case",          # Foreman's Office
		Vector2i(-55, 5):   "save_point",          # Loading Dock
		Vector2i(5, 5):     "save_point",          # Break Station
		Vector2i(65, 25):   "save_point",          # Locker Room
		Vector2i(-55, -5):  "shop",                # Loading Dock
		Vector2i(-5, -5):   "shop",                # Break Station
		Vector2i(-25, -25): "salvage_bin",         # Gear Works
		Vector2i(-25, 25):  "salvage_bin",         # Bone Yard
	}
	# Conveyor switches
	for room in conveyor_switches.keys():
		for switch_hex in conveyor_switches[room]:
			if hex == switch_hex:
				return "conveyor_switch"
	return object_map.get(hex, "")

func _interact_at_hex(hex: Vector2i):
	var obj_id = _get_object_id_at_hex(hex)
	match obj_id:
		"assembly_station":
			_show_assembly_menu()
		"soul_furnace":
			_show_furnace_menu()
		"conveyor_switch":
			_flip_conveyor_switch()
		"skull_case":
			_destroy_skull_case()
		"save_point":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_notification("Progress saved.", Color(0.3, 0.9, 0.3))
		"shop":
			_open_machinist_shop()
		"salvage_bin":
			_add_salvage("bone", 2)
			_add_salvage("gear", 2)
			_show_notification("🔧 Salvage bin looted! +2 Bone, +2 Gear", Color(0.3, 0.9, 0.3))
	
	# Check for portal interaction
	if hex_map.get_tile(hex) == HexTileMap.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(hex)
		if portal_dir == "exit":
			if current_room_id == "loading_dock":
				get_tree().change_scene_to_file("res://scenes/Floor8.tscn")
			elif current_room_id == "foremans_office":
				get_tree().change_scene_to_file("res://scenes/Floor10.tscn")

func _show_assembly_menu():
	var text = "⚙ ASSEMBLY STATION\n"
	text += "Bone: %d | Gear: %d\n\n" % [bone_count, gear_count]
	text += "[1] Bone Drone (2B+1G) — deal 4, block 2\n"
	text += "[2] Gear Skeleton (2B+1G) — deal 6, draw 1\n"
	text += "[3] Soul Engine (2B+1G) — deal 10, discard buff\n"
	text += "[4] Stitch-Walker (2B+1G) — block 8, counter 5\n"
	text += "[R] Repair Self (1B+2G) — heal 10, block 5\n"
	text += "[S] Build Strike Team (6B+3G) — 3 companions"
	_show_dialogue("Assembly Station", text)

func _show_furnace_menu():
	var text = "🔥 SOUL FURNACE\n"
	if elemental_core_held:
		text += "[OVERCLOCK available — Elemental Core active]\n"
	text += "[F] Free Souls (70%% alarm chance)\n"
	text += "[B] Burn Souls (3 Bone, +1 Soul Debt)\n"
	text += "[D] Drain Soul-Piston (2 Gems, kill construct)\n"
	text += "\nSouls freed: %d | Soul debt: %d" % [souls_freed, soul_debt]
	_show_dialogue("Soul Furnace", text)

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
	AudioManager.play_combat(9)
	combat_manager.start_combat(combat_data, GameState.player_deck)
	var ui = get_node_or_null("CombatUI")
	if ui:
		ui.setup(combat_manager)
		ui.visible = true

# ===================================================================
# FLOOR SPECIFIC SETUP
# ===================================================================

func _setup_floor_specific():
	# Check cross-floor bleed from Floor 8
	if GameState.get_value("floor9_no_power", false):
		no_power = true
		foreman_start_hp_percent = 0.8
		foreman_enraged = true
		_show_notification("⚠ No power from Floor 8! Constructs slower, Foreman enraged!", Color(0.9, 0.3, 0.3))
	
	if GameState.get_value("floor9_radiation_debuff", false):
		radiation_active = true
		_show_notification("☢ Radiation debuff active! -2 HP per room", Color(0.9, 0.5, 0.2))
	
	if GameState.get_value("elemental_core_held", false):
		elemental_core_held = true
		_show_notification("🔥 Elemental Core active! Can overclock furnaces!", Color(0.9, 0.4, 0.2))
	
	if GameState.get_value("floor9_elementals_loose", false):
		elementals_loose = true
		_show_notification("💨 Elementals loose! +2 elite encounters!", Color(0.9, 0.7, 0.3))
	
	if GameState.get_value("floor8_chief_handler_killed", false):
		goblin_refugees = true
		_show_notification("🤪 Goblin refugees causing chaos!", Color(0.9, 0.7, 0.3))
	
	# Set foreman HP based on cross-floor bleed
	foreman_max_hp = int(65 * foreman_start_hp_percent)
	foreman_hp = foreman_max_hp
	
	# Initialize conveyor
	_update_conveyor_direction()
	
	print("[Floor9] Setup complete. Bone: %d | Gear: %d | Liberator: %s | Enraged: %s" % [
		bone_count, gear_count, liberator_status, foreman_enraged
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
			KEY_1:
				if not in_combat and not in_ui:
					_build_companion("bone_drone")
					return
			KEY_2:
				if not in_combat and not in_ui:
					_build_companion("gear_skeleton")
					return
			KEY_3:
				if not in_combat and not in_ui:
					_build_companion("soul_engine")
					return
			KEY_4:
				if not in_combat and not in_ui:
					_build_companion("stitch_walker")
					return
			KEY_R:
				if not in_combat and not in_ui:
					_repair_self()
					return
			KEY_F:
				if not in_combat and not in_ui:
					_free_souls_from_furnace()
					return
			KEY_B:
				if not in_combat and not in_ui:
					_burn_souls_in_furnace()
					return
			KEY_D:
				if not in_combat and not in_ui:
					_drain_soul_piston()
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
				_check_conveyor_push()
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
	print("[Floor9-Hex] Post-combat closed, resuming")

