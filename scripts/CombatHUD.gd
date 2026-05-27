extends CanvasLayer
class_name CombatHUD

# CombatHUD - Main combat interface showing player stats, card hand, and phase info
# Add as CanvasLayer to Combat scene. Connects to GameState signals for live updates.
#
# Layout:
#   Top-Left:    HP bar, Attention meter, Status icons
#   Top-Right:   Quiddity count, Deck count, Floor info
#   Center-Top:  Combat phase banner ("Player Phase" / "Enemy Phase")
#   Bottom:      Card hand display (5 cards visible)
#   Above Hand:  Summon slots (3-4 active summons)

# --- Layout Config ---
const HAND_SIZE := 5
const SUMMON_SLOTS := 4
const CARD_WIDTH := 96
const CARD_HEIGHT := 128
const CARD_SPACING := 8
const STATUS_ICON_SIZE := 24

# --- State ---
var current_hp := 50
var max_hp := 50
var current_attention := 10
var max_attention := 10
var current_quiddity := 0
var deck_count := 0
var is_player_phase := true
var combat_manager: CombatManager = null

# UI Nodes (created in _ready)
var _hp_bar: ProgressBar
var _hp_label: Label
var _attention_bar: ProgressBar
var _attention_label: Label
var _quiddity_label: Label
var _deck_label: Label
var _phase_banner: Label
var _status_container: HBoxContainer
var _hand_container: HBoxContainer
var _summon_container: HBoxContainer
var _summon_slots: Array[PanelContainer] = []
var _hand_cards: Array[Control] = []

# Card data in hand
var _hand_data: Array[CardData] = []
var _selected_card_index := -1

# --- Signals ---
signal card_selected(card_data: CardData, index: int)
signal card_played(card_data: CardData, index: int)
signal summon_slot_clicked(slot_index: int)

func _ready():
	_setup_ui()
	_connect_signals()
	_refresh_all()

