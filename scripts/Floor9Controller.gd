extends FloorController

# ===================================================================
# FLOOR 9 CONTROLLER — The Bone Forges
# Refactored to use FloorController base class + Floor9Template
# ===================================================================
# Adds: Salvage & Crafting, Soul Furnaces, Liberator/Soul Debt,
#       Conveyor belts, Foreman Eternal boss, Cross-floor from Floor 8
# ===================================================================

@onready var floor9_template: Floor9Template = Floor9Template.new()

# Salvage & Crafting State
var bone_count: int = 0
var gear_count: int = 0
var companions_built: Array[Dictionary] = []
var companions_built_total: int = 0
var max_companions: int = 3

# Soul Furnace State
var souls_freed: int = 0
var soul_debt: int = 0
var liberator_status: bool = false
var furnaces_destroyed: int = 0
var furnaces_used: int = 0
var all_furnaces_destroyed: bool = false

# Conveyor Belt State
var conveyor_direction: String = "east"
var on_conveyor: bool = false
var conveyor_speed: float = 2.0
var conveyor_maze_solved: bool = false

# Boss State (The Foreman Eternal)
var foreman_phase: int = 1
var foreman_hp: int = 65
var foreman_max_hp: int = 65
var foreman_enraged: bool = false
var foreman_start_hp_percent: float = 1.0
var inspection_turn_counter: int = 0
var skull_case_destroyed: bool = false
var skull_case_hp: int = 15
var strike_team_built: bool = false

# Cross-Floor Bleed from Floor 8
var no_power: bool = false
var radiation_active: bool = false
var elemental_core_held: bool = false
var elementals_loose: bool = false
var goblin_refugees: bool = false
var radiation_hp_loss: int = 0

# UI References
var salvage_ui: Label
var furnace_ui: Label
var conveyor_ui: Label
var foreman_ui: Label
var liberator_ui: Label

func _ready():
	floor_template = floor9_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Check cross-floor bleed from Floor 8
	if GameState.get_value("floor9_no_power", false):
		no_power = true
		foreman_start_hp_percent = 0.8
		foreman_enraged = true
		_show_notification("⚠ No power from Floor 8! Constructs slower, Foreman enraged!", Color(0.9, 0.3, 0.3))

	if GameState.get_value("floor9_radiation_debuff", false):
		radiation_active = true
		_show_notification("☢ Radiation debuff active! -2 HP per room", Color(0.9, 0.5, 0.2))

	if GameState.get_value("elemental_core_held", false):
		elemental_core_held = true
		_show_notification("🔥 Elemental Core active! Can overclock furnaces!", Color(0.9, 0.4, 0.2))

	if GameState.get_value("floor9_elementals_loose", false):
		elementals_loose = true
		_show_notification("💨 Elementals loose! +2 elite encounters!", Color(0.9, 0.7, 0.3))

	if GameState.get_value("floor8_chief_handler_killed", false):
		goblin_refugees = true
		_show_notification("🤪 Goblin refugees causing chaos!", Color(0.9, 0.7, 0.3))

	# Set foreman HP based on cross-floor bleed
	foreman_max_hp = int(65 * foreman_start_hp_percent)
	foreman_hp = foreman_max_hp

	# Initialize conveyor directions
	_update_conveyor_direction()

	print("[Floor9] Setup complete. Bone: %d | Gear: %d | Liberator: %s | Enraged: %s" % [
		bone_count, gear_count, liberator_status, foreman_enraged
	])

