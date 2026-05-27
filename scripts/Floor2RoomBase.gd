extends Node2D
class_name Floor2RoomBase

# Base class for all Floor 2 rooms
# Adds:
#   - Environmental state tracking (spore effects)
#   - Faction identification for kill tracking
#   - Spore cloud / pool interaction
#   - Elevator shortcut integration

# Room identification
@export var room_id: String = ""
@export var room_display_name: String = "Unknown Room"
@export var transit_token_name: String = ""
@export var dominant_faction: String = ""  # "Undead" | "Elemental" | "Construct" | "Aberration"

# Encounter settings
@export var encounter_type: String = "enemies"
@export var auto_spawn: bool = true
@export var spawn_on_approach: bool = false

# Environmental features
@export var has_spore_clouds: bool = false
@export var has_pool: bool = false
@export var has_collapsing_platforms: bool = false
@export var has_overgrown_traps: bool = false

# Portal markers
@onready var portal_entrance: Marker2D = get_node_or_null("PortalEntrance")
@onready var portal_exit: Marker2D = get_node_or_null("PortalExit")

# Interior (shown when player enters)
@onready var interior: Node2D = $Interior
@onready var enemy_spawn: Marker2D = $EnemySpawn

# State
var is_cleared: bool = false
var has_given_token: bool = false
var is_interior_visible: bool = false
var enemies_spawned: bool = false
var spawned_enemy_nodes: Array[Node2D] = []
var defeated_faction: String = ""  # For spore cycle tracking

# Spore VFX
var spore_particles: Array[Sprite2D] = []
var overlay_sprite: Sprite2D
var _spore_tween: Tween

# Portal locking
var locked_portals: Dictionary = {}

# Signals
signal room_entered
signal room_exited
signal room_cleared
signal transit_token_given(token_name: String)
signal encounter_started(enemy_names: Array[String])
signal encounter_ended(victory: bool)

func _ready():
	if interior:
		interior.visible = false
	is_interior_visible = false

func show_interior():
	if interior:
		interior.visible = true
	is_interior_visible = true
	emit_signal("room_entered")
	
	# Spawn spore particles for rooms with spore clouds
	if has_spore_clouds and spore_particles.is_empty():
		_spawn_spore_particles(10)

func hide_interior():
	if interior:
		interior.visible = false
	is_interior_visible = false
	emit_signal("room_exited")
	
	# Clear particles when leaving
	if not spore_particles.is_empty():
		_clear_spore_particles()

func mark_cleared():
	if is_cleared:
		return
	is_cleared = true
	give_transit_token()
	emit_signal("room_cleared")
	print("[Floor2] Room '%s' cleared!" % room_display_name)

func give_transit_token():
	if transit_token_name.is_empty() or has_given_token:
		return
	has_given_token = true
	if GameState.has_method("add_transit_token"):
		GameState.add_transit_token(transit_token_name)
	emit_signal("transit_token_given", transit_token_name)
	print("[Floor2] Gave transit token: %s" % transit_token_name)

func get_player_spawn_position() -> Vector2:
	if portal_entrance:
		return portal_entrance.global_position
	return global_position

func get_exit_position() -> Vector2:
	if portal_exit:
		return portal_exit.global_position
	return global_position

# Portal locking
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
	if enemies_spawned or is_cleared:
		return
	
	var comp = RoomEnemyDatabase.get_floor2_composition(room_id, encounter_type)
	if comp.get("is_peaceful", false):
		print("[Floor2] Room '%s' is peaceful" % room_display_name)
		return
	
	var enemy_templates = comp.get("enemies", [])
	if enemy_templates.is_empty():
		return
	
	var enemy_data: Array[CombatManager.EnemyData] = []
	var enemy_names: Array[String] = []
	for template in enemy_templates:
		if template is RoomEnemyDatabase.EnemyTemplate:
			enemy_data.append(template.to_combat_data())
			enemy_names.append(template.name)
	
	spawned_enemy_nodes = _spawn_enemy_nodes(enemy_data)
	enemies_spawned = true
	
	# Track faction for spore cycle
	defeated_faction = dominant_faction
	
	emit_signal("encounter_started", enemy_names)
	print("[Floor2] Spawned %d enemies in '%s': %s" % [enemy_data.size(), room_display_name, ", ".join(enemy_names)])

