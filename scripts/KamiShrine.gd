extends Node2D
class_name KamiShrine

# Kami Shrine - Offering system for Floor 3 rooms
# Each room may have a shrine with specific kami demands
# Offerings give boons based on item quality and kami preference

signal boon_granted(shrine_name: String, boon_type: String)
signal offering_accepted(item_name: String, kami_response: String)
signal offering_rejected(item_name: String, kami_response: String)

# Shrine configuration
var shrine_name: String = "Unknown Kami"
var preferred_offerings: Array[String] = []  # Item types this kami loves
var accepts_any: bool = false  # Some kami (like desperate water) accept anything
var offering_text: String = "Leave Offering [E]"

# Boon types
var minor_boon: String = ""
var major_boon: String = ""
var epic_boon: String = ""

# Sprite path override (from database)
var sprite_path: String = ""

# Visual state
var has_been_visited: bool = false
var last_offering: String = ""
var boons_granted: int = 0

# Visual components
var shrine_base: Node2D
var shrine_glow: Node2D
var interact_label: Label

# Offering item definitions (mapping item_id -> quality)
const OFFERING_QUALITY = {
	"machine_oil": 1,       # Minor
	"polished_brass": 2,    # Minor/Major
	"interesting_trash": 0, # None (desperate kami only)
	"sacred_gasket": 3,     # Major
	"phosphor_crystal": 3,  # Major
	"gear_devil_token": 5   # Epic (should never be offered, but...)
}

const OFFERING_GEM_VALUE = {
	"machine_oil": 2,
	"polished_brass": 5,
	"interesting_trash": 1,
	"sacred_gasket": 12,
	"phosphor_crystal": 8,
	"gear_devil_token": 50
}

func _ready():
	_setup_visuals()

func _setup_visuals():
	# Determine sprite path: use override if set, otherwise map from name
	var path = sprite_path
	if path.is_empty():
		path = _get_kami_sprite_path()
	
	if ResourceLoader.exists(path):
		var kami_sprite = Sprite2D.new()
		kami_sprite.name = "KamiSprite"
		kami_sprite.texture = load(path)
		kami_sprite.scale = Vector2(1.5, 1.5)  # 64x64 -> 96x96
		kami_sprite.position = Vector2(0, -20)
		add_child(kami_sprite)
		print("KamiShrine: Loaded sprite %s" % path)
	else:
		# Fallback: procedural shrine
		_setup_procedural_visuals()
		print("KamiShrine: Missing sprite %s, using fallback" % path)
	
	# Glow overlay (always added)
	_setup_glow()
	
	# Interaction label
	_setup_label()

func _get_kami_sprite_path() -> String:
	# Map shrine name to sprite file
	match shrine_name:
		"Water Kami", "Desperate Water Kami":
			return "res://assets/sprites/puzzles/kami_friction.png"
		"Heat Kami":
			return "res://assets/sprites/puzzles/kami_heat.png"
		"Maintenance Kami":
			return "res://assets/sprites/puzzles/kami_maintenance.png"
		"Regulation Kami":
			return "res://assets/sprites/puzzles/kami_maintenance.png"
		"Friction Kami":
			return "res://assets/sprites/puzzles/kami_friction.png"
		_:
			return "res://assets/sprites/puzzles/kami_friction.png"

func _setup_procedural_visuals():
	# Shrine base (small alcove/platform)
	shrine_base = Node2D.new()
	shrine_base.name = "ShrineBase"
	
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-20, 10), Vector2(20, 10),
		Vector2(15, -15), Vector2(-15, -15)
	])
	base.color = Color(0.5, 0.45, 0.4)
	shrine_base.add_child(base)
	
	# Shrine icon (small symbol)
	var icon = Polygon2D.new()
	icon.name = "ShrineIcon"
	icon.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(8, 0),
		Vector2(0, 8), Vector2(-8, 0)
	])
	icon.color = Color(0.6, 0.5, 0.8)
	shrine_base.add_child(icon)
	
	add_child(shrine_base)

func _setup_glow():
	# Glow (hidden until activated)
	shrine_glow = Node2D.new()
	shrine_glow.name = "ShrineGlow"
	shrine_glow.visible = false
	
	var glow_circle = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in 16:
		var a = (TAU / 16.0) * i
		pts.append(Vector2(cos(a) * 35, sin(a) * 35))
	glow_circle.polygon = pts
	glow_circle.color = Color(0.8, 0.7, 0.3, 0.3)
	shrine_glow.add_child(glow_circle)
	
	add_child(shrine_glow)

func _setup_label():
	interact_label = Label.new()
	interact_label.name = "InteractLabel"
	interact_label.text = offering_text
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.position = Vector2(-50, -60)
	interact_label.size = Vector2(100, 20)
	interact_label.add_theme_font_size_override("font_size", 11)
	interact_label.modulate = Color(0.9, 0.9, 0.7)
	interact_label.visible = false
	add_child(interact_label)

# --- Offering Logic ---

