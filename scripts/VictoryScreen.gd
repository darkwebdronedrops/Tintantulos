extends CanvasLayer
class_name VictoryScreen

# VictoryScreen — "YOU ESCAPED THE TOWER OF TINTANTULOS"
# Shows when boss is defeated. Stats + return to title.

signal return_to_title_requested
signal new_game_plus_requested

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	visible = false

func show_victory():
	visible = true
	_build_screen()

func _build_screen():
	for child in get_children():
		child.queue_free()
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.95)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "THE MACHINE STOPS"
	title.position = Vector2(560, 200)
	title.size = Vector2(800, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "You have escaped the Tower of Tintantulos."
	subtitle.position = Vector2(560, 290)
	subtitle.size = Vector2(800, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(subtitle)
	
	# Stats
	var stats = Label.new()
	var cleared = GameState.get_cleared_room_count()
	stats.text = "Rooms cleared: %d/12\nGems collected: %d\nGear Devil Tokens: %d\nDeck size: %d\nBosses defeated: %d" % [
		cleared, GameState.gems, GameState.get_gear_devil_token_count(),
		GameState.player_deck.size(), GameState.defeated_bosses.size()
	]
	stats.position = Vector2(660, 360)
	stats.size = Vector2(600, 150)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 16)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	add_child(stats)
	
	# Survivor Choice Section
	var choice_label = Label.new()
	choice_label.text = "Choose one card to carry into the next climb:"
	choice_label.position = Vector2(560, 520)
	choice_label.size = Vector2(800, 30)
	choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_label.add_theme_font_size_override("font_size", 14)
	choice_label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.0))
	add_child(choice_label)
	
	var survivor_container = HBoxContainer.new()
	survivor_container.name = "SurvivorContainer"
	survivor_container.position = Vector2(460, 555)
	survivor_container.size = Vector2(1000, 80)
	survivor_container.alignment = BoxContainer.ALIGNMENT_CENTER
	survivor_container.add_theme_constant_override("separation", 12)
	add_child(survivor_container)
	
	var chosen_survivor: String = ""
	
	# Build deck choice buttons
	var deck_data = GameState.get_deck_card_data()
	for card in deck_data:
		var btn = Button.new()
		var is_dragon = card.faction == "Dragon"
		var prefix = "★ " if is_dragon else ""
		btn.text = "%s%s (%s)" % [prefix, card.card_name, card.faction]
		btn.custom_minimum_size = Vector2(140, 50)
		btn.add_theme_font_size_override("font_size", 11)
		if is_dragon:
			btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		btn.pressed.connect(func():
			chosen_survivor = card.id
			# Mark chosen card
			CardDB.mark_card_survivor(card.id)
			# Update button visuals
			for b in survivor_container.get_children():
				b.disabled = (b != btn)
				if b == btn:
					b.text = "✓ " + b.text
		)
		survivor_container.add_child(btn)
	
	# Buttons
	var btn_vbox = VBoxContainer.new()
	btn_vbox.position = Vector2(810, 660)
	btn_vbox.size = Vector2(300, 150)
	btn_vbox.add_theme_constant_override("separation", 16)
	add_child(btn_vbox)
	
	var ngp_btn = Button.new()
	ngp_btn.text = "⚙ New Game+"
	ngp_btn.custom_minimum_size = Vector2(300, 50)
	ngp_btn.add_theme_font_size_override("font_size", 18)
	ngp_btn.pressed.connect(_on_new_game_plus)
	btn_vbox.add_child(ngp_btn)
	
	var title_btn = Button.new()
	title_btn.text = "Return to Title"
	title_btn.custom_minimum_size = Vector2(300, 45)
	title_btn.add_theme_font_size_override("font_size", 16)
	title_btn.pressed.connect(_on_return_title)
	btn_vbox.add_child(title_btn)

func _on_new_game_plus():
	# Keep deck and gems, reset rooms
	GameState.new_game()
	get_tree().paused = false
	new_game_plus_requested.emit()
	visible = false

func _on_return_title():
	get_tree().paused = false
	return_to_title_requested.emit()
	visible = false
