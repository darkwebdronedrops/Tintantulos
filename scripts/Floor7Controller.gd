extends FloorController

# ===================================================================
# FLOOR 7 CONTROLLER — The Broken Pact
# Refactored to use FloorController base class + Floor7Template
# ===================================================================
# Adds: Pact system (mid-combat + contract stations), void cracks,
#       docket tracking, The Denied boss (3 phases), cross-floor bleed
# ===================================================================

@onready var floor7_template: Floor7Template = Floor7Template.new()

# Pact State
var signed_pacts: Array[Dictionary] = []
var active_pact_effects: Dictionary = {}
var pact_mid_combat_offers: Array[Dictionary] = []
var pact_offer_cooldown: int = 0

# Void Crack State
var void_crack_positions: Array[Vector2] = []
var void_crack_stabilized: Array[bool] = []
var near_void_crack: bool = false
var stabilizers_placed: int = 0

# Docket State
var docket_sins: Dictionary = {}
var docket_total_weight: int = 0
var docket_calculated: bool = false

# Boss State (The Denied)
var boss_phase: int = 1  # 1=Hearing, 2=Verdict, 3=Appeal
var boss_hp: int = 60
var boss_max_hp: int = 60
var witnesses_spawned: Array[String] = []
var final_pact_offered: bool = false
var final_pact_signed: bool = false
var all_pacts_broken: bool = false

# Goblin Forger (from Floor 6)
var goblin_forger_available: bool = false
var forgery_used: bool = false

# UI References
var pact_ui: Label
var docket_ui: Label
var void_crack_ui: Label
var sin_meter_ui: Label

func _ready():
	floor_template = floor7_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Check cross-floor bleed from Floor 6
	if GameState.floor6_graduate_status:
		_show_notification("🎓 Alumni Discount active — Pacts cost 25% less", Color(0.3, 0.9, 0.3))
	
	if GameState.floor6_failed_courses:
		_show_notification("⚠ Failed Courses — Pacts cost 50% more", Color(0.9, 0.3, 0.3))
	
	if GameState.floor6_audit_status:
		_show_notification("👁 Demon Suspicion — Negotiation checks are harder", Color(0.9, 0.7, 0.3))
	
	if GameState.floor6_goblin_janitor_befriended:
		goblin_forger_available = true
		_show_notification("🤝 Goblin Forger available in Break Room", Color(0.3, 0.9, 0.3))
	
	# Initialize void cracks
	_initialize_void_cracks()
	
	# Calculate docket on first entry
	if not docket_calculated:
		_calculate_docket()
	
	print("[Floor7] Setup complete. Sins: %d | Goblin forger: %s" % [
		docket_total_weight, goblin_forger_available
	])

func _setup_floor_ui():
	# Pact display
	pact_ui = Label.new()
	pact_ui.name = "PactUI"
	pact_ui.position = Vector2(20, 20)
	pact_ui.size = Vector2(400, 120)
	pact_ui.add_theme_font_size_override("font_size", 12)
	add_child(pact_ui)
	_update_pact_display()
	
	# Docket / sin meter
	docket_ui = Label.new()
	docket_ui.name = "DocketUI"
	docket_ui.position = Vector2(20, 150)
	docket_ui.size = Vector2(350, 80)
	docket_ui.add_theme_font_size_override("font_size", 11)
	add_child(docket_ui)
	_update_docket_display()
	
	# Void crack status
	void_crack_ui = Label.new()
	void_crack_ui.name = "VoidCrackUI"
	void_crack_ui.position = Vector2(20, 240)
	void_crack_ui.size = Vector2(300, 30)
	void_crack_ui.add_theme_font_size_override("font_size", 11)
	add_child(void_crack_ui)
	_update_void_crack_display()
	
	# Sin meter (boss phase indicator)
	sin_meter_ui = Label.new()
	sin_meter_ui.name = "SinMeterUI"
	sin_meter_ui.position = Vector2(20, 280)
	sin_meter_ui.size = Vector2(300, 40)
	sin_meter_ui.add_theme_font_size_override("font_size", 12)
	sin_meter_ui.visible = false
	add_child(sin_meter_ui)

