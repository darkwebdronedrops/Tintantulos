extends CanvasLayer
class_name PauseMenu

# PauseMenu — In-game pause overlay
# Resume, Save Game, Settings, Quit to Title

signal resume_requested
signal settings_requested
signal quit_to_title_requested

# Visual nodes
var panel: PanelContainer

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	call_deferred("_build_menu")

func _build_menu():
	# Background dim
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.8)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	# Center panel
	panel = PanelContainer.new()
	panel.size = Vector2(400, 350)
	panel.position = Vector2(760, 365)
	add_child(panel)
	
	# Panel background sprite if available
	var panel_sprite = "res://assets/sprites/ui_env/ui_hud_panel.png"
	if ResourceLoader.exists(panel_sprite):
		var sprite = Sprite2D.new()
		sprite.texture = load(panel_sprite)
		sprite.scale = Vector2(400.0 / sprite.texture.get_size().x, 350.0 / sprite.texture.get_size().y)
		sprite.centered = false
		panel.add_child(sprite)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(360, 310)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Resume
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(300, 45)
	resume_btn.add_theme_font_size_override("font_size", 16)
	resume_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	resume_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	resume_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	resume_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)
	
	# Save
	var save_btn = Button.new()
	save_btn.text = "💾 Save Game"
	save_btn.custom_minimum_size = Vector2(300, 45)
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	save_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	save_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	save_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	save_btn.pressed.connect(_on_save)
	vbox.add_child(save_btn)
	
	# Settings
	var settings_btn = Button.new()
	settings_btn.text = "⚙ Settings"
	settings_btn.custom_minimum_size = Vector2(300, 45)
	settings_btn.add_theme_font_size_override("font_size", 16)
	settings_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	settings_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	settings_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	settings_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	settings_btn.pressed.connect(_on_settings)
	vbox.add_child(settings_btn)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)
	
	# Quit to title
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.custom_minimum_size = Vector2(300, 40)
	quit_btn.add_theme_font_size_override("font_size", 14)
	quit_btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	quit_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.6))
	quit_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.3, 0.3))
	quit_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.3, 0.3))
	quit_btn.pressed.connect(_on_quit_to_title)
	vbox.add_child(quit_btn)

func show_pause():
	visible = true

func hide_pause():
	visible = false

func _on_resume():
	hide_pause()
	resume_requested.emit()

func _on_save():
	GameState.save_game()
	# Show brief confirmation
	var notif = Label.new()
	notif.text = "💾 Game Saved!"
	notif.position = Vector2(860, 720)
	notif.size = Vector2(200, 30)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

func _on_settings():
	hide_pause()
	settings_requested.emit()

func _on_quit_to_title():
	hide_pause()
	quit_to_title_requested.emit()

func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_resume()
		get_viewport().set_input_as_handled()
