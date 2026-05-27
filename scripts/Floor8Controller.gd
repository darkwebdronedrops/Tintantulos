extends FloorController

# ===================================================================
# FLOOR 8 CONTROLLER — The Overclock Forge
# Refactored to use FloorController base class + Floor8Template
# ===================================================================
# Adds: Overclock meter, Elemental Charge, Containment vessels,
#       Goblin morale, Chief Engineer Blix boss, Padlock door puzzle
# ===================================================================

@onready var floor8_template: Floor8Template = Floor8Template.new()

# Overclock State
var overclock: int = 0
var overclock_max: int = 999
var current_overclock_tier: String = "low"
var misfire_active: bool = false

# Elemental Charge State
var elemental_charge: Dictionary = {
	"fire": 0, "water": 0, "earth": 0, "air": 0
}
var elemental_charge_max: int = 10

# Containment Vessel State
var room_vessel_count: Dictionary = {}
var vessel_states: Dictionary = {}  # room_id -> Array of vessel states
var vessels_vented: int = 0
var vessels_overclocked: int = 0
var vessels_patched: int = 0
var all_vessels_vented: bool = false

# Goblin Morale State
var active_goblin_count: int = 0
var goblin_leader_alive: bool = false
var goblin_morale_broken: bool = false

# Boss State (Chief Engineer Blix)
var blix_phase: int = 1
var blix_hp: int = 55
var blix_max_hp: int = 55
var blix_surrendered: bool = false
var meltdown_timer: int = 10
var scram_pulled: bool = false
var reactor_critical: bool = false

# Padlock Door State
var padlocks_remaining: int = 17
var padlock_keys_found: Array[String] = []
var padlock_door_open: bool = false
var cache_looted: bool = false

# Cross-Floor Bleed
var blix_recognizes_contracts: bool = false
var blix_indifferent: bool = false
var shaman_fascinated: bool = false
var elementals_angry: bool = false

# UI References
var overclock_ui: Label
var elemental_ui: Label
var containment_ui: Label
var blix_ui: Label
var meltdown_ui: Label

func _ready():
	floor_template = floor8_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Initialize overclock
	overclock = 0
	_update_overclock_tier()

	# Initialize elemental charge
	elemental_charge = {"fire": 0, "water": 0, "earth": 0, "air": 0}
	
	# Add shop kiosk
	var kiosk = Node2D.new()
	kiosk.name = "ShopKiosk"
	kiosk.position = Vector2(500, 400)
	add_child(kiosk)
	print("[Floor8] Shop kiosk added")

	# Initialize vessels per room
	var config = floor8_template.get_containment_config()
	var counts = config.get("vessel_count_per_room", {})
	for room_id in counts.keys():
		room_vessel_count[room_id] = counts[room_id]
		vessel_states[room_id] = []
		for i in range(counts[room_id]):
			vessel_states[room_id].append({"index": i, "state": "contained", "elemental_type": _random_elemental_type()})

	# Check cross-floor bleed from Floor 7
	if GameState.get_value("marked_debuff_active", false):
		blix_recognizes_contracts = true
		_show_notification("📜 Blix recognizes your demon contracts", Color(0.9, 0.3, 0.9))

	if GameState.get_value("pacts_broken_count", 0) > 0:
		blix_indifferent = true

	if GameState.get_value("void_bond_active", false):
		shaman_fascinated = true

	if GameState.get_value("souls_enslaved_count", 0) > 0:
		elementals_angry = true
		_show_notification("⚠ Elementals are angrier (+1 CHARGE)", Color(0.9, 0.7, 0.3))

	# Padlock door
	var padlock_config = floor8_template.get_padlock_config()
	padlocks_remaining = padlock_config.get("padlock_count", 17)

	print("[Floor8] Setup complete. OC: %d | Vessels: %d | Blix contracts: %s" % [
		overclock, _total_vessel_count(), blix_recognizes_contracts
	])

func _random_elemental_type() -> String:
	var types = ["fire", "water", "earth", "air"]
	return types[randi() % types.size()]

func _total_vessel_count() -> int:
	var total = 0
	for count in room_vessel_count.values():
		total += count
	return total