func _update_floor_ui():
	_update_pact_display()
	_update_docket_display()
	_update_void_crack_display()
	if boss_phase > 1:
		_update_sin_meter_display()

# -------------------------------------------------------------------
# Docket System — Track Player Sins Across All Floors
# -------------------------------------------------------------------

func _calculate_docket():
	"""Pull player's choice history from GameState and calculate sin weight."""
	var categories = floor7_template.get_docket_categories()
	var total = 0
	
	for sin_id in categories.keys():
		var config = categories[sin_id]
		var count = _get_sin_count(sin_id)
		var weight = config["weight"]
		var label = config["label"]
		
		if count > 0:
			docket_sins[sin_id] = {
				"count": count,
				"weight": weight,
				"label": label,
				"total": count * weight
			}
			total += count * weight
		elif weight < 0 and count > 0:
			# Liberator reduces sin
			total += count * weight
	
	docket_total_weight = max(0, total)
	docket_calculated = true
	
	print("[Floor7] Docket calculated: %d sin weight" % docket_total_weight)
	_update_docket_display()

func _get_sin_count(sin_id: String) -> int:
	"""Get the count of a specific sin from GameState."""
	match sin_id:
		"pacts_signed":
			return GameState.get_value("pacts_signed_count", 0)
		"souls_enslaved":
			return GameState.get_value("souls_enslaved_count", 0)
		"bosses_killed":
			return GameState.get_value("bosses_defeated_count", 0)
		"courses_failed":
			return GameState.get_value("courses_failed_count", 0)
		"clocktower_sabotaged":
			return 1 if GameState.get_value("floor6_clocktower_sabotaged", false) else 0
		"pacts_broken":
			return GameState.get_value("pacts_broken_count", 0)
		"companions_built":
			return GameState.get_value("companions_built_count", 0)
		"souls_freed":
			return GameState.get_value("souls_freed_count", 0)
		_:
			return 0

func _update_docket_display():
	if not docket_ui:
		return
	
	if docket_sins.is_empty():
		docket_ui.text = "📋 DOCKET: Clean (no sins recorded)"
		docket_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		return
	
	var text = "📋 DOCKET (%d sin weight):\n" % docket_total_weight
	for sin_id in docket_sins.keys():
		var sin = docket_sins[sin_id]
		text += "• %s: %d (%s)\n" % [sin["label"], sin["count"], sin_id]
	
	var color = Color(0.8, 0.8, 0.8)
	if docket_total_weight >= 10:
		color = Color(0.9, 0.3, 0.3)  # Heavy sin
	elif docket_total_weight >= 5:
		color = Color(0.9, 0.7, 0.3)  # Moderate
	else:
		color = Color(0.5, 0.8, 0.5)  # Light
	
	docket_ui.text = text
	docket_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Pact System — Contract Stations & Mid-Combat Offers
# -------------------------------------------------------------------

func _offer_pact_at_station(pact_id: String):
	"""Player interacts with a contract station to sign a pact."""
	var config = floor7_template.get_pact_config()
	var pact = config.get(pact_id)
	if not pact:
		return
	
	# Check if already signed
	for signed in signed_pacts:
		if signed["id"] == pact_id and not pact.get("can_stack", false):
			_show_notification("You already signed %s" % pact["name"], Color(0.7, 0.7, 0.7))
			return
	
	# Apply cost modifiers from Floor 6
	var cost_multiplier = _get_pact_cost_multiplier()
	
	# Show pact dialog
	var desc = "%s\n\nBenefit: %s\nCost: %s" % [
		pact["name"], pact["immediate"], pact["permanent"]
	]
	
	if cost_multiplier != 1.0:
		desc += "\n[Modified: %d%% cost]" % int(cost_multiplier * 100)
	
	_show_dialogue("Contract Station", desc + "\n\nSign?")
	
	# TODO: Add yes/no choice UI
	# For now, auto-sign for demonstration
	_sign_pact(pact_id)

