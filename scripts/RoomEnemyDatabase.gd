extends Node
class_name RoomEnemyDatabase
# Note: Not an autoload singleton — instantiate or reference directly when needed

# RoomEnemyDatabase — Thematic enemy compositions for Floor 3
# Each room has unique enemies that "are the things in the room"
# Difficulty scales with room progression (rooms 1-3 easy, 4-7 medium, 8-11 hard)

class EnemyTemplate:
	var name: String
	var sprite_path: String
	var max_hp: int
	var attack: int
	var defense: int
	var action_pattern: Array = []
	var is_boss: bool = false
	var description: String = ""
	var json_data: Dictionary = {}  # Store full JSON for advanced features
	
	func _init(n: String, sprite: String, hp: int, atk: int, def_: int = 0, 
	           pattern: Array = [], boss: bool = false, desc: String = "", json: Dictionary = {}):
		name = n
		sprite_path = sprite
		max_hp = hp
		attack = atk
		defense = def_
		action_pattern = pattern if pattern.size() > 0 else [CombatManager.EnemyAction.ATTACK]
		is_boss = boss
		description = desc
		json_data = json
	
	func to_combat_data() -> CombatManager.EnemyData:
		var ed = CombatManager.EnemyData.new(name, max_hp, attack, defense, action_pattern)
		ed.sprite_texture_path = sprite_path
		return ed

# ============================================================================
# ENEMY TEMPLATES — All available enemies in the game
# ============================================================================

static var ENEMIES: Dictionary

static func _pattern_to_action(pattern_name: String) -> CombatManager.EnemyAction:
	"""Map JSON pattern strings to CombatManager.EnemyAction enums."""
	var p = pattern_name.to_lower().strip_edges()
	match p:
		# Direct mappings
		"melee", "attack", "strike", "bite", "slash", "claw", "punch", "charge", "release", "scream", "consume", "command", "crush", "borrow", "grin", "reach", "replace", "not", "drown", "quiet", "cross", "recall", "pull", "extinction", "lure":
			return CombatManager.EnemyAction.ATTACK
		# Defensive mappings
		"defend", "block", "shield", "flee", "cower", "hide", "hold", "reflect", "watch", "hums", "speak":
			return CombatManager.EnemyAction.DEFEND
		# Default everything else to SPECIAL
		_:
			return CombatManager.EnemyAction.SPECIAL

static func _load_json_enemies():
	"""Load all enemy definitions from JSON files in enemies/ directory."""
	var enemy_dir = "res://enemies/"
	var dir = DirAccess.open(enemy_dir)
	if dir == null:
		push_warning("RoomEnemyDatabase: Could not open enemies directory: %s" % enemy_dir)
		return
	
	var faction_folders = []
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			faction_folders.append(folder_name)
		folder_name = dir.get_next()
	dir.list_dir_end()
	
	var loaded_count = 0
	var skipped_count = 0
	
	for faction in faction_folders:
		var faction_dir_path = enemy_dir + faction + "/"
		var faction_dir = DirAccess.open(faction_dir_path)
		if faction_dir == null:
			continue
		
		faction_dir.list_dir_begin()
		var file_name = faction_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var json_path = faction_dir_path + file_name
				var json_text = FileAccess.get_file_as_string(json_path)
				if json_text.is_empty():
					push_warning("RoomEnemyDatabase: Failed to read %s" % json_path)
					file_name = faction_dir.get_next()
					continue
				
				var json = JSON.new()
				var parse_result = json.parse(json_text)
				if parse_result != OK:
					push_warning("RoomEnemyDatabase: Failed to parse %s: %s" % [json_path, json.get_error_message()])
					file_name = faction_dir.get_next()
					continue
				
				var data = json.get_data()
				if not data is Dictionary:
					file_name = faction_dir.get_next()
					continue
				
				var enemy_name = data.get("name", "")
				if enemy_name.is_empty():
					file_name = faction_dir.get_next()
					continue
				
				# Skip if already loaded from hardcoded (JSON takes precedence, log it)
				if ENEMIES.has(enemy_name):
					# Overwrite with JSON data
					pass
				
				# Extract stats
				var max_hp = data.get("max_hp", data.get("hp", 10))
				var attack = data.get("attack", 3)
				var defense = data.get("defense", 0)
				if defense == 0:
					defense = data.get("def", 0)
				
				# Determine if boss
				var is_boss = false
				var tier = data.get("tier", "")
				if tier == "Boss" or tier == "Mini" or tier == "Secret":
					is_boss = true
				# Also check for known boss naming patterns
				var lower_name = enemy_name.to_lower()
				if lower_name.begins_with("the ") and ("king" in lower_name or "mother" in lower_name or "core" in lower_name or "inheritance" in lower_name or "choice" in lower_name or "protocol" in lower_name or "plane" in lower_name or "eternal" in lower_name or "prime" in lower_name or "caldera" in lower_name or "immutable" in lower_name or "assembly" in lower_name or "dean" in lower_name or "denied" in lower_name or "foreman" in lower_name or "interview" in lower_name or "confession" in lower_name or "embrace" in lower_name or "eidolon" in lower_name or "consumption" in lower_name or "confluence" in lower_name or "replacement" in lower_name or "certainty" in lower_name or "compiler" in lower_name or "first machine" in lower_name or "shadow that walks" in lower_name or "geometric" in lower_name or "devouring past" in lower_name or "elemental core" in lower_name or "final inheritance" in lower_name):
					is_boss = true
				
				# Map action pattern
				var action_pattern: Array = []
				var raw_pattern = data.get("pattern", [])
				if raw_pattern is Array:
					for action_name in raw_pattern:
						if action_name is String:
							action_pattern.append(_pattern_to_action(action_name))
				if action_pattern.is_empty():
					action_pattern = [CombatManager.EnemyAction.ATTACK]
				
				# Get sprite path from animations
				var sprite_path = ""
				var animations = data.get("animations", {})
				if animations is Dictionary:
					var idle_anim = animations.get("idle", {})
					if idle_anim is Dictionary:
						sprite_path = idle_anim.get("sprite", "")
				if sprite_path.is_empty():
					# Fallback: construct path from name
					var safe_name = enemy_name.to_lower().replace(" ", "_").replace("-", "_")
					var faction_lower = faction.to_lower()
					sprite_path = "res://assets/sprites/enemies/%s/enemy_%s_idle.png" % [faction_lower, safe_name]
					# Also try root enemies folder
					if not ResourceLoader.exists(sprite_path):
						sprite_path = "res://assets/sprites/enemies/enemy_%s_idle.png" % safe_name
				
				# Build description from mechanic
				var description = ""
				var mechanic = data.get("mechanic", {})
				if mechanic is Dictionary:
					description = mechanic.get("description", "")
				if description.is_empty():
					description = data.get("description", "")
				if description.is_empty():
					description = "%s from the %s faction." % [enemy_name, faction]
				
				# Create template
				var template = EnemyTemplate.new(
					enemy_name,
					sprite_path,
					max_hp,
					attack,
					defense,
					action_pattern,
					is_boss,
					description
				)
				
				ENEMIES[enemy_name] = template
				loaded_count += 1
			
			file_name = faction_dir.get_next()
		faction_dir.list_dir_end()
	
	print("RoomEnemyDatabase: Loaded %d enemies from JSON files" % loaded_count)
	if skipped_count > 0:
		print("RoomEnemyDatabase: Skipped %d duplicate enemies" % skipped_count)