func _setup_floor_ui():
	# Overclock display
	overclock_ui = Label.new()
	overclock_ui.name = "OverclockUI"
	overclock_ui.position = Vector2(20, 20)
	overclock_ui.size = Vector2(400, 80)
	overclock_ui.add_theme_font_size_override("font_size", 12)
	add_child(overclock_ui)
	_update_overclock_display()

	# Elemental charge display
	elemental_ui = Label.new()
	elemental_ui.name = "ElementalUI"
	elemental_ui.position = Vector2(20, 110)
	elemental_ui.size = Vector2(350, 60)
	elemental_ui.add_theme_font_size_override("font_size", 11)
	add_child(elemental_ui)
	_update_elemental_display()

	# Containment vessel display
	containment_ui = Label.new()
	containment_ui.name = "ContainmentUI"
	containment_ui.position = Vector2(20, 180)
	containment_ui.size = Vector2(350, 40)
	containment_ui.add_theme_font_size_override("font_size", 11)
	add_child(containment_ui)
	_update_containment_display()

	# Blix / boss display
	blix_ui = Label.new()
	blix_ui.name = "BlixUI"
	blix_ui.position = Vector2(20, 230)
	blix_ui.size = Vector2(400, 40)
	blix_ui.add_theme_font_size_override("font_size", 12)
	blix_ui.visible = false
	add_child(blix_ui)

	# Meltdown timer display
	meltdown_ui = Label.new()
	meltdown_ui.name = "MeltdownUI"
	meltdown_ui.position = Vector2(20, 280)
	meltdown_ui.size = Vector2(400, 40)
	meltdown_ui.add_theme_font_size_override("font_size", 12)
	meltdown_ui.visible = false
	add_child(meltdown_ui)

func _update_floor_ui():
	_update_overclock_display()
	_update_elemental_display()
	_update_containment_display()
	if blix_phase > 1:
		_update_blix_display()
		_update_meltdown_display()

# -------------------------------------------------------------------
# Overclock Meter System
# -------------------------------------------------------------------

func _add_overclock(amount: int):
	"""Add overclock points and update tier."""
	overclock += amount
	_update_overclock_tier()
	_update_overclock_display()
	print("[Floor8] Overclock: %d (%s tier)" % [overclock, current_overclock_tier])

func _decay_overclock():
	"""Decay overclock when entering a room without combat."""
	var config = floor8_template.get_overclock_config()
	var decay = config.get("decay_per_room", 2)
	overclock = max(0, overclock - decay)
	_update_overclock_tier()
	_update_overclock_display()

func _update_overclock_tier():
	"""Determine current overclock tier and effects."""
	var config = floor8_template.get_overclock_config()
	var thresholds = config.get("thresholds", {})

	var new_tier = "low"
	for tier_name in ["critical", "high", "medium", "low"]:
		var tier = thresholds.get(tier_name, {})
		var min_val = tier.get("min", 0)
		var max_val = tier.get("max", 999)
		if overclock >= min_val and overclock < max_val:
			new_tier = tier_name
			break

	if new_tier != current_overclock_tier:
		current_overclock_tier = new_tier
		_on_overclock_tier_change(new_tier)

func _on_overclock_tier_change(tier: String):
	"""Handle tier transition effects."""
	match tier:
		"medium":
			_show_notification("⚡ OVERCLOCK 10+ — Cards cost 1 less!", Color(0.9, 0.7, 0.3))
		"high":
			_show_notification("⚡ OVERCLOCK 15+ — Cards cost 1 less, 25% misfire!", Color(0.9, 0.5, 0.2))
		"critical":
			_show_notification("⚡ OVERCLOCK 20+ — Cards cost 2 less, 50% misfire, elemental damage DOUBLED!", Color(0.9, 0.2, 0.2))
			# Check if Blix should surrender
			if blix_phase >= 3 and not blix_surrendered:
				_blix_surrender()

func _get_card_cost_reduction() -> int:
	var config = floor8_template.get_overclock_config()
	var thresholds = config.get("thresholds", {})
	var tier = thresholds.get(current_overclock_tier, {})
	return tier.get("card_cost_reduction", 0)

func _get_misfire_chance() -> float:
	var config = floor8_template.get_overclock_config()
	var thresholds = config.get("thresholds", {})
	var tier = thresholds.get(current_overclock_tier, {})
	return tier.get("misfire_chance", 0.0)

func _get_elemental_multiplier() -> float:
	var config = floor8_template.get_overclock_config()
	var thresholds = config.get("thresholds", {})
	var tier = thresholds.get(current_overclock_tier, {})
	return tier.get("elemental_multiplier", 1.0)

func _check_misfire() -> bool:
	"""Check if current card play misfires (random target)."""
	if randf() < _get_misfire_chance():
		misfire_active = true
		_show_notification("💥 MISFIRE! Random target!", Color(0.9, 0.5, 0.2))
		return true
	return false

func _update_overclock_display():
	if not overclock_ui:
		return

	var tier_display = current_overclock_tier.to_upper()
	var reduction = _get_card_cost_reduction()
	var misfire = int(_get_misfire_chance() * 100)
	var elemental_mult = _get_elemental_multiplier()

	var text = "⚡ OVERCLOCK: %d [%s]\n" % [overclock, tier_display]
	text += "Cards: -%d cost | Misfire: %d%% | Elemental: %.1fx" % [
		reduction, misfire, elemental_mult
	]

	var color = Color(0.8, 0.8, 0.8)
	match current_overclock_tier:
		"low": color = Color(0.5, 0.8, 0.5)
		"medium": color = Color(0.9, 0.7, 0.3)
		"high": color = Color(0.9, 0.5, 0.2)
		"critical": color = Color(0.9, 0.2, 0.2)

	overclock_ui.text = text
	overclock_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Elemental Charge System