func _sign_pact(pact_id: String):
	"""Sign a pact and apply effects."""
	var config = floor7_template.get_pact_config()
	var pact = config[pact_id]
	
	var signed_pact = {
		"id": pact_id,
		"name": pact["name"],
		"immediate": pact["immediate"],
		"permanent": pact["permanent"],
		"floor_signed": 7,
		"active": true
	}
	signed_pacts.append(signed_pact)
	
	# Apply immediate effects
	_apply_pact_immediate_effect(pact_id)
	
	# Apply permanent cost
	_apply_pact_permanent_cost(pact_id)
	
	# Track in GameState
	GameState.pacts_signed_count = GameState.get_value("pacts_signed_count", 0) + 1
	
	_show_notification("📜 Signed: %s" % pact["name"], Color(0.9, 0.3, 0.3))
	_update_pact_display()
	print("[Floor7] Pact signed: %s" % pact_id)

func _apply_pact_immediate_effect(pact_id: String):
	"""Apply the immediate benefit of a pact."""
	match pact_id:
		"blood_contract":
			# +3 damage all cards this floor
			active_pact_effects["blood_damage_bonus"] = 3
			_show_notification("🩸 +3 damage to all cards!", Color(0.9, 0.3, 0.3))
		"soul_mortgage":
			# +1 card draw per turn
			active_pact_effects["extra_draw"] = 1
			_show_notification("📜 Draw +1 card per turn!", Color(0.7, 0.3, 0.9))
		"void_bond":
			# Gain random epic card
			var epic_cards = ["void_touch", "unstable_formula", "fractured"]
			var random_card = epic_cards[randi() % epic_cards.size()]
			# TODO: Add card to deck
			_show_notification("🌀 Void Bond: Gained %s!" % random_card, Color(0.3, 0.3, 0.9))
		"silence_clause":
			# Skip next enemy turn (only in combat)
			active_pact_effects["enemy_skip_turn"] = 1
			_show_notification("🔇 Enemy skips next turn!", Color(0.5, 0.5, 0.5))

func _apply_pact_permanent_cost(pact_id: String):
	"""Apply the permanent cost of a pact."""
	match pact_id:
		"blood_contract":
			# -5 max HP
			GameState.player_max_hp = max(1, GameState.get_value("player_max_hp", 20) - 5)
			_show_notification("💔 Max HP reduced by 5", Color(0.9, 0.3, 0.3))
		"soul_mortgage":
			# Remove 1 random card from deck
			# TODO: Remove random card
			_show_notification("💀 Card removed from deck", Color(0.7, 0.3, 0.9))
		"void_bond":
			# Mark card as mutating
			GameState.void_bond_active = true
			_show_notification("🌀 One card now mutates each combat", Color(0.3, 0.3, 0.9))
		"silence_clause":
			# Cannot speak to NPCs
			GameState.silence_clause_active = true
			_show_notification("🔇 NPC interaction disabled", Color(0.5, 0.5, 0.5))

func _get_pact_cost_multiplier() -> float:
	"""Calculate cost multiplier based on Floor 6 status."""
	var multiplier = 1.0
	
	if GameState.floor6_graduate_status:
		multiplier -= 0.25  # Alumni discount
	
	if GameState.floor6_failed_courses:
		multiplier += 0.50  # Failed courses penalty
	
	return max(0.1, multiplier)

func _break_all_pacts():
	"""Break all signed pacts — costs refunded but enemies enraged."""
	if signed_pacts.is_empty():
		_show_notification("No pacts to break", Color(0.7, 0.7, 0.7))
		return
	
	# Refund permanent costs
	for pact in signed_pacts:
		_refund_pact_cost(pact["id"])
	
	# Track broken pacts
	GameState.pacts_broken_count = GameState.get_value("pacts_broken_count", 0) + signed_pacts.size()
	
	# Clear pact list
	signed_pacts.clear()
	active_pact_effects.clear()
	
	all_pacts_broken = true
	
	_show_notification("💥 ALL PACTS BROKEN! Costs refunded. Enemies enraged!", Color(0.9, 0.9, 0.3))
	print("[Floor7] All pacts broken — %d pacts refunded" % signed_pacts.size())

