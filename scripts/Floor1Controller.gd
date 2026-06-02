extends FloorController

# ===================================================================
# FLOOR 1 CONTROLLER — The Portal Room
# Refactored to use FloorController base class + Floor1Template
# ===================================================================

@onready var floor1_template: Floor1Template = Floor1Template.new()

# Tutorial state
var door_tutorial_active: bool = false
var tutorial_step: int = 0
var tutorial_prompt_label: Label

# Shop stock — Universal cards (only place to buy cards with gems)
var shop_stock: Array[Dictionary] = [
	{"card_id": "Universal_counterspell", "cost": 15, "name": "Counterspell", "desc": "Negate enemy Special, they lose next action"},
	{"card_id": "Universal_focus", "cost": 10, "name": "Focus", "desc": "Gain +2 Attention this turn"},
	{"card_id": "Universal_fortify", "cost": 12, "name": "Fortify", "desc": "Gain 8 Shield"},
	{"card_id": "Universal_cleanse", "cost": 10, "name": "Cleanse", "desc": "Remove all debuffs"},
	{"card_id": "Universal_overcharge", "cost": 15, "name": "Overcharge", "desc": "Next attack deals +50% damage"}
]

var shop_ui_active: bool = false
var shop_ui_container: Control

func _ready():
	floor_template = floor1_template
	super._ready()
	
	# Initialize hex tile map
	var hex_map = get_node_or_null("HexTileMap")
	if hex_map:
		hex_map.generate_floor1_layout()
		print("[Floor1] Hex tile map generated")

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Snap player to hex center on spawn
	var hex_map = get_node_or_null("HexTileMap")
	if hex_map and player_node:
		var spawn_hex = hex_map.get_room_center("entry")
		player_node.global_position = hex_map.hex_to_world(spawn_hex)
		print("[Floor1] Player snapped to hex center: %s" % str(spawn_hex))
	
	if GameState.is_first_run:
		print("[Floor1] First run — tutorial mode")
		_lock_portals_except(["north"])
	else:
		print("[Floor1] Re-run — all portals active")
		_unlock_all_portals()
		if not GameState.door_tutorial_completed:
			GameState.door_tutorial_completed = true

func _setup_floor_ui():
	# Transit token display
	var transit_ui = Control.new()
	transit_ui.name = "TransitTokenUI"
	transit_ui.position = Vector2(20, 20)
	add_child(transit_ui)
	_update_transit_token_display()
	
	# Tutorial prompt overlay
	tutorial_prompt_label = Label.new()
	tutorial_prompt_label.name = "TutorialPrompt"
	tutorial_prompt_label.position = Vector2(660, 200)
	tutorial_prompt_label.size = Vector2(600, 80)
	tutorial_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_prompt_label.add_theme_font_size_override("font_size", 18)
	tutorial_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	tutorial_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	tutorial_prompt_label.add_theme_constant_override("shadow_outline_size", 4)
	tutorial_prompt_label.visible = false
	add_child(tutorial_prompt_label)

func _update_floor_ui():
	_update_transit_token_display()

func _update_transit_token_display():
	var transit_ui = get_node_or_null("TransitTokenUI")
	if not transit_ui:
		return
	
	for child in transit_ui.get_children():
		child.queue_free()
	
	var tokens = GameState.transit_tokens if GameState.get("transit_tokens") else []
	if tokens.is_empty():
		return
	
	var y_offset = 0
	for token in tokens:
		var label = Label.new()
		label.text = "🗝 %s" % token
		label.position = Vector2(0, y_offset)
		label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		transit_ui.add_child(label)
		y_offset += 25

# -------------------------------------------------------------------
# The Door Tutorial
# -------------------------------------------------------------------

func _start_door_tutorial():
	"""Start the scripted Door tutorial combat."""
	door_tutorial_active = true
	tutorial_step = 0
	print("[Floor1] Door tutorial started")
	
	# Start combat with The Door
	var door_enemy = RoomEnemyDatabase.ENEMIES["The Door"].to_combat_data()
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if combat_manager:
		in_combat = true
		combat_manager.start_combat([door_enemy], GameState.player_deck)
		combat_manager.combat_ended.connect(_on_tutorial_combat_ended)
		
		# Show first prompt
		_advance_tutorial_step()

