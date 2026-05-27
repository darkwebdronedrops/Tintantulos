extends Node2D
class_name RoomScene

# RoomScene - Base class for all room scenes
# Each room is a separate scene that gets instantiated by Floor3Controller

# Room data
var room_id: int = 0
var room_name: String = ""
var is_cleared: bool = false
var has_boss: bool = false
var boss_type: String = ""
var boss_defeated: bool = false

# Widget for light puzzle
var widget_rotation: int = 0  # 0-5 (hex directions)
var widget_powered: bool = false

# Enemy spawn marker
var enemy_spawn_position: Vector2 = Vector2.ZERO

# References
@onready var interior: Node2D = $Interior
@onready var widget_socket: Marker2D = $WidgetSocket
@onready var enemy_spawn: Marker2D = $EnemySpawn
@onready var center_marker: Marker2D = $CenterMarker

func _ready():
	# Hide interior in overworld by default
	if interior:
		interior.visible = false

func setup(id: int, name: String, boss: bool = false, b_type: String = ""):
	room_id = id
	room_name = name
	has_boss = boss
	boss_type = b_type

func show_interior():
	"""Show the room interior (when player enters)"""
	if interior:
		interior.visible = true

func hide_interior():
	"""Hide the room interior (when player exits)"""
	if interior:
		interior.visible = false

func set_widget_rotation(dir: int):
	"""Set widget rotation (0-5, hex directions)"""
	widget_rotation = dir % 6

func power_widget():
	"""Power the widget (when room puzzle is solved)"""
	widget_powered = true

func get_widget_world_pos() -> Vector2:
	"""Get the world position of the widget socket"""
	if widget_socket:
		return widget_socket.global_position
	return global_position

func get_player_spawn_position() -> Vector2:
	"""Get the world position of the player spawn marker"""
	var spawn = get_node_or_null("PlayerSpawn")
	if spawn:
		return spawn.global_position
	return global_position

func get_save_data() -> Dictionary:
	return {
		"room_id": room_id,
		"is_cleared": is_cleared,
		"boss_defeated": boss_defeated,
		"widget_rotation": widget_rotation,
		"widget_powered": widget_powered,
	}

func load_save_data(data: Dictionary):
	is_cleared = data.get("is_cleared", false)
	boss_defeated = data.get("boss_defeated", false)
	widget_rotation = data.get("widget_rotation", 0)
	widget_powered = data.get("widget_powered", false)