# -------------------------------------------------------------------

func _add_elemental_charge(element: String, amount: int):
	"""Add charge to a specific element."""
	if not elemental_charge.has(element):
		return

	var config = floor8_template.get_elemental_charge_config()
	var max_c = config.get("max_charge", 10)

	elemental_charge[element] = mini(elemental_charge[element] + amount, max_c)
	_update_elemental_display()
	print("[Floor8] %s charge: %d/%d" % [element, elemental_charge[element], max_c])

func _consume_elemental_charge(element: String, amount: int) -> int:
	"""Consume charge from an element, return actual amount consumed."""
	if not elemental_charge.has(element):
		return 0

	var consumed = mini(amount, elemental_charge[element])
	elemental_charge[element] -= consumed
	_update_elemental_display()
	return consumed

func _get_dominant_element() -> String:
	"""Get the element with highest charge."""
	var max_charge = -1
	var dominant = "fire"
	for element in elemental_charge.keys():
		if elemental_charge[element] > max_charge:
			max_charge = elemental_charge[element]
			dominant = element
	return dominant

func _update_elemental_display():
	if not elemental_ui:
		return

	var text = "🔥%d 💧%d 🪨%d 🌪️%d" % [
		elemental_charge["fire"], elemental_charge["water"],
		elemental_charge["earth"], elemental_charge["air"]
	]

	var dominant = _get_dominant_element()
	var color = Color(0.8, 0.8, 0.8)
	match dominant:
		"fire": color = Color(0.9, 0.4, 0.2)
		"water": color = Color(0.2, 0.5, 0.9)
		"earth": color = Color(0.6, 0.4, 0.2)
		"air": color = Color(0.7, 0.8, 0.9)

	elemental_ui.text = text
	elemental_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Containment Vessel System
# -------------------------------------------------------------------

func _interact_with_vessel(vessel_index: int, action: String):
	"""Player chooses an action on a containment vessel."""
	if not vessel_states.has(current_room_id):
		return

	var vessels = vessel_states[current_room_id]
	if vessel_index >= vessels.size():
		return

	var vessel = vessels[vessel_index]
	if vessel["state"] != "contained":
		_show_notification("Vessel already %s" % vessel["state"], Color(0.7, 0.7, 0.7))
		return

	var config = floor8_template.get_containment_config()
	var actions = config.get("actions", {})

	match action:
		"vent":
			_vent_vessel(vessel, vessel_index)
		"overclock":
			_overclock_vessel(vessel, vessel_index)
		"patch":
			_patch_vessel(vessel, vessel_index)

func _vent_vessel(vessel: Dictionary, index: int):
	"""Release elemental for immediate combat."""
	vessel["state"] = "vented"
	vessels_vented += 1

	var elemental_type = vessel.get("elemental_type", "fire")
	_show_notification("💨 Vessel vented! %s elemental released!" % elemental_type, Color(0.5, 0.8, 0.5))

	# Spawn combat with elemental
	var enemy_name = _elemental_type_to_enemy(elemental_type)
	_start_combat_with_enemies([enemy_name])

	# Add elemental charge
	_add_elemental_charge(elemental_type, 2)

	# Spawn combat with escaped elemental + goblin
	# Note: removed duplicate elemental_type declaration
	enemy_name = _elemental_type_to_enemy(elemental_type)
	_start_combat_with_enemies([enemy_name, "Alarm Ringer"])

	# Check if all vented
	_check_all_vessels_status()
	_update_containment_display()

func _overclock_vessel(vessel: Dictionary, index: int):
	"""Empower elemental before release."""
	var config = floor8_template.get_containment_config()
	var actions = config.get("actions", {})
	var overclock_cost = actions.get("overclock", {}).get("cost_overclock", 3)

	if overclock < overclock_cost:
		_show_notification("Need %d Overclock to overclock vessel" % overclock_cost, Color(0.9, 0.3, 0.3))
		return

	overclock -= overclock_cost
	vessel["state"] = "overclocked"
	vessels_overclocked += 1

	var elemental_type = vessel.get("elemental_type", "fire")
	_show_notification("⚡ OVERCLOCKED! %s elemental empowered (+2 CHARGE, better loot)!" % elemental_type, Color(0.9, 0.5, 0.2))

	# Spawn harder combat with better loot
	var enemy_name = _elemental_type_to_enemy(elemental_type)
	_start_combat_with_enemies([enemy_name, "Containment Goblin"])

	# Add more elemental charge
	_add_elemental_charge(elemental_type, 4)

	_update_overclock_display()
	_check_all_vessels_status()
	_update_containment_display()

