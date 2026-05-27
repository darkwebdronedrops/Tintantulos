extends RoomPuzzle
class_name FlywheelPuzzle

# The Flywheel - Room 9
# Puzzle: Build momentum by repeatedly pushing a giant gear, then release at max speed
#   to fling the light emitter into alignment. Over-push = gear jams (reset).
# Mechanic: [E] to push gear. Each push adds momentum. Gear auto-decelerates.
#   At 80+ momentum, [R] to release → fling check. 60-80 = partial (needs 2 flings).
#   <60 = not enough. >100 = jam (gear overspin, 3s reset). Perfect window: 85-95.
# Token: Wedged in gear teeth — dislodges when release happens at 90+ momentum.
# Shrine: Momentum Kami - prefers Polished Brass, Machine Oil

enum FlywheelState { IDLE, PUSHING, SPINNING, RELEASING, JAMMED, ALIGNED }

# Flywheel gear
var flywheel: Node2D
var wheel_rotation: float = 0.0
var momentum: float = 0.0  # 0-100
const MAX_MOMENTUM: float = 100.0
const PUSH_INCREMENT: float = 15.0
const DECAY_RATE: float = 8.0  # Per second
const RELEASE_THRESHOLD: float = 80.0
const PERFECT_MIN: float = 85.0
const PERFECT_MAX: float = 95.0
const JAM_THRESHOLD: float = 100.0

# Release mechanism
var release_switch: Node2D
var release_count: int = 0
const RELEASES_NEEDED: int = 1  # One perfect release

# Speed indicator
var speed_bar: Node2D

# Visual
var status_label: Label
var momentum_label: Label

func _ready():
	room_id = 9
	room_name = "The Flywheel"
	super._ready()

func _setup_visuals():
	# Flywheel gear (large, center)
	flywheel = _create_flywheel()
	add_child(flywheel)
	
	# Speed indicator (right side)
	speed_bar = _create_speed_bar()
	speed_bar.position = Vector2(70, 0)
	add_child(speed_bar)
	
	# Release switch (bottom)
	release_switch = _create_release_switch()
	release_switch.position = Vector2(0, 60)
	add_child(release_switch)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Push the flywheel to build momentum. Release at 85-95."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-150, -90)
	status_label.size = Vector2(300, 24)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color(0.9, 0.9, 0.8)
	add_child(status_label)
	
	# Momentum value label
	momentum_label = Label.new()
	momentum_label.name = "MomentumLabel"
	momentum_label.text = "0%"
	momentum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	momentum_label.position = Vector2(50, -20)
	momentum_label.size = Vector2(40, 20)
	momentum_label.add_theme_font_size_override("font_size", 14)
	momentum_label.modulate = Color(0.3, 0.9, 0.9)
	add_child(momentum_label)

func _create_flywheel() -> Node2D:
	var wheel = Node2D.new()
	wheel.name = "Flywheel"
	
	# Wheel sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_flywheel_wheel.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_flywheel_wheel.png")
		sprite.scale = Vector2(0.9, 0.9)
	else:
		# Fallback: large gear
		var rim = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 24:
			var a = (TAU / 24.0) * i
			var r = 55.0 if i % 2 == 0 else 48.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		rim.polygon = pts
		rim.color = Color(0.5, 0.5, 0.55)
		wheel.add_child(rim)
		
		for i in 8:
			var spoke = Line2D.new()
			var a = (TAU / 8.0) * i
			spoke.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(a) * 50, sin(a) * 50)])
			spoke.width = 4
			spoke.default_color = Color(0.4, 0.4, 0.45)
			wheel.add_child(spoke)
	wheel.add_child(sprite)
	
	return wheel

