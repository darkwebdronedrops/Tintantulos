extends FloorController

# ===================================================================
# FLOOR 10 CONTROLLER — The Dragon's Lair
# Refactored to use FloorController base class + Floor10Template
# ===================================================================
# 11 Moments: Ghosts → Hoard → Aspects → Revelation → Throne
# Dragon boss with true/false endings, Cano Protocol meta-boss
# ===================================================================

@onready var floor10_template: Floor10Template = Floor10Template.new()

# Moment State
var current_moment: int = 1
var total_moments: int = 11
var moment_type: String = "ghost"

# Ghost State
var ghosts_appeared: Array[int] = []
var ghosts_spoken: Array[int] = []

# Hoard State
var hoard_objects_touched: Dictionary = {}
var hoard_objects_altered: Dictionary = {}
var hoard_weight_revealed: bool = false

# Aspect State
var aspects_defeated: Array[String] = []
var aspect_current: String = ""
var time_aspect_hp: int = 40
var greed_aspect_hp: int = 45
var transformation_aspect_hp: int = 40

# Dragon State
var dragon_phase: int = 1
var dragon_hp: int = 50
var dragon_max_hp: int = 50
var dragon_variant_name: String = "The Dragon"
var dragon_sprite_path: String = "res://assets/sprites/floor10/boss_the_dragon_idle.png"
var player_attacked_in_phase_1: bool = false
var crack_revealed: bool = false
var crack_visible: bool = false
var final_choice_made: bool = false

# Weight Calculation
var player_weight: int = 0  # Positive = heavy/corrupted, Negative = light/pure

# Ending State
var ending_chosen: String = ""
var cano_protocol_triggered: bool = false

# Cano Protocol State
var cano_hp: int = 50
var cano_archive_remaining: int = 50
var cano_ability_index: int = 0  # 0=MemoryLeak, 1=StackOverflow, 2=GarbageCollection
var cano_phase: int = 1

# Cross-Floor Dialogue Flags
var cross_floor_dialogue: Dictionary = {}

# UI References
var moment_ui: Label
var hoard_ui: Label
var aspect_ui: Label
var dragon_ui: Label
var weight_ui: Label
var cano_ui: Label

func _ready():
	floor_template = floor10_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Calculate player weight
	_calculate_player_weight()

	# Setup Dragon variant based on GameState probability roll
	_setup_dragon_variant()

	# Set Dragon HP based on weight + variant
	var config = floor10_template.get_dragon_config()
	var base_hp: int
	if player_weight > 0:
		# Heavy choices = Dragon weaker (recognizes kin)
		base_hp = config.get("hp_heavy_choices", 35)
		_show_notification("💀 Your corruption weighs heavy. The Dragon recognizes kin. HP: %d" % dragon_max_hp, Color(0.9, 0.3, 0.3))
	else:
		# Light choices = Dragon stronger (threat to cycle)
		base_hp = config.get("hp_light_choices", 70)
		_show_notification("🕊 Your purity is a threat. The Dragon fights with everything. HP: %d" % dragon_max_hp, Color(0.3, 0.9, 0.3))

	# Apply variant HP modifier
	var variant_mod = _get_dragon_hp_modifier()
	dragon_max_hp = base_hp + variant_mod
	dragon_hp = dragon_max_hp

	# Check Cano Protocol trigger
	_check_cano_protocol_trigger()

	# Gather cross-floor dialogue
	_gather_cross_floor_dialogue()

	print("[Floor10] Setup. Weight: %d | Dragon: %s | HP: %d/%d | Cano: %s" % [
		player_weight, dragon_variant_name, dragon_hp, dragon_max_hp, cano_protocol_triggered
	])
	
	# Add shop kiosk before final confrontation
	var kiosk = Node2D.new()
	kiosk.name = "ShopKiosk"
	kiosk.position = Vector2(200, 800)
	add_child(kiosk)
	print("[Floor10] Shop kiosk added")

func _calculate_player_weight():
	"""Calculate player's moral weight across all floors."""
	var categories = floor10_template.get_weight_categories()
	var heavy = categories.get("heavy", {})
	var light = categories.get("light", {})

	# Heavy choices (positive weight = corruption)
	for choice_id in heavy.keys():
		var config = heavy[choice_id]
		var threshold = config.get("threshold", 1)
		var weight = config.get("weight", 0)
		var count = _get_choice_count(choice_id)
		if count >= threshold:
			player_weight += weight

	# Light choices (negative weight = purity)
	for choice_id in light.keys():
		var config = light[choice_id]
		var weight = config.get("weight", 0)
		if _check_condition(choice_id):
			player_weight += weight  # weight is negative

	print("[Floor10] Player weight calculated: %d" % player_weight)

func _get_choice_count(choice_id: String) -> int:
	"""Get the count/value of a tracked choice."""
	match choice_id:
		"pacts_signed": return GameState.get_value("pacts_signed_count", 0)
		"souls_enslaved": return GameState.get_value("souls_enslaved_count", 0)
		"soul_debt": return GameState.get_value("soul_debt_count", 0)
		"companions_built": return GameState.get_value("companions_built_total", 0)
		"void_bond_active": return 1 if GameState.get_value("void_bond_active", false) else 0
		"marked_debuff": return 1 if GameState.get_value("marked_debuff_active", false) else 0
		_: return 0

func _check_condition(choice_id: String) -> bool:
	"""Check if a condition is met."""
	match choice_id:
		"liberator_status": return GameState.get_value("liberator_status", false)
		"all_pacts_refused": return GameState.get_value("pacts_signed_count", 0) == 0
		"all_furnaces_destroyed": return GameState.get_value("all_furnaces_destroyed", false)
		"no_soul_debt": return GameState.get_value("soul_debt_count", 0) == 0
		"graduate_status": return GameState.get_value("floor6_graduate_status", "") != ""
		_: return false

func _check_cano_protocol_trigger():
	"""Check if Cano Protocol should trigger instead of Dragon."""
	var config = floor10_template.get_cano_config()
	var trigger = config.get("trigger", {})
	var required_deck = trigger.get("dragon_deck_size", 50)
	var min_runs = trigger.get("run_count_minimum", 2)

	var current_archive = GameState.get_value("dragon_deck_archive_size", 0)
	var run_count = GameState.get_value("run_count", 1)

	if current_archive >= required_deck and run_count >= min_runs:
		cano_protocol_triggered = true
		_show_notification("⚠ NO DRAGON. The throne is empty. The door is open.", Color(0.3, 0.3, 0.9))
		print("[Floor10] Cano Protocol triggered! Archive: %d | Runs: %d" % [current_archive, run_count])

