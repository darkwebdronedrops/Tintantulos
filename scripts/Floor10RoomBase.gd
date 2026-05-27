extends Floor1RoomBase
class_name Floor10RoomBase

# ===================================================================
# FLOOR 10 ROOM BASE — The Dragon's Lair
# Extends Floor1RoomBase with moment-specific logic for the 11 moments
# ===================================================================

# Moment configuration
@export var moment_type: String = "ghost"  # ghost, hoard, score, combat, walk, boss_phase_1_2, final_choice
@export var ghost_boss_id: int = 0  # Which floor's boss ghost appears (1-9)
@export var aspect_type: String = ""  # "time", "greed", "transformation" for combat moments
@export var is_final_choice_room: bool = false
@export var hidden_crack_visible: bool = false

# Hoard objects (populated by controller based on player choices)
var hoard_objects: Array[String] = []
var hoard_object_sprites: Dictionary = {}

# Ghost state
var ghost_dialogue_shown: bool = false
var ghost_spoken_to: bool = false

# Aspect state
var aspect_defeated: bool = false

# Final choice state
var choice_made: bool = false

# Signals
signal ghost_dialogue_requested(ghost_id: int)
signal hoard_object_touched(object_id: String)
signal weight_reveal_requested
signal aspect_combat_requested(aspect_id: String)
signal dragon_fight_requested
signal final_choice_made(choice_id: String)
signal hidden_door_entered

func _ready():
	super._ready()
	# Floor 10 rooms are always "interior visible" — no portal hiding
	if interior:
		interior.visible = true
	is_interior_visible = true

# -------------------------------------------------------------------
# Moment-specific setup
# -------------------------------------------------------------------

func setup_moment(config: Dictionary):
	"""Called by Floor10Controller to configure this moment."""
	match moment_type:
		"ghost":
			_setup_ghost_moment(config)
		"hoard":
			_setup_hoard_moment(config)
		"score":
			_setup_score_moment(config)
		"combat":
			_setup_combat_moment(config)
		"walk":
			_setup_walk_moment(config)
		"boss_phase_1_2":
			_setup_boss_moment(config)
		"final_choice":
			_setup_final_choice_moment(config)

func _setup_ghost_moment(config: Dictionary):
	"""Configure ghost encounter."""
	if ghost_boss_id <= 0:
		return
	# Ghost is already in scene, just needs activation
	var ghost = interior.get_node_or_null("GhostBoss")
	if ghost:
		ghost.visible = true
		ghost.modulate = Color(1, 1, 1, 0.7)  # Translucent

func _setup_hoard_moment(config: Dictionary):
	"""Configure hoard objects."""
	# Show only objects relevant to player's choices
	var player_objects = config.get("hoard_objects", [])
	for obj_name in player_objects:
		var sprite = interior.get_node_or_null(obj_name)
		if sprite:
			sprite.visible = true
			hoard_object_sprites[obj_name] = sprite

func _setup_score_moment(config: Dictionary):
	"""Configure weight display."""
	var label = interior.get_node_or_null("WeightLabel")
	if label:
		var weight = config.get("player_weight", 0)
		var label_text = "Light" if weight < 0 else ("Heavy" if weight > 0 else "Balanced")
		label.text = "WEIGHT: %d [%s]" % [weight, label_text]

func _setup_combat_moment(config: Dictionary):
	"""Configure aspect combat."""
	if aspect_type.is_empty():
		return
	var enemy_sprite = interior.get_node_or_null("EnemySprite")
	if enemy_sprite:
		enemy_sprite.visible = true
	# Auto-spawn encounter
	auto_spawn = true
	encounter_type = "enemies"

func _setup_walk_moment(config: Dictionary):
	"""Configure approach moment."""
	pass  # Visuals are in scene

func _setup_boss_moment(config: Dictionary):
	"""Configure Dragon boss moment."""
	var crack = interior.get_node_or_null("HiddenCrack")
	if crack:
		crack.visible = hidden_crack_visible
	auto_spawn = true
	encounter_type = "boss"

func _setup_final_choice_moment(config: Dictionary):
	"""Configure final choice moment."""
	var door = interior.get_node_or_null("HiddenDoor")
	if door:
		# Door visible only if true ending conditions met
		door.visible = config.get("true_ending_available", false)

# -------------------------------------------------------------------
# Interaction overrides
# -------------------------------------------------------------------

func on_player_interact():
	"""Handle player pressing interact in this moment."""
	match moment_type:
		"ghost":
			_interact_ghost()
		"hoard":
			_interact_hoard()
		"score":
			_interact_score()
		"combat":
			_interact_combat()
		"boss_phase_1_2":
			_interact_boss()
		"final_choice":
			_interact_final_choice()
		_:
			super.on_player_entered()

func _interact_ghost():
	if ghost_boss_id > 0 and not ghost_spoken_to:
		ghost_spoken_to = true
		emit_signal("ghost_dialogue_requested", ghost_boss_id)

func _interact_hoard():
	# Check which hoard object is nearby
	for obj_name in hoard_object_sprites.keys():
		var sprite = hoard_object_sprites[obj_name]
		if sprite and _is_player_near(sprite):
			emit_signal("hoard_object_touched", obj_name)
			return
	# If near reveal weight area
	var reveal = interior.get_node_or_null("RevealWeight")
	if reveal and _is_player_near(reveal):
		emit_signal("weight_reveal_requested")

func _interact_score():
	emit_signal("weight_reveal_requested")

func _interact_combat():
	if not aspect_type.is_empty() and not aspect_defeated:
		emit_signal("aspect_combat_requested", aspect_type)

func _interact_boss():
	emit_signal("dragon_fight_requested")

func _interact_final_choice():
	if choice_made:
		return
	# Check which choice area player is near
	# For now, emit the signal and let controller handle selection
	emit_signal("final_choice_made", "pending")

func _is_player_near(node: Node2D, distance: float = 60.0) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false
	return player.global_position.distance_to(node.global_position) < distance

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func interact_hoard_object(object_id: String):
	"""Touch a hoard object — called by controller."""
	var sprite = hoard_object_sprites.get(object_id)
	if sprite:
		# Glow effect
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.3)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
		# Float animation
		tween = create_tween()
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.5)
		tween.tween_property(sprite, "position:y", sprite.position.y, 0.5)

func show_ghost_dialogue(ghost_id: int):
	"""Display ghost dialogue — called by controller."""
	var dialogue_label = interior.get_node_or_null("GhostDialogue")
	if dialogue_label:
		dialogue_label.visible = true
		# Fade in
		var tween = create_tween()
		tween.tween_property(dialogue_label, "modulate:a", 1.0, 1.0).from(0.0)

func reveal_true_ending_path():
	"""Reveal the hidden door — called by controller."""
	var door = interior.get_node_or_null("HiddenDoor")
	if door:
		door.visible = true
		var tween = create_tween()
		tween.tween_property(door, "modulate:a", 1.0, 2.0).from(0.0)
	var crack = interior.get_node_or_null("HiddenCrack")
	if crack:
		crack.visible = true
		hidden_crack_visible = true

func mark_aspect_defeated():
	aspect_defeated = true

func mark_choice_made(choice: String):
	choice_made = true