func _patch_vessel(vessel: Dictionary, index: int):
	"""Seal containment, skip fight, gain minor loot."""
	var config = floor8_template.get_containment_config()
	var actions = config.get("actions", {})
	var gem_cost = actions.get("patch", {}).get("cost_gems", 5)

	if GameState.gems < gem_cost:
		_show_notification("Need %d Gems to patch vessel" % gem_cost, Color(0.9, 0.3, 0.3))
		return

	GameState.gems -= gem_cost
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)

	vessel["state"] = "patched"
	vessels_patched += 1

	_show_notification("🔧 Patched! Minor loot gained (%d gems spent)" % gem_cost, Color(0.3, 0.9, 0.3))

	# Give minor loot
	# TODO: Give minor loot

	_check_all_vessels_status()
	_update_containment_display()

func _elemental_type_to_enemy(element: String) -> String:
	match element:
		"fire": return "Steam Mote"
		"water": return "Pressure Knot"
		"earth": return "Glass Wraith"
		"air": return "Ion Howler"
		_: return "Steam Mote"

func _check_all_vessels_status():
	"""Check if all vessels have been handled."""
	var total = _total_vessel_count()
	var handled = vessels_vented + vessels_overclocked + vessels_patched

	if vessels_vented == total and total > 0:
		all_vessels_vented = true
		_show_notification("💨 ALL VESSELS VENTED! Elementals loose!", Color(0.9, 0.7, 0.3))

func _update_containment_display():
	if not containment_ui:
		return

	var current_room_vessels = vessel_states.get(current_room_id, [])
	var contained = 0
	for v in current_room_vessels:
		if v["state"] == "contained":
			contained += 1

	if current_room_vessels.is_empty():
		containment_ui.text = "🔧 No vessels in this room"
	else:
		containment_ui.text = "🔧 Vessels: %d contained | %d vented | %d overclocked | %d patched" % [
			contained, vessels_vented, vessels_overclocked, vessels_patched
		]

# -------------------------------------------------------------------
# Goblin Morale System
# -------------------------------------------------------------------

func _update_goblin_morale(goblin_count: int, has_leader: bool):
	"""Update goblin morale state based on group composition."""
	active_goblin_count = goblin_count
	goblin_leader_alive = has_leader

	var config = floor8_template.get_goblin_morale_config()
	var threshold = config.get("group_threshold", 3)
	var overlock_threshold = config.get("overlock_terrified_threshold", 15)

	# Check if goblins should flee
	if goblin_count < threshold and not has_leader:
		var cower_chance = config.get("pair_cower_chance", 0.50)
		if overclock >= overlock_threshold:
			# Overclock too high — goblins fight to death
			_show_notification("😱 Goblins are TERRIFIED by your chaos! They fight to the death!", Color(0.9, 0.3, 0.3))
		else:
			_show_notification("😰 Goblin morale broken! %d%% chance to flee/cower" % int(cower_chance * 100), Color(0.9, 0.7, 0.3))

	if goblin_count >= threshold:
		var bonus = config.get("group_damage_bonus", 2)
		_show_notification("😈 Goblin group! +%d damage, cannot flee!" % bonus, Color(0.9, 0.3, 0.3))

func _on_goblin_leader_killed():
	"""When the leader goblin dies, test morale for remaining goblins."""
	goblin_leader_alive = false
	var config = floor8_template.get_goblin_morale_config()
	var panic_chance = config.get("leader_death_panic_chance", 0.50)

	_show_notification("💀 Chief Handler killed! Goblins panic (%d%% flee)!" % int(panic_chance * 100), Color(0.9, 0.7, 0.3))
	# TODO: Apply flee chance to remaining goblins

# -------------------------------------------------------------------
# Boss System — Chief Engineer Blix (3 Phases)
# -------------------------------------------------------------------

func _start_boss_fight():
	"""Begin Chief Engineer Blix boss encounter."""
	blix_phase = 1
	blix_hp = blix_max_hp
	blix_surrendered = false
	scram_pulled = false
	reactor_critical = false
	meltdown_timer = 10

	# Blix intro dialogue
	var intro = "Chief Engineer Blix, at your service!\nI've lost three arms, two legs, one eye, and my sense of fear to this reactor.\nAnd I've never been happier!\nNow — are you here to vent, overclock, or explode?"

	if blix_recognizes_contracts:
		intro += "\n\nOoh, contracts! I got a contract too! Wanna trade?"
	elif blix_indifferent:
		intro += "\n\nDemons are boring. They don't explode. I like exploding."

	_show_dialogue("Chief Engineer Blix", intro)

	_update_blix_display()
	_update_meltdown_display()
	print("[Floor8] Boss fight started — Phase 1: The Shift")