func _setup_floor_ui():
	# Salvage display
	salvage_ui = Label.new()
	salvage_ui.name = "SalvageUI"
	salvage_ui.position = Vector2(20, 20)
	salvage_ui.size = Vector2(400, 100)
	salvage_ui.add_theme_font_size_override("font_size", 12)
	add_child(salvage_ui)
	_update_salvage_display()

	# Furnace / soul debt display
	furnace_ui = Label.new()
	furnace_ui.name = "FurnaceUI"
	furnace_ui.position = Vector2(20, 130)
	furnace_ui.size = Vector2(350, 80)
	furnace_ui.add_theme_font_size_override("font_size", 11)
	add_child(furnace_ui)
	_update_furnace_display()

	# Conveyor display
	conveyor_ui = Label.new()
	conveyor_ui.name = "ConveyorUI"
	conveyor_ui.position = Vector2(20, 220)
	conveyor_ui.size = Vector2(300, 40)
	conveyor_ui.add_theme_font_size_override("font_size", 11)
	add_child(conveyor_ui)
	_update_conveyor_display()

	# Liberator status display
	liberator_ui = Label.new()
	liberator_ui.name = "LiberatorUI"
	liberator_ui.position = Vector2(20, 270)
	liberator_ui.size = Vector2(300, 40)
	liberator_ui.add_theme_font_size_override("font_size", 12)
	add_child(liberator_ui)
	_update_liberator_display()

	# Foreman boss display
	foreman_ui = Label.new()
	foreman_ui.name = "ForemanUI"
	foreman_ui.position = Vector2(20, 320)
	foreman_ui.size = Vector2(400, 40)
	foreman_ui.add_theme_font_size_override("font_size", 12)
	foreman_ui.visible = false
	add_child(foreman_ui)

func _update_floor_ui():
	_update_salvage_display()
	_update_furnace_display()
	_update_conveyor_display()
	_update_liberator_display()
	if foreman_phase > 0:
		_update_foreman_display()

# -------------------------------------------------------------------
# Salvage & Crafting System
# -------------------------------------------------------------------

func _add_salvage(material: String, amount: int):
	"""Add crafting materials from defeated enemies."""
	var config = floor9_template.get_crafting_config()
	var mats = config.get("materials", {})
	var max_amount = mats.get(material, {}).get("max", 20)

	match material:
		"bone":
			bone_count = mini(bone_count + amount, max_amount)
			_show_notification("🦴 +%d Bone! (Total: %d)" % [amount, bone_count], Color(0.8, 0.8, 0.7))
		"gear":
			gear_count = mini(gear_count + amount, max_amount)
			_show_notification("⚙ +%d Gear! (Total: %d)" % [amount, gear_count], Color(0.6, 0.6, 0.7))

	_update_salvage_display()
	print("[Floor9] Salvage: %d Bone, %d Gear" % [bone_count, gear_count])

func _build_companion(companion_type: String):
	"""Build a companion card at an Assembly Station."""
	var config = floor9_template.get_crafting_config()
	var recipes = config.get("recipes", {})
	var companions = recipes.get("companion", {})
	var recipe = companions.get(companion_type)

	if not recipe:
		_show_notification("Unknown companion type", Color(0.9, 0.3, 0.3))
		return

	var req_bone = recipe.get("bone", 2)
	var req_gear = recipe.get("gear", 1)

	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return

	if companions_built.size() >= max_companions:
		_show_notification("Max %d companions!" % max_companions, Color(0.9, 0.3, 0.3))
		return

	# Deduct materials
	bone_count -= req_bone
	gear_count -= req_gear

	# Create companion
	var companion = {
		"type": companion_type,
		"name": _companion_type_to_name(companion_type),
		"effect": recipe.get("effect", ""),
		"temporary": true,
		"combat_used": false
	}
	companions_built.append(companion)
	companions_built_total += 1

	_show_notification("🤖 Built: %s!" % companion["name"], Color(0.3, 0.9, 0.3))
	_update_salvage_display()
	print("[Floor9] Companion built: %s" % companion_type)

func _companion_type_to_name(companion_type: String) -> String:
	match companion_type:
		"bone_drone": return "Bone Drone"
		"gear_skeleton": return "Gear Skeleton"
		"soul_engine": return "Soul Engine"
		"stitch_walker": return "Stitch-Walker"
		_: return "Companion"