func _gather_cross_floor_dialogue():
	"""Gather all cross-floor dialogue triggers."""
	var effects = floor10_template.get_cross_floor_effects()

	for floor_key in effects.keys():
		var floor_effects = effects[floor_key]
		for condition in floor_effects.keys():
			if _check_floor_condition(condition):
				cross_floor_dialogue[condition] = floor_effects[condition]

func _check_floor_condition(condition: String) -> bool:
	"""Check if a cross-floor condition is met."""
	match condition:
		"liberator_status": return GameState.get_value("liberator_status", false)
		"soul_debt_gt_3": return GameState.get_value("soul_debt_count", 0) > 3
		"companions_built_5": return GameState.get_value("companions_built_total", 0) >= 5
		"all_furnaces_destroyed": return GameState.get_value("all_furnaces_destroyed", false)
		"reforging_accepted": return GameState.get_value("reforging_accepted", false)
		"reforging_refused": return GameState.get_value("reforging_refused", false)
		"high_fire_attunement": return GameState.get_value("fire_attunement", 0) > 5
		"signed_final_pact": return GameState.get_value("final_pact_signed", false)
		"broke_all_pacts": return GameState.get_value("pacts_broken_count", 0) >= GameState.get_value("pacts_signed_count", 0) and GameState.get_value("pacts_signed_count", 0) > 0
		"void_bond_active": return GameState.get_value("void_bond_active", false)
		"graduate_status": return GameState.get_value("floor6_graduate_status", "") != ""
		"dropout_status": return GameState.get_value("floor6_dropout", "") != ""
		"deans_key": return GameState.get_value("floor6_master_key", false)
		"defeated_elemental_core": return GameState.get_value("floor5_elemental_core_defeated", false)
		"befriended_goblin_janitor": return GameState.get_value("floor6_goblin_janitor_befriended", false)
		"sold_memories": return GameState.get_value("floor4_sold_memories", false)
		"bought_infinity_mirror": return GameState.get_value("floor4_bought_infinity_mirror", false)
		"optimal_boss_kill": return GameState.get_value("floor3_optimal_kill", false)
		"suboptimal_boss_kill": return GameState.get_value("floor3_suboptimal_kill", false)
		"killed_flesh_garden": return GameState.get_value("floor2_killed_flesh_garden", false)
		"left_spore_clouds": return GameState.get_value("floor2_left_spores", false)
		"befriended_shortcut_maker": return GameState.get_value("floor1_shortcut_maker_befriended", false)
		_: return false

func _setup_floor_ui():
	# Moment display
	moment_ui = Label.new()
	moment_ui.name = "MomentUI"
	moment_ui.position = Vector2(20, 20)
	moment_ui.size = Vector2(400, 40)
	moment_ui.add_theme_font_size_override("font_size", 13)
	add_child(moment_ui)
	_update_moment_display()

	# Hoard display
	hoard_ui = Label.new()
	hoard_ui.name = "HoardUI"
	hoard_ui.position = Vector2(20, 70)
	hoard_ui.size = Vector2(400, 80)
	hoard_ui.add_theme_font_size_override("font_size", 11)
	hoard_ui.visible = false
	add_child(hoard_ui)

	# Weight display
	weight_ui = Label.new()
	weight_ui.name = "WeightUI"
	weight_ui.position = Vector2(20, 160)
	weight_ui.size = Vector2(350, 40)
	weight_ui.add_theme_font_size_override("font_size", 12)
	add_child(weight_ui)
	_update_weight_display()

	# Aspect display
	aspect_ui = Label.new()
	aspect_ui.name = "AspectUI"
	aspect_ui.position = Vector2(20, 210)
	aspect_ui.size = Vector2(400, 40)
	aspect_ui.add_theme_font_size_override("font_size", 12)
	aspect_ui.visible = false
	add_child(aspect_ui)

	# Dragon display
	dragon_ui = Label.new()
	dragon_ui.name = "DragonUI"
	dragon_ui.position = Vector2(20, 260)
	dragon_ui.size = Vector2(400, 40)
	dragon_ui.add_theme_font_size_override("font_size", 12)
	dragon_ui.visible = false
	add_child(dragon_ui)

	# Cano Protocol display
	cano_ui = Label.new()
	cano_ui.name = "CanoUI"
	cano_ui.position = Vector2(20, 260)
	cano_ui.size = Vector2(500, 60)
	cano_ui.add_theme_font_size_override("font_size", 11)
	cano_ui.visible = false
	add_child(cano_ui)

func _update_floor_ui():
	_update_moment_display()
	_update_hoard_display()
	_update_weight_display()
	_update_aspect_display()
	_update_dragon_display()
	if cano_protocol_triggered:
		_update_cano_display()

# -------------------------------------------------------------------
# Moment System
# -------------------------------------------------------------------

func _update_moment_display():
	if not moment_ui:
		return

	var text = ""
	match moment_type:
		"ghost": text = "👁 Moment %d — The %s" % [current_moment, _ghost_name()]
		"hoard": text = "💎 Moment %d — The Hoard" % current_moment
		"score": text = "⚖ Moment %d — The Weight" % current_moment
		"combat": text = "⚔ Moment %d — The %s Aspect" % [current_moment, aspect_current.capitalize()]
		"walk": text = "🚶 Moment %d — The Approach" % current_moment
		"boss_phase_1_2": text = "🐉 Moment %d — The Revelation" % current_moment
		"final_choice": text = "👑 Moment %d — The Throne" % current_moment

	moment_ui.text = text

func _ghost_name() -> String:
	match current_moment:
		1: return "Threshold"
		2: return "Witness"
		3: return "Memory"
		_: return "Ghost"

func _advance_moment():
	"""Advance to the next moment."""
	current_moment += 1
	if current_moment > total_moments:
		return

	# Update moment type
	var room_id = "moment_%02d_%s" % [current_moment, _get_moment_id_suffix(current_moment)]
	var room = rooms.get(room_id)
	if room:
		moment_type = room.get("moment_type", "walk")
		current_room_id = room_id
		_enter_room(room_id)

	_update_moment_display()
	print("[Floor10] Advanced to Moment %d: %s" % [current_moment, moment_type])

func _get_moment_id_suffix(moment_num: int) -> String:
	match moment_num:
		1: return "threshold"
		2: return "witness"
		3: return "memory"
		4: return "hoard"
		5: return "weight"
		6: return "first_aspect"
		7: return "second_aspect"
		8: return "third_aspect"
		9: return "approach"
		10: return "revelation"
		11: return "throne"
		_: return "walk"

# -------------------------------------------------------------------
# Ghost Encounters (Moments 1-3)
# -------------------------------------------------------------------

