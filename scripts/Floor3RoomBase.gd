extends Floor1RoomBase
class_name Floor3RoomBase

# ===================================================================
# FLOOR 3 ROOM BASE — The Gearworks
# Extends Floor1RoomBase with Floor 3-specific features:
#   - Light puzzle widget socket
#   - Rotating room support (dial system)
#   - Puzzle integration
# ===================================================================

# Floor 3-specific properties
var is_rotating: bool = true       # Rooms 1-11 rotate; Room 12 (Quench) is stationary
var slot_index: int = -1           # Position on the dial (0-11)
var widget_rotation: int = 0       # 0-5 (hex direction the widget faces)
var widget_powered: bool = false   # True when room puzzle is solved
var has_puzzle: bool = true        # All Floor 3 rooms have puzzles

# Signals
signal puzzle_solved(room_id: String)

# Floor 3 nodes (in addition to Floor1RoomBase nodes)
var widget_socket: Marker2D
var center_marker: Marker2D

func _ready():
	# Use get_node_or_null for optional nodes (Floor 3 rooms may not have all Floor1 nodes)
	portal_entrance = get_node_or_null("PortalEntrance")
	portal_exit = get_node_or_null("PortalExit")
	interior = get_node_or_null("Interior")
	enemy_spawn = get_node_or_null("EnemySpawn")
	
	# Floor 3-specific nodes
	widget_socket = get_node_or_null("WidgetSocket")
	center_marker = get_node_or_null("CenterMarker")
	
	# Hide interior by default
	if interior:
		interior.visible = false
	is_interior_visible = false

func setup(id: int, name: String, boss: bool = false, b_type: String = ""):
	room_id = str(id)
	room_display_name = name
	has_boss = boss
	boss_type = b_type

func set_widget_rotation(dir: int):
	widget_rotation = dir % 6

func power_widget():
	widget_powered = true

func get_widget_world_pos() -> Vector2:
	if widget_socket:
		return widget_socket.global_position
	return global_position

func get_center_world_pos() -> Vector2:
	if center_marker:
		return center_marker.global_position
	return global_position

func get_player_spawn_position() -> Vector2:
	# Floor 3: player spawns at room center, not at portal entrance
	if center_marker:
		return center_marker.global_position
	return global_position

func get_exit_position() -> Vector2:
	# Floor 3 doesn't use portal exits — returns center for compatibility
	return get_player_spawn_position()

# Override mark_cleared to emit puzzle_solved signal
func mark_cleared():
	if is_cleared:
		return
	is_cleared = true
	emit_signal("room_cleared")
	emit_signal("puzzle_solved", room_id)
	print("[Floor3] Room '%s' cleared!" % room_display_name)

func get_save_data() -> Dictionary:
	var data = super.get_save_data() if super.has_method("get_save_data") else {}
	data["widget_rotation"] = widget_rotation
	data["widget_powered"] = widget_powered
	data["slot_index"] = slot_index
	data["is_rotating"] = is_rotating
	return data

func load_save_data(data: Dictionary):
	if super.has_method("load_save_data"):
		super.load_save_data(data)
	widget_rotation = data.get("widget_rotation", 0)
	widget_powered = data.get("widget_powered", false)
	slot_index = data.get("slot_index", -1)
	is_rotating = data.get("is_rotating", true)
