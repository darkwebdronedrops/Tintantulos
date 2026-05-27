extends FloorController

# ===================================================================
# FLOOR 6 CONTROLLER — The Lunar University
# Refactored to use FloorController base class + Floor6Template
# ===================================================================
# Adds: Curriculum/grading system, moonlight beams, clocktower bell,
#       lecture hall panic, toxic ink, The Dean boss, Undercroft goblin
# ===================================================================

@onready var floor6_template: Floor6Template = Floor6Template.new()

# Curriculum State
var assigned_courses: Array[Dictionary] = []
var course_progress: Dictionary = {}
var player_grades: Dictionary = {}
var audit_mode: bool = false
var graduate_status: bool = false
var all_courses_completed: bool = false

# Moonlight State
var moonlight_turn_count: int = 0
var moonlight_beam_positions: Array[Vector2] = []
var in_moonlight: bool = false
var moonlight_shift_interval: int = 5

# Clocktower State
var clocktower_turn_count: int = 0
var clocktower_bell_interval: int = 10
var clocktower_sabotaged: bool = false

# Lecture Hall Panic
var active_professors: Dictionary = {}  # room_id -> professor_entity_id
var panicking_students: Dictionary = {}  # room_id -> Array[student_ids]

# Toxic Ink (College of Echoes)
var in_echoes_library: bool = false
var toxic_ink_attention_drain: int = 1

# Boss State (The Dean)
var boss_current_phase: String = "administration"  # "administration" | "lunar"
var boss_phase_transitioned: bool = false

# Undercroft Goblin
var goblin_janitor_befriended: bool = false
var master_key_held: bool = false

# UI References
var curriculum_ui: Label
var moonlight_ui: Label
var clocktower_ui: Label
var grade_ui: Label
var boss_phase_ui: Label

func _ready():
	floor_template = floor6_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Restore saved state
	if GameState.floor6_graduate_status == "graduate":
		graduate_status = true
		_show_notification("🎓 Graduate Status active — No course assignment needed.", Color(0.3, 0.9, 0.3))
	
	if GameState.floor6_clocktower_sabotaged:
		clocktower_sabotaged = true
	
	if GameState.floor6_master_key:
		master_key_held = true
	
	# Initialize configurations
	var moonlight_config = floor6_template.get_moonlight_config()
	moonlight_shift_interval = moonlight_config.get("shift_interval", 5)
	
	var clock_config = floor6_template.get_clocktower_config()
	clocktower_bell_interval = clock_config.get("bell_interval", 10)
	
	print("[Floor6] Moonlight interval: %d | Bell interval: %d | Sabotaged: %s" % [
		moonlight_shift_interval, clocktower_bell_interval, clocktower_sabotaged
	])
	
	# Add shop kiosk
	var kiosk = Node2D.new()
	kiosk.name = "ShopKiosk"
	kiosk.position = Vector2(500, 400)
	add_child(kiosk)
	print("[Floor6] Shop kiosk added")

func _setup_floor_ui():
	# Curriculum / course display
	curriculum_ui = Label.new()
	curriculum_ui.name = "CurriculumUI"
	curriculum_ui.position = Vector2(20, 20)
	curriculum_ui.size = Vector2(400, 80)
	curriculum_ui.add_theme_font_size_override("font_size", 13)
	add_child(curriculum_ui)
	_update_curriculum_display()
	
	# Moonlight status
	moonlight_ui = Label.new()
	moonlight_ui.name = "MoonlightUI"
	moonlight_ui.position = Vector2(20, 110)
	moonlight_ui.size = Vector2(300, 30)
	moonlight_ui.add_theme_font_size_override("font_size", 12)
	add_child(moonlight_ui)
	_update_moonlight_display()
	
	# Clocktower status
	clocktower_ui = Label.new()
	clocktower_ui.name = "ClocktowerUI"
	clocktower_ui.position = Vector2(20, 150)
	clocktower_ui.size = Vector2(300, 30)
	clocktower_ui.add_theme_font_size_override("font_size", 12)
	add_child(clocktower_ui)
	_update_clocktower_display()
	
	# Grade display (hidden until courses assigned)
	grade_ui = Label.new()
	grade_ui.name = "GradeUI"
	grade_ui.position = Vector2(20, 190)
	grade_ui.size = Vector2(300, 60)
	grade_ui.add_theme_font_size_override("font_size", 12)
	grade_ui.visible = false
	add_child(grade_ui)

