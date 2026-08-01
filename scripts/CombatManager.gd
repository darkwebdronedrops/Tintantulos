extends Node
class_name CombatManager

enum AttentionState {WHISPER, BORROWED, UNDEFINED, SCREAM}
enum EnemyAction {ATTACK, DEFEND, SPECIAL}

class EnemyData:
	var name: String
	var enemy_name: String  # Alias for CombatUI compatibility
	var max_hp: int
	var hp: int
	var attack: int
	var defense: int = 0
	var action_pattern: Array = [EnemyAction.ATTACK]
	var current_action_index: int = 0
	var keywords: PackedStringArray = []
	var active_dots: Array[DoTData] = []
	var sprite_texture_path: String = ""  # CombatUI compatibility
	var faction: String = "Unknown"  # CombatUI compatibility

	func _init(n: String, mhp: int, atk: int, def_: int = 0, pattern: Array = [], kw: PackedStringArray = []):
		name = n
		enemy_name = n
		max_hp = mhp
		hp = mhp
		attack = atk
		defense = def_
		keywords = kw
		if pattern.size() > 0:
			action_pattern = pattern
		else:
			action_pattern = [EnemyAction.ATTACK]
		
		# Try to infer sprite from enemy name
		var base_name = n.to_lower().replace(" ", "_").replace("-", "_")
		for suffix in ["_idle", "_attack", "_damage", "_death", ""]:
			var try_path = "res://assets/sprites/enemies/enemy_" + base_name + suffix + ".png"
			if ResourceLoader.exists(try_path):
				sprite_texture_path = try_path
				break
		
		# Try to infer faction from name
		if "goblin" in base_name or "gear" in base_name or "tight" in base_name:
			faction = "Construct"
		elif "flesh" in base_name or "bone" in base_name or "undead" in base_name:
			faction = "Undead"
		elif "spore" in base_name or "fungal" in base_name or "mushroom" in base_name:
			faction = "Aberration"
		elif "flame" in base_name or "fire" in base_name or "ember" in base_name or "caldera" in base_name:
			faction = "Elemental"
		elif "dragon" in base_name or "boss" in base_name:
			faction = "Boss"

	func has_keyword(kw: String) -> bool:
		for k in keywords:
			if k.to_lower() == kw.to_lower():
				return true
		return false

	func add_dot(dot: DoTData):
		active_dots.append(dot)

	func tick_dots() -> int:
		var total_damage = 0
		var alive: Array[DoTData] = []
		for dot in active_dots:
			var dmg = dot.tick()
			total_damage += dmg
			if not dot.is_expired():
				alive.append(dot)
			else:
				print("CombatManager: %s DoT on %s expired" % [dot.type, name])
		active_dots.clear()
		for dot in alive:
			active_dots.append(dot)
		return total_damage

class DoTData:
	var type: String
	var damage: int
	var duration: int
	var source: String
	var color: Color

	func _init(t: String, dmg: int, dur: int, src: String, c: Color):
		type = t
		damage = dmg
		duration = dur
		source = src
		color = c

	func tick() -> int:
		duration -= 1
		return damage

	func is_expired() -> bool:
		return duration <= 0

class SummonData:
	var name: String
	var max_hp: int
	var hp: int
	var attack: int
	var growth_atk: int = 0
	var growth_hp: int = 0
	var keywords: PackedStringArray = []
	var has_attacked_this_turn: bool = false
	var just_summoned: bool = true

	func _init(n: String, mhp: int, atk: int, kw: PackedStringArray = [], g_atk: int = 0, g_hp: int = 0):
		name = n
		max_hp = mhp
		hp = mhp
		attack = atk
		keywords = kw
		growth_atk = g_atk
		growth_hp = g_hp
		print("SummonData: Created %s (%d/%d HP, %d ATK)" % [name, hp, max_hp, attack])

	func has_keyword(kw: String) -> bool:
		for k in keywords:
			if k.to_lower() == kw.to_lower():
				return true
		return false

	func grow():
		# Growth: any summon with growth stats can grow (not just Nature keyword)
		if growth_atk > 0 or growth_hp > 0:
			attack += growth_atk
			max_hp += growth_hp
			hp += growth_hp
			print("SummonManager: %s grew! +%d ATK, +%d/%d HP (now %d ATK, %d/%d HP)" % [
				name, growth_atk, growth_hp, growth_hp, attack, hp, max_hp
			])
			return true
		return false

# Player Stats
var player_shield: int = 0
var player_attention: int = 0
var player_quiddity: int = 0
var player_stake: int = 0  # 0-5, reduces card draw
var current_stake: int = 0  # Alias for CombatUI compatibility

var _player_hp: int:
	get:
		return GameState.player_hp
	set(value):
		var delta = value - GameState.player_hp
		if delta > 0:
			GameState.heal_player(delta)
		elif delta < 0:
			GameState.damage_player(-delta)

var _player_max_hp: int:
	get:
		return GameState.player_max_hp

# Public aliases for CombatUI compatibility
var player_hp: int:
	get:
		return _player_hp
	set(value):
		_player_hp = value

var player_max_hp: int:
	get:
		return _player_max_hp

func get_attention_state_name() -> String:
	return _get_attention_state_name()

func _get_attention_state_name() -> String:
	match current_attention_state:
		AttentionState.WHISPER:
			return "Whisper"
		AttentionState.BORROWED:
			return "Borrowed"
		AttentionState.UNDEFINED:
			return "Undefined"
		AttentionState.SCREAM:
			return "Scream"
	return "Unknown"

# Trap System
var active_traps: Array[Dictionary] = []  # {card: CardData, caster_turn: int}

# Combat State
var turn_count: int = 0
var hand: Array = []
var enemies: Array = []
var deck: Array = []
var discard_pile: Array = []
var summons: Array[SummonData] = []
var player_dots: Array[DoTData] = []
var current_enemy_index: int = 0
var is_player_turn: bool = true
var combat_active: bool = false
var pact_queue: Array[Dictionary] = []

# Attention System
var current_attention_state: AttentionState = AttentionState.WHISPER

# Quiddity System
var quiddity_this_combat: int = 0

# CHARGE System (Elemental resource)
var player_charge: int = 0
const MAX_CHARGE: int = 10
var charge_revealed: bool = false  # Hidden until Nature/Flow played

# Flow discount tracking
var next_card_cost_reduction: int = 0

# Boss Mode
var is_boss_mode: bool = false
var boss: BossAI.BossBehavior = null
var boss_ai: BossAI = null

# Tutorial Mode
var tutorial_mode: bool = false

# Eidolon tracking
var player_last_damage: int = 10  # Default so Eidolon has something to mirror

# First keyword tracking
var _first_played_cards: Array[String] = []  # Cards already played this combat (for "First" keyword)