func _repair_self():
	"""Spend materials to heal and gain block."""
	var config = floor9_template.get_crafting_config()
	var repair = config.get("recipes", {}).get("repair", {})
	var req_bone = repair.get("bone", 1)
	var req_gear = repair.get("gear", 2)
	var heal = repair.get("heal", 10)
	var block = repair.get("block", 5)

	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear to repair" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return

	bone_count -= req_bone
	gear_count -= req_gear

	# Apply heal and block
	if GameState.has_method("heal_player"):
		GameState.heal_player(heal)
	if GameState.has_method("add_player_shield"):
		GameState.add_player_shield(block)
	_show_notification("🔧 Repaired! +%d HP, +%d Block" % [heal, block], Color(0.3, 0.9, 0.3))
	_update_salvage_display()

func _salvage_defeated_enemy(enemy_name: String):
	"""Salvage parts from a defeated enemy."""
	if "undead" in enemy_name.to_lower() or "skeleton" in enemy_name.to_lower() or "bone" in enemy_name.to_lower():
		_add_salvage("bone", 1)
	elif "construct" in enemy_name.to_lower() or "machinist" in enemy_name.to_lower() or "golem" in enemy_name.to_lower():
		_add_salvage("gear", 1)

func _update_salvage_display():
	if not salvage_ui:
		return

	var text = "🦴 Bone: %d | ⚙ Gear: %d\n" % [bone_count, gear_count]
	text += "🤖 Companions: %d/%d" % [companions_built.size(), max_companions]

	if companions_built_total >= 5:
		text += " [BUILDER]"

	salvage_ui.text = text
	salvage_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))

# -------------------------------------------------------------------
# Soul Furnace System
# -------------------------------------------------------------------

func _interact_with_furnace(action: String):
	"""Player chooses an action on a soul furnace."""
	var config = floor9_template.get_furnace_config()
	var actions = config.get("actions", {})

	match action:
		"free_souls":
			_free_souls_from_furnace()
		"burn_souls":
			_burn_souls_in_furnace()
		"drain_soul_piston":
			_drain_soul_piston()

func _free_souls_from_furnace():
	"""Destroy furnace to free souls."""
	var config = floor9_template.get_furnace_config()
	var actions = config.get("actions", {})
	var free_config = actions.get("free_souls", {})
	var alarm_chance = free_config.get("alarm_chance", 0.7)

	souls_freed += 1
	furnaces_destroyed += 1

	_show_notification("✨ Souls freed! Total: %d" % souls_freed, Color(0.3, 0.9, 0.3))

	# Alarm chance
	if randf() < alarm_chance:
		_show_notification("🚨 Alarm! Enemies incoming!", Color(0.9, 0.3, 0.3))
		# Start enemy encounter for this room
		var comp = RoomEnemyDatabase.get_floor9_composition(current_room_id)
		if not comp.get("is_peaceful", false):
			var enemy_names: Array[String] = []
			for template in comp.get("enemies", []):
				if template.has_method("to_combat_data"):
					enemy_names.append(template.name)
			if enemy_names.size() > 0:
				_start_combat_with_enemies(enemy_names, comp.get("is_boss", false))

	# Check Liberator threshold
	var threshold = config.get("liberator_threshold", 5)
	if souls_freed >= threshold and not liberator_status:
		liberator_status = true
		GameState.liberator_status = true
		_show_notification("🕊 LIBERATOR STATUS! Undead deal -2 damage!", Color(0.3, 0.9, 0.3))

	# Check all furnaces destroyed
	var total_furnaces = config.get("furnace_count", 4)
	if furnaces_destroyed >= total_furnaces:
		all_furnaces_destroyed = true
		_show_notification("🔥 ALL FURNACES DESTROYED! Factory power failing!", Color(0.9, 0.5, 0.2))

	_update_furnace_display()
	print("[Floor9] Furnace destroyed. Souls freed: %d" % souls_freed)

func _burn_souls_in_furnace():
	"""Burn 3 Bone to power a door."""
	var config = floor9_template.get_furnace_config()
	var actions = config.get("actions", {})
	var burn_config = actions.get("burn_souls", {})
	var cost_bone = burn_config.get("cost_bone", 3)

	if bone_count < cost_bone:
		_show_notification("Need %d Bone to burn" % cost_bone, Color(0.9, 0.3, 0.3))
		return

	bone_count -= cost_bone
	soul_debt += 1
	furnaces_used += 1
	GameState.soul_debt_count = soul_debt

	_show_notification("🔥 Souls burned! Door powered. Soul Debt: %d" % soul_debt, Color(0.9, 0.3, 0.3))
	_update_salvage_display()
	_update_furnace_display()
	print("[Floor9] Soul burned. Debt: %d" % soul_debt)

