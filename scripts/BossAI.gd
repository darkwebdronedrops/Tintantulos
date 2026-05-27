extends Node
class_name BossAI

# BossAI - Unique behaviors for each Floor 3 boss

enum BossType {
	NONE,
	THE_CALDERA,
	GEAR_MOTHER,
	GOBLIN_KING_GRIMGUT,
	THE_CONSUMPTION,
	THE_INTERVIEW,
	THE_UNSENT_LETTER,
	THE_EIDOLON
}

class BossBehavior:
	var name: String
	var max_hp: int
	var attack: int
	var special_cooldown: int = 0
	var special_ready: bool = false
	var turn_counter: int = 0
	var type: BossType
	
	# Phase management
	var current_phase: int = 1
	var phase_thresholds: Array[int] = []
	
	func _init(n: String, hp: int, atk: int, t: BossType):
		name = n
		max_hp = hp
		attack = atk
		type = t

static func create_boss(boss_name: String) -> BossBehavior:
	match boss_name:
		"TheCaldera":
			return BossBehavior.new("The Caldera", 50, 8, BossType.THE_CALDERA)
		"GearMother":
			return BossBehavior.new("Gear Mother", 60, 6, BossType.GEAR_MOTHER)
		"GoblinKingGrimgut":
			return BossBehavior.new("Goblin King Grimgut", 45, 10, BossType.GOBLIN_KING_GRIMGUT)
		"TheConsumption":
			return BossBehavior.new("The Consumption", 80, 12, BossType.THE_CONSUMPTION)
		"TheInterview":
			return BossBehavior.new("The Interview", 70, 15, BossType.THE_INTERVIEW)
		"TheUnsentLetter":
			return BossBehavior.new("The Unsent Letter", 55, 7, BossType.THE_UNSENT_LETTER)
		"TheEidolon":
			return BossBehavior.new("The Eidolon", 65, 12, BossType.THE_EIDOLON)
		_:
			return BossBehavior.new("Boss", 40, 5, BossType.NONE)

static func execute_turn(boss: BossBehavior, combat_manager: CombatManager) -> Dictionary:
	"""Execute boss turn, return {damage: int, effect: String, heal: int}"""
	var result = {
		"damage": 0,
		"effect": "",
		"heal": 0,
		"summon": false,
		"buff": false
	}
	
	boss.turn_counter += 1
	boss.special_cooldown = max(0, boss.special_cooldown - 1)
	
	# Check phase transition
	var current_hp_percent = float(combat_manager.enemies[0].hp) / combat_manager.enemies[0].max_hp if combat_manager.enemies.size() > 0 else 1.0
	if current_hp_percent < 0.5 and boss.current_phase == 1:
		boss.current_phase = 2
		result.effect = "PHASE_CHANGE"
	
	match boss.type:
		BossType.THE_CALDERA:
			result = _the_caldera_turn(boss, combat_manager)
		BossType.GEAR_MOTHER:
			result = _gear_mother_turn(boss, combat_manager)
		BossType.GOBLIN_KING_GRIMGUT:
			result = _goblin_king_turn(boss, combat_manager)
		BossType.THE_CONSUMPTION:
			result = _the_consumption_turn(boss, combat_manager)
		BossType.THE_INTERVIEW:
			result = _the_interview_turn(boss, combat_manager)
		BossType.THE_UNSENT_LETTER:
			result = _the_unsent_letter_turn(boss, combat_manager)
		BossType.THE_EIDOLON:
			result = _the_eidolon_turn(boss, combat_manager)
		_:
			# Default: simple attack
			result.damage = boss.attack
	
	return result

