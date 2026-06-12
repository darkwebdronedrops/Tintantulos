extends FloorController
class_name Floor3Controller

# ===================================================================
# FLOOR 3 CONTROLLER — The Gearworks
# Extends FloorController while preserving all unique Floor 3 mechanics:
#   - Hex-grid overworld movement around a ring
#   - Dial rotation (R key rotates Rooms 1-11)
#   - Light Beam Puzzle (11 widgets align to center)
#   - 12 unique room puzzles
#   - Crown Cog inner hub with Machinist shop
#   - Overworld enemies, traps, world offerings
#   - Boss encounters
# ===================================================================

# Floor 3 Template
@onready var floor3_template: Floor3Template = Floor3Template.new()

# Constants
const OUTER_RADIUS: float = 1500.0
const INNER_RADIUS: float = 200.0
const ROTATION_STEP: float = 30.0
const ROOM_INTERIOR_SIZE: float = 350.0
const MAX_OVERWORLD_ENEMIES: int = 6
const ENEMY_SPAWN_CHANCE: float = 0.7
const TRAP_SPAWN_CHANCE: float = 0.25
const MAX_WORLD_OFFERINGS: int = 5
const OFFERING_SPAWN_CHANCE: float = 0.4

# --- Audio Helpers ---

func _play_audio(sound_name: String, bus: int = 1):  # 1 = SFX bus
	"""Play a sound effect via AudioManager"""
	var audio_mgr = _get_audio_manager()
	if audio_mgr:
		var bus_name = "SFX" if bus == 1 else "Master"
		audio_mgr.play_sfx(sound_name, bus_name)

func _get_audio_manager():
	"""Find AudioManager in the scene tree"""
	var root = get_tree().root
	for child in root.get_children():
		var found = _find_node_recursive(child, "AudioManager")
		if found:
			return found
	return null

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, target_name)
		if found:
			return found
	return null

# Room metadata (parallel to base class rooms dict)
var room_metadata: Dictionary = {}  # room_id (String) -> RoomMeta

class RoomMeta:
	var id: int
	var slot_index: int
	var is_stationary: bool
	var has_boss: bool
	var boss_type: String
	var boss_defeated: bool
	var base_angle: float
	var current_angle: float
	var position: Vector2
	var spawned_enemies: Array[Node2D] = []

# Dial state
var dial_position: int = 0
var rotation_angle: float = 0.0

# Combat gate — locked until player does Room 1 or rotates dial
var combat_unlocked: bool = false

# Player hex state
var player_hex: Vector2i = Vector2i(0, -4)
var blocked_hexes: Array[Vector2i] = []

# Puzzles
var room_puzzles: Dictionary = {}  # room_id (int) -> RoomPuzzle
var active_puzzle: RoomPuzzle = null
var in_puzzle: bool = false
var pending_boss_room_id: int = 0

# Light Beam Puzzle
var light_beam_puzzle: LightBeamPuzzle

# Machinist Shop
var machinist_shop: MachinistShopUI
var in_shop: bool = false

# Overworld Enemies
var overworld_enemies: Array[OverworldEnemy] = []
var next_enemy_id: int = 1

# Traps
var active_traps: Array[Trap] = []
var trap_hex_map: Dictionary = {}  # Vector2i -> Trap

# World Offerings
var world_offerings: Array[WorldOfferingPickup] = []

# Post-Combat
var post_combat_ui: PostCombatUI
var last_combat_faction: String = ""

# Offering Inventory
var offering_inventory: OfferingInventoryUI

# Overworld HUD
var overworld_hud: OverworldHUD

# Camera
var camera: GameCamera

# Screens
var title_screen: TitleScreen
var settings_menu: SettingsMenu
var victory_screen: VictoryScreen

# Save dialog
var save_dialog_overlay: CanvasLayer = null

# Combat (accessed via nodes)
@onready var combat_manager: CombatManager = $CombatManager if has_node("CombatManager") else null
@onready var combat_ui: CombatUI = $CombatUI if has_node("CombatUI") else null

# Inner room (Crown Cog)
var crown_cog_node: Node2D

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready():
	GameState.current_floor = 3
	floor_template = floor3_template
	super._ready()

func _setup_floor_specific():
	print("[Floor3] Setting up The Gearworks...")
	
	# Ensure combat is wired (base class uses local vars, we need member access)
	if combat_ui and combat_ui.has_method("setup") and combat_manager:
		combat_ui.setup(combat_manager)
	if combat_manager and combat_manager.has_signal("combat_ended"):
		# Avoid duplicate connection if base class already connected
		if not combat_manager.combat_ended.is_connected(_on_combat_ended):
			combat_manager.combat_ended.connect(_on_combat_ended)
	
	# Initialize room metadata
	var slot_angles = floor3_template.SLOT_ANGLES
	for i in range(12):
		var room_id_int = i + 1
		var room_id_str = str(room_id_int)
		var meta = RoomMeta.new()
		meta.id = room_id_int
		meta.is_stationary = (room_id_int == 12)
		meta.has_boss = floor3_template.is_boss_room(room_id_int)
		meta.boss_type = floor3_template.get_boss_type(room_id_int)
		meta.boss_defeated = false
		
		if meta.is_stationary:
			meta.slot_index = 0
		else:
			meta.slot_index = room_id_int  # Initial: Room 1 → slot 1, etc.
		
		meta.base_angle = slot_angles[meta.slot_index]
		meta.current_angle = meta.base_angle
		
		var room_node = rooms.get(room_id_str)
		if room_node:
			meta.position = room_node.global_position
		
		room_metadata[room_id_str] = meta
		
		if room_node and room_node is Floor3RoomBase:
			room_node.is_rotating = not meta.is_stationary
			room_node.slot_index = meta.slot_index
			room_node.room_display_name = floor3_template.get_room_name(room_id_int)
			room_node.has_puzzle = true
			_setup_room_visuals(room_node, meta)
	
	# Create Crown Cog hub
	_create_crown_cog()
	
	# Setup room puzzles
	_initialize_room_puzzles()
	
	# Setup Light Beam Puzzle
	light_beam_puzzle = LightBeamPuzzle.new()
	add_child(light_beam_puzzle)
	var room_nodes = {}
	for room_id_str in rooms:
		var node = rooms[room_id_str]
		if node:
			room_nodes[int(room_id_str)] = node
	light_beam_puzzle.create_widget_visuals(room_nodes)
	light_beam_puzzle.puzzle_complete.connect(_on_puzzle_complete)
	
	print("[Floor3] _setup_floor_specific() — player_node exists: ", player_node != null)
	print("[Floor3] _setup_floor_specific() — rooms count: ", rooms.size())
	print("[Floor3] _setup_floor_specific() — room '12' exists: ", rooms.has("12"))
	
	# Setup Camera
	camera = GameCamera.new()
	camera.name = "Camera2D"
	add_child(camera)
	print("[Floor3] Camera created: ", camera != null)
	
	# Force immediate snap - don't wait for _process lerp
	if player_node:
		print("[Floor3] Snapping camera to player at: ", player_node.global_position)
		camera.global_position = player_node.global_position
		camera.set_target(player_node)
	else:
		push_warning("[Floor3] player_node is null during _setup_floor_specific!")
	
	# Setup player starting position (Room 12 — The Quench)
	var start_room = rooms.get("12")
	print("[Floor3] start_room for '12': ", start_room)
	if start_room:
		player_hex = HexGrid.world_to_hex(start_room.global_position)
		print("[Floor3] Room 12 global_position: ", start_room.global_position)
		print("[Floor3] Room 12 player spawn: ", start_room.get_player_spawn_position() if start_room.has_method("get_player_spawn_position") else "N/A")
		if player_node:
			player_node.global_position = start_room.global_position
			camera.set_target(player_node)
			camera.position = player_node.position
			print("[Floor3] Player moved to: ", player_node.global_position)
			print("[Floor3] Camera at: ", camera.global_position)
		current_room_id = "12"
		# Suppress auto combat on start room until unlocked
		start_room.auto_spawn = false
		print("[Floor3] Start room auto_spawn suppressed — combat locked until Room 1 or dial rotation")
	
	# Generate world walls
	_generate_world_walls()
	
	# Add to group
	add_to_group("floor3_controller")
	
	# Connect GameState death signal
	if GameState.has_signal("player_died"):
		GameState.player_died.connect(_on_player_died)
	
	# Setup Overworld HUD
	overworld_hud = OverworldHUD.new()
	overworld_hud.name = "OverworldHUD"
	add_child(overworld_hud)
	
	# Spawn overworld enemies
	_spawn_overworld_enemies()
	
	# Spawn world offerings
	_spawn_world_offerings()
	
	print("[Floor3] Setup complete — %d rooms + Crown Cog" % rooms.size())

func _setup_floor_ui():
	# Post-combat UI
	post_combat_ui = PostCombatUI.new()
	post_combat_ui.name = "PostCombatUI"
	post_combat_ui.visible = false
	post_combat_ui.rewards_confirmed.connect(_on_post_combat_confirmed)
	add_child(post_combat_ui)
	
	# Machinist Shop (Floor 3 custom with boss challenge)
	machinist_shop = MachinistShopUI.new()
	machinist_shop.name = "MachinistShop"
	machinist_shop.visible = false
	machinist_shop.shop_closed.connect(_on_shop_closed)
	machinist_shop.boss_challenged.connect(_on_boss_challenged)
	add_child(machinist_shop)
	
	# Offering Inventory
	offering_inventory = OfferingInventoryUI.new()
	offering_inventory.name = "OfferingInventory"
	offering_inventory.visible = false
	offering_inventory.inventory_closed.connect(_on_inventory_closed)
	add_child(offering_inventory)
	
	# Title Screen
	title_screen = TitleScreen.new()
	title_screen.name = "TitleScreen"
	title_screen.visible = false  # Don't block the floor view on load
	title_screen.new_game_started.connect(_on_title_new_game)
	title_screen.continue_game_started.connect(_on_title_continue)
	add_child(title_screen)

