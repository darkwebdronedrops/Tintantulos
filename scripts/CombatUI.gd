extends CanvasLayer
class_name CombatUI

# CombatUI - Redesigned with textured UI assets
# Replaces all ColorRect nodes with TextureRect/Sprite2D
# Adds: Deck counter, Potion slots, Equipment panel

@onready var combat_manager: CombatManager

# UI nodes
var hand_container: HBoxContainer
var enemy_container: HBoxContainer
var player_panel: NinePatchRect
var attention_bar: TextureProgressBar
var attention_state_label: Label
var attention_value_label: Label
var end_turn_btn: TextureButton
var stake_btn: TextureButton
var weapon_use_btn: TextureButton
var shield_icon: TextureRect
var shield_label: Label
var hp_bar: TextureProgressBar
var hp_text_label: Label
var quiddity_icon: TextureRect
var quiddity_label: Label
var deck_icon: TextureRect
var deck_count_label: Label

# New: Potion slots
var potion_container: HBoxContainer
var potion_slots: Array[TextureButton] = []

# New: Equipment panel
var equip_panel: NinePatchRect
var equip_slots: Array[TextureRect] = []

# Card play mist effect
var card_play_effect: CardPlayEffect
var mist_overlay: ColorRect

var selected_card_index: int = -1

func _ready():
	visible = false

func setup(cm: CombatManager):
	combat_manager = cm
	
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.turn_started.connect(_on_turn_started)
	combat_manager.player_damaged.connect(_update_player_display)
	combat_manager.enemy_damaged.connect(_update_enemy_display)
	combat_manager.card_drawn.connect(_on_card_drawn)
	combat_manager.card_played.connect(_on_card_played)
	combat_manager.attention_changed.connect(_update_attention_display)
	
	_create_ui()