func _spawn_enemy_nodes(enemy_data: Array[CombatManager.EnemyData]) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	var base_pos = enemy_spawn.global_position if enemy_spawn else global_position
	
	for i in range(enemy_data.size()):
		var enemy = enemy_data[i]
		var enemy_node = _create_enemy_node(enemy, i)
		var offset = Vector2((i - (enemy_data.size() - 1) * 0.5) * 60, 0)
		enemy_node.position = base_pos + offset
		add_child(enemy_node)
		spawned.append(enemy_node)
	
	EnemySpawner.show_spawn_animation(spawned)
	return spawned

func _create_enemy_node(enemy: CombatManager.EnemyData, index: int) -> Node2D:
	var container = Node2D.new()
	container.name = "Enemy_%d_%s" % [index, enemy.name.replace(" ", "_")]
	
	var template = RoomEnemyDatabase.get_enemy_template(enemy.name)
	var sprite_path = ""
	if template:
		sprite_path = template.sprite_path
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var tex = load(sprite_path)
		if tex:
			sprite.texture = tex
			sprite.scale = Vector2(2.0, 2.0)
	else:
		sprite = _create_fallback_sprite(enemy.name)
	
	container.add_child(sprite)
	
	var hp_bar = EnemySpawner._create_hp_bar(enemy.hp, enemy.max_hp)
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(0, -40)
	container.add_child(hp_bar)
	
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
	var poly = Polygon2D.new()
	var color = Color(0.5, 0.5, 0.5)
	
	if "Flesh" in enemy_name or "Debt" in enemy_name or "Crawler" in enemy_name or "Wound" in enemy_name:
		color = Color(0.5, 0.3, 0.3)  # Undead - reddish
	elif "Droplet" in enemy_name or "Cinder" in enemy_name or "Hydrostatic" in enemy_name:
		color = Color(0.3, 0.5, 0.7)  # Elemental - bluish
	elif "Clockwork" in enemy_name or "Brass" in enemy_name or "Gear" in enemy_name:
		color = Color(0.6, 0.5, 0.3)  # Construct - brass
	elif "Bug" in enemy_name:
		color = Color(0.4, 0.2, 0.6)  # Aberration - purple glitch
	elif "Garden" in enemy_name:
		color = Color(0.3, 0.7, 0.3)  # Boss - green
	
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-20, -20), Vector2(20, -20),
		Vector2(20, 20), Vector2(-20, 20)
	])
	return poly

func on_enemy_defeated(enemy_node: Node2D):
	if enemy_node in spawned_enemy_nodes:
		enemy_node.modulate = Color(0.3, 0.3, 0.3)
		var sprite = enemy_node.get_node_or_null("Sprite")
		if sprite and sprite is Node2D:
			sprite.rotation = PI / 2
	
	var all_dead = true
	for node in spawned_enemy_nodes:
		if node.modulate != Color(0.3, 0.3, 0.3):
			all_dead = false
			break
	
	if all_dead and spawned_enemy_nodes.size() > 0:
		emit_signal("encounter_ended", true)
		mark_cleared()

func despawn_enemies():
	for node in spawned_enemy_nodes:
		if is_instance_valid(node):
			node.queue_free()
	spawned_enemy_nodes.clear()
	enemies_spawned = false

# ============================================================
# ENVIRONMENTAL EFFECTS
# ============================================================

func apply_spore_effects(effects: Dictionary):
	"""Called by Floor2Controller to apply current spore state effects."""
	# Reduce interior visibility for spore clouds
	if has_spore_clouds and effects.has("spore_visibility"):
		if interior:
			interior.modulate = Color(1, 1, 1, effects["spore_visibility"])
	
	# Pool heal/toxic
	if has_pool and effects.has("pool_heal"):
		var heal = effects["pool_heal"]
		if heal > 0:
			print("[Floor2] Pool heals %d HP per turn" % heal)
		else:
			print("[Floor2] Pool is toxic! Takes %d damage per turn" % -heal)
	
	# Show/hide state overlay
	_update_spore_overlay(effects)