static func _static_init():
	ENEMIES = {
		# --- CONSTRUCTS (mechanical, gear-based) ---
		"Piston Assembly": EnemyTemplate.new(
			"Piston Assembly",
			"res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png",
			12, 3, 1,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
			false,
			"A basic steam-powered construct. Punches with hydraulic force."
		),
		"Clockwork Hound": EnemyTemplate.new(
			"Clockwork Hound",
			"res://assets/sprites/enemies/Construct/enemy_clockwork_hound_idle.png",
			10, 4, 0,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
			false,
			"Fast mechanical predator. Alternates bite and evasive maneuvers."
		),
		"Diagnostic Eye": EnemyTemplate.new(
			"Diagnostic Eye",
			"res://assets/sprites/enemies/Construct/enemy_diagnostic_eye_idle.png",
			8, 2, 2,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
			false,
			"Floating surveillance unit. Scans weaknesses before striking."
		),
		"Gear Pair": EnemyTemplate.new(
			"Gear Pair",
			"res://assets/sprites/enemies/Construct/enemy_gear_pair_idle.png",
			15, 3, 3,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
			false,
			"Interlocked gears that grind together. High defense, slow but relentless."
		),
		
		# --- FLOOR 4 CONSTRUCTS (undercroft machinery) ---
		"Engine Block": EnemyTemplate.new(
			"Engine Block",
			"res://assets/sprites/enemies/Construct/enemy_engine_block_idle.png",
			18, 4, 4,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
			false,
			"A heavy engine core given legs. Slow, armored, and unstoppable."
		),
		"Drive Train": EnemyTemplate.new(
			"Drive Train",
			"res://assets/sprites/enemies/Construct/enemy_drive_train_idle.png",
			12, 5, 1,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK],
			false,
			"A runaway gear chain. Fast, relentless, no defense but constant motion."
		),
		
		# --- ELEMENTALS ---
		"The Caldera": EnemyTemplate.new(
			"The Caldera",
			"res://assets/sprites/enemies/Elemental/enemy_the_caldera_idle.png",
			25, 6, 2,
			[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
			false,
			"A living volcano of brass and coal. Burns on contact."
		),
	
	# --- FLOOR 5 ENEMIES (airship docks) ---
	"Sneak Thief": EnemyTemplate.new(
		"Sneak Thief",
		"res://assets/sprites/floor5/enemy_sneak_thief_idle.png",
		6, 3, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		false,
		"A nimble sky thief. Dashes between cover, strikes from wind shadows."
	),
	"Debt Eternal": EnemyTemplate.new(
		"Debt Eternal",
		"res://assets/sprites/floor5/enemy_debt_eternal_idle.png",
		10, 3, 2,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Ghost of a debtor who jumped to avoid payment. Still owes the tower."
	),
	"Jetstream Shepherd": EnemyTemplate.new(
		"Jetstream Shepherd",
		"res://assets/sprites/floor5/enemy_jetstream_shepherd_idle.png",
		12, 4, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Wind elemental that herds gales. Grants Wind CHARGE on death."
	),
	"Pressure Knot": EnemyTemplate.new(
		"Pressure Knot",
		"res://assets/sprites/floor5/enemy_pressure_knot_idle.png",
		14, 3, 3,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Steam elemental of compressed fury. Built-up pressure releases in bursts."
	),
	"The Resonance": EnemyTemplate.new(
		"The Resonance",
		"res://assets/sprites/floor5/enemy_resonance_idle.png",
		15, 2, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Aberration of wrong frequency. CHARGE doubles then burns every 2 turns."
	),
	"Elemental Core": EnemyTemplate.new(
		"Elemental Core",
		"res://assets/sprites/floor5/enemy_elemental_core_idle.png",
		60, 8, 4,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK],
		true,
		"Manifestation of pure elemental fusion. Wind->Steam->Lightning phases."
	),
	
	# --- FLOOR 6 ENEMIES (The Lunar University) ---
	"Calibration Drone": EnemyTemplate.new(
		"Calibration Drone",
		"res://assets/sprites/floor6/enemy_calibration_drone_idle.png",
		8, 2, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK],
		false,
		"Campus security drone. Patrols the quadrangle, scans for unenrolled students."
	),
	"Logic Core": EnemyTemplate.new(
		"Logic Core",
		"res://assets/sprites/floor6/enemy_logic_core_idle.png",
		10, 3, 2,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Floating crystalline advisor. Gives misleading directions to test problem-solving."
	),
	"Brass Enforcer": EnemyTemplate.new(
		"Brass Enforcer",
		"res://assets/sprites/floor6/enemy_brass_enforcer_idle.png",
		15, 4, 3,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
		false,
		"Professor of discipline. Leads 2-3 student drones in lecture hall encounters."
	),
	"The Forgotten": EnemyTemplate.new(
		"The Forgotten",
		"res://assets/sprites/floor6/enemy_the_forgotten_idle.png",
		8, 5, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Undead student who 'forgets' player cards. High damage, fragile."
	),
	"The One Who Remembers": EnemyTemplate.new(
		"The One Who Remembers",
		"res://assets/sprites/floor6/enemy_the_one_who_remembers_idle.png",
		12, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
		false,
		"Undead professor. Knows all player moves. Anticipates and counters."
	),
	"Marrow Priest": EnemyTemplate.new(
		"Marrow Priest",
		"res://assets/sprites/floor6/enemy_marrow_priest_idle.png",
		14, 3, 2,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Undead librarian. Protects the stacks. Staff summons ink elementals."
	),
	"The Dean": EnemyTemplate.new(
		"The Dean",
		"res://assets/sprites/floor6/boss_the_dean_idle.png",
		70, 8, 5,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		true,
		"The university's administration made flesh. Tenure grants debuff immunity. Curriculum Change randomizes player hand."
	),
	"The Denied": EnemyTemplate.new(
		"The Denied",
		"res://assets/sprites/floor7/boss_the_denied_idle.png",
		60, 10, 5,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		true,
		"The final judge of broken pacts. Three phases: Hearing, Verdict, Appeal."
	),
	# --- FLOOR 7 ENEMIES (The Broken Pact) ---
	"Soul Clerk": EnemyTemplate.new(
		"Soul Clerk",
		"res://assets/sprites/floor7/enemy_soul_clerk_idle.png",
		8, 2, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK],
		false,
		"Bureaucratic demon that processes soul mortgages. Moves in triplicate."
	),
	"Contract Lawyer": EnemyTemplate.new(
		"Contract Lawyer",
		"res://assets/sprites/floor7/enemy_contract_lawyer_idle.png",
		12, 4, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		false,
		"Demon attorney. Finds loopholes in your deck and exploits them."
	),
	"Blood Notary": EnemyTemplate.new(
		"Blood Notary",
		"res://assets/sprites/floor7/enemy_blood_notary_idle.png",
		14, 5, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Notary who seals contracts in blood. High damage, relentless stamps."
	),
	"Debt Collector": EnemyTemplate.new(
		"Debt Collector",
		"res://assets/sprites/floor7/enemy_debt_collector_idle.png",
		20, 4, 4,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Armored enforcer of soul-debt. Slow but heavy. Chain weapon."
	),
	"Void-Touched Researcher": EnemyTemplate.new(
		"Void-Touched Researcher",
		"res://assets/sprites/floor7/enemy_void_researcher_idle.png",
		10, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Former academic mutated by void experiments. Tentacles see the future."
	),
	"Paper Cut": EnemyTemplate.new(
		"Paper Cut",
		"res://assets/sprites/floor7/enemy_paper_cut_idle.png",
		6, 3, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK],
		false,
		"Living paper cut. Fast, fragile, each strike deals more damage."
	),
	"The Redacted": EnemyTemplate.new(
		"The Redacted",
		"res://assets/sprites/floor7/enemy_the_redacted_idle.png",
		16, 4, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		false,
		"Redacted by the bureaucracy itself. Its data bleeds into reality."
	),
	# --- FLOOR 8 ENEMIES (The Overclock Forge) ---
	"Steam Mote": EnemyTemplate.new(
		"Steam Mote",
		"res://assets/sprites/floor8/enemy_steam_mote_idle.png",
		6, 3, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Fire+Water hybrid. Low HP but builds CHARGE twice as fast. Explodes at 3 CHARGE instead of 5."
	),
	"Glass Wraith": EnemyTemplate.new(
		"Glass Wraith",
		"res://assets/sprites/floor8/enemy_glass_wraith_idle.png",
		10, 4, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
		false,
		"Fire+Earth hybrid. Immune to physical while CHARGED. Shatters when hit at max CHARGE, dealing shard damage to all."
	),
	"Ion Howler": EnemyTemplate.new(
		"Ion Howler",
		"res://assets/sprites/floor8/enemy_ion_howler_idle.png",
		14, 4, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Air specialist. Erratic CHARGE build. At max CHARGE, scrambles player's hand costs for 2 turns."
	),
	"Containment Goblin": EnemyTemplate.new(
		"Containment Goblin",
		"res://assets/sprites/floor8/enemy_containment_goblin_idle.png",
		8, 3, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		false,
		"Carries wrench. Repairs containment vessels (heals elemental 5 HP). If killed while repairing, vessel ruptures instantly."
	),
	"Alarm Ringer": EnemyTemplate.new(
		"Alarm Ringer",
		"res://assets/sprites/floor8/enemy_alarm_ringer_idle.png",
		5, 2, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Weak. If not killed in 2 turns, pulls alarm — summons 2 more goblins + releases nearest vessel."
	),
	"Overclock Shaman": EnemyTemplate.new(
		"Overclock Shaman",
		"res://assets/sprites/floor8/enemy_overclock_shaman_idle.png",
		12, 4, 2,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Buffs elementals' CHARGE build. Can supercharge one elemental (+3 CHARGE instantly, but it becomes unstable — 50% chance to attack nearest goblin instead of player)."
	),
	"Chief Engineer Blix": EnemyTemplate.new(
		"Chief Engineer Blix",
		"res://assets/sprites/floor8/boss_chief_engineer_blix_idle.png",
		55, 6, 4,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		true,
		"Goblin who has survived every explosion. Three phases: The Shift, The Meltdown, The Scram."
	),
	# Floor 9 (The Bone Forges) enemies
	"Assembly Skeleton": EnemyTemplate.new(
		"Assembly Skeleton",
		"res://assets/sprites/floor9/enemy_assembly_skeleton_idle.png",
		8, 3, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Weak undead worker. Respawns once after 2 turns unless hit with fire."
	),
	"Foreman Specter": EnemyTemplate.new(
		"Foreman Specter",
		"res://assets/sprites/floor9/enemy_foreman_specter_idle.png",
		12, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Ghostly foreman. Buffs all construct allies. Can possess a construct, gaining its body + stats."
	),
	"Soul Burner": EnemyTemplate.new(
		"Soul Burner",
		"res://assets/sprites/floor9/enemy_soul_burner_idle.png",
		10, 4, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Explodes on death dealing damage based on souls absorbed. Can be drained pre-emptively."
	),
	"The Pensioned": EnemyTemplate.new(
		"The Pensioned",
		"res://assets/sprites/floor9/enemy_the_pensioned_idle.png",
		18, 3, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK],
		false,
		"Ancient undead worker. Cannot die — reaches 0 HP, falls apart, reassembles in 3 turns at full HP unless all parts destroyed."
	),
	"Ribcage Loader": EnemyTemplate.new(
		"Ribcage Loader",
		"res://assets/sprites/floor9/enemy_ribcage_loader_idle.png",
		10, 3, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Carries bone crates. Drops healing bones on death."
	),
	"Skull-Faced Machinist": EnemyTemplate.new(
		"Skull-Faced Machinist",
		"res://assets/sprites/floor9/enemy_skull_machinist_idle.png",
		12, 3, 2,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Repairs allies. Must be killed first or combat drags."
	),
	"Femur Golem": EnemyTemplate.new(
		"Femur Golem",
		"res://assets/sprites/floor9/enemy_femur_golem_idle.png",
		20, 5, 3,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Heavy hitter. Each attack costs it a limb — gets weaker but faster as fight continues."
	),
	"Soul-Piston": EnemyTemplate.new(
		"Soul-Piston",
		"res://assets/sprites/floor9/enemy_soul_piston_idle.png",
		15, 4, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Powered by trapped soul. If player frees soul mid-combat (spending 2 gems), construct deactivates instantly."
	),
	"The Foreman Eternal": EnemyTemplate.new(
		"The Foreman Eternal",
		"res://assets/sprites/floor9/boss_foreman_eternal_idle.png",
		65, 8, 5,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		true,
		"A construct-lich who has replaced every organ, every limb, every thought-process with machinery — except its original skull, which it keeps in a glass case on its chest. Three phases: The Shift, Quality Control, Efficiency Measures."
	),
	"Snotling": EnemyTemplate.new(
		"Snotling",
		"res://assets/sprites/enemies/Goblin/enemy_snotling_idle.png",
		2, 2, 0,
		[CombatManager.EnemyAction.ATTACK],
		false,
		"A tiny, furious goblin minion. Weak alone, annoying in groups."
	),
	"Torch Boy": EnemyTemplate.new(
		"Torch Boy",
		"res://assets/sprites/enemies/Goblin/enemy_torch_boy_idle.png",
		6, 4, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Goblin with a blazing torch. Special: throws torch for fire damage."
	),
	"Droplet": EnemyTemplate.new(
		"Droplet",
		"res://assets/sprites/enemies/Elemental/enemy_droplet_idle.png",
		4, 0, 0,
		[],
		false,
		"A wobbling water elemental. Non-hostile — produces offerings."
	),
	"The Door": EnemyTemplate.new(
		"The Door",
		"res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png",
		8, 4, 4,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK],
		false,
		"The tower's entrance fights back. Teaches block-then-attack rhythm."
	),
	"Snotling King": EnemyTemplate.new(
		"Snotling King",
		"res://assets/sprites/enemies/Goblin/boss_the_snotling_king_idle.png",
		15, 5, 2,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		true,
		"Goblin mini-boss. Summons snotlings, commands them to attack."
	),
	"Shortcut Maker": EnemyTemplate.new(
		"Shortcut Maker",
		"res://assets/sprites/enemies/Demon/enemy_obsession_demon_idle.png",
		6, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Demon in a shabby suit. Offers deals with hidden costs."
	),
	"The Bug": EnemyTemplate.new(
		"The Bug",
		"res://assets/sprites/enemies/enemy_the_bug_idle.png",
		9, 3, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"A glitch in the system. Unpredictable attack patterns."
	),
	"The Lag": EnemyTemplate.new(
		"The Lag",
		"res://assets/sprites/enemies/enemy_the_lag_idle.png",
		14, 4, 1,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Moves slowly then strikes in bursts. Defensive between attacks."
	),
	"The Echo": EnemyTemplate.new(
		"The Echo",
		"res://assets/sprites/enemies/enemy_the_echo_idle.png",
		11, 3, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Repeats your last card's effect back at you."
	),
	"The Loop": EnemyTemplate.new(
		"The Loop",
		"res://assets/sprites/enemies/enemy_the_loop_idle.png",
		16, 3, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Cyclical fighter. Repeats attack-defend patterns endlessly."
	),
	"The Cursor": EnemyTemplate.new(
		"The Cursor",
		"res://assets/sprites/enemies/enemy_the_cursor_idle.png",
		10, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Repositions constantly. Special moves it to a defensive stance."
	),
	"The Default": EnemyTemplate.new(
		"The Default",
		"res://assets/sprites/enemies/enemy_the_default_idle.png",
		13, 3, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.DEFEND],
		false,
		"The factory setting. Balanced, unremarkable, surprisingly durable."
	),
	"The Collar": EnemyTemplate.new(
		"The Collar",
		"res://assets/sprites/enemies/enemy_the_collar_idle.png",
		12, 4, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"A tightening constraint. Damage increases as fight progresses."
	),
	"The Contagion": EnemyTemplate.new(
		"The Contagion",
		"res://assets/sprites/enemies/enemy_the_contagion_idle.png",
		10, 2, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Spreads damage to all enemies when it strikes. Weak alone, dangerous in groups."
	),
	"The Hollow": EnemyTemplate.new(
		"The Hollow",
		"res://assets/sprites/enemies/enemy_the_hollow_idle.png",
		18, 2, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Empty shell with high HP but low damage. Takes hits so allies can strike."
	),
	"The Whisper": EnemyTemplate.new(
		"The Whisper",
		"res://assets/sprites/enemies/enemy_the_whisper_idle.png",
		9, 2, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"Broadcasts distractions. Special reduces player attention efficiency."
	),
	"The Mirror": EnemyTemplate.new(
		"The Mirror",
		"res://assets/sprites/enemies/enemy_the_mirror_idle.png",
		12, 3, 3,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Reflects damage back when defending. Symmetrical and patient."
	),
	"The Duplicate": EnemyTemplate.new(
		"The Duplicate",
		"res://assets/sprites/enemies/enemy_the_duplicate_idle.png",
		10, 3, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Copies the highest-HP enemy's stats. Adapts to threats."
	),
	"The Refrain": EnemyTemplate.new(
		"The Refrain",
		"res://assets/sprites/enemies/enemy_the_refrain_idle.png",
		11, 3, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Repeats the same attack pattern. Predictable but relentless."
	),
	
	# --- FLOOR 4 ABERRATIONS (mirror / glitch bazaar) ---
	"Mirror Self": EnemyTemplate.new(
		"Mirror Self",
		"res://assets/sprites/enemies/enemy_mirror_self_idle.png",
		14, 4, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
		false,
		"Your reflection steps out of the glass. It knows every card you play."
	),
	"The Afterimage": EnemyTemplate.new(
		"The Afterimage",
		"res://assets/sprites/enemies/enemy_afterimage_idle.png",
		10, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"A delayed echo of violence. Its attacks resolve one turn after you see them."
	),
	
	# --- UNDEAD (fungal decay) ---
	"Flesh Debt": EnemyTemplate.new(
		"Flesh Debt",
		"res://assets/sprites/enemies/Undead/enemy_flesh_debt_idle.png",
		8, 3, 1,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.SPECIAL],
		false,
		"A fungal zombie still paying off its death. GRASP steals cards."
	),
	"Flesh Crawler": EnemyTemplate.new(
		"Flesh Crawler",
		"res://assets/sprites/enemies/Undead/enemy_flesh_crawler_idle.png",
		6, 2, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK],
		false,
		"Swarm of crawling fungal limbs. Fast but fragile."
	),
	"Forgetful Wound": EnemyTemplate.new(
		"Forgetful Wound",
		"res://assets/sprites/enemies/Undead/enemy_forgetful_wound_idle.png",
		10, 4, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK],
		false,
		"A wound that won't close. Reopens if not finished quickly."
	),
	
	# --- ELEMENTAL (water/steam in cavern) ---
	"Cinder Mote": EnemyTemplate.new(
		"Cinder Mote",
		"res://assets/sprites/enemies/Elemental/enemy_cinder_mote_idle.png",
		5, 4, 0,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		false,
		"Tiny fire elemental. Burns bright, dies fast."
	),
	"Hydrostatic Eye": EnemyTemplate.new(
		"Hydrostatic Eye",
		"res://assets/sprites/enemies/Elemental/enemy_hydrostatic_eye_idle.png",
		7, 3, 1,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Floating water lens. Ranged attacks from the pool's surface."
	),
	
	# --- CONSTRUCT (overgrown excavation) ---
	"Brass Knuckle": EnemyTemplate.new(
		"Brass Knuckle",
		"res://assets/sprites/enemies/Construct/enemy_brass_knuckle_idle.png",
		14, 5, 2,
		[CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.DEFEND],
		false,
		"Heavy mining construct. Slow but devastating punches."
	),
	
	# --- BOSSES (Floor 2) ---
	"The Flesh Garden": EnemyTemplate.new(
		"The Flesh Garden",
		"res://assets/sprites/enemies/Undead/boss_the_flesh_garden_idle.png",
		40, 6, 3,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		true,
		"Amalgamation of fungal decay and consumed corpses. The garden grows on death."
	),
	"The Interview": EnemyTemplate.new(
		"The Interview",
		"res://assets/sprites/enemies/enemy_the_interview_idle.png",
		70, 15, 5,
		[CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL],
		true,
		"It does not ask questions. It asks YOU."
	),
	"The Eidolon": EnemyTemplate.new(
		"The Eidolon",
		"res://assets/sprites/enemies/enemy_the_eidolon_idle.png",
		65, 12, 8,
		[CombatManager.EnemyAction.DEFEND, CombatManager.EnemyAction.ATTACK, CombatManager.EnemyAction.SPECIAL, CombatManager.EnemyAction.DEFEND],
		true,
		"Your reflection, given teeth."
	),
	}
	
	# Load all enemies from JSON files (supplements/overrides hardcoded entries)
	_load_json_enemies()
	
	print("RoomEnemyDatabase: Total enemies registered: %d" % ENEMIES.size())

