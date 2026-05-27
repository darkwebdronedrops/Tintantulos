class_name Floor6Template
extends FloorTemplate

# ===================================================================
# FLOOR 6 TEMPLATE — The Lunar University
# Refactored to use FloorController base class + Floor6Template
# ===================================================================
# Quadrangle center + 4 colleges + Undercroft + Clocktower (boss)
# ===================================================================

func _init():
	floor_id = 6
	floor_name = "The Lunar University"
	starting_room_id = "quadrangle"
	hex_step_size = 60.0
	interact_range = 80.0
	
	rooms = {
		"quadrangle": {
			"scene_path": "res://scenes/rooms/Floor6_Quadrangle.tscn",
			"position": Vector2(0, 0),
			"connections": {
				"north": "gears",
				"east": "echoes",
				"south": "aether",
				"west": "pacts",
				"down": "undercroft",
				"up": "clocktower",
				"exit": "floor5_exit"
			}
		},
		"gears": {
			"scene_path": "res://scenes/rooms/Floor6_Gears.tscn",
			"position": Vector2(0, -800),
			"connections": {
				"south": "quadrangle",
				"shortcut": "echoes"  # Gear Garden maze shortcut
			}
		},
		"echoes": {
			"scene_path": "res://scenes/rooms/Floor6_Echoes.tscn",
			"position": Vector2(800, 0),
			"connections": {
				"west": "quadrangle",
				"shortcut": "gears"
			}
		},
		"aether": {
			"scene_path": "res://scenes/rooms/Floor6_Aether.tscn",
			"position": Vector2(0, 800),
			"connections": {
				"north": "quadrangle"
			}
		},
		"pacts": {
			"scene_path": "res://scenes/rooms/Floor6_Pacts.tscn",
			"position": Vector2(-800, 0),
			"connections": {
				"east": "quadrangle"
			}
		},
		"undercroft": {
			"scene_path": "res://scenes/rooms/Floor6_Undercroft.tscn",
			"position": Vector2(200, 200),
			"connections": {
				"up": "quadrangle"
			}
		},
		"clocktower": {
			"scene_path": "res://scenes/rooms/Floor6_Clocktower_Apex.tscn",
			"position": Vector2(0, -1200),
			"connections": {
				"down": "quadrangle"
			}
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# The Registrar (course assignment)
		"TheRegistrar": return "Talk to Registrar"
		
		# Clocktower mechanism (sabotage)
		"ClockMechanism": return "Sabotage Clock"
		"ClockSpeedDial": return "Adjust Clock"
		
		# Library books (College of Echoes)
		"WhisperingBook": return "Read Book"
		"ScreamingBook": return "Read Book"
		"ResearchTome": return "Study Tome"
		
		# Gear Garden puzzle
		"GearPuzzleNode": return "Align Gear"
		
		# Dean's office (locked)
		"DeanDoor": return "Dean's Office"
		
		# College of Pacts (locked door)
		"PactsDoor": return "College of Pacts"
		
		# Undercroft goblin
		"SneakThief": return "Talk to Janitor"
		
		# Moonlight-sensitive objects
		"MoonlightText": return "Read Inscription"
		"ShadowCache": return "Search Cache"
		
		# Thesis panel (College of Echoes)
		"ThesisPanel": return "Defend Thesis"
		
		# Save point
		"SavePoint": return "Save Game"
		
		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalNorth", "PortalEast", "PortalSouth", "PortalWest",
		"PortalUp", "PortalDown", "ReturnPortal",
		"DeanElevator", "UndercroftHatch", "GearGardenGate"
	]

# -------------------------------------------------------------------
# Curriculum Configuration
# -------------------------------------------------------------------

func get_course_config() -> Dictionary:
	return {
		"courses_per_visit": 3,
		"grading": {
			"A": {"defeat_count": 5, "no_damage": true, "reward_tier": "epic", "gems": 50},
			"B": {"defeat_count": 3, "reward_tier": "rare", "gems": 25},
			"C": {"defeat_count": 1, "reward_tier": "common", "gems": 0},
			"F": {"defeat_count": 0, "reward_tier": "none", "penalty": "detention"}
		},
		"audit_mode": {"no_requirements": true, "no_rewards": true, "safe": true}
	}

# -------------------------------------------------------------------
# Moonlight Beam Configuration
# -------------------------------------------------------------------

func get_moonlight_config() -> Dictionary:
	return {
		"shift_interval": 5,  # Combat turns
		"beam_count": 3,
		"light_effect": "reveal_text_and_attract_patrols",
		"shadow_effect": "hide_from_patrols"
	}

# -------------------------------------------------------------------
# Clocktower Bell Configuration
# -------------------------------------------------------------------

func get_clocktower_config() -> Dictionary:
	return {
		"bell_interval": 10,  # Combat turns
		"heal_amount": 5,
		"can_sabotage": true,
		"sabotage_location": "gears"  # Clock mechanism in College of Gears
	}

# -------------------------------------------------------------------
# Boss Configuration (The Dean)
# -------------------------------------------------------------------

func get_boss_config() -> Dictionary:
	return {
		"name": "The Dean",
		"hp": 70,
		"phase_transition_hp": 35,
		"pattern": ["Defend", "Special", "Melee", "Defend"],
		"phase_2_name": "Lunar Construct",
		"tenure": true  # Cannot be debuffed for more than 1 turn
	}

# -------------------------------------------------------------------
# Undercroft Goblin Config
# -------------------------------------------------------------------

func get_undercroft_config() -> Dictionary:
	return {
		"goblin_name": "Sneak Thief",
		"goblin_hp": 10,
		"behavior": "steal_with_iou",
		"reward": "Master Key",
		"master_key_effect": "opens_any_locked_door"
	}

# -------------------------------------------------------------------
# Cross-Floor Bleed Checks
# -------------------------------------------------------------------

func get_cross_floor_effects() -> Dictionary:
	return {
		"from_floor5": {
			"elemental_core_defeated": {
				"effect": "aether_partially_reopens",
				"bonus": "1_random_elemental_card"
			},
			"spore_filter_active": {
				"effect": "reduced_toxic_ink_penalty",
				"bonus": "toxic_ink_attention_drain_halved"
			}
		},
		"to_floor5": {
			"clocktower_sabotaged": {
				"effect": "predictable_storm_timing",
				"bonus": "floor5_storm_interval_known"
			},
			"goblin_janitor_befriended": {
				"effect": "wrench_in_mooring",
				"bonus": "one_airship_unlocked_early"
			}
		}
	}
