extends CanvasLayer
class_name CombatUI

# CombatUI — Scaled for 1280x720 viewport

@onready var combat_manager: CombatManager

var hand_container: HBoxContainer
var enemy_container: HBoxContainer
var player_panel: NinePatchRect
var attention_bar: TextureProgressBar
var attention_state_label: Label
var attention_value_label: Label
var end_turn_btn: Button
var stake_btn: Button
var weapon_use_btn: Button
var shield_icon: TextureRect
var shield_label: Label
var hp_bar: ProgressBar
var hp_text_label: Label
var quiddity_icon: TextureRect
var quiddity_label: Label
var deck_icon: TextureRect
var deck_count_label: Label

var potion_container: HBoxContainer
var potion_slots: Array[TextureButton] = []

var equip_panel: PanelContainer
var equip_slots: Array[TextureRect] = []

var card_play_effect: CardPlayEffect
var mist_overlay: ColorRect
var card_preview: TextureRect  # Large card preview on hover

var selected_card_index: int = -1

# Scale for 1280x720 (from 1920x1080 design)
const S: float = 0.67

func _ready():
	visible = false

func setup(cm: CombatManager):
	combat_manager = cm
	
	# Only connect if not already connected (idempotent for multiple setup calls)
	if not combat_manager.combat_started.is_connected(_on_combat_started):
		combat_manager.combat_started.connect(_on_combat_started)
	if not combat_manager.combat_ended.is_connected(_on_combat_ended):
		combat_manager.combat_ended.connect(_on_combat_ended)
	if not combat_manager.turn_started.is_connected(_on_turn_started):
		combat_manager.turn_started.connect(_on_turn_started)
	if not combat_manager.player_damaged.is_connected(_update_player_display):
		combat_manager.player_damaged.connect(_update_player_display)
	if not combat_manager.enemy_damaged.is_connected(_update_enemy_display):
		combat_manager.enemy_damaged.connect(_update_enemy_display)
	if not combat_manager.card_drawn.is_connected(_on_card_drawn):
		combat_manager.card_drawn.connect(_on_card_drawn)
	if not combat_manager.card_played.is_connected(_on_card_played):
		combat_manager.card_played.connect(_on_card_played)
	if not combat_manager.attention_changed.is_connected(_update_attention_display):
		combat_manager.attention_changed.connect(_update_attention_display)
	
	_create_ui()