func _spawn_ghost_boss(floor_num: int):
	"""Spawn the ghost of a defeated boss."""
	if floor_num in ghosts_appeared:
		return

	ghosts_appeared.append(floor_num)

	var ghost_name = ""
	var dialogue = ""
	match floor_num:
		1:
			ghost_name = "The Door"
			dialogue = "I was the first thing you fought.\nI taught you to block and strike.\nYou have come far since then.\n...I am proud of you."
		2:
			ghost_name = "Spore Heart"
			dialogue = "You walked through my garden.\nYou breathed my spores.\nYou killed me, or I killed myself —\nit matters little now.\nI remember you."
		3:
			ghost_name = "Gear Mother"
			dialogue = "You broke my gears.\nI should hate you.\nBut gears break. That is what gears do.\nYou simply... arrived at the right time."

	_show_dialogue("Ghost of %s" % ghost_name, dialogue)
	_show_notification("👁 Ghost of %s appears..." % ghost_name, Color(0.7, 0.7, 0.9))

	# Check for cross-floor dialogue
	for condition in cross_floor_dialogue.keys():
		var effect = cross_floor_dialogue[condition]
		if effect.has("dragon_dialogue") and floor_num == 1:
			# Floor 1 specific
			pass

	print("[Floor10] Ghost of Floor %d appeared" % floor_num)

# -------------------------------------------------------------------
# Hoard System (Moments 4-5)
# -------------------------------------------------------------------

func _touch_hoard_object(object_id: String):
	"""Player touches a hoard object."""
	var config = floor10_template.get_hoard_config()
	var obj = config.get(object_id)
	if not obj:
		return

	if hoard_objects_touched.has(object_id):
		_show_notification("You already touched %s" % obj["name"], Color(0.7, 0.7, 0.7))
		return

	hoard_objects_touched[object_id] = true

	var desc = "%s\nFloor %d choice: %s" % [obj["name"], obj["floor"], obj["choice"]]
	if obj["can_alter"]:
		desc += "\n\nCan alter: %s (%s)" % [obj["alter_action"], obj["alter_cost"]]

	_show_dialogue(obj["name"], desc)
	_update_hoard_display()
	print("[Floor10] Touched hoard object: %s" % object_id)

func _alter_hoard_object(object_id: String):
	"""Alter a hoard object at a cost."""
	var config = floor10_template.get_hoard_config()
	var obj = config.get(object_id)
	if not obj or not obj["can_alter"]:
		return

	if hoard_objects_altered.has(object_id):
		_show_notification("Already altered", Color(0.7, 0.7, 0.7))
		return

	# Apply cost
	match object_id:
		"blood_contract":
			# Take 10 damage
			_show_notification("💔 Burned contract! -10 HP! Pact removed!", Color(0.9, 0.3, 0.3))
			# Remove pact buff, apply 10 damage
			if GameState.has_method("damage_player"):
				GameState.damage_player(10)
			if GameState.has_method("remove_boon"):
				GameState.remove_boon("infernal_pact")
		"soul_gem":
			# Dragon gains +5 HP
			if player_weight > 0:
				dragon_hp += 5
				_show_notification("💎 Shattered gem! Freed soul! Dragon +5 HP!", Color(0.3, 0.9, 0.3))
		"reforged_blade":
			_show_notification("🔥 Melted blade! Lost buff, kept cards!", Color(0.9, 0.7, 0.3))
			# Remove weapon buff
			_show_notification("🔥 Buff removed!", Color(0.9, 0.7, 0.3))
		"graduate_scroll":
			_show_notification("📜 Rewrote scroll! Floor 7 prices affected!", Color(0.7, 0.7, 0.9))
			# Change grade (affects Floor 7 shop prices)
			_show_notification("📜 Grade changed! Floor 7 prices updated!", Color(0.7, 0.7, 0.9))

	hoard_objects_altered[object_id] = true
	_update_hoard_display()

func _reveal_weight():
	"""Reveal the player's accumulated weight."""
	if hoard_weight_revealed:
		return

	hoard_weight_revealed = true

	var label = "Light" if player_weight < 0 else ("Heavy" if player_weight > 0 else "Balanced")
	_show_dialogue("The Weight", "Your choices across 9 floors:\n\nWeight: %d (%s)\n\nPacts signed: %d\nSouls freed: %d\nSouls enslaved: %d\nCompanions built: %d\n\nThe Dragon sees this." % [
		player_weight, label,
		GameState.get_value("pacts_signed_count", 0),
		GameState.get_value("souls_freed_count", 0),
		GameState.get_value("souls_enslaved_count", 0),
		GameState.get_value("companions_built_total", 0)
	])

func _update_hoard_display():
	if not hoard_ui:
		return

	var touched = hoard_objects_touched.size()
	var altered = hoard_objects_altered.size()
	var text = "💎 HOARD: %d touched | %d altered\n" % [touched, altered]
	for obj_id in hoard_objects_touched.keys():
		var name = floor10_template.get_hoard_config().get(obj_id, {}).get("name", obj_id)
		var status = "[ALTERED]" if hoard_objects_altered.has(obj_id) else ""
		text += "• %s %s\n" % [name, status]

	hoard_ui.text = text
	hoard_ui.visible = current_moment in [4, 5]

func _update_weight_display():
	if not weight_ui:
		return

	var label = ""
	var color = Color(0.8, 0.8, 0.8)
	if player_weight < -5:
		label = "PURE"
		color = Color(0.3, 0.9, 0.3)
	elif player_weight < 0:
		label = "LIGHT"
		color = Color(0.5, 0.8, 0.5)
	elif player_weight == 0:
		label = "BALANCED"
		color = Color(0.8, 0.8, 0.8)
	elif player_weight > 5:
		label = "CORRUPTED"
		color = Color(0.9, 0.3, 0.3)
	else:
		label = "HEAVY"
		color = Color(0.9, 0.7, 0.3)

	weight_ui.text = "⚖ WEIGHT: %d [%s]" % [player_weight, label]
	weight_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Dragon Aspect Combats (Moments 6-8)
# -------------------------------------------------------------------

func _start_aspect_combat(aspect_id: String):
	"""Start combat with a Dragon Aspect."""
	aspect_current = aspect_id
	var config = floor10_template.get_aspect_config()
	var aspect = config.get(aspect_id)
	if not aspect:
		return

	var hp = aspect.get("hp", 40)
	match aspect_id:
		"time": time_aspect_hp = hp
		"greed": greed_aspect_hp = hp
		"transformation": transformation_aspect_hp = hp

	# Check for cross-floor empowerment
	var effects = floor10_template.get_cross_floor_effects()
	var from_f9 = effects.get("from_floor9", {})
	if aspect_id == "greed" and from_f9.get("soul_debt_gt_3", {}).get("aspect_greed_empowered", false):
		greed_aspect_hp += 10
		_show_notification("😈 Greed Aspect empowered by soul debt!", Color(0.9, 0.3, 0.3))

	# Check for cross-floor weakening
	var from_f7 = effects.get("from_floor7", {})
	if from_f7.get("broke_all_pacts", {}).get("aspects_minus_2_hp", false):
		hp -= 2
		_show_notification("💪 Pactless! Aspects weakened!", Color(0.3, 0.9, 0.3))

	_show_dialogue(aspect["name"], _get_aspect_intro(aspect_id))
	_update_aspect_display()
	print("[Floor10] Aspect combat started: %s" % aspect_id)