func _drain_soul_piston():
	"""Spend 2 gems to free a soul from a Soul-Piston construct mid-combat."""
	var cost = 2
	if GameState.gems < cost:
		_show_notification("Need %d Gems to drain soul" % cost, Color(0.9, 0.3, 0.3))
		return

	GameState.gems -= cost
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)

	_show_notification("💎 Soul freed! Construct deactivates!", Color(0.3, 0.9, 0.3))
	# TODO: Deactivate nearest construct enemy

func _update_furnace_display():
	if not furnace_ui:
		return

	var text = "🔥 Furnaces: %d freed | %d used\n" % [furnaces_destroyed, furnaces_used]
	text += "💀 Soul Debt: %d | Souls Freed: %d\n" % [soul_debt, souls_freed]

	if liberator_status:
		text += "🕊 LIBERATOR"
		furnace_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif soul_debt > 0:
		text += "☠ DEBTOR"
		furnace_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		furnace_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))

	furnace_ui.text = text

func _update_liberator_display():
	if not liberator_ui:
		return

	if liberator_status:
		liberator_ui.text = "🕊 LIBERATOR — Undead deal -2 damage"
		liberator_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		liberator_ui.visible = true
	elif soul_debt > 3:
		liberator_ui.text = "☠ SOUL DEBT: %d — Dragon will be disgusted" % soul_debt
		liberator_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		liberator_ui.visible = true
	else:
		liberator_ui.visible = false

# -------------------------------------------------------------------
# Conveyor Belt System
# -------------------------------------------------------------------

func _update_conveyor_direction():
	"""Update conveyor direction based on current room."""
	var config = floor9_template.get_conveyor_config()
	var directions = config.get("directions", {})
	conveyor_direction = directions.get(current_room_id, "east")

func _ride_conveyor():
	"""Ride the conveyor belt to the next room."""
	var config = floor9_template.get_conveyor_config()
	var speed = config.get("ride_speed", 2.0)

	on_conveyor = true
	_show_notification("🏭 Riding conveyor... Direction: %s" % conveyor_direction, Color(0.6, 0.6, 0.7))

	# TODO: Move player in conveyor direction at speed
	# Check for hazards
	if randf() < 0.3:
		var damage = config.get("hazard_damage", 3)
		_show_notification("💥 Conveyor hazard! %d damage!" % damage, Color(0.9, 0.3, 0.3))
		# Apply conveyor hazard damage
		if GameState.has_method("damage_player"):
			GameState.damage_player(damage)

func _flip_conveyor_switch():
	"""Flip a conveyor switch to change direction."""
	match conveyor_direction:
		"east": conveyor_direction = "west"
		"west": conveyor_direction = "east"
		"north": conveyor_direction = "south"
		"south": conveyor_direction = "north"
		"random": conveyor_direction = "east"

	_show_notification("🔀 Conveyor switched to %s!" % conveyor_direction, Color(0.3, 0.9, 0.3))
	_update_conveyor_display()

func _time_conveyor_jump():
	"""Time a jump between moving platforms in Conveyor Maze."""
	var config = floor9_template.get_conveyor_config()
	var window = config.get("timing_window", 2.0)

	_show_notification("⏱ Time your jump! Window: %.1f seconds!" % window, Color(0.9, 0.7, 0.3))
	# Start timing challenge (simplified — auto-succeed for now)
	_show_notification("⏱ Jump successful!", Color(0.3, 0.9, 0.3))

func _update_conveyor_display():
	if not conveyor_ui:
		return

	if current_room_id in ["assembly_line", "furnace_room", "foundry_pit", "gear_works", "bone_yard", "conveyor_maze"]:
		conveyor_ui.text = "🏭 Conveyor: %s" % conveyor_direction
		if on_conveyor:
			conveyor_ui.text += " [RIDING]"
		conveyor_ui.visible = true
	else:
		conveyor_ui.visible = false