func _setup_ui():
	# Root container for all HUD elements
	var root = Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# ===== TOP LEFT: HP + Attention =====
	var left_panel = VBoxContainer.new()
	left_panel.position = Vector2(16, 16)
	left_panel.size = Vector2(240, 120)
	root.add_child(left_panel)
	
	# HP Bar
	var hp_row = HBoxContainer.new()
	left_panel.add_child(hp_row)
	
	var hp_icon = Label.new()
	hp_icon.text = "❤"
	hp_icon.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	hp_row.add_child(hp_icon)
	
	_hp_bar = ProgressBar.new()
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.size = Vector2(160, 20)
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.modulate = Color(0.9, 0.1, 0.1)
	hp_row.add_child(_hp_bar)
	
	_hp_label = Label.new()
	_hp_label.text = "50/50"
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(_hp_label)
	
	# Attention Bar
	var attn_row = HBoxContainer.new()
	left_panel.add_child(attn_row)
	
	var attn_icon = Label.new()
	attn_icon.text = "⚡"
	attn_icon.add_theme_color_override("font_color", Color(0.8, 0.2, 0.8))
	attn_row.add_child(attn_icon)
	
	_attention_bar = ProgressBar.new()
	_attention_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attention_bar.size = Vector2(160, 20)
	_attention_bar.max_value = 10
	_attention_bar.value = 10
	_attention_bar.modulate = Color(0.8, 0.2, 0.8)
	attn_row.add_child(_attention_bar)
	
	_attention_label = Label.new()
	_attention_label.text = "10/10"
	_attention_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	attn_row.add_child(_attention_label)
	
	# Status icons row
	_status_container = HBoxContainer.new()
	_status_container.size = Vector2(240, STATUS_ICON_SIZE)
	left_panel.add_child(_status_container)
	
	# ===== TOP RIGHT: Quiddity + Deck =====
	var right_panel = VBoxContainer.new()
	right_panel.position = Vector2(get_viewport().size.x - 200, 16)
	right_panel.size = Vector2(180, 100)
	right_panel.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(right_panel)
	
	_quiddity_label = Label.new()
	_quiddity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quiddity_label.add_theme_font_size_override("font_size", 18)
	_quiddity_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
	right_panel.add_child(_quiddity_label)
	
	_deck_label = Label.new()
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_deck_label.add_theme_font_size_override("font_size", 14)
	_deck_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	right_panel.add_child(_deck_label)
	
	# ===== CENTER TOP: Phase Banner =====
	_phase_banner = Label.new()
	_phase_banner.position = Vector2(get_viewport().size.x / 2 - 120, 16)
	_phase_banner.size = Vector2(240, 32)
	_phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_phase_banner.add_theme_font_size_override("font_size", 20)
	_phase_banner.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	root.add_child(_phase_banner)
	
	# ===== BOTTOM: Card Hand =====
	_hand_container = HBoxContainer.new()
	_hand_container.position = Vector2(
		(get_viewport().size.x - (HAND_SIZE * (CARD_WIDTH + CARD_SPACING))) / 2,
		get_viewport().size.y - CARD_HEIGHT - 24
	)
	_hand_container.size = Vector2(HAND_SIZE * (CARD_WIDTH + CARD_SPACING), CARD_HEIGHT)
	_hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(_hand_container)
	
	# Create empty card slots
	for i in range(HAND_SIZE):
		var card_panel = _create_card_slot(i)
		_hand_container.add_child(card_panel)
		_hand_cards.append(card_panel)
	
	# ===== ABOVE HAND: Summon Slots =====
	_summon_container = HBoxContainer.new()
	_summon_container.position = Vector2(
		(get_viewport().size.x - (SUMMON_SLOTS * (CARD_WIDTH + CARD_SPACING))) / 2,
		get_viewport().size.y - CARD_HEIGHT - 80
	)
	_summon_container.size = Vector2(SUMMON_SLOTS * (CARD_WIDTH + CARD_SPACING), 48)
	_summon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(_summon_container)
	
	for i in range(SUMMON_SLOTS):
		var slot = _create_summon_slot(i)
		_summon_container.add_child(slot)
		_summon_slots.append(slot)
	
	# ===== FLEE BUTTON (bottom-left, below hand) =====
	var flee_btn = TextureButton.new()
	flee_btn.name = "FleeButton"
	flee_btn.position = Vector2(20, get_viewport().size.y - 48)
	flee_btn.size = Vector2(32, 32)
	
	var flee_tex = load("res://assets/sprites/ui/ui_icon_flee.png")
	if flee_tex:
		flee_btn.texture_normal = flee_tex
		flee_btn.texture_hover = flee_tex
		flee_btn.texture_pressed = flee_tex
		flee_btn.ignore_texture_size = true
		flee_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		flee_btn.self_modulate = Color(1.0, 0.3, 0.3)  # Red tint
	
	# Hover effect: darken on mouse over
	flee_btn.mouse_entered.connect(func():
		flee_btn.self_modulate = Color(0.7, 0.2, 0.2)  # Darker red
	)
	flee_btn.mouse_exited.connect(func():
		flee_btn.self_modulate = Color(1.0, 0.3, 0.3)  # Normal red
	)
	
	flee_btn.pressed.connect(_on_flee_pressed)
	root.add_child(flee_btn)

func _create_card_slot(index: int) -> PanelContainer:
	"""Create an empty card display slot."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	# Empty state label
	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	panel.add_child(label)
	
	# Hover + click handling
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_on_card_clicked(index)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_on_card_right_clicked(index)
	)
	
	panel.mouse_entered.connect(func():
		_on_card_hover(index, true)
	)
	panel.mouse_exited.connect(func():
		_on_card_hover(index, false)
	)
	
	return panel

func _create_summon_slot(index: int) -> PanelContainer:
	"""Create a summon slot display."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, 48)
	panel.size = Vector2(CARD_WIDTH, 48)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.2, 0.25)
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Empty"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	panel.add_child(label)
	
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			summon_slot_clicked.emit(index)
	)
	
	return panel

# --- Signal Connections ---

func _connect_signals():
	# GameState signals
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.quiddity_changed.connect(_on_quiddity_changed)
	GameState.deck_changed.connect(_on_deck_changed)

func _on_hp_changed(new_hp: int, max_hp_val: int, delta: int):
	current_hp = new_hp
	max_hp = max_hp_val
	_refresh_hp()
	
	# Flash red if damage taken
	if delta < 0:
		_flash_damage_vignette()

func _on_quiddity_changed(new_quiddity: int):
	current_quiddity = new_quiddity
	_refresh_quiddity()

