extends Node2D
class_name FloatingText

# FloatingText - Combat feedback numbers (damage, heal, shield, etc.)
# Spawns at target position, floats upward, fades out.
#
# Usage:
#   FloatingText.spawn(get_tree().root, position, "-12", Color.RED)
#   FloatingText.spawn_damage(target, 12)
#   FloatingText.spawn_heal(target, 5)
#   FloatingText.spawn_shield(target, 3)

@export var float_speed := 40.0
@export var lifetime := 1.2
@export var spread := 20.0  # Random horizontal drift

var _text := ""
var _color := Color.WHITE
var _timer := 0.0
var _start_pos := Vector2.ZERO
var _drift := Vector2.ZERO
var _label: Label

func _ready():
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	
	# Use a bold pixel-friendly font if available
	var font = ThemeDB.fallback_font
	_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", 16)
	
	_update_appearance()
	
	# Random drift for visual variety
	_drift = Vector2(randf_range(-spread, spread), -float_speed)
	_start_pos = global_position

func _process(delta):
	_timer += delta
	
	# Float upward with drift
	global_position += _drift * delta
	
	# Fade out in last 0.4 seconds
	if _timer > lifetime - 0.4:
		var fade = 1.0 - (_timer - (lifetime - 0.4)) / 0.4
		modulate.a = clamp(fade, 0.0, 1.0)
	
	if _timer >= lifetime:
		queue_free()

func _update_appearance():
	_label.text = _text
	_label.modulate = _color
	
	# Add outline for readability against any background
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 2)

func set_text(text: String, color: Color):
	_text = text
	_color = color
	if _label:
		_update_appearance()

# --- Static Factory Methods ---

static func spawn(parent: Node, pos: Vector2, text: String, color: Color) -> FloatingText:
	var ft := FloatingText.new()
	ft.global_position = pos
	ft.set_text(text, color)
	parent.add_child(ft)
	return ft

static func spawn_damage(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(0.9, 0.1, 0.1)  # Red
	var text := "-%d" % amount
	return spawn(parent, pos, text, color)

static func spawn_heal(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(0.1, 0.8, 0.2)  # Green
	var text := "+%d" % amount
	return spawn(parent, pos, text, color)

static func spawn_shield(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(0.2, 0.4, 0.9)  # Blue
	var text := "+%d Shield" % amount
	return spawn(parent, pos, text, color)

static func spawn_quiddity(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(1.0, 0.8, 0.1)  # Gold
	var text := "+%d Q" % amount
	return spawn(parent, pos, text, color)

static func spawn_attention(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(0.8, 0.2, 0.8)  # Purple
	var text := "%+d Attn" % amount
	return spawn(parent, pos, text, color)

static func spawn_miss(parent: Node, pos: Vector2) -> FloatingText:
	var color := Color(0.5, 0.5, 0.5)  # Grey
	return spawn(parent, pos, "MISS", color)

static func spawn_crit(parent: Node, pos: Vector2, amount: int) -> FloatingText:
	var color := Color(1.0, 0.6, 0.0)  # Orange/Gold
	var text := "CRIT -%d!" % amount
	return spawn(parent, pos, text, color)

static func spawn_keyword(parent: Node, pos: Vector2, keyword: String) -> FloatingText:
	var color := Color(0.9, 0.9, 0.9)  # White
	var text := keyword.to_upper()
	return spawn(parent, pos, text, color)