func _create_ui():
	# ============================================
	# PLAYER PANEL (left side) — NinePatchRect with texture
	# ============================================
	player_panel = NinePatchRect.new()
	player_panel.name = "PlayerPanel"
	player_panel.position = Vector2(20, 50)
	player_panel.size = Vector2(300, 440)
	var panel_tex = load("res://assets/sprites/ui/ui_panel_bg.png")
	if panel_tex:
		player_panel.texture = panel_tex
		player_panel.patch_margin_left = 20
		player_panel.patch_margin_right = 20
		player_panel.patch_margin_top = 20
		player_panel.patch_margin_bottom = 20
	add_child(player_panel)
	
	# HP Bar (TextureProgressBar)
	hp_bar = TextureProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.position = Vector2(15, 15)
	hp_bar.size = Vector2(270, 28)
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.nine_patch_stretch = true
	hp_bar.stretch_margin_left = 4
	hp_bar.stretch_margin_right = 4
	var hp_frame = load("res://assets/sprites/ui/ui_hp_bar_frame.png")
	var hp_fill = load("res://assets/sprites/ui/ui_hp_bar_fill.png")
	if hp_frame:
		hp_bar.texture_over = hp_frame
	if hp_fill:
		hp_bar.texture_progress = hp_fill
	player_panel.add_child(hp_bar)
	
	# HP Text
	hp_text_label = Label.new()
	hp_text_label.name = "HPText"
	hp_text_label.position = Vector2(15, 15)
	hp_text_label.size = Vector2(270, 28)
	hp_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text_label.add_theme_font_size_override("font_size", 14)
	player_panel.add_child(hp_text_label)
	
	# Shield Icon + Label
	shield_icon = TextureRect.new()
	shield_icon.name = "ShieldIcon"
	shield_icon.position = Vector2(15, 52)
	shield_icon.size = Vector2(28, 28)
	var shield_tex = load("res://assets/sprites/ui/ui_shield_icon.png")
	if shield_tex:
		shield_icon.texture = shield_tex
	shield_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	player_panel.add_child(shield_icon)
	
	shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	shield_label.position = Vector2(48, 52)
	shield_label.size = Vector2(237, 28)
	shield_label.add_theme_font_size_override("font_size", 16)
	shield_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85))
	player_panel.add_child(shield_label)
	
	# Attention State (WHISPER/BORROWED/UNDEFINED/SCREAM)
	attention_state_label = Label.new()
	attention_state_label.name = "AttentionState"
	attention_state_label.position = Vector2(10, 90)
	attention_state_label.size = Vector2(280, 30)
	attention_state_label.add_theme_font_size_override("font_size", 20)
	attention_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(attention_state_label)
	
	# Attention Value
	attention_value_label = Label.new()
	attention_value_label.name = "AttentionValue"
	attention_value_label.position = Vector2(10, 125)
	attention_value_label.size = Vector2(280, 25)
	attention_value_label.add_theme_font_size_override("font_size", 16)
	attention_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(attention_value_label)
	
	# Attention Bar (TextureProgressBar)
	attention_bar = TextureProgressBar.new()
	attention_bar.name = "AttentionBar"
	attention_bar.position = Vector2(10, 155)
	attention_bar.size = Vector2(280, 28)
	attention_bar.min_value = 0
	attention_bar.max_value = 20
	attention_bar.nine_patch_stretch = true
	var attn_frame = load("res://assets/sprites/ui/ui_attention_frame.png")
	var attn_fill = load("res://assets/sprites/ui/ui_attention_fill.png")
	if attn_frame:
		attention_bar.texture_over = attn_frame
	if attn_fill:
		attention_bar.texture_progress = attn_fill
	player_panel.add_child(attention_bar)
	
	# Attention state descriptions
	var desc_label = Label.new()
	desc_label.name = "AttentionDesc"
	desc_label.position = Vector2(10, 190)
	desc_label.size = Vector2(280, 50)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	player_panel.add_child(desc_label)
	
	# Quiddity Icon + Label
	quiddity_icon = TextureRect.new()
	quiddity_icon.name = "QuiddityIcon"
	quiddity_icon.position = Vector2(15, 250)
	quiddity_icon.size = Vector2(26, 26)
	var gem_tex = load("res://assets/sprites/ui/ui_gem_quiddity.png")
	if gem_tex:
		quiddity_icon.texture = gem_tex
	quiddity_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	player_panel.add_child(quiddity_icon)
	
	quiddity_label = Label.new()
	quiddity_label.name = "QuiddityLabel"
	quiddity_label.position = Vector2(46, 250)
	quiddity_label.size = Vector2(239, 26)
	quiddity_label.add_theme_font_size_override("font_size", 16)
	quiddity_label.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	player_panel.add_child(quiddity_label)
	
	# Deck Icon + Count (next to quiddity)
	deck_icon = TextureRect.new()
	deck_icon.name = "DeckIcon"
	deck_icon.position = Vector2(15, 285)
	deck_icon.size = Vector2(36, 48)
	var deck_tex = load("res://assets/sprites/ui/ui_deck_icon.png")
	if deck_tex:
		deck_icon.texture = deck_tex
	deck_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	player_panel.add_child(deck_icon)
	
	deck_count_label = Label.new()
	deck_count_label.name = "DeckCount"
	deck_count_label.position = Vector2(56, 285)
	deck_count_label.size = Vector2(229, 48)
	deck_count_label.add_theme_font_size_override("font_size", 16)
	deck_count_label.text = "Deck: 0"
	player_panel.add_child(deck_count_label)
	
	# End turn button (TextureButton)
	end_turn_btn = TextureButton.new()
	end_turn_btn.name = "EndTurnBtn"
	end_turn_btn.position = Vector2(10, 345)
	end_turn_btn.size = Vector2(135, 50)
	var btn_tex = load("res://assets/sprites/ui/ui_button_bg.png")
	var btn_pressed = load("res://assets/sprites/ui/ui_button_bg_pressed.png")
	if btn_tex:
		end_turn_btn.texture_normal = btn_tex
	if btn_pressed:
		end_turn_btn.texture_pressed = btn_pressed
	# Add label as child
	var end_turn_label = Label.new()
	end_turn_label.text = "End Turn (T)"
	end_turn_label.anchor_right = 1.0
	end_turn_label.anchor_bottom = 1.0
	end_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_turn_label.add_theme_font_size_override("font_size", 14)
	end_turn_btn.add_child(end_turn_label)
	end_turn_btn.pressed.connect(_on_end_turn)
	player_panel.add_child(end_turn_btn)
	
	# Stake button (TextureButton)
	stake_btn = TextureButton.new()
	stake_btn.name = "StakeBtn"
	stake_btn.position = Vector2(155, 345)
	stake_btn.size = Vector2(135, 50)
	if btn_tex:
		stake_btn.texture_normal = btn_tex
	if btn_pressed:
		stake_btn.texture_pressed = btn_pressed
	var stake_label = Label.new()
	stake_label.name = "StakeLabel"
	stake_label.text = "Stake 0"
	stake_label.anchor_right = 1.0
	stake_label.anchor_bottom = 1.0
	stake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stake_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stake_label.add_theme_font_size_override("font_size", 14)
	stake_btn.add_child(stake_label)
	stake_btn.tooltip_text = "Click to increase stake: draw fewer cards, gain Quiddity"
	stake_btn.pressed.connect(_on_stake)
	player_panel.add_child(stake_btn)
	
	# ============================================
	# POTIONS (bottom left, below player panel)
	# ============================================
	potion_container = HBoxContainer.new()
	potion_container.name = "PotionContainer"
	potion_container.position = Vector2(20, 500)
	potion_container.size = Vector2(300, 48)
	potion_container.alignment = BoxContainer.ALIGNMENT_CENTER
	potion_container.add_theme_constant_override("separation", 12)
	add_child(potion_container)
	
	# Create 3 potion slots
	for i in range(3):
		var slot = TextureButton.new()
		slot.name = "PotionSlot_%d" % i
		slot.size = Vector2(44, 44)
		var empty_slot = load("res://assets/sprites/ui/ui_slot_empty.png")
		if empty_slot:
			slot.texture_normal = empty_slot
		slot.disabled = true
		potion_container.add_child(slot)
		potion_slots.append(slot)
	
	# ============================================
	# ============================================
	# EQUIPMENT PANEL (right side)
	# ============================================
	equip_panel = NinePatchRect.new()
	equip_panel.name = "EquipPanel"
	equip_panel.position = Vector2(1580, 50)
	equip_panel.size = Vector2(120, 320)
	if panel_tex:
		equip_panel.texture = panel_tex
		equip_panel.patch_margin_left = 15
		equip_panel.patch_margin_right = 15
		equip_panel.patch_margin_top = 15
		equip_panel.patch_margin_bottom = 15
	add_child(equip_panel)
	
	# Equipment label
	var equip_title = Label.new()
	equip_title.text = "GEAR"
	equip_title.position = Vector2(5, 8)
	equip_title.size = Vector2(110, 22)
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_title.add_theme_font_size_override("font_size", 14)
	equip_panel.add_child(equip_title)
	
	# Create 4 equipment slots
	var equip_types = ["weapon", "armor", "trinket", "shield"]
	var equip_icons = [
		"res://assets/sprites/ui/ui_equip_weapon.png",
		"res://assets/sprites/ui/ui_equip_armor.png",
		"res://assets/sprites/ui/ui_equip_trinket.png",
		"res://assets/sprites/ui/ui_equip_shield.png"
	]
	for i in range(4):
		var slot = TextureRect.new()
		slot.name = "Equip_%s" % equip_types[i]
		slot.position = Vector2(28, 40 + i * 70)
		slot.size = Vector2(64, 64)
		var slot_tex = load("res://assets/sprites/ui/ui_equip_slot.png")
		if slot_tex:
			slot.texture = slot_tex
		# Add equipped item icon (small, centered)
		var item = TextureRect.new()
		item.name = "Item"
		item.position = Vector2(16, 16)
		item.size = Vector2(32, 32)
		var item_tex = load(equip_icons[i])
		if item_tex:
			item.texture = item_tex
		item.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		slot.add_child(item)
		equip_panel.add_child(slot)
		equip_slots.append(slot)
	
	# Weapon Use Button (below weapon slot)
	weapon_use_btn = TextureButton.new()
	weapon_use_btn.name = "WeaponUseBtn"
	weapon_use_btn.position = Vector2(28, 110)
	weapon_use_btn.size = Vector2(64, 28)
	var weapon_btn_tex = load("res://assets/sprites/ui/ui_weapon_attack.png")
	if weapon_btn_tex:
		weapon_use_btn.texture_normal = weapon_btn_tex
	weapon_use_btn.disabled = true
	weapon_use_btn.tooltip_text = "Weapon not charged"
	weapon_use_btn.pressed.connect(_on_weapon_use)
	equip_panel.add_child(weapon_use_btn)
	
	# ============================================
	# ============================================
	# HAND CONTAINER (bottom center)
	# ============================================
	hand_container = HBoxContainer.new()
	hand_container.name = "HandContainer"
	hand_container.position = Vector2(340, 820)
	hand_container.size = Vector2(1400, 240)
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", 15)
	add_child(hand_container)
	
	# ============================================
	# ============================================
	# ENEMY CONTAINER (top)
	# ============================================
	enemy_container = HBoxContainer.new()
	enemy_container.name = "EnemyContainer"
	enemy_container.position = Vector2(350, 50)
	enemy_container.size = Vector2(1200, 300)
	enemy_container.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_container.add_theme_constant_override("separation", 40)
	add_child(enemy_container)
	
	# ============================================
	# CARD PLAY MIST EFFECT (full screen overlay)
	# ============================================
	mist_overlay = ColorRect.new()
	mist_overlay.name = "MistOverlay"
	mist_overlay.anchor_right = 1.0
	mist_overlay.anchor_bottom = 1.0
	mist_overlay.offset_right = 1920.0
	mist_overlay.offset_bottom = 1080.0
	mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist_overlay.visible = false
	
	var mist_material = ShaderMaterial.new()
	var mist_shader = load("res://assets/shaders/card_mist.gdshader")
	if mist_shader:
		mist_material.shader = mist_shader
		mist_overlay.material = mist_material
	add_child(mist_overlay)
	
	card_play_effect = CardPlayEffect.new()
	card_play_effect.name = "CardPlayEffect"
	card_play_effect.effect_rect = mist_overlay
	add_child(card_play_effect)