func _update_floor_ui():
	_update_curriculum_display()
	_update_moonlight_display()
	_update_clocktower_display()
	if not assigned_courses.is_empty():
		_update_grade_display()

# -------------------------------------------------------------------
# Curriculum System — Course Assignment & Grading
# -------------------------------------------------------------------

func _assign_courses():
	"""The Registrar assigns 3 courses to the player."""
	if graduate_status or audit_mode:
		return
	
	var config = floor6_template.get_course_config()
	var course_types = ["Construct", "Undead", "Elemental"]
	
	# Shuffle and pick 3
	course_types.shuffle()
	assigned_courses.clear()
	course_progress.clear()
	
	for i in range(config["courses_per_visit"]):
		var course_type = course_types[i]
		var course = {
			"id": i,
			"type": course_type,
			"defeated_count": 0,
			"damage_taken": false,
			"completed": false
		}
		assigned_courses.append(course)
		course_progress[i] = 0
		player_grades[i] = "F"
	
	_show_dialogue("The Registrar", "Welcome to the Lunar University.\nYou are enrolled in 3 courses:\n\n1. Engineering (Construct)\n2. History (Undead)\n3. Elemental Theory (Elemental)\n\nDefeat the required enemies. Take no damage for an A.\nFail and face detention.")
	_update_curriculum_display()
	print("[Floor6] 3 courses assigned")

func _audit_courses():
	"""Player chooses to audit — no requirements, no rewards."""
	audit_mode = true
	_show_dialogue("The Registrar", "Audit status confirmed.\nNo requirements. No rewards.\nSafe passage granted.")
	print("[Floor6] Audit mode activated")

func _refuse_courses():
	"""Player refuses — all enemies become hostile (hard mode)."""
	_show_dialogue("The Registrar", "UNENROLLED.\nAll campus security to quadrangle.\nDISCIPLINARY ACTION INITIATED.")
	
	# Spawn additional security in quadrangle
	var quad = rooms.get("quadrangle")
	if quad and quad.has_method("spawn_security"):
		quad.spawn_security(3)  # 3 extra Calibration Drones
	
	print("[Floor6] Hard mode — all enemies hostile")

func _record_enemy_defeat(faction: String, damage_taken: bool):
	"""Record an enemy defeat for course progress."""
	if audit_mode or graduate_status or assigned_courses.is_empty():
		return
	
	for i in range(assigned_courses.size()):
		var course = assigned_courses[i]
		if course["type"] == faction and not course["completed"]:
			course["defeated_count"] += 1
			if damage_taken:
				course["damage_taken"] = true
			
			_update_course_grade(i)
			print("[Floor6] Course %d progress: %d defeats, grade: %s" % [
				i, course["defeated_count"], player_grades[i]
			])
	
	_update_curriculum_display()
	_check_all_courses_complete()

func _update_course_grade(course_id: int):
	"""Calculate grade for a course based on progress."""
	var course = assigned_courses[course_id]
	var config = floor6_template.get_course_config()
	var grading = config["grading"]
	
	var count = course["defeated_count"]
	var no_damage = not course["damage_taken"]
	
	if count >= grading["A"]["defeat_count"] and no_damage:
		player_grades[course_id] = "A"
	elif count >= grading["B"]["defeat_count"]:
		player_grades[course_id] = "B"
	elif count >= grading["C"]["defeat_count"]:
		player_grades[course_id] = "C"
	else:
		player_grades[course_id] = "F"

func _check_all_courses_complete():
	"""Check if all courses have at least a C grade."""
	if assigned_courses.is_empty():
		return
	
	var all_passed = true
	var any_failed = false
	
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		if grade == "F":
			all_passed = false
			any_failed = true
		assigned_courses[i]["completed"] = (grade != "F")
	
	if all_passed and not all_courses_completed:
		all_courses_completed = true
		_show_dialogue("The Registrar", "ALL COURSES PASSED.\nGraduation requirements met.\nThe Dean's elevator is now accessible.")
		_unlock_dean_elevator()
	elif any_failed and all_courses_completed:
		# Shouldn't happen, but handle
		all_courses_completed = false