func _get_aspect_intro(aspect_id: String) -> String:
	match aspect_id:
		"time": return "I am what you spent.\nI am every turn you used to hurt others.\nNow those turns turn against you."
		"greed": return "I am what you kept.\nI am every gem you hoarded, every card you saved.\nThe more you have, the larger I grow."
		"transformation": return "I am what you changed.\nI am every enemy you corrupted, every pact you signed.\nYou remade the world in your image.\nNow I wear that image."
		_: return ""

func _on_aspect_defeated(aspect_id: String):
	"""Handle aspect defeat."""
	aspects_defeated.append(aspect_id)
	_show_notification("⚔ %s Aspect defeated!" % aspect_id.capitalize(), Color(0.3, 0.9, 0.3))

	# If player has 5+ companions built, skip remaining aspects
	if GameState.get_value("companions_built_total", 0) >= 5 and aspects_defeated.size() < 3:
		_show_dialogue(dragon_variant_name, "You build. I destroy.\nWe are not so different.\nSkip the rest. Face me.")
		# Skip directly to moment 9 (The Approach)
		_show_notification("⏩ Skipping to The Approach...", Color(0.8, 0.8, 0.3))

	_update_aspect_display()
	print("[Floor10] Aspect defeated: %s" % aspect_id)

func _update_aspect_display():
	if not aspect_ui:
		return

	if aspect_current.is_empty():
		aspect_ui.visible = false
		return

	var hp = 0
	match aspect_current:
		"time": hp = time_aspect_hp
		"greed": hp = greed_aspect_hp
		"transformation": hp = transformation_aspect_hp

	var defeated = aspect_current in aspects_defeated
	var text = ""
	if defeated:
		text = "⚔ %s Aspect: DEFEATED" % aspect_current.capitalize()
	else:
		text = "⚔ %s Aspect: %d HP" % [aspect_current.capitalize(), hp]

	aspect_ui.text = text
	aspect_ui.visible = true

# -------------------------------------------------------------------
# Dragon Boss (Moments 9-10)
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Dragon Variant System
# -------------------------------------------------------------------

func _setup_dragon_variant():
	"""Pick dragon variant based on GameState probability roll.
	AudioManager._get_dragon_key() sets this per run (33% each)."""
	var variant = GameState.get_value("dragon_variant", "")
	
	# If no variant set yet, pick one now (shouldn't happen, but safety)
	if variant.is_empty():
		var roll = randf()
		if roll < 0.33:
			variant = "red_dragon"
		elif roll < 0.66:
			variant = "black_dragon"
		else:
			variant = "gold_dragon"
		GameState.dragon_variant = variant
	
	# Map variant key to display name and sprite path
	match variant:
		"red_dragon":
			dragon_variant_name = "Red Dragon"
			dragon_sprite_path = "res://assets/sprites/enemies/Dragon/enemy_red_dragon_idle.png"
		"black_dragon":
			dragon_variant_name = "Black Dragon"
			dragon_sprite_path = "res://assets/sprites/enemies/Dragon/enemy_black_dragon_idle.png"
		"gold_dragon":
			dragon_variant_name = "Gold Dragon"
			dragon_sprite_path = "res://assets/sprites/enemies/Dragon/enemy_gold_dragon_idle.png"
		_:
			dragon_variant_name = "The Dragon"
			dragon_sprite_path = "res://assets/sprites/floor10/boss_the_dragon_idle.png"
	
	print("[Floor10] Dragon variant: %s | Sprite: %s" % [dragon_variant_name, dragon_sprite_path])

func _get_dragon_hp_modifier() -> int:
	"""HP modifier based on dragon variant."""
	match GameState.get_value("dragon_variant", ""):
		"red_dragon": return -5   # Aggressive but fragile
		"black_dragon": return +10  # Tanky
		"gold_dragon": return 0   # Balanced
		_: return 0

func _get_dragon_intro_text() -> String:
	"""Variant-specific intro text for the Dragon."""
	match dragon_variant_name:
		"Red Dragon":
			return "I am the fire that consumes what you build. I do not hoard. I destroy."
		"Black Dragon":
			return "I am the memory of every tower that fell before this one. I wait. I endure."
		"Gold Dragon":
			return "I am the question you have been climbing to answer. Will you like the answer?"
		_:
			return "You have climbed through greed and grief, through transformation and trial."

func _start_dragon_fight():
	"""Begin the Dragon encounter."""
	if cano_protocol_triggered:
		_start_cano_fight()
		return

	dragon_phase = 1
	player_attacked_in_phase_1 = false
	crack_revealed = false
	crack_visible = false

	# Build introduction with cross-floor dialogue + variant flavor
	var intro = _get_dragon_intro_text() + "\n\nYou have killed my servants, befriended my janitors, freed my prisoners, and enslaved my workers.\nYou have become many things.\nBut there is one thing you have not yet become.\nFinished."

	# Add cross-floor specific dialogue
	for condition in cross_floor_dialogue.keys():
		var effect = cross_floor_dialogue[condition]
		if effect.has("dragon_dialogue"):
			intro += "\n\n" + effect["dragon_dialogue"]
			break  # Only one specific dialogue

	_show_dialogue(dragon_variant_name, intro)
	_update_dragon_display()
	print("[Floor10] Dragon fight started — Phase 1: The Revelation")

func _on_dragon_phase_1_revelation():
	"""Phase 1: Dragon speaks. Player can attack or listen."""
	_show_dialogue(dragon_variant_name, "I do not attack.\nI speak.\nI tell you what I know about you —\nbased on all your tracked choices.\n\nYou freed %d souls.\nYou enslaved %d.\nYou signed %d pacts and broke %d.\nYou rebuilt yourself in the Kami Crucible.\nYou have become many things.\nBut have you become what you wanted?" % [
		GameState.get_value("souls_freed_count", 0),
		GameState.get_value("souls_enslaved_count", 0),
		GameState.get_value("pacts_signed_count", 0),
		GameState.get_value("pacts_broken_count", 0)
	])

	# Offer choice: attack or listen
	_show_notification("🐉 Choose: [A]ttack or [L]isten", Color(0.9, 0.7, 0.3))