# ============================================================================
# ROOM ENEMY COMPOSITIONS
# Each room has a thematic set of enemies that "are the things in the room"
# ============================================================================

const ROOM_COMPOSITIONS = {
	# Room 1 — The Quench (water/cooling)
	1: {
		"name": "Steam Constructs",
		"enemies": ["Piston Assembly", "Piston Assembly"],
		"ambush": ["Piston Assembly", "The Bug", "Piston Assembly"],
		"trap": ["Piston Assembly", "The Lag"],
		"flavor": "Cooling system defenders emerge from the condensation."
	},
	
	# Room 2 — The Spark (fire/heat)
	2: {
		"name": "Furnace Guardians",
		"enemies": ["The Caldera", "Diagnostic Eye"],
		"ambush": ["The Caldera", "Diagnostic Eye", "Gear Pair"],
		"trap": ["The Caldera", "The Collar"],
		"flavor": "The furnace's heat has given life to its guardians."
	},
	
	# Room 3 — The Governor (regulation/control)
	3: {
		"name": "System Regulators",
		"enemies": ["Diagnostic Eye", "Gear Pair"],
		"ambush": ["Diagnostic Eye", "The Default", "Gear Pair"],
		"trap": ["Diagnostic Eye", "The Cursor"],
		"flavor": "Regulatory systems detect unauthorized activity."
	},
	
	# Room 4 — The Draft (airflow/steam)
	4: {
		"name": "Pressure Demons",
		"enemies": ["Piston Assembly", "Clockwork Hound"],
		"ambush": ["Piston Assembly", "The Echo", "Clockwork Hound"],
		"trap": ["Piston Assembly", "The Echo", "The Echo"],
		"flavor": "Steam pressure vents its fury through manifested constructs."
	},
	
	# Room 5 — The Temper (heat treatment)
	5: {
		"name": "Tempered Guardians",
		"enemies": ["Gear Pair", "The Caldera"],
		"ambush": ["Gear Pair", "The Caldera", "Diagnostic Eye"],
		"trap": ["The Caldera", "The Collar", "Gear Pair"],
		"flavor": "The forge's heat has tempered these defenders into steel."
	},
	
	# Room 6 — The Beacon (height/light)
	6: {
		"name": "Light Sentinels",
		"enemies": ["Diagnostic Eye", "Diagnostic Eye"],
		"ambush": ["Diagnostic Eye", "The Whisper", "Diagnostic Eye"],
		"trap": ["Diagnostic Eye", "The Whisper"],
		"flavor": "The beacon's light reveals intruders to its watchful eyes."
	},
	
	# Room 7 — The Escapement (time/rhythm)
	7: {
		"name": "Temporal Constructs",
		"enemies": ["Clockwork Hound", "The Loop"],
		"ambush": ["Clockwork Hound", "The Loop", "The Lag"],
		"trap": ["The Loop", "The Lag", "Clockwork Hound"],
		"flavor": "Time itself manifests to defend the escapement."
	},
	
	# Room 8 — The Bearing (friction/oil)
	8: {
		"name": "Friction Demons",
		"enemies": ["Gear Pair", "Piston Assembly"],
		"ambush": ["Gear Pair", "The Hollow", "Piston Assembly"],
		"trap": ["Gear Pair", "The Hollow", "The Forgotten"],
		"flavor": "Seized bearings scream as friction-spawned demons emerge."
	},
	
	# Room 9 — The Flywheel (momentum)
	9: {
		"name": "Momentum Thralls",
		"enemies": ["Gear Pair", "Clockwork Hound"],
		"ambush": ["Gear Pair", "The Contagion", "Clockwork Hound"],
		"trap": ["Gear Pair", "The Contagion", "The Contagion"],
		"flavor": "The flywheel's stored momentum births spinning attackers."
	},
	
	# Room 10 — The Counterweight (balance)
	10: {
		"name": "Balanced Twins",
		"enemies": ["The Mirror", "The Duplicate"],
		"ambush": ["The Mirror", "The Duplicate", "The Default"],
		"trap": ["The Mirror", "The Duplicate", "The Mirror"],
		"flavor": "The scale's balance manifests as paired, symmetrical foes."
	},
	
	# Room 11 — The Oiler (maintenance)
	11: {
		"name": "Neglected Servitors",
		"enemies": ["Piston Assembly", "The Forgotten"],
		"ambush": ["Piston Assembly", "The Forgotten", "Clockwork Hound"],
		"trap": ["The Forgotten", "The Forgotten", "The Hollow"],
		"flavor": "Neglected maintenance equipment rises in angry rebellion."
	},
}