func _advance_tutorial_step():
	match tutorial_step:
		0:
			_show_tutorial_prompt("The Door closes its panels.\nPlay a BLOCK (Defense) card to defend yourself!")
		1:
			_show_tutorial_prompt("Good! Now the Door slams forward.\nPlay an ATTACK card to strike back!")
		2:
			_show_tutorial_prompt("The Door closes again.\nPlay another BLOCK card!")
		3:
			_show_tutorial_prompt("Final strike! Play an ATTACK card to finish it!")
		4:
			_hide_tutorial_prompt()
			print("[Floor1] Tutorial complete — victory!")

func _show_tutorial_prompt(text: String):
	if tutorial_prompt_label:
		tutorial_prompt_label.text = text
		tutorial_prompt_label.visible = true

func _hide_tutorial_prompt():
	if tutorial_prompt_label:
		tutorial_prompt_label.visible = false

func _on_tutorial_combat_ended(victory: bool):
	in_combat = false
	_hide_tutorial_prompt()
	
	if victory:
		# Tutorial reward
		GameState.door_tutorial_completed = true
		GameState.is_first_run = false
		
		# Give random basic card
		var basic_cards = ["gear_strike", "brass_shield", "piston_slam"]
		var random_card = basic_cards[randi() % basic_cards.size()]
		GameState.add_card_to_deck(random_card)
		
		# Give quiddity
		GameState.add_quiddity(10)
		
		_show_dialogue("The Door", "The Door creaks open. Light spills through.\nYou gained a new card and 10 Quiddity!")
		
		# Unlock all portals
		_unlock_all_portals()
		
		# Mark north room cleared
		var north = rooms.get("north")
		if north and north.has_method("mark_cleared"):
			north.mark_cleared()
		
		print("[Floor1] Door tutorial completed — all portals unlocked")
	else:
		_show_dialogue("The Door", "The Portal pulls you back. The Door remains closed.")
		# On death, respawn at center with 1 HP (Floor 1 safety net)
		GameState.player_hp = max(1, GameState.player_hp)
		move_player_to_room("central")
	
	# Disconnect signal
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if combat_manager and combat_manager.combat_ended.is_connected(_on_tutorial_combat_ended):
		combat_manager.combat_ended.disconnect(_on_tutorial_combat_ended)

func _check_tutorial_card_played(card: CardData):
	"""Called when player plays a card during tutorial. Check if correct type."""
	if not door_tutorial_active:
		return
	
	match tutorial_step:
		0, 2:  # Expecting Defense/Block
			if card.card_type == "Defense" or card.shield_amount > 0:
				tutorial_step += 1
				_advance_tutorial_step()
			else:
				_show_tutorial_prompt("That's not a Block card!\nPlay a DEFENSE card to protect yourself.")
		1, 3:  # Expecting Attack
			if card.card_type == "Attack" or card.damage_flat > 0 or card.uses_dice:
				tutorial_step += 1
				_advance_tutorial_step()
			else:
				_show_tutorial_prompt("That's not an Attack card!\nPlay an ATTACK card to damage the Door.")

# -------------------------------------------------------------------
# Boss Unlock
# -------------------------------------------------------------------

func _on_check_boss_unlock():
	if _check_boss_unlock():
		_unlock_boss_portal()

func _check_boss_unlock() -> bool:
	return GameState.has_all_transit_tokens()

func _unlock_boss_portal():
	print("[Floor1] BOSS PORTAL UNLOCKED!")
	boss_portal_unlocked.emit()
	var central = rooms.get("central")
	if central and central.has_method("activate_boss_portal"):
		central.activate_boss_portal()
	
	_show_dialogue("The Tower", "The Main Portal shifts from blue to red.\nThe path Up opens.")

# -------------------------------------------------------------------
# Portal Locking
# -------------------------------------------------------------------

func _lock_portals_except(allowed: Array[String]):
	var room = rooms.get("central")
	if not room:
		return
	# Room must implement unlock/lock portal methods
	for dir_name in ["north", "east", "south", "west"]:
		if dir_name not in allowed and room.has_method("lock_portal"):
			room.lock_portal(dir_name)

