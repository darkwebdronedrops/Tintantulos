extends Node2D

# ===================================================================
# FLOOR 5 CONTROLLER — Hex-Based — The Airship Docks
# ===================================================================
# CHARGE system: wind/steam/lightning/aether
# Mooring puzzle: 3 valves unlock boss arena
# Environmental hazards: wind gusts, steam vents, storm phases
# Gangplank weight: too many entities = collapse
# Boss: The Elemental Core (3 phases)
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "f5_dock"
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

# CHARGE system
var charge: Dictionary = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
var max_charge: int = 10
var vent_ready: bool = false

# Mooring puzzle
var valves_turned: Dictionary = {"breeze": false, "boiler": false, "gale": false}
var all_moorings_unlocked: bool = false

# Environmental hazards
var combat_turn_count: int = 0
var in_storm_phase: bool = false

# Gangplank
var gangplank_weight: int = 0
const GANGPLANK_LIMIT: int = 3

# Boss
var boss_phase: String = ""

# Secret
var cargo_hold_discovered: bool = false

# Room data
var room_data: Dictionary = {
	"f5_dock":     {"center": Vector2i(0, 0),   "radius": 8, "encounter": "none",    "display": "The Main Dock"},
	"f5_breeze":   {"center": Vector2i(0, -20),  "radius": 6, "encounter": "wind",    "display": "Breeze Mooring"},
	"f5_boiler":   {"center": Vector2i(18, 0),   "radius": 6, "encounter": "steam",   "display": "Boiler Mooring"},
	"f5_gale":     {"center": Vector2i(0, 20),   "radius": 6, "encounter": "storm",   "display": "Gale Mooring"},
	"f5_crow":     {"center": Vector2i(0, -40),  "radius": 8, "encounter": "boss",    "display": "Crow's Nest"},
	"f5_cargo":    {"center": Vector2i(22, 5),   "radius": 4, "encounter": "secret",  "display": "Secret Cargo Hold"},
}

# Portal connections
var portal_connections: Dictionary = {
	"f5_dock":   {"north": "f5_breeze", "east": "f5_boiler", "south": "f5_gale", "up": "f5_crow"},
	"f5_breeze": {"south": "f5_dock", "up": "f5_crow"},
	"f5_boiler": {"west": "f5_dock", "secret": "f5_cargo"},
	"f5_gale":   {"north": "f5_dock", "up": "f5_crow"},
	"f5_crow":   {"down": "f5_dock"},
	"f5_cargo":  {"exit": "f5_boiler"},
}

var portal_offsets: Dictionary = {
	"north": Vector2i(0, -8), "south": Vector2i(0, 8),
	"east": Vector2i(8, 0), "west": Vector2i(-8, 0),
	"up": Vector2i(0, -8), "down": Vector2i(0, 8),
	"secret": Vector2i(8, 0), "exit": Vector2i(-8, 0),
}

var room_cleared: Dictionary = {}
var room_encounter_spawned: Dictionary = {}

# UI
var interact_prompt: Label
var pause_menu: CanvasLayer
var charge_ui: Label
var mooring_ui: Label