func _refund_pact_cost(pact_id: String):
	"""Refund the permanent cost of a broken pact."""
	match pact_id:
		"blood_contract":
			GameState.player_max_hp += 5
		"soul_mortgage":
			# TODO: Return removed card to deck
			pass
		"void_bond":
			GameState.void_bond_active = false
		"silence_clause":
			GameState.silence_clause_active = false

func _update_pact_display():
	if not pact_ui:
		return
	
	if signed_pacts.is_empty():
		pact_ui.text = "📜 NO PACTS SIGNED"
		pact_ui.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		return
	
	var text = "📜 ACTIVE PACTS:\n"
	for pact in signed_pacts:
		text += "• %s\n" % pact["name"]
		if pact.get("active", false):
			text += "  %s\n" % pact["immediate"]
	
	pact_ui.text = text
	pact_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

# -------------------------------------------------------------------
# Mid-Combat Pact Offers
# -------------------------------------------------------------------

func _offer_mid_combat_pact(enemy_name: String):
	"""An enemy offers a pact during combat."""
	if pact_offer_cooldown > 0:
		return
	
	var offers = [
		{
			"enemy": enemy_name,
			"offer": "I will stop attacking if you give me 5 HP permanently",
			"benefit": "enemy_stops_attacking",
			"cost": "-5 max HP",
			"pact_id": "blood_contract"
		},
		{
			"enemy": enemy_name,
			"offer": "Take this card — it transforms randomly each combat",
			"benefit": "random_epic_card",
			"cost": "card_mutates",
			"pact_id": "void_bond"
		}
	]
	
	var offer = offers[randi() % offers.size()]
	pact_mid_combat_offers.append(offer)
	
	_show_dialogue(enemy_name, offer["offer"] + "\n\nAccept?")
	pact_offer_cooldown = 3  # 3 turns before next offer
	
	print("[Floor7] Mid-combat pact offered by %s" % enemy_name)

func _accept_mid_combat_pact(offer_index: int):
	"""Player accepts a mid-combat pact offer."""
	if offer_index >= pact_mid_combat_offers.size():
		return
	
	var offer = pact_mid_combat_offers[offer_index]
	_sign_pact(offer["pact_id"])
	
	# Apply combat benefit
	match offer["benefit"]:
		"enemy_stops_attacking":
			# TODO: Make specific enemy stop attacking
			pass
		"random_epic_card":
			# Already handled by _sign_pact
			pass
	
	pact_mid_combat_offers.remove_at(offer_index)

# -------------------------------------------------------------------
# Void Crack System
# -------------------------------------------------------------------

func _initialize_void_cracks():
	"""Place void cracks in aberration-heavy rooms."""
	var config = floor7_template.get_void_crack_config()
	var count = config.get("stabilizer_count", 3)
	
	# Place cracks in Corridor, Laboratory, Void Lab
	void_crack_positions = [
		Vector2(100, 100),   # Corridor
		Vector2(-100, 200),  # Laboratory
		Vector2(50, -50)     # Void Lab
	]
	
	void_crack_stabilized = [false, false, false]
	stabilizers_placed = 0
	
	print("[Floor7] %d void cracks initialized" % void_crack_positions.size())

func _check_void_crack_proximity():
	"""Check if player is near a void crack."""
	var player_pos = player_node.global_position if player_node else Vector2.ZERO
	var was_near = near_void_crack
	near_void_crack = false
	
	for i in range(void_crack_positions.size()):
		if void_crack_stabilized[i]:
			continue
		
		if player_pos.distance_to(void_crack_positions[i]) < 80.0:
			near_void_crack = true
			if not was_near:
				_show_notification("🌀 Near void crack — Reality unstable!", Color(0.3, 0.3, 0.9))
			break
	
	_update_void_crack_display()