# === THE CALDERA ===
# Volcanic forge entity. Builds heat, then erupts.
static func _the_caldera_turn(boss: BossBehavior, _cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	if boss.turn_counter % 3 == 0:
		# Eruption: Heavy damage every 3rd turn
		result.damage = boss.attack * 2
		result.effect = "ERUPTION"
	elif boss.current_phase == 2 and boss.turn_counter % 2 == 0:
		# Phase 2: Summon magma minions
		result.damage = boss.attack
		result.summon = true
		result.effect = "SUMMON_MAGMA"
	else:
		# Heat buildup
		result.damage = boss.attack
		boss.attack += 1  # Gets stronger each turn
	
	return result

# === GEAR MOTHER ===
# Spawns constructs, repairs herself.
static func _gear_mother_turn(boss: BossBehavior, _cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	if boss.turn_counter % 4 == 0:
		# Repair protocol
		result.heal = 10
		result.effect = "REPAIR"
	elif boss.turn_counter % 2 == 0:
		# Spawn minion
		result.damage = boss.attack
		result.summon = true
		result.effect = "ASSEMBLE"
	else:
		result.damage = boss.attack
	
	return result

# === GOBLIN KING GRIMGUT ===
# Swarm tactics, gets stronger as minions die.
static func _goblin_king_turn(boss: BossBehavior, _cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	# WAR_CRY energy builds
	if boss.turn_counter % 3 == 0:
		result.damage = boss.attack + boss.turn_counter
		result.summon = true
		result.effect = "WAR_CRY"
	else:
		result.damage = boss.attack
		result.summon = (boss.turn_counter % 2 == 0)
		result.effect = "GOBLIN_SWARM"
	
	return result

# === THE CONSUMPTION ===
# Devours everything. Gains HP from damage dealt.
static func _the_consumption_turn(boss: BossBehavior, _cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	result.damage = boss.attack
	
	# Devour: Heals for 50% of damage dealt
	result.heal = result.damage / 2
	result.effect = "DEVOUR"
	
	if boss.current_phase == 2:
		# Phase 2: Ravenous hunger
		result.damage = int(result.damage * 1.5)
		result.effect = "RAVENOUS"
	
	return result

# === THE INTERVIEW ===
# Questions your worth. Inflicts mental damage (corruption/attention effects).
static func _the_interview_turn(boss: BossBehavior, cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	# Different "questions" each turn
	var questions = ["DOUBT", "REGRET", "FEAR", "SHAME", "WORTH"]
	var question = questions[boss.turn_counter % questions.size()]
	
	result.effect = question
	
	match question:
		"DOUBT":
			# Forces discard
			result.damage = boss.attack
			if cm.hand.size() > 0:
				cm.discard.append(cm.hand.pop_back())
		"REGRET":
			# Damage based on attention
			result.damage = boss.attack + cm.player_attention
		"FEAR":
			# High damage, but decreases next turn
			result.damage = boss.attack * 2
			boss.attack = max(5, boss.attack - 2)
		"SHAME":
			# Damage ignores shield
			result.damage = boss.attack
			result.effect = "SHAME_PIERCE"
		"WORTH":
			# Phase 2 only: Tests if you deserve to continue
			if boss.current_phase == 2:
				result.damage = boss.attack * 3
			else:
				result.damage = boss.attack
	
	return result

# === THE UNSENT LETTER ===
# Words cut deeper. Status effects and delayed damage.
# === THE EIDOLON ===
# Mirror phantom. Copies your damage, reflects your tactics.
static func _the_eidolon_turn(boss: BossBehavior, cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	# Track player's last damage dealt for mirroring
	var player_last_damage = cm.player_last_damage if "player_last_damage" in cm else 10
	
	if boss.turn_counter % 4 == 0:
		# Reflection Burst: Deals damage equal to player's last attack ×1.5
		result.damage = int(player_last_damage * 1.5)
		result.effect = "REFLECTION_BURST"
	elif boss.turn_counter % 2 == 0:
		# Mirror Strike: Copies player's last damage exactly
		result.damage = player_last_damage
		result.effect = "MIRROR_STRIKE"
	else:
		# Phantom Grasp: Base attack + scaling
		result.damage = boss.attack + (boss.turn_counter / 2)
		result.effect = "PHANTOM_GRASP"
	
	if boss.current_phase == 2:
		# Phase 2 — Echo: Doubles the mirrored damage
		if result.effect == "REFLECTION_BURST" or result.effect == "MIRROR_STRIKE":
			result.damage = int(result.damage * 2)
			result.effect += "_ECHO"
		# Phase 2 also heals slightly when it mirrors successfully
		result.heal = result.damage / 4
	
	return result

static func _the_unsent_letter_turn(boss: BossBehavior, _cm: CombatManager) -> Dictionary:
	var result = {"damage": 0, "effect": "", "heal": 0, "summon": false, "buff": false}
	
	# Ink bleed: Delayed damage
	if boss.special_cooldown <= 0:
		result.damage = boss.attack
		result.effect = "INK_BLEED"
		boss.special_cooldown = 3
	else:
		result.damage = boss.attack
		result.effect = "LETTER_CUT"
	
	if boss.current_phase == 2:
		# Words left unspoken: Unavoidable damage
		result.damage += 5
		result.effect += "_UNSPOKEN"
	
	return result
