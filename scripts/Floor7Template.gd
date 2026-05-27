class_name Floor7Template
extends FloorTemplate

# ===================================================================
# FLOOR 7 TEMPLATE — The Broken Pact
# Refactored to use FloorController base class + Floor7Template
# ===================================================================
# Spiral bureaucracy on hex grid: 11 rooms in concentric rings
# Outer → Middle → Inner → Center (Auditorium)
# ===================================================================

func _init():
	floor_id = 7
	floor_name = "The Broken Pact"
	starting_room_id = "office"
	hex_step_size = 60.0
	interact_range = 80.0
	
	# Spiral layout — outer ring far from center, inner ring close
	# Creates visual "ascending rings" effect while keeping hex connectivity
	rooms = {
		# === OUTER RING (Offices) ===
		"office": {
			"scene_path": "res://scenes/rooms/Floor7_Office.tscn",
			"position": Vector2(-900, -600),
			"connections": {
				"east": "court",
				"southeast": "break_room",
				"exit": "floor6_exit"
			}
		},
		"court": {
			"scene_path": "res://scenes/rooms/Floor7_Court.tscn",
			"position": Vector2(0, -900),
			"connections": {
				"west": "office",
				"south": "break_room",
				"southeast": "corridor"
			}
		},
		"break_room": {
			"scene_path": "res://scenes/rooms/Floor7_BreakRoom.tscn",
			"position": Vector2(600, -600),
			"connections": {
				"northwest": "court",
				"west": "office",
				"south": "filing"
			}
		},
		"filing": {
			"scene_path": "res://scenes/rooms/Floor7_Filing.tscn",
			"position": Vector2(900, 0),
			"connections": {
				"north": "break_room",
				"southwest": "corridor",
				"west": "court_ii"
			}
		},
		
		# === MIDDLE RING (Courts + Corridor) ===
		"corridor": {
			"scene_path": "res://scenes/rooms/Floor7_Corridor.tscn",
			"position": Vector2(600, 600),
			"connections": {
				"northeast": "filing",
				"northwest": "court",
				"west": "laboratory",
				"south": "storage"
			}
		},
		"laboratory": {
			"scene_path": "res://scenes/rooms/Floor7_Laboratory.tscn",
			"position": Vector2(0, 900),
			"connections": {
				"east": "corridor",
				"south": "void_lab",
				"southwest": "storage"
			}
		},
		"storage": {
			"scene_path": "res://scenes/rooms/Floor7_Storage.tscn",
			"position": Vector2(-600, 600),
			"connections": {
				"northeast": "laboratory",
				"north": "corridor",
				"west": "court_ii"
			}
		},
		"court_ii": {
			"scene_path": "res://scenes/rooms/Floor7_CourtII.tscn",
			"position": Vector2(-900, 0),
			"connections": {
				"east": "storage",
				"southeast": "laboratory",
				"south": "void_lab"
			}
		},
		
		# === INNER RING (Laboratory + Antechamber) ===
		"void_lab": {
			"scene_path": "res://scenes/rooms/Floor7_VoidLab.tscn",
			"position": Vector2(-300, 300),
			"connections": {
				"north": "laboratory",
				"northeast": "court_ii",
				"east": "antechamber"
			}
		},
		"antechamber": {
			"scene_path": "res://scenes/rooms/Floor7_Antechamber.tscn",
			"position": Vector2(300, 300),
			"connections": {
				"west": "void_lab",
				"south": "auditorium"
			}
		},
		
		# === CENTER (Boss) ===
		"auditorium": {
			"scene_path": "res://scenes/rooms/Floor7_Auditorium.tscn",
			"position": Vector2(0, 0),
			"connections": {
				"north": "antechamber",
				"exit": "floor8_entrance"
			}
		}
	}

# -------------------------------------------------------------------
# Floor-Specific Interactables
# -------------------------------------------------------------------

func get_interactable_label(node_name: String) -> String:
	match node_name:
		# Contract stations (pact desks)
		"ContractStation": return "Sign Contract"
		"BloodDesk": return "Blood Contract"
		"SoulDesk": return "Soul Mortgage"
		"VoidDesk": return "Void Bond"
		"SilenceDesk": return "Silence Clause"
		
		# Void cracks
		"VoidCrack": return "Approach Crack"
		"VoidStabilizer": return "Stabilize Void"
		
		# Docket / court
		"DocketReader": return "Read Docket"
		"WitnessStand": return "Approach Witness"
		"PleadingStand": return "Plead Case"
		
		# Boss
		"DeniedThrone": return "Confront the Denied"
		"FinalContract": return "Sign Final Pact"
		"BreakPacts": return "Break All Pacts"
		
		# Puzzle
		"LoopholeText": return "Review Contract"
		"PressurePlate": return "Stand on Plate"
		
		# NPCs
		"SoulClerk": return "Talk to Clerk"
		"ContractLawyer": return "Talk to Lawyer"
		"GoblinForger": return "Talk to Forger"
		
		# Save point
		"SavePoint": return "Save Game"
		
		_: return ""