func _apply_course_rewards():
	"""Give rewards based on final grades."""
	if audit_mode:
		return
	
	var config = floor6_template.get_course_config()
	var total_gems = 0
	
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		var grading = config["grading"].get(grade, {})
		
		var gems = grading.get("gems", 0)
		var tier = grading.get("reward_tier", "none")
		
		if gems > 0:
			total_gems += gems
		
		if tier != "none":
			# TODO: Add card to deck based on tier
			print("[Floor6] Course %d reward: %s tier card" % [i, tier])
		
		if grade == "F":
			# Detention combat
			_trigger_detention()
	
	if total_gems > 0:
		GameState.gems += total_gems
		if GameState.has_signal("gems_changed"):
			GameState.gems_changed.emit(GameState.gems)
		_show_notification("🎓 Course rewards: %d Gems!" % total_gems, Color(0.3, 0.9, 0.3))

func _trigger_detention():
	"""Trigger detention combat with campus security."""
	_show_notification("⚠ DETENTION! Campus security incoming!", Color(0.9, 0.3, 0.3))
	
	var security = RoomEnemyDatabase.ENEMIES.get("calibration_drone", null)
	if security:
		var combat_manager = $CombatManager if has_node("CombatManager") else null
		if combat_manager:
			in_combat = true
			var enemies = []
			enemies.append(security.to_combat_data())
			enemies.append(security.to_combat_data())
			combat_manager.start_combat(enemies, GameState.player_deck)

func _update_curriculum_display():
	if not curriculum_ui:
		return
	
	if audit_mode:
		curriculum_ui.text = "📝 AUDIT MODE — Safe Passage"
		curriculum_ui.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		return
	
	if graduate_status:
		curriculum_ui.text = "🎓 GRADUATE — No Courses Required"
		curriculum_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		return
	
	if assigned_courses.is_empty():
		curriculum_ui.text = "📝 No Courses Assigned\nTalk to The Registrar"
		curriculum_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		return
	
	var text = "📝 CURRICULUM:\n"
	for i in range(assigned_courses.size()):
		var course = assigned_courses[i]
		var grade = player_grades.get(i, "F")
		var color = Color(0.8, 0.8, 0.8)
		match grade:
			"A": color = Color(0.3, 0.9, 0.3)
			"B": color = Color(0.5, 0.8, 0.5)
			"C": color = Color(0.7, 0.7, 0.5)
			"F": color = Color(0.9, 0.3, 0.3)
		
		text += "%d. %s: %d/%d [%s]\n" % [
			i + 1, course["type"],
			course["defeated_count"],
			5 if grade == "A" else (3 if grade == "B" else 1),
			grade
		]
	
	curriculum_ui.text = text
	curriculum_ui.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_grade_display():
	if not grade_ui:
		return
	
	var text = "GRADES:\n"
	for i in range(assigned_courses.size()):
		var grade = player_grades.get(i, "F")
		text += "Course %d: %s\n" % [i + 1, grade]
	
	grade_ui.text = text
	grade_ui.visible = true

# -------------------------------------------------------------------
# Moonlight Beam System
# -------------------------------------------------------------------

func _on_combat_started():
	"""Reset moonlight tracking at combat start."""
	moonlight_turn_count = 0
	in_moonlight = false
	_update_moonlight_display()

func _shift_moonlight_beams():
	"""Move moonlight beams to new positions."""
	# Randomly reposition 3 beams in the arena
	moonlight_beam_positions.clear()
	for i in range(3):
		var angle = randf() * TAU
		var dist = 200.0 + randf() * 300.0
		moonlight_beam_positions.append(Vector2(cos(angle) * dist, sin(angle) * dist))
	
	_show_notification("🌙 Moonlight shifts...", Color(0.7, 0.7, 0.9))
	print("[Floor6] Moonlight beams shifted to %d positions" % moonlight_beam_positions.size())

func _check_player_moonlight_position():
	"""Check if player is standing in moonlight or shadow."""
	if moonlight_beam_positions.is_empty():
		return
	
	var player_pos = player_node.global_position if player_node else Vector2.ZERO
	var in_light = false
	
	for beam_pos in moonlight_beam_positions:
		if player_pos.distance_to(beam_pos) < 100.0:  # Beam radius
			in_light = true
			break
	
	if in_light and not in_moonlight:
		# Entered light
		in_moonlight = true
		_show_notification("🌙 MOONLIGHT — Text revealed! Patrols alerted!", Color(0.7, 0.7, 0.9))
		# TODO: Reveal hidden text, attract patrols
		
	elif not in_light and in_moonlight:
		# Entered shadow
		in_moonlight = false
		_show_notification("🌑 SHADOW — Hidden from patrols.", Color(0.3, 0.3, 0.4))
		# TODO: Hide from patrols