func _get_attention_color(state: CombatManager.AttentionState) -> Color:
	match state:
		CombatManager.AttentionState.WHISPER: return Color(0.72, 0.53, 0.04)    # Deep amber
		CombatManager.AttentionState.BORROWED: return Color(1.0, 0.84, 0.0)     # Bright gold
		CombatManager.AttentionState.UNDEFINED: return Color(1.0, 1.0, 0.0)     # Electric yellow
		CombatManager.AttentionState.SCREAM: return Color(0.0, 1.0, 1.0)        # Cyan/white
	return Color(0.5, 0.5, 0.5)

func _get_attention_description(state: CombatManager.AttentionState) -> String:
	match state:
		CombatManager.AttentionState.WHISPER:
			return "Min damage dealt/taken. Safe but slow."
		CombatManager.AttentionState.BORROWED:
			return "Average damage. Risk/reward threshold."
		CombatManager.AttentionState.UNDEFINED:
			return "Max damage taken. High vulnerability."
		CombatManager.AttentionState.SCREAM:
			return "Max damage dealt, but enemies deal max too."
	return ""

func _on_combat_started():
	visible = true
	_update_player_display(0)
	_update_attention_display(0, 20)
	_update_quiddity_display(0)
	_update_deck_count()
	_create_enemy_displays()
	_update_hand_display()
	selected_card_index = -1

