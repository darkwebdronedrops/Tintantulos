extends CanvasLayer
class_name TitleScreen

# TitleScreen — Main menu for The Gearworks
# Background: bg_title_gearworks.png
# Options: New Game, Continue (if save exists), Quit

signal new_game_started
signal continue_game_started
signal quit_requested

# Visual nodes
var bg_sprite: Sprite2D
var title_label: Label
var subtitle_label: Label
var new_game_btn: Button
var continue_btn: Button
var quit_btn: Button

const TITLE_BG = "res://assets/sprites/ui_env/bg_title_gearworks.png"

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	
	# Play title music
	AudioManager.play_special("title")
	
	call_deferred("_build_title_screen")

func _build_title_screen():
	# Background sprite
	if ResourceLoader.exists(TITLE_BG):
		bg_sprite = Sprite2D.new()
		bg_sprite.texture = load(TITLE_BG)
		bg_sprite.position = Vector2(960, 540)  # Center for 1920x1080
		# Scale to cover screen (bg is 400x224, need to upscale)
		var scale_x = 1920.0 / bg_sprite.texture.get_size().x
		var scale_y = 1080.0 / bg_sprite.texture.get_size().y
		bg_sprite.scale = Vector2(scale_x, scale_y)
		add_child(bg_sprite)
	else:
		# Fallback: dark background
		var bg = ColorRect.new()
		bg.color = Color(0.05, 0.05, 0.08)
		bg.size = Vector2(1920, 1080)
		bg.position = Vector2.ZERO
		add_child(bg)
	
	# Dark overlay for text readability
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.4)
	overlay.size = Vector2(1920, 1080)
	overlay.position = Vector2.ZERO
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# Title
	title_label = Label.new()
	title_label.text = "THE TOWER OF TINTANTULOS"
	title_label.position = Vector2(560, 200)
	title_label.size = Vector2(800, 80)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "A Card-Based Dungeon Ascent"
	subtitle_label.position = Vector2(660, 290)
	subtitle_label.size = Vector2(600, 30)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(subtitle_label)
	
	# Menu container
	var menu_vbox = VBoxContainer.new()
	menu_vbox.position = Vector2(810, 400)
	menu_vbox.size = Vector2(300, 250)
	menu_vbox.add_theme_constant_override("separation", 16)
	add_child(menu_vbox)
	
	# Continue button (only if save exists)
	continue_btn = Button.new()
	continue_btn.text = "⚙ Continue"
	continue_btn.custom_minimum_size = Vector2(300, 50)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	continue_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	continue_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	continue_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	continue_btn.visible = GameState.has_save()
	continue_btn.pressed.connect(_on_continue)
	menu_vbox.add_child(continue_btn)
	
	# New Game button
	new_game_btn = Button.new()
	new_game_btn.text = "⚙ New Game"
	new_game_btn.custom_minimum_size = Vector2(300, 50)
	new_game_btn.add_theme_font_size_override("font_size", 18)
	new_game_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	new_game_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	new_game_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	new_game_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	new_game_btn.pressed.connect(_on_new_game)
	menu_vbox.add_child(new_game_btn)
	
	# Select Floor button (dev/test menu)
	var select_floor_btn = Button.new()
	select_floor_btn.text = "⚙ Select Floor"
	select_floor_btn.custom_minimum_size = Vector2(300, 50)
	select_floor_btn.add_theme_font_size_override("font_size", 18)
	select_floor_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	select_floor_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.7))
	select_floor_btn.add_theme_color_override("font_pressed_color", Color(0.5, 0.5, 0.3))
	select_floor_btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.2))
	select_floor_btn.pressed.connect(_on_select_floor)
	menu_vbox.add_child(select_floor_btn)
	
	# Quit button
	quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(300, 40)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	quit_btn.add_theme_color_override("font_hover_color", Color(0.7, 0.7, 0.8))
	quit_btn.add_theme_color_override("font_pressed_color", Color(0.3, 0.3, 0.4))
	quit_btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.35))
	quit_btn.pressed.connect(_on_quit)
	menu_vbox.add_child(quit_btn)
	
	# Version
	var version_label = Label.new()
	version_label.text = "v0.2.4"
	version_label.position = Vector2(20, 1040)
	version_label.size = Vector2(100, 20)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	add_child(version_label)
	
	# Version / credits
	var credits = Label.new()
	credits.text = "Torespar Studios"
	credits.position = Vector2(860, 1020)
	credits.size = Vector2(200, 20)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_font_size_override("font_size", 10)
	credits.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	add_child(credits)
	
	# Floor select panel (hidden by default)
	_build_floor_select_panel()

func _on_new_game():
	visible = false
	AudioManager.stop_music()
	GameState.new_game()
	# Load Floor 1 directly instead of just emitting signal
	get_tree().change_scene_to_file("res://scenes/Floor1.tscn")
	new_game_started.emit()

func _on_continue():
	if GameState.has_save():
		visible = false
		AudioManager.stop_music()
		GameState.load_game()
		# Load the saved floor
		var floor_scene = "res://scenes/Floor%d.tscn" % GameState.current_floor
		get_tree().change_scene_to_file(floor_scene)
		continue_game_started.emit()

func _on_quit():
	quit_requested.emit()
	get_tree().quit()

