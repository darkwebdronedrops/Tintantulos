extends CanvasLayer
class_name TutorialOverlay

# TutorialOverlay — Dark fantasy tutorial overlay
# Blocks all game input while the tutorial is active.

signal step_advance_requested
signal skip_requested

@onready var bg: ColorRect
@onready var panel: NinePatchRect
@onready var step_counter: Label
@onready var text_label: Label
@onready var continue_btn: TextureButton
@onready var skip_btn: TextureButton

var _current_step: int = 0

const PANEL_WIDTH: float = 700.0
const PANEL_HEIGHT: float = 400.0
const BODY_FONT_SIZE: int = 22
const BUTTON_FONT_SIZE: int = 18
const COUNTER_FONT_SIZE: int = 16

func _ready():
	layer = 100
	visible = false
	_create_ui()

func _create_ui():
	# Full-screen dark background that blocks input
	bg = ColorRect.new()
	bg.name = "Background"
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0, 0, 0, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Center panel using NinePatchRect (matches CombatUI style)
	panel = NinePatchRect.new()
	panel.name = "Panel"
	panel.position = Vector2((1280 - PANEL_WIDTH) / 2, (720 - PANEL_HEIGHT) / 2)
	panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	var panel_tex = load("res://assets/sprites/ui/ui_panel_bg.png")
	if panel_tex:
		panel.texture = panel_tex
		panel.patch_margin_left = 20
		panel.patch_margin_right = 20
		panel.patch_margin_top = 20
		panel.patch_margin_bottom = 20
	add_child(panel)
	
	# Solid dark background behind panel content
	var panel_bg = ColorRect.new()
	panel_bg.name = "PanelBG"
	panel_bg.anchor_right = 1.0
	panel_bg.anchor_bottom = 1.0
	panel_bg.color = Color(0.06, 0.06, 0.10, 0.95)
	panel.add_child(panel_bg)
	panel.move_child(panel_bg, 0)
	
	# Step counter at top
	step_counter = Label.new()
	step_counter.name = "StepCounter"
	step_counter.position = Vector2(0, 16)
	step_counter.size = Vector2(PANEL_WIDTH, 28)
	step_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	step_counter.add_theme_font_size_override("font_size", COUNTER_FONT_SIZE)
	step_counter.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	step_counter.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	step_counter.add_theme_constant_override("font_outline_size", 2)
	panel.add_child(step_counter)
	
	# Tutorial text (main body)
	text_label = Label.new()
	text_label.name = "TutorialText"
	text_label.position = Vector2(40, 60)
	text_label.size = Vector2(PANEL_WIDTH - 80, 240)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	text_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	text_label.add_theme_constant_override("font_outline_size", 3)
	text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	text_label.add_theme_constant_override("font_shadow_offset_x", 3)
	text_label.add_theme_constant_override("font_shadow_offset_y", 3)
	panel.add_child(text_label)
	
	# Continue button (steps 1-7)
	continue_btn = TextureButton.new()
	continue_btn.name = "ContinueButton"
	continue_btn.position = Vector2((PANEL_WIDTH - 180) / 2, PANEL_HEIGHT - 70)
	continue_btn.size = Vector2(180, 44)
	var btn_tex = load("res://assets/sprites/ui/ui_button_bg.png")
	var btn_pressed = load("res://assets/sprites/ui/ui_button_bg_pressed.png")
	if btn_tex:
		continue_btn.texture_normal = btn_tex
	if btn_pressed:
		continue_btn.texture_pressed = btn_pressed
	continue_btn.pressed.connect(_on_continue_pressed)
	panel.add_child(continue_btn)
	
	# Continue button label
	var btn_label = Label.new()
	btn_label.name = "ContinueLabel"
	btn_label.anchor_right = 1.0
	btn_label.anchor_bottom = 1.0
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_label.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	btn_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	btn_label.add_theme_constant_override("font_outline_size", 2)
	continue_btn.add_child(btn_label)
	btn_label.text = "Continue"
	
	# Skip button (small, bottom-right corner)
	skip_btn = TextureButton.new()
	skip_btn.name = "SkipButton"
	skip_btn.position = Vector2(PANEL_WIDTH - 90, PANEL_HEIGHT - 40)
	skip_btn.size = Vector2(80, 28)
	if btn_tex:
		skip_btn.texture_normal = btn_tex
	if btn_pressed:
		skip_btn.texture_pressed = btn_pressed
	skip_btn.pressed.connect(_on_skip_pressed)
	panel.add_child(skip_btn)
	
	var skip_label = Label.new()
	skip_label.name = "SkipLabel"
	skip_label.anchor_right = 1.0
	skip_label.anchor_bottom = 1.0
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	skip_label.add_theme_font_size_override("font_size", 14)
	skip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	skip_btn.add_child(skip_label)
	skip_label.text = "Skip"

func set_step(step_index: int):
	_current_step = step_index
	var steps = TutorialManager.STEPS
	if step_index >= 0 and step_index < steps.size():
		text_label.text = steps[step_index]
		step_counter.text = "Step %d / %d" % [step_index + 1, TutorialManager.TOTAL_STEPS]
	
	# Show/hide continue button: visible on steps 0-6 (1-7), hidden on step 7 (8)
	continue_btn.visible = step_index < TutorialManager.TOTAL_STEPS - 1

func _input(event: InputEvent):
	if not visible:
		return
	
	# Block all game input while tutorial is active
	get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_request_advance()
	elif event is InputEventMouseButton and event.pressed:
		# On final step, any click completes. On other steps, any click advances.
		_request_advance()

func _request_advance():
	# On the final step, any input completes the tutorial
	# On steps 0-6, advance to next step
	if _current_step >= TutorialManager.TOTAL_STEPS - 1:
		step_advance_requested.emit()
	else:
		step_advance_requested.emit()

func _on_continue_pressed():
	step_advance_requested.emit()

func _on_skip_pressed():
	skip_requested.emit()

func show_overlay():
	visible = true
	# Ensure we capture input
	process_mode = Node.PROCESS_MODE_ALWAYS

func hide_overlay():
	visible = false