# Signals
signal combat_started
signal combat_ended(victory: bool)
signal turn_started(is_player: bool)
signal player_damaged(amount: int)
signal enemy_damaged(index: int, damage: int)
signal card_drawn(card: CardData)
signal card_played(card: CardData)
signal attention_changed(current: int, max_: int)
signal player_died
signal deck_changed
signal quiddity_changed(amount: int, total: int)
signal weapon_used(target_index: int, damage: int)
signal enemy_died(index: int)

# Weapon System
var equipped_weapon_id: String = ""
var weapon_charge: int = 0
var weapon_max_charge: int = 0
var weapon_damage_min: int = 0
var weapon_damage_max: int = 0

# Shield System
var equipped_shield_id: String = ""
var shield_block: int = 0
var shield_retributive: int = 0
var shield_special_used: bool = false
var shield_type: String = ""

# Trinket System
var equipped_trinket_id: String = ""
var trinket_faction: String = ""
var trinket_effects: Dictionary = {}
var trinket_free_spell_used: bool = false

func setup(p_deck: Array):
	# Convert String IDs to CardData objects if needed
	deck.clear()
	for item in p_deck:
		if item is String:
			var card = CardDB.get_card(item)
			if card:
				deck.append(card)
			else:
				push_warning("CombatManager: Unknown card ID '%s', skipping" % item)
		elif item is CardData:
			deck.append(item)
		else:
			push_warning("CombatManager: Invalid deck item type: %s" % typeof(item))
	deck.shuffle()

func start_combat(enemy_data: Array, p_deck: Array = []):
	# Fallback: if no deck provided, try GameState then CardDB starter deck
	if p_deck.is_empty():
		if GameState.player_deck.size() > 0:
			p_deck = GameState.player_deck.duplicate()
			print("CombatManager: Using GameState.player_deck (%d cards)" % p_deck.size())
		elif CardDB.starter_deck.size() > 0:
			p_deck = CardDB.starter_deck.duplicate()
			print("CombatManager: Using CardDB.starter_deck (%d cards)" % p_deck.size())
		else:
			push_warning("CombatManager: No deck available!")
	
	if p_deck.size() > 0:
		setup(p_deck)

	hand.clear()
	discard_pile.clear()
	enemies.clear()
	summons.clear()
	player_dots.clear()
	pact_queue.clear()
	active_traps.clear()
	_first_played_cards.clear()
	player_charge = 0
	charge_revealed = false
	player_shield = 0
	player_attention = 0
	player_quiddity = 0
	quiddity_this_combat = 0
	is_boss_mode = false
	boss = null
	turn_count = 0
	player_last_damage = 10  # Reset for Eidolon tracking
	player_stake = 0
	current_stake = 0  # Reset stake each combat
	
	# Tutorial safety: player cannot die in tutorial
	if tutorial_mode:
		player_hp = max(player_hp, 1)
		print("[CombatManager] Tutorial mode active: HP floor at 1")

	# Load equipped weapon, shield, and trinket from GameState
	_load_equipped_weapon()
	_load_equipped_shield()
	_load_equipped_trinket()

	for ed in enemy_data:
		enemies.append(ed)

	combat_active = true
	is_player_turn = true

	# Apply trinket combat-start effects
	_apply_trinket_at_combat_start()

	_draw_cards(5 - player_stake)
	combat_started.emit()
	_update_attention_state()
	turn_started.emit(true)

func _load_equipped_weapon():
	"""Load weapon data from GameState equipment."""
	var weapon_id = GameState.equipped_weapon
	if weapon_id.is_empty():
		return
	var data = GameState.get_equipment_data(weapon_id, "weapon")
	if data.is_empty():
		return
	
	equipped_weapon_id = weapon_id
	weapon_damage_min = data.get("damage_min", 0)
	weapon_damage_max = data.get("damage_max", 0)
	weapon_max_charge = data.get("charge", 0)
	weapon_charge = data.get("start_ready", false) as int * weapon_max_charge
	print("CombatManager: Equipped %s (%d-%d dmg, charge %d/%d)" % [
		data.get("name", weapon_id), weapon_damage_min, weapon_damage_max,
		weapon_charge, weapon_max_charge
	])

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
	
	if "spell cards cost" in lower and "less" in lower:
		trinket_effects["spell_cost_reduction"] = 1
	if "once per combat" in lower and "free spell" in lower:
		trinket_effects["free_spell_per_combat"] = true
		trinket_free_spell_used = false
	if "healing" in lower and "+2" in lower:
		trinket_effects["healing_bonus"] = 2
	if "lose" in lower and "hp" in lower and "quiddity" in lower:
		trinket_effects["hp_cost_at_start"] = 3
		trinket_effects["quiddity_at_start"] = 6
	if "free" in lower and "summon" in lower:
		trinket_effects["free_summon"] = true
	if "+1 max summons" in lower:
		trinket_effects["max_summons_bonus"] = 1
	if "goblin summons" in lower and "+1 hp" in lower:
		trinket_effects["goblin_summon_hp_bonus"] = 1
	if "elemental" in lower and "charge" in lower and "faster" in lower:
		trinket_effects["elemental_charge_bonus"] = 1
	if "+2 attention" in lower or "attention start" in lower:
		trinket_effects["attention_start_bonus"] = 2
	if "below 25%" in lower and "block" in lower:
		trinket_effects["survivor_block_threshold"] = 0.25
		trinket_effects["survivor_block_amount"] = 3
	if "drawing costs hp" in lower or "deck is your hp" in lower:
		trinket_effects["draw_costs_hp"] = true
		trinket_effects["draw_hp_cost"] = 1
	if "reshuffle heals" in lower:
		trinket_effects["reshuffle_heals"] = true

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
		var drone = SummonData.new(
			"Assembly Drone",
			8,
			2,
			["construct", "machine"],
			1,
			2
		)
		summons.append(drone)
		print("CombatManager: Assembly Core summoned a drone!")
	
	# Veil Piercer: +2 Attention start
	if trinket_effects.has("attention_start_bonus"):
		player_attention += trinket_effects["attention_start_bonus"]
		print("CombatManager: Veil Piercer +%d Attention at start" % trinket_effects["attention_start_bonus"])
	
	trinket_free_spell_used = false

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
		if card.card_type == "Special" or card.card_type == "special" or card.card_type == "Direct" or card.faction == "Arcane":
			cost = max(0, cost - trinket_effects["spell_cost_reduction"])
			print("CombatManager: Crystal Focus reduced spell cost to %d" % cost)
	
	# Crystal Focus: once per combat free spell
	if trinket_effects.has("free_spell_per_combat") and not trinket_free_spell_used:
		if card.card_type == "Special" or card.card_type == "special" or card.card_type == "Direct" or card.faction == "Arcane":
			trinket_free_spell_used = true
			cost = 0
			print("CombatManager: Crystal Focus free spell activated!")
	
	return cost