func show_title():
	visible = true
	# Update continue button visibility in case save was deleted/created
	if continue_btn:
		continue_btn.visible = GameState.has_save()

# Floor Select Panel
var floor_select_panel: Panel
var floor_select_buttons: Array[Button] = []

const FLOOR_DATA = {
	1: {"name": "Floor 1: The Portal Room", "scene": "res://scenes/Floor1.tscn", "status": "ready"},
	2: {"name": "Floor 2: The Fungal Cavern", "scene": "res://scenes/Floor2.tscn", "status": "ready"},
	3: {"name": "Floor 3: The Gearworks", "scene": "res://scenes/Floor3.tscn", "status": "ready"},
	4: {"name": "Floor 4: Curio Bazaar", "scene": "res://scenes/Floor4.tscn", "status": "ready"},
	5: {"name": "Floor 5: Airship Docks", "scene": "res://scenes/Floor5.tscn", "status": "ready"},
	6: {"name": "Floor 6: Lunar University", "scene": "res://scenes/Floor6.tscn", "status": "ready"},
	7: {"name": "Floor 7: Broken Pact", "scene": "res://scenes/Floor7.tscn", "status": "ready"},
	8: {"name": "Floor 8: Kami Crucible", "scene": "res://scenes/Floor8.tscn", "status": "ready"},
	9: {"name": "Floor 9: Bone Forges", "scene": "res://scenes/Floor9.tscn", "status": "ready"},
	10: {"name": "Floor 10: The Dragon", "scene": "res://scenes/Floor10.tscn", "status": "ready"},
}

func _build_floor_select_panel():
	"""Build the floor selection panel (hidden by default)"""
	floor_select_panel = Panel.new()
	floor_select_panel.name = "FloorSelectPanel"
	floor_select_panel.position = Vector2(560, 180)
	floor_select_panel.size = Vector2(800, 700)
	floor_select_panel.visible = false
	
	# Panel background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 0.95)
	bg.size = Vector2(800, 700)
	floor_select_panel.add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "SELECT FLOOR"
	title.position = Vector2(0, 20)
	title.size = Vector2(800, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	floor_select_panel.add_child(title)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.position = Vector2(20, 20)
	back_btn.size = Vector2(100, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.pressed.connect(_on_floor_select_back)
	floor_select_panel.add_child(back_btn)
	
	# Floor grid
	var grid = GridContainer.new()
	grid.position = Vector2(50, 100)
	grid.size = Vector2(700, 520)
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 12)
	floor_select_panel.add_child(grid)
	
	# Create button for each floor
	for floor_num in range(1, 11):
		var data = FLOOR_DATA[floor_num]
		var btn = Button.new()
		
		var status_icon = ""
		var status_color = Color(1, 1, 1)
		match data.status:
			"ready":
				status_icon = "🟢"
				status_color = Color(0.6, 1.0, 0.6)
			"placeholder":
				status_icon = "🟡"
				status_color = Color(1.0, 1.0, 0.6)
			"design":
				status_icon = "⚫"
				status_color = Color(0.5, 0.5, 0.5)
		
		btn.text = "%s %d. %s" % [status_icon, floor_num, data.name]
		btn.custom_minimum_size = Vector2(340, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", status_color)
		
		# Only enable if floor is ready
		if data.status == "ready":
			btn.pressed.connect(_on_floor_selected.bind(floor_num))
		else:
			btn.disabled = true
			btn.tooltip_text = "Not yet implemented"
		
		grid.add_child(btn)
		floor_select_buttons.append(btn)
	
	# Status legend
	var legend = Label.new()
	legend.text = "🟢 Playable  |  🟡 Placeholder  |  ⚫ Design Only"
	legend.position = Vector2(0, 640)
	legend.size = Vector2(800, 30)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_font_size_override("font_size", 11)
	legend.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	floor_select_panel.add_child(legend)
	
	add_child(floor_select_panel)

func _on_select_floor():
	"""Show floor selection panel"""
	if floor_select_panel:
		floor_select_panel.visible = true
		# Hide main menu buttons
		if continue_btn:
			continue_btn.visible = false
		new_game_btn.visible = false
		quit_btn.visible = false

func _on_floor_select_back():
	"""Return to main menu"""
	if floor_select_panel:
		floor_select_panel.visible = false
	# Show main menu buttons
	if continue_btn:
		continue_btn.visible = GameState.has_save()
	new_game_btn.visible = true
	quit_btn.visible = true

func _on_floor_selected(floor_num: int):
	"""Load the selected floor"""
	var data = FLOOR_DATA[floor_num]
	if data.scene.is_empty():
		push_warning("Floor %d has no scene path" % floor_num)
		return
	
	print("[TitleScreen] Loading Floor %d: %s" % [floor_num, data.scene])
	
	# Set current floor in GameState
	GameState.set_current_floor(floor_num)
	
	# Hide title screen
	visible = false
	if floor_select_panel:
		floor_select_panel.visible = false
	
	# Stop title music — floor will start its own ambient
	AudioManager.stop_music()
	
	# Use loading screen for Floor 2
	if floor_num == 2:
		var loading_screen = LoadingScreen.new()
		add_child(loading_screen)
		loading_screen.show_for_floor(2)
		await loading_screen.loading_ready
		loading_screen.transition_to(data.scene, 2.0)
	else:
		# Direct scene change for other floors
		get_tree().change_scene_to_file(data.scene)