func _player_attacks_dragon_phase_1():
	"""Player attacks in Phase 1 — reveals hidden crack."""
	player_attacked_in_phase_1 = true
	crack_revealed = true

	# Check if crack is visible
	var config = floor10_template.get_dragon_config()
	var visible_if = config.get("phase_1", {}).get("crack_visible_if", "no_major_demon_deals")
	if visible_if == "no_major_demon_deals" and not GameState.get_value("final_pact_signed", false):
		crack_visible = true
		_show_notification("💥 CRACK APPEARS in the wall behind the throne!", Color(0.3, 0.9, 0.3))
	else:
		_show_notification("💥 You struck the wall. Something shifted... but you cannot see what.", Color(0.7, 0.7, 0.7))

	_show_dialogue(dragon_variant_name, "You struck before I finished speaking.\nThat is not manners.\nThat is not wisdom.\nThat is... interesting.\n\nLook behind me.\nThe wall has a crack now.\nIt was always there.\nYou just needed to hit something to see it.\nThe Compiler is behind that wall.\nIt has been behind every wall.\nWill you go to it?\nOr will you stay here and listen to my three pretty lies?")

	# Dragon takes damage but doesn't retaliate
	dragon_hp -= 5
	_show_notification("Dragon takes 5 damage. It does not retaliate.", Color(0.9, 0.3, 0.3))

	# Move to Phase 2
	dragon_phase = 2
	_on_dragon_phase_2_test()

func _player_listens_phase_1():
	"""Player listens in Phase 1 — no crack, dialogue choices reveal weakness."""
	_show_dialogue(dragon_variant_name, "Patience. Virtue.\nLet me tell you my patterns.\nI attack in threes.\nI pause on the fourth.\nI am strongest when you are full, weakest when you are empty.\nRemember this.\nIt may save you.")

	# Move to Phase 2
	dragon_phase = 2
	_on_dragon_phase_2_test()

func _on_dragon_phase_2_test():
	"""Phase 2: Combat or dialogue based on Phase 1 choice."""
	if player_attacked_in_phase_1:
		_show_dialogue(dragon_variant_name, "You chose aggression.\nI respect that.\nBut respect is not mercy.")
		# Dragon enters combat form — stronger, faster, telegraphed attacks
		_show_notification("🐉 Dragon enters COMBAT FORM!", Color(0.9, 0.3, 0.3))
	else:
		_show_dialogue(dragon_variant_name, "You chose patience.\nI have told you my patterns.\nUse them.\nOr don't.\nThe choice, as always, is yours.")
		# Dialogue choices reveal weaknesses
		_show_notification("🐉 Dragon reveals weaknesses through dialogue!", Color(0.3, 0.9, 0.3))
	
	# Start actual combat with the dragon variant
	_start_dragon_combat()

func _start_dragon_combat():
	"""Start card combat with the dragon variant. Syncs manual HP with combat stats."""
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if not combat_manager:
		push_error("[Floor10] No CombatManager found!")
		return
	
	# Sync dragon HP with variant's combat stats before starting
	var enemy_template = RoomEnemyDatabase.ENEMIES.get(dragon_variant_name)
	if enemy_template:
		dragon_max_hp = enemy_template.max_hp
		# If dragon already took narrative damage, carry it over
		if dragon_hp > dragon_max_hp:
			dragon_hp = dragon_max_hp
	else:
		push_warning("[Floor10] Dragon variant '%s' not found in database, using default" % dragon_variant_name)
	
	print("[Floor10] Starting dragon combat: %s | HP: %d/%d" % [dragon_variant_name, dragon_hp, dragon_max_hp])
	
	# Connect to enemy damage signal for HP sync
	if not combat_manager.enemy_damaged.is_connected(_on_dragon_damaged_in_combat):
		combat_manager.enemy_damaged.connect(_on_dragon_damaged_in_combat)
	
	_start_combat_with_enemies([dragon_variant_name], true)

func _on_dragon_damaged_in_combat(index: int, damage: int):
	"""Sync CombatManager enemy HP back to manual dragon_hp tracker."""
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if not combat_manager or combat_manager.enemies.is_empty():
		return
	
	# Find the dragon enemy in combat (should be index 0 in a boss fight)
	if index >= 0 and index < combat_manager.enemies.size():
		var enemy = combat_manager.enemies[index]
		if enemy.name == dragon_variant_name or enemy.name == "The Dragon":
			dragon_hp = enemy.hp
			_update_dragon_display()
			print("[Floor10] Dragon took %d damage in combat | HP: %d/%d" % [damage, dragon_hp, dragon_max_hp])
			
			# Check for Phase 3 threshold during combat
			var threshold = floor10_template.get_dragon_config().get("phase_3", {}).get("hp_threshold", 0.25)
			if float(dragon_hp) / dragon_max_hp <= threshold and dragon_phase < 3:
				_show_notification("🐉 %s is weakening... Phase 3 approaching!" % dragon_variant_name, Color(0.9, 0.7, 0.3))

func _on_dragon_phase_3_climax():
	"""Phase 3: Dragon at 25% HP. Offers Final Choice."""
	var threshold = floor10_template.get_dragon_config().get("phase_3", {}).get("hp_threshold", 0.25)
	if float(dragon_hp) / dragon_max_hp > threshold:
		return

	dragon_phase = 3

	_show_dialogue(dragon_variant_name, "I am not your enemy.\nI am your mirror.\n\nKill me, and the tower ends —\nbut the Compiler will build another,\nand you will climb again,\nbecause you do not know how to stop.\n\nTake my place, and the tower continues —\nbut you will wait for someone worthy to end it,\nand they never come,\nbecause you have taught them that deals are easier than fights.\n\nOr... walk away.\nIf you can.\nIf you have ever been able to.\n\nYou cannot.\nYou signed that away in Floor 7.")

	_show_notification("👑 FINAL CHOICE: [D]estroy | [B]ecome | [W]alk Away", Color(0.9, 0.7, 0.3))

	# Check if true ending door is available
	if crack_revealed and player_attacked_in_phase_1 and not GameState.get_value("final_pact_signed", false):
		_show_notification("🔮 HIDDEN DOOR available! [H] to enter!", Color(0.3, 0.3, 0.9))

func _update_dragon_display():
	if not dragon_ui:
		return

	var text = ""
	if cano_protocol_triggered:
		text = "⚠ CANO PROTOCOL — NO DRAGON"
		dragon_ui.add_theme_color_override("font_color", Color(0.3, 0.3, 0.9))
	else:
		match dragon_phase:
			1:
				text = "🐉 %s: Phase 1 — Revelation | %d/%d HP" % [dragon_variant_name.to_upper(), dragon_hp, dragon_max_hp]
				if player_attacked_in_phase_1:
					text += " [ATTACKED]"
			2:
				text = "🐉 %s: Phase 2 — Test | %d/%d HP" % [dragon_variant_name.to_upper(), dragon_hp, dragon_max_hp]
			3:
				text = "🐉 %s: Phase 3 — Climax | %d/%d HP" % [dragon_variant_name.to_upper(), dragon_hp, dragon_max_hp]
				if crack_revealed:
					text += " [CRACK]"

		dragon_ui.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

	dragon_ui.text = text
	dragon_ui.visible = current_moment >= 9