func _on_combat_ended(victory: bool):
	var msg = Label.new()
	msg.text = "VICTORY!" if victory else "DEFEAT..."
	msg.position = Vector2(860, 450)
	msg.size = Vector2(200, 80)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 56)
	msg.modulate = Color(0.3, 0.9, 0.3) if victory else Color(0.9, 0.3, 0.3)
	add_child(msg)
	
	await get_tree().create_timer(2.5).timeout
	
	visible = false
	msg.queue_free()
	
	for child in hand_container.get_children():
		child.queue_free()
	for child in enemy_container.get_children():
		child.queue_free()

func _on_turn_started(is_player: bool):
	end_turn_btn.disabled = not is_player
	stake_btn.disabled = not is_player
	_update_weapon_button()
	_update_player_display(0)
	_update_attention_display(combat_manager.player_attention, 20)
	_update_hand_display()
	_update_enemy_buttons()
	_update_deck_count()

func _on_end_turn():
	combat_manager.end_player_turn()

func _on_stake():
	var current_stake = combat_manager.player_stake
	var new_stake = (current_stake + 1) % 6  # Cycle 0→1→2→3→4→5→0
	var delta = new_stake - current_stake
	if delta < 0:
		# Wrapping from 5 to 0 — refund all quiddity
		combat_manager.player_quiddity -= current_stake
		combat_manager.quiddity_this_combat -= current_stake
	else:
		combat_manager.player_quiddity += delta
		combat_manager.quiddity_this_combat += delta
	combat_manager.player_stake = new_stake
	
	var stake_label = stake_btn.get_node_or_null("StakeLabel")
	if stake_label and stake_label is Label:
		if new_stake == 0:
			stake_label.text = "Stake 0"
			stake_btn.tooltip_text = "Click to increase stake"
		else:
			stake_label.text = "Stake -%d" % new_stake
			stake_btn.tooltip_text = "Draw %d fewer cards, gain %d Quiddity. Click to increase." % [new_stake, new_stake]
	
	_update_quiddity_display(combat_manager.player_quiddity)
	print("CombatUI: Stake set to %d (draw %d cards, +%d Quiddity)" % [new_stake, 5 - new_stake, new_stake])

