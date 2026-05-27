# Shield and Trinket Implementation for CombatManager
# This module should be integrated into CombatManager.gd
# Place after the weapon system section (around line 185)

# ===================================================================
# SHIELD SYSTEM
# ===================================================================
var equipped_shield_id: String = ""
var shield_block: int = 0           # Flat damage blocked per hit
var shield_retributive: int = 0     # Damage attacker takes when hitting player
var shield_special_used: bool = false  # For one-per-combat effects (Dragon Scale)
var shield_type: String = ""        # "block", "retributive", "hybrid"

# ===================================================================
# TRINKET SYSTEM
# ===================================================================
var equipped_trinket_id: String = ""
var trinket_faction: String = ""
var trinket_effects: Dictionary = {}  # Parsed from trinket data

# Combat-scoped trinket state
var trinket_free_spell_used: bool = false
var trinket_full_heal_used: bool = false  # Per-floor, not per-combat

# ===================================================================
# LOADING FUNCTIONS
# ===================================================================

func _load_equipped_shield():
	"""Load shield data from GameState."""
	var shield_id = GameState.equipped_shield
	if shield_id.is_empty():
		return
	var data = GameState.get_equipment_data(shield_id, "shield")
	if data.is_empty():
		return
	
	equipped_shield_id = shield_id
	shield_type = data.get("type", "")
	shield_block = data.get("block", 0)
	shield_retributive = data.get("retributive", 0)
	shield_special_used = false
	print("CombatManager: Equipped %s (block %d, retributive %d, type: %s)" % [
		data.get("name", shield_id), shield_block, shield_retributive, shield_type
	])

func _load_equipped_trinket():
	"""Load trinket data from GameState and parse effects."""
	var trinket_id = GameState.equipped_trinket
	if trinket_id.is_empty():
		return
	var data = GameState.get_equipment_data(trinket_id, "trinket")
	if data.is_empty():
		return
	
	equipped_trinket_id = trinket_id
	trinket_faction = data.get("faction", "")
	_parse_trinket_effects(data.get("desc", ""))
	print("CombatManager: Equipped trinket %s (%s)" % [data.get("name", trinket_id), trinket_faction])

func _parse_trinket_effects(desc: String):
	"""Parse trinket description into actionable effects."""
	trinket_effects.clear()
	var lower = desc.to_lower()
	
	# Crystal Focus: spell cards cost 1 less Quiddity
	if "spell cards cost" in lower and "less" in lower:
		trinket_effects["spell_cost_reduction"] = 1
	
	# Crystal Focus: once per combat free spell
	if "once per combat" in lower and "free spell" in lower:
		trinket_effects["free_spell_per_combat"] = true
		trinket_free_spell_used = false
	
	# Blessed Relic: healing +2
	if "healing" in lower and "+2" in lower:
		trinket_effects["healing_bonus"] = 2
	
	# Blood Chalice: lose 3 HP at combat start, gain 6 Quiddity
	if "lose" in lower and "hp" in lower and "quiddity" in lower:
		trinket_effects["hp_cost_at_start"] = 3
		trinket_effects["quiddity_at_start"] = 6
	
	# Assembly Core: free Assembly Drone summon
	if "free" in lower and "summon" in lower:
		trinket_effects["free_summon"] = true
	
	# Swarm Totem: +1 max summons
	if "+1 max summons" in lower:
		trinket_effects["max_summons_bonus"] = 1
	
	# Swarm Totem: Goblin summons +1 HP
	if "goblin summons" in lower and "+1 hp" in lower:
		trinket_effects["goblin_summon_hp_bonus"] = 1
	
	# Catalyst Ring: elemental cards charge faster
	if "elemental" in lower and "charge" in lower and "faster" in lower:
		trinket_effects["elemental_charge_bonus"] = 1
	
	# Veil Piercer: +2 Attention start
	if "+2 attention" in lower or "attention start" in lower:
		trinket_effects["attention_start_bonus"] = 2
	
	# Survivor's Badge: below 25% HP gain 3 Block
	if "below 25%" in lower and "block" in lower:
		trinket_effects["survivor_block_threshold"] = 0.25
		trinket_effects["survivor_block_amount"] = 3
	
	# Grasping Shroud: drawing costs HP
	if "drawing costs hp" in lower or "deck is your hp" in lower:
		trinket_effects["draw_costs_hp"] = true
		trinket_effects["draw_hp_cost"] = 1
	
	# Grasping Shroud: reshuffle heals to full
	if "reshuffle heals" in lower:
		trinket_effects["reshuffle_heals"] = true