func _on_deck_changed():
	_refresh_deck_count()

# --- Public Update Methods ---

func set_attention(current: int, maximum: int):
	"""Update attention meter (combat resource)."""
	current_attention = current
	max_attention = maximum
	_refresh_attention()

func set_phase(player_phase: bool):
	"""Switch combat phase banner."""
	is_player_phase = player_phase
	_refresh_phase()

func set_hand(cards: Array[CardData]):
	"""Set the visible card hand."""
	_hand_data = cards
	_refresh_hand()

func add_card_to_hand(card: CardData):
	"""Add a card to hand (e.g., card draw)."""
	if _hand_data.size() < HAND_SIZE:
		_hand_data.append(card)
		_refresh_hand()
		AudioManager.play_sfx("card_draw")

func remove_card_from_hand(index: int):
	"""Remove a card from hand (e.g., after playing)."""
	if index >= 0 and index < _hand_data.size():
		_hand_data.remove_at(index)
		_refresh_hand()

func clear_hand():
	"""Clear all cards from hand."""
	_hand_data.clear()
	_refresh_hand()

func set_summon_slot(slot_index: int, name: String, hp: int, max_hp: int, atk: int):
	"""Update a summon slot display."""
	if slot_index >= 0 and slot_index < SUMMON_SLOTS:
		var slot = _summon_slots[slot_index]
		var label = slot.get_child(0) as Label
		if label:
			label.text = "%s\n%d/%d HP | ATK %d" % [name, hp, max_hp, atk]
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func clear_summon_slot(slot_index: int):
	"""Clear a summon slot."""
	if slot_index >= 0 and slot_index < SUMMON_SLOTS:
		var slot = _summon_slots[slot_index]
		var label = slot.get_child(0) as Label
		if label:
			label.text = "Empty"
			label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func add_status_icon(icon_text: String, tooltip: String, color: Color):
	"""Add a status effect icon to the status bar."""
	var icon = Label.new()
	icon.text = icon_text
	icon.tooltip_text = tooltip
	icon.add_theme_color_override("font_color", color)
	icon.add_theme_font_size_override("font_size", 16)
	_status_container.add_child(icon)

func clear_status_icons():
	"""Remove all status effect icons."""
	for child in _status_container.get_children():
		child.queue_free()

# --- Refresh Methods ---

func _refresh_all():
	_refresh_hp()
	_refresh_attention()
	_refresh_quiddity()
	_refresh_deck_count()
	_refresh_phase()
	_refresh_hand()

func _refresh_hp():
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_label.text = "%d/%d" % [current_hp, max_hp]
	
	# Color shift based on HP level
	var ratio = float(current_hp) / max_hp
	if ratio > 0.5:
		_hp_bar.modulate = Color(0.2, 0.8, 0.2)  # Green
	elif ratio > 0.25:
		_hp_bar.modulate = Color(0.9, 0.7, 0.1)  # Yellow
	else:
		_hp_bar.modulate = Color(0.9, 0.1, 0.1)  # Red

func _refresh_attention():
	_attention_bar.max_value = max_attention
	_attention_bar.value = current_attention
	_attention_label.text = "%d/%d" % [current_attention, max_attention]
	
	# Dim if not enough attention for typical card cost
	if current_attention < 2:
		_attention_bar.modulate = Color(0.9, 0.1, 0.1)  # Red warning
	else:
		_attention_bar.modulate = Color(0.8, 0.2, 0.8)  # Normal purple

func _refresh_quiddity():
	_quiddity_label.text = "◆ %d" % current_quiddity

func _refresh_deck_count():
	# Get deck count from GameState
	var count = 0
	if GameState.get("player_deck"):
		count = GameState.player_deck.size()
	deck_count = count
	_deck_label.text = "🃏 %d cards" % deck_count

func _refresh_phase():
	if is_player_phase:
		_phase_banner.text = "◄ PLAYER PHASE ►"
		_phase_banner.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))  # Blue
	else:
		_phase_banner.text = "◄ ENEMY PHASE ►"
		_phase_banner.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Red