func _stabilize_void_crack(crack_index: int):
	"""Stabilize a void crack using a stabilizer plate."""
	if crack_index >= void_crack_positions.size():
		return
	
	if void_crack_stabilized[crack_index]:
		_show_notification("Already stabilized", Color(0.7, 0.7, 0.7))
		return
	
	void_crack_stabilized[crack_index] = true
	stabilizers_placed += 1
	
	var config = floor7_template.get_void_crack_config()
	var total = config.get("stabilizer_count", 3)
	
	_show_notification("🔧 Void crack stabilized! (%d/%d)" % [stabilizers_placed, total], Color(0.3, 0.9, 0.3))
	
	if stabilizers_placed >= total:
		_show_notification("✅ All void cracks sealed!", Color(0.3, 0.9, 0.3))
	
	_update_void_crack_display()
	print("[Floor7] Void crack %d stabilized" % crack_index)

func _on_void_crack_effect():
	"""Apply void crack transformation effect."""
	if not near_void_crack:
		return
	
	var config = floor7_template.get_void_crack_config()
	var chance = config.get("transform_chance", 0.3)
	
	if randf() < chance:
		var mutations = config.get("enemy_mutations", ["Void-Touched"])
		var mutation = mutations[randi() % mutations.size()]
		
		_show_notification("🌀 VOID EFFECT: Enemy transformed into %s!" % mutation, Color(0.3, 0.3, 0.9))
		# TODO: Apply mutation to nearest enemy
		print("[Floor7] Void transformed enemy: %s" % mutation)

func _update_void_crack_display():
	if not void_crack_ui:
		return
	
	var total = void_crack_positions.size()
	var stabilized = stabilizers_placed
	var remaining = total - stabilized
	
	if remaining == 0:
		void_crack_ui.text = "🔧 VOID: All Sealed"
		void_crack_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif near_void_crack:
		void_crack_ui.text = "🌀 VOID CRACK NEARBY! (%d/%d sealed)" % [stabilized, total]
		void_crack_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.9))
	else:
		void_crack_ui.text = "🌀 Void Cracks: %d/%d sealed" % [stabilized, total]
		void_crack_ui.add_theme_color_override("font_color", Color(0.5, 0.3, 0.7))

# -------------------------------------------------------------------
# Boss System — The Denied (3 Phases)
# -------------------------------------------------------------------

func _start_boss_fight():
	"""Begin The Denied boss encounter."""
	boss_phase = 1
	boss_hp = boss_max_hp
	witnesses_spawned.clear()
	final_pact_offered = false
	final_pact_signed = false
	
	_show_dialogue("The Denied", "The Dean said my research was 'unethical.'\nThe Dean said I was 'a danger to students.'\nThe Dean denied my tenure.\nBut the Dean never met my new colleagues.\nWould you like to meet them?")
	
	_update_sin_meter_display()
	print("[Floor7] Boss fight started — Phase 1: The Hearing")

func _on_boss_phase_1_hearing():
	"""Phase 1: The Denied reads the docket and summons witnesses."""
	# Summon witnesses based on docket weight
	var witness_count = mini(docket_total_weight, 6)  # Cap at 6 witnesses
	
	_show_dialogue("The Denied", "Let us review your record.\n%d sin weight. %d witnesses to call." % [
		docket_total_weight, witness_count
	])
	
	# Spawn witnesses (ghosts of defeated enemies)
	for i in range(witness_count):
		var witness_name = "Witness_%d" % i
		witnesses_spawned.append(witness_name)
		# TODO: Spawn mini-enemy that attacks once
		_show_notification("👁 Witness summoned!", Color(0.9, 0.3, 0.3))
	
	# Player can plead to dismiss witnesses
	_plead_case()

func _plead_case():
	"""Spend gems to dismiss witnesses."""
	var config = floor7_template.get_boss_config()
	var cost = config.get("plead_cost_gems", 5)
	
	if GameState.gems >= cost and not witnesses_spawned.is_empty():
		GameState.gems -= cost
		var dismissed = witnesses_spawned.pop_back()
		_show_notification("💰 Pleading: %s dismissed (%d gems)" % [dismissed, cost], Color(0.3, 0.9, 0.3))
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
	elif witnesses_spawned.is_empty():
		_show_notification("No witnesses remaining", Color(0.7, 0.7, 0.7))
	else:
		_show_notification("Need %d gems to plead" % cost, Color(0.9, 0.3, 0.3))