# -------------------------------------------------------------------
# Final Choice System (False Endings)
# -------------------------------------------------------------------

func _choose_ending(ending_id: String):
	"""Player makes the final choice."""
	ending_chosen = ending_id
	final_choice_made = true

	var config = floor10_template.get_ending_config()
	var ending = config.get(ending_id)
	if not ending:
		return

	match ending_id:
		"destroy_dragon":
			_ending_destroy_dragon()
		"become_dragon":
			_ending_become_dragon()
		"walk_away":
			_ending_walk_away()
		"true_ending":
			_ending_true()

func _ending_destroy_dragon():
	"""Ending A: Destroy the Dragon."""
	_show_dialogue("Ending: End the Cycle", "Dragon dies.\nTower collapses in cutscene.\nPlayer escapes.\n\nAll souls freed.\nAll pacts broken.\nAll transformations reversed.\n\nCredits roll.\nPost-credits: a new tower appears on the horizon.\nSomeone else begins to climb.\n\nNew Game+ unlocked.\nYou keep nothing but knowledge.\nOne piece of advice appears in each floor of the next run.\n\nThe Compiler is still running.\nThe tower will respawn.\nYou ended a symptom, not the disease.")

	GameState.save_suffix = "ENDED_THE_CYCLE"
	GameState.ng_plus_unlocked = true
	GameState.false_ending_seen = true

	_show_notification("🏁 FALSE ENDING: End the Cycle — NG+ Unlocked", Color(0.9, 0.7, 0.3))
	_end_game()

func _ending_become_dragon():
	"""Ending B: Become the Dragon."""
	_show_dialogue("Ending: Become the Dragon", "Player ascends the throne.\nBecomes the new source of the tower's power.\n\nGame continues — but now you ARE the final boss.\nThe 'restart' is a New Game+ where the previous run's player character appears as a ghost boss in Floor 10, using the deck they built.\n\nYou think you 'won' by becoming god.\nYou have actually become the Compiler's newest process.\nThe Cano Protocol now runs in your body.\n\nNew Game+ where previous run's build becomes the Dragon's deck.\nEach run stacks.\n\nThis choice PERMANENTLY locks the true ending for all future runs until you reset your save.")

	GameState.save_suffix = "BECAME_THE_TOWER"
	GameState.ng_plus_unlocked = true
	GameState.true_ending_locked = true
	GameState.become_ending_chosen = true

	_show_notification("🏁 FALSE ENDING: Become the Dragon — NG+ Unlocked (True Ending LOCKED)", Color(0.9, 0.3, 0.3))
	_end_game()

func _ending_walk_away():
	"""Ending C: Walk Away (only for Liberator + no pacts + no reforging)."""
	if not _can_walk_away():
		_show_notification("You cannot walk away. You signed that away in Floor 7.", Color(0.9, 0.3, 0.3))
		return

	_show_dialogue("Ending: Walk Away", "Player leaves the tower through a door that was always there but never visible.\n\nDragon lets them go.\n'You were never meant to climb.\nYou were meant to leave.'\n\nNo New Game+.\nExile Mode unlocks.\nA completely different game.\n\nThe most subtle trap.\nThis looks like enlightenment.\nBut the Compiler is still running.\nThe tower still stands.\nThe door was always there because the Compiler put it there —\nto filter out the ones who wouldn't fight.")

	GameState.save_suffix = "WALKED_AWAY"
	GameState.exile_mode_unlocked = true

	_show_notification("🏁 FALSE ENDING: Walk Away — Exile Mode Unlocked", Color(0.3, 0.9, 0.3))
	_end_game()

func _can_walk_away() -> bool:
	"""Check if player meets Walk Away conditions."""
	return (
		GameState.get_value("liberator_status", false) and
		GameState.get_value("pacts_signed_count", 0) == 0 and
		not GameState.get_value("reforging_accepted", false)
	)

func _enter_hidden_door():
	"""Enter the hidden door behind the throne — true ending path."""
	if not crack_revealed:
		_show_notification("No hidden door visible", Color(0.7, 0.7, 0.7))
		return

	if not player_attacked_in_phase_1:
		_show_notification("The crack is there, but you didn't earn it.", Color(0.9, 0.3, 0.3))
		return

	if GameState.get_value("final_pact_signed", false):
		_show_notification("The door is there, but invisible to the marked.", Color(0.9, 0.3, 0.3))
		return

	# True ending path — Cano Protocol
	_show_notification("🔮 Entering hidden door... The Compiler awaits.", Color(0.3, 0.3, 0.9))
	_start_cano_fight()

# -------------------------------------------------------------------
# Cano Protocol (True Final Boss)
# -------------------------------------------------------------------

func _start_cano_fight():
	"""Begin the Cano Protocol encounter."""
	cano_protocol_triggered = true
	cano_phase = 1
	cano_hp = 50
	cano_archive_remaining = 50
	cano_ability_index = 0

	_show_dialogue("The Cano Protocol", "RUN COUNT DETECTED: %d.\nDRAGON DECK STATE: 50/50.\nLOCKED.\n\nYOU HAVE FILLED THE TOWER WITH YOURSELF.\nNOW YOU FACE WHAT YOU BUILT.\n\nThe Protocol displays your Docket on the walls.\nEvery choice. Every compromise. Every 'victory.'\nAcross ALL runs.\n\n'You thought purity was the answer.\nYou thought corruption was the answer.\nYou thought leaving was the answer.\nYou kept playing.\nThe only variable that changed was your belief that you had chosen.'")

	_show_notification("⚠ THE CANO PROTOCOL — DEBUG aura active!", Color(0.3, 0.3, 0.9))
	_update_cano_display()
	print("[Floor10] Cano Protocol fight started!")

func _on_cano_phase_1_diagnosis():
	"""Phase 1: Protocol explains. No combat yet."""
	_show_dialogue("The Cano Protocol", "The Compiler does not appear on your first run.\nIt appears when you have done enough runs that the Dragon's deck has accumulated 50 cards from your previous builds.\n\nEach run ending archives your deck to the Dragon's deck.\nDragon deck caps at 50. When it hits 50, the deck locks.\n\nOn the next run, when you reach Floor 10: There is no Dragon.\nThe throne is empty.\nThe door behind it is already open.\n\nBehind it: me.\n\nThe Dragon was never the final boss.\nThe Dragon was the loading screen.")

	# Transition to combat
	cano_phase = 2
	_show_notification("⚠ Phase 2 — OVERRIDE initiated!", Color(0.9, 0.3, 0.3))

