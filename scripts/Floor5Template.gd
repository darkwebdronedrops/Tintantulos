class_name Floor5Template
extends FloorTemplate

# ===================================================================
# FLOOR 5 TEMPLATE — The Airship Docks
# Refactored to use FloorController base class + Floor5Template
# ===================================================================
# Vertical tower: Mooring → 3 Airships → Crow's Nest → Aetherworks (boss)
# ===================================================================

func _init():
	floor_id = 5
	floor_name = "The Airship Docks"
	starting_room_id = "mooring"
	hex_step_size = 60.0
	interact_range = 80.0
	
	rooms = {
		"mooring": {
			"scene_path": "res://scenes/rooms/Floor5_Mooring.tscn",
			"position": Vector2(0, 800),
			"connections": {
				"up": "breeze",
				"up2": "boiler",
				"up3": "gale",
				"down": "floor4_exit"  # Elevator back to Floor 4
			}
		},
		"breeze": {
			"scene_path": "res://scenes/rooms/Floor5_Breeze.tscn",
			"position": Vector2(-600, 0),
			"connections": {
				"down": "mooring",
				"up": "crow",
				"right": "boiler"
			}
		},
		"boiler": {
			"scene_path": "res://scenes/rooms/Floor5_Boiler.tscn",
			"position": Vector2(0, 0),
			"connections": {
				"down": "mooring",
				"up": "crow",
				"left": "breeze",
				"right": "gale",
				"secret": "cargo"
			}
		},
		"gale": {
			"scene_path": "res://scenes/rooms/Floor5_Gale.tscn",
			"position": Vector2(600, 0),
			"connections": {
				"down": "mooring",
				"up": "crow",
				"left": "boiler"
			}
		},
		"cargo": {
			"scene_path": "res://scenes/rooms/Floor5_Cargo.tscn",
			"position": Vector2(50, 50),
			"connections": {
				"exit": "boiler"
			}
		},
		"crow": {
			"scene_path": "res://scenes/rooms/Floor5_Crow.tscn",
			"position": Vector2(0, -800),
			"connections": {
				"down": "breeze",
				"down2": "boiler",
				"down3": "gale",
				"up": "aether"
			}
		},
		"aether": {
			"scene_path": "res://scenes/rooms/Floor5_Aetherworks.tscn",
			"position": Vector2(0, -800),
			"connections": {
				"exit": "crow"
			}
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# Steam valves (one per airship, unlock mooring)
		"SteamValve_Breeze": return "Turn Valve"
		"SteamValve_Boiler": return "Turn Valve"
		"SteamValve_Gale": return "Turn Valve"
		
		# Anchor points (protect against wind shear)
		"AnchorPoint": return "Anchor Rope"
		
		# Lightning rods (CHARGE source / danger)
		"LightningRod": return "Approach Rod"
		
		# Cargo lifts (vertical travel)
		"CargoLift": return "Ride Lift"
		
		# Boss altar entrance
		"BossAltar": return "Challenge Boss"
		
		# Hidden cargo door (secret room access)
		"FakeWall": return "Inspect Wall"
		
		# Environmental triggers
		"SteamVent": return "Vent Steam"
		
		# Grounding cable (for lightning rod puzzle)
		"GroundingCable": return "Attach Cable"
		
		# Save point
		"SavePoint": return "Save Game"
		
		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalUp", "PortalDown", "PortalLeft", "PortalRight",
		"Gangplank_Breeze", "Gangplank_Boiler", "Gangplank_Gale",
		"ReturnPortal", "BossPortal", "CargoLift", "SecretDoor"
	]

# -------------------------------------------------------------------
# CHARGE System Configuration
# -------------------------------------------------------------------

func get_charge_config() -> Dictionary:
	return {
		"max_charge": 10,
		"wind_per_gust": 1,
		"steam_per_vent": 2,
		"lightning_per_rod": 3,
		"elemental_death_bonus": 1,
		"vent_threshold": 10
	}

# -------------------------------------------------------------------
# Environmental Hazard Timers (in combat turns)
# -------------------------------------------------------------------

func get_hazard_timers() -> Dictionary:
	return {
		"wind_gust_interval": 3,
		"steam_vent_interval": 4,
		"storm_phase_interval": 8,
		"steam_tell_turns": 2  # Warning turns before vent burst
	}

# -------------------------------------------------------------------
# Gangplank Weight Limits
# -------------------------------------------------------------------

func get_gangplank_limit() -> int:
	return 3  # Max entities before collapse (player + 2 enemies)
