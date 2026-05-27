class_name Floor9Template
extends FloorTemplate

# ===================================================================
# FLOOR 9 TEMPLATE — The Bone Forges
# Refactored to use FloorController base class + Floor9Template
# ===================================================================
# Factory grid on hex grid: 11 rooms with conveyor belt flow
# Loading Dock → Assembly Line → Furnace Room → Quality Control → Foreman's Office
# ===================================================================

func _init():
	floor_id = 9
	floor_name = "The Bone Forges"
	starting_room_id = "loading_dock"
	hex_step_size = 60.0
	interact_range = 80.0

	# Factory grid layout — conveyor flow from west to east, north/south branches
	rooms = {
		# === LOADING DOCK (Entry) ===
		"loading_dock": {
			"scene_path": "res://scenes/rooms/Floor9_LoadingDock.tscn",
			"position": Vector2(-1000, 0),
			"connections": {
				"east": "assembly_line",
				"exit": "floor8_exit"
			}
		},
		# === ASSEMBLY LINE (Conveyor tutorial) ===
		"assembly_line": {
			"scene_path": "res://scenes/rooms/Floor9_AssemblyLine.tscn",
			"position": Vector2(-600, 0),
			"connections": {
				"west": "loading_dock",
				"east": "break_station",
				"north": "gear_works",
				"south": "bone_yard"
			}
		},
		# === BREAK STATION (Safe + Assembly) ===
		"break_station": {
			"scene_path": "res://scenes/rooms/Floor9_BreakStation.tscn",
			"position": Vector2(-200, 0),
			"connections": {
				"west": "assembly_line",
				"east": "furnace_room",
				"north": "quality_control"
			}
		},
		# === FURNACE ROOM (Soul furnace puzzle) ===
		"furnace_room": {
			"scene_path": "res://scenes/rooms/Floor9_FurnaceRoom.tscn",
			"position": Vector2(200, 0),
			"connections": {
				"west": "break_station",
				"east": "foundry_pit",
				"south": "conveyor_maze"
			}
		},
		# === GEAR WORKS (Construct area) ===
		"gear_works": {
			"scene_path": "res://scenes/rooms/Floor9_GearWorks.tscn",
			"position": Vector2(-600, -600),
			"connections": {
				"south": "assembly_line",
				"east": "quality_control"
			}
		},
		# === BONE YARD (Undead area) ===
		"bone_yard": {
			"scene_path": "res://scenes/rooms/Floor9_BoneYard.tscn",
			"position": Vector2(-600, 600),
			"connections": {
				"north": "assembly_line",
				"east": "conveyor_maze"
			}
		},
		# === QUALITY CONTROL (Machinist mini-boss) ===
		"quality_control": {
			"scene_path": "res://scenes/rooms/Floor9_QualityControl.tscn",
			"position": Vector2(-200, -600),
			"connections": {
				"west": "gear_works",
				"south": "break_station",
				"east": "locker_room"
			}
		},
		# === CONVEYOR MAZE (Moving platforms) ===
		"conveyor_maze": {
			"scene_path": "res://scenes/rooms/Floor9_ConveyorMaze.tscn",
			"position": Vector2(200, 600),
			"connections": {
				"west": "bone_yard",
				"north": "furnace_room",
				"east": "locker_room"
			}
		},
		# === FOUNDRY PIT (Soul-piston elite) ===
		"foundry_pit": {
			"scene_path": "res://scenes/rooms/Floor9_FoundryPit.tscn",
			"position": Vector2(600, 0),
			"connections": {
				"west": "furnace_room",
				"south": "locker_room",
				"east": "foremans_office"
			}
		},
		# === LOCKER ROOM (Safe, final prep) ===
		"locker_room": {
			"scene_path": "res://scenes/rooms/Floor9_LockerRoom.tscn",
			"position": Vector2(600, 600),
			"connections": {
				"west": "conveyor_maze",
				"north": "foundry_pit",
				"northwest": "quality_control",
				"east": "foremans_office"
			}
		},
		# === FOREMAN'S OFFICE (Boss) ===
		"foremans_office": {
			"scene_path": "res://scenes/rooms/Floor9_ForemanOffice.tscn",
			"position": Vector2(1000, 300),
			"connections": {
				"west": "foundry_pit",
				"southwest": "locker_room",
				"exit": "floor10_entrance"
			}
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# Assembly stations
		"AssemblyStation": return "Use Assembly Station"
		"BuildCompanion": return "Build Companion"
		"RepairSelf": return "Repair Self"
		"SalvageParts": return "Salvage Parts"

		# Soul furnaces
		"SoulFurnace": return "Interact with Furnace"
		"FreeSouls": return "Free Souls"
		"BurnSouls": return "Burn Souls"
		"DrainSoul": return "Drain Soul"

		# Conveyor belts
		"ConveyorBelt": return "Ride Conveyor"
		"ConveyorSwitch": return "Flip Switch"
		"Platform": return "Jump to Platform"

		# Boss
		"ForemanEternal": return "Confront Foreman"
		"GlassCase": return "Destroy Skull Case"
		"StrikeTeam": return "Build Strike Team"

		# Puzzles
		"FurnacePuzzle": return "Solve Furnace"
		"AssemblyPuzzle": return "Optimize Assembly"
		"TimingPuzzle": return "Time Conveyor"

		# NPCs / enemies
		"AssemblySkeleton": return "Talk to Skeleton"
		"SoulBurner": return "Drain Soul Burner"
		"SkullMachinist": return "Confront Machinist"
		"Pensioned": return "Approach Pensioned"

		# Save point
		"SavePoint": return "Save Game"

		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalEast", "PortalWest", "PortalNorth", "PortalSouth",
		"PortalNortheast", "PortalNorthwest", "PortalSoutheast", "PortalSouthwest",
		"ReturnPortal"
	]

# -------------------------------------------------------------------
# Salvage & Crafting Configuration
# -------------------------------------------------------------------

func get_crafting_config() -> Dictionary:
	return {
		"materials": {
			"bone": {"from": "undead_kills", "max": 20},
			"gear": {"from": "construct_kills", "max": 20}
		},
		"recipes": {
			"companion": {
				"bone_drone": {"bone": 2, "gear": 1, "effect": "deal_4_block_2"},
				"gear_skeleton": {"bone": 2, "gear": 1, "effect": "deal_6_draw_1"},
				"soul_engine": {"bone": 2, "gear": 1, "effect": "deal_10_discard_buff"},
				"stitch_walker": {"bone": 2, "gear": 1, "effect": "block_8_counter_5"}
			},
			"repair": {"bone": 1, "gear": 2, "heal": 10, "block": 5}
		},
		"max_companions": 3,
		"companions_temporary": true  # One combat only
	}

# -------------------------------------------------------------------
# Soul Furnace Configuration
# -------------------------------------------------------------------

func get_furnace_config() -> Dictionary:
	return {
		"actions": {
			"free_souls": {
				"description": "Destroy furnace, free souls, gain Liberator buff",
				"cost_bone": 0,
				"alarm_chance": 0.7,
				"moral_credit": 1,
				"liberator_buff": "undead_damage_minus_2"
			},
			"burn_souls": {
					"description": "Burn 3 Bone to power a door",
					"cost_bone": 3,
					"soul_debt": 1,
					"effect": "power_door"
				},
			"drain_soul_piston": {
					"description": "Spend 2 gems to free soul mid-combat, deactivate construct",
					"cost_gems": 2,
					"effect": "instant_kill_construct"
				}
		},
		"soul_debt_per_use": 1,
		"liberator_threshold": 5,  # Free 5+ souls = Liberator status
		"furnace_count": 4  # Rooms with furnaces
	}

# -------------------------------------------------------------------
# Conveyor Belt Configuration
# -------------------------------------------------------------------

func get_conveyor_config() -> Dictionary:
	return {
		"directions": {
			"assembly_line": "east",
			"furnace_room": "east",
			"foundry_pit": "south",
			"gear_works": "south",
			"bone_yard": "north",
			"conveyor_maze": "random"
		},
		"hazard_damage": 3,
		"ride_speed": 2.0,
		"timing_window": 2.0  # Seconds to time jump
	}

# -------------------------------------------------------------------
# Boss Configuration (The Foreman Eternal)
# -------------------------------------------------------------------

func get_boss_config() -> Dictionary:
	return {
		"name": "The Foreman Eternal",
		"hp": 65,
		"phase_transition_hp_1": 45,  # Phase 1 -> 2
		"phase_transition_hp_2": 20,    # Phase 2 -> 3
		"phase_1_name": "The Shift",
		"phase_2_name": "Quality Control",
		"phase_3_name": "Efficiency Measures",
		"inspection_interval": 3,  # Attacks every 3rd turn in Phase 1
		"conveyor_speed": 1.5,  # Multiplier for conveyor movement during boss
		"skull_case_hp": 15,
		"skull_destroy_bonus": 0.5,  # +50% damage if skull destroyed
		"strike_team_cost": {"bone": 6, "gear": 3}  # 3 companions at once
	}

# -------------------------------------------------------------------
# Cross-Floor Bleed Checks
# -------------------------------------------------------------------

func get_cross_floor_effects() -> Dictionary:
	return {
		"from_floor8": {
			"scrammed_reactor": {
				"effect": "no_power",
				"construct_speed_penalty": 0.5,
				"undead_speed_penalty": 0.3,
				"foreman_start_hp": 0.8,
				"foreman_enraged": true
			},
			"radiation_debuff": {
				"effect": "radiation",
				"hp_loss_per_room": 2,
				"elementals_kin": true
			},
			"elemental_core_held": {
				"effect": "core_empowered",
				"bonus": "can_overclock_furnaces"
			},
			"elementals_loose": {
				"effect": "foreman_furious",
				"bonus": "plus_2_elite_encounters"
			},
			"chief_handler_killed": {
				"effect": "goblin_refugees",
				"bonus": "mixed_goblin_undead_fights"
			}
		},
		"to_floor10": {
			"liberator_status": {
				"effect": "dragon_compassion",
				"bonus": "peaceful_resolution_offered",
				"damage_reduction": 3
			},
			"soul_debt_gt_3": {
				"effect": "dragon_disgust",
				"penalty": "opens_strongest_attack"
			},
			"companions_built_5": {
				"effect": "dragon_respect",
				"bonus": "secret_ending_path"
			},
			"all_furnaces_destroyed": {
				"effect": "freed_souls_follow",
				"bonus": "whisper_attack_patterns"
			}
		}
	}