func _modify_max_summons_with_trinket(base_max: int) -> int:
	"""Apply trinket summon limit bonuses."""
	if equipped_trinket_id.is_empty():
		return base_max
	
	if trinket_effects.has("max_summons_bonus"):
		base_max += trinket_effects["max_summons_bonus"]
	
	return base_max

func _modify_summon_hp_with_trinket(base_hp: int, summon_name: String) -> int:
	"""Apply trinket summon HP bonuses."""
	if equipped_trinket_id.is_empty():
		return base_hp
	
	if trinket_effects.has("goblin_summon_hp_bonus"):
		if "goblin" in summon_name.to_lower():
			base_hp += trinket_effects["goblin_summon_hp_bonus"]
			print("CombatManager: Swarm Totem +%d HP for Goblin summon" % trinket_effects["goblin_summon_hp_bonus"])
	
	return base_hp


func _draw_cards(count: int):
	var drawn = 0
	var missing = 0
	
	for i in range(count):
		if deck.size() == 0:
			# Reshuffle first
			if trinket_effects.has("reshuffle_heals"):
				var old_hp = _player_hp
				_player_hp = _player_max_hp
				print("CombatManager: Grasping Shroud reshuffle healed to full! (%d -> %d)" % [old_hp, _player_hp])
			
			if discard_pile.size() > 0:
				print("CombatManager: Deck empty, reshuffling discard...")
				deck = discard_pile.duplicate()
				deck.shuffle()
				discard_pile.clear()
			else:
				# Both deck and discard empty — take existential damage
				missing += 1
				continue
		
		if deck.size() == 0:
			missing += 1
			continue
		
		var card = deck.pop_front()
		
		# Grasping Shroud: drawing costs HP
		if trinket_effects.has("draw_costs_hp"):
			var draw_cost = trinket_effects.get("draw_hp_cost", 1)
			_player_hp -= draw_cost
			print("CombatManager: Grasping Shroud draw cost: %d HP" % draw_cost)
			if tutorial_mode and _player_hp <= 0:
				_player_hp = 1
				print("[CombatManager] Tutorial safety: Shroud cost prevented, HP clamped to 1")
				missing += (count - i - 1)
				break
			elif _player_hp <= 0:
				_player_hp = 0
				print("CombatManager: Grasping Shroud killed player by drawing!")
				missing += (count - i - 1)  # Count remaining as missing
				break
		
		hand.append(card)
		card_drawn.emit(card)
		drawn += 1
	
	if missing > 0:
		var damage = missing * 5
		_player_hp -= damage
		player_damaged.emit(damage)
		print("CombatManager: DECK DEATH — drew %d cards from empty deck, took %d damage!" % [missing, damage])
		if tutorial_mode and _player_hp <= 0:
			_player_hp = 1
			print("[CombatManager] Tutorial safety: deck-death prevented, HP clamped to 1")
		elif _player_hp <= 0:
			_player_hp = 0
			player_died.emit()
			combat_active = false
	
	print("CombatManager: Drew %d cards (%d missing, took %d existential damage)" % [drawn, missing, missing * 5])

func set_stake(stake_amount: int):
	"""Set stake amount (alias for stake_cards for UI compatibility)."""
	stake_cards(stake_amount)

func stake_cards(stake_amount: int):
	"""Set stake for the current combat. Stake reduces card draw, gives Quiddity 1:1.
	Refunds previous stake before applying new one."""
	if stake_amount < 0 or stake_amount > 5:
		return
	# Refund previous stake's quiddity
	var old_stake = player_stake
	player_quiddity -= old_stake
	quiddity_this_combat -= old_stake
	# Apply new stake
	player_stake = stake_amount
	current_stake = stake_amount
	player_quiddity += stake_amount
	quiddity_this_combat += stake_amount
	print("CombatManager: Staked %d (refunded %d) — draw %d cards, quiddity %d" % [stake_amount, old_stake, 5 - stake_amount, player_quiddity])

func use_weapon(target_index: int = 0) -> bool:
	"""Use equipped weapon if charged. Returns true if weapon was used."""
	if equipped_weapon_id.is_empty() or weapon_charge < weapon_max_charge:
		return false
	if target_index < 0 or target_index >= enemies.size() or enemies[target_index].hp <= 0:
		return false
	
	weapon_charge = 0
	
	# Base damage roll (attention adjudicates)
	var base_damage = weapon_damage_min
	if player_attention >= 8:
		base_damage = weapon_damage_max
	elif player_attention >= 4:
		base_damage = (weapon_damage_min + weapon_damage_max) / 2
	
	var damage = base_damage
	
	# Apply damage
	enemies[target_index].hp -= damage
	enemy_damaged.emit(target_index, damage)
	print("CombatManager: Weapon hit %s for %d damage (%d/%d HP)" % [enemies[target_index].name, damage, enemies[target_index].hp, enemies[target_index].max_hp])
	
	if enemies[target_index].hp <= 0:
		enemy_died.emit(target_index)
		_check_combat_end()
	
	weapon_used.emit(target_index, damage)
	return true

func end_player_turn():
	if not combat_active:
		return

	is_player_turn = false
	
	# Discard all remaining hand cards
	if not hand.is_empty():
		print("CombatManager: Discarding %d unplayed cards" % hand.size())
		for card in hand:
			discard_pile.append(card)
		hand.clear()

	_summon_attack_phase()
	_remove_dead_summons()

	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			var dot_dmg = enemies[i].tick_dots()
			if dot_dmg > 0:
				enemies[i].hp -= dot_dmg
				enemy_damaged.emit(i, dot_dmg)
				print("CombatManager: %s takes %d DoT damage (%d/%d HP)" % [enemies[i].name, dot_dmg, enemies[i].hp, enemies[i].max_hp])

			if enemies[i].hp <= 0:
				print("CombatManager: %s died from DoT!" % enemies[i].name)
				continue

			_enemy_act(i)

	_remove_dead_summons()

	if _check_combat_end():
		return

	is_player_turn = true
	player_shield = 0
	turn_count += 1
	
	# Reset attention for new turn (pact debt will be added by _process_pact_queue)
	player_attention = 0
	if trinket_effects.has("attention_start_bonus"):
		player_attention += trinket_effects["attention_start_bonus"]
		print("CombatManager: Veil Piercer +%d Attention at turn start" % trinket_effects["attention_start_bonus"])
	_update_attention_state()
	# Stake was set during previous player turn — used to reduce draw, then reset
	print("CombatManager: Turn start — Attention reset to %d, Stake %d (draw %d cards)" % [player_attention, player_stake, 5 - player_stake])

	for s in summons:
		s.has_attacked_this_turn = false
		s.just_summoned = false

	_summon_growth_phase()
	_process_pact_queue()
	_tick_player_dots()
	
	# Apply Floor 2 environmental effects (spore state)
	_apply_floor2_environmental_effects()
	
	# Tick weapon charge
	if equipped_weapon_id != "" and weapon_charge < weapon_max_charge:
		weapon_charge += 1
		print("CombatManager: Weapon charge %d/%d" % [weapon_charge, weapon_max_charge])

	# Check trinket passive triggers
	_check_trinket_passives()

	_draw_cards(5 - player_stake)
	
	# Stake is consumed after drawing — reset so player must re-stake next turn
	player_stake = 0
	current_stake = 0
	print("CombatManager: Cards drawn — Stake consumed, reset to 0")
	
	turn_started.emit(true)