# -------------------------------------------------------------------
# Boss System — The Foreman Eternal (3 Phases)
# -------------------------------------------------------------------

func _start_boss_fight():
	"""Begin The Foreman Eternal boss encounter."""
	foreman_phase = 1
	foreman_hp = foreman_max_hp
	inspection_turn_counter = 0
	skull_case_destroyed = false
	strike_team_built = false

	# Foreman intro
	var intro = "You are unprocessed material.\nDesignation: unknown.\nValue: uncalculated.\nPlease submit to nearest assembly station for evaluation.\nResistance will be logged."

	if liberator_status:
		intro = "You have damaged factory property.\nFreed souls represent lost labor hours.\nHowever: efficiency analysis suggests vengeance is non-productive.\nI will simply... process you faster."

	if foreman_enraged:
		intro += "\n\nPOWER FAILURE DETECTED.\nFOREMAN OVERRIDE: ENRAGED."

	_show_dialogue("The Foreman Eternal", intro)

	_update_foreman_display()
	print("[Floor9] Boss fight started — Phase 1: The Shift. HP: %d/%d" % [foreman_hp, foreman_max_hp])

func _on_foreman_phase_1_shift():
	"""Phase 1: Foreman on conveyor, summons skeletons, inspects every 3rd turn."""
	inspection_turn_counter += 1

	# Summon Assembly Skeleton periodically
	# Summon Assembly Skeleton periodically
	_start_combat_with_enemies(["Assembly Skeleton"])
	_show_notification("🦴 Foreman summons Assembly Skeleton!", Color(0.8, 0.8, 0.7))

	# Attack every 3rd turn (inspection time)
	var config = floor9_template.get_boss_config()
	var interval = config.get("inspection_interval", 3)
	if inspection_turn_counter % interval == 0:
		var damage = 12 if foreman_enraged else 8
		_show_notification("💀 INSPECTION TIME! Massive damage incoming!", Color(0.9, 0.3, 0.3))
		# TODO: Apply massive damage

	# Conveyor movement
	# TODO: Move foreman along conveyor

func _on_foreman_phase_2_quality_control():
	"""Phase 2: Foreman tests player with debuffs."""
	foreman_phase = 2

	# Apply random debuff
	var debuffs = ["weak", "vulnerable", "frail", "slow"]
	var debuff = debuffs[randi() % debuffs.size()]
	_show_notification("🔍 Quality Control: %s debuff applied!" % debuff, Color(0.9, 0.7, 0.3))
	# TODO: Apply debuff

	# If player has Soul Debt, summon enraged undead
	if soul_debt > 0:
		_show_notification("💀 Soul Debt summons enraged undead!", Color(0.9, 0.3, 0.3))
		# Spawn enraged undead adds
		_start_combat_with_enemies(["Assembly Skeleton", "Assembly Skeleton"])

	# If Liberator, conveyor slows
	if liberator_status:
		_show_notification("🕊 Liberator slows the conveyor!", Color(0.3, 0.9, 0.3))
		# TODO: Reduce conveyor speed

	# Deploy Soul-Pistons
	_show_notification("⚙ Soul-Pistons deployed!", Color(0.6, 0.6, 0.7))
	# Spawn Soul-Piston encounter
	_start_combat_with_enemies(["Soul-Piston", "Assembly Skeleton"])

	print("[Floor9] Phase 2: Quality Control")

func _on_foreman_phase_3_efficiency():
	"""Phase 3: Overtime mode — attacks every turn, summons accelerate."""
	foreman_phase = 3

	_show_dialogue("The Foreman Eternal", "Efficiency dropping.\nInitiating overtime protocols.\nAll breaks cancelled.\nProduction must continue.")

	# If Liberator, skull speaks
	if liberator_status and not skull_case_destroyed:
		_show_dialogue("The Skull", "Thank you. End this.\nThe machine does not know what it does.\nBut I remember.\nI remember being human.\nPlease.")

	_show_notification("⏱ FOREMAN OVERTIME! Attacks every turn!", Color(0.9, 0.2, 0.2))
	print("[Floor9] Phase 3: Efficiency Measures")