func _create_ui():
	# =====================================================================
	# STANDARDIZED COMBAT UI — Fixed positions for 1280×720 viewport
	# =====================================================================
	# Layout zones:
	#   Player Panel : (10, 10)    size (200, 300)
	#   Enemy Area   : (220, 10)   size (830, 130)
	#   Hand Area    : (220, 560)  size (830, 120)
	#   Equip Panel  : (1070, 10)  size (110, 300)
	# =====================================================================
	
	# Semi-transparent background — shows hex battlefield behind combat
	var existing_bg = get_node_or_null("CombatBG")
	if existing_bg:
		existing_bg.queue_free()
	
	var bg = ColorRect.new()
	bg.name = "CombatBG"
	bg.color = Color(0.02, 0.02, 0.04, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.z_index = -1
	add_child(bg)
	
	# --- PLAYER PANEL (left, 200×300) ---
	player_panel = NinePatchRect.new()
	player_panel.name = "PlayerPanel"
	player_panel.position = Vector2(10, 10)
	player_panel.size = Vector2(200, 300)
	# Skip decorative texture — use solid bg instead
	add_child(player_panel)
	
	var player_bg = ColorRect.new()
	player_bg.color = Color(0.08, 0.08, 0.12, 0.9)
	player_bg.anchor_right = 1.0
	player_bg.anchor_bottom = 1.0
	player_panel.add_child(player_bg)
	player_panel.move_child(player_bg, 0)
	
	# HP bar (y=8, height=20) — plain ProgressBar, no oversized texture_over
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(8, 8)
	hp_bar.size = Vector2(184, 20)
	hp_bar.min_value = 0; hp_bar.max_value = 100; hp_bar.value = 100
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.2, 0.8, 0.2)
	hp_style.corner_radius_top_left = 3
	hp_style.corner_radius_top_right = 3
	hp_style.corner_radius_bottom_left = 3
	hp_style.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", hp_style)
	var hp_bg_style = StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0.15, 0.15, 0.15)
	hp_bg_style.corner_radius_top_left = 3
	hp_bg_style.corner_radius_top_right = 3
	hp_bg_style.corner_radius_bottom_left = 3
	hp_bg_style.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", hp_bg_style)
	player_panel.add_child(hp_bar)
	
	hp_text_label = Label.new()
	hp_text_label.name = "HPText"
	hp_text_label.position = Vector2(8, 8)
	hp_text_label.size = Vector2(184, 20)
	hp_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(hp_text_label)
	
	# Shield (y=32)
	shield_icon = TextureRect.new()
	shield_icon.name = "ShieldIcon"
	shield_icon.position = Vector2(8, 32)
	shield_icon.size = Vector2(20, 20)
	shield_icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var shield_tex = load("res://assets/sprites/ui/ui_shield_icon.png")
	if shield_tex: shield_icon.texture = shield_tex
	player_panel.add_child(shield_icon)
	
	shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	shield_label.position = Vector2(32, 32)
	shield_label.size = Vector2(160, 20)
	shield_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85))
	player_panel.add_child(shield_label)
	
	# Attention state (y=58)
	attention_state_label = Label.new()
	attention_state_label.name = "AttentionState"
	attention_state_label.position = Vector2(4, 58)
	attention_state_label.size = Vector2(192, 20)
	attention_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(attention_state_label)
	
	attention_value_label = Label.new()
	attention_value_label.name = "AttentionValue"
	attention_value_label.position = Vector2(4, 80)
	attention_value_label.size = Vector2(192, 18)
	attention_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(attention_value_label)
	
	attention_bar = ProgressBar.new()
	attention_bar.name = "AttentionBar"
	attention_bar.position = Vector2(4, 100)
	attention_bar.size = Vector2(192, 18)
	attention_bar.min_value = 0; attention_bar.max_value = 20
	var attn_fill_style = StyleBoxFlat.new()
	attn_fill_style.bg_color = Color(0.8, 0.2, 0.8)
	attn_fill_style.corner_radius_top_left = 3
	attn_fill_style.corner_radius_top_right = 3
	attn_fill_style.corner_radius_bottom_left = 3
	attn_fill_style.corner_radius_bottom_right = 3
	attention_bar.add_theme_stylebox_override("fill", attn_fill_style)
	var attn_bg_style = StyleBoxFlat.new()
	attn_bg_style.bg_color = Color(0.15, 0.15, 0.15)
	attn_bg_style.corner_radius_top_left = 3
	attn_bg_style.corner_radius_top_right = 3
	attn_bg_style.corner_radius_bottom_left = 3
	attn_bg_style.corner_radius_bottom_right = 3
	attention_bar.add_theme_stylebox_override("background", attn_bg_style)
	player_panel.add_child(attention_bar)
	
	var desc_label = Label.new()
	desc_label.name = "AttentionDesc"
	desc_label.position = Vector2(4, 122)
	desc_label.size = Vector2(192, 36)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	player_panel.add_child(desc_label)
	
	# Quiddity (y=162)
	quiddity_icon = TextureRect.new()
	quiddity_icon.name = "QuiddityIcon"
	quiddity_icon.position = Vector2(8, 162)
	quiddity_icon.size = Vector2(18, 18)
	quiddity_icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	quiddity_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var gem_tex = load("res://assets/sprites/ui/ui_gem_quiddity.png")
	if gem_tex: quiddity_icon.texture = gem_tex
	player_panel.add_child(quiddity_icon)
	
	quiddity_label = Label.new()
	quiddity_label.name = "QuiddityLabel"
	quiddity_label.position = Vector2(30, 162)
	quiddity_label.size = Vector2(162, 18)
	quiddity_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	player_panel.add_child(quiddity_label)
	
	# Deck count (y=186)
	deck_count_label = Label.new()
	deck_count_label.name = "DeckCount"
	deck_count_label.position = Vector2(8, 186)
	deck_count_label.size = Vector2(184, 20)
	deck_count_label.text = "Deck: 0"
	player_panel.add_child(deck_count_label)
	
	# End Turn button (y=216) — plain button, no oversized texture
	end_turn_btn = Button.new()
	end_turn_btn.name = "EndTurnBtn"
	end_turn_btn.position = Vector2(8, 216)
	end_turn_btn.size = Vector2(90, 32)
	end_turn_btn.text = "End Turn (T)"
	end_turn_btn.pressed.connect(_on_end_turn)
	player_panel.add_child(end_turn_btn)
	
	# Stake button (y=216, to the right) — plain button
	stake_btn = Button.new()
	stake_btn.name = "StakeBtn"
	stake_btn.position = Vector2(104, 216)
	stake_btn.size = Vector2(90, 32)
	stake_btn.text = "Stake 0"
	stake_btn.pressed.connect(_on_stake)
	player_panel.add_child(stake_btn)
	
	# --- ENEMY CONTAINER (top center, 830×130) ---
	enemy_container = HBoxContainer.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.position = Vector2(220, 10)
	enemy_container.size = Vector2(830, 130)
	enemy_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	enemy_container.add_theme_constant_override("separation", 40)
	add_child(enemy_container)
	
	# --- HAND CONTAINER (bottom center, 830×120) ---
	hand_container = HBoxContainer.new()
	hand_container.name = "HandContainer"
	hand_container.position = Vector2(220, 560)
	hand_container.size = Vector2(830, 120)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", 10)
	add_child(hand_container)
	
	# --- EQUIP PANEL (right, 110×300) ---
	equip_panel = PanelContainer.new()
	equip_panel.name = "EquipPanel"
	equip_panel.position = Vector2(1070, 10)
	equip_panel.size = Vector2(110, 300)
	add_child(equip_panel)
	
	var equip_bg_style = StyleBoxFlat.new()
	equip_bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	equip_bg_style.corner_radius_top_left = 4
	equip_bg_style.corner_radius_top_right = 4
	equip_bg_style.corner_radius_bottom_left = 4
	equip_bg_style.corner_radius_bottom_right = 4
	equip_panel.add_theme_stylebox_override("panel", equip_bg_style)
	
	var equip_vbox = VBoxContainer.new()
	equip_vbox.add_theme_constant_override("separation", 4)
	equip_panel.add_child(equip_vbox)
	
	var equip_title = Label.new()
	equip_title.text = "GEAR"
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_title.add_theme_font_size_override("font_size", 14)
	equip_vbox.add_child(equip_title)
	
	var equip_types = ["weapon", "armor", "trinket", "shield"]
	var equip_icons = [
		"res://assets/sprites/ui/ui_equip_weapon.png",
		"res://assets/sprites/ui/ui_equip_armor.png",
		"res://assets/sprites/ui/ui_equip_trinket.png",
		"res://assets/sprites/ui/ui_equip_shield.png"
	]
	for i in range(4):
		var slot_hbox = HBoxContainer.new()
		slot_hbox.add_theme_constant_override("separation", 4)
		slot_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var slot = TextureRect.new()
		slot.name = "Equip_%s" % equip_types[i]
		slot.custom_minimum_size = Vector2(48, 48)
		slot.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var slot_tex = load("res://assets/sprites/ui/ui_equip_slot.png")
		if slot_tex: slot.texture = slot_tex
		
		var item = TextureRect.new()
		item.name = "Item"
		item.custom_minimum_size = Vector2(32, 32)
		item.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var item_tex = load(equip_icons[i])
		if item_tex: item.texture = item_tex
		slot.add_child(item)
		slot_hbox.add_child(slot)
		equip_vbox.add_child(slot_hbox)
		equip_slots.append(slot)
	
	var weapon_btn_hbox = HBoxContainer.new()
	weapon_btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_use_btn = Button.new()
	weapon_use_btn.name = "WeaponUseBtn"
	weapon_use_btn.custom_minimum_size = Vector2(48, 20)
	weapon_use_btn.text = "Atk"
	weapon_use_btn.disabled = true
	weapon_use_btn.tooltip_text = "Weapon not charged"
	weapon_use_btn.pressed.connect(_on_weapon_use)
	weapon_btn_hbox.add_child(weapon_use_btn)
	equip_vbox.add_child(weapon_btn_hbox)
	
	# --- MIST OVERLAY (full screen effect) ---
	mist_overlay = ColorRect.new()
	mist_overlay.name = "MistOverlay"
	mist_overlay.anchor_right = 1.0
	mist_overlay.anchor_bottom = 1.0
	mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist_overlay.visible = false
	var mist_material = ShaderMaterial.new()
	var mist_shader = load("res://assets/shaders/card_mist.gdshader")
	if mist_shader: mist_material.shader = mist_shader
	mist_overlay.material = mist_material
	add_child(mist_overlay)
	
	card_play_effect = CardPlayEffect.new()
	card_play_effect.name = "CardPlayEffect"
	card_play_effect.effect_rect = mist_overlay
	add_child(card_play_effect)
	
	# Card preview (large, shows on hover) — sized to fit within 1280x720 viewport
	card_preview = TextureRect.new()
	card_preview.name = "CardPreview"
	card_preview.size = Vector2(180, 250)
	card_preview.position = Vector2(550, 160)
	card_preview.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	card_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_preview.visible = false
	card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_preview)

