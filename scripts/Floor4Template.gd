class_name Floor4Template
extends FloorTemplate

# ===================================================================
# FLOOR 4 TEMPLATE — The Curio Bazaar (Refactored to Room-Based)
# ===================================================================
# Rooms: bazaar (main) → undercroft | refectory
# Booth interiors loaded dynamically as overlays
# ===================================================================

const BOOTH_RADIUS: float = 900.0

func _init():
	floor_id = 4
	floor_name = "The Curio Bazaar"
	starting_room_id = "bazaar"
	hex_step_size = 60.0
	interact_range = 100.0
	
	rooms = {
		"bazaar": {
			"scene_path": "res://scenes/rooms/floor4/Floor4_Bazaar.tscn",
			"position": Vector2(0, 0),
			"connections": {
				"down": "undercroft",
				"up": "refectory"
			}
		},
		"undercroft": {
			"scene_path": "res://scenes/rooms/floor4/Floor4_Undercroft.tscn",
			"position": Vector2(0, 2000),
			"connections": {
				"up": "bazaar"
			}
		},
		"refectory": {
			"scene_path": "res://scenes/rooms/floor4/Floor4_Refectory.tscn",
			"position": Vector2(0, -2000),
			"connections": {
				"down": "bazaar"
			}
		}
	}
	
	custom_data = {
		# === BOOTH POSITIONS (on bazaar floor) ===
		"booth_positions": {
			"booth_12": _circle_pos(12),
			"booth_1":  _circle_pos(1),
			"booth_2":  _circle_pos(2),
			"booth_3":  _circle_pos(3),
			"booth_4":  _circle_pos(4),
			"booth_5":  _circle_pos(5),
			"booth_6":  _circle_pos(6),
			"booth_7":  _circle_pos(7),
			"booth_8":  _circle_pos(8),
			"booth_9":  _circle_pos(9),
			"booth_10": _circle_pos(10),
			"booth_11": _circle_pos(11),
		},
		"real_vendors": ["booth_12", "booth_4", "booth_8"],
		"trap_types": {
			"booth_1":  "infinity_mirror",
			"booth_2":  "bargain_bin",
			"booth_3":  "timepiece_exchange",
			"booth_5":  "memory_monger",
			"booth_6":  "duplicate_drapers",
			"booth_7":  "glitch_glassworks",
			"booth_9":  "rollback_refinery",
			"booth_10": "sample_crier",
			"booth_11": "reflection_salon",
		},
		
		# === UNDERCROFT ===
		"undercroft_hazards": {
			"aether_slick_zones": [
				{"center": Vector2(-150, 100), "radius": 80},
				{"center": Vector2(250, -150), "radius": 100},
				{"center": Vector2(0, 300), "radius": 60},
			],
		},
		"undercroft_loot": ["machine_oil", "polished_brass"],
		
		# === REFECTORY ===
		"refectory_food_stations": [
			{"pos": Vector2(-200, -100), "type": "memory_stew"},
			{"pos": Vector2(200, 100),  "type": "nostalgia_bread"},
			{"pos": Vector2(0, 200),   "type": "phantom_meat"},
		],
		
		# === GREAT LIFTER ===
		"great_lifter_repaired": false,
		"required_parts": ["gear_part_1", "gear_part_2", "steam_valve"],
		"collected_parts": [],
		
		# === BOOTH CLEAR TRACKING ===
		"booths_cleared_main": [],
	}

func _circle_pos(clock_hour: int) -> Vector2:
	var angle = deg_to_rad((clock_hour - 3) * -30.0)
	return Vector2(cos(angle), sin(angle)) * BOOTH_RADIUS

# -------------------------------------------------------------------
# Level tracking (for legacy level-switching architecture)
# -------------------------------------------------------------------

var _current_level: String = "main"
var _unlocked_levels: Array[String] = ["main"]  # main always unlocked

func get_current_level() -> String:
	return _current_level

func set_current_level(level: String):
	_current_level = level

func is_level_unlocked(level: String) -> bool:
	return level in _unlocked_levels

func unlock_level(level: String):
	if level not in _unlocked_levels:
		_unlocked_levels.append(level)

# -------------------------------------------------------------------
# Exit helpers (level transition points)
# -------------------------------------------------------------------

func get_exit_name_at_position(level: String, world_pos: Vector2, threshold: float = 80.0) -> String:
	match level:
		"main":
			var exits = {
				"grate1": Vector2(-400, 400),
				"grate2": Vector2(400, -300),
				"grate3": Vector2(0, 800),
				"stairs1": Vector2(-700, 0),
				"stairs2": Vector2(700, 200),
				"lift": Vector2(200, -600),
			}
			for exit_name in exits.keys():
				if world_pos.distance_to(exits[exit_name]) < threshold:
					return exit_name
		"undercroft":
			var exits = {
				"ladder1": Vector2(-200, 300),
				"ladder2": Vector2(300, -200),
				"steam_vent": Vector2(0, -400),
			}
			for exit_name in exits.keys():
				if world_pos.distance_to(exits[exit_name]) < threshold:
					return exit_name
		"refectory":
			var exits = {
				"stairs1": Vector2(-400, 0),
				"stairs2": Vector2(500, 200),
				"dumbwaiter": Vector2(0, -300),
			}
			for exit_name in exits.keys():
				if world_pos.distance_to(exits[exit_name]) < threshold:
					return exit_name
	return ""

