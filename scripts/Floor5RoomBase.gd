extends Floor1RoomBase
class_name Floor5RoomBase

# ===================================================================
# FLOOR 5 ROOM BASE — The Airship Docks
# ===================================================================
# Adds Floor 5 specific room behaviors:
#   - Anchor points (wind resistance)
#   - Lightning rod proximity
#   - Steam effects
#   - Gangplank / secret door unlocking
#   - Faction tracking for elemental death bonus
# ===================================================================

# Room-specific features
@export var has_anchor: bool = false
@export var has_lightning_rod: bool = false
@export var has_steam_valve: bool = false
@export var has_secret_door: bool = false
@export var dominant_faction: String = ""  # "Elemental", "Undead", "Aberration", "Goblin"

# State
var player_anchored: bool = false
var near_lightning_rod: bool = false
var gangplanks_unlocked: bool = false
var secret_door_unlocked: bool = false
var steam_effect_playing: bool = false

func _ready():
	super._ready()

# -------------------------------------------------------------------
# Anchor System (Wind Resistance)
# -------------------------------------------------------------------

func toggle_anchor():
	"""Toggle anchor state."""
	if not has_anchor:
		return
	player_anchored = not player_anchored
	print("[Floor5] Anchor toggled: %s" % player_anchored)

func is_player_anchored() -> bool:
	"""Check if player is currently anchored."""
	return has_anchor and player_anchored

# -------------------------------------------------------------------
# Lightning Rod System
# -------------------------------------------------------------------

func approach_lightning_rod():
	"""Player approaches the lightning rod."""
	if not has_lightning_rod:
		return
	near_lightning_rod = true

func leave_lightning_rod():
	"""Player leaves lightning rod proximity."""
	near_lightning_rod = false

func is_near_lightning_rod() -> bool:
	"""Check if player is near lightning rod."""
	return has_lightning_rod and near_lightning_rod

# -------------------------------------------------------------------
# Steam Effects
# -------------------------------------------------------------------

func play_steam_effect():
	"""Play visual steam release effect."""
	if steam_effect_playing:
		return
	steam_effect_playing = true
	
	# Find steam vent sprites and animate them
	var vents = _find_nodes_by_name("SteamVent")
	for vent in vents:
		if vent is Sprite2D:
			var tween = create_tween()
			tween.tween_property(vent, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.3)
			tween.tween_property(vent, "modulate", Color(1.0, 1.0, 1.0, 0.6), 1.0)
			
	print("[Floor5] Steam effect played in '%s'" % room_display_name)
	
	# Reset after animation
	await get_tree().create_timer(1.5).timeout
	steam_effect_playing = false

# -------------------------------------------------------------------
# Gangplank / Crow's Nest Unlock
# -------------------------------------------------------------------

func unlock_gangplanks():
	"""Unlock gangplanks to Crow's Nest."""
	if gangplanks_unlocked:
		return
	gangplanks_unlocked = true
	
	# Show gangplank sprites if they exist
	var gangplanks = _find_nodes_by_name("Gangplank")
	for gp in gangplanks:
		if gp is Sprite2D:
			gp.visible = true
			gp.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Show portal to Crow's Nest
	var portal = get_node_or_null("Interior/PortalUp")
	if portal:
		portal.visible = true
	
	print("[Floor5] Gangplanks unlocked in '%s'" % room_display_name)

# -------------------------------------------------------------------
# Secret Door (Cargo Hold)
# -------------------------------------------------------------------

func unlock_secret_door():
	"""Unlock the secret door to cargo hold."""
	if secret_door_unlocked:
		return
	secret_door_unlocked = true
	
	# Find fake wall and hide it / reveal door
	var fake_wall = get_node_or_null("Interior/FakeWall")
	if fake_wall:
		fake_wall.visible = false
	
	var secret_door = get_node_or_null("Interior/SecretDoor")
	if secret_door:
		secret_door.visible = true
	
	print("[Floor5] Secret door unlocked in '%s'" % room_display_name)

# -------------------------------------------------------------------
# Faction Tracking (for CHARGE bonuses)
# -------------------------------------------------------------------

func get_defeated_faction() -> String:
	"""Return the dominant faction of enemies in this room."""
	return dominant_faction

# -------------------------------------------------------------------
# Encounter Override (track faction)
# -------------------------------------------------------------------

func spawn_encounter():
	"""Override to track faction for CHARGE bonuses."""
	super.spawn_encounter()
	
	# Set dominant faction from composition
	var comp = RoomEnemyDatabase.get_floor5_composition(room_id, "enemies")
	if comp.has("faction"):
		dominant_faction = comp["faction"]

# -------------------------------------------------------------------
# Helper
# -------------------------------------------------------------------

func _find_nodes_by_name(partial_name: String) -> Array[Node]:
	"""Find all descendant nodes whose name contains partial_name."""
	var results: Array[Node] = []
	for child in get_children():
		if partial_name in child.name:
			results.append(child)
		results.append_array(_find_in_children(child, partial_name))
	return results

func _find_in_children(node: Node, partial_name: String) -> Array[Node]:
	var results: Array[Node] = []
	for child in node.get_children():
		if partial_name in child.name:
			results.append(child)
		results.append_array(_find_in_children(child, partial_name))
	return results
