class_name IntroCinematic
extends Control

# ===================================================================
# INTRO CINEMATIC — Approach the Tower
# ===================================================================
# Three painted plates crossfade as the player approaches:
#   1. cine_tower_far.png    — tower on the horizon
#   2. cine_tower_near.png   — looming base, gold door
#   3. cine_ground_path.png  — the path at ground level
# Narrative text over. Skippable (any key / click). Ends in Floor 1.
# ===================================================================

signal cinematic_ended

const PLATE_FAR := "res://assets/sprites/tutorial/cine_tower_far.png"
const PLATE_NEAR := "res://assets/sprites/tutorial/cine_tower_near.png"
const PLATE_GROUND := "res://assets/sprites/tutorial/cine_ground_path.png"

var plates: Array[TextureRect] = []
var current_plate: int = -1
var current_step: int = 0
var step_timer: float = 0.0
var is_active: bool = false
var skip_requested: bool = false

var text_label: Label
var prompt_label: Label
var fade_rect: ColorRect

# [text, duration, plate_index]
var steps: Array = [
	{"text": "", "duration": 1.6, "plate": 0},
	{"text": "I don't remember how I got here.", "duration": 3.2, "plate": 0},
	{"text": "One moment I was... somewhere else.\nNow I'm standing before this.", "duration": 3.6, "plate": 0},
	{"text": "The Tower of Tintantulos.", "duration": 3.2, "plate": 1},
	{"text": "It shouldn't exist. But it does.\nAnd it's calling me.", "duration": 3.6, "plate": 1},
	{"text": "", "duration": 1.0, "plate": 2},
	{"text": "The Door is waiting.", "duration": 2.6, "plate": 2},
]

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	start_cinematic()

func _build():
	var plate_paths := [PLATE_FAR, PLATE_NEAR, PLATE_GROUND]
	for i in range(plate_paths.size()):
		var tr := TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if ResourceLoader.exists(plate_paths[i]):
			tr.texture = load(plate_paths[i])
		tr.modulate.a = 0.0
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		plates.append(tr)

	text_label = Label.new()
	text_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	text_label.position = Vector2(-500, -190)
	text_label.size = Vector2(1000, 90)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 21)
	text_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78))
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	text_label.add_theme_constant_override("shadow_offset_x", 2)
	text_label.add_theme_constant_override("shadow_offset_y", 2)
	text_label.modulate.a = 0.0
	add_child(text_label)

	prompt_label = Label.new()
	prompt_label.text = "[ press any key to skip ]"
	prompt_label.position = Vector2(540, 690)
	prompt_label.size = Vector2(200, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 11)
	prompt_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	prompt_label.modulate.a = 0.65
	add_child(prompt_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

func start_cinematic():
	is_active = true
	AudioManager.play_special("title")
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.6)
	print("[IntroCinematic] Starting — %d steps" % steps.size())

func _input(event: InputEvent):
	if not is_active or skip_requested:
		return
	if (event is InputEventKey and event.pressed and not event.echo) \
	or (event is InputEventMouseButton and event.pressed):
		_skip()

func _skip():
	skip_requested = true
	print("[IntroCinematic] Skipped")
	_end()

func _process(delta: float):
	if not is_active:
		return
	step_timer += delta

	if current_step >= steps.size():
		_end()
		return

	var step: Dictionary = steps[current_step]
	_ensure_plate(step.get("plate", 0))

	var hold_end: float = step.duration
	var fade_in: float = min(0.6, step.duration * 0.25)
	var fade_out: float = 0.6

	if step_timer <= fade_in:
		text_label.text = step.get("text", "")
		text_label.modulate.a = step_timer / fade_in
	elif step_timer <= hold_end:
		text_label.modulate.a = 1.0
	elif step_timer <= hold_end + fade_out:
		text_label.modulate.a = max(0.0, 1.0 - (step_timer - hold_end) / fade_out)
	else:
		current_step += 1
		step_timer = 0.0

func _ensure_plate(idx: int):
	if idx == current_plate or idx < 0 or idx >= plates.size():
		return
	# slow push-in on the incoming plate
	var tr := plates[idx]
	tr.pivot_offset = tr.size / 2.0
	tr.scale = Vector2(1.0, 1.0)
	var kb := create_tween()
	kb.tween_property(tr, "scale", Vector2(1.09, 1.09), 9.0).set_trans(Tween.TRANS_LINEAR)
	# crossfade
	var tw := create_tween()
	for i in range(plates.size()):
		if i == idx:
			tw.tween_property(plates[i], "modulate:a", 1.0, 1.4)
		else:
			tw.parallel().tween_property(plates[i], "modulate:a", 0.0, 1.4)
	current_plate = idx

func _end():
	if not is_active:
		return
	is_active = false
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	tween.tween_callback(_go)

func _go():
	cinematic_ended.emit()
	get_tree().change_scene_to_file("res://scenes/Floor1.tscn")