func try_offering(item_id: String) -> bool:
	"""Attempt to offer an item. Returns true if accepted."""
	var quality = OFFERING_QUALITY.get(item_id, 0)
	
	# Check if kami accepts this
	var accepted = false
	var response = ""
	var boon = ""
	
	if accepts_any:
		# Desperate kami - takes anything
		accepted = true
		response = _get_random_accept_response("desperate")
		boon = _determine_boon(quality, true)
	elif item_id in preferred_offerings:
		# Preferred offering
		accepted = true
		response = _get_random_accept_response("preferred")
		boon = _determine_boon(quality, true)
	elif quality > 0:
		# Non-preferred but still valuable
		accepted = true
		response = _get_random_accept_response("neutral")
		boon = _determine_boon(quality, false)  # Downgrade boon
	else:
		# Trash to non-desperate kami
		accepted = false
		response = _get_random_reject_response()
	
	if accepted:
		last_offering = item_id
		boons_granted += 1
		_grant_boon(boon)
		offering_accepted.emit(item_id, response)
		_show_activation()
	else:
		offering_rejected.emit(item_id, response)
	
	_show_kami_dialogue(response)
	return accepted

func _determine_boon(quality: int, preferred: bool) -> String:
	"""Determine boon based on offering quality"""
	var roll = randi() % 100
	
	if not preferred:
		roll -= 20  # Penalty for non-preferred
	
	if quality >= 4 and roll >= 70:
		return epic_boon
	elif quality >= 2 and roll >= 40:
		return major_boon
	else:
		return minor_boon

func _grant_boon(boon: String):
	"""Apply boon effects to GameState"""
	match boon:
		"cooling_blessing":
			GameState.add_temp_effect("fire_resist", 3)
		"water_walk":
			GameState.add_temp_effect("water_walk", 1)
		"flood_room":
			# Epic: deal damage to all enemies in current room
			GameState.add_temp_effect("room_flood", 1)
		"lubrication_blessing":
			GameState.add_temp_effect("speed_boost", 3)
		"auto_oil":
			# Major: automatically solve next oil-related puzzle
			GameState.add_temp_effect("auto_maintain", 1)
		"machine_ally":
			# Epic: summon construct ally for combat
			GameState.add_temp_effect("construct_ally", 2)
		_:
			# Generic minor: heal 3 HP
			GameState.heal_player(3)
	
	boon_granted.emit(shrine_name, boon)
	print("KamiShrine: %s granted boon '%s'" % [shrine_name, boon])

# --- Responses ---

func _get_random_accept_response(category: String) -> String:
	var responses = {
		"desperate": [
			"Yes... YES! Even this crumb! I accept!",
			"So long since offerings... thank you...",
			"*desperate gurgling* Accepted. Accepted!",
			"Pathetic offering, but I am STARVING."
		],
		"preferred": [
			"Ah! Exactly what I desired!",
			"*satisfied hum* You understand the machine.",
			"Proper maintenance pleases this kami.",
			"A worthy tribute to the gears."
		],
		"neutral": [
			"Not ideal... but I shall accept.",
			"Hmm. Unconventional, but sufficient.",
			"It will do. The machine hungers less now.",
			"Acceptable. Return with better next time."
		]
	}
	
	var list = responses.get(category, responses["neutral"])
	return list[randi() % list.size()]

func _get_random_reject_response() -> String:
	var responses = [
		"*disgusted whirring* Remove that filth.",
		"The machine spits upon your offering.",
		"Unworthy. Come back with proper oil.",
		"*grinding noises* Insult. Pure insult.",
		"Do you mock this kami with trash?"
	]
	return responses[randi() % responses.size()]

# --- Visual Feedback ---

func _show_activation():
	shrine_glow.visible = true
	var tween = create_tween()
	tween.tween_property(shrine_glow, "modulate:a", 0.6, 0.3)
	tween.tween_property(shrine_glow, "modulate:a", 0.3, 0.3)
	tween.set_loops(3)
	
	# Pulse the icon
	var icon = shrine_base.get_node("ShrineIcon")
	var icon_tween = create_tween()
	icon_tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.2)
	icon_tween.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.2)

func _show_kami_dialogue(text: String):
	var dialogue = Label.new()
	dialogue.text = text
	dialogue.position = Vector2(-80, -40)
	dialogue.size = Vector2(160, 40)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.add_theme_font_size_override("font_size", 10)
	dialogue.modulate = Color(0.8, 0.7, 0.9)
	add_child(dialogue)
	
	# Fade out
	var tween = create_tween()
	await get_tree().create_timer(2.5).timeout
	tween.tween_property(dialogue, "modulate:a", 0.0, 0.5)
	await tween.finished
	dialogue.queue_free()

# --- Utility ---

func get_acceptable_offerings() -> Array[String]:
	if accepts_any:
		return ["machine_oil", "polished_brass", "interesting_trash", "sacred_gasket", "phosphor_crystal"]
	return preferred_offerings.duplicate()

func get_save_data() -> Dictionary:
	return {
		"shrine_name": shrine_name,
		"boons_granted": boons_granted,
		"last_offering": last_offering,
		"has_been_visited": has_been_visited
	}

func load_save_data(data: Dictionary):
	boons_granted = data.get("boons_granted", 0)
	last_offering = data.get("last_offering", "")
	has_been_visited = data.get("has_been_visited", false)