func _on_cano_phase_2_override():
	"""Phase 2: Combat with Cano Protocol."""
	var config = floor10_template.get_cano_config()
	var abilities = config.get("abilities_cycle", [])
	if abilities.is_empty():
		return

	var ability = abilities[cano_ability_index]
	var ability_name = ability.get("name", "")

	match ability_name:
		"MEMORY_LEAK":
			_cano_memory_leak()
		"STACK_OVERFLOW":
			_cano_stack_overflow()
		"GARBAGE_COLLECTION":
			_cano_garbage_collection()

	# Advance ability index
	cano_ability_index = (cano_ability_index + 1) % abilities.size()
	_update_cano_display()

func _cano_memory_leak():
	"""Memory Leak: Convert Quiddity to damage."""
	var quiddity = GameState.get_value("quiddity", 0)
	var damage = quiddity / 2
	if quiddity == 0:
		damage = 5

	_show_notification("💧 MEMORY LEAK: %d Quiddity → %d damage!" % [quiddity, damage], Color(0.9, 0.3, 0.3))
	# Apply Protocol damage
	if GameState.has_method("damage_player"):
		GameState.damage_player(5)
	_show_notification("💥 Protocol damage! -5 HP!", Color(0.9, 0.3, 0.3))

func _cano_stack_overflow():
	"""Stack Overflow: Spawn Process Interrupt (copy of most-played card)."""
	var most_played = GameState.get_value("most_played_card", "Unknown")
	var card_cost = GameState.get_value("most_played_card_cost", 2)
	var hp = card_cost * 3

	_show_notification("💥 STACK OVERFLOW: Process Interrupt spawned! (%s, %d HP)" % [most_played, hp], Color(0.9, 0.5, 0.2))
	# TODO: Spawn Process Interrupt enemy
	_start_combat_with_enemies(["The Cano Protocol"])

func _cano_garbage_collection():
	"""Garbage Collection: Remove highest-cost card."""
	_show_notification("🗑 GARBAGE COLLECTION: Highest-cost card REMOVED!", Color(0.9, 0.7, 0.3))
	# TODO: Remove highest cost card from hand or deck
	_show_notification("🗑 Highest cost card removed from deck!", Color(0.9, 0.7, 0.3))

func _player_plays_void_card():
	"""Player plays a Void card — damages Cano Protocol."""
	var config = floor10_template.get_cano_config()
	var damage = config.get("damage_mechanic", {}).get("void_cards", 1)

	cano_hp -= damage
	cano_archive_remaining -= 1

	_show_notification("🌀 VOID HIT! Compiler -%d HP! Archive: %d remaining" % [damage, cano_archive_remaining], Color(0.3, 0.3, 0.9))

	if cano_archive_remaining <= 0:
		_cano_phase_3_permission_denied()

	_update_cano_display()

func _cano_phase_3_permission_denied():
	"""Phase 3: Archive empty. Final choice."""
	cano_phase = 3

	_show_dialogue("The Cano Protocol", "ARCHIVE EMPTY.\nNO PATTERNS DETECTED.\nYOU HAVE UNMADE YOURSELF.\n\nCONFIRM: END PROCESS?\nTHIS WILL END ALL FLOORS, ALL CHOICES, ALL MEMORIES, ALL RUNS.\n\nYES / NO")

	_show_notification("🔮 PERMISSION DENIED — The TRUE Final Choice", Color(0.3, 0.3, 0.9))
	_update_cano_display()

func _cano_confirm_end(yes: bool):
	"""Player chooses YES or NO on ending the process."""
	if yes:
		_show_dialogue("The Cano Protocol", "PROCESS ENDED.\n\nThe wireframe walls fill with color.\nThe tower crumbles — not in a cutscene, but in real time,\nfloor by floor, as you watch from the top.\n\nThe climb was real.\nThe ending is real.\n\nThe screen fades to black.\nNo credits.\nJust silence.\n\nThen, a single line:\n'The tower was never a place.\nIt was a question.\nYou answered.'")

		GameState.save_suffix = "STOPPED"
		GameState.cano_defeated = true
		GameState.true_ending_achieved = true

		_show_notification("🏁 TRUE ENDING: The Cano Protocol Defeated", Color(0.3, 0.9, 0.3))
		_end_game()
	else:
		_show_dialogue("The Cano Protocol", "PROCESS CONTINUES.\nTHANK YOU FOR YOUR PARTICIPATION.\n\nYou are returned to the main menu.\nYour save file is renamed: [PLAYERNAME]_SAVED_THE_TOWER.dat\n\nNew Game+ unlocks with a message:\n'The tower appreciates your loyalty.'")

		GameState.save_suffix = "SAVED_THE_TOWER"
		GameState.ng_plus_unlocked = true

		_show_notification("🔄 Process continues...", Color(0.9, 0.7, 0.3))
		_end_game()

func _update_cano_display():
	if not cano_ui:
		return

	var text = ""
	match cano_phase:
		1:
			text = "⚠ CANO: Phase 1 — Diagnosis"
		2:
			var abilities = floor10_template.get_cano_config().get("abilities_cycle", [])
			var current = abilities[cano_ability_index].get("name", "") if abilities.size() > 0 else ""
			text = "⚠ CANO: Phase 2 — Override | HP: %d | Archive: %d\nNext: %s" % [
				cano_hp, cano_archive_remaining, current
			]
		3:
			text = "⚠ CANO: Phase 3 — Permission Denied\nArchive: EMPTY"

	cano_ui.text = text
	cano_ui.visible = cano_protocol_triggered

	var color = Color(0.3, 0.3, 0.9)
	if cano_phase == 2:
		color = Color(0.9, 0.3, 0.3)
	elif cano_phase == 3:
		color = Color(0.9, 0.9, 0.3)
	cano_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		# Ghost interactions
		"Talk to Ghost":
			if current_moment <= 3:
				_spawn_ghost_boss(current_moment)

		# Hoard objects
		"Touch Blood Contract":
			_touch_hoard_object("blood_contract")
		"Touch Soul Gem":
			_touch_hoard_object("soul_gem")
		"Touch Reforged Blade":
			_touch_hoard_object("reforged_blade")
		"Touch Graduate Scroll":
			_touch_hoard_object("graduate_scroll")

		# Hoard alterations
		"Burn Contract":
			_alter_hoard_object("blood_contract")
		"Shatter Gem":
			_alter_hoard_object("soul_gem")
		"Melt Blade":
			_alter_hoard_object("reforged_blade")
		"Rewrite Scroll":
			_alter_hoard_object("graduate_scroll")

		# Weight
		"Reveal Weight":
			_reveal_weight()

		# Aspects
		"Face Time Aspect":
			_start_aspect_combat("time")
		"Face Greed Aspect":
			_start_aspect_combat("greed")
		"Face Transformation Aspect":
			_start_aspect_combat("transformation")

		# Dragon
		"Face the Dragon":
			_start_dragon_fight()
		"Attack":
			if dragon_phase == 1:
				_player_attacks_dragon_phase_1()
		"Listen":
			if dragon_phase == 1:
				_player_listens_phase_1()

		# Final choices
		"Destroy the Dragon":
			_choose_ending("destroy_dragon")
		"Become the Dragon":
			_choose_ending("become_dragon")
		"Walk Away":
			_choose_ending("walk_away")
		"Enter Hidden Door":
			_enter_hidden_door()

		# Cano Protocol
		"Face the Compiler":
			if cano_protocol_triggered:
				_on_cano_phase_1_diagnosis()
		"YES — End Process":
			if cano_phase == 3:
				_cano_confirm_end(true)
		"NO — Continue":
			if cano_phase == 3:
				_cano_confirm_end(false)
		"Open Shop":
			_open_shop()

		# Cross-floor NPCs
		"Talk to Shortcut Maker":
			_show_dialogue("Shortcut Maker", "Last chance to take the back door.\nI keep my promises.\nSkip to the choice immediately?\n...but the Dragon will be at full power.")
		"Talk to Janitor":
			_show_dialogue("Goblin Janitor", "You helped me. I help you.\nThe Dragon's true HP is...\n%s" % dragon_hp)
			# TODO: Reveal true HP
			_show_notification("👁 True HP revealed: %d/%d" % [dragon_hp, dragon_max_hp], Color(0.3, 0.9, 0.3))

		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.")

		_:
			super._on_object_interact(object_type)