# Signals
signal room_changed(room_id: String, room_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	call_deferred("_build_floor")

func _build_floor():
	if hex_map:
		hex_map.generate_floor5_layout()
		print("[Floor5-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_floor_specific()
	
	AudioManager.play_floor_ambient(5)
	_enter_room("f5_dock")

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
		shadow.color = Color(0.0, 0.0, 0.0, 0.3)
		shadow.z_index = -1
		player_node.add_child(shadow)
		add_child(player_node)
		print("[Floor5-Hex] Player created")
	
	var entry_center = room_data["f5_dock"]["center"]
	player_node.global_position = hex_map.hex_to_world(entry_center)
	print("[Floor5-Hex] Player placed at dock: %s" % str(entry_center))

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		print("[Floor5-Hex] CombatManager wired")

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
		AudioManager.play_combat(5)
		print("[Floor5-Hex] Combat started: %s" % encounter_type)
		combat_turn_count = 0

func _get_encounter_enemies(encounter_type: String) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	match encounter_type:
		"wind": result = _spawn_enemies(["Jetstream Shepherd"])
		"steam": result = _spawn_enemies(["Steam Golem"])
		"storm": result = _spawn_enemies(["Lightning Sprite"])
		"boss": result = _spawn_enemies(["Elemental Core"])
		"secret": result = _spawn_enemies(["Mimic Chest"])
		_: result = _spawn_enemies(["Jetstream Shepherd"])
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
	AudioManager.play_floor_ambient(5)
	if victory:
		room_cleared[current_room_id] = true
		if current_room_id == "f5_crow":
			_floor_complete()
	else:
		GameState.player_hp = max(1, GameState.player_hp)
		player_node.global_position = hex_map.hex_to_world(room_data["f5_dock"]["center"])

func _floor_complete():
	_show_dialogue("The Tower", "The Elemental Core shatters. Press [S] to ascend to Floor 6.")
	GameState.add_card_to_deck("elemental_core_card")
	GameState.gems += 75
	GameState.save_game()

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
	
	charge_ui = Label.new()
	charge_ui.name = "ChargeUI"
	charge_ui.position = Vector2(20, 20)
	charge_ui.size = Vector2(300, 60)
	charge_ui.add_theme_font_size_override("font_size", 14)
	add_child(charge_ui)
	_update_charge_display()
	
	mooring_ui = Label.new()
	mooring_ui.name = "MooringUI"
	mooring_ui.position = Vector2(20, 90)
	mooring_ui.size = Vector2(300, 30)
	mooring_ui.add_theme_font_size_override("font_size", 12)
	add_child(mooring_ui)
	_update_mooring_display()

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

func _update_charge_display():
	if not charge_ui:
		return
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	var color = Color(0.8, 0.8, 0.8)
	if vent_ready:
		color = Color(0.9, 0.9, 0.3)
	charge_ui.text = "CHARGE: %d/%d\n🌪 %d | 💨 %d | ⚡ %d | ☄ %d" % [total, max_charge, charge["wind"], charge["steam"], charge["lightning"], charge["aether"]]
	charge_ui.add_theme_color_override("font_color", color)

func _update_mooring_display():
	if not mooring_ui:
		return
	var count = 0
	for v in valves_turned.values():
		if v:
			count += 1
	if all_moorings_unlocked:
		mooring_ui.text = "🔓 All Moorings Unlocked — Crow's Nest accessible!"
		mooring_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		mooring_ui.text = "⚓ Moorings: %d/3 (Breeze, Boiler, Gale)" % count
		mooring_ui.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))

func _toggle_pause_menu():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

# ===================================================================
# MOVEMENT
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
			KEY_V:
				if vent_ready:
					_vent_charge()
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

