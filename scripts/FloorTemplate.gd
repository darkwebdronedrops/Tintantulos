class_name FloorTemplate
extends RefCounted

# ===================================================================
# FLOOR TEMPLATE — Base class for floor-specific configuration data
# ===================================================================
# Each floor provides a template containing:
#   - Room definitions (scene paths, positions, connections)
#   - Floor metadata (ID, name, starting room)
#   - Floor-specific constants (room distance, hex step size, etc.)
#
# The FloorController reads this template to build the floor layout.
# Floor-specific logic (dial rotation, trap booths, etc.) stays in
# the per-floor controller that extends FloorController.
# ===================================================================

# Floor metadata
@export var floor_id: int = 0
@export var floor_name: String = "Unnamed Floor"
@export var starting_room_id: String = ""

# Room definitions — override in child template
# Format: { room_id: { scene_path: String, position: Vector2, connections: Dictionary } }
var rooms: Dictionary = {}

# Movement constants
@export var hex_step_size: float = 60.0
@export var interact_range: float = 80.0
@export var transition_duration: float = 0.5

# Optional: floor-specific custom data
# Child templates can add their own properties
var custom_data: Dictionary = {}

# -------------------------------------------------------------------
# Virtual methods — override in child templates
# -------------------------------------------------------------------

func get_room_scene_path(room_id: String) -> String:
	var room_data = rooms.get(room_id, {})
	return room_data.get("scene_path", "")

func get_room_position(room_id: String) -> Vector2:
	var room_data = rooms.get(room_id, {})
	return room_data.get("position", Vector2.ZERO)

func get_room_connections(room_id: String) -> Dictionary:
	var room_data = rooms.get(room_id, {})
	return room_data.get("connections", {})

func get_all_room_ids() -> Array:
	return rooms.keys()

func has_room(room_id: String) -> bool:
	return room_id in rooms

# Override to provide floor-specific interactable mappings
func get_interactable_label(node_name: String) -> String:
	return ""

# Override to check if a node name is a portal (not an interactable)
func is_portal_node(node_name: String) -> bool:
	return false