# -------------------------------------------------------------------
# Combat Overrides
# -------------------------------------------------------------------

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	"""Override for aspect and Cano Protocol encounters."""
	# Check if this is an aspect fight
	if "aspect" in room_id:
		var aspect_id = rooms.get(room_id, {}).get("aspect", "")
		if aspect_id and aspect_id not in aspects_defeated:
			_start_aspect_combat(aspect_id)
			return

	# Check if this is the Dragon
	if room_id == "moment_10_revelation" and not cano_protocol_triggered:
		_start_dragon_fight()
		return

	# Check if this is Cano Protocol
	if room_id == "moment_10_revelation" and cano_protocol_triggered:
		_start_cano_fight()
		return

	# Check for cross-floor effects in combat
	for condition in cross_floor_dialogue.keys():
		var effect = cross_floor_dialogue[condition]
		if effect.has("dragon_attacks_50_percent_miss"):
			_show_notification("🪞 Infinity Mirror active! 50% miss chance on Dragon!", Color(0.3, 0.9, 0.3))

	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to handle aspect defeat and boss transitions."""
	# Disconnect dragon damage signal if connected
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if combat_manager and combat_manager.enemy_damaged.is_connected(_on_dragon_damaged_in_combat):
		combat_manager.enemy_damaged.disconnect(_on_dragon_damaged_in_combat)
	
	if not victory:
		super._on_combat_ended(victory)
		return

	# Check aspect defeat
	if aspect_current and aspect_current not in aspects_defeated:
		_on_aspect_defeated(aspect_current)
		aspect_current = ""
		return

	# Check Dragon combat outcome
	if current_room_id == "moment_10_revelation" and not cano_protocol_triggered:
		# If dragon is dead (0 HP or below), player destroyed it
		if dragon_hp <= 0:
			_choose_ending("destroy_dragon")
			return
		
		# If dragon HP is at or below threshold, trigger Phase 3 climax choice
		var threshold = floor10_template.get_dragon_config().get("phase_3", {}).get("hp_threshold", 0.25)
		if float(dragon_hp) / dragon_max_hp <= threshold and dragon_phase < 3:
			_on_dragon_phase_3_climax()
			return

	# Check Cano Protocol defeat
	if cano_protocol_triggered and cano_archive_remaining <= 0 and cano_phase < 3:
		_cano_phase_3_permission_denied()
		return

	super._on_combat_ended(victory)

func _on_combat_turn_advanced():
	"""Override for Dragon and Cano Protocol turn logic."""
	# Cano Protocol ability cycle
	if cano_protocol_triggered and cano_phase == 2:
		_on_cano_phase_2_override()

	# Dragon phase 2 combat
	if current_room_id == "moment_10_revelation" and dragon_phase == 2 and not cano_protocol_triggered:
		# Dragon attacks based on Phase 1 choice
		if player_attacked_in_phase_1:
			_show_notification("🐉 Dragon attacks! Telegraphed — you see it coming!", Color(0.9, 0.7, 0.3))
		else:
			_show_notification("🐉 Dragon attacks! But you know its patterns!", Color(0.3, 0.9, 0.3))

	# Update displays
	_update_dragon_display()
	_update_aspect_display()
	_update_cano_display()

# -------------------------------------------------------------------
# Game End
# -------------------------------------------------------------------

func _end_game():
	"""End the game with chosen ending. Show VictoryScreen and return to title or start NG+."""
	print("[Floor10] GAME ENDED — Ending: %s" % ending_chosen)

	# Save final state
	GameState.save_game()

	# Show VictoryScreen for NG+ / return to title
	var victory_screen = VictoryScreen.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_screen.return_to_title_requested.connect(func():
		victory_screen.queue_free()
		# Return to title screen
		var title_screen = TitleScreen.new()
		title_screen.name = "TitleScreen"
		title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		title_screen.new_game_started.connect(func():
			get_tree().change_scene_to_file("res://scenes/Floor1.tscn")
		)
		title_screen.continue_game_started.connect(func():
			var current_floor = GameState.current_floor
			var scene_path = TitleScreen.FLOOR_DATA.get(current_floor, {}).get("scene", "res://scenes/Floor1.tscn")
			get_tree().change_scene_to_file(scene_path)
		)
		get_tree().current_scene.add_child(title_screen)
		title_screen.show_title()
	)
	victory_screen.new_game_plus_requested.connect(func():
		victory_screen.queue_free()
		# Start NG+ — GameState.new_game() already handles survivor archiving and deck rebuild
		GameState.new_game()
		get_tree().change_scene_to_file("res://scenes/Floor1.tscn")
	)
	get_tree().current_scene.add_child(victory_screen)
	victory_screen.show_victory()

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_player_weight() -> int:
	return player_weight

func get_ending_chosen() -> String:
	return ending_chosen

func is_cano_protocol_triggered() -> bool:
	return cano_protocol_triggered

func get_aspects_defeated() -> Array:
	return aspects_defeated.duplicate()

func get_hoard_objects_touched() -> Dictionary:
	return hoard_objects_touched.duplicate()

func did_player_attack_in_phase_1() -> bool:
	return player_attacked_in_phase_1

func is_crack_revealed() -> bool:
	return crack_revealed