func _create_speed_bar() -> Node2D:
	var bar = Node2D.new()
	bar.name = "SpeedBar"
	
	# Background
	var bg = Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(-8, -60), Vector2(8, -60),
		Vector2(8, 60), Vector2(-8, 60)
	])
	bg.color = Color(0.2, 0.2, 0.25)
	bar.add_child(bg)
	
	# Green zone (perfect range)
	var green_zone = Polygon2D.new()
	green_zone.polygon = PackedVector2Array([
		Vector2(-9, -6), Vector2(9, -6),
		Vector2(9, 18), Vector2(-9, 18)
	])
	green_zone.color = Color(0.2, 0.8, 0.3, 0.3)
	bar.add_child(green_zone)
	
	# Danger zone (jam)
	var danger_zone = Polygon2D.new()
	danger_zone.polygon = PackedVector2Array([
		Vector2(-9, -60), Vector2(9, -60),
		Vector2(9, -48), Vector2(-9, -48)
	])
	danger_zone.color = Color(0.8, 0.2, 0.2, 0.3)
	bar.add_child(danger_zone)
	
	# Fill bar
	var fill = Polygon2D.new()
	fill.name = "Fill"
	fill.polygon = PackedVector2Array([
		Vector2(-6, 60), Vector2(6, 60),
		Vector2(6, 60), Vector2(-6, 60)
	])
	fill.color = Color(0.3, 0.7, 0.9)
	bar.add_child(fill)
	
	return bar

func _create_release_switch() -> Node2D:
	var sw = Node2D.new()
	sw.name = "ReleaseSwitch"
	
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-15, -8), Vector2(15, -8),
		Vector2(15, 8), Vector2(-15, 8)
	])
	base.color = Color(0.5, 0.5, 0.55)
	sw.add_child(base)
	
	var lever = Line2D.new()
	lever.name = "Lever"
	lever.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -20)])
	lever.width = 4
	lever.default_color = Color(0.8, 0.3, 0.2)
	sw.add_child(lever)
	
	var label = Label.new()
	label.text = "RELEASE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-25, 10)
	label.size = Vector2(50, 14)
	label.add_theme_font_size_override("font_size", 9)
	label.modulate = Color(0.9, 0.7, 0.3)
	sw.add_child(label)
	
	return sw

func _setup_interactables():
	# Flywheel (push)
	interactables.append(flywheel)
	
	# Release switch
	interactables.append(release_switch)