func _get_attention_color(state: CombatManager.AttentionState) -> Color:
	match state:
		CombatManager.AttentionState.WHISPER: return Color(0.72, 0.53, 0.04)
		CombatManager.AttentionState.BORROWED: return Color(1.0, 0.84, 0.0)
		CombatManager.AttentionState.UNDEFINED: return Color(1.0, 1.0, 0.0)
		CombatManager.AttentionState.SCREAM: return Color(0.0, 1.0, 1.0)
	return Color(0.5, 0.5, 0.5)

func _get_attention_description(state: CombatManager.AttentionState) -> String:
	match state:
		CombatManager.AttentionState.WHISPER: return "Min damage. Safe but slow."
		CombatManager.AttentionState.BORROWED: return "Average damage. Risk threshold."
		CombatManager.AttentionState.UNDEFINED: return "Max damage taken. Vulnerable."
		CombatManager.AttentionState.SCREAM: return "Max damage dealt. Enemies too."
	return ""

func _on_combat_started():
	visible = true
	_update_player_display(0)
	_update_attention_display(0, 20)
	_update_quiddity_display(0)
	_update_deck_count()
	_create_enemy_displays()
	_update_hand_display()
	_update_weapon_button()
	selected_card_index = -1

func _on_combat_ended(victory: bool):
	var msg = Label.new()
	msg.text = "VICTORY!" if victory else "DEFEAT..."
	msg.position = Vector2(540, 300)
	msg.size = Vector2(200, 60)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 48)
	msg.modulate = Color(0.3, 0.9, 0.3) if victory else Color(0.9, 0.3, 0.3)
	add_child(msg)
	await get_tree().create_timer(2.5).timeout
	visible = false
	msg.queue_free()
	for child in hand_container.get_children(): child.queue_free()
	for child in enemy_container.get_children(): child.queue_free()

