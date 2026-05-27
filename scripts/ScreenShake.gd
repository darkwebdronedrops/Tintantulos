extends Node
# class_name ScreenShake — REMOVED: conflicts with autoload singleton

# ScreenShake - Camera shake effect for impactful moments
# Call ScreenShake.trigger(intensity, duration) from anywhere.
#
# Usage:
#   ScreenShake.trigger(0.5, 0.3)  # Light shake
#   ScreenShake.trigger(1.0, 0.5)  # Heavy shake (boss hit)
#   ScreenShake.trigger(2.0, 1.0)  # Massive shake (dragon roar)

var _camera: Camera2D = null
var _shake_intensity := 0.0
var _shake_duration := 0.0
var _shake_timer := 0.0
var _original_position := Vector2.ZERO
var _is_shaking := false

func _ready():
	_find_camera()

func _find_camera():
	"""Find the main camera in the scene."""
	var viewport = get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()
	
	if _camera == null:
		# Try to find any Camera2D
		var cameras = get_tree().get_nodes_in_group("camera")
		if cameras.size() > 0:
			_camera = cameras[0] as Camera2D

func _process(delta):
	if not _is_shaking or _camera == null:
		return
	
	_shake_timer += delta
	
	if _shake_timer >= _shake_duration:
		_stop_shake()
		return
	
	# Decaying intensity
	var progress := _shake_timer / _shake_duration
	var current_intensity := _shake_intensity * (1.0 - progress)
	
	# Random offset
	var offset := Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)
	
	_camera.offset = _original_position + offset

func _stop_shake():
	_is_shaking = false
	if _camera != null:
		_camera.offset = _original_position

func trigger(intensity: float, duration: float):
	"""Trigger a screen shake."""
	if _camera == null:
		_find_camera()
		if _camera == null:
			return
	
	# Store original position if starting fresh
	if not _is_shaking:
		_original_position = _camera.offset
	
	# Queue stronger shakes, extend duration
	if _is_shaking:
		_shake_intensity = max(_shake_intensity, intensity)
		_shake_duration = max(_shake_duration, _shake_timer + duration)
	else:
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_timer = 0.0
		_is_shaking = true

func stop():
	"""Stop shaking immediately."""
	_stop_shake()

# --- Preset Shakes ---

func light_hit():
	trigger(2.0, 0.15)

func medium_hit():
	trigger(4.0, 0.3)

func heavy_hit():
	trigger(8.0, 0.5)

func boss_entrance():
	trigger(10.0, 1.0)

func boss_phase_change():
	trigger(6.0, 0.8)

func dragon_roar():
	trigger(15.0, 1.5)

func trap_trigger():
	trigger(5.0, 0.4)

func death_blow():
	trigger(3.0, 0.6)

func critical_hit():
	trigger(6.0, 0.3)

func explosion():
	trigger(12.0, 0.7)