func _unlock_all_portals():
	for room in rooms.values():
		if room.has_method("unlock_all_portals"):
			room.unlock_all_portals()

# -------------------------------------------------------------------
# Object Interactions (override)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	match object_type:
		"Talk to Construct":
			_show_dialogue("Transit Construct", "Welcome to the Tower, Seeker. The portals lead to the four trials. Collect all transit tokens to unlock the path Up.")
		"Open Shop":
			_open_shop()
		"Open Chest":
			_open_chest()
		"Break Wall":
			_break_wall()
		"Approach Door":
			if not GameState.door_tutorial_completed:
				_start_door_tutorial()
			else:
				_show_dialogue("The Door", "The Door stands open. The threshold has been crossed.")
		"Receive Blessing":
			_receive_blessing()
		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.")
		"Make Offering":
			_make_offering()
		_:
			print("[Floor1] Unknown interaction: %s" % object_type)

# -------------------------------------------------------------------
# Shop System
# -------------------------------------------------------------------

func _open_shop():
	"""Open the functional card shop UI."""
	if shop_ui_active:
		return
	
	if shop_stock.is_empty():
		_show_dialogue("Shop", "The shop is closed. Return later.")
		return
	
	shop_ui_active = true
	in_ui = true
	
	# Create shop UI container
	shop_ui_container = Control.new()
	shop_ui_container.name = "ShopUI"
	add_child(shop_ui_container)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	shop_ui_container.add_child(bg)
	
	# Panel
	var panel = PanelContainer.new()
	panel.size = Vector2(700, 550)
	panel.position = Vector2(610, 265)
	shop_ui_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "⚙ Machinist's Card Shop ⚙"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var gems_label = Label.new()
	gems_label.text = "Gems: %d💎" % GameState.gems
	gems_label.add_theme_font_size_override("font_size", 18)
	gems_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	header.add_child(gems_label)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Universal cards — only available here!"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(subtitle)
	
	# Card grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	vbox.add_child(grid)
	
	for i in range(shop_stock.size()):
		var slot = _create_card_shop_slot(i, shop_stock[i], gems_label)
		grid.add_child(slot)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Leave Shop"
	close_btn.custom_minimum_size = Vector2(140, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close_shop)
	vbox.add_child(close_btn)
	
	# Input handling for ESC
	set_process_input(true)

func _create_card_shop_slot(index: int, item: Dictionary, gems_label: Label) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 140)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	vbox.add_child(name_label)
	
	# Description
	var desc = Label.new()
	desc.text = item.get("desc", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	# Cost
	var cost = Label.new()
	cost.text = "%d💎" % item["cost"]
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 12)
	cost.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(cost)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Buy button
	var btn = Button.new()
	btn.text = "Buy"
	btn.custom_minimum_size = Vector2(100, 32)
	btn.disabled = GameState.gems < item["cost"]
	btn.pressed.connect(_on_buy_card.bind(index, item, gems_label))
	vbox.add_child(btn)
	
	return panel

func _on_buy_card(index: int, item: Dictionary, gems_label: Label):
	if GameState.gems < item["cost"]:
		return
	
	var card_id = item["card_id"]
	var card = CardDB.get_card(card_id)
	if not card:
		_show_notification("Card not found!")
		return
	
	if GameState.player_deck.size() >= 50:
		_show_notification("Deck full! Max 50 cards.")
		return
	
	GameState.gems -= item["cost"]
	GameState.add_card_to_deck(card_id)
	gems_label.text = "Gems: %d💎" % GameState.gems
	
	# Update all button states
	if shop_ui_container:
		for child in shop_ui_container.get_children():
			if child is PanelContainer:
				for vbox in child.get_children():
					if vbox is VBoxContainer:
						for btn in vbox.get_children():
							if btn is Button and btn.text == "Buy":
								# Find the cost label to get price
								var cost = 0
								for c in vbox.get_children():
									if c is Label and "💎" in c.text:
										cost = int(c.text.replace("💎", "").strip_edges())
								btn.disabled = GameState.gems < cost
	
	_show_notification("Bought %s!" % item["name"])