# ============================================================================
# TRAP-SPECIFIC ENEMY COMPOSITIONS
# ============================================================================

const TRAP_COMPOSITIONS = {
	"GraspingCogTrap": {
		"name": "Cog Spawn",
		"enemies": ["Gear Pair", "Piston Assembly"],
		"flavor": "The grasping cog births lesser gear-constructs."
	},
	"CompressionTrap": {
		"name": "Pressure Manifest",
		"enemies": ["The Collar", "Piston Assembly"],
		"flavor": "Compressed steam condenses into violent forms."
	},
	"RecalibrationTrap": {
		"name": "Calibration Drones",
		"enemies": ["Diagnostic Eye", "The Default", "The Cursor"],
		"flavor": "Recalibration systems manifest defensive drones."
	},
	"WarningSermonTrap": {
		"name": "Broadcast Thralls",
		"enemies": ["The Whisper", "The Echo", "The Refrain"],
		"flavor": "The Gear Devil's broadcast materializes signal-creatures."
	},
}

# ============================================================================
# BOSS COMPOSITIONS (for Crown Cog)
# ============================================================================

const BOSS_COMPOSITIONS = {
	"TheCaldera": {
		"name": "The Caldera",
		"enemies": ["The Caldera"],
		"is_boss": true,
		"flavor": "The living furnace core. All heat in the Tower flows through it."
	},
	"GearMother": {
		"name": "Gear Mother",
		"enemies": ["GearMother"],  # Uses boss sprite set
		"is_boss": true,
		"flavor": "The progenitor of all gears. She remembers every tooth that broke."
	},
	"TheInterview": {
		"name": "The Interview",
		"enemies": ["The Interview"],
		"is_boss": true,
		"flavor": "It does not ask questions. It asks YOU."
	},
	"TheEidolon": {
		"name": "The Eidolon",
		"enemies": ["The Eidolon"],
		"is_boss": true,
		"flavor": "Your reflection, given teeth."
	},
}

