extends Node2D
class_name Floor1RoomBase

# Base class for all Floor 1 rooms
# Self-contained room with portal system, interior visibility, transit tokens,
# and enemy encounter spawning

# Room identification
@export var room_id: String = ""
@export var room_display_name: String = "Unknown Room"
@export var transit_token_name: String = ""  # e.g., "East Pass", "North Pass"

# Encounter settings
@export var encounter_type: String = "enemies"  # "enemies", "ambush", "boss"
@export var auto_spawn: bool = true  # Spawn enemies immediately on enter
@export var spawn_on_approach: bool = false  # Wait for player approach + E key

# Boss settings
@export var has_boss: bool = false
@export var boss_type: String = ""

# Portal markers
@onready var portal_entrance: Marker2D = get_node_or_null("PortalEntrance")
@onready var portal_exit: Marker2D = get_node_or_null("PortalExit")

# Interior (shown when player enters)
@onready var interior: Node2D = $Interior
@onready var enemy_spawn: Marker2D = get_node_or_null("EnemySpawn")

# State
var is_cleared: bool = false
var has_given_token: bool = false
var is_interior_visible: bool = false
var enemies_spawned: bool = false
var spawned_enemy_nodes: Array[Node2D] = []

# Portal locking
var locked_portals: Dictionary = {}  # direction -> lock_reason

# Signals
signal room_entered
signal room_exited
signal room_cleared
signal transit_token_given(token_name: String)
signal encounter_started(enemy_names: Array[String])
signal encounter_ended(victory: bool)

func _ready():
	# Hide interior by default (shown when player enters)
	if interior:
		interior.visible = false
	is_interior_visible = false

func show_interior():
	"""Called when player enters the room via portal"""
	if interior:
		interior.visible = true
	is_interior_visible = true
	emit_signal("room_entered")

func hide_interior():
	"""Called when player exits through portal"""
	if interior:
		interior.visible = false
	is_interior_visible = false
	emit_signal("room_exited")

func on_player_entered():
	"""Called by FloorController when player enters via portal"""
	show_interior()
	if auto_spawn and not enemies_spawned and not is_cleared:
		spawn_encounter()

func on_player_exited():
	"""Called by FloorController when player leaves"""
	hide_interior()
	if enemies_spawned:
		despawn_enemies()

func mark_cleared():
	"""Call this when room's objective is complete (combat won, puzzle solved)"""
	if is_cleared:
		return
	is_cleared = true
	give_transit_token()
	emit_signal("room_cleared")
	print("[Floor1] Room '%s' cleared!" % room_display_name)

func give_transit_token():
	"""Give transit token to player (if room has one)"""
	if transit_token_name.is_empty() or has_given_token:
		return
	has_given_token = true
	GameState.add_transit_token(transit_token_name)
	emit_signal("transit_token_given", transit_token_name)
	print("[Floor1] Gave transit token: %s" % transit_token_name)

func get_player_spawn_position() -> Vector2:
	"""Where player should appear when entering this room"""
	if portal_entrance:
		return portal_entrance.global_position
	return global_position

func get_exit_position() -> Vector2:
	"""Where player stands to exit (for portal trigger)"""
	if portal_exit:
		return portal_exit.global_position
	return global_position

# Portal locking system
func lock_portal(direction: String, reason: String = "Locked"):
	locked_portals[direction] = reason

func unlock_portal(direction: String):
	if direction in locked_portals:
		locked_portals.erase(direction)

func is_portal_locked(direction: String) -> bool:
	return direction in locked_portals

func unlock_all_portals():
	locked_portals.clear()

# ============================================================
# ENEMY ENCOUNTER SYSTEM
# ============================================================

func spawn_encounter():
	"""Spawn enemies for this room based on RoomEnemyDatabase"""
	if enemies_spawned or is_cleared:
		return
	
	var comp = RoomEnemyDatabase.get_floor1_composition(room_id, encounter_type)
	if comp.get("is_peaceful", false):
		print("[Floor1] Room '%s' is peaceful — no enemies" % room_display_name)
		return
	
	var enemy_templates = comp.get("enemies", [])
	if enemy_templates.is_empty():
		return
	
	# Convert templates to CombatManager.EnemyData
	var enemy_data: Array[CombatManager.EnemyData] = []
	var enemy_names: Array[String] = []
	for template in enemy_templates:
		if template is RoomEnemyDatabase.EnemyTemplate:
			enemy_data.append(template.to_combat_data())
			enemy_names.append(template.name)
	
	# Spawn visual enemy nodes
	spawned_enemy_nodes = _spawn_enemy_nodes(enemy_data)
	enemies_spawned = true
	
	emit_signal("encounter_started", enemy_names)
	print("[Floor1] Spawned %d enemies in '%s': %s" % [enemy_data.size(), room_display_name, ", ".join(enemy_names)])

