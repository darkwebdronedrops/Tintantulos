extends CanvasLayer
class_name OverworldHUD

# OverworldHUD — Persistent overlay showing player status in The Gearworks
# Top-left: HP bar, gems, deck, offerings
# Top-right: Rooms cleared / 12, Crown Cog status
# Bottom: Context messages (transient)

# References
var hp_bar_bg: ColorRect
var hp_bar_fg: ColorRect
var hp_label: Label
var gem_label: Label
var deck_label: Label
var offering_label: Label
var quiddity_label: Label
var rooms_label: Label
var crown_label: Label
var message_label: Label

# Styling
const BAR_WIDTH: float = 200.0
const BAR_HEIGHT: float = 18.0
const PANEL_PADDING: float = 12.0
const CORNER_OFFSET: Vector2 = Vector2(16, 16)

# Sprite paths
const PANEL_SPRITE = "res://assets/sprites/ui_env/ui_hud_panel.png"
const BAR_FRAME_SPRITE = "res://assets/sprites/ui_env/ui_bar_frame.png"

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	_build_hud()
	_update_all()
	
	# Connect to GameState signals
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.gems_changed.connect(_on_gems_changed)
	GameState.offerings_changed.connect(_on_offerings_changed)
	GameState.quiddity_changed.connect(_on_quiddity_changed)
	GameState.deck_changed.connect(_on_deck_changed)

func _process(_delta):
	_update_all()

func _build_hud():
	# Main container — fills viewport, no interaction blocking
	var container = Control.new()
	container.name = "HUDContainer"
	container.size = Vector2(1920, 1080)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# === TOP LEFT: Core Stats ===
	var left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.position = CORNER_OFFSET
	left_panel.custom_minimum_size = Vector2(280, 160)
	container.add_child(left_panel)
	
	# Add brass panel sprite as background
	if ResourceLoader.exists(PANEL_SPRITE):
		var bg_sprite = Sprite2D.new()
		bg_sprite.texture = load(PANEL_SPRITE)
		bg_sprite.scale = Vector2(280.0 / bg_sprite.texture.get_size().x, 160.0 / bg_sprite.texture.get_size().y)
		bg_sprite.centered = false
		left_panel.add_child(bg_sprite)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_vbox.position = Vector2(12, 10)
	left_vbox.size = Vector2(250, 140)
	left_panel.add_child(left_vbox)
	
	# HP Bar with frame sprite
	var hp_row = _create_bar_container("HP", Color(0.3, 0.9, 0.3), BAR_WIDTH, BAR_HEIGHT)
	left_vbox.add_child(hp_row)
	# Store references to bar elements for updates
	var bar_container = hp_row.get_child(1)  # Index 1 is the bar_container Control
	hp_bar_bg = bar_container.get_node_or_null("BarBG")
	hp_bar_fg = bar_container.get_node_or_null("BarFG")
	hp_label = hp_row.get_node_or_null("ValueLabel")
	
	# Gems
	gem_label = _create_stat_label("💎 Gems: 0")
	left_vbox.add_child(gem_label)
	
	# Quiddity
	quiddity_label = _create_stat_label("◈ Quiddity: 0")
	left_vbox.add_child(quiddity_label)
	
	# Deck
	deck_label = _create_stat_label("🃏 Deck: 0/50")
	left_vbox.add_child(deck_label)
	
	# Offerings
	offering_label = _create_stat_label("🎁 Offerings: 0/10")
	left_vbox.add_child(offering_label)
	
	# === TOP RIGHT: Progress ===
	var right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.position = Vector2(1620, CORNER_OFFSET.y)
	right_panel.custom_minimum_size = Vector2(280, 110)
	container.add_child(right_panel)
	
	# Add brass panel sprite as background
	if ResourceLoader.exists(PANEL_SPRITE):
		var bg_sprite = Sprite2D.new()
		bg_sprite.texture = load(PANEL_SPRITE)
		bg_sprite.scale = Vector2(280.0 / bg_sprite.texture.get_size().x, 110.0 / bg_sprite.texture.get_size().y)
		bg_sprite.centered = false
		right_panel.add_child(bg_sprite)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	right_vbox.position = Vector2(12, 10)
	right_vbox.size = Vector2(250, 90)
	right_panel.add_child(right_vbox)
	
	# Rooms cleared
	rooms_label = _create_stat_label("🏠 Rooms: 0/12")
	right_vbox.add_child(rooms_label)
	
	# Crown Cog status
	crown_label = _create_stat_label("👑 Crown Cog: LOCKED")
	crown_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))
	right_vbox.add_child(crown_label)
	
	# Dial position
	var dial_label = _create_stat_label("☸ Dial: Position 0")
	dial_label.name = "DialLabel"
	right_vbox.add_child(dial_label)
	
	# === BOTTOM CENTER: Transient Messages ===
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.position = Vector2(560, 980)
	message_label.size = Vector2(800, 30)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8))
	message_label.visible = false
	container.add_child(message_label)
	
	# === BOTTOM LEFT: Controls hint ===
	var controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.position = Vector2(CORNER_OFFSET.x, 1020)
	controls_label.size = Vector2(400, 40)
	controls_label.text = "WEADZX: Move  |  Click: Move/Interact  |  S: Interact  |  R: Rotate Dial  |  ESC: Menu"
	controls_label.add_theme_font_size_override("font_size", 10)
	controls_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	container.add_child(controls_label)