func _on_blix_phase_1_shift():
	"""Phase 1: Blix runs between consoles, releasing elementals in waves."""
	# Blix doesn't attack directly — she supercharges elementals
	# TODO: Spawn goblin engineers + release elementals periodically
	_show_notification("⚡ Blix supercharges an elemental!", Color(0.9, 0.5, 0.2))

	# Add overclock from chaos
	_add_overclock(3)

func _on_blix_phase_2_meltdown():
	"""Phase 2: Blix fuses with reactor. Direct attacks."""
	blix_phase = 2
	_show_dialogue("Chief Engineer Blix", "The reactor's singing! That's bad!\nWhen it sings, it means it's about to hit the high note!\nPULL THE LEVER! SCRAM IT!\nUnless... you want to see what happens?")

	# Blix now attacks directly, builds CHARGE in player
	_show_notification("😈 Blix enters meltdown! Direct attacks!", Color(0.9, 0.2, 0.2))
	print("[Floor8] Phase 2: The Meltdown")

func _on_blix_phase_3_scram():
	"""Phase 3: Scram offer or meltdown race."""
	blix_phase = 3
	reactor_critical = true

	# Check for surrender
	if overclock > 20 and not blix_surrendered:
		_blix_surrender()
		return

	_show_dialogue("Chief Engineer Blix", "PULL THE SCRAM LEVER!\nEverything stops!\nOr... let it blow. Ten turns.\nPure DPS race.")

	_show_notification("⏱ MELTDOWN TIMER: 10 turns!", Color(0.9, 0.2, 0.2))
	_update_meltdown_display()
	print("[Floor8] Phase 3: The Scram")

func _blix_surrender():
	"""Blix surrenders to high overclock player."""
	blix_surrendered = true
	blix_hp = 0

	_show_dialogue("Chief Engineer Blix", "You're at... twenty-three overclock?\nTwenty-FOUR?\nHow are you still standing?\nThe walls are melting just looking at you.\nOkay. You win. Take the core.\nI'm going to find a new job.\nSomewhere with fewer explosions.\nLike a volcano.")

	# Give elemental core
	var config = floor8_template.get_boss_config()
	var core = config.get("core_reward", "elemental_core")
	GameState.elemental_core_held = true

	_show_notification("🔥 ELEMENTAL CORE acquired! +1 fire damage all cards!", Color(0.9, 0.4, 0.2))

	# End combat
	_end_boss_combat(true)

func _pull_scram_lever():
	"""Pull the scram lever — boss dies instantly, player takes radiation damage."""
	if scram_pulled:
		return

	scram_pulled = true
	var config = floor8_template.get_boss_config()
	var damage = config.get("scram_damage_to_player", 15)

	_show_notification("☢ SCRAM! Blix dies! You take %d radiation damage!" % damage, Color(0.9, 0.9, 0.3))

	# Apply radiation damage
	if GameState.has_method("damage_player"):
		GameState.damage_player(damage)
	_show_notification("☢ Radiation damage! -%d HP!" % damage, Color(0.9, 0.3, 0.3))

	# Boss dies
	blix_hp = 0
	_end_boss_combat(true)

func _destroy_coolant_pipe():
	"""Destroy coolant pipe to vent player CHARGE."""
	var vented = _consume_elemental_charge(_get_dominant_element(), 3)
	_show_notification("💨 Coolant pipe destroyed! Vented %d CHARGE!" % vented, Color(0.3, 0.9, 0.3))
	# Reduce player CHARGE damage
	_show_notification("💨 CHARGE vented! Damage reduced!", Color(0.3, 0.9, 0.3))

func _advance_meltdown_timer():
	"""Advance meltdown timer during Phase 3."""
	if not reactor_critical or scram_pulled or blix_surrendered:
		return

	meltdown_timer -= 1
	_show_notification("⏱ MELTDOWN: %d turns remaining!" % meltdown_timer, Color(0.9, 0.2, 0.2))

	if meltdown_timer <= 0:
		_meltdown_explosion()

	_update_meltdown_display()

func _meltdown_explosion():
	"""Reactor explodes — massive damage, game over or severe penalty."""
	_show_notification("💥 REACTOR EXPLOSION!", Color(0.9, 0.1, 0.1))
	# Apply massive damage — potential floor reset
	if GameState.has_method("damage_player"):
		GameState.damage_player(50)
	_show_notification("💥 Meltdown damage! -50 HP!", Color(0.9, 0.1, 0.1))