# ===================================================================
# SHIELD DAMAGE INTERCEPTION
# ===================================================================

func _apply_shield_to_damage(damage: int, enemy_index: int = -1) -> Dictionary:
	"""Apply shield effects to incoming damage. Returns {damage, retributive, blocked, negated}."""
	var result = {"damage": damage, "retributive": 0, "blocked": 0, "negated": false}
	
	if equipped_shield_id.is_empty():
		return result
	
	# Dragon Scale: once per combat, negate ANY hit entirely
	if equipped_shield_id == "dragon_scale" and not shield_special_used:
		shield_special_used = true
		result.negated = true
		result.damage = 0
		print("CombatManager: Dragon Scale negated the hit!")
		return result
	
	# Aegis Bulwark: ignores first elemental hit
	if equipped_shield_id == "aegis_bulwark" and not shield_special_used:
		# Check if enemy has Elemental keyword
		if enemy_index >= 0 and enemy_index < enemies.size():
			var enemy = enemies[enemy_index]
			if enemy.has_keyword("elemental"):
				shield_special_used = true
				result.negated = true
				result.damage = 0
				print("CombatManager: Aegis Bulwark ignored the elemental hit!")
				return result
	
	# Apply block
	if shield_block > 0:
		var blocked = min(damage, shield_block)
		result.blocked = blocked
		result.damage = damage - blocked
		print("CombatManager: Shield blocked %d damage" % blocked)
	
	# Apply retributive damage
	if shield_retributive > 0 and enemy_index >= 0 and enemy_index < enemies.size():
		result.retributive = shield_retributive
		var enemy = enemies[enemy_index]
		enemy.hp -= shield_retributive
		print("CombatManager: Retributive shield dealt %d damage to %s" % [shield_retributive, enemy.name])
		if enemy.hp <= 0:
			print("CombatManager: %s died from retributive damage!" % enemy.name)
	
	return result

# ===================================================================
# TRINKET COMBAT EFFECTS
# ===================================================================

func _apply_trinket_at_combat_start():
	"""Apply trinket effects when combat begins."""
	if equipped_trinket_id.is_empty():
		return
	
	# Blood Chalice: lose HP, gain Quiddity
	if trinket_effects.has("hp_cost_at_start"):
		var hp_cost = trinket_effects["hp_cost_at_start"]
		_player_hp -= hp_cost
		print("CombatManager: Blood Chalice drained %d HP" % hp_cost)
	
	if trinket_effects.has("quiddity_at_start"):
		var quiddity_gain = trinket_effects["quiddity_at_start"]
		player_quiddity += quiddity_gain
		quiddity_this_combat += quiddity_gain
		quiddity_changed.emit(player_quiddity, quiddity_this_combat)
		print("CombatManager: Blood Chalice granted %d Quiddity" % quiddity_gain)
	
	# Assembly Core: free summon
	if trinket_effects.has("free_summon"):
		var drone = SummonData.new()
		drone.name = "Assembly Drone"
		drone.max_hp = 8
		drone.hp = 8
		drone.attack = 2
		drone.growth_atk = 1
		drone.growth_hp = 2
		drone.keywords = ["construct", "machine"]
		summons.append(drone)
		print("CombatManager: Assembly Core summoned a drone!")
	
	# Veil Piercer: +2 Attention start
	if trinket_effects.has("attention_start_bonus"):
		player_attention += trinket_effects["attention_start_bonus"]
		print("CombatManager: Veil Piercer +%d Attention at start" % trinket_effects["attention_start_bonus"])
	
	# Reset per-combat flags
	trinket_free_spell_used = false
	# Note: trinket_full_heal_used is per-floor, not reset per combat