func _on_weapon_use():
	"""Use equipped weapon on currently selected enemy (defaults to first alive)."""
	if not combat_manager.is_player_turn:
		return
	# Find first alive enemy as default target
	var target = 0
	for i in range(combat_manager.enemies.size()):
		if combat_manager.enemies[i].hp > 0:
			target = i
			break
	if combat_manager.use_weapon(target):
		print("CombatUI: Weapon used on enemy %d" % target)
		_update_enemy_buttons()
		_update_weapon_button()

func _update_weapon_button():
	"""Update weapon use button based on charge state."""
	if weapon_use_btn:
		var charged = combat_manager.equipped_weapon_id != "" and combat_manager.weapon_charge >= combat_manager.weapon_max_charge and combat_manager.weapon_max_charge > 0
		weapon_use_btn.disabled = not charged or not combat_manager.is_player_turn
		if charged:
			weapon_use_btn.tooltip_text = "Weapon charged! Click to attack"
		else:
			weapon_use_btn.tooltip_text = "Weapon charging... (%d/%d)" % [combat_manager.weapon_charge, combat_manager.weapon_max_charge]

func _on_card_drawn(_card: CardData):
	_update_hand_display()
	_update_deck_count()

func _on_card_played(card: CardData):
	_update_hand_display()
	_update_player_display(0)
	selected_card_index = -1
	_update_deck_count()
	
	# Trigger faction-colored mist effect
	if card_play_effect and card:
		card_play_effect.trigger_effect(card.faction)

func _update_player_display(_amount: int = 0):
	var hp_percent = float(combat_manager.player_hp) / combat_manager.player_max_hp
	hp_bar.value = hp_percent * 100
	hp_text_label.text = "%d / %d" % [combat_manager.player_hp, combat_manager.player_max_hp]
	# Change fill texture when low
	if hp_percent <= 0.3:
		var low_fill = load("res://assets/sprites/ui/ui_hp_bar_fill_low.png")
		if low_fill:
			hp_bar.texture_progress = low_fill
	else:
		var normal_fill = load("res://assets/sprites/ui/ui_hp_bar_fill.png")
		if normal_fill:
			hp_bar.texture_progress = normal_fill
	
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
	
	# Update description
	var desc_label = player_panel.get_node_or_null("AttentionDesc")
	if desc_label:
		desc_label.text = _get_attention_description(state)
	
	# Debt warning
	if current >= 18:
		attention_value_label.modulate = Color(1, 0.3, 0.3)
	else:
		attention_value_label.modulate = Color(1, 1, 1)

func _update_quiddity_display(current: int):
	quiddity_label.text = "Quiddity: %d" % current

func _update_deck_count():
	var deck_size = combat_manager.deck.size() if combat_manager.deck else 0
	deck_count_label.text = "Deck: %d" % deck_size

func _create_enemy_displays():
	for child in enemy_container.get_children():
		child.queue_free()
	
	for i in range(combat_manager.enemies.size()):
		var enemy = combat_manager.enemies[i]
		var panel = _create_enemy_panel(enemy, i)
		enemy_container.add_child(panel)