func _refresh_hand():
	for i in range(HAND_SIZE):
		var panel = _hand_cards[i]
		var label = panel.get_child(0) as Label
		
		if i < _hand_data.size():
			var card = _hand_data[i]
			label.text = card.card_name
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			
			# Update border color by faction
			var style = panel.get_theme_stylebox("panel").duplicate()
			style.border_color = _get_faction_color(card.faction)
			panel.add_theme_stylebox_override("panel", style)
			
			# Dim if unplayable (not enough attention)
			if card.attention_cost > current_attention:
				panel.modulate = Color(0.5, 0.5, 0.5, 0.5)
			else:
				panel.modulate = Color.WHITE
		else:
			label.text = ""
			var empty_style = panel.get_theme_stylebox("panel").duplicate()
			empty_style.border_color = Color(0.3, 0.3, 0.35)
			panel.add_theme_stylebox_override("panel", empty_style)
			panel.modulate = Color.WHITE

func _get_faction_color(faction: String) -> Color:
	match faction.to_lower():
		"construct": return Color(0.8, 0.6, 0.2)   # Brass/Gold
		"goblin": return Color(0.2, 0.7, 0.2)     # Green
		"undead": return Color(0.4, 0.4, 0.4)     # Grey
		"elemental": return Color(0.2, 0.5, 0.9)  # Blue
		"demon": return Color(0.9, 0.2, 0.2)      # Red
		"aberration": return Color(0.6, 0.2, 0.8) # Purple
		"dragon": return Color(1.0, 0.6, 0.0)     # Orange
		"universal": return Color(0.7, 0.7, 0.7)  # Silver
		_: return Color(0.5, 0.5, 0.5)

# --- Interaction Handlers ---

func _on_card_clicked(index: int):
	if index >= _hand_data.size():
		return
	
	var card = _hand_data[index]
	
	# Check if playable
	if card.attention_cost > current_attention:
		AudioManager.play_sfx("cant_play")
		return
	
	_selected_card_index = index
	card_selected.emit(card, index)
	
	# Visual feedback
	var panel = _hand_cards[index]
	var tween = create_tween()
	tween.tween_property(panel, "position:y", -8, 0.1)
	tween.chain().tween_property(panel, "position:y", 0, 0.1)

func _on_card_right_clicked(index: int):
	"""Show card details (could open tooltip/modal)."""
	if index < _hand_data.size():
		# TODO: Show card tooltip with full stats
		pass

func _on_card_hover(index: int, hovering: bool):
	if index >= _hand_data.size():
		return
	
	var panel = _hand_cards[index]
	if hovering:
		# Lift card slightly
		panel.position.y = -4
		AudioManager.play_sfx("card_hover")
	else:
		panel.position.y = 0

func play_card(index: int) -> bool:
	"""Play a card from hand. Returns true if successful."""
	if index < 0 or index >= _hand_data.size():
		return false
	
	var card = _hand_data[index]
	
	if card.attention_cost > current_attention:
		return false
	
	# Deduct attention
	current_attention -= card.attention_cost
	_refresh_attention()
	
	# Remove from hand
	_hand_data.remove_at(index)
	_refresh_hand()
	
	AudioManager.play_sfx("card_play")
	card_played.emit(card, index)
	
	return true

# --- Visual Effects ---

func _flash_damage_vignette():
	"""Flash red vignette when taking damage."""
	var vignette = ColorRect.new()
	vignette.color = Color(0.9, 0.1, 0.1, 0.3)
	vignette.size = get_viewport().size
	add_child(vignette)
	
	var tween = create_tween()
	tween.tween_property(vignette, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): vignette.queue_free())

func show_damage_number(amount: int, position: Vector2):
	"""Show floating damage text at world position."""
	FloatingText.spawn_damage(self, position, amount)

func show_heal_number(amount: int, position: Vector2):
	"""Show floating heal text."""
	FloatingText.spawn_heal(self, position, amount)

func show_shield_number(amount: int, position: Vector2):
	"""Show floating shield text."""
	FloatingText.spawn_shield(self, position, amount)

func _on_flee_pressed():
	"""Player pressed FLEE button."""
	if combat_manager:
		var success = combat_manager.flee_combat()
		if success:
			_show_notification("⚡ FLED! No Aggro active — RUN!", Color(0.9, 0.5, 0.2))
		else:
			_show_notification("Cannot flee right now!", Color(0.7, 0.7, 0.7))