func _create_bar_container(label_text: String, color: Color, width: float, height: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	# Label
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(30, height)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	container.add_child(label)
	
	# Bar container (holds frame + fill)
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(width, height)
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(bar_container)
	
	var bar_fg: ColorRect
	var bar_bg: ColorRect
	
	# Frame sprite background
	if ResourceLoader.exists(BAR_FRAME_SPRITE):
		var frame = Sprite2D.new()
		frame.texture = load(BAR_FRAME_SPRITE)
		frame.scale = Vector2(width / frame.texture.get_size().x, height / frame.texture.get_size().y)
		frame.centered = false
		bar_container.add_child(frame)
		
		# Inner fill (inside the frame)
		bar_fg = ColorRect.new()
		bar_fg.name = "BarFG"
		bar_fg.color = color
		bar_fg.position = Vector2(3, 3)
		bar_fg.size = Vector2(width - 6, height - 6)
		bar_container.add_child(bar_fg)
	else:
		# Fallback: simple colored bar
		bar_bg = ColorRect.new()
		bar_bg.name = "BarBG"
		bar_bg.size = Vector2(width, height)
		bar_bg.color = Color(0.15, 0.15, 0.18)
		bar_container.add_child(bar_bg)
		
		bar_fg = ColorRect.new()
		bar_fg.name = "BarFG"
		bar_fg.size = Vector2(width, height)
		bar_fg.color = color
		bar_container.add_child(bar_fg)
	
	# Value label
	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "50/50"
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	container.add_child(value_label)
	
	return container

func _create_stat_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	return label

# --- Update Methods ---

func _update_all():
	_update_hp()
	_update_gems()
	_update_quiddity()
	_update_deck()
	_update_offerings()
	_update_rooms()
	_update_crown()
	_update_dial()

func _update_hp():
	var hp = GameState.player_hp
	var max_hp = GameState.player_max_hp
	var ratio = float(hp) / float(max_hp) if max_hp > 0 else 0.0
	
	if hp_bar_fg:
		var target_width = max(0, BAR_WIDTH * ratio)
		hp_bar_fg.custom_minimum_size = Vector2(target_width, BAR_HEIGHT)
		# Color shift: green -> yellow -> red
		if ratio > 0.5:
			hp_bar_fg.color = Color(0.3, 0.9, 0.3).lerp(Color(0.9, 0.9, 0.3), (1.0 - ratio) * 2.0)
		else:
			hp_bar_fg.color = Color(0.9, 0.9, 0.3).lerp(Color(0.9, 0.2, 0.2), (0.5 - ratio) * 2.0)
	
	if hp_label:
		hp_label.text = "%d/%d" % [hp, max_hp]
		# Warning color at low HP
		if hp <= max_hp * 0.25:
			hp_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _update_gems():
	if gem_label:
		gem_label.text = "💎 Gems: %d" % GameState.gems

func _update_quiddity():
	if quiddity_label:
		quiddity_label.text = "◈ Quiddity: %d" % GameState.player_quiddity

func _update_deck():
	if deck_label:
		var count = GameState.player_deck.size()
		var max_count = GameState.deck_max_size
		deck_label.text = "🃏 Deck: %d/%d" % [count, max_count]
		if count >= max_count:
			deck_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			deck_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

func _update_offerings():
	if offering_label:
		var count = GameState.inventory_offerings.size()
		offering_label.text = "🎁 Offerings: %d/10" % count
		if count >= 10:
			offering_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			offering_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

func _update_rooms():
	if rooms_label:
		var cleared = GameState.get_cleared_room_count()
		rooms_label.text = "🏠 Rooms: %d/12" % cleared
		if cleared >= 12:
			rooms_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			rooms_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

func _update_crown():
	if crown_label:
		if GameState.crown_cog_unlocked:
			crown_label.text = "👑 Crown Cog: UNLOCKED"
			crown_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		else:
			var aligned = 0
			# Try to get aligned count from light beam puzzle if available
			var f3 = get_tree().get_first_node_in_group("floor3_controller")
			if f3 and f3.light_beam_puzzle:
				aligned = f3.light_beam_puzzle.get_aligned_count()
			crown_label.text = "👑 Crown Cog: %d/11 beams" % aligned
			crown_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))

func _update_dial():
	var dial_label = get_node_or_null("HUDContainer/RightPanel/DialLabel")
	if dial_label:
		dial_label.text = "☸ Dial: Position %d" % GameState.dial_position

# --- Public Methods ---

func show_message(text: String, duration: float = 3.0, color: Color = Color(0.9, 0.9, 0.8)):
	"""Show a transient message at bottom center"""
	if message_label:
		message_label.text = text
		message_label.modulate = color
		message_label.visible = true
		
		# Clear after duration
		await get_tree().create_timer(duration).timeout
		if message_label:
			message_label.visible = false

func show_damage_flash():
	"""Flash the screen red briefly when taking damage"""
	var flash = ColorRect.new()
	flash.color = Color(0.9, 0.1, 0.1, 0.3)
	flash.size = Vector2(1920, 1080)
	flash.position = Vector2.ZERO
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func pulse_hp_bar():
	"""Pulse the HP bar when healing"""
	if hp_bar_fg and is_instance_valid(hp_bar_fg):
		var tween = create_tween()
		tween.tween_property(hp_bar_fg, "modulate", Color(1.5, 1.5, 1.5), 0.2)
		tween.tween_property(hp_bar_fg, "modulate", Color(1.0, 1.0, 1.0), 0.3)

# --- Signal Handlers ---

func _on_hp_changed(new_hp: int, max_hp: int, delta: int):
	_update_hp()
	if delta < 0:
		show_damage_flash()
	elif delta > 0:
		pulse_hp_bar()

func _on_gems_changed(new_amount: int):
	_update_gems()

func _on_offerings_changed():
	_update_offerings()

func _on_quiddity_changed(new_amount: int):
	_update_quiddity()

func _on_deck_changed():
	_update_deck()