func _on_boss_phase_2_verdict():
	"""Phase 2: The Denied offers the Final Pact."""
	final_pact_offered = true
	
	_show_dialogue("The Denied", "Sign this, and you walk out.\nNo combat. No risk.\nJust... a small lien on your future.\nEveryone signs. Everyone.")
	
	_show_notification("📜 FINAL PACT OFFERED", Color(0.9, 0.3, 0.9))
	print("[Floor7] Phase 2: Final Pact offered")

func _sign_final_pact():
	"""Sign the Final Pact — instant boss death but Marked debuff."""
	final_pact_signed = true
	
	_show_dialogue("The Denied", "Signed. Sealed.\nThe lien is recorded.\nYou may pass.\n...we will meet again.")
	
	# Boss dies instantly
	boss_hp = 0
	_show_notification("💀 The Denied yields! MARKED debuff applied!", Color(0.9, 0.3, 0.9))
	
	# Apply Marked debuff for Floors 8-9
	GameState.marked_debuff_active = true
	
	# End combat
	_end_boss_combat(true)

func _refuse_final_pact():
	"""Refuse the Final Pact — boss transforms into aberration form."""
	_show_dialogue("The Denied", "Then face judgment.")
	
	# Boss transforms — +50% HP
	var config = floor7_template.get_boss_config()
	var bonus = config.get("refuse_hp_bonus", 0.5)
	boss_max_hp = int(boss_max_hp * (1.0 + bonus))
	boss_hp = boss_max_hp
	
	_show_notification("😈 The Denied transforms! HP: %d" % boss_hp, Color(0.9, 0.3, 0.3))
	
	# Move to Phase 3
	boss_phase = 3
	_update_sin_meter_display()
	print("[Floor7] Phase 3: Aberration Form — HP %d" % boss_hp)

func _on_boss_phase_3_appeal():
	"""Phase 3: Reality breaks. Floor geometry shifts."""
	_show_dialogue("The Denied", "I become the verdict.\nReality is my court.\nYou have no grounds to appeal.")
	
	_show_notification("🌀 REALITY BREAKS! Geometry shifts every 3 turns!", Color(0.3, 0.3, 0.9))
	
	# Start reality shift timer
	# TODO: Shift room geometry every 3 turns
	print("[Floor7] Phase 3: The Appeal — reality unstable")

func _use_pact_as_ammo(pact_index: int):
	"""Sacrifice a pact's benefit for a massive attack."""
	if pact_index >= signed_pacts.size():
		return
	
	var pact = signed_pacts[pact_index]
	var damage = 20  # Massive damage from sacrificed pact
	
	# Remove pact benefit
	active_pact_effects.erase(pact["id"])
	
	_show_notification("💥 SACRIFICED: %s for %d damage!" % [pact["name"], damage], Color(0.9, 0.9, 0.3))
	
	# TODO: Deal damage to boss
	print("[Floor7] Pact sacrificed: %s → %d damage" % [pact["name"], damage])

func _end_boss_combat(victory: bool):
	"""End the boss fight and handle transitions."""
	if victory:
		if final_pact_signed:
			_show_dialogue("The Tower", "The Denied yields.\nThe contract is binding.\nThe path to Floor 8 opens.\nBut something follows you now.")
		elif all_pacts_broken:
			_show_dialogue("The Tower", "The Denied falls.\nAll pacts shattered.\nThe debt is cleared.\nThe path to Floor 8 opens, clean.")
		else:
			_show_dialogue("The Tower", "The Denied falls.\nSome pacts honored, some broken.\nA mixed verdict.\nThe path to Floor 8 opens.")
		
		# Give rewards
		GameState.gems += 100
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
		
		# Save progress
		GameState.save_game()
		
		# Show transition prompt and auto-ascend after delay
		_show_floor_transition_prompt()
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(_ascend_to_next_floor)
	else:
		# Defeat
		_show_notification("💀 Defeated by The Denied", Color(0.9, 0.3, 0.3))