func play_card(hand_index: int, target_index: int):
	if not is_player_turn or hand_index < 0 or hand_index >= hand.size():
		return

	var card = hand[hand_index]

	var effective_cost = max(1, card.attention_cost - next_card_cost_reduction)
	
	# Apply trinket cost modifications
	effective_cost = _modify_card_cost_with_trinket(effective_cost, card)
	
	# First keyword: first play of this card each combat costs 1 less
	if (card.keywords.has("first") or card.keywords.has("First")) and not _first_played_cards.has(card.card_name):
		effective_cost = max(1, effective_cost - 1)
		print("CombatManager: First trigger - %s costs 1 less on first play! (now %d)" % [card.card_name, effective_cost])
	
	if player_attention + effective_cost > 20:
		return

	# Apply cost reduction if any
	if next_card_cost_reduction > 0:
		print("CombatManager: Flow discount applied - %d Attention (reduced from %d)" % [effective_cost, card.attention_cost])
		next_card_cost_reduction = 0  # Consume the discount

	player_attention += effective_cost
	
	# Track this card as played (for First keyword)
	if not _first_played_cards.has(card.card_name):
		_first_played_cards.append(card.card_name)

	# Elemental CHARGE: playing Elemental cards adds +1 CHARGE
	if card.faction == "Elemental":
		var charge_gain = 1
		# Catalyst Ring: elemental cards charge faster
		if trinket_effects.has("elemental_charge_bonus"):
			charge_gain += trinket_effects["elemental_charge_bonus"]
			print("CombatManager: Catalyst Ring boosted CHARGE gain! +%d (was +1)" % charge_gain)
		player_charge = min(player_charge + charge_gain, MAX_CHARGE)
		print("CombatManager: CHARGE +%d! Current: %d/%d" % [charge_gain, player_charge, MAX_CHARGE])

	if card.keywords.has("bone") or card.keywords.has("Bone"):
		player_shield += card.attention_cost
		print("CombatManager: Bone trigger - +%d shield from attention cost" % card.attention_cost)

	if card.keywords.has("corruption") or card.keywords.has("Corruption"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("corruption", 2, 3, card.card_name, Color(0.6, 0.2, 0.8))
			enemies[target_index].add_dot(dot)
			print("CombatManager: Corruption applied to %s! 2 dmg/turn for 3 turns" % enemies[target_index].name)

	if card.keywords.has("poison") or card.keywords.has("Poison"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("poison", 3, 4, card.card_name, Color(0.2, 0.8, 0.3))
			enemies[target_index].add_dot(dot)
			print("CombatManager: Poison applied to %s! 3 dmg/turn for 4 turns" % enemies[target_index].name)

	if card.keywords.has("fire") or card.keywords.has("Fire"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("fire", 4, 2, card.card_name, Color(0.9, 0.3, 0.1))
			enemies[target_index].add_dot(dot)
			print("CombatManager: Fire applied to %s! 4 dmg/turn for 2 turns" % enemies[target_index].name)

	if card.keywords.has("pact") or card.keywords.has("Pact"):
		pact_queue.append({"card": card, "target_index": target_index})
		print("CombatManager: Pact sealed! %s will replay next turn (cost: %d Attention)" % [card.card_name, card.attention_cost])

	# Play card whoosh sound
	AudioManager.play_sfx("card_whoosh")

	if target_index >= 0:
		_resolve_damage(card, target_index)
	_apply_shield(card)
	_apply_heal(card)
	_apply_summon(card)
	_apply_trap(card)

	# General backfire rule: same-faction target doubles attention cost
	# Void keyword: card counts as having NO faction → prevents backfire
	if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
		var enemy = enemies[target_index]
		var card_effective_faction = ""

		# If card has Void, it counts as having no faction → no backfire
		if card.keywords.has("void") or card.keywords.has("Void"):
			card_effective_faction = ""  # Null faction
			print("CombatManager: Void active - %s counts as having no faction" % card.card_name)
		else:
			card_effective_faction = card.faction

		# Check if enemy shares the card's effective faction
		if card_effective_faction != "" and (enemy.has_keyword(card_effective_faction.to_lower()) or enemy.has_keyword(card_effective_faction)):
			player_attention += card.attention_cost
			print("CombatManager: BACKFIRE! %s shares %s faction - attention doubled to %d" % [enemy.name, card_effective_faction, player_attention])
		else:
			if card_effective_faction != "":
				print("CombatManager: No backfire - %s does not share %s faction" % [enemy.name, card_effective_faction])

	# Flow keyword: next card costs -2 Attention (min 1)
	if card.keywords.has("flow") or card.keywords.has("Flow"):
		next_card_cost_reduction = 2
		print("CombatManager: Flow trigger - next card costs -2 Attention (min 1)")

	if card.keywords.has("glitch") or card.keywords.has("Glitch"):
		if randf() < 0.25:
			_apply_glitch_effect(card)
		else:
			print("CombatManager: Glitch... but nothing happened (% chance failed)")

	hand.remove_at(hand_index)
	discard_pile.append(card)

	card_played.emit(card)
	_update_attention_state()
	attention_changed.emit(player_attention, 20)

func _resolve_damage(card: CardData, target_index: int):
	if card.damage_flat <= 0 and card.damage_dice == "":
		return

	if target_index < 0 or target_index >= enemies.size():
		return

	var enemy = enemies[target_index]
	if enemy.hp <= 0:
		return

	# Play weapon swing sound
	AudioManager.play_sfx("weapon_swing")

	var damage = 0

	if card.uses_dice:
		var dice_str = card.damage_dice
		if card.keywords.has("sharp") or card.keywords.has("Sharp"):
			dice_str = _upgrade_dice_for_sharp(dice_str)
			
		# Machine keyword: roll twice and average (reliable damage)
		if card.keywords.has("machine") or card.keywords.has("Machine"):
			var roll1 = _roll_dice(dice_str)
			var roll2 = _roll_dice(dice_str)
			damage = int((roll1 + roll2) / 2.0)
			print("CombatManager: Machine trigger - averaged %s: %d + %d = %d" % [dice_str, roll1, roll2, damage])
		else:
			damage = _roll_dice(dice_str)
			if card.keywords.has("sharp") or card.keywords.has("Sharp"):
				print("CombatManager: Sharp trigger - upgraded dice: %s = %d" % [dice_str, damage])
	else:
		if card.keywords.has("sharp") or card.keywords.has("Sharp"):
			damage = card.damage_flat + 1
			print("CombatManager: Sharp trigger - flat damage +1 = %d" % damage)
		else:
			damage = card.damage_flat

	damage = _apply_attention_multiplier(damage)

	var actual_damage = max(0, damage - enemy.defense)

	if card.keywords.has("sneaky") or card.keywords.has("Sneaky"):
		if not enemy.has_keyword("sneaky"):
			var sneaky_bonus = _roll_dice("2d6")
			actual_damage += sneaky_bonus
			print("CombatManager: Sneaky trigger - +%d bonus damage!" % sneaky_bonus)

	# Nature keyword: +2 flat damage per CHARGE
	if card.keywords.has("nature") or card.keywords.has("Nature"):
		if player_charge > 0:
			var nature_bonus = player_charge * 2
			actual_damage += nature_bonus
			if not charge_revealed:
				charge_revealed = true
				print("CombatManager: ⚡ CHARGE REVEALED! You've built %d elemental energy! Nature deals +%d damage!" % [player_charge, nature_bonus])
			else:
				print("CombatManager: Nature trigger - +%d damage from %d CHARGE" % [nature_bonus, player_charge])

	# Flow keyword: +1d6 per CHARGE (max +3d6), then CONSUMES all CHARGE
	if card.keywords.has("flow") or card.keywords.has("Flow"):
		if player_charge > 0:
			var flow_dice_count = min(player_charge, 3)
			var flow_bonus = _roll_dice("%dd6" % flow_dice_count)
			actual_damage += flow_bonus
			if not charge_revealed:
				charge_revealed = true
				print("CombatManager: ⚡ CHARGE REVEALED! You've built %d elemental energy! Flow adds +%dd6 = %d damage!" % [player_charge, flow_dice_count, flow_bonus])
			else:
				print("CombatManager: Flow trigger - +%dd6 = %d bonus damage from %d CHARGE" % [flow_dice_count, flow_bonus, player_charge])
			# Flow CONSUMES CHARGE (it's the spending side)
			print("CombatManager: Flow consumed all %d CHARGE!" % player_charge)
			player_charge = 0

	if actual_damage <= 0:
		AudioManager.play_sfx("miss_dodge")
		print("CombatManager: Attack missed or was fully blocked!")
	else:
		enemy.hp -= actual_damage
		player_last_damage = actual_damage  # Track for Eidolon mirror
		enemy_damaged.emit(target_index, actual_damage)
		print("CombatManager: Dealt %d damage to %s (%d/%d HP left)" % [actual_damage, enemy.name, enemy.hp, enemy.max_hp])

func _apply_attention_multiplier(damage: int) -> int:
	match current_attention_state:
		AttentionState.WHISPER:
			return max(1, damage / 2)
		AttentionState.BORROWED:
			return damage
		AttentionState.UNDEFINED:
			return damage * 2
		AttentionState.SCREAM:
			return damage * 3
	return damage

func _apply_shield(card: CardData):
	if card.shield_amount > 0:
		player_shield += card.shield_amount

func _apply_heal(card: CardData):
	if card.heal_amount > 0:
		var heal_amount = _modify_heal_with_trinket(card.heal_amount)
		_player_hp = min(_player_max_hp, _player_hp + heal_amount)
		print("CombatManager: Healed %d HP (base %d, trinket bonus %d)" % [
			heal_amount, card.heal_amount, heal_amount - card.heal_amount
		])

func _apply_summon(card: CardData):
	if card.summon_count <= 0:
		return

	for i in range(card.summon_count):
		var base_hp = card.summon_hp
		var modified_hp = _modify_summon_hp_with_trinket(base_hp, card.card_name)
		
		var summon = SummonData.new(
			card.card_name + " (Summon)",
			modified_hp,
			card.summon_attack,
			card.keywords,
			card.summon_growth_atk,
			card.summon_growth_hp
		)
		summons.append(summon)
		print("CombatManager: Summoned %s (%d HP, %d ATK, growth: +%d/%d)" % [summon.name, summon.hp, summon.attack, summon.growth_atk, summon.growth_hp])

		if summon.has_keyword("precision"):
			_summon_attack_single(summon)
			print("CombatManager: Precision trigger - %s attacks immediately!" % summon.name)

func _summon_attack_single(summon: SummonData):
	if summon.hp <= 0:
		return

	var living_enemies = []
	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			living_enemies.append(i)

	if living_enemies.is_empty():
		return

	var target = living_enemies[randi() % living_enemies.size()]
	var damage = summon.attack

	if summon.has_keyword("machine"):
		damage = max(1, damage / 2) + max(1, damage / 2)

	enemies[target].hp -= damage
	print("CombatManager: %s attacks %s for %d damage" % [summon.name, enemies[target].name, damage])
	enemy_damaged.emit(target, damage)

func _summon_attack_phase():
	for summon in summons:
		if summon.hp <= 0:
			continue
		if summon.has_attacked_this_turn:
			continue
		if summon.just_summoned and not summon.has_keyword("fast"):
			print("CombatManager: %s has summoning sickness - cannot attack" % summon.name)
			continue

		_summon_attack_single(summon)
		summon.has_attacked_this_turn = true

func _summon_growth_phase():
	for summon in summons:
		if summon.hp > 0:
			summon.grow()

func _remove_dead_summons():
	var alive: Array[SummonData] = []
	for s in summons:
		if s.hp > 0:
			alive.append(s)
		else:
			print("CombatManager: %s destroyed!" % s.name)
	summons.clear()
	for s in alive:
		summons.append(s)

func _process_pact_queue():
	if pact_queue.is_empty():
		return

	print("CombatManager: Pact turn - %d cards replaying..." % pact_queue.size())

	for entry in pact_queue:
		var card = entry["card"] as CardData
		var target_index = entry["target_index"]

		player_attention += card.attention_cost
		print("CombatManager: Pact - %s costs %d Attention (debt possible)" % [card.card_name, card.attention_cost])

		if target_index < 0 or target_index >= enemies.size() or enemies[target_index].hp <= 0:
			var living = []
			for i in range(enemies.size()):
				if enemies[i].hp > 0:
					living.append(i)
			if living.size() > 0:
				target_index = living[randi() % living.size()]
			else:
				target_index = -1

		if target_index >= 0:
			if card.keywords.has("corruption") or card.keywords.has("Corruption"):
				var dot = DoTData.new("corruption", 2, 3, card.card_name + " (Pact)", Color(0.6, 0.2, 0.8))
				enemies[target_index].add_dot(dot)
			if card.keywords.has("poison") or card.keywords.has("Poison"):
				var dot = DoTData.new("poison", 3, 4, card.card_name + " (Pact)", Color(0.2, 0.8, 0.3))
				enemies[target_index].add_dot(dot)
			if card.keywords.has("fire") or card.keywords.has("Fire"):
				var dot = DoTData.new("fire", 4, 2, card.card_name + " (Pact)", Color(0.9, 0.3, 0.1))
				enemies[target_index].add_dot(dot)

		if target_index >= 0:
			_resolve_damage(card, target_index)
		_apply_shield(card)
		_apply_heal(card)
		_apply_summon(card)
		_apply_trap(card)

		card_played.emit(card)
		_update_attention_state()
		attention_changed.emit(player_attention, 20)
		print("CombatManager: Pact - %s replayed!" % card.card_name)

	pact_queue.clear()

func _apply_floor2_environmental_effects():
	"""Apply Floor 2 spore state environmental effects at end of player turn."""
	# Pool effect: heal or toxic damage
	var pool_effect = GameState.floor2_pool_effect
	if pool_effect != 0:
		if pool_effect > 0:
			# Healing pool
			_player_hp = min(_player_max_hp, _player_hp + pool_effect)
			print("CombatManager: Bioluminescent pool heals %d HP" % pool_effect)
		else:
			# Toxic pool
			var toxic_damage = -pool_effect
			_player_hp -= toxic_damage
			player_damaged.emit(toxic_damage)
			print("CombatManager: Toxic pool deals %d damage!" % toxic_damage)
	
	# Spore damage
	var spore_dmg = GameState.floor2_spore_damage
	if spore_dmg > 0:
		_player_hp -= spore_dmg
		player_damaged.emit(spore_dmg)
		print("CombatManager: Spore cloud deals %d damage!" % spore_dmg)

func _tick_player_dots():
	var total_damage = 0
	var alive: Array[DoTData] = []
	for dot in player_dots:
		var dmg = dot.tick()
		total_damage += dmg
		print("CombatManager: %s DoT ticks for %d damage! (%d turns left)" % [dot.type, dmg, dot.duration])
		if not dot.is_expired():
			alive.append(dot)
		else:
			print("CombatManager: %s DoT expired" % dot.type)
	player_dots.clear()
	for dot in alive:
		player_dots.append(dot)

	if total_damage > 0:
		GameState.damage_player(total_damage)
		player_damaged.emit(total_damage)

func _apply_trap(card: CardData):
	"""Cast a trap: pay cost, place in active_traps. Effect triggers on enemy action."""
	var cost = card.trap_cast_cost if card.trap_cast_cost > 0 else card.attention_cost
	player_attention += cost
	active_traps.append({"card": card, "caster_turn": turn_count})
	print("CombatManager: TRAP CAST — %s (cost %d Attention). Trigger: %s | Disarm: %s" % [
		card.card_name, cost, card.trap_trigger_action, card.trap_disarm_action
	])

func _check_traps(enemy_action: EnemyAction, enemy_index: int) -> bool:
	"""Check if any active trap triggers on this enemy action. Returns true if a trap fired."""
	var action_str = ""
	match enemy_action:
		EnemyAction.ATTACK:
			action_str = "Attack"
		EnemyAction.DEFEND:
			action_str = "Defend"
		EnemyAction.SPECIAL:
			action_str = "Special"
	
	var i = 0
	while i < active_traps.size():
		var trap = active_traps[i]
		var card = trap.card as CardData
		
		# Disarm: enemy performs disarm action → trap fizzles, player pays disarm cost
		if card.trap_disarm_action != "" and action_str == card.trap_disarm_action:
			player_attention += card.trap_disarm_cost
			print("CombatManager: TRAP DISARMED — %s fizzled! (disarm cost: %d Attention)" % [
				card.card_name, card.trap_disarm_cost
			])
			active_traps.remove_at(i)
			continue
		
		# Trigger: enemy performs trigger action → trap fires
		var trigger_match = false
		if card.trap_trigger_action == "Move":
			# "Move" maps to ATTACK (enemy moves to attack)
			trigger_match = (enemy_action == EnemyAction.ATTACK)
		elif card.trap_trigger_action != "":
			trigger_match = (action_str == card.trap_trigger_action)
		
		if trigger_match:
			_trigger_trap(card, enemy_index)
			active_traps.remove_at(i)
			return true
		
		i += 1
	return false

func _trigger_trap(card: CardData, enemy_index: int):
	"""Execute trap effect."""
	var enemy = enemies[enemy_index]
	match card.card_name:
		"Gear Shield":
			# Block next attack: nullify damage this turn
			enemy.attack = 0
			print("CombatManager: TRAP TRIGGERED — Gear Shield blocks %s's attack!" % enemy.name)
		"Tripwire":
			# 3 damage + lose next action
			var dmg = 3
			enemy.hp -= dmg
			enemy_damaged.emit(enemy_index, dmg)
			# Skip next action by advancing index
			enemy.current_action_index += 1
			print("CombatManager: TRAP TRIGGERED — Tripwire snags %s for %d damage! They lose their next action." % [
				enemy.name, dmg
			])
			if enemy.hp <= 0:
				print("CombatManager: %s died from trap damage!" % enemy.name)
		_:
			print("CombatManager: TRAP TRIGGERED — %s on %s (generic, no specific effect)" % [
				card.card_name, enemy.name
			])

func _apply_glitch_effect(card: CardData):
	"""Glitch: 25% chance for bonus effect based on card type"""
	match card.card_type:
		"Attack", "Defense", "Skill":
			# Spells: Heal 5 HP
			_player_hp = min(_player_max_hp, _player_hp + 5)
			print("CombatManager: GLITCH! %s glitched - +5 HP heal!" % card.card_name)
		"Summon":
			# Summons: Grant next card cost reduction
			next_card_cost_reduction = 2
			print("CombatManager: GLITCH! %s glitched - next card costs -2 Attention!" % card.card_name)
		"Trap":
			# Traps: Deal 1d4 damage to all enemies
			var glitch_damage = _roll_dice("1d4")
			for i in range(enemies.size()):
				if enemies[i].hp > 0:
					enemies[i].hp -= glitch_damage
					enemy_damaged.emit(i, glitch_damage)
					print("CombatManager: GLITCH! %s glitched - %s takes %d trap damage!" % [card.card_name, enemies[i].name, glitch_damage])
		_:
			print("CombatManager: GLITCH! %s glitched - but nothing special happened..." % card.card_name)

func _upgrade_dice_for_sharp(dice_string: String) -> String:
	var parts = dice_string.split("d")
	if parts.size() == 2:
		var count = int(parts[0]) + 1
		var sides = int(parts[1])
		return "%dd%d" % [count, sides]
	return dice_string

func _roll_dice(dice_string: String) -> int:
	var parts = dice_string.split("d")
	if parts.size() != 2:
		return 0

	var count = int(parts[0])
	var sides = int(parts[1])
	var total = 0

	for i in range(count):
		total += randi() % sides + 1

	return total

func _enemy_act(index: int):
	# Boss is always enemy index 0 in boss mode
	if is_boss_mode and index == 0 and boss != null:
		_boss_turn()
		return
	
	var enemy = enemies[index]
	if enemy.hp <= 0:
		return

	var action = enemy.action_pattern[enemy.current_action_index % enemy.action_pattern.size()]
	enemy.current_action_index += 1
	
	# Check traps BEFORE enemy acts
	if _check_traps(action, index):
		# Trap fired — enemy's action was interrupted
		return
	
	match action:
		EnemyAction.ATTACK:
			var damage = enemy.attack
			damage = _apply_enemy_attention_multiplier(damage)

			var target_summon = false
			var target_summon_index = -1
			if summons.size() > 0 and randf() < 0.5:
				var living_summons = []
				for i in range(summons.size()):
					if summons[i].hp > 0:
						living_summons.append(i)
				if living_summons.size() > 0:
					target_summon = true
					target_summon_index = living_summons[randi() % living_summons.size()]

			if target_summon and target_summon_index >= 0:
				var summon = summons[target_summon_index]
				var actual_damage = max(0, damage)
				summon.hp -= actual_damage
				print("CombatManager: %s attacks %s for %d damage (%d/%d HP left)" % [
					enemy.name, summon.name, actual_damage, summon.hp, summon.max_hp
				])
				if summon.hp <= 0:
					print("CombatManager: %s destroys %s!" % [enemy.name, summon.name])
			else:
				# Apply shield to damage
				var enemy_idx = enemies.find(enemy)
				var shield_result = _apply_shield_to_damage(damage, enemy_idx)
				
				if shield_result.negated:
					print("CombatManager: %s's attack was completely negated by shield!" % enemy.name)
				else:
					var actual_damage = max(0, shield_result.damage)
					_player_hp -= actual_damage
					player_damaged.emit(actual_damage)
					
					# Log shield block
					if shield_result.blocked > 0:
						print("CombatManager: Shield blocked %d damage from %s" % [shield_result.blocked, enemy.name])
					
					# Log retributive damage
					if shield_result.retributive > 0:
						print("CombatManager: Shield retaliated %d damage to %s" % [shield_result.retributive, enemy.name])
						# Check if enemy died from retributive
						if enemy.hp <= 0:
							print("CombatManager: %s died from retributive shield damage!" % enemy.name)

		EnemyAction.DEFEND:
			enemy.defense += 3
		EnemyAction.SPECIAL:
			_enemy_special(index)

func _apply_enemy_attention_multiplier(damage: int) -> int:
	match current_attention_state:
		AttentionState.WHISPER:
			return max(1, damage / 2)
		AttentionState.BORROWED:
			return damage
		AttentionState.UNDEFINED:
			return damage * 2
		AttentionState.SCREAM:
			return damage * 3
	return damage

func _check_combat_end() -> bool:
	var all_enemies_dead = true
	for enemy in enemies:
		if enemy.hp > 0:
			all_enemies_dead = false
			break
	
	if all_enemies_dead:
		combat_active = false
		if is_boss_mode:
			print("CombatManager: BOSS DEFEATED — %s falls!" % boss.name if boss else "BOSS")
			combat_ended.emit(true)
			return true
		combat_ended.emit(true)
		return true
	
	# Tutorial safety: player cannot die in tutorial
	if tutorial_mode and _player_hp <= 0:
		_player_hp = 1
		print("[CombatManager] Tutorial safety: HP clamped to 1")
		return false
	
	if _player_hp <= 0:
		combat_active = false
		combat_ended.emit(false)
		return true
	
	return false

func _update_attention_state():
	var attention = player_attention
	if attention <= 5:
		current_attention_state = AttentionState.WHISPER
	elif attention <= 10:
		current_attention_state = AttentionState.BORROWED
	elif attention <= 15:
		current_attention_state = AttentionState.UNDEFINED
	else:
		current_attention_state = AttentionState.SCREAM

func enable_boss_mode(boss_name: String):
	"""Activate boss AI for this combat"""
	is_boss_mode = true
	boss = BossAI.create_boss(boss_name)
	boss_ai = BossAI.new()
	print("CombatManager: BOSS MODE — %s enters the arena!" % boss.name)

func _boss_turn():
	"""Execute boss turn using BossAI"""
	if boss == null or enemies.size() == 0 or enemies[0].hp <= 0:
		return
	
	var result = BossAI.execute_turn(boss, self)
	
	# Apply boss damage
	if result.damage > 0:
		var damage = _apply_enemy_attention_multiplier(result.damage)
		var actual_damage = max(0, damage - player_shield)
		_player_hp -= actual_damage
		player_damaged.emit(actual_damage)
		print("CombatManager: %s deals %d damage! (%s)" % [boss.name, actual_damage, result.effect])
	
	# Boss heal
	if result.heal > 0:
		enemies[0].hp = min(enemies[0].max_hp, enemies[0].hp + result.heal)
		print("CombatManager: %s heals %d HP! (%s) — now %d/%d" % [boss.name, result.heal, result.effect, enemies[0].hp, enemies[0].max_hp])
	
	# Boss summon minion
	if result.summon:
		var minion = EnemyData.new("%s Minion" % boss.name, 10, 3)
		enemies.append(minion)
		print("CombatManager: %s summons a minion! (%s)" % [boss.name, result.effect])
	
	# Phase change announcement
	if result.effect == "PHASE_CHANGE":
		print("CombatManager: ⚠ %s enters PHASE 2!" % boss.name)

func _enemy_special(index: int):
	"""Execute enemy SPECIAL action based on faction/keywords."""
	var enemy = enemies[index]
	
	# Faction-based specials
	if enemy.faction == "Construct":
		# Gear up: +2 defense and next attack deals +2
		enemy.defense += 2
		enemy.attack += 2
		print("CombatManager: %s SPECIAL — gears shift! +2 DEF, +2 ATK" % enemy.name)
		
	elif enemy.faction == "Goblin":
		# Sneaky: heal 3 HP
		var heal = 3
		enemy.hp = min(enemy.max_hp, enemy.hp + heal)
		print("CombatManager: %s SPECIAL — scurries away! +%d HP (%d/%d)" % [
			enemy.name, heal, enemy.hp, enemy.max_hp
		])
		
	elif enemy.faction == "Undead":
		# Bone call: summon a bone minion (weak)
		if enemies.size() < 4:
			var minion = EnemyData.new("Bone Minion", 5, 2, 0, [EnemyAction.ATTACK], ["Bone"])
			minion.faction = "Undead"
			enemies.append(minion)
			print("CombatManager: %s SPECIAL — raises a Bone Minion!" % enemy.name)
		else:
			# Full field: drain life instead
			var drain = 2
			_player_hp -= drain
			player_damaged.emit(drain)
			enemy.hp = min(enemy.max_hp, enemy.hp + drain)
			print("CombatManager: %s SPECIAL — life drain! %d damage, heals %d" % [
				enemy.name, drain, drain
			])
			
	elif enemy.faction == "Elemental":
		# Charge up: gain 2 CHARGE (applies to player for elemental cards)
		player_charge = min(MAX_CHARGE, player_charge + 2)
		print("CombatManager: %s SPECIAL — elemental surge! Player CHARGE +2 (now %d/%d)" % [
			enemy.name, player_charge, MAX_CHARGE
		])
		
	elif enemy.faction == "Aberration":
		# Glitch: random effect
		var roll = randi() % 3
		match roll:
			0:
				# Confuse: player loses 1 Attention
				player_attention = max(0, player_attention - 1)
				print("CombatManager: %s SPECIAL — glitches reality! -1 Attention" % enemy.name)
			1:
				# Mutate: +3 HP
				var heal = 3
				enemy.hp = min(enemy.max_hp, enemy.hp + heal)
				print("CombatManager: %s SPECIAL — mutates! +%d HP" % [enemy.name, heal])
			2:
				# Echo: attack again
				var dmg = enemy.attack
				_player_hp -= dmg
				player_damaged.emit(dmg)
				print("CombatManager: %s SPECIAL — echoes! %d damage" % [enemy.name, dmg])
				
	elif enemy.faction == "Demon":
		# Corrupt: apply corruption DoT to player
		var dot = DoTData.new("corruption", 2, 3, enemy.name + " (Corrupt)", Color(0.6, 0.2, 0.8))
		player_dots.append(dot)
		print("CombatManager: %s SPECIAL — corrupts! 2 dmg/turn for 3 turns" % enemy.name)
		
	else:
		# Generic: heal 2
		var heal = 2
		enemy.hp = min(enemy.max_hp, enemy.hp + heal)
		print("CombatManager: %s SPECIAL — recovers! +%d HP" % [enemy.name, heal])
	if summons.size() == 0:
		return -1

	var lowest_index = 0
	var lowest_hp = summons[0].hp

	for i in range(1, summons.size()):
		if summons[i].hp < lowest_hp:
			lowest_hp = summons[i].hp
			lowest_index = i

	return lowest_index

func cast_death_card(discard_index: int, target_index: int = 0) -> bool:
	if not is_player_turn:
		return false

	if discard_index < 0 or discard_index >= discard_pile.size():
		return false

	var card = discard_pile[discard_index]

	if not (card.keywords.has("death") or card.keywords.has("Death")):
		print("CombatManager: Card %s doesn't have Death keyword!" % card.card_name)
		return false

	var sacrifice_index = _find_lowest_hp_summon()
	if sacrifice_index < 0:
		print("CombatManager: No summon available to sacrifice!")
		return false

	var sacrifice = summons[sacrifice_index]
	print("CombatManager: Death - sacrificing %s (%d/%d HP)" % [sacrifice.name, sacrifice.hp, sacrifice.max_hp])

	if player_attention + card.attention_cost > 20:
		print("CombatManager: Not enough attention to cast %s from discard" % card.card_name)
		return false

	player_attention += card.attention_cost

	summons.remove_at(sacrifice_index)
	print("CombatManager: %s sacrificed!" % sacrifice.name)

	discard_pile.remove_at(discard_index)

	if card.keywords.has("corruption") or card.keywords.has("Corruption"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("corruption", 2, 3, card.card_name + " (Death)", Color(0.6, 0.2, 0.8))
			enemies[target_index].add_dot(dot)
	if card.keywords.has("poison") or card.keywords.has("Poison"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("poison", 3, 4, card.card_name + " (Death)", Color(0.2, 0.8, 0.3))
			enemies[target_index].add_dot(dot)
	if card.keywords.has("fire") or card.keywords.has("Fire"):
		if target_index >= 0 and target_index < enemies.size() and enemies[target_index].hp > 0:
			var dot = DoTData.new("fire", 4, 2, card.card_name + " (Death)", Color(0.9, 0.3, 0.1))
			enemies[target_index].add_dot(dot)

	if card.keywords.has("bone") or card.keywords.has("Bone"):
		player_shield += card.attention_cost
		print("CombatManager: Bone trigger (Death) - +%d shield" % card.attention_cost)

	if target_index >= 0:
		_resolve_damage(card, target_index)
	_apply_shield(card)
	_apply_heal(card)
	_apply_summon(card)
	_apply_trap(card)

	card_played.emit(card)
	_update_attention_state()
	attention_changed.emit(player_attention, 20)

	print("CombatManager: Death - %s cast from discard!" % card.card_name)
	return true

func get_discard_with_death() -> Array[CardData]:
	var result: Array[CardData] = []
	for card in discard_pile:
		if card.keywords.has("death") or card.keywords.has("Death"):
			result.append(card)
	return result

func flee_combat() -> bool:
	"""Player flees combat — applies costs and ends with defeat state.
	
	Costs:
		- 1d6 parting damage (enemy gets a free hit as you turn)
		- Lose 1 random card from deck
		- Combat quiddity evaporates (no post-combat rewards)
		- 3-second No Aggro grace period to escape
	
	Returns true if flee succeeded.
	"""
	if not combat_active:
		return false
	
	# Parting damage: 1d6
	var parting_damage = randi() % 6 + 1
	_player_hp -= parting_damage
	player_damaged.emit(parting_damage)
	FloatingText.spawn_damage(self, Vector2(960, 540), parting_damage)
	print("CombatManager: FLEE — parting damage %d! HP: %d/%d" % [parting_damage, _player_hp, _player_max_hp])
	
	# Lose 1 random card from deck
	if GameState.player_deck.size() > 0:
		var lost_index = randi() % GameState.player_deck.size()
		var lost_card = GameState.player_deck[lost_index]
		GameState.player_deck.remove_at(lost_index)
		deck_changed.emit()
		FloatingText.spawn(self, Vector2(960, 500), "Lost: %s" % lost_card.card_name, Color(0.8, 0.2, 0.2))
		print("CombatManager: FLEE — lost card %s" % lost_card.card_name)
	else:
		FloatingText.spawn(self, Vector2(960, 500), "No cards to lose!", Color(0.8, 0.2, 0.2))
	
	# Activate No Aggro state (3 seconds)
	GameState.activate_no_aggro(3.0)
	
	# End combat as defeat (room stays uncleared, enemies persist)
	combat_active = false
	combat_ended.emit(false)
	
	# Check if player died from parting damage
	if _player_hp <= 0:
		_player_hp = 1  # Minimum 1 HP — you fled, you didn't die
		print("CombatManager: FLEE — parting damage would have killed, saved at 1 HP")
	
	print("CombatManager: FLEE successful! No Aggro active for 3 seconds.")
	return true