func _setup_shop():
	"""Override — Floor 3 creates its shop in _setup_floor_ui() with boss challenge signal."""
	pass
	
	# Pause Menu (Floor3 custom, but store separately to avoid conflict with base class)
	var floor3_pause = PauseMenu.new()
	floor3_pause.name = "PauseMenu"
	floor3_pause.visible = false
	floor3_pause.resume_requested.connect(_on_pause_resume)
	floor3_pause.settings_requested.connect(_on_pause_settings)
	floor3_pause.quit_to_title_requested.connect(_on_pause_quit_to_title)
	add_child(floor3_pause)
	pause_menu = floor3_pause  # Assign to base class variable for compatibility
	
	# Settings Menu
	settings_menu = SettingsMenu.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.visible = false
	settings_menu.settings_closed.connect(_on_settings_closed)
	add_child(settings_menu)
	
	# Victory Screen
	victory_screen = VictoryScreen.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.visible = false
	victory_screen.return_to_title_requested.connect(_on_victory_return_title)
	victory_screen.new_game_plus_requested.connect(_on_victory_ngp)
	add_child(victory_screen)

func _update_floor_ui():
	# Overworld HUD updates are handled in _process
	pass

# -------------------------------------------------------------------
# Room Visual Setup
# -------------------------------------------------------------------

func _setup_room_visuals(room_node: Floor3RoomBase, meta: RoomMeta):
	# Add center hex for overworld visibility
	var center_hex = Polygon2D.new()
	center_hex.name = "CenterHex"
	center_hex.polygon = HexGrid.get_hex_polygon()
	center_hex.scale = Vector2(0.6, 0.6)
	center_hex.color = floor3_template.get_room_color(meta.id)
	if meta.has_boss and meta.boss_defeated:
		center_hex.color = Color(0.3, 0.8, 0.3)
	room_node.add_child(center_hex)
	
	# Room label
	var label = Label.new()
	label.name = "RoomLabel"
	label.text = "%d. %s" % [meta.id, room_node.room_display_name]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-60, -210)
	label.size = Vector2(120, 30)
	label.add_theme_font_size_override("font_size", 14)
	room_node.add_child(label)
	
	# Boss indicator
	if meta.has_boss:
		var boss_label = Label.new()
		boss_label.name = "BossLabel"
		boss_label.text = "⚠ BOSS"
		boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_label.position = Vector2(-40, -235)
		boss_label.size = Vector2(80, 20)
		boss_label.add_theme_font_size_override("font_size", 12)
		boss_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		room_node.add_child(boss_label)
	
	# Cleared indicator
	if GameState.is_room_cleared(meta.id):
		meta.boss_defeated = true
		var cleared = Label.new()
		cleared.name = "ClearedLabel"
		cleared.text = "✓ CLEARED"
		cleared.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cleared.position = Vector2(-50, 210)
		cleared.size = Vector2(100, 20)
		cleared.add_theme_font_size_override("font_size", 11)
		cleared.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		room_node.add_child(cleared)

# -------------------------------------------------------------------
# Crown Cog Hub
# -------------------------------------------------------------------

func _create_crown_cog():
	var container = Node2D.new()
	container.name = "CrownCog"
	add_child(container)
	crown_cog_node = container
	
	# Walkable floor
	var floor_sprite = Sprite2D.new()
	floor_sprite.name = "CrownFloor"
	floor_sprite.z_index = -10
	var floor_path = "res://assets/sprites/ui_env/env_floor_hex.png"
	if ResourceLoader.exists(floor_path):
		floor_sprite.texture = load(floor_path)
		floor_sprite.scale = Vector2(8.0, 8.0)
		floor_sprite.region_enabled = true
		floor_sprite.region_rect = Rect2(0, 0, 256, 256)
	container.add_child(floor_sprite)
	
	# Background cog
	var bg_path = "res://assets/sprites/backgrounds/bg_crown_cog_hub.png"
	var cog_sprite = Sprite2D.new()
	cog_sprite.name = "CogSprite"
	cog_sprite.z_index = -50
	if ResourceLoader.exists(bg_path):
		cog_sprite.texture = load(bg_path)
		cog_sprite.scale = Vector2(2.5, 2.5)
		cog_sprite.position = Vector2(0, -200)
		container.add_child(cog_sprite)
	else:
		var cog = Polygon2D.new()
		cog.name = "CogShape"
		cog.color = Color(0.9, 0.8, 0.3)
		var points = PackedVector2Array()
		for i in range(12):
			var angle = (TAU / 12.0) * i
			var r = 80.0 if i % 2 == 0 else 60.0
			points.append(Vector2(cos(angle) * r, sin(angle) * r))
		cog.polygon = points
		container.add_child(cog)
	
	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = "CROWN\nCOG"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -20)
	label.size = Vector2(80, 40)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	# Boss Altar
	_create_boss_altar(container)
	
	# Dial Button
	var dial_btn = Area2D.new()
	dial_btn.name = "DialButton"
	dial_btn.position = Vector2(0, 120)
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	dial_btn.add_child(collision)
	var dial_sprite_path = "res://assets/sprites/ui/ui_dial_button.png"
	if ResourceLoader.exists(dial_sprite_path):
		var dial_sprite = Sprite2D.new()
		dial_sprite.texture = load(dial_sprite_path)
		dial_btn.add_child(dial_sprite)
	else:
		var btn_visual = Polygon2D.new()
		btn_visual.polygon = HexGrid.get_hex_polygon()
		btn_visual.scale = Vector2(0.8, 0.8)
		btn_visual.color = Color(0.9, 0.5, 0.2)
		dial_btn.add_child(btn_visual)
	var btn_label = Label.new()
	btn_label.text = "ROTATE"
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.position = Vector2(-30, -10)
	btn_label.size = Vector2(60, 20)
	btn_label.add_theme_font_size_override("font_size", 10)
	dial_btn.add_child(btn_label)
	container.add_child(dial_btn)
	
	# Machinist NPC
	_add_machinist_npc(container)

func _create_boss_altar(parent: Node2D):
	var altar = Node2D.new()
	altar.name = "BossAltar"
	altar.position = Vector2(0, 40)
	
	var base = Polygon2D.new()
	base.name = "AltarBase"
	base.polygon = PackedVector2Array([
		Vector2(-30, 0), Vector2(30, 0),
		Vector2(25, -15), Vector2(-25, -15)
	])
	base.color = Color(0.3, 0.3, 0.35)
	altar.add_child(base)
	
	var core = Polygon2D.new()
	core.name = "AltarCore"
	core.polygon = PackedVector2Array([
		Vector2(-20, -15), Vector2(20, -15),
		Vector2(15, -40), Vector2(-15, -40)
	])
	core.color = Color(0.15, 0.15, 0.2)
	altar.add_child(core)
	
	var glow = Polygon2D.new()
	glow.name = "AltarGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-25, -10), Vector2(25, -10),
		Vector2(20, -45), Vector2(-20, -45)
	])
	glow.color = Color(0.9, 0.3, 0.3, 0.0)
	altar.add_child(glow)
	
	var status = Label.new()
	status.name = "AltarLabel"
	status.text = "SEALED"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.position = Vector2(-40, -55)
	status.size = Vector2(80, 20)
	status.add_theme_font_size_override("font_size", 10)
	status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	altar.add_child(status)
	
	var interact = Label.new()
	interact.name = "AltarInteract"
	interact.text = ""
	interact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact.position = Vector2(-50, 10)
	interact.size = Vector2(100, 20)
	interact.add_theme_font_size_override("font_size", 10)
	interact.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	altar.add_child(interact)
	
	parent.add_child(altar)
	_update_boss_altar_visuals()

func _update_boss_altar_visuals():
	var altar = get_node_or_null("CrownCog/BossAltar")
	if not altar:
		return
	var core = altar.get_node_or_null("AltarCore")
	var glow = altar.get_node_or_null("AltarGlow")
	var label = altar.get_node_or_null("AltarLabel")
	var interact = altar.get_node_or_null("AltarInteract")
	
	if not GameState.crown_cog_unlocked:
		if core: core.color = Color(0.15, 0.15, 0.2)
		if glow: glow.color = Color(0.9, 0.3, 0.3, 0.0)
		if label:
			label.text = "SEALED"
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		if interact: interact.text = ""
	else:
		var has_available_boss = false
		for room_id_str in room_metadata:
			var meta = room_metadata[room_id_str]
			if meta.has_boss and not meta.boss_defeated:
				has_available_boss = true
				break
		
		if has_available_boss:
			if core: core.color = Color(0.9, 0.2, 0.2)
			if glow: glow.color = Color(0.9, 0.3, 0.3, 0.6)
			if label:
				label.text = "OPEN"
				label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			if interact: interact.text = "[S] Challenge Boss"
			if glow and not glow.has_meta("pulsing"):
				glow.set_meta("pulsing", true)
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(glow, "modulate:a", 0.3, 1.0)
				tween.tween_property(glow, "modulate:a", 0.6, 1.0)
		else:
			if core: core.color = Color(0.3, 0.8, 0.3)
			if glow: glow.color = Color(0.3, 0.9, 0.3, 0.3)
			if label:
				label.text = "CLEARED"
				label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			if interact: interact.text = ""