func _update_sin_meter_display():
	if not sin_meter_ui:
		return
	
	var text = ""
	match boss_phase:
		1:
			text = "PHASE 1: THE HEARING\n%d witnesses | %d sin weight" % [
				witnesses_spawned.size(), docket_total_weight
			]
		2:
			text = "PHASE 2: THE VERDICT\nFinal Pact offered"
		3:
			text = "PHASE 3: THE APPEAL\nReality unstable | %d/%d HP" % [
				boss_hp, boss_max_hp
			]
	
	sin_meter_ui.text = text
	sin_meter_ui.visible = true

# -------------------------------------------------------------------
# Goblin Forger (Cross-Floor from Floor 6)
# -------------------------------------------------------------------

func _interact_with_forger():
	"""The Floor 6 goblin janitor appears in Break Room."""
	if not goblin_forger_available:
		_show_dialogue("Empty", "The forger's desk is empty.")
		return
	
	if forgery_used:
		_show_dialogue("Sneak Thief", "Already forged one for ya, pal.\nOne per customer. Union rules.")
		return
	
	_show_dialogue("Sneak Thief", "Hey pal! Heard ya made it to the demon floor.\nI can... 'help' with the paperwork.\nOne free pact — forged signature, no cost to you.\nJust don't tell The Denied, yeah?")
	
	# TODO: Show pact selection UI
	# For now, auto-forge blood contract
	_forgery_sign_pact("blood_contract")