func _on_turn_started(is_player: bool):
	end_turn_btn.disabled = not is_player
	_update_weapon_button()
	# Reset stake display at turn start
	if stake_btn:
		stake_btn.text = "Stake 0"
	if combat_manager:
		_update_quiddity_display(combat_manager.player_quiddity)

func _on_card_drawn(_card: CardData):
	_update_hand_display()
	_update_deck_count()

func _on_end_turn():
	if combat_manager and combat_manager.is_player_turn:
		AudioManager.play_sfx("end_turn")
		combat_manager.end_player_turn()
		selected_card_index = -1
		_update_hand_display()

func _on_stake():
	if not combat_manager or not combat_manager.is_player_turn:
		return
	var new_stake = (combat_manager.current_stake + 1) % 6
	combat_manager.set_stake(new_stake)
	var stake_label = stake_btn.get_node_or_null("StakeLabel")
	if stake_label: stake_label.text = "Stake %d" % new_stake
	_update_quiddity_display(combat_manager.player_quiddity)

func _on_weapon_use():
	if not combat_manager.is_player_turn: return
	var target = 0
	for i in range(combat_manager.enemies.size()):
		if combat_manager.enemies[i].hp > 0:
			target = i
			break
	if combat_manager.use_weapon(target):
		_update_enemy_buttons()
		_update_weapon_button()

func _on_card_played(card: CardData):
	_update_hand_display()
	_update_player_display(0)
	selected_card_index = -1
	_update_deck_count()
	if card_play_effect and card:
		card_play_effect.trigger_effect(card.faction)