func _update_blix_display():
	if not blix_ui:
		return

	var text = ""
	match blix_phase:
		1:
			text = "BLIX: Phase 1 — The Shift | %d/%d HP" % [blix_hp, blix_max_hp]
		2:
			text = "BLIX: Phase 2 — The Meltdown | %d/%d HP" % [blix_hp, blix_max_hp]
		3:
			if blix_surrendered:
				text = "BLIX: SURRENDERED"
			elif scram_pulled:
				text = "BLIX: SCRAMMED"
			else:
				text = "BLIX: Phase 3 — The Scram | %d/%d HP" % [blix_hp, blix_max_hp]

	blix_ui.text = text
	blix_ui.visible = true

	var color = Color(0.9, 0.5, 0.2)
	if blix_surrendered:
		color = Color(0.3, 0.9, 0.3)
	elif scram_pulled:
		color = Color(0.9, 0.9, 0.3)

	blix_ui.add_theme_color_override("font_color", color)

func _update_meltdown_display():
	if not meltdown_ui:
		return

	if not reactor_critical or blix_phase < 3:
		meltdown_ui.visible = false
		return

	if blix_surrendered or scram_pulled:
		meltdown_ui.visible = false
		return

	meltdown_ui.text = "⏱ MELTDOWN: %d turns!" % meltdown_timer
	meltdown_ui.visible = true

	var color = Color(0.9, 0.7, 0.3)
	if meltdown_timer <= 5:
		color = Color(0.9, 0.3, 0.2)
	if meltdown_timer <= 3:
		color = Color(0.9, 0.1, 0.1)

	meltdown_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Padlock Door System
# -------------------------------------------------------------------

func _pick_padlock():
	"""Pick a padlock using Overclock."""
	if padlock_door_open:
		_show_notification("Door already open", Color(0.7, 0.7, 0.7))
		return

	var config = floor8_template.get_padlock_config()
	var pick_cost = config.get("pick_cost_overclock", 5)
	var alarm_chance = config.get("pick_alarm_chance", 0.3)

	if overclock < pick_cost:
		_show_notification("Need %d Overclock to pick" % pick_cost, Color(0.9, 0.3, 0.3))
		return

	overclock -= pick_cost
	padlocks_remaining -= 1

	_show_notification("🔓 Padlock picked! %d remaining" % padlocks_remaining, Color(0.3, 0.9, 0.3))

	# Alarm chance
	if randf() < alarm_chance:
		_show_notification("🚨 ALARM! Goblins incoming!", Color(0.9, 0.3, 0.3))
		# Spawn goblin encounter
		_start_combat_with_enemies(["Containment Goblin", "Alarm Ringer"])

	if padlocks_remaining <= 0:
		_open_padlock_door()

	_update_overclock_display()

func _use_padlock_key(room_id: String):
	"""Use a key found in a room to open a padlock."""
	if room_id in padlock_keys_found:
		_show_notification("Key from %s already used" % room_id, Color(0.7, 0.7, 0.7))
		return

	padlock_keys_found.append(room_id)
	padlocks_remaining -= 1

	_show_notification("🔑 Key used! %d padlocks remaining" % padlocks_remaining, Color(0.3, 0.9, 0.3))

	if padlocks_remaining <= 0:
		_open_padlock_door()

func _open_padlock_door():
	"""Open the padlock door to the Control Room."""
	padlock_door_open = true
	_show_notification("🚪 PADLOCK DOOR OPEN! Control Room accessible!", Color(0.3, 0.9, 0.3))

	# Unlock connection to control room
	var padlock_room = rooms.get("padlock_door")
	if padlock_room:
		padlock_room["connections"]["up"] = "control_room"

func _loot_padlock_cache():
	"""Loot the cache behind the padlock door."""
	if cache_looted:
		_show_notification("Cache already looted", Color(0.7, 0.7, 0.7))
		return

	var config = floor8_template.get_padlock_config()
	var loot = config.get("cache_loot", [])

	cache_looted = true
	_show_notification("💰 Cache looted! Overclocked cards + elemental shards!", Color(0.9, 0.7, 0.3))

	# TODO: Give loot items
	GameState.gems += 25
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)

# -------------------------------------------------------------------
# Union Negotiation
# -------------------------------------------------------------------

func _negotiate_union():
	"""Spend gems for safe passage through Union Hall."""
	var cost = 10
	if GameState.gems < cost:
		_show_notification("Need %d Gems to negotiate" % cost, Color(0.9, 0.3, 0.3))
		return

	GameState.gems -= cost
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)

	_show_notification("🤝 Union negotiated! Safe passage for %d gems" % cost, Color(0.3, 0.9, 0.3))
	# TODO: Set Union Hall as safe

func _intimidate_goblins():
	"""Intimidate goblins — fight, but they fight harder."""
	_show_notification("😠 Intimidated! Goblins fight harder!", Color(0.9, 0.3, 0.3))
	# TODO: Buff goblin stats