func _check_trinket_passives():
	"""Check passive trinket triggers each turn."""
	if equipped_trinket_id.is_empty():
		return
	
	# Survivor's Badge: below 25% HP gain Block
	if trinket_effects.has("survivor_block_threshold"):
		var threshold = trinket_effects["survivor_block_threshold"]
		var block_amount = trinket_effects["survivor_block_amount"]
		var hp_percent = float(_player_hp) / GameState.player_max_hp
		if hp_percent <= threshold and player_shield < block_amount:
			player_shield = block_amount
			print("CombatManager: Survivor's Badge triggered! Block = %d" % block_amount)

func _modify_heal_with_trinket(amount: int) -> int:
	"""Apply trinket healing bonuses."""
	if equipped_trinket_id.is_empty():
		return amount
	
	# Blessed Relic: healing +2
	if trinket_effects.has("healing_bonus"):
		amount += trinket_effects["healing_bonus"]
		print("CombatManager: Blessed Relic +%d healing" % trinket_effects["healing_bonus"])
	
	return amount

func _modify_card_cost_with_trinket(cost: int, card: CardData) -> int:
	"""Apply trinket cost modifications."""
	if equipped_trinket_id.is_empty():
		return cost
	
	# Crystal Focus: spell cards cost 1 less
	if trinket_effects.has("spell_cost_reduction"):
		if card.card_type == "spell" or card.card_type == "Spell":
			cost = max(0, cost - trinket_effects["spell_cost_reduction"])
			print("CombatManager: Crystal Focus reduced spell cost to %d" % cost)
	
	# Crystal Focus: once per combat free spell
	if trinket_effects.has("free_spell_per_combat") and not trinket_free_spell_used:
		if card.card_type == "spell" or card.card_type == "Spell":
			trinket_free_spell_used = true
			cost = 0
			print("CombatManager: Crystal Focus free spell activated!")
	
	return cost

func _modify_max_summons_with_trinket(base_max: int) -> int:
	"""Apply trinket summon limit bonuses."""
	if equipped_trinket_id.is_empty():
		return base_max
	
	# Swarm Totem: +1 max summons
	if trinket_effects.has("max_summons_bonus"):
		base_max += trinket_effects["max_summons_bonus"]
	
	return base_max

func _modify_summon_hp_with_trinket(base_hp: int, summon_name: String) -> int:
	"""Apply trinket summon HP bonuses."""
	if equipped_trinket_id.is_empty():
		return base_hp
	
	# Swarm Totem: Goblin summons +1 HP
	if trinket_effects.has("goblin_summon_hp_bonus"):
		if "goblin" in summon_name.to_lower():
			base_hp += trinket_effects["goblin_summon_hp_bonus"]
			print("CombatManager: Swarm Totem +%d HP for Goblin summon" % trinket_effects["goblin_summon_hp_bonus"])
	
	return base_hp

# ===================================================================
# GRASPING SHROUD SPECIAL
# ===================================================================

func _draw_cards_with_shroud(count: int) -> Array[CardData]:
	"""Draw cards, applying Grasping Shroud HP cost if equipped."""
	var drawn: Array[CardData] = []
	
	for i in range(count):
		if deck.size() == 0:
			# Reshuffle
			if trinket_effects.has("reshuffle_heals"):
				var old_hp = _player_hp
				_player_hp = GameState.player_max_hp
				print("CombatManager: Grasping Shroud reshuffle healed to full! (%d -> %d)" % [old_hp, _player_hp])
			else:
				print("CombatManager: Deck empty, reshuffling discard...")
			deck = discard_pile.duplicate()
			deck.shuffle()
			discard_pile.clear()
		
		if deck.size() == 0:
			break
		
		var card = deck.pop_back()
		
		# Grasping Shroud: drawing costs HP
		if trinket_effects.has("draw_costs_hp"):
			var draw_cost = trinket_effects.get("draw_hp_cost", 1)
			_player_hp -= draw_cost
			print("CombatManager: Grasping Shroud draw cost: %d HP" % draw_cost)
			if _player_hp <= 0:
				_player_hp = 0
				print("CombatManager: Grasping Shroud killed player by drawing!")
				break
		
		hand.append(card)
		drawn.append(card)
		card_drawn.emit(card)
		print("CombatManager: Drew %s" % card.card_name)
	
	return drawn
