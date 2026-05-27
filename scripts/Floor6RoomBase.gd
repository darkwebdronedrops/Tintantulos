extends Floor1RoomBase
class_name Floor6RoomBase

# ===================================================================
# FLOOR 6 ROOM BASE — The Lunar University
# Extends Floor1RoomBase with moonlight, registrar, book reading,
# locked doors, and clocktower sabotage
# ===================================================================

# Moonlight system
var moonlight_active: bool = true
var moonlight_beams: Array[Area2D] = []

# Room-specific flags
var registrar_interacted: bool = false
var books_read: int = 0
var clocktower_sabotaged_here: bool = false
var door_locked: bool = false
var door_lock_reason: String = ""

func _ready():
	super._ready()

# -------------------------------------------------------------------
# Moonlight System
# -------------------------------------------------------------------

func is_in_moonlight() -> bool:
	"""Check if player is currently in a moonlight beam zone."""
	for beam in moonlight_beams:
		if beam.has_overlapping_bodies():
			return true
	return false

func is_in_shadow() -> bool:
	"""Check if player is in shadow (not in any moonlight beam)."""
	return not is_in_moonlight()

func set_moonlight_active(active: bool):
	"""Toggle moonlight beam visibility and collision."""
	moonlight_active = active
	for beam in moonlight_beams:
		beam.visible = active
		beam.monitoring = active

func register_moonlight_beam(beam: Area2D):
	"""Register a moonlight beam Area2D for tracking."""
	if beam not in moonlight_beams:
		moonlight_beams.append(beam)

# -------------------------------------------------------------------
# The Registrar
# -------------------------------------------------------------------

func interact_registrar() -> Dictionary:
	"""Interact with The Registrar. Returns choice result."""
	if registrar_interacted:
		return {"status": "already_interacted", "message": "The Registrar has already assigned your courses."}
	
	registrar_interacted = true
	return {
		"status": "first_interaction",
		"message": "Welcome to the Lunar University. Three courses have been assigned."
	}

func has_registrar_interacted() -> bool:
	return registrar_interacted

# -------------------------------------------------------------------
# Book Reading (Library of Voices)
# -------------------------------------------------------------------

func read_book() -> Dictionary:
	"""Read a book in the library. Returns outcome."""
	books_read += 1
	
	var roll = randi() % 3
	match roll:
		0:
			return {
				"status": "lore",
				"message": "The book whispers: 'The Dean was once a student too.'",
				"books_read": books_read
			}
		1:
			return {
				"status": "misinformation",
				"message": "The book SCREAMS! 2 damage from misinformation!",
				"damage": 2,
				"books_read": books_read
			}
		2:
			return {
				"status": "research",
				"message": "Research notes found. Next course grade +1!",
				"books_read": books_read,
				"research_bonus": true
			}
		_:
			return {"status": "lore", "message": "The pages are blank.", "books_read": books_read}

func get_books_read() -> int:
	return books_read

func has_research_status() -> bool:
	return books_read >= 5

# -------------------------------------------------------------------
# Locked Doors
# -------------------------------------------------------------------

func approach_door(door_id: String) -> Dictionary:
	"""Approach a locked door. Returns access result."""
	if not door_locked:
		return {"status": "unlocked", "message": "The door opens easily."}
	
	# Check keys
	if GameState.floor6_master_key:
		return {"status": "master_key", "message": "The Master Key turns. The heavy doors groan open."}
	
	if GameState.floor6_deans_key and door_id == "dean_office":
		return {"status": "deans_key", "message": "The Dean's Key fits perfectly."}
	
	return {
		"status": "locked",
		"message": door_lock_reason if not door_lock_reason.is_empty() else "Locked. A key is needed."
	}

func lock_door(reason: String = "Locked"):
	door_locked = true
	door_lock_reason = reason

func unlock_door():
	door_locked = false
	door_lock_reason = ""

func is_door_locked() -> bool:
	return door_locked

# -------------------------------------------------------------------
# Clocktower Sabotage
# -------------------------------------------------------------------

func toggle_clocktower_sabotage() -> Dictionary:
	"""Attempt to sabotage the clocktower mechanism."""
	if clocktower_sabotaged_here:
		return {"status": "already_sabotaged", "message": "The mechanism is already broken."}
	
	if GameState.floor6_clocktower_sabotaged:
		return {"status": "globally_sabotaged", "message": "The clocktower bell is already silenced."}
	
	clocktower_sabotaged_here = true
	GameState.floor6_clocktower_sabotaged = true
	GameState.save_game()
	
	return {
		"status": "sabotaged",
		"message": "The clocktower mechanism grinds to a halt. The bell will never ring again.",
		"security_alert": true
	}

func is_clocktower_sabotaged() -> bool:
	return clocktower_sabotaged_here or GameState.floor6_clocktower_sabotaged

# -------------------------------------------------------------------
# Override: Room Entered
# -------------------------------------------------------------------

func on_player_entered():
	show_interior()
	if auto_spawn and not enemies_spawned and not is_cleared:
		spawn_encounter()
	
	# Check moonlight for quadrangle
	if room_id == "quadrangle" and moonlight_active:
		_update_moonlight_display()

func _update_moonlight_display():
	"""Update UI hint about moonlight status."""
	pass  # UI updates handled by Floor6Controller

# -------------------------------------------------------------------
# Override: Enemy Defeat Tracking for Course Progress
# -------------------------------------------------------------------

func on_enemy_defeated(enemy_node: Node2D):
	super.on_enemy_defeated(enemy_node)
	
	# Signal to controller for course progress
	var controller = get_node_or_null("/root/Floor6Controller")
	if controller and controller.has_method("_record_enemy_defeat"):
		var faction = _get_enemy_faction(enemy_node.name)
		controller._record_enemy_defeat(faction, false)

func _get_enemy_faction(enemy_name: String) -> String:
	"""Determine faction from enemy name."""
	var name_lower = enemy_name.to_lower()
	if "construct" in name_lower or "drone" in name_lower or "core" in name_lower or "brass" in name_lower or "dean" in name_lower:
		return "Construct"
	elif "undead" in name_lower or "forgotten" in name_lower or "remembers" in name_lower or "marrow" in name_lower:
		return "Undead"
	elif "goblin" in name_lower or "sneak" in name_lower or "thief" in name_lower:
		return "Goblin"
	elif "elemental" in name_lower:
		return "Elemental"
	return "Unknown"