func _update_moonlight_display():
	if not moonlight_ui:
		return
	
	var next_shift = moonlight_shift_interval - (moonlight_turn_count % moonlight_shift_interval)
	var status = "🌙 Moonlight: %s | Next shift: %d" % [
		"LIGHT" if in_moonlight else "SHADOW",
		next_shift
	]
	
	var color = Color(0.7, 0.7, 0.9) if in_moonlight else Color(0.3, 0.3, 0.4)
	moonlight_ui.text = status
	moonlight_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Clocktower Bell System
# -------------------------------------------------------------------

func _ring_clocktower_bell():
	"""The bell rings — all enemies on floor heal 5 HP."""
	_show_notification("🔔 BELL RINGS — Classes resume! Enemies heal 5 HP!", Color(0.9, 0.7, 0.3))
	
	# Heal all active enemies in current combat
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if combat_manager and combat_manager.has_method("heal_all_enemies"):
		combat_manager.heal_all_enemies(5)
	
	print("[Floor6] Clocktower bell — all enemies healed 5 HP")

func _sabotage_clocktower():
	"""Sabotage the clock mechanism — stops bell permanently."""
	if clocktower_sabotaged:
		_show_notification("Clock already sabotaged.", Color(0.7, 0.7, 0.7))
		return
	
	clocktower_sabotaged = true
	GameState.floor6_clocktower_sabotaged = true
	
	_show_notification("🔧 CLOCK SABOTAGED — Bell silenced forever!", Color(0.9, 0.3, 0.3))
	_show_dialogue("The Tower", "The clocktower mechanism grinds to a halt.\nThe bell will never ring again.\nBut campus security has been alerted...")
	
	# Spawn security as punishment
	_trigger_detention()
	
	_update_clocktower_display()
	print("[Floor6] Clocktower sabotaged!")

func _speed_up_clock():
	"""Speed up clock — enemies age and take DOT."""
	_show_notification("⏱ CLOCK ACCELERATED — Enemies age rapidly!", Color(0.9, 0.5, 0.2))
	
	# Apply DOT to all enemies
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if combat_manager and combat_manager.has_method("apply_dot_all_enemies"):
		combat_manager.apply_dot_all_enemies(3, 3)  # 3 damage per turn for 3 turns

func _update_clocktower_display():
	if not clocktower_ui:
		return
	
	if clocktower_sabotaged:
		clocktower_ui.text = "🔧 CLOCK: SABOTAGED"
		clocktower_ui.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		var next_bell = clocktower_bell_interval - (clocktower_turn_count % clocktower_bell_interval)
		clocktower_ui.text = "🔔 Bell: %d turns" % next_bell
		clocktower_ui.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

# -------------------------------------------------------------------
# Lecture Hall Panic
# -------------------------------------------------------------------

func _on_professor_defeated(room_id: String, professor_id: String):
	"""When a professor is defeated, students panic."""
	if not active_professors.has(room_id):
		return
	
	active_professors.erase(room_id)
	
	var students = panicking_students.get(room_id, [])
	if students.is_empty():
		return
	
	_show_notification("📚 PROFESSOR DEFEATED! Students panic!", Color(0.9, 0.9, 0.3))
	
	# Students take random actions: flee, attack wildly, or freeze
	for student_id in students:
		var roll = randi() % 3
		match roll:
			0:
				# Flee
				print("[Floor6] Student %s flees!" % student_id)
				# TODO: Remove from combat
			1:
				# Attack wildly
				print("[Floor6] Student %s attacks wildly!" % student_id)
				# TODO: Random target attack
			2:
				# Freeze
				print("[Floor6] Student %s freezes in panic!" % student_id)
				# TODO: Skip turn
	
	panicking_students.erase(room_id)