func _destroy_skull_case():
	"""Destroy the glass case containing the Foreman's original skull."""
	if skull_case_destroyed:
		_show_notification("Skull case already destroyed", Color(0.7, 0.7, 0.7))
		return

	skull_case_destroyed = true

	_show_notification("💀 SKULL CASE DESTROYED! Foreman loses construct enhancements!", Color(0.9, 0.3, 0.3))

	# Foreman loses enhancements but deals +50% damage
	var config = floor9_template.get_boss_config()
	var bonus = config.get("skull_destroy_bonus", 0.5)
	# Apply slow but +damage modifier
	_show_notification("⚡ Foreman damage bonus: +%.0f%%!" % (bonus * 100), Color(0.9, 0.7, 0.2))

	if liberator_status:
		_show_notification("🕊 The skull whispers: 'Thank you...'", Color(0.3, 0.9, 0.3))

func _build_strike_team():
	"""Build 3 companion cards at once for one massive push."""
	var config = floor9_template.get_boss_config()
	var cost = config.get("strike_team_cost", {})
	var req_bone = cost.get("bone", 6)
	var req_gear = cost.get("gear", 3)

	if bone_count < req_bone or gear_count < req_gear:
		_show_notification("Need %d Bone + %d Gear for Strike Team!" % [req_bone, req_gear], Color(0.9, 0.3, 0.3))
		return

	bone_count -= req_bone
	gear_count -= req_gear

	# Build 3 companions at once
	var types = ["bone_drone", "gear_skeleton", "soul_engine"]
	for i in range(3):
		if companions_built.size() < max_companions:
			_build_companion(types[i])

	strike_team_built = true
	_show_notification("🤖 STRIKE TEAM BUILT! 3 companions ready!", Color(0.3, 0.9, 0.3))
	_update_salvage_display()

func _update_foreman_display():
	if not foreman_ui:
		return

	var text = ""
	match foreman_phase:
		1:
			text = "FOREMAN: Phase 1 — The Shift | %d/%d HP" % [foreman_hp, foreman_max_hp]
			if foreman_enraged:
				text += " [ENRAGED]"
		2:
			text = "FOREMAN: Phase 2 — Quality Control | %d/%d HP" % [foreman_hp, foreman_max_hp]
		3:
			text = "FOREMAN: Phase 3 — Efficiency | %d/%d HP" % [foreman_hp, foreman_max_hp]
			if skull_case_destroyed:
				text += " [SKULL BROKEN]"

	foreman_ui.text = text
	foreman_ui.visible = true

	var color = Color(0.9, 0.3, 0.3)
	if foreman_phase == 3:
		color = Color(0.9, 0.1, 0.1)
	foreman_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Radiation Debuff (From Floor 8)
# -------------------------------------------------------------------