# ============================================================================
# FLOOR 1 ROOM COMPOSITIONS
# ============================================================================

const FLOOR1_COMPOSITIONS = {
	"north": {
		"name": "The Door",
		"enemies": ["The Door"],
		"flavor": "The tower's entrance fights back. Learn to block, then strike.",
		"is_tutorial": true,
	},
	"east": {
		"name": "The Warren",
		"enemies": ["Goblin Grunt"],
		"ambush": ["Goblin Grunt", "Snotling"],
		"flavor": "Goblin territory. Debris provides cover.",
	},
	"south": {
		"name": "The Shrine",
		"enemies": [],
		"flavor": "A peaceful shrine. Droplet offers gifts, not combat.",
		"is_peaceful": true,
	},
	"west": {
		"name": "The Gauntlet",
		"enemies": ["Torch Boy"],
		"flavor": "A torch-wielding goblin guards the path through traps.",
	},
	"boss": {
		"name": "Snotling King",
		"enemies": ["Snotling King"],
		"flavor": "The goblin king and his swarm. Floor 1's final test.",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 2 ROOM COMPOSITIONS — The Fungal Cavern
# ============================================================================

const FLOOR2_COMPOSITIONS = {
	"upper": {
		"name": "The Rot Garden",
		"enemies": ["Flesh Debt"],
		"ambush": ["Flesh Debt", "Flesh Crawler"],
		"flavor": "Undead fungal feeders emerge from the rot. GRASP teaches card theft.",
		"faction": "Undead",
	},
	"middle": {
		"name": "The Grotto",
		"enemies": ["Droplet"],
		"ambush": ["Droplet", "Cinder Mote"],
		"flavor": "Elementals dance on the bioluminescent pool. CHARGE builds over turns.",
		"faction": "Elemental",
	},
	"lower": {
		"name": "The Overgrown Excavation",
		"enemies": ["Clockwork Hound"],
		"ambush": ["Brass Knuckle"],
		"flavor": "Ancient mining constructs overgrown with fungus. Heavy and relentless.",
		"faction": "Construct",
	},
	"secret": {
		"name": "The Mycelial Glitch",
		"enemies": ["The Bug"],
		"flavor": "A glitch in the fungal network. Error cards clog your hand.",
		"faction": "Aberration",
		"is_secret": true,
	},
	"spore_heart": {
		"name": "The Flesh Garden",
		"enemies": ["The Flesh Garden"],
		"flavor": "The garden that grows on graves. The beauty that feeds on death.",
		"faction": "Undead",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 6 ROOM COMPOSITIONS — The Lunar University
# ============================================================================

const FLOOR6_COMPOSITIONS = {
	"quadrangle": {
		"name": "The Quadrangle",
		"enemies": ["Calibration Drone"],
		"ambush": ["Calibration Drone", "Logic Core"],
		"flavor": "Moonlit courtyard. The Registrar waits. Campus security patrols.",
		"faction": "Construct",
	},
	"gears": {
		"name": "College of Gears",
		"enemies": ["Brass Enforcer", "Calibration Drone"],
		"ambush": ["Brass Enforcer", "Calibration Drone", "Calibration Drone"],
		"flavor": "Mechanical workshops. The gear garden turns. Professors enforce discipline.",
		"faction": "Construct",
	},
	"echoes": {
		"name": "College of Echoes",
		"enemies": ["The Forgotten"],
		"ambush": ["The Forgotten", "Marrow Priest"],
		"flavor": "The library whispers. Toxic ink pools. Eternal students study.",
		"faction": "Undead",
	},
	"aether": {
		"name": "College of Aether",
		"enemies": [],
		"flavor": "Closed for renovation. Steam leaks from boarded doors. Foreshadowing.",
		"faction": "Elemental",
		"is_peaceful": true,
	},
	"pacts": {
		"name": "College of Pacts",
		"enemies": [],
		"flavor": "Locked. Demonology department. Summoning circles glow behind windows.",
		"faction": "Demon",
		"is_peaceful": true,
	},
	"undercroft": {
		"name": "The Undercroft",
		"enemies": [],
		"flavor": "Steam tunnels. The goblin janitor 'borrows' things. Master Key hidden here.",
		"faction": "Goblin",
		"is_peaceful": true,
	},
	"clocktower": {
		"name": "The Clocktower Apex",
		"enemies": ["The Dean"],
		"flavor": "The Dean awaits. Glass dome. Moonlight. The final exam.",
		"faction": "Construct",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 5 ROOM COMPOSITIONS — The Airship Docks
# ============================================================================

const FLOOR5_COMPOSITIONS = {
	"mooring": {
		"name": "The Mooring",
		"enemies": ["Goblin Grunt", "Goblin Grunt"],
		"ambush": ["Goblin Grunt", "Sneak Thief", "Goblin Grunt"],
		"flavor": "Stowaways and sky rats scavenge the landing platform.",
		"faction": "Goblin",
	},
	"breeze": {
		"name": "The Breeze",
		"enemies": ["Jetstream Shepherd"],
		"ambush": ["Jetstream Shepherd", "Jetstream Shepherd"],
		"flavor": "Wind shepherds tend the open deck. The gales answer their call.",
		"faction": "Elemental",
	},
	"boiler": {
		"name": "The Boiler",
		"enemies": ["Pressure Knot"],
		"ambush": ["Pressure Knot", "Debt Eternal"],
		"flavor": "Steam pressure births elementals. A debtor's ghost lingers in the pipes.",
		"faction": "Elemental",
	},
	"gale": {
		"name": "The Gale",
		"enemies": ["Jetstream Shepherd", "Debt Eternal"],
		"ambush": ["Jetstream Shepherd", "Jetstream Shepherd", "Pressure Knot"],
		"flavor": "The storm draws elementals and dead alike. Both ride the wind.",
		"faction": "Elemental",
	},
	"cargo": {
		"name": "The Cargo Hold",
		"enemies": ["The Resonance"],
		"flavor": "Wrong frequency made sentient. CHARGE hoarding is fatal here.",
		"faction": "Aberration",
		"is_secret": true,
	},
	"crow": {
		"name": "The Crow's Nest",
		"enemies": ["Jetstream Shepherd", "Debt Eternal"],
		"ambush": ["Pressure Knot", "Jetstream Shepherd"],
		"flavor": "Highest point, thinnest air. Lightning rods hum with hungry charge.",
		"faction": "Elemental",
	},
	"aether": {
		"name": "The Aetherworks",
		"enemies": ["Elemental Core"],
		"flavor": "The Elemental Core fuses wind, steam, and lightning into one will.",
		"faction": "Elemental",
		"is_boss": true,
	},
}



const FLOOR4_COMPOSITIONS = {
	# Real vendors (peaceful — no combat)
	"booth_12": {
		"name": "The Gearwright",
		"enemies": [],
		"flavor": "A brass automata merchant. Sells Construct cards and gear parts.",
		"is_peaceful": true,
	},
	"booth_4": {
		"name": "The Steam-Press",
		"enemies": [],
		"flavor": "A goblin in brass goggles. Sells consumables and steam tonics.",
		"is_peaceful": true,
	},
	"booth_8": {
		"name": "The Curio Collector",
		"enemies": [],
		"flavor": "A hooded figure selling rare items and memory cards.",
		"is_peaceful": true,
	},
	
	# Trap booths (Aberration enemies — HP 6-12 tier)
	"booth_1": {
		"name": "The Infinity Mirror",
		"enemies": ["Mirror Self"],
		"flavor": "Your reflection steps out of the glass. It knows every card you play.",
		"trap_type": "infinity_mirror",
	},
	"booth_2": {
		"name": "The Bargain Bin",
		"enemies": ["The Bug", "The Cursor"],
		"flavor": "The displays bite. Error cards breed in the glass cases.",
		"trap_type": "bargain_bin",
	},
	"booth_3": {
		"name": "The Timepiece Exchange",
		"enemies": ["The Lag", "The Afterimage", "The Afterimage"],
		"flavor": "Clocks run backward. Your actions resolve one turn late.",
		"trap_type": "timepiece_exchange",
	},
	"booth_5": {
		"name": "The Memory Monger",
		"enemies": ["The Forgotten", "The Forgotten"],
		"flavor": "Sells your own memories back to you. Each one costs a card.",
		"trap_type": "memory_monger",
	},
	"booth_6": {
		"name": "The Duplicate Drapers",
		"enemies": ["Mirror Self", "Mirror Self"],
		"flavor": "Copies of you wander the booth. Which one is real?",
		"trap_type": "duplicate_drapers",
	},
	"booth_7": {
		"name": "The Glitch Glassworks",
		"enemies": ["The Bug", "The Bug"],
		"flavor": "Items shatter into Error cards when touched.",
		"trap_type": "glitch_glassworks",
	},
	"booth_9": {
		"name": "The Rollback Refinery",
		"enemies": ["The Lag", "The Bug"],
		"flavor": "Every purchase reverts. You keep paying.",
		"trap_type": "rollback_refinery",
	},
	"booth_10": {
		"name": "The Sample Crier",
		"enemies": ["The Cursor", "The Forgotten"],
		"flavor": "The holographic barker shows your reflection. Then it shows your death.",
		"trap_type": "sample_crier",
	},
	"booth_11": {
		"name": "The Reflection Salon",
		"enemies": ["Mirror Self"],
		"flavor": "Full-length brass mirror. Your reflection steps out with your exact HP.",
		"trap_type": "reflection_salon",
	},
}

# ============================================================================
# FLOOR 7 ROOM COMPOSITIONS — The Broken Pact
# ============================================================================

const FLOOR7_COMPOSITIONS = {
	"office": {
		"name": "The Bureaucratic Office",
		"enemies": ["Soul Clerk"],
		"flavor": "Demon bureaucracy. Brass desks, filing cabinets, and blood-ink contracts.",
		"faction": "Demon",
	},
	"court": {
		"name": "The Trial Chamber",
		"enemies": ["Contract Lawyer"],
		"ambush": ["Contract Lawyer", "Soul Clerk"],
		"flavor": "First combat. Contract Lawyer cross-examines your cards.",
		"faction": "Demon",
	},
	"break_room": {
		"name": "The Break Room",
		"enemies": [],
		"flavor": "Safe mixed room. Coffee machine, scattered chairs. Goblin Forger lurks.",
		"is_peaceful": true,
	},
	"filing": {
		"name": "The Endless Filing",
		"enemies": ["Debt Collector"],
		"flavor": "Debt Collector mini-boss. Endless filing cabinets. Narrow aisles.",
		"faction": "Demon",
	},
	"corridor": {
		"name": "The Corridor",
		"enemies": [],
		"flavor": "First void cracks. Unstable reality patches. No enemies, but danger.",
		"is_peaceful": true,
	},
	"laboratory": {
		"name": "The Void Laboratory",
		"enemies": ["Void-Touched Researcher"],
		"flavor": "Mutation tutorial. Void-Touched Researcher demonstrates void bonds.",
		"faction": "Aberration",
	},
	"storage": {
		"name": "The Contract Storage",
		"enemies": ["Paper Cut"],
		"ambush": ["Paper Cut", "Paper Cut"],
		"flavor": "Treasure chests, pact scrolls on shelves. Paper Cut guards the archive.",
		"faction": "Demon",
	},
	"court_ii": {
		"name": "The Second Court",
		"enemies": ["Blood Notary"],
		"ambush": ["Blood Notary", "Contract Lawyer"],
		"flavor": "Harder combat. Docket display board. Blood Notary demands seals.",
		"faction": "Demon",
	},
	"void_lab": {
		"name": "The Reality Lab",
		"enemies": ["The Redacted"],
		"ambush": ["The Redacted", "Void-Touched Researcher"],
		"flavor": "Reality unstable. Geometric distortions. The Redacted patrols.",
		"faction": "Aberration",
	},
	"antechamber": {
		"name": "The Antechamber",
		"enemies": [],
		"flavor": "Final preparation room. Last contract station. Heavy doors to boss.",
		"is_peaceful": true,
	},
	"auditorium": {
		"name": "The Auditorium",
		"enemies": ["The Denied"],
		"flavor": "Boss arena. Debating hall, circular seating, central contract altar.",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 8 ROOM COMPOSITIONS — The Overclock Forge
# ============================================================================

const FLOOR8_COMPOSITIONS = {
	"loading_bay": {
		"name": "The Loading Bay",
		"enemies": ["Containment Goblin"],
		"ambush": ["Containment Goblin", "Alarm Ringer"],
		"flavor": "Where raw elementals are delivered. Goblin handlers drag them in chains.",
		"faction": "Goblin",
	},
	"lower_works": {
		"name": "The Lower Works",
		"enemies": ["Steam Mote"],
		"ambush": ["Steam Mote", "Steam Mote"],
		"flavor": "Fire and water forced into coexistence. Results: steam, explosions, and occasional tea.",
		"faction": "Elemental",
	},
	"break_room": {
		"name": "The Break Room",
		"enemies": [],
		"flavor": "Safe room. Containment station. Overclock tutorial posters on the walls.",
		"is_peaceful": true,
	},
	"containment_hall": {
		"name": "The Containment Hall",
		"enemies": ["Containment Goblin", "Steam Mote"],
		"ambush": ["Containment Goblin", "Containment Goblin", "Steam Mote"],
		"flavor": "Three massive vessels. Two goblin handlers. First hard fight of the floor.",
		"faction": "Mixed",
	},
	"the_leak": {
		"name": "The Leak",
		"enemies": ["Steam Mote", "Steam Mote"],
		"ambush": ["Steam Mote", "Steam Mote", "Pressure Knot"],
		"flavor": "Vent-only room. Ruptured pipes. Elemental swarm. No goblins — just escaping energy.",
		"faction": "Elemental",
	},
	"middle_works": {
		"name": "The Middle Works",
		"enemies": ["Glass Wraith", "Alarm Ringer"],
		"ambush": ["Glass Wraith", "Glass Wraith", "Alarm Ringer"],
		"flavor": "Earth and air crushed together. Glass tornadoes, flying shrapnel, shattered containment rings.",
		"faction": "Mixed",
	},
	"union_hall": {
		"name": "The Union Hall",
		"enemies": ["Containment Goblin", "Containment Goblin"],
		"ambush": ["Containment Goblin", "Containment Goblin", "Containment Goblin"],
		"flavor": "Goblin union banners, strike signs. Chief Handler leads the pack. Morale test.",
		"faction": "Goblin",
	},
	"the_crack": {
		"name": "The Crack",
		"enemies": ["Pressure Knot"],
		"ambush": ["Pressure Knot", "Steam Mote"],
		"flavor": "Pressure Knot elite guards a single massive vessel. Vent, overclock, or patch decision point.",
		"faction": "Elemental",
	},
	"upper_works": {
		"name": "The Upper Works",
		"enemies": ["Overclock Shaman", "Steam Mote"],
		"ambush": ["Overclock Shaman", "Steam Mote", "Ion Howler"],
		"flavor": "Overclock Shaman + 2 vessels. Complex fight in the reactor machinery maze.",
		"faction": "Mixed",
	},
	"padlock_door": {
		"name": "The Padlock Door",
		"enemies": [],
		"flavor": "Seventeen padlocks on a heavy door. Final preparation cache. Overclocked loot behind.",
		"is_peaceful": true,
	},
	"control_room": {
		"name": "The Control Room",
		"enemies": ["Chief Engineer Blix"],
		"flavor": "Boss arena. Four containment consoles, blast shield, Chief Engineer Blix at the reactor.",
		"faction": "Goblin",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 9 ROOM COMPOSITIONS — The Bone Forges
# ============================================================================

const FLOOR9_COMPOSITIONS = {
	"loading_dock": {
		"name": "The Loading Dock",
		"enemies": ["Assembly Skeleton"],
		"ambush": ["Assembly Skeleton", "Ribcage Loader"],
		"flavor": "Where raw materials (skeletons, fresh corpses) arrive. Smells of lye and iron. First salvage tutorial.",
		"faction": "Undead",
	},
	"assembly_line": {
		"name": "The Assembly Line",
		"enemies": ["Assembly Skeleton", "Ribcage Loader"],
		"ambush": ["Assembly Skeleton", "Skull-Faced Machinist", "Ribcage Loader"],
		"flavor": "Conveyor belts, mixed combat. Arms of brass, hands of bone. Eyes that glow with trapped souls.",
		"faction": "Mixed",
	},
	"break_station": {
		"name": "The Break Station",
		"enemies": [],
		"flavor": "Safe room. Assembly station, soul furnace choice. Bone piles and gear stacks.",
		"is_peaceful": true,
	},
	"furnace_room": {
		"name": "The Furnace Room",
		"enemies": ["Soul Burner", "Assembly Skeleton"],
		"ambush": ["Soul Burner", "Foreman Specter", "Assembly Skeleton"],
		"flavor": "Three soul-forges glowing green. Smokestacks of femurs. Trapped souls. Destroy or use?",
		"faction": "Mixed",
	},
	"quality_control": {
		"name": "Quality Control",
		"enemies": ["Skull-Faced Machinist"],
		"ambush": ["Skull-Faced Machinist", "Assembly Skeleton"],
		"flavor": "Testing chamber where finished products are activated. Skull Machinist mini-boss. Combat arena.",
		"faction": "Construct",
	},
	"bone_yard": {
		"name": "The Bone Yard",
		"enemies": ["Assembly Skeleton", "Assembly Skeleton"],
		"ambush": ["Assembly Skeleton", "Assembly Skeleton", "The Pensioned"],
		"flavor": "Endless skeleton piles. Respawning undead. Bone dust clouds. Skeleton swarm.",
		"faction": "Undead",
	},
	"gear_works": {
		"name": "The Gear Works",
		"enemies": ["Skull-Faced Machinist", "Ribcage Loader"],
		"ambush": ["Femur Golem", "Skull-Faced Machinist"],
		"flavor": "Construct-only room. Skull-faced machinists and repair stations. Femur Golem elite.",
		"faction": "Construct",
	},
	"conveyor_maze": {
		"name": "The Conveyor Maze",
		"enemies": ["Ribcage Loader", "Soul-Piston"],
		"ambush": ["Ribcage Loader", "Soul-Piston", "Assembly Skeleton"],
		"flavor": "Moving platforms, timing puzzle. Shifting layout. Ride or fight against the flow.",
		"faction": "Mixed",
	},
	"foundry_pit": {
		"name": "The Foundry Pit",
		"enemies": ["Soul-Piston", "Soul Burner"],
		"ambush": ["Soul-Piston", "Soul Burner", "Femur Golem"],
		"flavor": "Soul-piston elite. Lava-like soul-energy. Furnace choice: free or burn?",
		"faction": "Mixed",
	},
	"locker_room": {
		"name": "The Locker Room",
		"enemies": [],
		"flavor": "Final assembly, preparation. Companion card crafting. Safe room before the boss.",
		"is_peaceful": true,
	},
	"foremans_office": {
		"name": "The Foreman's Office",
		"enemies": ["The Foreman Eternal"],
		"flavor": "Boss arena. Conveyor belt throne, glass case with skull. The Foreman Eternal — construct-lich.",
		"faction": "Construct",
		"is_boss": true,
	},
}

# ============================================================================
# FLOOR 10 ROOM COMPOSITIONS — The Dragon's Lair (11 Moments)
# ============================================================================

const FLOOR10_COMPOSITIONS = {
	"moment_01_threshold": {
		"name": "The Threshold",
		"enemies": [],
		"flavor": "Ghost of Floor 1. The Door remembers you.",
		"is_peaceful": true,
	},
	"moment_02_witness": {
		"name": "The Witness",
		"enemies": [],
		"flavor": "Ghost of Floor 2. Spore Heart remembers you.",
		"is_peaceful": true,
	},
	"moment_03_memory": {
		"name": "The Memory",
		"enemies": [],
		"flavor": "Ghost of Floor 3. Gear Mother remembers you.",
		"is_peaceful": true,
	},
	"moment_04_hoard": {
		"name": "The Hoard",
		"enemies": [],
		"flavor": "Crystallized choices. Touch them. Remember.",
		"is_peaceful": true,
	},
	"moment_05_weight": {
		"name": "The Weight",
		"enemies": [],
		"flavor": "Your score. Your choices. The Dragon sees this.",
		"is_peaceful": true,
	},
	"moment_06_first_aspect": {
		"name": "The First Aspect",
		"enemies": ["Aspect of Time"],
		"flavor": "I am what you spent. I am every turn you used to hurt others.",
		"is_boss": false,
	},
	"moment_07_second_aspect": {
		"name": "The Second Aspect",
		"enemies": ["Aspect of Greed"],
		"flavor": "I am what you kept. I am every gem you hoarded.",
		"is_boss": false,
	},
	"moment_08_third_aspect": {
		"name": "The Third Aspect",
		"enemies": ["Aspect of Transformation"],
		"flavor": "I am what you changed. I wear your image.",
		"is_boss": false,
	},
	"moment_09_approach": {
		"name": "The Approach",
		"enemies": [],
		"flavor": "The Dragon awaits. There is no turning back.",
		"is_peaceful": true,
	},
	"moment_10_revelation": {
		"name": "The Revelation",
		"enemies": ["The Dragon"],
		"flavor": "The Dragon speaks. Will you listen, or strike?",
		"is_boss": true,
	},
	"moment_11_throne": {
		"name": "The Throne",
		"enemies": [],
		"flavor": "The Final Choice. Destroy, Become, or Walk Away.",
		"is_peaceful": true,
	},
}

# ============================================================================
# FLOOR 4 UNDERCROFT COMPOSITIONS
# ============================================================================

const FLOOR4_UNDERCROFT_COMPOSITIONS = {
	"construct_patrol_1": {
		"name": "Pipe Patrol",
		"enemies": ["Piston Assembly", "Piston Assembly"],
		"flavor": "Automated constructs patrol the steam pipes. They do not question orders.",
		"level": "undercroft",
	},
	"construct_patrol_2": {
		"name": "Gear Cellar Guards",
		"enemies": ["Gear Pair", "Diagnostic Eye"],
		"flavor": "The gear cellar is protected. The guards have not slept in centuries.",
		"level": "undercroft",
	},
	"gear_wagon_ambush": {
		"name": "The Gear Wagon",
		"enemies": ["Engine Block", "Drive Train"],
		"flavor": "A runaway gear wagon barrels toward you. Dodge or be crushed.",
		"level": "undercroft",
		"is_trap": true,
	},
	"aether_slick_encounter": {
		"name": "Aether Slick Spirits",
		"enemies": ["The Forgotten", "The Afterimage"],
		"flavor": "The aether-fluid reflects something that isn't you. It reaches out.",
		"level": "undercroft",
	},
}

# ============================================================================
# FLOOR 4 REFECTORY COMPOSITIONS
# ============================================================================

const FLOOR4_REFECTORY_COMPOSITIONS = {
	"sample_crier_balcony": {
		"name": "The Sample Crier (Refectory)",
		"enemies": ["The Cursor", "The Forgotten"],
		"flavor": "The holographic barker drifts between balconies. It sells your own face back to you.",
		"level": "refectory",
		"is_trap": true,
	},
	"memory_feast": {
		"name": "The Memory Feast",
		"enemies": ["Mirror Self"],
		"flavor": "The food is memory made edible. So is the enemy at your table.",
		"level": "refectory",
	},
	"steam_pipe_phantom": {
		"name": "Pipe Phantom",
		"enemies": ["The Lag", "The Lag"],
		"flavor": "Voices of past customers echo through the steam pipes. Then one of them isn't a recording.",
		"level": "refectory",
	},
	"balcony_wanderer": {
		"name": "Balcony Aberration",
		"enemies": ["The Bug"],
		"flavor": "Something glitched its way up from the main floor. It doesn't belong here either.",
		"level": "refectory",
	},
}

# ============================================================================
# PUBLIC API
# ============================================================================

static func get_floor_composition(floor_id: int, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Generic floor composition lookup. Routes to floor-specific methods."""
	match floor_id:
		1: return get_floor1_composition(room_id, encounter_type)
		2: return get_floor2_composition(room_id, encounter_type)
		4: return get_floor4_composition(room_id, encounter_type)
		5: return get_floor5_composition(room_id, encounter_type)
		6: return get_floor6_composition(room_id, encounter_type)
		7: return get_floor7_composition(room_id, encounter_type)
		8: return get_floor8_composition(room_id, encounter_type)
		9: return get_floor9_composition(room_id, encounter_type)
		10: return get_floor10_composition(room_id, encounter_type)
		_: return _fallback_composition()

static func get_floor10_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 10 moment.

	Args:
		room_id: Moment ID string (moment_01_threshold through moment_11_throne)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, is_peaceful, is_boss
	"""
	if not FLOOR10_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR10_COMPOSITIONS[room_id]
	return _build_floor10_comp(comp, room_id, encounter_type)

static func _build_floor10_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 10 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor10 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_floor2_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 2 room.
	
	Args:
		room_id: Room ID string (upper, middle, lower, secret, spore_heart)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)
	
	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_secret, is_boss
	"""
	if not FLOOR2_COMPOSITIONS.has(room_id):
		return _fallback_composition()
	
	var comp = FLOOR2_COMPOSITIONS[room_id]
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))
	
	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor2 room %s" % [enemy_name, room_id])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_secret": comp.get("is_secret", false),
		"is_boss": comp.get("is_boss", false),
		"is_peaceful": comp.get("is_peaceful", false),
		"room_id": room_id,
	}

static func get_floor4_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for Floor 4.
	
	Floor 4 has three levels:
	  - Main: 12 booths (real vendors + trap booths)
	  - Undercroft: Construct patrols, gear wagon ambush, aether slick encounters
	  - Refectory: Sample crier, memory feast, steam pipe phantoms
	"""
	# Check main level booth compositions
	if FLOOR4_COMPOSITIONS.has(room_id):
		return _build_floor4_comp(FLOOR4_COMPOSITIONS[room_id], room_id)
	
	# Check undercroft compositions
	if FLOOR4_UNDERCROFT_COMPOSITIONS.has(room_id):
		return _build_floor4_comp(FLOOR4_UNDERCROFT_COMPOSITIONS[room_id], room_id)
	
	# Check refectory compositions
	if FLOOR4_REFECTORY_COMPOSITIONS.has(room_id):
		return _build_floor4_comp(FLOOR4_REFECTORY_COMPOSITIONS[room_id], room_id)
	
	return _fallback_composition()

static func _build_floor4_comp(comp: Dictionary, room_id: String) -> Dictionary:
	"""Build a Floor 4 composition from raw data."""
	var enemy_names = comp.get("enemies", [])
	
	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor4 room %s" % [enemy_name, room_id])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"is_trap": comp.get("is_trap", false),
		"trap_type": comp.get("trap_type", ""),
		"level": comp.get("level", "main"),
		"room_id": room_id,
	}

static func get_floor5_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 5 room.

	Args:
		room_id: Room ID string (mooring, breeze, boiler, gale, cargo, crow, aether)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_secret, is_boss
	"""
	if not FLOOR5_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR5_COMPOSITIONS[room_id]
	return _build_floor5_comp(comp, room_id, encounter_type)

static func _build_floor5_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 5 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor5 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_secret": comp.get("is_secret", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func _build_floor6_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 6 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor6 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_floor7_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 7 room.

	Args:
		room_id: Room ID string (office, court, break_room, filing, corridor, laboratory, storage, court_ii, void_lab, antechamber, auditorium)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_peaceful, is_boss
	"""
	if not FLOOR7_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR7_COMPOSITIONS[room_id]
	return _build_floor7_comp(comp, room_id, encounter_type)

static func _build_floor7_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 7 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor7 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_floor8_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 8 room.

	Args:
		room_id: Room ID string (loading_bay, lower_works, break_room, containment_hall, the_leak, middle_works, union_hall, the_crack, upper_works, padlock_door, control_room)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_peaceful, is_boss
	"""
	if not FLOOR8_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR8_COMPOSITIONS[room_id]
	return _build_floor8_comp(comp, room_id, encounter_type)

static func _build_floor8_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 8 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor8 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_floor9_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 9 room.

	Args:
		room_id: Room ID string (loading_dock, assembly_line, break_station, furnace_room, quality_control, bone_yard, gear_works, conveyor_maze, foundry_pit, locker_room, foremans_office)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_peaceful, is_boss
	"""
	if not FLOOR9_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR9_COMPOSITIONS[room_id]
	return _build_floor9_comp(comp, room_id, encounter_type)

static func _build_floor9_comp(comp: Dictionary, room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Build a Floor 9 composition from raw data."""
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))

	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor9 room %s" % [enemy_name, room_id])

	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"faction": comp.get("faction", ""),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_floor6_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 6 room.

	Args:
		room_id: Room ID string (quadrangle, gears, echoes, aether, pacts, undercroft, clocktower)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)

	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, faction, is_peaceful, is_boss
	"""
	if not FLOOR6_COMPOSITIONS.has(room_id):
		return _fallback_composition()

	var comp = FLOOR6_COMPOSITIONS[room_id]
	return _build_floor6_comp(comp, room_id, encounter_type)

static func get_floor1_composition(room_id: String, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a Floor 1 room.
	
	Args:
		room_id: Room ID string (north, east, south, west, boss)
		encounter_type: 'enemies' (standard), 'ambush' (extra enemies)
	
	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor, is_tutorial, is_peaceful, is_boss
	"""
	if not FLOOR1_COMPOSITIONS.has(room_id):
		return _fallback_composition()
	
	var comp = FLOOR1_COMPOSITIONS[room_id]
	var enemy_names = comp.get(encounter_type, comp.get("enemies", []))
	
	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in floor1 room %s" % [enemy_name, room_id])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp.get("flavor", ""),
		"is_tutorial": comp.get("is_tutorial", false),
		"is_peaceful": comp.get("is_peaceful", false),
		"is_boss": comp.get("is_boss", false),
		"room_id": room_id,
	}

static func get_room_composition(room_id: int, encounter_type: String = "enemies") -> Dictionary:
	"""Get enemy composition for a room.
	
	Args:
		room_id: Room number (1-11)
		encounter_type: 'enemies' (standard), 'ambush' (puzzle ambush), 'trap' (trap combat)
	
	Returns:
		Dictionary with keys: name, enemies (Array[EnemyTemplate]), flavor
	"""
	if not ROOM_COMPOSITIONS.has(room_id):
		return _fallback_composition()
	
	var comp = ROOM_COMPOSITIONS[room_id]
	var enemy_names = comp.get(encounter_type, comp["enemies"])
	
	var templates: Array[EnemyTemplate] = []
	for enemy_name in enemy_names:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
		else:
			push_warning("RoomEnemyDatabase: Unknown enemy '%s' in room %d" % [enemy_name, room_id])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp["flavor"],
		"room_id": room_id,
	}

static func get_trap_composition(trap_type: String) -> Dictionary:
	"""Get enemy composition for a trap-triggered combat."""
	if not TRAP_COMPOSITIONS.has(trap_type):
		return _fallback_composition()
	
	var comp = TRAP_COMPOSITIONS[trap_type]
	var templates: Array[EnemyTemplate] = []
	for enemy_name in comp["enemies"]:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp["flavor"],
		"trap_type": trap_type,
	}

static func get_boss_composition(boss_name: String) -> Dictionary:
	"""Get boss encounter composition."""
	if not BOSS_COMPOSITIONS.has(boss_name):
		return _fallback_composition()
	
	var comp = BOSS_COMPOSITIONS[boss_name]
	var templates: Array[EnemyTemplate] = []
	for enemy_name in comp["enemies"]:
		if ENEMIES.has(enemy_name):
			templates.append(ENEMIES[enemy_name])
	
	return {
		"name": comp["name"],
		"enemies": templates,
		"flavor": comp["flavor"],
		"is_boss": true,
	}

static func get_all_enemy_names() -> Array:
	"""Return all available enemy template names."""
	return ENEMIES.keys()

static func get_enemy_template(name: String) -> EnemyTemplate:
	if ENEMIES.has(name):
		return ENEMIES[name]
	return null

static func _fallback_composition() -> Dictionary:
	"""Fallback when no specific composition exists."""
	return {
		"name": "Gear Minions",
		"enemies": [ENEMIES["Piston Assembly"], ENEMIES["Piston Assembly"]],
		"flavor": "Generic maintenance constructs respond to disturbance.",
		"fallback": true,
	}