func _spawn_enemy_nodes(enemy_data: Array[CombatManager.EnemyData]) -> Array[Node2D]:
	"""Create visual enemy nodes at the enemy spawn marker"""
	var spawned: Array[Node2D] = []
	var base_pos = enemy_spawn.global_position if enemy_spawn else global_position
	
	for i in range(enemy_data.size()):
		var enemy = enemy_data[i]
		var enemy_node = _create_enemy_node(enemy, i)
		
		# Offset multiple enemies slightly
		var offset = Vector2((i - (enemy_data.size() - 1) * 0.5) * 60, 0)
		enemy_node.position = base_pos + offset
		
		add_child(enemy_node)
		spawned.append(enemy_node)
	
	# Play spawn animation
	EnemySpawner.show_spawn_animation(spawned)
	
	return spawned

func _create_enemy_node(enemy: CombatManager.EnemyData, index: int) -> Node2D:
	var container = Node2D.new()
	container.name = "Enemy_%d_%s" % [index, enemy.name.replace(" ", "_")]
	
	# Get sprite path from database or fallback
	var template = RoomEnemyDatabase.get_enemy_template(enemy.name)
	var sprite_path = ""
	if template:
		sprite_path = template.sprite_path
	
	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var tex = load(sprite_path)
		if tex:
			sprite.texture = tex
			sprite.scale = Vector2(2.0, 2.0)
	else:
		# Fallback — colored rectangle
		sprite = _create_fallback_sprite(enemy.name)
	
	container.add_child(sprite)
	
	# HP bar above enemy
	var hp_bar = EnemySpawner._create_hp_bar(enemy.hp, enemy.max_hp)
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(0, -40)
	container.add_child(hp_bar)
	
	# Name label
	var label = Label.new()
	label.name = "NameLabel"
	label.text = enemy.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -60)
	label.size = Vector2(100, 20)
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	return container

func _create_fallback_sprite(enemy_name: String) -> Polygon2D:
	"""Create a colored shape if sprite is missing"""
	var poly = Polygon2D.new()
	
	var color = Color(0.7, 0.3, 0.3)
	if "Door" in enemy_name:
		color = Color(0.4, 0.4, 0.5)
	elif "Snotling" in enemy_name:
		color = Color(0.3, 0.7, 0.3)
	elif "King" in enemy_name:
		color = Color(0.9, 0.7, 0.2)
	elif "Demon" in enemy_name or "Shortcut" in enemy_name:
		color = Color(0.7, 0.2, 0.7)
	
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-20, -20), Vector2(20, -20),
		Vector2(20, 20), Vector2(-20, 20)
	])
	
	return poly

func on_enemy_defeated(enemy_node: Node2D):
	"""Called when an enemy is defeated in combat"""
	if enemy_node in spawned_enemy_nodes:
		# Grey out the sprite
		enemy_node.modulate = Color(0.3, 0.3, 0.3)
		var sprite = enemy_node.get_node_or_null("Sprite")
		if sprite and sprite is Node2D:
			sprite.rotation = PI / 2
	
	# Check if all enemies defeated
	var all_dead = true
	for node in spawned_enemy_nodes:
		# Check if node is still alive (would need HP tracking)
		if node.modulate != Color(0.3, 0.3, 0.3):
			all_dead = false
			break
	
	if all_dead and spawned_enemy_nodes.size() > 0:
		emit_signal("encounter_ended", true)
		mark_cleared()

func despawn_enemies():
	"""Remove all spawned enemies (used when leaving room)"""
	for node in spawned_enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_enemy_nodes.clear()
	enemies_spawned = false

# Boss portal activation (for central room)
func activate_boss_portal():
	"""Override in central room to show boss portal"""
	var portal = get_node_or_null("Interior/PortalUp")
	if portal:
		portal.visible = true
		print("[Floor1] Boss portal activated in central room")

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"room_id": room_id,
		"is_cleared": is_cleared,
		"has_given_token": has_given_token,
		"enemies_spawned": enemies_spawned,
		"has_boss": has_boss,
		"boss_type": boss_type
	}

func load_save_data(data: Dictionary):
	if data.has("is_cleared"):
		is_cleared = data["is_cleared"]
	if data.has("has_given_token"):
		has_given_token = data["has_given_token"]
	if data.has("enemies_spawned"):
		enemies_spawned = data["enemies_spawned"]
	if data.has("has_boss"):
		has_boss = data["has_boss"]
	if data.has("boss_type"):
		boss_type = data["boss_type"]
