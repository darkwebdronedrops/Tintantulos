class_name Floor1Template
extends FloorTemplate

# ===================================================================
# FLOOR 1 TEMPLATE — The Portal Room
# ===================================================================
# Cross layout: Center + 4 directions (North, East, South, West)
# ===================================================================

func _init():
	floor_id = 1
	floor_name = "The Portal Room"
	starting_room_id = "central"
	hex_step_size = 60.0
	interact_range = 80.0
	
	rooms = {
		"central": {
			"scene_path": "res://scenes/rooms/Floor1_Central.tscn",
			"position": Vector2(0, 0),
			"connections": {"north": "north", "east": "east", "south": "south", "west": "west", "up": "boss"}
		},
		"north": {
			"scene_path": "res://scenes/rooms/Floor1_North_Door.tscn",
			"position": Vector2(0, -800),
			"connections": {"south": "central"}
		},
		"east": {
			"scene_path": "res://scenes/rooms/Floor1_East_Warren.tscn",
			"position": Vector2(800, 0),
			"connections": {"west": "central"}
		},
		"south": {
			"scene_path": "res://scenes/rooms/Floor1_South_Shrine.tscn",
			"position": Vector2(0, 800),
			"connections": {"north": "central"}
		},
		"west": {
			"scene_path": "res://scenes/rooms/Floor1_West_Gauntlet.tscn",
			"position": Vector2(-800, 0),
			"connections": {"east": "central"}
		},
		"boss": {
			"scene_path": "res://scenes/rooms/Floor1_Boss_Arena.tscn",
			"position": Vector2(1200, -800),
			"connections": {"exit": "central"}
		}
	}

func get_interactable_label(node_name: String) -> String:
	match node_name:
		"NPC_Construct": return "Talk to Construct"
		"ShopKiosk": return "Open Shop"
		"Chest": return "Open Chest"
		"BreakableWall": return "Break Wall"
		"TheDoor": return "Approach Door"
		"Droplet": return "Receive Blessing"
		"SavePoint": return "Save Game"
		"Altar": return "Make Offering"
		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in ["MainPortal", "PortalNorth", "PortalEast", "PortalSouth", "PortalWest", "PortalUp", "ReturnPortal"]