func _on_room_entered(room_id: String):
	"""Override to apply radiation damage per room."""
	super._on_room_entered(room_id)

	if radiation_active:
		var damage = 2
		radiation_hp_loss += damage
		_show_notification("☢ Radiation: -%d HP! (Total lost: %d)" % [damage, radiation_hp_loss], Color(0.9, 0.5, 0.2))
		# Apply damage to player on foreman hit
		if GameState.has_method("damage_player"):
			GameState.damage_player(5)
		_show_notification("💥 Foreman strike! -5 HP", Color(0.9, 0.3, 0.3))

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		"Use Assembly Station":
			_show_assembly_menu()

		"Build Companion":
			# Show companion selection UI
			_show_notification("Select: [1] Bone Drone | [2] Gear Skeleton | [3] Soul Engine | [4] Stitch-Walker", Color(0.8, 0.8, 0.8))

		"Repair Self":
			_repair_self()

		"Salvage Parts":
			_show_notification("Salvage nearby enemy remains...", Color(0.7, 0.7, 0.7))
			# TODO: Check for nearby defeated enemies

		"Interact with Furnace":
			_show_furnace_menu()

		"Free Souls":
			_free_souls_from_furnace()

		"Burn Souls":
			_burn_souls_in_furnace()

		"Drain Soul":
			_drain_soul_piston()

		"Ride Conveyor":
			_ride_conveyor()

		"Flip Switch":
			_flip_conveyor_switch()

		"Jump to Platform":
			_time_conveyor_jump()

		"Confront Foreman":
			_start_boss_fight()

		"Destroy Skull Case":
			_destroy_skull_case()

		"Build Strike Team":
			_build_strike_team()

		"Solve Furnace":
			_show_dialogue("Puzzle", "Multiple furnaces, limited time.\nWhich souls to free? Which to use?\nEach choice affects the factory...")

		"Optimize Assembly":
			_show_dialogue("Puzzle", "Given limited Bone + Gear,\nbuild the best companion for upcoming combat.\nWrong build = harder fight.\nRight build = advantage.")

		"Time Conveyor":
			_time_conveyor_jump()

		"Talk to Skeleton":
			_show_dialogue("Assembly Skeleton", "Shift starts in... shift started... shift never ends.\nPlease report to Station 7.\nStation 7 was demolished.\nPlease report to Station 8.")

		"Drain Soul Burner":
			_show_notification("Soul Burner drained! Prevents explosion on death!", Color(0.3, 0.9, 0.3))
			# TODO: Prevent soul burner explosion

		"Confront Machinist":
			_show_dialogue("Skull-Faced Machinist", "Machines don't break.\nMachines only wait.\nWait for oil, wait for parts, wait for...\nyou. You have parts I need.")

		"Approach Pensioned":
			_show_dialogue("The Pensioned", "Forty years on the line.\nForty years of assembly.\nI don't remember what I was assembling.\nBut I never stopped.")

		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.")

		_:
			super._on_object_interact(object_type)

func _show_assembly_menu():
	"""Show the assembly station menu."""
	var text = "⚙ ASSEMBLY STATION\n"
	text += "Bone: %d | Gear: %d\n\n" % [bone_count, gear_count]
	text += "[C] Companion (2B+1G)\n"
	text += "[R] Repair Self (1B+2G)\n"
	text += "[S] Salvage"
	_show_notification(text, Color(0.8, 0.8, 0.7))

func _show_furnace_menu():
	"""Show the furnace interaction menu."""
	var text = "🔥 SOUL FURNACE\n"
	if elemental_core_held:
		text += "[OVERCLOCK available — Elemental Core active]\n"
	text += "[F] Free Souls (alarm chance)\n"
	text += "[B] Burn Souls (3 Bone, +Soul Debt)\n"
	text += "[D] Drain Soul-Piston (2 Gems)"
	_show_notification(text, Color(0.9, 0.5, 0.2))