func _register_lecture_hall(room_id: String, professor_id: String, student_ids: Array):
	"""Register a lecture hall encounter for panic tracking."""
	active_professors[room_id] = professor_id
	panicking_students[room_id] = student_ids.duplicate()
	print("[Floor6] Lecture hall registered: %s with %d students" % [room_id, student_ids.size()])

# -------------------------------------------------------------------
# Toxic Ink (College of Echoes)
# -------------------------------------------------------------------

func _on_room_entered(room_id: String):
	"""Override to check for toxic ink zones."""
	super._on_room_entered(room_id)
	
	if room_id == "echoes":
		in_echoes_library = true
		_show_notification("📚 Entered library — Toxic ink detected.", Color(0.5, 0.3, 0.3))
	else:
		in_echoes_library = false

# -------------------------------------------------------------------
# Boss Phase System (The Dean)
# -------------------------------------------------------------------

func _check_boss_phase(boss_hp: int, max_hp: int = 70) -> String:
	"""Determine current boss phase based on HP percentage."""
	var hp_percent = float(boss_hp) / max_hp
	
	var new_phase = "administration"
	if hp_percent <= 0.5:
		new_phase = "lunar"
	
	if new_phase != boss_current_phase:
		boss_current_phase = new_phase
		boss_phase_transitioned = true
		_on_boss_phase_transition(new_phase)
	
	return new_phase

func _on_boss_phase_transition(new_phase: String):
	"""Handle boss phase change effects."""
	match new_phase:
		"lunar":
			_show_notification("🌙 PHASE 2: LUNAR CONSTRUCT — Moonlight floods the arena!", Color(0.7, 0.7, 0.9))
			_show_dialogue("The Dean", "The clocktower glass shatters.\nMoonlight floods the arena.\nI become the night.")
			
			# Moonlight beams now heal Dean
			# Student spawns become Undead
			# TODO: Update spawn logic
			
			# Apply "tenure" — cannot be debuffed
			print("[Floor6] Dean enters Lunar phase — immune to debuffs")

func _update_boss_phase_display():
	if not boss_phase_ui:
		return
	
	var color = Color(0.8, 0.8, 0.8)
	match boss_current_phase:
		"administration": color = Color(0.5, 0.5, 0.6)
		"lunar": color = Color(0.7, 0.7, 0.9)
	
	boss_phase_ui.text = "BOSS: The Dean [%s PHASE]" % boss_current_phase.to_upper()
	boss_phase_ui.add_theme_color_override("font_color", color)
	boss_phase_ui.visible = true

# -------------------------------------------------------------------
# Undercroft Goblin (Sneak Thief)
# -------------------------------------------------------------------

func _interact_with_goblin():
	"""Interact with the Undercroft janitor goblin."""
	if goblin_janitor_befriended:
		_show_dialogue("Sneak Thief", "Hey pal! Need a key? I 'borrowed' one from the Dean's office.\nTake it — no strings attached.\n...okay, 5 Gems interest. Payable never.")
		
		if not master_key_held:
			master_key_held = true
			GameState.floor6_master_key = true
			_show_notification("🔑 MASTER KEY acquired! Opens any locked door!", Color(0.9, 0.7, 0.3))
	else:
		# First interaction
		_show_dialogue("Sneak Thief", "Yo. I'm the union rep for maintenance goblins.\nYou look like someone who needs doors opened.\nI can help. But you gotta be cool.")
		goblin_janitor_befriended = true
		GameState.floor6_goblin_janitor_befriended = true
		_show_notification("🤝 Goblin janitor befriended!", Color(0.3, 0.9, 0.3))