func _add_machinist_npc(parent: Node2D):
	var npc = Node2D.new()
	npc.name = "MachinistNPC"
	npc.position = Vector2(0, -120)
	var sprite_path = "res://assets/sprites/floor3/machinist_npc.png"
	if ResourceLoader.exists(sprite_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.scale = Vector2(0.8, 0.8)
		npc.add_child(sprite)
	else:
		var body = Polygon2D.new()
		body.color = Color(0.4, 0.35, 0.3)
		body.polygon = PackedVector2Array([
			Vector2(-15, -30), Vector2(15, -30),
			Vector2(20, 0), Vector2(10, 20),
			Vector2(-10, 20), Vector2(-20, 0)
		])
		npc.add_child(body)
		var eye = Polygon2D.new()
		eye.color = Color(0.9, 0.7, 0.2)
		eye.polygon = PackedVector2Array([
			Vector2(-5, -15), Vector2(5, -15),
			Vector2(5, -5), Vector2(-5, -5)
		])
		npc.add_child(eye)
	var label = Label.new()
	label.text = "[S] The Machinist"
	label.position = Vector2(-50, 25)
	label.size = Vector2(100, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	npc.add_child(label)
	parent.add_child(npc)

# -------------------------------------------------------------------
# Room Puzzles
# -------------------------------------------------------------------

func _initialize_room_puzzles():
	var puzzle_types = {
		1: QuenchPuzzle, 2: SparkPuzzle, 3: GovernorPuzzle,
		4: DraftPuzzle, 5: TemperPuzzle, 6: BeaconPuzzle,
		7: EscapementPuzzle, 8: BearingPuzzle, 9: FlywheelPuzzle,
		10: CounterweightPuzzle, 11: OilerPuzzle, 12: null
	}
	
	for room_id_int in puzzle_types:
		var puzzle_class = puzzle_types[room_id_int]
		if puzzle_class == null:
			continue
		var puzzle = puzzle_class.new()
		puzzle.name = "Puzzle_Room%d" % room_id_int
		puzzle.puzzle_solved.connect(_on_room_puzzle_solved)
		puzzle.combat_triggered.connect(_on_room_combat_triggered)
		puzzle.token_found.connect(_on_room_token_found)
		room_puzzles[room_id_int] = puzzle
		add_child(puzzle)
	
	print("[Floor3] Room puzzles initialized: %d" % room_puzzles.size())

func _on_room_puzzle_solved(room_id: int):
	print("[Floor3] Room %d puzzle solved!" % room_id)
	_exit_room()
	if light_beam_puzzle and light_beam_puzzle.is_widget_in_room(room_id):
		light_beam_puzzle.power_widget(room_id)
		var facing_dir = _get_facing_center_rotation(room_id)
		var widget = light_beam_puzzle.widgets.get(room_id)
		if widget:
			widget.rotation = facing_dir
			light_beam_puzzle.update_widget_visual(room_id)
	
	var meta = room_metadata.get(str(room_id))
	if meta and meta.has_boss and not meta.boss_defeated:
		pending_boss_room_id = room_id
		_show_notification("⚠ %s AWAKENS\nExit the room to face it!" % meta.boss_type, Color(0.9, 0.3, 0.2))
	else:
		meta.boss_defeated = true
		GameState.clear_room(room_id)
		_update_room_cleared_visual(room_id)

func _get_facing_center_rotation(room_id: int) -> int:
	var room_node = rooms.get(str(room_id))
	if not room_node:
		return 0
	var to_center = -room_node.global_position.normalized()
	var best_dot = -1.0
	var best_dir = 0
	for i in 6:
		var dir_vec = HexGrid.get_direction_vector(i).normalized()
		var dot = dir_vec.dot(to_center)
		if dot > best_dot:
			best_dot = dot
			best_dir = i
	return best_dir

func _on_room_combat_triggered(room_id: int, _enemies: Array):
	print("[Floor3] Room %d ambush combat triggered!" % room_id)
	_enter_combat_in_room(room_id, "ambush")

func _on_room_token_found(room_id: int):
	print("[Floor3] Gear Devil Token found in room %d!" % room_id)

# -------------------------------------------------------------------
# Input Override — Floor 3 Hex Movement + Special Keys
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Title screen handling
	if title_screen and title_screen.visible:
		return
	
	# Save dialog handling
	if _is_save_dialog_open():
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_N:
				_on_save_no()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_Y:
				var room12 = rooms.get("12")
				if room12:
					_on_save_yes(room12)
				get_viewport().set_input_as_handled()
		return
	
	# Floor transition prompt
	var transition_prompt = get_node_or_null("FloorTransitionPrompt")
	if transition_prompt and event is InputEventKey and event.pressed:
		if event.keycode == KEY_S or event.keycode == KEY_SPACE:
			_ascend_to_next_floor()
			get_viewport().set_input_as_handled()
			return
	
	# Always handle ESC (even in UI) for closing shop/puzzle/pause
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if in_puzzle:
			_exit_puzzle()
			get_viewport().set_input_as_handled()
		elif in_shop:
			machinist_shop._on_close_shop()
			get_viewport().set_input_as_handled()
		elif not in_combat and not title_screen.visible:
			show_pause()
			get_viewport().set_input_as_handled()
		return
	
	# Block movement/interaction when in combat, transition, or UI
	if in_combat or in_transition or in_ui:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_E, KEY_A, KEY_D, KEY_Z, KEY_X:
				# Let base class handle hex movement
				super._input(event)
				_check_trap_triggers()
				_check_room_entry()
				_check_enemy_combat_triggers()
				_check_world_offering_pickups()
				get_viewport().set_input_as_handled()
			KEY_S, KEY_SPACE:
				_try_interact()
				get_viewport().set_input_as_handled()
			KEY_I:
				if not in_combat and not in_puzzle and not in_shop:
					if offering_inventory and not offering_inventory.visible:
						in_ui = true
						offering_inventory.show_inventory()
						get_viewport().set_input_as_handled()
					elif offering_inventory and offering_inventory.visible:
						offering_inventory.hide_inventory()
						get_viewport().set_input_as_handled()
			KEY_R:
				if not in_combat and not in_puzzle and not in_shop:
					_rotate_dial()
					get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world = get_global_mouse_position()
		var target_hex = HexGrid.world_to_hex(mouse_world)
		
		if HexGrid.hex_distance(player_hex, target_hex) == 1 and not _is_hex_blocked(target_hex):
			player_hex = target_hex
			_update_player_position()
			_check_trap_triggers()
			_check_room_entry()
			_check_enemy_combat_triggers()
			_check_world_offering_pickups()
			get_viewport().set_input_as_handled()
		elif target_hex == player_hex:
			_try_interact()
			get_viewport().set_input_as_handled()

# -------------------------------------------------------------------
# Movement & Interaction (Floor 3 overrides)
# -------------------------------------------------------------------

func _hex_step(move_vec: Vector2):
	if not player_node:
		return
	var step = floor_template.hex_step_size if floor_template else 60.0
	var new_hex = player_hex + _vector_to_hex_dir(move_vec)
	if _is_hex_blocked(new_hex):
		return
	player_hex = new_hex
	player_node.position = HexGrid.hex_to_world(player_hex)
	
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(animator):
			animator.play_idle()

func _vector_to_hex_dir(vec: Vector2) -> Vector2i:
	var angle = vec.angle()
	var degrees = rad_to_deg(angle)
	if degrees >= -22.5 and degrees < 22.5:       return Vector2i(1, 0)   # E
	elif degrees >= 22.5 and degrees < 67.5:      return Vector2i(1, -1)  # NE
	elif degrees >= 67.5 and degrees < 112.5:     return Vector2i(0, -1)  # N... wait
	# Hex directions: 0=NW(-1,0)? No, let's use HexGrid.DIRECTIONS
	# W/E/A/D/Z/X mapping from base class:
	# W: (-0.866, -0.5) = NW = dir 0?
	# Actually let's just map directly
	var best_i = 0
	var best_dot = -1.0
	for i in 6:
		var dir_vec = HexGrid.get_direction_vector(i).normalized()
		var dot = dir_vec.dot(vec.normalized())
		if dot > best_dot:
			best_dot = dot
			best_i = i
	return HexGrid.DIRECTIONS[best_i]

func _update_player_position():
	if player_node:
		player_node.position = HexGrid.hex_to_world(player_hex)
	if in_puzzle and active_puzzle:
		active_puzzle.update_player_position(player_node.global_position)

func _try_interact():
	if in_shop:
		return
	if _is_save_dialog_open():
		return
	if in_puzzle and active_puzzle:
		var handled = active_puzzle.try_interact()
		if handled:
			return
	
	# Crown Cog
	if player_hex == Vector2i(0, 0):
		if GameState.crown_cog_unlocked:
			_enter_crown_cog()
		return
	
	# Room 12 (save)
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var room_hex = HexGrid.world_to_hex(room_node.global_position)
		if player_hex == room_hex and int(room_id_str) == 12:
			_show_save_dialog(room_node)
			return
	
	# Other rooms
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var room_hex = HexGrid.world_to_hex(room_node.global_position)
		if player_hex == room_hex:
			var room_id_int = int(room_id_str)
			var meta = room_metadata.get(room_id_str)
			if room_id_int == 12:
				_show_save_dialog(room_node)
				return
			
			if meta and meta.slot_index == 1:
				if light_beam_puzzle and light_beam_puzzle.is_widget_in_room(room_id_int):
					if meta.boss_defeated:
						light_beam_puzzle.rotate_widget(room_id_int)
						return
					else:
						_enter_room(room_id_int)
						return
				elif not meta.boss_defeated:
					_enter_room(room_id_int)
					return
			else:
				_show_notification("Room locked!\nRotate dial to bring to 1 o'clock", Color(0.9, 0.5, 0.2))
				return
	
	# Adjacent to uncleared room at slot 1
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var room_hex = HexGrid.world_to_hex(room_node.global_position)
		var meta = room_metadata.get(room_id_str)
		if HexGrid.hex_distance(player_hex, room_hex) <= 1 and not meta.boss_defeated:
			if meta.slot_index == 1:
				_enter_room(int(room_id_str))
				return
			else:
				_show_notification("Room locked!\nRotate dial to bring to 1 o'clock", Color(0.9, 0.5, 0.2))
				return

func _check_room_entry():
	if in_shop:
		return
	
	# Crown Cog
	if player_hex == Vector2i(0, 0):
		var from_valid = false
		for room_id_str in rooms:
			var meta = room_metadata.get(room_id_str)
			if meta and meta.slot_index in [1, 2]:
				var room_hex = HexGrid.world_to_hex(rooms[room_id_str].global_position)
				if HexGrid.hex_distance(player_hex, room_hex) <= 2:
					from_valid = true
					break
		if GameState.crown_cog_unlocked and from_valid:
			_enter_room(0)
		return
	
	# Auto-enter room
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var room_hex = HexGrid.world_to_hex(room_node.global_position)
		if player_hex == room_hex:
			var room_id_int = int(room_id_str)
			var meta = room_metadata.get(room_id_str)
			if room_id_int == 12:
				return
			if meta and meta.slot_index == 1:
				if not meta.boss_defeated:
					_enter_room(room_id_int)
				return
			if not meta.boss_defeated:
				_show_notification("Room locked!\nRotate dial to bring to 1 o'clock", Color(0.9, 0.5, 0.2))
			return

func _enter_room(room_id):
	if in_combat or in_puzzle or in_shop:
		return
	
	# Unlock combat when entering Room 1 (The Quench puzzle)
	if room_id == 1 and not combat_unlocked:
		combat_unlocked = true
		_enable_combat_on_all_rooms()
		_show_notification("⚙ The offering is taken... Combat unlocked!", Color(0.9, 0.7, 0.3))
		print("[Floor3] Combat unlocked by Room 1 entry")
	
	if camera:
		camera.zoom = Vector2(0.7, 0.7)
	
	# Play room enter sound
	_play_audio("room_enter")
	
	# Show interior
	if room_id == 0:
		if not GameState.crown_cog_unlocked:
			print("[Floor3] Crown Cog is locked!")
			return
		_enter_crown_cog()
		return
	
	var room_node = rooms.get(str(room_id))
	if room_node and room_node.has_method("show_interior"):
		room_node.show_interior()
	
	print("[Floor3] Entering room %d" % room_id)
	
	# Gate combat globally until unlocked
	if not combat_unlocked:
		_show_notification("The constructs are dormant...\nAwaken the Gearworks first.", Color(0.7, 0.7, 0.7))
		return
	
	if room_puzzles.has(room_id):
		_start_puzzle(room_id)
	else:
		_enter_combat_in_room(room_id, "enemies")

func _start_puzzle(room_id):
	in_puzzle = true
	in_ui = true
	active_puzzle = room_puzzles[room_id]
	var room_node = rooms.get(str(room_id))
	if room_node:
		active_puzzle.position = room_node.global_position
	if active_puzzle.state == RoomPuzzle.PuzzleState.LOCKED:
		active_puzzle.state = RoomPuzzle.PuzzleState.ACTIVE
	_show_puzzle_ui(true)
	if player_node:
		active_puzzle.update_player_position(player_node.global_position)
	print("[Floor3] Started puzzle in room %d" % room_id)

func _exit_puzzle():
	if camera:
		camera.zoom = Vector2(0.5, 0.5)
	
	# Play room exit sound
	_play_audio("room_exit")
	
	# Hide all interiors
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		if room_node and room_node.has_method("hide_interior"):
			room_node.hide_interior()
	
	if not in_puzzle:
		return
	
	if pending_boss_room_id > 0:
		var room_id = pending_boss_room_id
		pending_boss_room_id = 0
		in_puzzle = false
		in_ui = false
		active_puzzle = null
		_show_puzzle_ui(false)
		_enter_combat_in_room(room_id, "boss")
		return
	
	in_puzzle = false
	in_ui = false
	active_puzzle = null
	_show_puzzle_ui(false)
	_cleanup_combat_traps()
	print("[Floor3] Exited puzzle")

func _exit_room():
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		if room_node and room_node.has_method("hide_interior"):
			room_node.hide_interior()
	_cleanup_combat_traps()

func _show_puzzle_ui(show: bool):
	var ui = get_node_or_null("PuzzleUI")
	if show and not ui:
		ui = CanvasLayer.new()
		ui.name = "PuzzleUI"
		var panel = ColorRect.new()
		panel.color = Color(0.1, 0.1, 0.15, 0.7)
		panel.size = Vector2(300, 100)
		panel.position = Vector2(20, 520)
		ui.add_child(panel)
		var label = Label.new()
		label.text = "PUZZLE MODE\n[S] Interact | [W/E/A/D/Z/X] Move | [ESC] Exit Room"
		label.position = Vector2(30, 530)
		label.size = Vector2(280, 80)
		label.add_theme_font_size_override("font_size", 12)
		label.modulate = Color(0.8, 0.8, 0.9)
		ui.add_child(label)
		add_child(ui)
	elif not show and ui:
		ui.queue_free()

func _enter_crown_cog():
	print("[Floor3] Entering Crown Cog...")
	var altar = get_node_or_null("CrownCog/BossAltar")
	if altar:
		var interact_label = altar.get_node_or_null("AltarInteract")
		if interact_label and interact_label.text == "[S] Challenge Boss":
			_on_boss_challenged()
			return
	in_shop = true
	in_ui = true
	machinist_shop.show_shop()

func _on_shop_closed():
	in_shop = false
	in_ui = false
	if camera:
		camera.zoom = Vector2(0.5, 0.5)

# -------------------------------------------------------------------
# Combat (Floor 3 overrides)
# -------------------------------------------------------------------

func _on_combat_ended(victory: bool):
	print("[Floor3] Combat ended — victory: %s" % victory)
	in_combat = false
	
	if camera:
		camera.zoom = Vector2(0.5, 0.5)
	
	# Find room by player position
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var room_hex = HexGrid.world_to_hex(room_node.global_position)
		if player_hex == room_hex and victory:
			var meta = room_metadata.get(room_id_str)
			if meta:
				meta.boss_defeated = true
				GameState.clear_room(meta.id)
				_update_room_cleared_visual(meta.id)
			_despawn_enemies_in_room(int(room_id_str))
			break
	
	var quiddity_earned = combat_manager.player_quiddity if combat_manager else 0
	GameState.add_quiddity(quiddity_earned)
	
	if not victory:
		_handle_player_death("You were defeated in combat...")
		return
	
	# Boss victory
	if combat_manager and combat_manager.is_boss_mode:
		print("[Floor3] BOSS DEFEATED!")
		for room_id_str in room_metadata:
			var meta = room_metadata[room_id_str]
			if meta.has_boss and not meta.boss_defeated:
				meta.boss_defeated = true
				meta.is_cleared = true
				GameState.clear_room(meta.id)
				_update_room_cleared_visual(meta.id)
				break
		
		# Check if all bosses defeated + Crown Cog unlocked → show ascend
		if _check_all_bosses_defeated() and GameState.crown_cog_unlocked:
			_show_ascend_prompt()
		elif victory_screen:
			victory_screen.show_victory()
		return
	
	# Normal post-combat
	if post_combat_ui:
		post_combat_ui.show_post_combat(victory, quiddity_earned, last_combat_faction)

func _check_all_bosses_defeated() -> bool:
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.has_boss and not meta.boss_defeated:
			return false
	return true

func _show_ascend_prompt():
	"""Show prompt to ascend to Floor 4 when all conditions met."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "The Crown Cog turns freely.
Press [S] to Ascend to Floor 4"
	prompt.position = Vector2(660, 500)
	prompt.size = Vector2(600, 80)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	prompt.add_theme_constant_override("shadow_outline_size", 4)
	add_child(prompt)
	_show_notification("🌟 THE GEARWORKS ARE COMPLETE 🌟
Ascend when ready.", Color(0.3, 0.9, 0.3))

func _on_post_combat_confirmed(bought_cards: Array[String], burned_cards: Array[String], gems_earned: int):
	print("[Floor3] Post-combat confirmed")
	var summary = ""
	if bought_cards.size() > 0:
		summary += "Bought %d cards. " % bought_cards.size()
	if burned_cards.size() > 0:
		summary += "Burned %d for %d💎. " % [burned_cards.size(), gems_earned]
	if summary.is_empty():
		summary = "No changes made."
	_show_notification("Rewards confirmed\n%s" % summary, Color(0.3, 0.9, 0.3))
	
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.spawned_enemies.size() > 0:
			for enemy_node in meta.spawned_enemies:
				if is_instance_valid(enemy_node):
					enemy_node.queue_free()
			meta.spawned_enemies.clear()

func _enter_combat_in_room(room_id, encounter_type: String = "enemies", forced_enemies: Array[CombatManager.EnemyData] = []):
	var meta = room_metadata.get(str(room_id))
	if not meta:
		return
	
	var enemies: Array[CombatManager.EnemyData] = []
	var encounter_name = ""
	var encounter_flavor = ""
	last_combat_faction = ""
	
	if forced_enemies.size() > 0:
		enemies = forced_enemies.duplicate()
		encounter_name = "Trap Ambush"
		encounter_flavor = "A trap springs hostile constructs!"
		last_combat_faction = "Construct"
	elif meta.has_boss and encounter_type == "boss":
		var boss_comp = RoomEnemyDatabase.get_boss_composition(meta.boss_type)
		encounter_name = boss_comp["name"]
		encounter_flavor = boss_comp["flavor"]
		for template in boss_comp["enemies"]:
			enemies.append(template.to_combat_data())
			last_combat_faction = _extract_faction_from_path(template.sprite_path)
		enemies.append(CombatManager.EnemyData.new("Piston Assembly", 15, 3))
	else:
		var comp = RoomEnemyDatabase.get_room_composition(room_id, encounter_type)
		encounter_name = comp["name"]
		encounter_flavor = comp["flavor"]
		for template in comp["enemies"]:
			enemies.append(template.to_combat_data())
			var path_parts = template.sprite_path.split("/")
			for part in path_parts:
				if part in CardDB.FACTIONS:
					last_combat_faction = part
					break
	
	var room_node = rooms.get(str(room_id))
	if room_node:
		meta.spawned_enemies = EnemySpawner.spawn_enemies_in_room(room_node, enemies)
		EnemySpawner.show_spawn_animation(meta.spawned_enemies)
		await get_tree().create_timer(0.5).timeout
	
	_show_notification("⚔ %s\n%s" % [encounter_name, encounter_flavor], Color(0.9, 0.7, 0.3))
	await get_tree().create_timer(1.0).timeout
	
	in_combat = true
	
	var deck: Array[CardData] = []
	if GameState.player_deck.size() > 0:
		deck = GameState.get_deck_card_data()
	else:
		deck = CardDB.get_starter_deck()
		for card in deck:
			GameState.player_deck.append(card.id)
	
	if combat_manager:
		if meta.has_boss and encounter_type == "boss":
			combat_manager.enable_boss_mode(meta.boss_type)
		combat_manager.start_combat(enemies, deck)
	
	print("[Floor3] Combat started: %s vs %d enemies" % [encounter_name, enemies.size()])

func _on_boss_challenged():
	in_shop = false
	print("[Floor3] Boss challenged!")
	var boss_names = ["TheCaldera", "GearMother", "GoblinKingGrimgut", "TheInterview", "TheEidolon"]
	var selected_boss = boss_names[randi() % boss_names.size()]
	var boss_comp = RoomEnemyDatabase.get_boss_composition(selected_boss)
	
	var enemies: Array[CombatManager.EnemyData] = []
	for template in boss_comp["enemies"]:
		enemies.append(template.to_combat_data())
	enemies.append(CombatManager.EnemyData.new("Piston Assembly", 20, 4))
	enemies.append(CombatManager.EnemyData.new("Diagnostic Eye", 15, 3))
	
	in_combat = true
	_show_notification("👑 FINAL BOSS\n%s" % boss_comp["flavor"], Color(0.9, 0.2, 0.2))
	await get_tree().create_timer(1.5).timeout
	
	var deck: Array[CardData] = []
	if GameState.player_deck.size() > 0:
		deck = GameState.get_deck_card_data()
	else:
		deck = CardDB.get_starter_deck()
	
	if combat_manager:
		combat_manager.enable_boss_mode(selected_boss)
		combat_manager.start_combat(enemies, deck)

func _extract_faction_from_path(sprite_path: String) -> String:
	var parts = sprite_path.split("/")
	for part in parts:
		match part:
			"Construct", "Elemental", "Goblin", "Demon", "Undead", "Aberration":
				return part
		if CardDB and "FACTIONS" in CardDB and part in CardDB.FACTIONS:
			return part
	return "Construct"

# -------------------------------------------------------------------
# Object Interaction Override
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	match object_type:
		"Save Game":
			var room12 = rooms.get("12")
			if room12:
				_show_save_dialog(room12)
		"Talk to Construct", "The Machinist":
			_enter_crown_cog()
		_:
			print("[Floor3] Interaction: %s" % object_type)

# -------------------------------------------------------------------
# Dial Rotation
# -------------------------------------------------------------------

func _rotate_dial():
	if in_combat or in_puzzle:
		return
	
	# Unlock combat on first rotation
	if not combat_unlocked:
		combat_unlocked = true
		_enable_combat_on_all_rooms()
		_show_notification("⚙ The Gearworks awaken... Combat unlocked!", Color(0.9, 0.7, 0.3))
		print("[Floor3] Combat unlocked by dial rotation")
	
	# Play dial rotation sound
	_play_audio("dial_rotate")
	
	dial_position = (dial_position + 1) % 10
	rotation_angle += ROTATION_STEP
	print("[Floor3] Rotating dial to position %d" % dial_position)
	
	# Animate Crown Cog
	var crown = get_node_or_null("CrownCog/CogSprite") or get_node_or_null("CrownCog/CogShape")
	if crown:
		var tween = create_tween()
		tween.tween_property(crown, "rotation_degrees", rotation_angle, 0.5)
	
	var slot_angles = floor3_template.SLOT_ANGLES
	
	# Rotate non-stationary rooms
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if not meta.is_stationary:
			meta.slot_index = (meta.slot_index % 11) + 1
			meta.current_angle = slot_angles[meta.slot_index]
			var new_pos = Vector2(
				cos(deg_to_rad(meta.current_angle)) * OUTER_RADIUS,
				sin(deg_to_rad(meta.current_angle)) * OUTER_RADIUS
			)
			meta.position = new_pos  # Not actually used; we update the node directly
			
			var room_node = rooms.get(room_id_str)
			if room_node:
				var tween = create_tween()
				tween.tween_property(room_node, "position", new_pos, 0.5)
			
			# Update Floor3RoomBase slot_index
			if room_node is Floor3RoomBase:
				room_node.slot_index = meta.slot_index
	
	# Update light beam widgets
	if light_beam_puzzle:
		var room_positions = {}
		for room_id_str in rooms:
			room_positions[int(room_id_str)] = rooms[room_id_str].global_position
		light_beam_puzzle.update_all_widget_visuals(room_positions)
	
	GameState.dial_position = dial_position
	_spawn_traps_for_rotation()

# -------------------------------------------------------------------
# Light Beam Puzzle
# -------------------------------------------------------------------

func _on_puzzle_complete():
	print("[Floor3] Light Beam Puzzle Complete!")
	GameState.crown_cog_unlocked = true
	_update_boss_altar_visuals()
	
	var crown = get_node_or_null("CrownCog/CogSprite") or get_node_or_null("CrownCog/CogShape")
	if crown:
		var tween = create_tween()
		tween.tween_property(crown, "modulate", Color(1.0, 1.0, 0.5), 0.5)
		tween.tween_property(crown, "modulate", Color(0.9, 0.8, 0.3), 0.5)
	
	_show_notification("CROWN COG UNLOCKED!", Color(1.0, 0.9, 0.3))

# -------------------------------------------------------------------
# Trap System
# -------------------------------------------------------------------

func _check_trap_triggers():
	if trap_hex_map.has(player_hex):
		var trap = trap_hex_map[player_hex]
		if trap and trap.state != Trap.TrapState.DISABLED:
			trap.trigger_trap()

func _spawn_traps_for_rotation():
	_clear_disabled_traps()
	if active_traps.size() >= 8:
		return
	if randf() > TRAP_SPAWN_CHANCE:
		return
	
	var available_rooms = []
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.id != 12 and not GameState.is_room_cleared(meta.id):
			available_rooms.append(meta)
	
	if available_rooms.is_empty():
		return
	
	var target_meta = available_rooms[randi() % available_rooms.size()]
	var room_node = rooms.get(str(target_meta.id))
	var room_hex = HexGrid.world_to_hex(room_node.global_position) if room_node else Vector2i.ZERO
	var trap_type = _pick_trap_for_room(target_meta.id)
	var spawn_hex = _find_trap_spawn_hex(room_hex)
	if spawn_hex == Vector2i(-999, -999):
		return
	
	var trap = _create_trap(trap_type)
	if trap:
		trap.position = HexGrid.hex_to_world(spawn_hex)
		trap.affected_hexes = [spawn_hex]
		trap.trap_triggered.connect(_on_trap_triggered)
		trap.trap_damage_dealt.connect(_on_trap_damage)
		trap.trap_terrain_changed.connect(_on_trap_terrain_changed)
		trap.trap_combat_forced.connect(_on_trap_combat_forced)
		active_traps.append(trap)
		trap_hex_map[spawn_hex] = trap
		add_child(trap)
		print("[Floor3] Spawned %s at hex %s (room %d)" % [trap.trap_name, str(spawn_hex), target_meta.id])

func _pick_trap_for_room(room_id: int) -> String:
	match room_id:
		1, 12: return "grasping_cog"
		2, 4, 5: return "compression"
		3, 7: return "warning_sermon"
		6, 8, 10: return "recalibration"
		9, 11: return "grasping_cog"
		_: return "grasping_cog"

func _find_trap_spawn_hex(room_hex: Vector2i) -> Vector2i:
	var candidates = []
	for q in range(-2, 3):
		for r in range(-2, 3):
			if abs(q + r) > 2:
				continue
			var check = room_hex + Vector2i(q, r)
			var dist = HexGrid.hex_distance(room_hex, check)
			if dist <= 1:
				continue
			if trap_hex_map.has(check):
				continue
			if _is_hex_blocked(check):
				continue
			candidates.append(check)
	if candidates.is_empty():
		return Vector2i(-999, -999)
	return candidates[randi() % candidates.size()]

func _create_trap(trap_type: String) -> Trap:
	match trap_type:
		"grasping_cog": return GraspingCogTrap.new()
		"compression": return CompressionTrap.new()
		"recalibration": return RecalibrationTrap.new()
		"warning_sermon": return WarningSermonTrap.new()
		_: return null

func _clear_disabled_traps():
	var to_remove = []
	for trap in active_traps:
		if trap.state == Trap.TrapState.DISABLED:
			to_remove.append(trap)
	for trap in to_remove:
		active_traps.erase(trap)
		for hex in trap.affected_hexes:
			if trap_hex_map.has(hex) and trap_hex_map[hex] == trap:
				trap_hex_map.erase(hex)
		trap.queue_free()

func _on_trap_triggered(trap_name: String, effect: String):
	print("[Floor3] Trap triggered: %s - %s" % [trap_name, effect])
	_show_notification("%s triggered!" % trap_name, Color(0.9, 0.2, 0.2))

func _on_trap_damage(amount: int, damage_type: String):
	print("[Floor3] Trap damage: %d %s" % [amount, damage_type])
	if player_node:
		_show_damage_flash()

func _on_trap_terrain_changed(hexes: Array[Vector2i], passable: bool):
	for hex in hexes:
		if passable:
			blocked_hexes.erase(hex)
		else:
			if not hex in blocked_hexes:
				blocked_hexes.append(hex)

func _on_trap_combat_forced(_enemies: Array):
	print("[Floor3] Trap forced combat!")
	
	# Gate trap combat until unlocked
	if not combat_unlocked:
		_show_notification("The trap is inactive... the Gearworks are still dormant.", Color(0.7, 0.7, 0.7))
		return
	
	var triggering_trap = null
	if trap_hex_map.has(player_hex):
		triggering_trap = trap_hex_map[player_hex]
	
	if triggering_trap:
		var trap_type = triggering_trap.get_class()
		var comp = RoomEnemyDatabase.get_trap_composition(trap_type)
		GameState.add_temp_effect("trap_debuff", 60)
		_show_notification("TRAP AMBUSH! %s" % comp["name"], Color(0.9, 0.3, 0.1))
		var combat_enemies: Array[CombatManager.EnemyData] = []
		for template in comp["enemies"]:
			combat_enemies.append(template.to_combat_data())
		var target_room_id = 1
		for room_id_str in room_metadata:
			var meta = room_metadata[room_id_str]
			if not meta.boss_defeated:
				target_room_id = meta.id
				break
		_enter_combat_in_room(target_room_id, "trap", combat_enemies)
	else:
		_enter_combat_in_room(1, "trap")

func _cleanup_combat_traps():
	var to_remove = []
	for trap in active_traps:
		if not is_instance_valid(trap):
			to_remove.append(trap)
			continue
		if trap.pushes_to_combat:
			to_remove.append(trap)
			for hex in trap.affected_hexes:
				if trap_hex_map.has(hex) and trap_hex_map[hex] == trap:
					trap_hex_map.erase(hex)
			trap.queue_free()
	for trap in to_remove:
		if trap in active_traps:
			active_traps.erase(trap)

# -------------------------------------------------------------------
# Overworld Enemies
# -------------------------------------------------------------------

func _spawn_overworld_enemies():
	overworld_enemies.clear()
	var spawned_count = 0
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.boss_defeated or meta.id == 12:
			continue
		if randf() > ENEMY_SPAWN_CHANCE:
			continue
		var room_node = rooms.get(room_id_str)
		var room_hex = HexGrid.world_to_hex(room_node.global_position) if room_node else Vector2i.ZERO
		var comp = RoomEnemyDatabase.get_room_composition(meta.id, "enemies")
		var templates = comp["enemies"]
		if templates.is_empty():
			continue
		var template = templates[randi() % templates.size()]
		var enemy = OverworldEnemy.new()
		enemy.name = "OverworldEnemy_%d" % next_enemy_id
		enemy.setup(next_enemy_id, room_hex, _get_faction_for_room(meta.id), template.name, template.sprite_path)
		enemy.patrol_radius = 5
		enemy.can_move_to = func(hex: Vector2i) -> bool: return _can_enemy_move_to(hex)
		enemy.enemy_name = template.name
		enemy.enemy_spotted_player.connect(_on_enemy_spotted)
		enemy.enemy_lost_player.connect(_on_enemy_lost)
		enemy.enemy_combat_triggered.connect(_on_enemy_combat)
		add_child(enemy)
		overworld_enemies.append(enemy)
		next_enemy_id += 1
		spawned_count += 1
		if spawned_count >= MAX_OVERWORLD_ENEMIES:
			break
	print("[Floor3] Spawned %d overworld enemies" % spawned_count)

func _update_overworld_enemies(delta: float):
	for enemy in overworld_enemies:
		if not is_instance_valid(enemy):
			continue
		enemy.check_player_proximity(player_hex)
		if enemy.is_combat_triggered(player_hex):
			_trigger_enemy_combat(enemy)
			return

func _check_enemy_combat_triggers():
	for enemy in overworld_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.is_combat_triggered(player_hex):
			_trigger_enemy_combat(enemy)
			return

func _trigger_enemy_combat(primary_enemy: OverworldEnemy):
	if in_combat or in_puzzle or in_shop:
		return
	
	# Gate overworld enemy combat until unlocked
	if not combat_unlocked:
		_show_notification("This construct is dormant... for now.", Color(0.7, 0.7, 0.7))
		return
	
	print("[Floor3] Enemy combat triggered by %s" % primary_enemy.enemy_name)
	
	var nearest_room_id = 1
	var nearest_dist = 9999
	for room_id_str in rooms:
		var room_node = rooms[room_id_str]
		var r_hex = HexGrid.world_to_hex(room_node.global_position)
		var d = HexGrid.hex_distance(player_hex, r_hex)
		if d < nearest_dist:
			nearest_dist = d
			nearest_room_id = int(room_id_str)
	
	var combat_enemies: Array[CombatManager.EnemyData] = []
	var joined_names: Array[String] = [primary_enemy.enemy_name]
	var enemies_to_despawn: Array[OverworldEnemy] = [primary_enemy]
	
	var primary_template = RoomEnemyDatabase.get_enemy_template(primary_enemy.combat_template_name)
	if primary_template:
		last_combat_faction = _extract_faction_from_path(primary_template.sprite_path)
		combat_enemies.append(primary_template.to_combat_data())
	
	for other in overworld_enemies:
		if other == primary_enemy:
			continue
		if not is_instance_valid(other):
			continue
		var should_join = false
		if other.state in [OverworldEnemy.State.ALERTED, OverworldEnemy.State.CHASING]:
			should_join = true
		var dist_to_primary = HexGrid.hex_distance(primary_enemy.current_hex, other.current_hex)
		if dist_to_primary <= 3:
			should_join = true
		if should_join:
			var other_template = RoomEnemyDatabase.get_enemy_template(other.combat_template_name)
			if other_template:
				combat_enemies.append(other_template.to_combat_data())
				joined_names.append(other.enemy_name)
				enemies_to_despawn.append(other)
	
	var banner = "⚔ AMBUSH!\n"
	if joined_names.size() == 1:
		banner += joined_names[0]
	else:
		banner += "%s + %d allies!" % [joined_names[0], joined_names.size() - 1]
	_show_notification(banner, Color(0.9, 0.3, 0.2))
	
	for e in enemies_to_despawn:
		overworld_enemies.erase(e)
		e.force_despawn()
	
	if combat_enemies.size() > 0:
		_enter_combat_with_enemies(combat_enemies, nearest_room_id)
	else:
		_enter_combat_in_room(nearest_room_id, "enemies")

func _enter_combat_with_enemies(enemies: Array[CombatManager.EnemyData], room_id: int):
	var room_node = rooms.get(str(room_id))
	var meta = room_metadata.get(str(room_id))
	if room_node and meta:
		meta.spawned_enemies = EnemySpawner.spawn_enemies_in_room(room_node, enemies)
		EnemySpawner.show_spawn_animation(meta.spawned_enemies)
		await get_tree().create_timer(0.5).timeout
	
	in_combat = true
	var deck: Array[CardData] = []
	if GameState.player_deck.size() > 0:
		deck = GameState.get_deck_card_data()
	else:
		deck = CardDB.get_starter_deck()
		for card in deck:
			GameState.player_deck.append(card.id)
	
	if combat_manager:
		combat_manager.start_combat(enemies, deck)

func _despawn_enemies_in_room(room_id: int):
	var room_node = rooms.get(str(room_id))
	var room_hex = HexGrid.world_to_hex(room_node.global_position) if room_node else Vector2i.ZERO
	var to_remove = []
	for enemy in overworld_enemies:
		if not is_instance_valid(enemy):
			to_remove.append(enemy)
			continue
		if enemy.patrol_center_hex == room_hex:
			to_remove.append(enemy)
			enemy.force_despawn()
	for enemy in to_remove:
		overworld_enemies.erase(enemy)

func _on_enemy_spotted(_enemy_id: int, distance: int):
	if overworld_hud:
		overworld_hud.show_message("⚠ Enemy spotted! (%d hexes)" % distance, 1.5, Color(0.9, 0.5, 0.2))

func _on_enemy_lost(_enemy_id: int):
	if overworld_hud:
		overworld_hud.show_message("Enemy lost track...", 1.0, Color(0.5, 0.9, 0.5))

func _on_enemy_combat(enemy_id: int, template_name: String):
	print("[Floor3] Enemy %d (%s) triggered combat" % [enemy_id, template_name])

func _get_faction_for_room(room_id: int) -> String:
	var comp = RoomEnemyDatabase.get_room_composition(room_id, "enemies")
	var templates = comp["enemies"]
	if templates.size() > 0:
		return _extract_faction_from_path(templates[0].sprite_path)
	return "Construct"

# -------------------------------------------------------------------
# World Offerings
# -------------------------------------------------------------------

func _spawn_world_offerings():
	world_offerings.clear()
	var spawned_count = 0
	var offering_pool = GameState.OFFERING_DATABASE.keys()
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.boss_defeated or meta.id == 12:
			continue
		if randf() > OFFERING_SPAWN_CHANCE:
			continue
		var room_node = rooms.get(room_id_str)
		var room_hex = HexGrid.world_to_hex(room_node.global_position) if room_node else Vector2i.ZERO
		var candidates = []
		for q in range(-3, 4):
			for r in range(-3, 4):
				if abs(q + r) > 3:
					continue
				var check = room_hex + Vector2i(q, r)
				var dist = HexGrid.hex_distance(room_hex, check)
				if dist == 0 or dist > 3:
					continue
				if _is_hex_blocked(check):
					continue
				if trap_hex_map.has(check):
					continue
				candidates.append(check)
		if candidates.is_empty():
			continue
		var spawn_hex = candidates[randi() % candidates.size()]
		var offering_id = offering_pool[randi() % offering_pool.size()]
		var pickup = WorldOfferingPickup.new()
		pickup.setup(offering_id, spawn_hex)
		pickup.offering_collected.connect(_on_world_offering_collected)
		add_child(pickup)
		world_offerings.append(pickup)
		spawned_count += 1
		if spawned_count >= MAX_WORLD_OFFERINGS:
			break
	print("[Floor3] Spawned %d world offerings" % spawned_count)

func _check_world_offering_pickups():
	var to_remove = []
	for pickup in world_offerings:
		if not is_instance_valid(pickup):
			to_remove.append(pickup)
			continue
		if pickup.check_player_collision(player_hex):
			to_remove.append(pickup)
			return
	for pickup in to_remove:
		world_offerings.erase(pickup)

func _enable_combat_on_all_rooms():
	"""Re-enable auto_spawn on all rooms when combat is unlocked."""
	for room_id_str in rooms:
		var room = rooms[room_id_str]
		if room and room.has_method("set"):
			room.auto_spawn = true
	print("[Floor3] Combat enabled on all rooms")

func _on_world_offering_collected(offering_id: String, _hex: Vector2i):
	var data = GameState.get_offering_data(offering_id)
	var name = data.get("name", offering_id)
	_show_notification("🎁 Found: %s!" % name, Color(0.9, 0.7, 0.3))
	
	# Unlock combat on first offering pickup
	if not combat_unlocked:
		combat_unlocked = true
		_show_notification("⚙ The offering awakens the Gearworks... Combat unlocked!", Color(0.9, 0.7, 0.3))
		print("[Floor3] Combat unlocked by offering pickup")
		_enable_combat_on_all_rooms()

# -------------------------------------------------------------------
# Save Dialog
# -------------------------------------------------------------------

func _is_save_dialog_open() -> bool:
	return save_dialog_overlay != null and is_instance_valid(save_dialog_overlay) and save_dialog_overlay.visible

func _show_save_dialog(room_node: Node2D):
	if _is_save_dialog_open():
		return
	in_ui = true
	
	save_dialog_overlay = CanvasLayer.new()
	save_dialog_overlay.name = "SaveDialogOverlay"
	add_child(save_dialog_overlay)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	save_dialog_overlay.add_child(bg)
	
	var panel = ColorRect.new()
	panel.color = Color(0.12, 0.15, 0.18, 1.0)
	panel.size = Vector2(360, 220)
	panel.position = Vector2(780, 430)
	save_dialog_overlay.add_child(panel)
	
	var title = Label.new()
	title.text = "💾 SAVE GAME"
	title.position = Vector2(780, 445)
	title.size = Vector2(360, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	save_dialog_overlay.add_child(title)
	
	var msg = Label.new()
	msg.text = "Record your progress to the crystal?"
	msg.position = Vector2(790, 500)
	msg.size = Vector2(340, 30)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	save_dialog_overlay.add_child(msg)
	
	var stats = Label.new()
	var cleared = GameState.get_cleared_room_count()
	stats.text = "Rooms: %d/12  |  Gems: %d" % [cleared, GameState.gems]
	stats.position = Vector2(790, 535)
	stats.size = Vector2(340, 20)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	save_dialog_overlay.add_child(stats)
	
	var yes_btn = Button.new()
	yes_btn.text = "YES — Save"
	yes_btn.position = Vector2(800, 575)
	yes_btn.size = Vector2(150, 45)
	yes_btn.add_theme_font_size_override("font_size", 14)
	yes_btn.pressed.connect(_on_save_yes.bind(room_node))
	save_dialog_overlay.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "NO — Cancel"
	no_btn.position = Vector2(970, 575)
	no_btn.size = Vector2(150, 45)
	no_btn.add_theme_font_size_override("font_size", 14)
	no_btn.pressed.connect(_on_save_no)
	save_dialog_overlay.add_child(no_btn)
	
	var hint = Label.new()
	hint.text = "[Enter / Click] Confirm    [ESC] Cancel"
	hint.position = Vector2(790, 625)
	hint.size = Vector2(340, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	save_dialog_overlay.add_child(hint)
	
	yes_btn.grab_focus()

func _on_save_yes(_room_node: Node2D):
	in_ui = false
	_close_save_dialog()
	GameState.save_game()
	if overworld_hud:
		overworld_hud.show_message("💾 Game Saved!", 2.5, Color(0.3, 0.9, 0.3))
	print("[Floor3] Game saved")

func _on_save_no():
	in_ui = false
	_close_save_dialog()
	if overworld_hud:
		overworld_hud.show_message("Save cancelled.", 1.5, Color(0.7, 0.7, 0.7))

func _close_save_dialog():
	if save_dialog_overlay and is_instance_valid(save_dialog_overlay):
		save_dialog_overlay.queue_free()
		save_dialog_overlay = null
		in_ui = false

# -------------------------------------------------------------------
# Death Handling
# -------------------------------------------------------------------

func _on_player_died():
	_handle_player_death("The Tower claims another...")

func _handle_player_death(flavor_text: String):
	print("[Floor3] PLAYER DIED — %s" % flavor_text)
	in_combat = false
	in_puzzle = false
	in_shop = false
	
	if overworld_hud:
		overworld_hud.show_damage_flash()
	_show_notification("💀 YOU DIED 💀\n%s" % flavor_text, Color(0.8, 0.1, 0.1))
	await get_tree().create_timer(2.0).timeout
	_show_game_over_screen()

func _show_game_over_screen():
	var overlay = CanvasLayer.new()
	overlay.name = "GameOverOverlay"
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	overlay.add_child(bg)
	
	var title = Label.new()
	title.text = "THE MACHINE STOPS"
	title.position = Vector2(610, 300)
	title.size = Vector2(700, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	overlay.add_child(title)
	
	var flavor = Label.new()
	flavor.text = "Your gears have ground to a halt."
	flavor.position = Vector2(610, 380)
	flavor.size = Vector2(700, 30)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 16)
	flavor.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	overlay.add_child(flavor)
	
	var stats = Label.new()
	var cleared = GameState.get_cleared_room_count()
	stats.text = "Rooms cleared: %d/12  |  Gems: %d  |  Tokens: %d" % [
		cleared, GameState.gems, GameState.get_gear_devil_token_count()
	]
	stats.position = Vector2(610, 430)
	stats.size = Vector2(700, 30)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	overlay.add_child(stats)
	
	var restart_btn = Button.new()
	restart_btn.text = "⚙ Restart Run"
	restart_btn.position = Vector2(810, 500)
	restart_btn.size = Vector2(300, 50)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart_run.bind(overlay))
	overlay.add_child(restart_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.position = Vector2(860, 570)
	quit_btn.size = Vector2(200, 40)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.pressed.connect(get_tree().quit)
	overlay.add_child(quit_btn)

func _on_restart_run(overlay: CanvasLayer):
	overlay.queue_free()
	GameState.reset_floor()
	GameState.player_hp = GameState.player_max_hp
	GameState.player_quiddity = 0
	for enemy in overworld_enemies:
		if is_instance_valid(enemy):
			enemy.force_despawn()
	overworld_enemies.clear()
	next_enemy_id = 1
	get_tree().reload_current_scene()

# -------------------------------------------------------------------
# Title Screen Handlers
# -------------------------------------------------------------------

func _on_title_new_game():
	GameState.new_game()
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		meta.boss_defeated = false
		meta.is_cleared = false
		_update_room_cleared_visual(meta.id, false)
	
	# Reset dial
	dial_position = 0
	rotation_angle = 0.0
	var slot_angles = floor3_template.SLOT_ANGLES
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.is_stationary:
			meta.slot_index = 0
		else:
			meta.slot_index = meta.id
		meta.current_angle = slot_angles[meta.slot_index]
		var room_node = rooms.get(room_id_str)
		if room_node:
			room_node.position = Vector2(
				cos(deg_to_rad(meta.current_angle)) * OUTER_RADIUS,
				sin(deg_to_rad(meta.current_angle)) * OUTER_RADIUS
			)
	
	# Reset player to Room 12
	var start_room = rooms.get("12")
	if start_room:
		player_hex = HexGrid.world_to_hex(start_room.global_position)
		if player_node:
			player_node.global_position = start_room.global_position
		current_room_id = "12"
	
	if light_beam_puzzle:
		light_beam_puzzle.reset_widgets()
	
	for trap in active_traps:
		if is_instance_valid(trap):
			trap.queue_free()
	active_traps.clear()
	trap_hex_map.clear()
	
	for enemy in overworld_enemies:
		if is_instance_valid(enemy):
			enemy.force_despawn()
	overworld_enemies.clear()
	next_enemy_id = 1
	_spawn_overworld_enemies()
	
	print("[Floor3] New game started")

func _on_title_continue():
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		meta.boss_defeated = GameState.is_room_cleared(meta.id)
		meta.is_cleared = meta.boss_defeated
		_update_room_cleared_visual(meta.id)
	
	dial_position = GameState.dial_position
	rotation_angle = dial_position * ROTATION_STEP
	var slot_angles = floor3_template.SLOT_ANGLES
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if not meta.is_stationary:
			meta.slot_index = ((meta.id - 1 + dial_position) % 11) + 1
			meta.current_angle = slot_angles[meta.slot_index]
			var room_node = rooms.get(room_id_str)
			if room_node:
				room_node.position = Vector2(
					cos(deg_to_rad(meta.current_angle)) * OUTER_RADIUS,
					sin(deg_to_rad(meta.current_angle)) * OUTER_RADIUS
				)
	
	var start_room = rooms.get("12")
	if start_room:
		player_hex = HexGrid.world_to_hex(start_room.global_position)
		if player_node:
			player_node.global_position = start_room.global_position
		current_room_id = "12"
	
	if GameState.crown_cog_unlocked:
		var crown = get_node_or_null("CrownCog/CogSprite") or get_node_or_null("CrownCog/CogShape")
		if crown:
			crown.modulate = Color(0.9, 0.8, 0.3)
	
	print("[Floor3] Continue from save")

func show_pause():
	if pause_menu:
		pause_menu.show_pause()

func _on_pause_resume():
	get_tree().paused = false

func _on_pause_settings():
	if settings_menu:
		settings_menu.show_settings()

func _on_settings_closed():
	if pause_menu:
		pause_menu.show_pause()

func _on_inventory_closed():
	in_ui = false
	get_tree().paused = false

func _on_pause_quit_to_title():
	if pause_menu:
		pause_menu.visible = false
	if title_screen:
		title_screen.show_title()
	GameState.save_game()

func _on_victory_return_title():
	if title_screen:
		title_screen.show_title()

func _on_victory_ngp():
	get_tree().paused = false
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		meta.boss_defeated = false
		meta.is_cleared = false
		_update_room_cleared_visual(meta.id, false)
	
	var start_room = rooms.get("12")
	if start_room:
		player_hex = HexGrid.world_to_hex(start_room.global_position)
		if player_node:
			player_node.global_position = start_room.global_position
	
	if light_beam_puzzle:
		light_beam_puzzle.reset_widgets()
	
	for trap in active_traps:
		if is_instance_valid(trap):
			trap.queue_free()
	active_traps.clear()
	trap_hex_map.clear()
	
	for enemy in overworld_enemies:
		if is_instance_valid(enemy):
			enemy.force_despawn()
	overworld_enemies.clear()
	next_enemy_id = 1
	_spawn_overworld_enemies()
	
	for pickup in world_offerings:
		if is_instance_valid(pickup):
			pickup.queue_free()
	world_offerings.clear()
	_spawn_world_offerings()
	
	print("[Floor3] New Game+ started")

# -------------------------------------------------------------------
# World Walls
# -------------------------------------------------------------------

func _generate_world_walls():
	var ring_inner = OUTER_RADIUS - 180.0
	var ring_outer = OUTER_RADIUS + 180.0
	var grid_range = 35
	
	for q in range(-grid_range, grid_range + 1):
		for r in range(-grid_range, grid_range + 1):
			if abs(q + r) > grid_range:
				continue
			var hex = Vector2i(q, r)
			var world_pos = HexGrid.hex_to_world(hex)
			var dist = world_pos.length()
			
			if hex == Vector2i(0, 0):
				continue
			
			var is_room_center = false
			for room_id_str in rooms:
				var room_node = rooms[room_id_str]
				if HexGrid.world_to_hex(room_node.global_position) == hex:
					is_room_center = true
					break
			if is_room_center:
				continue
			
			if dist < ring_inner or dist > ring_outer:
				blocked_hexes.append(hex)
				continue
			
			var near_room = false
			for room_id_str in rooms:
				var room_node = rooms[room_id_str]
				var room_hex = HexGrid.world_to_hex(room_node.global_position)
				var hex_dist = HexGrid.hex_distance(hex, room_hex)
				if hex_dist <= 8:
					near_room = true
					break
			if not near_room:
				blocked_hexes.append(hex)

func _is_hex_blocked(hex: Vector2i) -> bool:
	if hex == Vector2i(0, 0):
		return false
	for blocked in blocked_hexes:
		if blocked == hex:
			return true
	return false

func _can_enemy_move_to(hex: Vector2i) -> bool:
	"""Check if an enemy can move to a hex (not blocked, not a trap, not the Crown Cog center)."""
	if _is_hex_blocked(hex):
		return false
	if trap_hex_map.has(hex):
		return false
	# Don't walk onto the Crown Cog hub (center hex)
	if hex == Vector2i(0, 0):
		return false
	return true


func _update_room_cleared_visual(room_id: int, cleared: bool = true):
	var room_node = rooms.get(str(room_id))
	if not room_node:
		return
	var hex = room_node.get_node_or_null("CenterHex")
	if hex:
		hex.color = Color(0.3, 0.8, 0.3) if cleared else floor3_template.get_room_color(room_id)
	
	var cleared_label = room_node.get_node_or_null("ClearedLabel")
	if cleared and not cleared_label:
		var label = Label.new()
		label.name = "ClearedLabel"
		label.text = "✓ CLEARED"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-50, 210)
		label.size = Vector2(100, 20)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		room_node.add_child(label)
	elif not cleared and cleared_label:
		cleared_label.queue_free()

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.8), duration: float = 3.0):
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(-200, -150)
	notif.size = Vector2(400, 30)
	notif.add_theme_font_size_override("font_size", 14)
	notif.modulate = color
	add_child(notif)
	var tween = create_tween()
	tween.tween_property(notif, "position:y", -180, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

func _show_damage_flash():
	var flash = ColorRect.new()
	flash.color = Color(0.8, 0.1, 0.1, 0.3)
	flash.size = get_viewport_rect().size
	flash.position = Vector2.ZERO
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

# -------------------------------------------------------------------
# Process Override
# -------------------------------------------------------------------

func _process(delta: float):
	# Camera follow player (base class override - must include this!)
	if not player_node:
		push_warning("[Floor3] _process: player_node is null!")
		return
	
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.global_position = player_node.global_position
	else:
		push_warning("[Floor3] _process: Camera2D not found!")
	
	if in_combat or in_puzzle or in_ui:
		return
	if title_screen and title_screen.visible:
		return
	_update_overworld_enemies(delta)
	_update_overworld_interact_prompt()

func _update_overworld_interact_prompt():
	var prompt = ""
	if player_hex == Vector2i(0, 0):
		if GameState.crown_cog_unlocked:
			prompt = "[S] The Machinist"
		else:
			var aligned = light_beam_puzzle.get_aligned_count() if light_beam_puzzle else 0
			var total = light_beam_puzzle.widgets.size() if light_beam_puzzle else 11
			prompt = "Crown Cog locked (%d/%d beams)" % [aligned, total]
	else:
		for room_id_str in rooms:
			var room_node = rooms[room_id_str]
			var room_hex = HexGrid.world_to_hex(room_node.global_position)
			if player_hex == room_hex:
				var room_id_int = int(room_id_str)
				if room_id_int == 12:
					prompt = "[S] Save Game"
				elif light_beam_puzzle and light_beam_puzzle.is_widget_in_room(room_id_int):
					prompt = light_beam_puzzle.get_interact_prompt(room_id_int)
				break
	if prompt.is_empty() and not (title_screen and title_screen.visible):
		prompt = "[I] Inventory"
	
	if interact_prompt:
		interact_prompt.text = prompt
		interact_prompt.visible = not prompt.is_empty()
		if player_node:
			interact_prompt.global_position = player_node.global_position + Vector2(-60, -55)

# -------------------------------------------------------------------
# Room Transition Override (no-op for Floor 3)
# -------------------------------------------------------------------

func _transition_to_room(target_room_id: String):
	# Floor 3 uses hex movement, not portal transitions
	# But we track current_room_id for compatibility
	current_room_id = target_room_id

# -------------------------------------------------------------------
# Floor Transition (Ascend)
# -------------------------------------------------------------------

func _ascend_to_next_floor():
	print("[Floor3] Ascending to Floor 4...")
	get_tree().change_scene_to_file("res://scenes/Floor4.tscn")

func _on_check_boss_unlock():
	# Floor 3 boss unlock is handled by light beam puzzle + Crown Cog
	pass

# -------------------------------------------------------------------
# Save/Load Integration
# -------------------------------------------------------------------

func save_floor_state() -> Dictionary:
	var puzzle_states = {}
	for room_id in room_puzzles:
		puzzle_states[room_id] = room_puzzles[room_id].get_save_data()
	
	var trap_states = []
	for trap in active_traps:
		trap_states.append(trap.get_save_data())
	
	var enemy_states = []
	for enemy in overworld_enemies:
		if is_instance_valid(enemy):
			enemy_states.append(enemy.get_save_data())
	
	var room_slots = {}
	for room_id_str in room_metadata:
		room_slots[room_metadata[room_id_str].id] = room_metadata[room_id_str].slot_index
	
	return {
		"dial_position": dial_position,
		"rotation_angle": rotation_angle,
		"player_hex": [player_hex.x, player_hex.y],
		"cleared_rooms": _get_cleared_room_ids(),
		"puzzle_states": puzzle_states,
		"trap_states": trap_states,
		"light_beam_state": light_beam_puzzle.get_save_data() if light_beam_puzzle else {},
		"crown_cog_unlocked": GameState.crown_cog_unlocked,
		"enemy_states": enemy_states,
		"next_enemy_id": next_enemy_id,
		"room_slots": room_slots,
	}

func load_floor_state(data: Dictionary):
	dial_position = data.get("dial_position", 0)
	rotation_angle = data.get("rotation_angle", 0.0)
	var hex_arr = data.get("player_hex", [0, -4])
	player_hex = Vector2i(hex_arr[0], hex_arr[1])
	
	for room_id in data.get("cleared_rooms", []):
		var meta = room_metadata.get(str(room_id))
		if meta:
			meta.boss_defeated = true
			meta.is_cleared = true
	
	var puzzle_states = data.get("puzzle_states", {})
	for room_id in puzzle_states:
		if room_puzzles.has(room_id):
			room_puzzles[room_id].load_save_data(puzzle_states[room_id])
	
	var trap_states = data.get("trap_states", [])
	for trap_data in trap_states:
		var trap_type = trap_data.get("trap_id", "")
		var trap = _create_trap(trap_type)
		if trap:
			trap.load_save_data(trap_data)
			if trap.affected_hexes.size() > 0:
				trap.position = HexGrid.hex_to_world(trap.affected_hexes[0])
				trap_hex_map[trap.affected_hexes[0]] = trap
			trap.trap_triggered.connect(_on_trap_triggered)
			trap.trap_damage_dealt.connect(_on_trap_damage)
			trap.trap_terrain_changed.connect(_on_trap_terrain_changed)
			trap.trap_combat_forced.connect(_on_trap_combat_forced)
			active_traps.append(trap)
			add_child(trap)
	
	GameState.crown_cog_unlocked = data.get("crown_cog_unlocked", false)
	next_enemy_id = data.get("next_enemy_id", 1)
	
	var enemy_states = data.get("enemy_states", [])
	for enemy_data in enemy_states:
		var enemy = OverworldEnemy.new()
		enemy.name = "OverworldEnemy_%d" % enemy_data.get("enemy_id", 0)
		enemy.load_save_data(enemy_data)
		enemy.patrol_radius = 5
		enemy.can_move_to = func(hex: Vector2i) -> bool: return _can_enemy_move_to(hex)
		enemy.enemy_spotted_player.connect(_on_enemy_spotted)
		enemy.enemy_lost_player.connect(_on_enemy_lost)
		enemy.enemy_combat_triggered.connect(_on_enemy_combat)
		add_child(enemy)
		overworld_enemies.append(enemy)
	
	var light_beam_state = data.get("light_beam_state", {})
	if light_beam_puzzle and not light_beam_state.is_empty():
		light_beam_puzzle.load_save_data(light_beam_state)
	
	_update_player_position()
	
	var slot_angles = floor3_template.SLOT_ANGLES
	var room_slots = data.get("room_slots", {})
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.id in room_slots:
			meta.slot_index = room_slots[meta.id]
		elif not meta.is_stationary:
			meta.slot_index = ((meta.id - 1 + dial_position) % 11) + 1
		
		if not meta.is_stationary:
			meta.current_angle = slot_angles[meta.slot_index]
			var room_node = rooms.get(room_id_str)
			if room_node:
				room_node.position = Vector2(
					cos(deg_to_rad(meta.current_angle)) * OUTER_RADIUS,
					sin(deg_to_rad(meta.current_angle)) * OUTER_RADIUS
				)
	
	for enemy in overworld_enemies:
		if is_instance_valid(enemy):
			enemy._update_position()

func _get_cleared_room_ids() -> Array[int]:
	var ids: Array[int] = []
	for room_id_str in room_metadata:
		var meta = room_metadata[room_id_str]
		if meta.boss_defeated:
			ids.append(meta.id)
	return ids
