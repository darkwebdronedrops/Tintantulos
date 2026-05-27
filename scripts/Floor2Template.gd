class_name Floor2Template
extends FloorTemplate

# ===================================================================
# FLOOR 2 TEMPLATE — The Fungal Cavern
# ===================================================================
# 3-tier vertical cavern connected by fungal bridges
# Entry overlook → Upper/Middle/Lower → Spore Heart (boss)
# Secret room hidden in Lower Cavern
# ===================================================================

func _init():
	floor_id = 2
	floor_name = "The Fungal Cavern"
	starting_room_id = "entry"
	hex_step_size = 60.0
	interact_range = 80.0

	rooms = {
		"entry": {
			"scene_path": "res://scenes/rooms/Floor2_Entry.tscn",
			"position": Vector2(0, 0),
			"connections": {"north": "upper", "east": "middle", "south": "lower"}
		},
		"upper": {
			"scene_path": "res://scenes/rooms/Floor2_Upper.tscn",
			"position": Vector2(0, -1200),
			"connections": {"south": "entry", "down": "spore_heart"}
		},
		"middle": {
			"scene_path": "res://scenes/rooms/Floor2_Middle.tscn",
			"position": Vector2(1200, 0),
			"connections": {"west": "entry", "down": "spore_heart"}
		},
		"lower": {
			"scene_path": "res://scenes/rooms/Floor2_Lower.tscn",
			"position": Vector2(0, 1200),
			"connections": {"north": "entry", "down": "spore_heart", "secret": "secret"}
		},
		"secret": {
			"scene_path": "res://scenes/rooms/Floor2_Secret.tscn",
			"position": Vector2(800, 2000),
			"connections": {"exit": "lower"}
		},
		"spore_heart": {
			"scene_path": "res://scenes/rooms/Floor2_SporeHeart.tscn",
			"position": Vector2(2000, 0),
			"connections": {"exit": "entry"}
		}
	}

func get_interactable_label(node_name: String) -> String:
	match node_name:
		"FungalBridge": return "Cross Bridge"
		"SporeGate": return "Burn Spores"
		"BreakableWall": return "Break Wall"
		"PoolShrine": return "Approach Pool"
		"Elevator": return "Repair Elevator"
		"GearPart": return "Collect Gear"
		"BossThrone": return "Challenge Boss"
		"SavePoint": return "Save Game"
		"MushroomPlatform": return "Jump Platform"
		"SporeCloud": return "Disperse Spores"
		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalEntry", "PortalUpper", "PortalMiddle", "PortalLower",
		"PortalSecret", "PortalSporeHeart", "ReturnPortal", "ElevatorPortal"
	]
