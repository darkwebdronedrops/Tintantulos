class_name IntroCinematic
extends Control

# ===================================================================
# INTRO CINEMATIC — Approach the Tower
# ===================================================================
# Short cinematic: player approaches the Tower.
# Music + sequential text overlays. Ends with prompt to fight the Door.
# Skippable with any key/click.
# ===================================================================

signal cinematic_ended

# Cinematic state
var current_step: int = 0
var step_timer: float = 0.0
var is_active: bool = false
var skip_requested: bool = false

# UI elements
var background: ColorRect
var tower_sprite: Sprite2D
var text_label: Label
var prompt_label: Label
var fade_rect: ColorRect
var vignette: ColorRect

# Cinematic steps: [text, duration, fade_in_time]
var cinematic_steps: Array = [
	{"text": "", "duration": 1.5, "fade": 1.0},  # Black screen
	{"text": "I don't remember how I got here.", "duration": 3.0, "fade": 0.5},
	{"text": "One moment I was... somewhere else.\nNow I'm standing before this.", "duration": 3.5, "fade": 0.5},
	{"text": "The Tower of Tintantulos.", "duration": 3.0, "fade": 0.5},
	{"text": "It shouldn't exist. But it does.\nAnd it's calling me.", "duration": 3.5, "fade": 0.5},
	{"text": "", "duration": 1.0, "fade": 0.5},  # Brief pause
	{"text": "The Door is waiting.", "duration": 2.5, "fade": 0.3},
]

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	_build_scene()
	start_cinematic()

func _build_scene():
	# Full-screen black background
	background = ColorRect.new()
	background.color = Color(0.02, 0.02, 0.04)
	background.size = Vector2(1280, 720)
	add_child(background)
	
	# Tower silhouette (placeholder: dark geometric shape)
	tower_sprite = Sprite2D.new()
	tower_sprite.position = Vector2(640, 360)
	# Use a simple polygon as placeholder
	var tower_poly = Polygon2D.new()
	tower_poly.polygon = PackedVector2Array([
		Vector2(-40, 200),   # Bottom left
		Vector2(-25, -100),  # Mid left
		Vector2(-10, -180),  # Upper left
		Vector2(0, -220),    # Peak
		Vector2(10, -180),   # Upper right
		Vector2(25, -100),   # Mid right
		Vector2(40, 200),    # Bottom right
	])
	tower_poly.color = Color(0.1, 0.08, 0.15, 0.9)
	tower_sprite.add_child(tower_poly)
	add_child(tower_sprite)
	
	# Vignette effect (dark edges)
	vignette = ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.4)
	vignette.size = Vector2(1280, 720)
	add_child(vignette)
	
	# Text display
	text_label = Label.new()
	text_label.position = Vector2(140, 520)
	text_label.size = Vector2(1000, 80)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	text_label.add_theme_constant_override("shadow_outline_size", 4)
	text_label.modulate.a = 0.0
	add_child(text_label)
	
	# Skip prompt
	prompt_label = Label.new()
	prompt_label.text = "[Press any key to skip]"
	prompt_label.position = Vector2(540, 680)
	prompt_label.size = Vector2(200, 25)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 11)
	prompt_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	prompt_label.modulate.a = 0.6
	add_child(prompt_label)
	
	# Fade to black overlay
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.size = Vector2(1280, 720)
	add_child(fade_rect)

func start_cinematic():
	is_active = true
	current_step = 0
	step_timer = 0.0
	# Play ambient music
	AudioManager.play_special("title")
	# Start fade out from black
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.5)
	print("[IntroCinematic] Starting cinematic")

func _input(event: InputEvent):
	if not is_active:
		return
	
	# Skip on any input
	if event is InputEventKey and event.pressed:
		_skip_cinematic()
	elif event is InputEventMouseButton and event.pressed:
		_skip_cinematic()

func _skip_cinematic():
	if skip_requested:
		return
	skip_requested = true
	print("[IntroCinematic] Skipped by player")
	_end_cinematic()

func _process(delta: float):
	if not is_active:
		return
	
	step_timer += delta
	
	if current_step < cinematic_steps.size():
		var step = cinematic_steps[current_step]
		
		# Fade in text
		if step_timer <= step.get("fade", 0.5):
			var fade_progress = step_timer / step.get("fade", 0.5)
			text_label.modulate.a = fade_progress
			text_label.text = step.get("text", "")
		
		# Hold text
		elif step_timer <= step.duration:
			text_label.modulate.a = 1.0
		
		# Fade out and advance
		else:
			var fade_out_time = 0.5
			var fade_progress = (step_timer - step.duration) / fade_out_time
			text_label.modulate.a = max(0.0, 1.0 - fade_progress)
			
			if fade_progress >= 1.0:
				current_step += 1
				step_timer = 0.0
				
				# Check if cinematic is complete
				if current_step >= cinematic_steps.size():
					_end_cinematic()
	
	# Tower slowly grows (approach effect)
	if tower_sprite:
		var max_scale = 2.0
		var current_scale = 0.5 + (float(current_step) / cinematic_steps.size()) * (max_scale - 0.5)
		tower_sprite.scale = Vector2(current_scale, current_scale)
		# Slight upward movement (camera tilting up)
		tower_sprite.position.y = 360 - (float(current_step) / cinematic_steps.size()) * 80

func _end_cinematic():
	is_active = false
	cinematic_ended.emit()
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.tween_callback(_transition_to_tutorial)

func _transition_to_tutorial():
	# Load Floor 1 (tutorial mode will trigger via GameState.is_first_run)
	get_tree().change_scene_to_file("res://scenes/Floor1.tscn")