# -------------------------------------------------------------------
# Combat Overrides
# -------------------------------------------------------------------

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	"""Override to check for goblin refugees and apply cross-floor effects."""
	# Check for goblin refugees causing chaos
	if goblin_refugees and randf() < 0.3:
		_show_notification("🤪 Goblin refugees join the fight! Chaos!", Color(0.9, 0.7, 0.3))
		# Add random goblin reinforcement
		_start_combat_with_enemies(["Goblin Grunt"])

	# Check for elite encounters from elementals loose
	if elementals_loose and randf() < 0.4:
		_show_notification("💨 Loose elemental ambush!", Color(0.9, 0.7, 0.3))
		# Add elemental reinforcement
		_start_combat_with_enemies(["Cinder Mote"])

	# Apply no-power penalties
	if no_power:
		_show_notification("⚠ Low power! Constructs slower!", Color(0.9, 0.7, 0.3))
		# Reduce construct enemy speed
		_show_notification("🔧 Construct speed reduced!", Color(0.3, 0.9, 0.3))

	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to salvage defeated enemies and update state."""
	if not victory:
		super._on_combat_ended(victory)
		return

	# Check if this was boss fight
	if current_room_id == "foremans_office":
		_end_boss_combat(victory)
		return

	# Salvage defeated enemies
	# TODO: Get actual defeated enemy list from combat manager
	# For now, add generic salvage
	if randf() < 0.7:
		_add_salvage("bone", 1)
	if randf() < 0.5:
		_add_salvage("gear", 1)

	# Check for Liberator buff reducing undead damage
	if liberator_status:
		_show_notification("🕊 Liberator: Undead damage reduced!", Color(0.3, 0.9, 0.3))

	super._on_combat_ended(victory)

func _on_combat_turn_advanced():
	"""Override to process boss phases and radiation."""
	# Foreman phase logic
	if current_room_id == "foremans_office":
		var config = floor9_template.get_boss_config()
		var phase1_hp = config.get("phase_transition_hp_1", 45)
		var phase2_hp = config.get("phase_transition_hp_2", 20)

		if foreman_phase == 1:
			_on_foreman_phase_1_shift()
			if foreman_hp <= phase1_hp:
				_on_foreman_phase_2_quality_control()
		elif foreman_phase == 2:
			if foreman_hp <= phase2_hp:
				_on_foreman_phase_3_efficiency()

		_update_foreman_display()

	# Update all displays
	_update_salvage_display()
	_update_furnace_display()
	_update_conveyor_display()
	_update_liberator_display()

func _end_boss_combat(victory: bool):
	"""End the boss fight and handle transitions."""
	if victory:
		if liberator_status and skull_case_destroyed:
			_show_dialogue("The Tower", "The Foreman falls.\nThe skull is silent now.\nA mercy, at the end.\nThe path to Floor 10 opens.\nThe dragon awaits.")
		elif liberator_status:
			_show_dialogue("The Tower", "The Foreman falls.\nBut the skull still whispers.\n'Free them. Free them all.'\nThe path to Floor 10 opens.")
		elif soul_debt > 3:
			_show_dialogue("The Tower", "The Foreman falls.\nThe debt is paid in blood.\nThe dragon will smell it on you.\nThe path to Floor 10 opens.")
		else:
			_show_dialogue("The Tower", "The Foreman falls.\nThe factory groans but holds.\nThe path to Floor 10 opens.\nThe dragon awaits your weight.")

		# Give rewards
		GameState.gems += 100
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)

		# Apply cross-floor effects to Floor 10
		_apply_floor10_effects()

		# Save progress
		GameState.save_game()

		# Auto-transition to Floor 10 after a short delay
		_show_notification("🏰 Ascending to Floor 10...", Color(0.9, 0.7, 0.3))
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(_ascend_to_next_floor)
		add_child(timer)
		timer.start()
	else:
		_show_notification("💀 Defeated by The Foreman Eternal", Color(0.9, 0.3, 0.3))

func _apply_floor10_effects():
	"""Apply cross-floor bleed effects to Floor 10 based on Floor 9 outcome."""
	if liberator_status:
		GameState.floor10_dragon_compassion = true

	if soul_debt > 3:
		GameState.floor10_dragon_disgust = true
		GameState.floor10_soul_debt = soul_debt

	if companions_built_total >= 5:
		GameState.floor10_secret_ending_path = true

	if all_furnaces_destroyed:
		GameState.floor10_freed_souls_follow = true

# -------------------------------------------------------------------
# Floor Complete — Transition to Floor 10
# -------------------------------------------------------------------

func _show_floor_transition_prompt():
	"""Show prompt to ascend to Floor 10."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 10 — The Dragon"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	add_child(prompt)

func _ascend_to_next_floor():
	"""Ascend to Floor 10."""
	print("[Floor9] Ascending to Floor 10...")
	get_tree().change_scene_to_file("res://scenes/Floor10.tscn")

# -------------------------------------------------------------------
# Input Override
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Base class input
	super._input(event)

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_bone_count() -> int:
	return bone_count

func get_gear_count() -> int:
	return gear_count

func get_soul_debt() -> int:
	return soul_debt

func is_liberator() -> bool:
	return liberator_status

func get_companions_built_total() -> int:
	return companions_built_total

func are_all_furnaces_destroyed() -> bool:
	return all_furnaces_destroyed

func get_radiation_hp_loss() -> int:
	return radiation_hp_loss