func get_exit_target_level(exit_name: String) -> String:
	match exit_name:
		"grate1", "grate2", "grate3": return "undercroft"
		"stairs1", "stairs2", "lift": return "refectory"
		"ladder1", "ladder2", "steam_vent": return "main"
		"dumbwaiter", "stairs_down1", "stairs_down2": return "main"
	return ""

# -------------------------------------------------------------------
# Booth helpers
# -------------------------------------------------------------------

func get_booth_position(booth_id: String) -> Vector2:
	return custom_data.get("booth_positions", {}).get(booth_id, Vector2.ZERO)

func get_booth_id_at_position(world_pos: Vector2, threshold: float = 120.0) -> String:
	var positions = custom_data.get("booth_positions", {})
	for booth_id in positions.keys():
		if world_pos.distance_to(positions[booth_id]) < threshold:
			return booth_id
	return ""

func is_real_vendor(booth_id: String) -> bool:
	return booth_id in custom_data.get("real_vendors", [])

func get_trap_type(booth_id: String) -> String:
	return custom_data.get("trap_types", {}).get(booth_id, "")

func get_booth_scene_path(booth_id: String) -> String:
	match booth_id:
		"booth_12": return "res://scenes/rooms/floor4/Booth_Gearwright.tscn"
		"booth_4":  return "res://scenes/rooms/floor4/Booth_SteamPress.tscn"
		"booth_8":  return "res://scenes/rooms/floor4/Booth_Curio.tscn"
		"booth_1":  return "res://scenes/rooms/floor4/Booth_InfinityMirror.tscn"
		"booth_2":  return "res://scenes/rooms/floor4/Booth_BargainBin.tscn"
		"booth_3":  return "res://scenes/rooms/floor4/Booth_TimepieceExchange.tscn"
		"booth_5":  return "res://scenes/rooms/floor4/Booth_MemoryMonger.tscn"
		"booth_6":  return "res://scenes/rooms/floor4/Booth_DuplicateDrapers.tscn"
		"booth_7":  return "res://scenes/rooms/floor4/Booth_GlitchGlassworks.tscn"
		"booth_9":  return "res://scenes/rooms/floor4/Booth_RollbackRefinery.tscn"
		"booth_10": return "res://scenes/rooms/floor4/Booth_SampleCrier.tscn"
		"booth_11": return "res://scenes/rooms/floor4/Booth_ReflectionSalon.tscn"
		_:          return "res://scenes/rooms/floor4/Booth_Trap.tscn"

# -------------------------------------------------------------------
# Terrain / Hazards
# -------------------------------------------------------------------

func is_in_aether_slick(world_pos: Vector2) -> bool:
	var zones = custom_data.get("undercroft_hazards", {}).get("aether_slick_zones", [])
	for zone in zones:
		var center = zone.get("center", Vector2.ZERO)
		var radius = zone.get("radius", 0)
		if world_pos.distance_to(center) < radius:
			return true
	return false

func get_food_station_at(world_pos: Vector2, threshold: float = 60.0) -> Dictionary:
	var stations = custom_data.get("refectory_food_stations", [])
	for station in stations:
		if world_pos.distance_to(station.get("pos", Vector2.ZERO)) < threshold:
			return station
	return {}

# -------------------------------------------------------------------
# Great Lifter
# -------------------------------------------------------------------

func has_all_parts() -> bool:
	var required = custom_data.get("required_parts", [])
	var collected = custom_data.get("collected_parts", [])
	return required.size() > 0 and collected.size() >= required.size()

func collect_part(part_name: String):
	var collected = custom_data.get("collected_parts", [])
	if part_name not in collected:
		collected.append(part_name)
		custom_data["collected_parts"] = collected

func is_lifter_repaired() -> bool:
	return custom_data.get("great_lifter_repaired", false)

func repair_lifter():
	custom_data["great_lifter_repaired"] = true

func get_lifter_destination() -> String:
	if is_lifter_repaired():
		return "floor5"
	var misfires = ["undercroft", "refectory", "main"]
	return misfires[randi() % misfires.size()]

# -------------------------------------------------------------------
# Booth tracking
# -------------------------------------------------------------------

func clear_booth(booth_id: String):
	var cleared = custom_data.get("booths_cleared_main", [])
	if booth_id not in cleared:
		cleared.append(booth_id)
		custom_data["booths_cleared_main"] = cleared

func is_booth_cleared(booth_id: String) -> bool:
	return booth_id in custom_data.get("booths_cleared_main", [])