func _steal_card_with_iou():
	"""Goblin steals a card but leaves an IOU (returns after 3 turns + 5 Gems)."""
	# TODO: Steal random card from player deck
	_show_notification("💰 Goblin 'borrows' a card! IOU: Returns in 3 turns + 5 Gems!", Color(0.9, 0.7, 0.3))
	
	# Schedule return
	await get_tree().create_timer(3.0).timeout  # 3 turns ≈ 3 seconds in real-time
	# TODO: Return card + 5 Gems
	_show_notification("💰 IOU repaid! Card returned + 5 Gems!", Color(0.3, 0.9, 0.3))

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		"Talk to Registrar":
			if assigned_courses.is_empty() and not graduate_status and not audit_mode:
				_assign_courses()
			elif graduate_status:
				_show_dialogue("The Registrar", "Welcome back, Graduate.\nAll courses waived.\nThe Dean awaits.")
			elif audit_mode:
				_show_dialogue("The Registrar", "Audit status confirmed.\nProceed safely.")
			else:
				_show_dialogue("The Registrar", "Courses in progress.\nComplete your curriculum.")
		
		"Sabotage Clock":
			_sabotage_clocktower()
		
		"Adjust Clock":
			_speed_up_clock()
		
		"Read Book":
			_read_book()
		
		"Study Tome":
			_study_tome()
		
		"Align Gear":
			_align_gear()
		
		"Dean's Office":
			if master_key_held or all_courses_completed:
				_unlock_dean_elevator()
			else:
				_show_dialogue("Dean's Office", "Locked. Requires Dean's Key or course completion.")
		
		"College of Pacts":
			if master_key_held:
				_show_dialogue("College of Pacts", "The Master Key turns.\nThe heavy doors groan open.\nRed light spills out.")
				# TODO: Unlock College of Pacts early
			else:
				_show_dialogue("College of Pacts", "LOCKED.\nRequires Dean's Permission and Signed Waiver.\n...or a really good key.")
		
		"Talk to Janitor":
			_interact_with_goblin()
		
		"Read Inscription":
			if in_moonlight:
				_show_dialogue("Inscription", "The moonlight reveals hidden text:\n'Knowledge consumes those who seek it.'")
			else:
				_show_dialogue("Inscription", "Just scratched stone. Nothing readable.")
		
		"Search Cache":
			if not in_moonlight:
				_show_notification("🔍 Found hidden cache! 10 Gems!", Color(0.9, 0.7, 0.3))
				GameState.gems += 10
				if GameState.has_signal("gems_changed"):
					GameState.gems_changed.emit(GameState.gems)
			else:
				_show_notification("Nothing here. Too bright to hide anything.", Color(0.7, 0.7, 0.7))
		
		"Defend Thesis":
			_defend_thesis()
		
		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.")
		
		"Open Shop":
			_open_shop()
		_:
			super._on_object_interact(object_type)

func _read_book():
	"""Read a book in the library."""
	var roll = randi() % 3
	match roll:
		0:
			_show_dialogue("Book", "Whispered lore: 'The Dean was once a student too.'")
			GameState.floor6_books_read += 1
		1:
			_show_dialogue("Book", "The book SCREAMS! 2 damage from misinformation!")
			# TODO: Apply 2 damage
		2:
			_show_dialogue("Book", "Research notes on Construct vulnerabilities. Next course grade +1!")
			# TODO: Apply research bonus
	
	_check_research_status()

func _study_tome():
	"""Study a research tome."""
	_show_dialogue("Tome", "Dense academic text. You gain 'Research' status.")
	GameState.floor6_books_read += 1
	_check_research_status()

func _check_research_status():
	"""Check if player has read 5 books (Research status)."""
	if GameState.get_value("floor6_books_read", 0) >= 5:
		_show_notification("📚 RESEARCH STATUS — Next course grade +1!", Color(0.3, 0.9, 0.3))
		# TODO: Apply grade boost to next course

func _align_gear():
	"""Align gear in Gear Garden puzzle."""
	_show_notification("⚙ Gear aligned!", Color(0.7, 0.7, 0.7))
	# TODO: Check if all gears aligned → unlock shortcut

func _defend_thesis():
	"""Defend thesis to Undead panel."""
	_show_dialogue("Thesis Panel", "Present your research.")
	
	# Check if player has defeated enough target enemies
	var target_count = 0
	for course in assigned_courses:
		if course["completed"]:
			target_count += 1
	
	if target_count >= 2:
		_show_dialogue("Thesis Panel", "THESIS ACCEPTED.\nDean's Key fragment granted.\nCollege of Pacts partially unlocked.")
		# TODO: Give Dean's Key fragment
	else:
		_show_dialogue("Thesis Panel", "THESIS REJECTED.\nInsufficient research.\nDetention combat initiated.")
		_trigger_detention()

func _unlock_dean_elevator():
	"""Unlock elevator to Clocktower Apex (boss arena)."""
	var clocktower = rooms.get("clocktower")
	if clocktower and clocktower.has_method("unlock_elevator"):
		clocktower.unlock_elevator()
		_show_notification("🛗 Dean's elevator unlocked!", Color(0.3, 0.9, 0.3))
		print("[Floor6] Dean's elevator unlocked!")

