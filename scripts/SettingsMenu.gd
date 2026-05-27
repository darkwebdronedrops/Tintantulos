extends CanvasLayer
class_name SettingsMenu

# SettingsMenu — In-game settings overlay
# Volume (master/music/sfx), brightness, fullscreen, vsync
# All values persist to GameState for save/load

signal settings_closed

# Settings values (persisted)
var master_volume: float = 1.0    # 0.0 - 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var text_speed: float = 1.0       # 0.1 - 2.0 (multiplier for text display speed)
var brightness: float = 1.0       # 0.3 - 1.5
var fullscreen: bool = false
var vsync: bool = true

# UI references (for updating visuals)
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var text_speed_slider: HSlider
var brightness_slider: HSlider
var fullscreen_btn: CheckBox
var vsync_btn: CheckBox

# Brightness overlay (created dynamically, applied to entire viewport)
var brightness_overlay: ColorRect

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_load_settings()
	call_deferred("_build_menu")
	call_deferred("_apply_brightness")

func _build_menu():
	# Background dim
	var bg = ColorRect.new()
	bg.name = "SettingsBG"
	bg.color = Color(0.05, 0.05, 0.08, 0.9)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	# Center panel
	var panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.size = Vector2(480, 520)
	panel.position = Vector2(720, 280)
	add_child(panel)
	
	# Panel background sprite if available
	var panel_sprite = "res://assets/sprites/ui_env/ui_hud_panel.png"
	if ResourceLoader.exists(panel_sprite):
		var sprite = Sprite2D.new()
		sprite.texture = load(panel_sprite)
		sprite.scale = Vector2(480.0 / sprite.texture.get_size().x, 520.0 / sprite.texture.get_size().y)
		sprite.centered = false
		panel.add_child(sprite)
	
	var vbox = VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.add_theme_constant_override("separation", 10)
	vbox.position = Vector2(25, 20)
	vbox.size = Vector2(430, 480)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚙ SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	vbox.add_child(title)
	
	# Separator
	var sep = ColorRect.new()
	sep.color = Color(0.4, 0.35, 0.3, 0.5)
	sep.custom_minimum_size = Vector2(400, 2)
	vbox.add_child(sep)
	
	# --- AUDIO SECTION ---
	var audio_title = Label.new()
	audio_title.text = "🔊 AUDIO"
	audio_title.add_theme_font_size_override("font_size", 14)
	audio_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(audio_title)
	
	# Master Volume
	master_slider = _create_slider_row(vbox, "Master Volume", master_volume)
	master_slider.value_changed.connect(_on_master_volume_changed)
	
	# Music Volume
	music_slider = _create_slider_row(vbox, "Music Volume", music_volume)
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	# SFX Volume
	sfx_slider = _create_slider_row(vbox, "SFX Volume", sfx_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# --- GAMEPLAY SECTION ---
	var gameplay_title = Label.new()
	gameplay_title.text = "🎮 GAMEPLAY"
	gameplay_title.add_theme_font_size_override("font_size", 14)
	gameplay_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(gameplay_title)
	
	# Text Speed — custom slider with "x" display
	var text_hbox = HBoxContainer.new()
	text_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(text_hbox)
	
	var text_label = Label.new()
	text_label.text = "Text Speed"
	text_label.custom_minimum_size = Vector2(130, 0)
	text_label.add_theme_font_size_override("font_size", 12)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	text_hbox.add_child(text_label)
	
	text_speed_slider = HSlider.new()
	text_speed_slider.min_value = 0.1
	text_speed_slider.max_value = 2.0
	text_speed_slider.step = 0.1
	text_speed_slider.value = text_speed
	text_speed_slider.custom_minimum_size = Vector2(200, 20)
	text_hbox.add_child(text_speed_slider)
	
	var text_value_label = Label.new()
	text_value_label.text = "%.1fx" % text_speed
	text_value_label.custom_minimum_size = Vector2(50, 0)
	text_value_label.add_theme_font_size_override("font_size", 12)
	text_value_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	text_hbox.add_child(text_value_label)
	
	text_speed_slider.value_changed.connect(func(v):
		text_value_label.text = "%.1fx" % v
	)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	
	# Spacer
	var spacer1b = Control.new()
	spacer1b.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1b)
	
	# --- GRAPHICS SECTION ---
	var gfx_title = Label.new()
	gfx_title.text = "🎨 GRAPHICS"
	gfx_title.add_theme_font_size_override("font_size", 14)
	gfx_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(gfx_title)
	
	# Brightness
	brightness_slider = _create_slider_row(vbox, "Brightness", brightness, 0.3, 1.5)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	
	# Fullscreen
	fullscreen_btn = _create_checkbox_row(vbox, "Fullscreen", fullscreen)
	fullscreen_btn.toggled.connect(_on_fullscreen_toggled)
	
	# VSync
	vsync_btn = _create_checkbox_row(vbox, "VSync", vsync)
	vsync_btn.toggled.connect(_on_vsync_toggled)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)
	
	# --- BOTTOM BAR ---
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(bottom_hbox)
	
	# Reset to defaults
	var reset_btn = Button.new()
	reset_btn.text = "Reset to Defaults"
	reset_btn.custom_minimum_size = Vector2(180, 40)
	reset_btn.add_theme_font_size_override("font_size", 12)
	reset_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	reset_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	reset_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	reset_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	reset_btn.pressed.connect(_on_reset_defaults)
	bottom_hbox.add_child(reset_btn)
	
	# Spacer
	var hspacer = Control.new()
	hspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(hspacer)
	
	# Back / Close
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	back_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	back_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	back_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	back_btn.pressed.connect(_on_back)
	bottom_hbox.add_child(back_btn)