func _close_shop():
	shop_ui_active = false
	in_ui = false
	if shop_ui_container and is_instance_valid(shop_ui_container):
		shop_ui_container.queue_free()
	shop_ui_container = null

func _show_notification(text: String, color: Color = Color(0.3, 0.9, 0.3), duration: float = 3.0):
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(610, 220)
	notif.size = Vector2(700, 30)
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 180, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

func _buy_from_shop(index: int):
	"""Legacy method — now handled by _on_buy_card."""
	pass

# -------------------------------------------------------------------
# Chest System
# -------------------------------------------------------------------

func _open_chest():
	"""Open a chest in the Shrine room."""
	var current = rooms.get(current_room_id)
	if current and current.room_id == "south":
		# Shrine chest gives quiddity + random offering
		GameState.add_quiddity(5)
		var offerings = ["interesting_trash", "machine_oil", "polished_brass"]
		var random_offering = offerings[randi() % offerings.size()]
		GameState.add_offering(random_offering)
		AudioManager.play_sfx("chest_open")
		_show_dialogue("Chest", "You found 5 Quiddity and %s!" % GameState.get_offering_name(random_offering))
	else:
		_show_dialogue("Chest", "The chest is empty.")

# -------------------------------------------------------------------
# Breakable Wall / Secret Room
# -------------------------------------------------------------------

func _break_wall():
	"""Break the wall in East room to reveal secret room."""
	var current = rooms.get(current_room_id)
	if current and current.room_id == "east":
		# Check if player has something heavy (e.g., a specific item or just always works)
		_show_dialogue("Wall", "The wall crumbles! A hidden passage is revealed.")
		# Unlock secret portal in East room
		if current.has_method("unlock_portal"):
			current.unlock_portal("secret")
	else:
		_show_dialogue("Wall", "The wall is cracked but sturdy.")

# -------------------------------------------------------------------
# Droplet Blessing
# -------------------------------------------------------------------

func _receive_blessing():
	"""Receive blessing from Droplet in South room."""
	var current = rooms.get(current_room_id)
	if current and current.room_id == "south":
		# Heal and give periodic offerings
		GameState.heal_player(5)
		
		# Droplet generates offerings periodically
		var offerings = ["coolant_water", "machine_oil", "interesting_trash"]
		var random_offering = offerings[randi() % offerings.size()]
		if GameState.add_offering(random_offering):
			_show_dialogue("Droplet", "*wobble* ... *drip* ...\nThe water elemental gives you %s and heals 5 HP." % GameState.get_offering_name(random_offering))
		else:
			_show_dialogue("Droplet", "*wobble* ... You carry too many offerings.\nThe Droplet heals you for 5 HP instead.")
	else:
		_show_dialogue("Droplet", "The elemental is not here.")

# -------------------------------------------------------------------
# Offering System
# -------------------------------------------------------------------

func _make_offering():
	"""Make offering at shrine altar."""
	var current = rooms.get(current_room_id)
	if current and current.room_id == "south":
		if GameState.inventory_offerings.is_empty():
			_show_dialogue("Altar", "The altar awaits an offering. You have nothing to give.")
			return
		
		# Give first offering in inventory
		var offering = GameState.inventory_offerings[0]
		GameState.remove_offering(offering)
		
		# Random boon based on offering quality
		var quality = GameState.get_offering_quality(offering)
		match quality:
			0, 1:
				GameState.heal_player(3)
				_show_dialogue("Altar", "You offer %s.\nThe shrine grants a minor blessing: +3 HP." % GameState.get_offering_name(offering))
			2, 3:
				GameState.heal_player(5)
				GameState.add_temp_effect("shrine_blessing", 3)
				_show_dialogue("Altar", "You offer %s.\nThe shrine grants a major blessing: +5 HP and protection for 3 rooms." % GameState.get_offering_name(offering))
			_:
				GameState.heal_player(10)
				GameState.add_quiddity(5)
				_show_dialogue("Altar", "You offer %s.\nThe shrine glows with epic power: +10 HP and 5 Quiddity!" % GameState.get_offering_name(offering))
	else:
		_show_dialogue("Altar", "There is no altar here.")