func _update_player_display(_amount: int = 0):
	var hp_percent = float(combat_manager.player_hp) / combat_manager.player_max_hp
	hp_bar.value = hp_percent * 100
	hp_text_label.text = "%d / %d" % [combat_manager.player_hp, combat_manager.player_max_hp]
	shield_label.text = "Shield: %d" % combat_manager.player_shield

func _update_attention_display(current: int, maximum: int):
	attention_bar.value = current
	attention_value_label.text = "Attention: %d / %d" % [current, maximum]
	var state = combat_manager.current_attention_state
	var color = _get_attention_color(state)
	var state_name = combat_manager._get_attention_state_name()
	attention_state_label.text = state_name
	attention_state_label.modulate = color
	attention_bar.modulate = color
	var desc_label = player_panel.get_node_or_null("AttentionDesc")
	if desc_label: desc_label.text = _get_attention_description(state)
	attention_value_label.modulate = Color(1, 0.3, 0.3) if current >= 18 else Color(1, 1, 1)

func _update_quiddity_display(amount: int):
	quiddity_label.text = "Quiddity: %d" % amount

func _update_deck_count():
	if deck_count_label:
		var count = combat_manager.player_deck.size() if combat_manager.get("player_deck") else 0
		deck_count_label.text = "Deck: %d" % count

func _create_enemy_displays():
	for child in enemy_container.get_children(): child.queue_free()
	for i in range(combat_manager.enemies.size()):
		var panel = _create_enemy_panel(combat_manager.enemies[i], i)
		enemy_container.add_child(panel)

func _create_enemy_panel(enemy, index: int) -> Control:
	var s = S
	var panel = PanelContainer.new()
	panel.name = "Enemy_%d" % index
	panel.custom_minimum_size = Vector2(160, 130) * s
	
	var panel_bg_style = StyleBoxFlat.new()
	panel_bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	panel_bg_style.corner_radius_top_left = 4
	panel_bg_style.corner_radius_top_right = 4
	panel_bg_style.corner_radius_bottom_left = 4
	panel_bg_style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", panel_bg_style)
	
	var sprite = TextureRect.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(50, 8) * s
	sprite.size = Vector2(60, 60) * s
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if enemy.sprite_texture_path != "" and ResourceLoader.exists(enemy.sprite_texture_path):
		var tex = load(enemy.sprite_texture_path)
		if tex: sprite.texture = tex
	else:
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(_get_faction_color(enemy.faction))
		for x in range(64):
			for y in range(64):
				var dx = x - 32; var dy = y - 32
				if dx * dx + dy * dy > 900: img.set_pixel(x, y, Color(0, 0, 0, 0))
		sprite.texture = ImageTexture.create_from_image(img)
	panel.add_child(sprite)
	
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.text = enemy.enemy_name
	name_label.position = Vector2(5, 70) * s
	name_label.size = Vector2(150, 18) * s
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(name_label)
	
	var enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.name = "HPFill"
	enemy_hp_bar.position = Vector2(5, 90) * s
	enemy_hp_bar.size = Vector2(150, 12) * s
	enemy_hp_bar.min_value = 0; enemy_hp_bar.max_value = 100; enemy_hp_bar.value = 100
	var ehp_fill = StyleBoxFlat.new()
	ehp_fill.bg_color = Color(0.2, 0.8, 0.2)
	ehp_fill.corner_radius_top_left = 2
	ehp_fill.corner_radius_top_right = 2
	ehp_fill.corner_radius_bottom_left = 2
	ehp_fill.corner_radius_bottom_right = 2
	enemy_hp_bar.add_theme_stylebox_override("fill", ehp_fill)
	var ehp_bg = StyleBoxFlat.new()
	ehp_bg.bg_color = Color(0.15, 0.15, 0.15)
	ehp_bg.corner_radius_top_left = 2
	ehp_bg.corner_radius_top_right = 2
	ehp_bg.corner_radius_bottom_left = 2
	ehp_bg.corner_radius_bottom_right = 2
	enemy_hp_bar.add_theme_stylebox_override("background", ehp_bg)
	panel.add_child(enemy_hp_bar)
	
	var hp_text = Label.new()
	hp_text.name = "HPText"
	hp_text.text = "%d / %d" % [enemy.hp, enemy.max_hp]
	hp_text.position = Vector2(5, 105) * s
	hp_text.size = Vector2(150, 14) * s
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.add_theme_font_size_override("font_size", 10)
	panel.add_child(hp_text)
	
	var target_btn = TextureButton.new()
	target_btn.name = "TargetButton"
	target_btn.anchor_right = 1.0; target_btn.anchor_bottom = 1.0
	target_btn.modulate = Color(1, 1, 1, 0.0)
	var btn_normal = load("res://assets/sprites/ui/ui_target_button.png")
	var btn_pressed = load("res://assets/sprites/ui/ui_target_button_pressed.png")
	if btn_normal and btn_normal is Texture2D:
		target_btn.texture_normal = btn_normal
	if btn_pressed and btn_pressed is Texture2D:
		target_btn.texture_pressed = btn_pressed
	var target_label = Label.new()
	target_label.text = "TARGET"
	target_label.anchor_right = 1.0; target_label.anchor_bottom = 1.0
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_btn.add_child(target_label)
	target_btn.disabled = enemy.hp <= 0
	target_btn.pressed.connect(func(): _on_target_selected(index))
	panel.add_child(target_btn)
	
	return panel

