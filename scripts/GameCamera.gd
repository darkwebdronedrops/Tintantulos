extends Camera2D
class_name GameCamera

# GameCamera - Smooth follow camera with zoom

@export var follow_target: Node2D
@export var follow_speed: float = 5.0
@export var min_zoom: float = 0.2
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var initial_zoom: float = 0.4  # Balanced: see 2-3 nearby rooms, discover rest by walking

var target_position: Vector2
var is_shaking: bool = false
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0

func _ready():
	# Make this the active camera
	make_current()
	
	# Start centered with balanced view
	position = Vector2.ZERO
	zoom = Vector2(initial_zoom, initial_zoom)
	
	print("GameCamera: Ready, initial zoom: ", initial_zoom)

func _process(delta):
	if follow_target:
		# Smooth follow
		target_position = follow_target.position
		position = position.lerp(target_position, follow_speed * delta)
	
	# Handle shake
	if is_shaking:
		shake_duration -= delta
		if shake_duration <= 0:
			is_shaking = false
			position = target_position if follow_target else position
		else:
			position += Vector2(
				randf_range(-shake_magnitude, shake_magnitude),
				randf_range(-shake_magnitude, shake_magnitude)
			)

func _input(event):
	# Zoom with scroll wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_out()
	
	# Keyboard zoom
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_zoom_out()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_zoom_in()
		elif event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_reset_zoom()

func _zoom_in():
	var new_zoom = zoom.x + zoom_speed
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func _zoom_out():
	var new_zoom = zoom.x - zoom_speed
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func _reset_zoom():
	zoom = Vector2.ONE

func set_target(target: Node2D):
	follow_target = target

func shake(duration: float, magnitude: float):
	"""Trigger screen shake effect"""
	is_shaking = true
	shake_duration = duration
	shake_magnitude = magnitude

func focus_on_position(pos: Vector2, duration: float = 1.0):
	"""Temporarily focus on a specific position"""
	if follow_target:
		var original_target = follow_target
		follow_target = null
		
		var tween = create_tween()
		tween.tween_property(self, "position", pos, duration)
		
		await tween.finished
		
		follow_target = original_target