func _create_slider_row(parent: VBoxContainer, label_text: String, initial: float, min_val: float = 0.0, max_val: float = 1.0) -> HSlider:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(130, 0)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.01
	slider.value = initial
	slider.custom_minimum_size = Vector2(200, 20)
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = "%d%%" % int(initial * 100)
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	value_label.name = label_text.replace(" ", "") + "ValueLabel"
	hbox.add_child(value_label)
	
	# Update value label when slider moves
	slider.value_changed.connect(func(v):
		value_label.text = "%d%%" % int(v * 100) if max_val <= 1.0 else "%d%%" % int((v / max_val) * 100)
	)
	
	return slider

func _create_checkbox_row(parent: VBoxContainer, label_text: String, initial: bool) -> CheckBox:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(130, 0)
	hbox.add_child(spacer)
	
	var checkbox = CheckBox.new()
	checkbox.text = label_text
	checkbox.button_pressed = initial
	checkbox.add_theme_font_size_override("font_size", 12)
	checkbox.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	hbox.add_child(checkbox)
	
	return checkbox

# ============================================================================
# HANDLERS
# ============================================================================

func _on_master_volume_changed(value: float):
	master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	AudioManager.set_volume("master", value)
	_save_settings()

func _on_music_volume_changed(value: float):
	music_volume = value
	# Music bus — created if it doesn't exist
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioManager.set_volume("music", value)
	_save_settings()

func _on_sfx_volume_changed(value: float):
	sfx_volume = value
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioManager.set_volume("sfx", value)
	_save_settings()

func _on_text_speed_changed(value: float):
	text_speed = value
	GameState.text_speed = value
	_save_settings()

func _on_brightness_changed(value: float):
	brightness = value
	_apply_brightness()
	_save_settings()

func _apply_brightness():
	"""Apply brightness by modulating a fullscreen ColorRect overlay."""
	if brightness_overlay == null or not is_instance_valid(brightness_overlay):
		brightness_overlay = ColorRect.new()
		brightness_overlay.name = "BrightnessOverlay"
		brightness_overlay.color = Color(0, 0, 0, 0)
		brightness_overlay.size = Vector2(1920, 1080)
		brightness_overlay.position = Vector2.ZERO
		brightness_overlay.z_index = 1000  # Above everything
		brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks
		# Add to root so it persists across scenes
		if get_tree() and get_tree().root:
			get_tree().root.add_child(brightness_overlay)
			return  # First creation — brightness will be set on next call
	
	# brightness 1.0 = no overlay
	# brightness < 1.0 = darken (black overlay with alpha)
	# brightness > 1.0 = brighten (white overlay with alpha, additive-ish)
	if brightness <= 1.0:
		brightness_overlay.color = Color(0, 0, 0, 1.0 - brightness)
	else:
		var over = (brightness - 1.0) * 0.5  # Cap brightening intensity
		brightness_overlay.color = Color(1, 1, 1, over)

func _on_fullscreen_toggled(enabled: bool):
	fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()

func _on_vsync_toggled(enabled: bool):
	vsync = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)
	_save_settings()

func _on_reset_defaults():
	master_volume = 1.0
	music_volume = 1.0
	sfx_volume = 1.0
	text_speed = 1.0
	brightness = 1.0
	fullscreen = false
	vsync = true
	
	master_slider.value = 1.0
	music_slider.value = 1.0
	sfx_slider.value = 1.0
	text_speed_slider.value = 1.0
	brightness_slider.value = 1.0
	fullscreen_btn.button_pressed = false
	vsync_btn.button_pressed = true
	
	AudioManager.set_volume("master", 1.0)
	AudioManager.set_volume("music", 1.0)
	AudioManager.set_volume("sfx", 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	_apply_brightness()
	_save_settings()

func _on_back():
	visible = false
	settings_closed.emit()

# ============================================================================
# PERSISTENCE
# ============================================================================

func _save_settings():
	var data = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"text_speed": text_speed,
		"brightness": brightness,
		"fullscreen": fullscreen,
		"vsync": vsync,
	}
	# Save to user://settings.json
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if not file:
		return  # Use defaults
	
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		return
	
	var data = json.get_data()
	if data is Dictionary:
		master_volume = data.get("master_volume", 1.0)
		music_volume = data.get("music_volume", 1.0)
		sfx_volume = data.get("sfx_volume", 1.0)
		text_speed = data.get("text_speed", 1.0)
		brightness = data.get("brightness", 1.0)
		fullscreen = data.get("fullscreen", false)
		vsync = data.get("vsync", true)
		
		# Apply on load — sync AudioManager
		AudioManager.set_volume("master", master_volume)
		AudioManager.set_volume("music", music_volume)
		AudioManager.set_volume("sfx", sfx_volume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if not vsync:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func show_settings():
	visible = true
	_load_settings()
	# Refresh UI values
	master_slider.value = master_volume
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	text_speed_slider.value = text_speed
	brightness_slider.value = brightness
	fullscreen_btn.button_pressed = fullscreen
	vsync_btn.button_pressed = vsync

func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()

# ============================================================================
# UTILITY
# ============================================================================

static func linear_to_db(linear: float) -> float:
	"""Convert linear volume (0.0-1.0) to decibels."""
	if linear <= 0.0:
		return -80.0  # Mute
	return 20.0 * log(linear) / log(10.0)
