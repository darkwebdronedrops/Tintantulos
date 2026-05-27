class_name Floor8Template
extends FloorTemplate

# ===================================================================
# FLOOR 8 TEMPLATE — The Overclock Forge
# Refactored to use FloorController base class + Floor8Template
# ===================================================================
# Vertical factory on hex grid: 11 rooms stacked in spiraling refinery
# Loading Bay → Lower Works → Middle Works → Upper Works → Control Room
# ===================================================================

func _init():
	floor_id = 8
	floor_name = "The Overclock Forge"
	starting_room_id = "loading_bay"
	hex_step_size = 60.0
	interact_range = 80.0

	# Vertical spiral layout — stacked with slight horizontal offset for spiral feel
	rooms = {
		# === LOADING BAY (Entry) ===
		"loading_bay": {
			"scene_path": "res://scenes/rooms/Floor8_LoadingBay.tscn",
			"position": Vector2(0, 0),
			"connections": {
				"north": "lower_works",
				"exit": "floor7_exit"
			}
		},
		# === LOWER WORKS (Fire + Water) ===
		"lower_works": {
			"scene_path": "res://scenes/rooms/Floor8_LowerWorks.tscn",
			"position": Vector2(100, -600),
			"connections": {
				"south": "loading_bay",
				"north": "break_room",
				"east": "containment_hall"
			}
		},
		"break_room": {
			"scene_path": "res://scenes/rooms/Floor8_BreakRoom.tscn",
			"position": Vector2(-200, -800),
			"connections": {
				"south": "lower_works",
				"east": "the_leak"
			}
		},
		"containment_hall": {
			"scene_path": "res://scenes/rooms/Floor8_ContainmentHall.tscn",
			"position": Vector2(400, -600),
			"connections": {
				"west": "lower_works",
				"north": "the_leak",
				"northeast": "middle_works"
			}
		},
		"the_leak": {
			"scene_path": "res://scenes/rooms/Floor8_TheLeak.tscn",
			"position": Vector2(300, -1000),
			"connections": {
				"south": "containment_hall",
				"west": "break_room",
				"north": "middle_works"
			}
		},
		# === MIDDLE WORKS (Earth + Air) ===
		"middle_works": {
			"scene_path": "res://scenes/rooms/Floor8_MiddleWorks.tscn",
			"position": Vector2(500, -1400),
			"connections": {
				"southwest": "the_leak",
				"west": "lower_works",
				"north": "union_hall",
				"east": "the_crack"
			}
		},
		"union_hall": {
			"scene_path": "res://scenes/rooms/Floor8_UnionHall.tscn",
			"position": Vector2(300, -1800),
			"connections": {
				"south": "middle_works",
				"east": "upper_works",
				"north": "the_crack"
			}
		},
		"the_crack": {
			"scene_path": "res://scenes/rooms/Floor8_TheCrack.tscn",
			"position": Vector2(700, -1600),
			"connections": {
				"west": "middle_works",
				"south": "union_hall",
				"north": "upper_works"
			}
		},
		# === UPPER WORKS (Reactor) ===
		"upper_works": {
			"scene_path": "res://scenes/rooms/Floor8_UpperWorks.tscn",
			"position": Vector2(500, -2200),
			"connections": {
				"southwest": "the_crack",
				"west": "union_hall",
				"north": "padlock_door"
			}
		},
		"padlock_door": {
			"scene_path": "res://scenes/rooms/Floor8_PadlockDoor.tscn",
			"position": Vector2(300, -2600),
			"connections": {
				"south": "upper_works",
				"up": "control_room"
			}
		},
		# === CONTROL ROOM (Boss) ===
		"control_room": {
			"scene_path": "res://scenes/rooms/Floor8_ControlRoom.tscn",
			"position": Vector2(300, -3000),
			"connections": {
				"down": "padlock_door",
				"exit": "floor9_entrance"
			}
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# Containment vessels
		"ContainmentVessel": return "Interact with Vessel"
		"VentVessel": return "Vent Vessel"
		"OverclockVessel": return "Overclock Vessel"
		"PatchVessel": return "Patch Vessel"

		# Reactor / scram
		"ScramLever": return "Pull Scram Lever"
		"CoolantPipe": return "Destroy Coolant Pipe"
		"ReactorConsole": return "Use Console"

		# Padlock door
		"Padlock": return "Pick Lock"
		"PadlockKey": return "Use Key"
		"DoorCache": return "Open Cache"

		# Goblin NPCs
		"ContainmentGoblin": return "Talk to Engineer"
		"AlarmRinger": return "Talk to Ringer"
		"OverclockShaman": return "Talk to Shaman"
		"ChiefHandler": return "Talk to Handler"
		"Blix": return "Confront Blix"

		# Union negotiation
		"Negotiate": return "Negotiate Union"
		"Intimidate": return "Intimidate Goblins"
		"SabotageGear": return "Sabotage Equipment"

		# Puzzles
		"ContainmentOptimization": return "Optimize Containment"
		"PressureGauge": return "Read Gauge"

		# Save point
		"SavePoint": return "Save Game"

		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalNorth", "PortalSouth", "PortalEast", "PortalWest",
		"PortalUp", "PortalDown", "PortalNortheast", "PortalNorthwest",
		"PortalSoutheast", "PortalSouthwest",
		"ReturnPortal"
	]

# -------------------------------------------------------------------
# Overclock Meter Configuration
# -------------------------------------------------------------------

func get_overclock_config() -> Dictionary:
	return {
		"thresholds": {
			"low": {"min": 0, "max": 10, "card_cost_reduction": 0, "misfire_chance": 0.0, "elemental_multiplier": 1.0},
			"medium": {"min": 10, "max": 15, "card_cost_reduction": 1, "misfire_chance": 0.0, "elemental_multiplier": 1.0},
			"high": {"min": 15, "max": 20, "card_cost_reduction": 1, "misfire_chance": 0.25, "elemental_multiplier": 1.0},
			"critical": {"min": 20, "max": 999, "card_cost_reduction": 2, "misfire_chance": 0.50, "elemental_multiplier": 2.0}
		},
		"decay_per_room": 2,
		"goblin_kill_bonus": 2,
		"elemental_kill_bonus": 1
	}

# -------------------------------------------------------------------
# Elemental Charge Configuration
# -------------------------------------------------------------------

func get_elemental_charge_config() -> Dictionary:
	return {
		"elements": ["fire", "water", "earth", "air"],
		"max_charge": 10,
		"steam_mote_charge_rate": 2,  # Builds CHARGE twice as fast
		"steam_mote_explode_at": 3,  # Explodes at 3 instead of 5
		"pressure_knot_release_at": 3,  # Pressure wave at 3 CHARGE
		"ion_howler_scramble_at": 5  # Scrambles hand costs at max CHARGE
	}

# -------------------------------------------------------------------
# Containment Vessel Configuration
# -------------------------------------------------------------------

func get_containment_config() -> Dictionary:
	return {
		"actions": {
			"vent": {"description": "Release elemental for combat, gain dropped card", "cost_overclock": 0},
			"overclock": {"description": "Empower elemental (+2 CHARGE, better loot, harder fight)", "cost_overclock": 3},
			"patch": {"description": "Seal containment, skip fight, gain minor loot", "cost_gems": 5}
		},
		"vessel_count_per_room": {
			"loading_bay": 1,
			"lower_works": 2,
			"containment_hall": 3,
			"the_leak": 0,  # Vent-only, already ruptured
			"middle_works": 2,
			"the_crack": 1,
			"upper_works": 2,
			"padlock_door": 1
		}
	}

# -------------------------------------------------------------------
# Goblin Morale Configuration
# -------------------------------------------------------------------

func get_goblin_morale_config() -> Dictionary:
	return {
		"group_threshold": 3,
		"group_damage_bonus": 2,
		"group_cannot_flee": true,
		"pair_cower_chance": 0.50,
		"leader_death_panic_chance": 0.50,
		"overlock_terrified_threshold": 15,
		"overlock_fight_to_death": true
	}

# -------------------------------------------------------------------
# Boss Configuration (Chief Engineer Blix)
# -------------------------------------------------------------------

func get_boss_config() -> Dictionary:
	return {
		"name": "Chief Engineer Blix",
		"hp": 55,
		"phase_transition_hp_1": 35,  # Phase 1 -> 2
		"phase_transition_hp_2": 15,  # Phase 2 -> 3
		"phase_1_name": "The Shift",
		"phase_2_name": "The Meltdown",
		"phase_3_name": "The Scram",
		"scram_damage_to_player": 15,
		"scram_instant_death": true,  # Boss dies if scram pulled
		"meltdown_timer_turns": 10,  # 10-turn DPS race if no scram
		"overclock_surrender_threshold": 20,  # Blix surrenders if player OC > 20
		"core_reward": "elemental_core"  # Permanent +1 fire damage all cards
	}

# -------------------------------------------------------------------
# Padlock Door Configuration
# -------------------------------------------------------------------

func get_padlock_config() -> Dictionary:
	return {
		"padlock_count": 17,
		"keys_from_rooms": [
			"loading_bay", "lower_works", "break_room", "containment_hall",
			"the_leak", "middle_works", "union_hall", "the_crack",
			"upper_works"
		],
		"pick_cost_overclock": 5,
		"pick_alarm_chance": 0.3,
		"cache_loot": ["overclocked_card", "brass_gear", "elemental_shard"]
	}

# -------------------------------------------------------------------
# Cross-Floor Bleed Checks
# -------------------------------------------------------------------

func get_cross_floor_effects() -> Dictionary:
	return {
		"from_floor7": {
			"honored_all_pacts": {
				"effect": "demon_marked",
				"blix_dialogue": "Ooh, contracts! I got a contract too!",
				"bonus": "blix_shows_union_contract"
			},
			"broke_pacts": {
				"effect": "pactless",
				"blix_dialogue": "Demons are boring. They don't explode. I like exploding.",
				"bonus": "blix_indifferent"
			},
			"void_bond_active": {
				"effect": "shaman_fascination",
				"bonus": "free_mutation_removal",
				"condition": "talk_to_shaman_before_combat"
			},
			"soul_debt": {
				"effect": "angry_elementals",
				"bonus": "elemental_charge_plus_1_all_floor"
			}
		},
		"to_floor9": {
			"scrammed_reactor": {
				"effect": "no_power",
				"bonus": "floor9_constructs_slower",
				"penalty": "foreman_enraged",
				"boss_start_hp": 0.8
			},
			"no_scram_survived": {
				"effect": "radiation_debuff",
				"bonus": "elementals_kin",
				"penalty": "minus_2_hp_per_room"
			},
			"overclock_20_blix_surrender": {
				"effect": "elemental_core_held",
				"bonus": "floor9_can_overclock_furnaces"
			},
			"vented_all_vessels": {
				"effect": "elementals_loose",
				"penalty": "floor9_plus_2_elite_encounters"
			}
		}
	}