func _on_click_move(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
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
	
	# Gangplank collapse check
	if _is_gangplank_room(current_room_id):
		gangplank_weight += 1
		if gangplank_weight > GANGPLANK_LIMIT:
			_gangplank_collapse()
			return
	
	player_node.global_position = hex_map.hex_to_world(target_hex)
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	
	_check_room_transition(target_hex)
	_check_interactables()

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
# ROOM / PORTAL
# ===================================================================

func _check_room_transition(player_hex: Vector2i):
	if hex_map.get_tile(player_hex) == hex_map.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir:
			if portal_dir == "up" and current_room_id == "f5_dock" and not all_moorings_unlocked:
				_show_notification("Crow's Nest is locked. Turn all 3 mooring valves first!")
				return
			_try_portal_transition(portal_dir)
			return
	
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
	
	if direction == "up" and current_room_id == "f5_dock" and not all_moorings_unlocked:
		_show_notification("The gangplank to Crow's Nest is retracted. Unlock all 3 moorings.")
		return
	
	in_transition = true
	AudioManager.play_sfx("room_enter")
	var target_data = room_data[target_room]
	var target_hex = target_data["center"]
	var opposite_dir = _opposite_direction(direction)
	var entry_offset = portal_offsets.get(opposite_dir, Vector2i.ZERO)
	player_node.global_position = hex_map.hex_to_world(target_hex + entry_offset)
	_enter_room(target_room)
	in_transition = false

func _enter_room(room_id: String):
	if room_id == current_room_id:
		return
	current_room_id = room_id
	var data = room_data[room_id]
	print("[Floor5-Hex] Entered room: %s" % data["display"])
	room_changed.emit(room_id, data["display"])
	
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
		"secret": return "exit"
		"exit": return "secret"
	return ""

func _is_gangplank_room(room_id: String) -> bool:
	return room_id in ["f5_breeze", "f5_boiler", "f5_gale"]

func _gangplank_collapse():
	var damage = randi() % 6 + randi() % 6 + 2
	_show_notification("💥 GANGPLANK COLLAPSES! %d damage!" % damage, 3.0)
	GameState.damage_player(damage)
	player_node.global_position = hex_map.hex_to_world(room_data["f5_dock"]["center"])
	current_room_id = "f5_dock"
	in_combat = false

# ===================================================================
# INTERACTION
# ===================================================================

func _check_interactables():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var neighbors = hex_map.get_neighbors(player_hex)
	neighbors.append(player_hex)
	
	for hex in neighbors:
		if hex_map.get_tile(hex) == hex_map.TILE_OBJECT:
			_show_interact_prompt("Interact")
			return
	_hide_interact_prompt()

func _try_interact():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	match current_room_id:
		"f5_breeze", "f5_boiler", "f5_gale":
			_turn_valve(current_room_id.replace("f5_", ""))
		"f5_dock":
			_show_dialogue("Dock Master", "Turn all 3 mooring valves to extend the gangplank to Crow's Nest.")
		"f5_crow":
			if not all_moorings_unlocked:
				_show_dialogue("Boss Altar", "The Aetherworks is sealed. Unlock all three moorings first.")
			else:
				_start_combat("boss")
		"f5_boiler":
			if not cargo_hold_discovered:
				_discover_cargo_hold()
			else:
				_show_dialogue("Cargo Hold", "The hidden chamber hums with wrong frequency.")
		"f5_cargo":
			_show_dialogue("Cargo", "Ancient mechanisms glint in the dim light.")

func _turn_valve(room_short: String):
	if valves_turned.get(room_short, false):
		_show_notification("Valve already turned!")
		return
	
	valves_turned[room_short] = true
	var count = 0
	for v in valves_turned.values():
		if v:
			count += 1
	
	_show_notification("🔧 %s valve turned! (%d/3)" % [room_short.capitalize(), count])
	_add_charge("steam", 2)
	_update_mooring_display()
	_check_all_moorings_unlocked()

func _check_all_moorings_unlocked():
	if valves_turned["breeze"] and valves_turned["boiler"] and valves_turned["gale"]:
		if not all_moorings_unlocked:
			all_moorings_unlocked = true
			_show_dialogue("The Tower", "All three moorings unlock. The gangplank to Crow's Nest extends!")
			_update_mooring_display()

func _discover_cargo_hold():
	cargo_hold_discovered = true
	_show_dialogue("Cargo Hold", "The wall slides aside. A hidden cargo hold lies beyond, humming with wrong frequency.")
	# Unlock secret connection
	var connections = portal_connections.get("f5_boiler", {})
	connections["secret"] = "f5_cargo"
	portal_connections["f5_boiler"] = connections

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

# ===================================================================
# CHARGE / VENT
# ===================================================================

func _add_charge(type: String, amount: int):
	if type == "aether" or (charge["wind"] > 0 and charge["steam"] > 0 and charge["lightning"] > 0):
		charge["aether"] += amount
		_show_notification("☄ Aether CHARGE unstable! +%d" % amount)
	else:
		charge[type] = min(charge[type] + amount, max_charge)
		_show_notification("%s CHARGE: %d/%d" % [type.capitalize(), charge[type], max_charge])
	
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	vent_ready = total >= max_charge
	if vent_ready:
		_show_notification("⚡ MAX CHARGE — Press [V] to VENT!", 3.0)
	_update_charge_display()

func _vent_charge():
	if not vent_ready:
		return
	var dominant = _get_dominant_charge_type()
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	
	match dominant:
		"wind":
			_show_notification("🌪 VENT WIND — Push all enemies %d hexes!" % total)
		"steam":
			_show_notification("💨 VENT STEAM — Heal %d, Burn all for %d!" % [total * 2, total])
			if GameState.has_method("heal_player"):
				GameState.heal_player(total * 2)
		"lightning":
			_show_notification("⚡ VENT LIGHTNING — Stun all, deal %d damage!" % (total * 3))
		"aether":
			_show_notification("☄ VENT AETHER — UNSTABLE! Random effect!")
	
	charge = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
	vent_ready = false
	_update_charge_display()

func _get_dominant_charge_type() -> String:
	var max_val = charge.values().max()
	if max_val == 0:
		return "wind"
	for t in ["wind", "steam", "lightning", "aether"]:
		if charge[t] == max_val:
			return t
	return "wind"

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

func _show_notification(text: String, duration: float = 3.0):
	var notif = Label.new()
	notif.text = text
	notif.position = Vector2(390, 300)
	notif.size = Vector2(500, 30)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(notif)
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 250, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

func _setup_floor_specific():
	print("[Floor5-Hex] Floor 5 initialized — CHARGE system, 3 ships with wooden bridges, Elemental Core")

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
			else:
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
				return
	
	if not path_movement_active:
		var animator = player_node.get_node_or_null("PlayerAnimator") if player_node else null
		if animator and animator.has_meta("move_timer"):
			var timer = animator.get_meta("move_timer") - _delta
			if timer <= 0:
				animator.play_idle()
				animator.set_meta("move_timer", 0.0)
			else:
				animator.set_meta("move_timer", timer)

func _ascend_to_next_floor():
	AudioManager.play_sfx("floor_transition")
	get_tree().change_scene_to_file("res://scenes/Floor6.tscn")