func _update_spore_overlay(effects: Dictionary):
	"""Show appropriate spore state overlay on room."""
	# Remove old overlay
	if overlay_sprite and is_instance_valid(overlay_sprite):
		overlay_sprite.queue_free()
		overlay_sprite = null
	
	# Determine which overlay to show
	var overlay_path = ""
	if effects.has("spore_damage") and effects["spore_damage"] > 0:
		overlay_path = "res://assets/sprites/floor2/toxic_rot_overlay.png"
	elif effects.has("elemental_spawn_bonus"):
		overlay_path = "res://assets/sprites/floor2/fungal_bloom_overlay.png"
	elif effects.has("construct_spawn_bonus"):
		overlay_path = "res://assets/sprites/floor2/overgrowth_overlay.png"
	
	if overlay_path.is_empty():
		return
	
	# Add overlay sprite
	overlay_sprite = Sprite2D.new()
	overlay_sprite.name = "SporeOverlay"
	overlay_sprite.texture = load(overlay_path)
	overlay_sprite.position = Vector2(960, 600)
	overlay_sprite.scale = Vector2(8, 8)
	overlay_sprite.modulate = Color(1, 1, 1, 0.3)
	overlay_sprite.z_index = 10  # Above background, below enemies
	add_child(overlay_sprite)
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(overlay_sprite, "modulate", Color(1, 1, 1, 0.4), 1.0)
	
	print("[Floor2] Overlay applied: %s" % overlay_path)

func _spawn_spore_particles(count: int = 8):
	"""Spawn floating spore particles in room."""
	if not has_spore_clouds:
		return
	
	var tex = load("res://assets/sprites/floor2/spore_particle.png")
	if not tex:
		return
	
	for i in range(count):
		var particle = Sprite2D.new()
		particle.name = "SporeParticle_%d" % i
		particle.texture = tex
		particle.scale = Vector2(0.3 + randf() * 0.4, 0.3 + randf() * 0.4)
		particle.position = Vector2(
			randi() % 1600 + 200,  # Random x across room
			randi() % 800 + 200     # Random y across room
		)
		particle.modulate = Color(1, 1, 1, 0.3 + randf() * 0.4)
		particle.z_index = 5
		interior.add_child(particle)
		spore_particles.append(particle)
		
		# Animate floating
		var tween = create_tween().set_loops()
		tween.tween_property(particle, "position:y", particle.position.y - 50 - randf() * 100, 3.0 + randf() * 2.0)
		tween.tween_property(particle, "modulate:a", 0.1, 1.5)
		tween.tween_property(particle, "position:y", particle.position.y + 30, 2.0 + randf() * 2.0)
		tween.tween_property(particle, "modulate:a", 0.5, 1.5)
	
	print("[Floor2] Spawned %d spore particles" % count)

func _clear_spore_particles():
	"""Remove all spore particles."""
	for p in spore_particles:
		if is_instance_valid(p):
			p.queue_free()
	spore_particles.clear()
	print("[Floor2] Cleared spore particles")

# ============================================================
# ROOM-SPECIFIC FEATURES
# ============================================================

func reveal_secret():
	"""Override in Lower Cavern to reveal secret room passage."""
	pass

func unlock_elevator():
	"""Override in Lower Cavern to show elevator shortcut."""
	pass

func activate_boss():
	"""Override in Spore Heart to show boss throne."""
	pass

func get_defeated_faction() -> String:
	return defeated_faction

# ============================================================
# PLAYER EVENTS
# ============================================================

func on_player_entered():
	show_interior()
	if auto_spawn and not enemies_spawned and not is_cleared:
		spawn_encounter()

func on_player_exited():
	hide_interior()