func is_portal_node(node_name: String) -> bool:
	return node_name in [
		"PortalEast", "PortalWest", "PortalNorth", "PortalSouth",
		"PortalNortheast", "PortalNorthwest", "PortalSoutheast", "PortalSouthwest",
		"ReturnPortal", "BossPortal"
	]

# -------------------------------------------------------------------
# Pact Configuration
# -------------------------------------------------------------------

func get_pact_config() -> Dictionary:
	return {
		"blood_contract": {
			"name": "Blood Contract",
			"immediate": "+3 damage all cards this floor",
			"permanent": "-5 max HP",
			"cost_gems": 0,
			"can_stack": false
		},
		"soul_mortgage": {
			"name": "Soul Mortgage",
			"immediate": "Draw +1 card per turn this floor",
			"permanent": "Remove 1 random card from deck permanently",
			"cost_gems": 0,
			"can_stack": false
		},
		"void_bond": {
			"name": "Void Bond",
			"immediate": "Gain 1 random epic card",
			"permanent": "Card transforms unpredictably each combat",
			"cost_gems": 0,
			"can_stack": false
		},
		"silence_clause": {
			"name": "Silence Clause",
			"immediate": "Enemy skips next turn",
			"permanent": "Cannot speak to NPCs for rest of floor",
			"cost_gems": 0,
			"can_stack": false
		}
	}

# -------------------------------------------------------------------
# Void Crack Configuration
# -------------------------------------------------------------------

func get_void_crack_config() -> Dictionary:
	return {
		"transform_chance": 0.3,  # 30% chance to transform enemy/card when near
		"enemy_mutations": [
			"Void-Touched",
			"Fractured",
			"Redacted"
		],
		"stabilizer_count": 3,  # Need 3 stabilizers to seal all cracks
		"damage_on_fail": 5
	}

# -------------------------------------------------------------------
# Boss Configuration (The Denied)
# -------------------------------------------------------------------

func get_boss_config() -> Dictionary:
	return {
		"name": "The Denied",
		"hp": 60,
		"phase_transition_hp": 30,
		"docket_witness_damage": 3,  # Per witness summoned
		"plead_cost_gems": 5,  # To dismiss one witness
		"final_pact_instant_death": true,  # Boss dies if player signs
		"refuse_hp_bonus": 0.5,  # +50% HP if refused
		"phase_2_name": "Aberration Form",
		"phase_3_name": "The Verdict"
	}

# -------------------------------------------------------------------
# Docket Sin Categories
# -------------------------------------------------------------------

func get_docket_categories() -> Dictionary:
	return {
		"pacts_signed": {"weight": 2, "label": "Pact Breaker"},
		"souls_enslaved": {"weight": 3, "label": "Soul Debtor"},
		"bosses_killed": {"weight": 1, "label": "Slayer"},
		"courses_failed": {"weight": 2, "label": "Academic Fraud"},
		"clocktower_sabotaged": {"weight": 2, "label": "System Breaker"},
		"pacts_broken": {"weight": 4, "label": "Oath Breaker"},
		"companions_built": {"weight": 1, "label": "Necromancer"},
		"souls_freed": {"weight": -1, "label": "Liberator"}  # Negative = reduces sin
	}

# -------------------------------------------------------------------
# Cross-Floor Bleed Checks
# -------------------------------------------------------------------

func get_cross_floor_effects() -> Dictionary:
	return {
		"from_floor6": {
			"graduate_status": {
				"effect": "alumni_discount",
				"discount": 0.25
			},
			"failed_courses": {
				"effect": "pact_cost_increase",
				"penalty": 0.50
			},
			"audit_status": {
				"effect": "demon_suspicion",
				"penalty": "harder_negotiation"
			},
			"goblin_janitor_befriended": {
				"effect": "signature_forger",
				"bonus": "one_free_pact"
			}
		},
		"to_floor8": {
			"honored_all_pacts": {
				"effect": "demon_marked",
				"bonus": "blix_recognizes_contracts"
			},
			"broke_pacts": {
				"effect": "pactless",
				"bonus": "blix_indifferent"
			},
			"signed_final_pact": {
				"effect": "charged_vessels",
				"bonus": "floor8_charge_plus_1"
			},
			"void_bond_active": {
				"effect": "shaman_cleansing",
				"bonus": "free_mutation_removal"
			}
		}
	}