func _update_enemy_display(index: int, _damage: int):
	var panel = enemy_container.get_node_or_null("Enemy_%d" % index)
	if not panel: return
	var enemy = combat_manager.enemies[index]
	var enemy_hp = panel.get_node_or_null("HPFill")
	if enemy_hp:
		var hp_percent = float(enemy.hp) / enemy.max_hp
		enemy_hp.value = hp_percent * 100
	var hp_text = panel.get_node_or_null("HPText")
	if hp_text: hp_text.text = "%d / %d" % [enemy.hp, enemy.max_hp]
	if enemy.hp <= 0:
		panel.modulate = Color(0.4, 0.4, 0.4)
		var btn = panel.get_node_or_null("TargetButton")
		if btn:
			btn.disabled = true
			var btn_label = btn.get_node_or_null("Label")
			if btn_label and btn_label is Label:
				btn_label.text = "DEFEATED"

func _update_weapon_button():
	if not combat_manager or not weapon_use_btn:
		return
	var weapon_ready = combat_manager.equipped_weapon_id != "" and combat_manager.weapon_charge >= combat_manager.weapon_max_charge
	weapon_use_btn.disabled = not weapon_ready
	if weapon_ready:
		weapon_use_btn.tooltip_text = "Weapon ready!"
	else:
		weapon_use_btn.tooltip_text = "Weapon not charged (%d/%d)" % [combat_manager.weapon_charge, combat_manager.weapon_max_charge]

func _update_enemy_buttons():
	for i in range(combat_manager.enemies.size()):
		var panel = enemy_container.get_node_or_null("Enemy_%d" % i)
		if panel:
			var btn = panel.get_node_or_null("TargetButton")
			if btn and combat_manager.enemies[i].hp > 0:
				btn.disabled = false

func _update_hand_display():
	# Only rebuild if hand size changed — prevents destroying hover state
	# when _on_card_drawn fires for each card in a batch, or when
	# _on_card_clicked unnecessarily rebuilds before playing
	if hand_container.get_child_count() == combat_manager.hand.size():
		return
	for child in hand_container.get_children(): child.queue_free()
	for i in range(combat_manager.hand.size()):
		var card = combat_manager.hand[i]
		var card_node = _create_visual_card(card, i)
		hand_container.add_child(card_node)