# -------------------------------------------------------------------
# Floor Complete — Transition to Floor 7
# -------------------------------------------------------------------

func _on_floor_complete():
	"""Called when The Dean is defeated."""
	_show_dialogue("The Tower", "The Dean falls.\nThe clocktower bell rings one final time —\na graduation chime.\nThe Dean's Key materializes.\nThe path to Floor 7 opens.")
	
	# Give rewards
	GameState.add_card_to_deck("the_dean")  # Boss card
	GameState.gems += 100
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	
	# Grant Graduate status
	graduate_status = true
	GameState.floor6_graduate_status = "graduate"
	
	# Save progress
	GameState.save_game()
	
	# Show floor transition option
	_show_floor_transition_prompt()

func _show_floor_transition_prompt():
	"""Show prompt to ascend to Floor 7."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 7 — The Broken Pact"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

func _ascend_to_next_floor():
	"""Ascend to Floor 7."""
	print("[Floor6] Ascending to Floor 7...")
	get_tree().change_scene_to_file("res://scenes/Floor7.tscn")

# -------------------------------------------------------------------
# Combat Overrides
# -------------------------------------------------------------------

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	"""Override to register lecture halls and check professor presence."""
	# Check if this room has a professor-led encounter
	if room_id in ["gears", "echoes"]:
		# Look for professor in enemy list
		var professor_id = ""
		var student_ids = []
		
		for enemy_name in enemy_names:
			if "professor" in enemy_name.to_lower() or "dean" in enemy_name.to_lower():
				professor_id = enemy_name
			else:
				student_ids.append(enemy_name)
		
		if not professor_id.is_empty() and not student_ids.is_empty():
			_register_lecture_hall(room_id, professor_id, student_ids)
	
	# Check for toxic ink
	if room_id == "echoes":
		in_echoes_library = true
		_show_notification("📚 Toxic ink zone — Attention draining!", Color(0.5, 0.3, 0.3))
	
	# Check for moonlight in quadrangle
	if room_id == "quadrangle":
		_check_player_moonlight_position()
	
	# Normal combat start
	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to apply course progress and check boss defeat."""
	super._on_combat_ended(victory)
	
	if not victory:
		return
	
	# Check if this was boss fight
	if current_room_id == "clocktower":
		_on_floor_complete()
		return
	
	# Check faction kills for course progress
	var room = rooms.get(current_room_id)
	if room and room.has_method("get_defeated_faction"):
		var faction = room.get_defeated_faction()
		var damage_taken = room.get("player_damage_taken") if room.has_method("get") else false
		_record_enemy_defeat(faction, damage_taken)
	
	# Check if professor was defeated (lecture hall panic)
	if current_room_id in active_professors:
		var prof_id = active_professors[current_room_id]
		# Check if professor was in defeated enemies
		# TODO: Check combat manager defeated list
		# _on_professor_defeated(current_room_id, prof_id)

func _on_combat_turn_advanced():
	"""Override to process environmental effects."""
	# Moonlight shift
	moonlight_turn_count += 1
	if moonlight_turn_count % moonlight_shift_interval == 0:
		_shift_moonlight_beams()
	_check_player_moonlight_position()
	
	# Clocktower bell
	clocktower_turn_count += 1
	if not clocktower_sabotaged and clocktower_turn_count % clocktower_bell_interval == 0:
		_ring_clocktower_bell()
	
	# Toxic ink
	if in_echoes_library:
		var drain = toxic_ink_attention_drain
		if GameState.get_value("has_spore_filter", false):
			drain = max(1, drain / 2)
		# TODO: Reduce Attention by drain
		print("[Floor6] Toxic ink drains %d Attention" % drain)
	
	# Update displays
	_update_moonlight_display()
	_update_clocktower_display()
	_update_curriculum_display()

# -------------------------------------------------------------------
# Input Override
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Base class input
	super._input(event)

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_assigned_courses() -> Array:
	return assigned_courses.duplicate()

func get_grades() -> Dictionary:
	return player_grades.duplicate()

func is_graduate() -> bool:
	return graduate_status

func has_master_key() -> bool:
	return master_key_held

func is_clocktower_sabotaged() -> bool:
	return clocktower_sabotaged
