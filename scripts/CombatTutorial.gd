extends Node
class_name CombatTutorial

# ===================================================================
# COMBAT TUTORIAL — First-combat-only contextual hints
# ===================================================================
# Instantiated by floor controller during first combat.
# Shows non-intrusive hints that fade in/out.
# Self-destructs after combat ends.
# ===================================================================

var hint_queue: Array[Dictionary] = []
var current_hint: Control = null
var is_showing_hint: bool = false

# Hint trigger tracking
var has_shown_combat_start: bool = false
var has_shown_cards: bool = false
var has_shown_attention_zero: bool = false
var has_shown_enemy_attack: bool = false
var has_shown_damage: bool = false

func _ready():
	# Connect to combat manager signals if available
	var cm = _find_combat_manager()
	if cm:
		cm.combat_started.connect(_on_combat_started)
		cm.turn_started.connect(_on_turn_started)
		cm.player_damaged.connect(_on_player_damaged)
		cm.combat_ended.connect(_on_combat_ended)
		cm.card_played.connect(_on_card_played)

func _find_combat_manager() -> CombatManager:
	# Try to find combat manager in the scene
	var parent = get_parent()
	if parent:
		var cm = parent.get_node_or_null("CombatManager")
		if cm: return cm
		# Try sibling
		cm = parent.get_parent().get_node_or_null("CombatManager") if parent.get_parent() else null
		if cm: return cm
	return null

func _on_combat_started(_enemies: Array):
	if not has_shown_combat_start:
		has_shown_combat_start = true
		_show_hint("Combat begins! It's your turn.", Vector2(540, 200), 4.0)

func _on_turn_started(is_player_turn: bool):
	if is_player_turn and not has_shown_cards:
		has_shown_cards = true
		_show_hint("These are your cards. Each costs Attention to play.", Vector2(540, 520), 5.0)
	
	# Door tutorial: detect when player ends turn (enemy turn starts)
	if door_tutorial_active and not is_player_turn and door_tutorial_step >= 2:
		on_end_turn_pressed()

func _on_player_damaged(damage: int, _shield_absorbed: int):
	if not has_shown_damage:
		has_shown_damage = true
		_show_hint("You took damage! Shield absorbs damage before HP.", Vector2(540, 300), 4.0)

func _on_card_played(card: CardData):
	on_card_played(card.name)

func _on_combat_ended(_victory: bool):
	if GameState.has_seen_combat_tutorial:
		return
	GameState.has_seen_combat_tutorial = true
	GameState.save_game()
	_show_hint("Victory! You earned gems and cards. Keep climbing!", Vector2(540, 250), 4.0)
	# Self-destruct after a delay
	await get_tree().create_timer(5.0).timeout
	queue_free()

# -------------------------------------------------------------------
# Public: Check attention and show hint
# -------------------------------------------------------------------
func check_attention(current_attention: int, max_attention: int):
	if current_attention <= 0 and not has_shown_attention_zero:
		has_shown_attention_zero = true
		_show_hint("Out of Attention! Press [Space] or click End Turn.", Vector2(540, 520), 4.0)

# -------------------------------------------------------------------
# Public: Show enemy attack hint
# -------------------------------------------------------------------
func on_enemy_attack():
	if not has_shown_enemy_attack:
		has_shown_enemy_attack = true
		_show_hint("Enemy attacks! Use Shield cards to protect yourself.", Vector2(540, 300), 4.0)

# -------------------------------------------------------------------
# Door Tutorial: Scripted hints for the Threshold Door encounter
# -------------------------------------------------------------------
var door_tutorial_active: bool = false
var door_tutorial_step: int = 0
var has_shown_strike_hint: bool = false
var has_shown_block_hint: bool = false
var has_shown_end_turn_hint: bool = false

func start_door_tutorial():
	"""Enable scripted hints for the tutorial Door encounter."""
	door_tutorial_active = true
	door_tutorial_step = 0
	has_shown_strike_hint = false
	has_shown_block_hint = false
	has_shown_end_turn_hint = false
	print("[CombatTutorial] Door tutorial started")
	_show_hint("Combat begins! The Door is vulnerable.\nPlay a Strike to deal damage.", Vector2(540, 200), 5.0)

func on_card_played(card_name: String):
	"""Track card plays for tutorial hints."""
	if not door_tutorial_active:
		return
	
	match card_name.to_lower():
		"strike", "attack":
			if not has_shown_strike_hint:
				has_shown_strike_hint = true
				door_tutorial_step = 1
				_show_hint("Good! The Door braces itself.\nPlay a Block before it attacks.", Vector2(540, 200), 5.0)
		"block", "shield", "defend":
			if not has_shown_block_hint and door_tutorial_step >= 1:
				has_shown_block_hint = true
				door_tutorial_step = 2
				_show_hint("Shield absorbs damage before HP.\nPress [Space] or click End Turn.", Vector2(540, 520), 5.0)

func on_end_turn_pressed():
	"""Track end turn for tutorial hints."""
	if not door_tutorial_active:
		return
	if not has_shown_end_turn_hint and door_tutorial_step >= 2:
		has_shown_end_turn_hint = true
		_show_hint("The Door attacks! Your Shield absorbs the blow.\nNow strike back!", Vector2(540, 200), 4.0)
		door_tutorial_step = 3

# -------------------------------------------------------------------
# Core hint display
# -------------------------------------------------------------------
func _show_hint(text: String, position: Vector2, duration: float = 3.0):
	# Queue if already showing
	if is_showing_hint:
		hint_queue.append({"text": text, "pos": position, "dur": duration})
		return
	
	is_showing_hint = true
	
	# Create hint panel
	var panel = Panel.new()
	panel.name = "HintPanel"
	panel.position = position - Vector2(150, 30)
	panel.size = Vector2(300, 60)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.92)
	style.border_color = Color(0.9, 0.7, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Label
	var label = Label.new()
	label.name = "HintLabel"
	label.text = text
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 10
	label.offset_right = -10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	
	# Z-index high
	panel.z_index = 200
	panel.modulate.a = 0.0
	
	# Add to tree
	if get_parent():
		get_parent().add_child(panel)
	else:
		add_child(panel)
	
	current_hint = panel
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	# Wait duration
	await get_tree().create_timer(duration).timeout
	
	# Fade out
	var tween_out = create_tween()
	tween_out.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	# Remove
	panel.queue_free()
	current_hint = null
	is_showing_hint = false
	
	# Process queue
	if not hint_queue.is_empty():
		var next = hint_queue.pop_front()
		_show_hint(next["text"], next["pos"], next["dur"])