func _create_visual_card(card: CardData, index: int) -> Control:
	var s = S
	var card_root = Control.new()
	card_root.name = "Card_%d" % index
	card_root.size = Vector2(90, 120) * s
	card_root.custom_minimum_size = Vector2(90, 120) * s
	
	# Build finished card path from card data
	var safe_name = card.card_name.to_lower().replace(" ", "_").replace("'", "")
	var finished_path = "res://assets/sprites/cards/finished/%s/%s.png" % [card.faction, safe_name]
	
	# Check if pre-composited finished card exists
	var finished_tex = load(finished_path)
	if finished_tex:
		# Use finished card (single texture, all text/frame/art baked in)
		var card_rect = TextureRect.new()
		card_rect.name = "FinishedCard"
		card_rect.anchor_right = 1.0; card_rect.anchor_bottom = 1.0
		card_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_rect.texture = finished_tex
		card_root.add_child(card_rect)
		
		# Gold border for survivors (on top of finished card)
		if card.survives_reset:
			var border = TextureRect.new()
			border.name = "GoldBorder"
			border.anchor_right = 1.0; border.anchor_bottom = 1.0
			border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			border.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gold_tex = load("res://assets/sprites/ui/ui_card_gold_border.png")
			if gold_tex: border.texture = gold_tex
			card_root.add_child(border)
			var crown = TextureRect.new()
			crown.name = "CrownIcon"
			crown.position = Vector2(112, 5) * s
			crown.size = Vector2(22, 20) * s
			var crown_tex = load("res://assets/sprites/ui/ui_crown_icon.png")
			if crown_tex: crown.texture = crown_tex
			crown.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_root.add_child(crown)
	else:
		# Fallback: dynamic compositing (broken - frame centers are opaque)
		# Show a colored placeholder with name
		push_warning("No finished card found for %s, using placeholder" % card.card_name)
		var card_bg = ColorRect.new()
		card_bg.name = "CardBG"
		card_bg.anchor_right = 1.0; card_bg.anchor_bottom = 1.0
		card_bg.color = _get_faction_color(card.faction)
		card_root.add_child(card_bg)
		
		var name_label = Label.new()
		name_label.text = card.card_name
		name_label.anchor_right = 1.0; name_label.anchor_bottom = 1.0
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
		card_root.add_child(name_label)
	
	# Click handler (always on top)
	var click_handler = TextureButton.new()
	click_handler.name = "ClickHandler"
	click_handler.anchor_right = 1.0; click_handler.anchor_bottom = 1.0
	click_handler.modulate = Color(1, 1, 1, 0.0)
	click_handler.pressed.connect(func(): _on_card_clicked(index))
	click_handler.mouse_entered.connect(func(): _on_card_hover(index, true))
	click_handler.mouse_exited.connect(func(): _on_card_hover(index, false))
	card_root.add_child(click_handler)
	
	return card_root
func _get_faction_color(faction: String) -> Color:
	match faction:
		"Construct": return Color(0.7, 0.75, 0.8)
		"Goblin": return Color(0.5, 0.75, 0.45)
		"Undead": return Color(0.6, 0.55, 0.7)
		"Elemental": return Color(0.9, 0.6, 0.35)
		"Demon": return Color(0.8, 0.35, 0.3)
		"Aberration": return Color(0.7, 0.4, 0.75)
		"Dragon": return Color(0.85, 0.7, 0.35)
		"Universal": return Color(0.75, 0.75, 0.75)
		_: return Color(0.7, 0.7, 0.7)

func _on_card_clicked(index: int):
	selected_card_index = index
	# Don't rebuild here — _on_card_played will handle it after the card is removed
	for i in range(combat_manager.enemies.size()):
		if combat_manager.enemies[i].hp > 0:
			combat_manager.play_card(index, i)
			return

func _on_card_hover(index: int, is_hovering: bool):
	# Visual feedback for card hover
	var card_root = hand_container.get_node_or_null("Card_%d" % index)
	if card_root:
		if is_hovering:
			card_root.scale = Vector2(1.1, 1.1)
			# Show large preview
			if combat_manager and index >= 0 and index < combat_manager.hand.size():
				var card = combat_manager.hand[index]
				var safe_name = card.card_name.to_lower().replace(" ", "_").replace("'", "")
				var finished_path = "res://assets/sprites/cards/finished/%s/%s.png" % [card.faction, safe_name]
				var finished_tex = load(finished_path)
				if finished_tex:
					card_preview.texture = finished_tex
					card_preview.visible = true
				else:
					card_preview.visible = false
		else:
			card_root.scale = Vector2(1.0, 1.0)
			card_preview.visible = false

func _on_target_selected(enemy_index: int):
	AudioManager.play_sfx("target_select")
	if selected_card_index >= 0 and selected_card_index < combat_manager.hand.size():
		combat_manager.play_card(selected_card_index, enemy_index)
		selected_card_index = -1
		_update_hand_display()

func _input(event: InputEvent):
	if not visible: return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			_on_end_turn()
