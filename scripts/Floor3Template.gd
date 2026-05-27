class_name Floor3Template
extends FloorTemplate

# ===================================================================
# FLOOR 3 TEMPLATE — The Gearworks
# ===================================================================
# 12 outer rooms arranged like a clock + 1 inner room (Crown Cog)
# Room 12 (The Quench) at 12 o'clock = starting room, does NOT rotate
# Rooms 1-11 rotate when dial is triggered
# ===================================================================

const OUTER_RADIUS: float = 1500.0
const INNER_RADIUS: float = 200.0
const ROTATION_STEP: float = 30.0
const ROOM_INTERIOR_SIZE: float = 350.0
const GLOBAL_SCENE_SIZE: float = 3000.0

# Room names
const ROOM_NAMES: Array[String] = [
	"The Reservoir",      # 1
	"The Spark",         # 2
	"The Governor",      # 3
	"The Draft",         # 4
	"The Temper",        # 5
	"The Beacon",        # 6
	"The Escapement",    # 7
	"The Bearing",       # 8
	"The Flywheel",      # 9
	"The Counterweight", # 10
	"The Oiler",         # 11
	"The Quench"         # 12 (stationary)
]

# Boss rooms
const BOSS_ROOMS: Array[int] = [6, 9, 11]
const BOSS_TYPES: Array[String] = [
	"", "", "", "", "", "TheCaldera",
	"", "", "GearMother", "TheEidolon",
	"GoblinKingGrimgut", ""
]

# Room themes for sprite assets
const ROOM_THEMES: Dictionary = {
	1: "reservoir",
	2: "spark",
	3: "governor",
	4: "draft",
	5: "temper",
	6: "beacon",
	7: "escapement",
	8: "bearing",
	9: "flywheel",
	10: "counterweight",
	11: "oiler",
	12: "quench"
}

# Room scene paths
const ROOM_SCENE_PATHS: Dictionary = {
	1: "res://scenes/rooms/Room_01_Reservoir.tscn",
	2: "res://scenes/rooms/Room_02_Spark.tscn",
	3: "res://scenes/rooms/Room_03_Governor.tscn",
	4: "res://scenes/rooms/Room_04_Draft.tscn",
	5: "res://scenes/rooms/Room_05_Temper.tscn",
	6: "res://scenes/rooms/Room_06_Beacon.tscn",
	7: "res://scenes/rooms/Room_07_Escapement.tscn",
	8: "res://scenes/rooms/Room_08_Bearing.tscn",
	9: "res://scenes/rooms/Room_09_Flywheel.tscn",
	10: "res://scenes/rooms/Room_10_Counterweight.tscn",
	11: "res://scenes/rooms/Room_11_Oiler.tscn",
	12: "res://scenes/rooms/Room_12_Quench.tscn"
}

# Slot angles for dial positions
const SLOT_ANGLES: Array[float] = [
	-90.0, -60.0, -30.0, 0.0, 30.0, 60.0,
	90.0, 120.0, 150.0, 180.0, -150.0, -120.0
]

# Room colors for overworld hexes
const ROOM_COLORS: Dictionary = {
	1: Color(0.3, 0.4, 0.45),
	2: Color(0.45, 0.3, 0.25),
	3: Color(0.35, 0.35, 0.4),
	4: Color(0.4, 0.4, 0.45),
	5: Color(0.45, 0.3, 0.2),
	6: Color(0.35, 0.35, 0.4),
	7: Color(0.4, 0.4, 0.35),
	8: Color(0.4, 0.4, 0.4),
	9: Color(0.35, 0.35, 0.4),
	10: Color(0.4, 0.4, 0.35),
	11: Color(0.35, 0.3, 0.25),
	12: Color(0.3, 0.4, 0.45)
}

func _init():
	floor_id = 3
	floor_name = "The Gearworks"
	starting_room_id = "12"
	hex_step_size = 60.0
	interact_range = 80.0
	
	# Build rooms dict for FloorTemplate compatibility
	# Floor 3 uses integer IDs, not strings
	for i in range(12):
		var room_id = str(i + 1)
		var angle = SLOT_ANGLES[_get_slot_index(i + 1)]
		var pos = Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * OUTER_RADIUS
		rooms[room_id] = {
			"scene_path": ROOM_SCENE_PATHS[i + 1],
			"position": pos,
			"connections": {}  # Floor 3 uses hex grid movement, not portal connections
		}

func _get_slot_index(room_id: int) -> int:
	"""Room 12 = slot 0, Rooms 1-11 = slots 1-11"""
	if room_id == 12:
		return 0
	return room_id

func get_room_color(room_id: int) -> Color:
	return ROOM_COLORS.get(room_id, Color(0.4, 0.4, 0.5))

func is_boss_room(room_id: int) -> bool:
	return room_id in BOSS_ROOMS

func get_boss_type(room_id: int) -> String:
	if room_id >= 1 and room_id <= 12:
		return BOSS_TYPES[room_id - 1]
	return ""

func get_room_theme(room_id: int) -> String:
	return ROOM_THEMES.get(room_id, "unknown")

func is_stationary(room_id: int) -> bool:
	return room_id == 12

func get_slot_angle(room_id: int) -> float:
	var slot = _get_slot_index(room_id)
	return SLOT_ANGLES[slot]

func get_room_name(room_id: int) -> String:
	if room_id >= 1 and room_id <= 12:
		return ROOM_NAMES[room_id - 1]
	return "Unknown"