func _forgery_sign_pact(pact_id: String):
	"""Forge a pact signature — free benefit, no cost."""
	var config = floor7_template.get_pact_config()
	var pact = config[pact_id]
	
	var forged_pact = {
		"id": pact_id,
		"name": pact["name"] + " (FORGED)",
		"immediate": pact["immediate"],
		"permanent": "NONE (forged)",
		"floor_signed": 7,
		"active": true,
		"forged": true
	}
	signed_pacts.append(forged_pact)
	
	# Apply only the benefit, no cost
	_apply_pact_immediate_effect(pact_id)
	
	forgery_used = true
	
	_show_notification("🤝 FORGED: %s — No cost!" % pact["name"], Color(0.3, 0.9, 0.3))
	_update_pact_display()
	print("[Floor7] Forged pact signed: %s" % pact_id)

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		"Sign Contract", "Blood Contract", "Soul Mortgage", "Void Bond", "Silence Clause":
			var pact_id = ""
			match object_type:
				"Blood Contract": pact_id = "blood_contract"
				"Soul Mortgage": pact_id = "soul_mortgage"
				"Void Bond": pact_id = "void_bond"
				"Silence Clause": pact_id = "silence_clause"
				"Sign Contract":
					# Generic station — offer random pact
					var pacts = ["blood_contract", "soul_mortgage", "void_bond", "silence_clause"]
					pact_id = pacts[randi() % pacts.size()]
			
			if not pact_id.is_empty():
				_offer_pact_at_station(pact_id)
		
		"Approach Crack":
			_check_void_crack_proximity()
			if near_void_crack:
				_on_void_crack_effect()
		
		"Stabilize Void":
			# Find nearest unstabilized crack
			for i in range(void_crack_positions.size()):
				if not void_crack_stabilized[i]:
					_stabilize_void_crack(i)
					break
		
		"Read Docket":
			_calculate_docket()
			var docket_text = "Your Docket:\n"
			for sin_id in docket_sins.keys():
				var sin = docket_sins[sin_id]
				docket_text += "%s: %d (weight: %d)\n" % [sin["label"], sin["count"], sin["total"]]
			_show_dialogue("Docket Reader", docket_text + "\nTotal sin weight: %d" % docket_total_weight)
		
		"Approach Witness":
			_show_dialogue("Witness", "I testify to the player's sins.\n%d weight recorded." % docket_total_weight)
		
		"Plead Case":
			_plead_case()
		
		"Confront the Denied":
			_start_boss_fight()
		
		"Sign Final Pact":
			if final_pact_offered and not final_pact_signed:
				_sign_final_pact()
			else:
				_show_notification("No final pact offered", Color(0.7, 0.7, 0.7))
		
		"Break All Pacts":
			_break_all_pacts()
		
		"Review Contract":
			# Contract review puzzle
			_show_dialogue("Contract", "Review the fine print...\n\n'4% APR, compounded per floor.'\n\nLoophole found: The APR only applies if the signer is still alive.\nCorrect loophole = free benefit.\nWrong = cost doubled.")
			# TODO: Add actual puzzle mechanic
		
		"Stand on Plate":
			# Void stabilization puzzle
			_show_notification("Pressure plate activated", Color(0.3, 0.9, 0.3))
			# TODO: Check puzzle state
		
		"Talk to Clerk":
			_show_dialogue("Soul Clerk", "Name? Purpose of visit?\nExisting soul-debt?\nPlease form a single file line.\nNo, the OTHER single file line.\nThat one is for the condemned.")
		
		"Talk to Lawyer":
			var offer = "I offer a pact: +3 damage, -5 max HP.\nRefuse, and I buff all enemies."
			_show_dialogue("Contract Lawyer", offer)
			# TODO: Offer actual pact
		
		"Talk to Forger":
			_interact_with_forger()
		
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
	"""Override to check for mid-combat pact offers."""
	pact_offer_cooldown = 0
	pact_mid_combat_offers.clear()
	
	# Check for demon enemies that offer pacts
	for enemy_name in enemy_names:
		if "lawyer" in enemy_name.to_lower() or "clerk" in enemy_name.to_lower():
			_offer_mid_combat_pact(enemy_name)
			break  # Only one offer per combat start
	
	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to handle boss defeat and pact effects."""
	# Apply post-combat pact effects
	if victory and active_pact_effects.has("blood_damage_bonus"):
		# Blood contract damage bonus persists through combat
		pass
	
	# Reset cooldowns
	pact_offer_cooldown = 0
	
	# Check if this was boss fight
	if current_room_id == "auditorium":
		_end_boss_combat(victory)
		return
	
	super._on_combat_ended(victory)

func _on_combat_turn_advanced():
	"""Override to process void cracks and pact cooldowns."""
	# Decrement pact offer cooldown
	if pact_offer_cooldown > 0:
		pact_offer_cooldown -= 1
	
	# Check void crack proximity
	if current_room_id in ["corridor", "laboratory", "void_lab"]:
		_check_void_crack_proximity()
		if near_void_crack and randf() < 0.3:
			_on_void_crack_effect()
	
	# Boss phase transitions based on HP
	if current_room_id == "auditorium":
		var config = floor7_template.get_boss_config()
		var phase_hp = config.get("phase_transition_hp", 30)
		
		if boss_phase == 1 and (boss_hp <= phase_hp or witnesses_spawned.is_empty()):
			# Phase 1 ends when HP drops or all witnesses dismissed
			boss_phase = 2
			_on_boss_phase_2_verdict()
		elif boss_phase == 2 and not final_pact_signed and not final_pact_offered:
			# Shouldn't happen but handle
			_on_boss_phase_2_verdict()
		elif boss_phase == 3:
			# Reality shift every 3 turns
			pass
		
		_update_sin_meter_display()
	
	# Update displays
	_update_pact_display()
	_update_docket_display()
	_update_void_crack_display()

# -------------------------------------------------------------------
# Floor Complete — Transition to Floor 8
# -------------------------------------------------------------------

func _show_floor_transition_prompt():
	"""Show prompt to ascend to Floor 8."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 8 — The Overclock Forge"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

func _ascend_to_next_floor():
	"""Ascend to Floor 8."""
	print("[Floor7] Ascending to Floor 8...")
	get_tree().change_scene_to_file("res://scenes/Floor8.tscn")

# -------------------------------------------------------------------
# Input Override
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Base class input
	super._input(event)

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_signed_pacts() -> Array:
	return signed_pacts.duplicate()

func get_docket_weight() -> int:
	return docket_total_weight

func get_docket_sins() -> Dictionary:
	return docket_sins.duplicate()

func is_marked() -> bool:
	return GameState.get_value("marked_debuff_active", false)

func are_all_pacts_broken() -> bool:
	return all_pacts_broken

func is_final_pact_signed() -> bool:
	return final_pact_signed
