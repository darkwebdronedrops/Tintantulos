class_name Floor10Template
extends FloorTemplate

# ===================================================================
# FLOOR 10 TEMPLATE — The Dragon's Lair
# Refactored to use FloorController base class + Floor10Template
# ===================================================================
# 11 Moments in a single vast chamber — linear progression with branches
# The Approach → The Hoard → The Trial → The Revelation → The Throne
# ===================================================================

func _init():
	floor_id = 10
	floor_name = "The Dragon's Lair"
	starting_room_id = "moment_01_threshold"
	hex_step_size = 60.0
	interact_range = 80.0

	# 11 Moments — linear progression with Hoard branches
	rooms = {
		# === THE APPROACH (Moments 1-3) — Ghosts of defeated bosses ===
		"moment_01_threshold": {
			"scene_path": "res://scenes/rooms/Floor10_Threshold.tscn",
			"position": Vector2(0, 0),
			"connections": {"east": "moment_02_witness"},
			"moment_type": "ghost",
			"ghost_floor": 1,
			"ghost_boss": "The Door"
		},
		"moment_02_witness": {
			"scene_path": "res://scenes/rooms/Floor10_Witness.tscn",
			"position": Vector2(300, 0),
			"connections": {"west": "moment_01_threshold", "east": "moment_03_memory"},
			"moment_type": "ghost",
			"ghost_floor": 2,
			"ghost_boss": "Spore Heart"
		},
		"moment_03_memory": {
			"scene_path": "res://scenes/rooms/Floor10_Memory.tscn",
			"position": Vector2(600, 0),
			"connections": {"west": "moment_02_witness", "east": "moment_04_hoard"},
			"moment_type": "ghost",
			"ghost_floor": 3,
			"ghost_boss": "Gear Mother"
		},

		# === THE HOARD (Moments 4-6) — Interactive objects ===
		"moment_04_hoard": {
			"scene_path": "res://scenes/rooms/Floor10_Hoard.tscn",
			"position": Vector2(900, 0),
			"connections": {
				"west": "moment_03_memory",
				"north": "moment_05_weight",
				"east": "moment_06_first_aspect"
			},
			"moment_type": "hoard",
			"hoard_objects": ["blood_contract", "soul_gem", "reforged_blade", "graduate_scroll"]
		},
		"moment_05_weight": {
			"scene_path": "res://scenes/rooms/Floor10_Weight.tscn",
			"position": Vector2(900, -300),
			"connections": {"south": "moment_04_hoard"},
			"moment_type": "score",
			"reveals_weight": true
		},

		# === THE TRIAL (Moments 6-8) — Dragon Aspects ===
		"moment_06_first_aspect": {
			"scene_path": "res://scenes/rooms/Floor10_AspectTime.tscn",
			"position": Vector2(1200, 0),
			"connections": {"west": "moment_04_hoard", "east": "moment_07_second_aspect"},
			"moment_type": "combat",
			"aspect": "time"
		},
		"moment_07_second_aspect": {
			"scene_path": "res://scenes/rooms/Floor10_AspectGreed.tscn",
			"position": Vector2(1500, 0),
			"connections": {"west": "moment_06_first_aspect", "east": "moment_08_third_aspect"},
			"moment_type": "combat",
			"aspect": "greed"
		},
		"moment_08_third_aspect": {
			"scene_path": "res://scenes/rooms/Floor10_AspectTransformation.tscn",
			"position": Vector2(1800, 0),
			"connections": {"west": "moment_07_second_aspect", "east": "moment_09_approach"},
			"moment_type": "combat",
			"aspect": "transformation"
		},

		# === THE REVELATION (Moment 9-10) — Dragon boss ===
		"moment_09_approach": {
			"scene_path": "res://scenes/rooms/Floor10_Approach.tscn",
			"position": Vector2(2100, 0),
			"connections": {"west": "moment_08_third_aspect", "east": "moment_10_revelation"},
			"moment_type": "walk",
			"dragon_visible": true
		},
		"moment_10_revelation": {
			"scene_path": "res://scenes/rooms/Floor10_Revelation.tscn",
			"position": Vector2(2400, 0),
			"connections": {"west": "moment_09_approach", "east": "moment_11_throne"},
			"moment_type": "boss_phase_1_2"
		},

		# === THE THRONE (Moment 11) — Final Choice ===
		"moment_11_throne": {
			"scene_path": "res://scenes/rooms/Floor10_Throne.tscn",
			"position": Vector2(2700, 0),
			"connections": {"west": "moment_10_revelation"},
			"moment_type": "final_choice"
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# Hoard objects
		"BloodContract": return "Touch Blood Contract"
		"SoulGem": return "Touch Soul Gem"
		"ReforgedBlade": return "Touch Reforged Blade"
		"GraduateScroll": return "Touch Graduate Scroll"

		# Hoard actions
		"BurnContract": return "Burn Contract"
		"ShatterGem": return "Shatter Gem"
		"MeltBlade": return "Melt Blade"
		"RewriteScroll": return "Rewrite Scroll"

		# Dragon
		"TheDragon": return "Face the Dragon"
		"AttackDragon": return "Attack"
		"ListenDragon": return "Listen"

		# Throne choices
		"DestroyDragon": return "Destroy the Dragon"
		"BecomeDragon": return "Become the Dragon"
		"WalkAway": return "Walk Away"
		"HiddenDoor": return "Enter Hidden Door"

		# Cano Protocol
		"TheCompiler": return "Face the Compiler"
		"ConfirmEnd": return "YES — End Process"
		"DenyEnd": return "NO — Continue"

		# Cross-floor NPCs
		"ShortcutMaker": return "Talk to Shortcut Maker"
		"GoblinJanitor": return "Talk to Janitor"

		# Save
		"SavePoint": return "Save Game"

		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalEast", "PortalWest",
		"ReturnPortal", "ThronePortal"
	]

# -------------------------------------------------------------------
# Hoard Objects Configuration
# -------------------------------------------------------------------

func get_hoard_config() -> Dictionary:
	return {
		"blood_contract": {
			"name": "Blood Contract",
			"floor": 7,
			"choice": "signed_or_refused",
			"can_alter": true,
			"alter_action": "burn",
			"alter_cost": "10_damage",
			"alter_effect": "remove_pact"
		},
		"soul_gem": {
			"name": "Soul Gem",
			"floor": 9,
			"choice": "freed_or_enslaved",
			"can_alter": true,
			"alter_action": "shatter",
			"alter_cost": "dragon_plus_5_hp",
			"alter_effect": "free_enslaved_soul"
		},
		"reforged_blade": {
			"name": "Reforged Blade",
			"floor": 8,
			"choice": "accepted_or_refused",
			"can_alter": true,
			"alter_action": "melt",
			"alter_cost": "lose_buff",
			"alter_effect": "keep_cards"
		},
		"graduate_scroll": {
			"name": "Graduate Scroll",
			"floor": 6,
			"choice": "grade_achieved",
			"can_alter": true,
			"alter_action": "rewrite",
			"alter_cost": "affects_floor7",
			"alter_effect": "change_grade"
		}
	}

# -------------------------------------------------------------------
# Dragon Aspect Configuration
# -------------------------------------------------------------------

func get_aspect_config() -> Dictionary:
	return {
		"time": {
			"name": "Aspect of Time",
			"hp": 40,
			"mechanic": "replays_player_cards",
			"weakness": "neglected_deck",
			"bonus_damage_if_never_used": 5,
			"test": "diversification"
		},
		"greed": {
			"name": "Aspect of Greed",
			"hp": 45,
			"mechanic": "steals_resources",
			"weakness": "spend_everything",
			"shrink_trigger": "zero_gems_empty_hand",
			"test": "letting_go"
		},
		"transformation": {
			"name": "Aspect of Transformation",
			"hp": 40,
			"mechanic": "shifts_resistances",
			"weakness": "pure_cards",
			"pure_bypass": true,
			"test": "adaptation"
		}
	}

# -------------------------------------------------------------------
# Dragon Boss Configuration
# -------------------------------------------------------------------

func get_dragon_config() -> Dictionary:
	return {
		"name": "The Dragon",
		"hp_heavy_choices": 35,  # Player corrupted = dragon weaker (recognizes kin)
		"hp_light_choices": 70,   # Player pure = dragon stronger (threat to cycle)
		"phase_1": {
			"name": "The Revelation",
			"attacks": false,
			"speaks": true,
			"critical_mechanic": "attack_in_phase_1_reveals_crack",
			"crack_visible_if": "no_major_demon_deals"
		},
		"phase_2": {
			"name": "The Test",
			"if_attacked_in_phase_1": "combat_form_stronger",
			"if_waited": "dialogue_choices_reveal_weakness"
		},
		"phase_3": {
			"name": "The Climax",
			"hp_threshold": 0.25,  # 25% HP
			"offers_final_choice": true
		}
	}

# -------------------------------------------------------------------
# Final Choice Configuration (False Endings)
# -------------------------------------------------------------------

func get_ending_config() -> Dictionary:
	return {
		"destroy_dragon": {
			"name": "End the Cycle",
			"description": "Dragon dies. Tower collapses. New tower appears on horizon.",
			"unlock_ng_plus": true,
			"ng_plus_keeps": "knowledge_only",
			"false_ending": true,
			"locks_true_ending": false,
			"save_suffix": "ENDED_THE_CYCLE"
		},
		"become_dragon": {
			"name": "Become the Dragon",
			"description": "Player ascends throne. Becomes new source of power.",
			"unlock_ng_plus": true,
			"ng_plus_previous_deck_becomes_dragon": true,
			"false_ending": true,
			"locks_true_ending_permanently": true,
			"save_suffix": "BECAME_THE_TOWER"
		},
		"walk_away": {
			"name": "Walk Away",
			"description": "Only if Liberator + no pacts + no reforging. Leave through hidden door.",
			"unlock_exile_mode": true,
			"false_ending": true,
			"locks_true_ending": false,
			"save_suffix": "WALKED_AWAY"
		},
		"true_ending": {
			"name": "The Cano Protocol Defeated",
			"description": "No cutscene. No credits. Just silence. Then: 'The tower was never a place. It was a question. You answered.'",
			"requires": {
				"attacked_in_phase_1": true,
				"no_major_demon_deals": true,
				"found_hidden_door": true,
				"cano_protocol_defeated": true
			},
			"save_suffix": "STOPPED",
			"ending_message": "The tower was never a place. It was a question. You answered."
		}
	}

# -------------------------------------------------------------------
# Cano Protocol Configuration (True Final Boss)
# -------------------------------------------------------------------

func get_cano_config() -> Dictionary:
	return {
		"name": "The Cano Protocol",
		"trigger": {
			"dragon_deck_size": 50,
			"run_count_minimum": 2
		},
		"hp": 50,  # One per archived card
		"passive": {
			"name": "DEBUG",
			"effect": "normal_cards_cost_double",
			"void_exempt": true,
			"zero_cost_unchanged": true
		},
		"abilities_cycle": [
			{
				"name": "MEMORY_LEAK",
				"effect": "quiddity_to_damage",
				"ratio": "2_quiddity_1_damage",
				"zero_penalty": 5
			},
			{
				"name": "STACK_OVERFLOW",
				"effect": "spawn_process_interrupt",
				"hp_formula": "card_cost_x3",
				"uses_most_played_card": true
			},
			{
				"name": "GARBAGE_COLLECTION",
				"effect": "remove_highest_cost_card",
				"target": "hand_or_deck",
				"permanent_for_combat": true
			}
		],
		"damage_mechanic": {
			"normal_cards": 0,
			"void_cards": 1,
			"void_hits_remove_archive": true,
			"total_void_hits_needed": 50
		},
		"phase_3": {
			"name": "Permission Denied",
			"prompt": "CONFIRM: END PROCESS? THIS WILL END ALL FLOORS, ALL CHOICES, ALL MEMORIES, ALL RUNS. YES / NO",
			"yes_result": "protocol_dissolves_true_ending",
			"no_result": "reinitialize_continue"
		}
	}

# -------------------------------------------------------------------
# Weight Calculation (Dragon scaling)
# -------------------------------------------------------------------

func get_weight_categories() -> Dictionary:
	return {
		"heavy": {
			"pacts_signed": {"threshold": 2, "weight": 3},
			"souls_enslaved": {"threshold": 3, "weight": 4},
			"soul_debt": {"threshold": 3, "weight": 3},
			"companions_built": {"threshold": 5, "weight": 1},
			"void_bond_active": {"weight": 2},
			"marked_debuff": {"weight": 2}
		},
		"light": {
			"liberator_status": {"weight": -5},
			"all_pacts_refused": {"weight": -3},
			"all_furnaces_destroyed": {"weight": -2},
			"no_soul_debt": {"weight": -2},
			"graduate_status": {"weight": -1}
		}
	}

# -------------------------------------------------------------------
# Cross-Floor Bleed (Final Payoffs from ALL floors)
# -------------------------------------------------------------------

func get_cross_floor_effects() -> Dictionary:
	return {
		"from_floor9": {
			"liberator_status": {
				"effect": "door_visible_moment04",
				"option_c_available": true,
				"dragon_dialogue": "You freed them all. Every soul. Every prisoner."
			},
			"soul_debt_gt_3": {
				"effect": "dragon_disgust",
				"aspect_greed_empowered": true,
				"dragon_dialogue": "You used them. You are the Foreman's heir."
			},
			"companions_built_5": {
				"effect": "dragon_respect",
				"skip_to_phase_3": true,
				"dragon_dialogue": "You build. I destroy. We are not so different."
			},
			"all_furnaces_destroyed": {
				"effect": "freed_souls_whisper",
				"bonus": "whisper_attack_patterns"
			}
		},
		"from_floor8": {
			"reforging_accepted": {
				"effect": "part_of_tower_design",
				"option_b_preselected": true,
				"dragon_dialogue": "You are already part of the tower's design."
			},
			"reforging_refused": {
				"effect": "transformation_weaker",
				"dragon_dialogue": "You held yourself together. That is rare."
			},
			"high_fire_attunement": {
				"effect": "fire_kin",
				"dragon_fire_heals": true
			}
		},
		"from_floor7": {
			"signed_final_pact": {
				"effect": "dragon_knows_name",
				"all_aspects_plus_3_damage": true,
				"dragon_dialogue": "You are already mine. This is a formality."
			},
			"broke_all_pacts": {
				"effect": "unbound",
				"aspects_minus_2_hp": true,
				"dragon_dialogue": "You cannot be bound. That makes you dangerous."
			},
			"void_bond_active": {
				"effect": "cousins_mark",
				"can_remove_mutation_free": true,
				"dragon_dialogue": "You carry my cousin's mark."
			}
		},
		"from_floor6": {
			"graduate_status": {
				"dragon_dialogue": "Educated. But education is just another cage with prettier bars."
			},
			"dropout_status": {
				"dragon_dialogue": "You could not finish. Neither could I. We are alike."
			},
			"deans_key": {
				"dragon_dialogue": "That opens nothing. The Dean lied to you."
			}
		},
		"from_floor5": {
			"defeated_elemental_core": {
				"dragon_dialogue": "You killed the storm. I am what remains when storms die."
			},
			"befriended_goblin_janitor": {
				"effect": "janitor_in_moment04",
				"bonus": "reveals_true_hp"
			}
		},
		"from_floor4": {
			"sold_memories": {
				"effect": "empty_past",
				"dragon_dialogue": "You are empty. That is... new."
			},
			"bought_infinity_mirror": {
				"effect": "mirror_reflection",
				"dragon_attacks_50_percent_miss": true
			}
		},
		"from_floor3": {
			"optimal_boss_kill": {
				"dragon_dialogue": "Perfectionist. The tower was built by perfectionists. Look at us now."
			},
			"suboptimal_boss_kill": {
				"dragon_dialogue": "You rushed. You survived. That is the only grade that matters."
			}
		},
		"from_floor2": {
			"killed_flesh_garden": {
				"dragon_dialogue": "You ended growth. I am what grows back."
			},
			"left_spore_clouds": {
				"effect": "spore_damage_applies",
				"dragon_dialogue": "You walked through poison. Your lungs remember."
			}
		},
		"from_floor1": {
			"befriended_shortcut_maker": {
				"effect": "shortcut_in_moment09",
				"can_skip_to_choice": true,
				"dragon_full_power": true,
				"dragon_dialogue": "Last chance to take the back door. I keep my promises."
			}
		}
	}