func _create_enemy_panel(enemy: CombatManager.EnemyData, index: int) -> NinePatchRect:
	var panel = NinePatchRect.new()
	panel.name = "Enemy_%d" % index
	panel.size = Vector2(200, 260)
	var panel_tex = load("res://assets/sprites/ui/ui_enemy_panel_bg.png")
	if panel_tex:
		panel.texture = panel_tex
		panel.patch_margin_left = 15
		panel.patch_margin_right = 15
		panel.patch_margin_top = 15
		panel.patch_margin_bottom = 15
	panel.modulate = Color(1, 1, 1) if enemy.hp > 0 else Color(0.4, 0.4, 0.4)
	
	# Enemy name
	var name_label = Label.new()
	name_label.text = enemy.name
	name_label.position = Vector2(5, 8)
	name_label.size = Vector2(190, 28)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(name_label)
	
	# HP bar (TextureProgressBar)
	var enemy_hp = TextureProgressBar.new()
	enemy_hp.name = "HPFill"
	enemy_hp.position = Vector2(15, 45)
	enemy_hp.size = Vector2(170, 24)
	enemy_hp.min_value = 0
	enemy_hp.max_value = 100
	var hp_percent = float(enemy.hp) / enemy.max_hp
	enemy_hp.value = hp_percent * 100
	var hp_frame = load("res://assets/sprites/ui/ui_hp_bar_frame.png")
	var hp_fill = load("res://assets/sprites/ui/ui_hp_bar_fill.png")
	if hp_frame:
		enemy_hp.texture_over = hp_frame
	if hp_fill:
		enemy_hp.texture_progress = hp_fill
	if hp_percent <= 0.3:
		var low_fill = load("res://assets/sprites/ui/ui_hp_bar_fill_low.png")
		if low_fill:
			enemy_hp.texture_progress = low_fill
	panel.add_child(enemy_hp)
	
	# HP text
	var hp_text = Label.new()
	hp_text.name = "HPText"
	hp_text.text = "%d / %d" % [enemy.hp, enemy.max_hp]
	hp_text.position = Vector2(5, 45)
	hp_text.size = Vector2(190, 24)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hp_text)
	
	# Attack info
	var atk_label = Label.new()
	atk_label.text = "ATK: %d" % enemy.attack
	atk_label.position = Vector2(5, 80)
	atk_label.size = Vector2(190, 24)
	atk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(atk_label)
	
	# Target button (TextureButton)
	var target_btn = TextureButton.new()
	target_btn.name = "TargetButton"
	target_btn.position = Vector2(25, 190)
	target_btn.size = Vector2(150, 55)
	var btn_tex = load("res://assets/sprites/ui/ui_target_button.png")
	var btn_pressed = load("res://assets/sprites/ui/ui_button_bg_pressed.png")
	if btn_tex:
		target_btn.texture_normal = btn_tex
	if btn_pressed:
		target_btn.texture_pressed = btn_pressed
	var target_label = Label.new()
	target_label.text = "TARGET"
	target_label.anchor_right = 1.0
	target_label.anchor_bottom = 1.0
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 18)
	target_btn.add_child(target_label)
	target_btn.disabled = enemy.hp <= 0
	target_btn.pressed.connect(func(): _on_target_selected(index))
	panel.add_child(target_btn)
	
	return panel

func _update_enemy_display(index: int, _damage: int):
	var panel = enemy_container.get_node_or_null("Enemy_%d" % index)
	if not panel:
		return
	
	var enemy = combat_manager.enemies[index]
	
	# Update HP bar
	var enemy_hp = panel.get_node_or_null("HPFill")
	if enemy_hp:
		var hp_percent = float(enemy.hp) / enemy.max_hp
		enemy_hp.value = hp_percent * 100
		if hp_percent <= 0.3:
			var low_fill = load("res://assets/sprites/ui/ui_hp_bar_fill_low.png")
			if low_fill:
				enemy_hp.texture_progress = low_fill
		else:
			var normal_fill = load("res://assets/sprites/ui/ui_hp_bar_fill.png")
			if normal_fill:
				enemy_hp.texture_progress = normal_fill
	
	# Update HP text
	var hp_text = panel.get_node_or_null("HPText")
	if hp_text:
		hp_text.text = "%d / %d" % [enemy.hp, enemy.max_hp]
	
	# Grey out if dead
	if enemy.hp <= 0:
		panel.modulate = Color(0.4, 0.4, 0.4)
		var btn = panel.get_node_or_null("TargetButton")
		if btn:
			btn.disabled = true
			var btn_label = btn.get_node_or_null("Label")
			if btn_label and btn_label is Label:
				btn_label.text = "DEFEATED"