func _sabotage_equipment():
	"""Sabotage goblin equipment — they flee, but vessels rupture."""
	_show_notification("🔧 Equipment sabotaged! Goblins flee! Vessels rupture!", Color(0.9, 0.7, 0.3))
	# TODO: Make goblins flee, rupture all vessels in room

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		"Interact with Vessel":
			# Show vessel action menu
			_show_vessel_menu()

		"Vent Vessel":
			_vent_vessel(vessel_states[current_room_id][0], 0)

		"Overclock Vessel":
			_overclock_vessel(vessel_states[current_room_id][0], 0)

		"Patch Vessel":
			_patch_vessel(vessel_states[current_room_id][0], 0)

		"Pull Scram Lever":
			if blix_phase >= 3:
				_pull_scram_lever()
			else:
				_show_notification("Scram lever locked — reactor not critical", Color(0.7, 0.7, 0.7))

		"Destroy Coolant Pipe":
			_destroy_coolant_pipe()

		"Use Console":
			_show_notification("Console: Overclock %d | Elemental %s" % [overclock, _get_dominant_element()], Color(0.3, 0.9, 0.3))

		"Pick Lock":
			_pick_padlock()

		"Use Key":
			_use_padlock_key(current_room_id)

		"Open Cache":
			_loot_padlock_cache()

		"Talk to Engineer":
			_show_dialogue("Containment Goblin", "Don't touch the red pipe! Or the blue pipe! Or the hissing pipe!\nActually don't touch any pipes!\nThe whole room is pipes! Why are you here?!")

		"Talk to Ringer":
			_show_dialogue("Alarm Ringer", "Don't make me pull it.\nI WILL pull it.\nI'm not afraid!\n...I'm a little afraid.")

		"Talk to Shaman":
			if shaman_fascinated and GameState.get_value("void_bond_active", false):
				_show_dialogue("Overclock Shaman", "You mutate too! We should compare notes!\nTell me a combat story and I'll remove your mutation.\nFree! No strings! ...Okay, one string.")
				GameState.void_bond_active = false
				_show_notification("🌀 Void Bond mutation removed by Shaman!", Color(0.3, 0.9, 0.3))
			else:
				_show_dialogue("Overclock Shaman", "CHARGE! MORE CHARGE!\nThe elementals sing when they're full!\n...then they explode. But the singing is nice.")

		"Talk to Handler":
			_show_dialogue("Chief Handler", "Listen up, greenskins!\nWe work together, we live together!\nAnyone flees, I PERSONALLY feed them to the reactor!\n...it's a good motivator.")

		"Confront Blix":
			_start_boss_fight()

		"Negotiate Union":
			_negotiate_union()

		"Intimidate Goblins":
			_intimidate_goblins()

		"Sabotage Equipment":
			_sabotage_equipment()

		"Optimize Containment":
			_show_dialogue("Puzzle", "Three vessels.\nVent one, overclock one, patch one.\nCorrect combination = safe passage.\nWrong = elemental + goblin ambush.")
			# TODO: Actual puzzle logic

		"Read Gauge":
			_show_notification("Pressure: CRITICAL | Temperature: MELTING | Morale: NONEXISTENT", Color(0.9, 0.3, 0.3))

		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.")

		"Open Shop":
			_open_shop()
		_:
			super._on_object_interact(object_type)

func _show_vessel_menu():
	"""Show the vessel action selection UI."""
	# TODO: Show UI with Vent / Overclock / Patch options
	_show_notification("Vessel actions: [V]ent | [O]verclock | [P]atch", Color(0.8, 0.8, 0.8))