func _setup_shrine():
	# Momentum Kami
	kami_shrine = _create_shrine_from_db("momentum_kami", Vector2(-70, -50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	# Decay momentum over time
	if momentum > 0:
		momentum -= DECAY_RATE * delta
		momentum = max(0.0, momentum)
		_update_speed_bar()
		_update_momentum_label()
		
		# Auto-jam if exceeds threshold
		if momentum >= JAM_THRESHOLD:
			_trigger_jam()
			return
	
	# Rotate wheel based on momentum
	wheel_rotation += (momentum / 100.0) * 5.0 * delta
	flywheel.rotation = wheel_rotation
	
	# Update status based on momentum
	if momentum > 0 and momentum < RELEASE_THRESHOLD:
		status_label.text = "Building momentum... %d%%" % int(momentum)
	elif momentum >= RELEASE_THRESHOLD and momentum < PERFECT_MIN:
		status_label.text = "Close! Push a bit more... %d%%" % int(momentum)
	elif momentum >= PERFECT_MIN and momentum <= PERFECT_MAX:
		status_label.text = "PERFECT! Release NOW! %d%%" % int(momentum)
		status_label.modulate = Color(0.3, 0.9, 0.3)
	elif momentum > PERFECT_MAX and momentum < JAM_THRESHOLD:
		status_label.text = "Too fast! Release before it jams! %d%%" % int(momentum)
		status_label.modulate = Color(0.9, 0.7, 0.3)

func _push_flywheel():
	if momentum >= JAM_THRESHOLD:
		_trigger_jam()
		return
	
	momentum += PUSH_INCREMENT
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(flywheel, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_property(flywheel, "scale", Vector2(1.0, 1.0), 0.1)
	
	_play_sound("push_gear")
	
	# Check for immediate jam
	if momentum >= JAM_THRESHOLD:
		_trigger_jam()

func _release_flywheel():
	if momentum < RELEASE_THRESHOLD:
		status_label.text = "Not enough momentum! Push more. (%d%%)" % int(momentum)
		status_label.modulate = Color(0.9, 0.5, 0.2)
		_play_sound("fail")
		return
	
	release_count += 1
	
	# Check result
	if momentum > PERFECT_MAX and momentum < JAM_THRESHOLD:
		# Too fast but not jammed
		status_label.text = "Too fast! Gear overshot. Momentum lost."
		status_label.modulate = Color(0.9, 0.7, 0.3)
		momentum = 30.0
		_play_sound("overshoot")
	elif momentum >= PERFECT_MIN and momentum <= PERFECT_MAX:
		# Perfect!
		_solve_puzzle()
	else:
		# Good but not perfect — partial progress
		var needed = RELEASES_NEEDED - release_count
		if needed > 0:
			status_label.text = "Good push! %d more to align." % needed
			momentum = 0.0
			_play_sound("partial")
		else:
			# Enough partial releases
			_solve_puzzle()

func _trigger_jam():
	momentum = 0.0
	_update_speed_bar()
	
	status_label.text = "JAMMED! Gear overspun. Wait 3s..."
	status_label.modulate = Color(0.9, 0.2, 0.2)
	
	# Visual shake
	var tween = create_tween()
	for i in 10:
		tween.tween_property(flywheel, "position:x", randf() * 6 - 3, 0.05)
	tween.tween_property(flywheel, "position:x", 0, 0.05)
	
	_play_sound("jam")
	
	# Disable interaction briefly
	await get_tree().create_timer(3.0).timeout
	status_label.text = "Reset. Push to build momentum."
	status_label.modulate = Color(0.9, 0.9, 0.8)

func _solve_puzzle():
	momentum = 0.0
	_update_speed_bar()
	
	status_label.text = "EMITTER FLUNG INTO ALIGNMENT!"
	status_label.modulate = Color(0.3, 0.9, 0.3)
	
	# Visual: emitter flies into position
	if light_emitter:
		light_emitter.visible = true
		light_emitter.position = Vector2(0, -80)
		light_emitter.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(light_emitter, "position:y", -50, 0.5)
		tween.parallel().tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	# Reveal token (dislodged from gear teeth)
	if gear_devil_token:
		gear_devil_token.visible = true
		gear_devil_token.position = Vector2(30, -10)
		gear_devil_token.modulate.a = 0.0
		var tween2 = create_tween()
		tween2.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The flywheel releases its stored momentum! The light emitter flings into perfect alignment with a satisfying *CLANG*.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -200)
	popup.size = Vector2(400, 50)
	popup.add_theme_font_size_override("font_size", 12)
	popup.modulate = Color(0.5, 0.9, 0.7)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 3.0)
	await tween.finished
	popup.queue_free()

func _update_speed_bar():
	var fill = speed_bar.get_node("Fill")
	var t = momentum / MAX_MOMENTUM
	var bar_height = t * 120.0
	fill.polygon = PackedVector2Array([
		Vector2(-6, 60), Vector2(6, 60),
		Vector2(6, 60 - bar_height), Vector2(-6, 60 - bar_height)
	])
	
	# Color by zone
	if momentum >= JAM_THRESHOLD:
		fill.color = Color(0.9, 0.2, 0.2)
	elif momentum >= PERFECT_MIN and momentum <= PERFECT_MAX:
		fill.color = Color(0.3, 0.9, 0.3)
	elif momentum >= RELEASE_THRESHOLD:
		fill.color = Color(0.9, 0.9, 0.3)
	else:
		fill.color = Color(0.3, 0.7, 0.9)

func _update_momentum_label():
	momentum_label.text = "%d%%" % int(momentum)

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	if obj == flywheel:
		return "[E] Push Flywheel"
	elif obj == release_switch:
		if momentum >= RELEASE_THRESHOLD:
			return "[E] RELEASE!"
		return "[E] Release (need %d%%+)" % int(RELEASE_THRESHOLD)
	return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	if obj == flywheel:
		_push_flywheel()
	elif obj == release_switch:
		_release_flywheel()
	else:
		super._on_interact(obj)

func activate_puzzle():
	super.activate_puzzle()
	momentum = 0.0
	_update_speed_bar()
	_update_momentum_label()

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["momentum"] = momentum
	data["release_count"] = release_count
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	if data.has("momentum"):
		momentum = data["momentum"]
	if data.has("release_count"):
		release_count = data["release_count"]
	_update_speed_bar()
	_update_momentum_label()

func reset_puzzle():
	momentum = 0.0
	release_count = 0
	wheel_rotation = 0.0
	flywheel.rotation = 0.0
	_update_speed_bar()
	_update_momentum_label()
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	status_label.text = "Push the flywheel to build momentum. Release at 85-95."
	status_label.modulate = Color(0.9, 0.9, 0.8)