# -------------------------------------------------------------------
# Gauntlet Traps
# -------------------------------------------------------------------

func _on_player_moved():
	"""Check for trap triggers when player moves (Gauntlet room)."""
	if current_room_id != "west":
		return
	
	if not player_node:
		return
	
	var player_pos = player_node.global_position
	var current = rooms.get("west")
	if not current:
		return
	
	# Check tripwire proximity
	var tripwire_pos = current.get_node_or_null("Interior/Tripwire")
	if tripwire_pos:
		var dist = player_pos.distance_to(tripwire_pos.global_position)
		if dist < 40.0:
			_trigger_tripwire()

func _trigger_tripwire():
	"""Tripwire in Gauntlet — deals damage and spawns Torch Boy."""
	_show_dialogue("Trap", "TRIPWIRE! You take 2 damage and a Torch Boy ambushes you!")
	GameState.damage_player(2)
	
	# Spawn Torch Boy encounter
	var west = rooms.get("west")
	if west and west.has_method("spawn_encounter"):
		west.spawn_encounter()

# -------------------------------------------------------------------
# Boss Arena
# -------------------------------------------------------------------

func _on_boss_portal_entered():
	"""Player enters boss portal — load boss arena."""
	print("[Floor1] Entering boss arena...")
	
	# Transition to boss room
	_transition_to_room("boss")
	
	# Spawn Snotling King
	var boss_room = rooms.get("boss")
	if boss_room and boss_room.has_method("spawn_encounter"):
		boss_room.spawn_encounter()

# -------------------------------------------------------------------
# Floor Transition (Up to Floor 2)
# -------------------------------------------------------------------

func _on_floor_complete():
	"""Called when Snotling King is defeated."""
	_show_dialogue("The Tower", "The Snotling King falls.\nThe portal Up shimmers with new energy.")
	
	# Give boss rewards
	GameState.add_card_to_deck("goblin_snotling_king")  # Boss card
	GameState.gems += 20
	GameState.gems_changed.emit(GameState.gems)
	
	# Save progress
	GameState.save_game()
	
	# Show floor transition option
	_show_floor_transition_prompt()

func _show_floor_transition_prompt():
	"""Show prompt to ascend to next floor."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 2"
	prompt.position = Vector2(760, 600)
	prompt.size = Vector2(400, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)
	
	# Wait for interact key
	await get_tree().create_timer(0.5).timeout
	# The _input system will handle [S] press and trigger _ascend_to_next_floor

func _ascend_to_next_floor():
	"""Ascend to Floor 2."""
	print("[Floor1] Ascending to Floor 2...")
	AudioManager.play_sfx("floor_transition")
	get_tree().change_scene_to_file("res://scenes/Floor2.tscn")

# -------------------------------------------------------------------
# Input override for floor transition
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Check for shop close
	if shop_ui_active and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_shop()
		get_viewport().set_input_as_handled()
		return
	
	# Check for floor transition prompt
	var prompt = get_node_or_null("FloorTransitionPrompt")
	if prompt and event is InputEventKey and event.pressed:
		if event.keycode == KEY_S or event.keycode == KEY_SPACE:
			_ascend_to_next_floor()
			return
	
	# Otherwise use base class input
	super._input(event)

# -------------------------------------------------------------------
# Combat Override — Tutorial Card Check
# -------------------------------------------------------------------

func _on_combat_ended(victory: bool):
	"""Override to handle tutorial and boss."""
	super._on_combat_ended(victory)
	
	if not victory:
		return
	
	# Check if this was boss fight
	if current_room_id == "boss":
		_on_floor_complete()
		return
	
	# Check if all rooms cleared for boss unlock
	_on_check_boss_unlock()

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func is_boss_unlocked() -> bool:
	return _check_boss_unlock()

func get_current_room() -> Floor1RoomBase:
	var room = rooms.get(current_room_id)
	return room if room is Floor1RoomBase else null

func move_player_to_room(room_id: String):
	if room_id in rooms:
		_transition_to_room(room_id)