func _update_enemy_buttons():
	for i in range(combat_manager.enemies.size()):
		var panel = enemy_container.get_node_or_null("Enemy_%d" % i)
		if panel:
			var btn = panel.get_node_or_null("TargetButton")
			if btn and combat_manager.enemies[i].hp > 0:
				btn.disabled = false

func _update_hand_display():
	for child in hand_container.get_children():
		child.queue_free()
	
	for i in range(combat_manager.hand.size()):
		var card = combat_manager.hand[i]
		var card_node = _create_visual_card(card, i)
		hand_container.add_child(card_node)

# ============================================
# VISUAL CARD RENDERING — Textured UI Version
# ============================================

func _create_visual_card(card: CardData, index: int) -> Control:
	"""Create a visual card with textured UI assets"""
	
	# Main card container
	var card_root = Control.new()
	card_root.name = "Card_%d" % index
	card_root.size = Vector2(140, 200)
	card_root.custom_minimum_size = Vector2(140, 200)
	
	# --- Layer 1: Card Art (base) ---
	var art_rect = TextureRect.new()
	art_rect.name = "Art"
	art_rect.anchor_right = 1.0
	art_rect.anchor_bottom = 1.0
	art_rect.offset_left = 2
	art_rect.offset_top = 2
	art_rect.offset_right = -2
	art_rect.offset_bottom = -2
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load card art
	if card.sprite_texture_path != "":
		var art_tex = load(card.sprite_texture_path)
		if art_tex:
			art_rect.texture = art_tex
	else:
		# Fallback: colored background based on faction
		art_rect.modulate = _get_faction_color(card.faction)
	
	card_root.add_child(art_rect)
	
	# --- GOLD BORDER LAYER (for cards that survive resets) ---
	if card.survives_reset:
		var border = TextureRect.new()
		border.name = "GoldBorder"
		border.anchor_right = 1.0
		border.anchor_bottom = 1.0
		border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		border.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gold_tex = load("res://assets/sprites/ui/ui_card_gold_border.png")
		if gold_tex:
			border.texture = gold_tex
		card_root.add_child(border)
		
		# Crown icon (top-right corner indicator)
		var crown = TextureRect.new()
		crown.name = "CrownIcon"
		crown.position = Vector2(112, 5)
		crown.size = Vector2(22, 20)
		var crown_tex = load("res://assets/sprites/ui/ui_crown_icon.png")
		if crown_tex:
			crown.texture = crown_tex
		crown.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(crown)
	
	# --- Layer 2: Frame Border (overlay with transparent center) ---
	var frame_rect = TextureRect.new()
	frame_rect.name = "Frame"
	frame_rect.anchor_right = 1.0
	frame_rect.anchor_bottom = 1.0
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load frame texture
	if card.frame_texture_path != "":
		var frame_tex = load(card.frame_texture_path)
		if frame_tex:
			frame_rect.texture = frame_tex
	
	card_root.add_child(frame_rect)
	
	# --- Layer 3: Text Overlay (on top) ---
	# Attention cost badge (top left) — TextureRect with badge bg
	if card.attention_cost > 0:
		var badge = TextureRect.new()
		badge.name = "CostBadge"
		badge.position = Vector2(4, 4)
		badge.size = Vector2(32, 26)
		var badge_tex = load("res://assets/sprites/ui/ui_cost_badge.png")
		if badge_tex:
			badge.texture = badge_tex
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(badge)
		
		var cost_label = Label.new()
		cost_label.text = str(card.attention_cost)
		cost_label.position = Vector2(4, 4)
		cost_label.size = Vector2(32, 26)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 13)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(cost_label)
	
	# Card name (bottom area) — TextureRect strip background
	var name_bg = TextureRect.new()
	name_bg.name = "NameBG"
	name_bg.position = Vector2(4, 146)
	name_bg.size = Vector2(132, 22)
	var name_tex = load("res://assets/sprites/ui/ui_card_name_strip.png")
	if name_tex:
		name_bg.texture = name_tex
	name_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	name_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	name_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(name_bg)
	
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.position = Vector2(4, 146)
	name_label.size = Vector2(132, 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(name_label)
	
	# Effect text (below name) — TextureRect strip
	var effect_parts = []
	if card.damage_flat > 0 or card.damage_dice != "":
		if card.uses_dice:
			effect_parts.append("DMG: %s" % card.damage_dice)
		else:
			effect_parts.append("DMG: %d" % card.damage_flat)
	if card.shield_amount > 0:
		effect_parts.append("SHIELD: %d" % card.shield_amount)
	if card.heal_amount > 0:
		effect_parts.append("HEAL: %d" % card.heal_amount)
	if card.summon_count > 0:
		effect_parts.append("SUMMON %d" % card.summon_count)
	
	var effect_text = " / ".join(effect_parts)
	if effect_text != "":
		var effect_bg = TextureRect.new()
		effect_bg.name = "EffectBG"
		effect_bg.position = Vector2(4, 168)
		effect_bg.size = Vector2(132, 16)
		var effect_tex = load("res://assets/sprites/ui/ui_card_effect_strip.png")
		if effect_tex:
			effect_bg.texture = effect_tex
		effect_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		effect_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		effect_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(effect_bg)
		
		var effect_label = Label.new()
		effect_label.text = effect_text
		effect_label.position = Vector2(4, 168)
		effect_label.size = Vector2(132, 16)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(effect_label)
	
	# Keywords (bottom) — TextureRect strip
	if card.keywords.size() > 0:
		var keywords_bg = TextureRect.new()
		keywords_bg.name = "KeywordsBG"
		keywords_bg.position = Vector2(4, 184)
		keywords_bg.size = Vector2(132, 12)
		var kw_tex = load("res://assets/sprites/ui/ui_card_keywords_strip.png")
		if kw_tex:
			keywords_bg.texture = kw_tex
		keywords_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		keywords_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		keywords_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(keywords_bg)
		
		var keywords_label = Label.new()
		keywords_label.text = ", ".join(card.keywords)
		keywords_label.position = Vector2(4, 184)
		keywords_label.size = Vector2(132, 12)
		keywords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		keywords_label.add_theme_font_size_override("font_size", 8)
		keywords_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
		keywords_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_root.add_child(keywords_label)
	
	# --- Click handling ---
	# Check if affordable
	var would_exceed = (combat_manager.player_attention + card.attention_cost) > 20
	
	if would_exceed:
		card_root.modulate = Color(0.4, 0.4, 0.4)  # Greyed out
	else:
		# Highlight if selected
		if index == selected_card_index:
			card_root.modulate = Color(1.3, 1.3, 1.3)  # Brightened
		else:
			card_root.modulate = Color(1, 1, 1)
	
	# Make the card clickable via a full-size button overlay
	if not would_exceed:
		var click_area = Button.new()
		click_area.name = "ClickArea"
		click_area.anchor_right = 1.0
		click_area.anchor_bottom = 1.0
		click_area.flat = true
		click_area.modulate = Color(1, 1, 1, 0.0)  # Fully transparent
		click_area.pressed.connect(func(): _on_card_clicked(index))
		card_root.add_child(click_area)
	
	return card_root

func _get_faction_color(faction: String) -> Color:
	match faction:
		"Construct": return Color(0.7, 0.75, 0.8)    # Steel blue-gray
		"Goblin": return Color(0.5, 0.75, 0.45)      # Green
		"Undead": return Color(0.6, 0.55, 0.7)       # Purple-gray
		"Elemental": return Color(0.9, 0.6, 0.35)    # Orange
		"Demon": return Color(0.8, 0.35, 0.3)        # Red
		"Aberration": return Color(0.7, 0.4, 0.75)   # Magenta
		"Dragon": return Color(0.85, 0.7, 0.35)      # Gold
		"Universal": return Color(0.75, 0.75, 0.75)  # Silver
		_: return Color(0.7, 0.7, 0.7)

func _on_card_clicked(index: int):
	selected_card_index = index
	_update_hand_display()  # Refresh to show selection
	
	# Auto-play on first living enemy for now
	for i in range(combat_manager.enemies.size()):
		if combat_manager.enemies[i].hp > 0:
			combat_manager.play_card(index, i)
			return

func _on_target_selected(enemy_index: int):
	AudioManager.play_sfx("target_select")
	if selected_card_index >= 0 and selected_card_index < combat_manager.hand.size():
		combat_manager.play_card(selected_card_index, enemy_index)
		selected_card_index = -1
		_update_hand_display()

func _input(event: InputEvent):
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			_on_end_turn()