# -------------------------------------------------------------------
# Combat Overrides
# -------------------------------------------------------------------

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	"""Override to track goblin count and apply overclock bonuses."""
	# Count goblins
	var goblin_count = 0
	var has_leader = false
	for enemy_name in enemy_names:
		if "goblin" in enemy_name.to_lower() or "handler" in enemy_name.to_lower():
			goblin_count += 1
		if "chief" in enemy_name.to_lower() or "handler" in enemy_name.to_lower():
			has_leader = true

	_update_goblin_morale(goblin_count, has_leader)

	# Check for containment vessel auto-release in this room
	if vessel_states.has(room_id):
		for vessel in vessel_states[room_id]:
			if vessel["state"] == "contained" and randf() < 0.2:  # 20% chance to break free
				vessel["state"] = "vented"
				_show_notification("💥 Vessel ruptured! Elemental ambush!", Color(0.9, 0.5, 0.2))
				# Spawn elemental + goblin combat
				var elemental_type = vessel.get("elemental_type", "fire")
				var enemy_name = _elemental_type_to_enemy(elemental_type)
				_start_combat_with_enemies([enemy_name, "Containment Goblin"])

	# Apply elemental multiplier to damage
	var mult = _get_elemental_multiplier()
	if mult > 1.0:
		_show_notification("🔥 Elemental damage %.1fx from Overclock!" % mult, Color(0.9, 0.4, 0.2))

	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to apply post-combat overclock and elemental gains."""
	if not victory:
		# Decay overclock on defeat/retreat
		_decay_overclock()
		super._on_combat_ended(victory)
		return

	# Check if this was boss fight
	if current_room_id == "control_room":
		_end_boss_combat(victory)
		return

	# Add overclock from goblin kills
	var config = floor8_template.get_overclock_config()
	var goblin_bonus = config.get("goblin_kill_bonus", 2)
	var elemental_bonus = config.get("elemental_kill_bonus", 1)

	# TODO: Count actual defeated enemies by type
	# For now, add generic bonuses
	_add_overclock(goblin_bonus)

	# Add elemental charge from elemental kills
	# TODO: Determine which element based on defeated enemies
	_add_elemental_charge(_random_elemental_type(), elemental_bonus)

	# Check if Blix surrenders during regular combat (if player gets to 20+ OC before boss)
	if overclock > 20 and blix_phase == 0:
		_show_notification("⚡ Overclock critical! Blix might surrender if confronted!", Color(0.9, 0.2, 0.2))

	_update_overclock_display()
	_update_elemental_display()

	super._on_combat_ended(victory)

func _on_combat_turn_advanced():
	"""Override to process meltdown timer and Blix phases."""
	# Advance meltdown timer in Phase 3
	if current_room_id == "control_room" and blix_phase == 3:
		_advance_meltdown_timer()

	# Blix phase transitions
	if current_room_id == "control_room":
		var config = floor8_template.get_boss_config()
		var phase1_hp = config.get("phase_transition_hp_1", 35)
		var phase2_hp = config.get("phase_transition_hp_2", 15)

		if blix_phase == 1 and blix_hp <= phase1_hp:
			_on_blix_phase_2_meltdown()
		elif blix_phase == 2 and blix_hp <= phase2_hp:
			_on_blix_phase_3_scram()

		_update_blix_display()

	# Check misfire on card play
	if _check_misfire():
		pass  # Misfire handled in _check_misfire

	# Update displays
	_update_overclock_display()
	_update_elemental_display()
	_update_containment_display()

func _end_boss_combat(victory: bool):
	"""End the boss fight and handle transitions."""
	if victory:
		if blix_surrendered:
			_show_dialogue("The Tower", "Blix surrenders.\nThe elemental core is yours.\nThe path to Floor 9 opens.\nYou carry fire within you now.")
		elif scram_pulled:
			_show_dialogue("The Tower", "The reactor is dead.\nBlix is dead.\nThe forge is silent.\nThe path to Floor 9 opens — but something is missing.")
		else:
			_show_dialogue("The Tower", "Blix falls.\nThe reactor groans but holds.\nThe path to Floor 9 opens.\nRadiation lingers in your bones.")

		# Give rewards
		GameState.gems += 100
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)

		# Apply cross-floor effects
		_apply_floor9_effects()

		# Save progress
		GameState.save_game()

		# Show transition prompt
		_show_floor_transition_prompt()
		# Actually transition to Floor 9 after a short delay
		await get_tree().create_timer(3.0).timeout
		_ascend_to_next_floor()
	else:
		_show_notification("💀 Defeated by Chief Engineer Blix", Color(0.9, 0.3, 0.3))

func _apply_floor9_effects():
	"""Apply cross-floor bleed effects to Floor 9 based on Floor 8 outcome."""
	if scram_pulled:
		GameState.floor9_no_power = true
		GameState.floor9_foreman_enraged = true

	if not scram_pulled and blix_hp <= 0:
		GameState.floor9_radiation_debuff = true
		GameState.floor9_elementals_kin = true

	if blix_surrendered:
		GameState.elemental_core_held = true

	if all_vessels_vented:
		GameState.floor9_elementals_loose = true

# -------------------------------------------------------------------
# Floor Complete — Transition to Floor 9
# -------------------------------------------------------------------

func _show_floor_transition_prompt():
	"""Show prompt to ascend to Floor 9."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 9 — The Bone Forges"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

func _ascend_to_next_floor():
	"""Ascend to Floor 9."""
	print("[Floor8] Ascending to Floor 9...")
	get_tree().change_scene_to_file("res://scenes/Floor9.tscn")

# -------------------------------------------------------------------
# Input Override
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Base class input
	super._input(event)

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_overclock() -> int:
	return overclock

func get_overclock_tier() -> String:
	return current_overclock_tier

func get_elemental_charge() -> Dictionary:
	return elemental_charge.duplicate()

func get_dominant_element() -> String:
	return _get_dominant_element()

func has_elemental_core() -> bool:
	return GameState.get_value("elemental_core_held", false)

func is_scram_pulled() -> bool:
	return scram_pulled

func did_blix_surrender() -> bool:
	return blix_surrendered
