extends RoomPuzzle
class_name EscapementPuzzle

# The Escapement - Room 7
# Puzzle: Time your trigger pulls to match gear tooth alignment
# Mechanic: Escapement wheel rotates (1 rev / 4s, 6 teeth). Press switch when tooth
#   passes through the green tick zone. 3 perfect alignments unlocks mechanism.
#   Timing window tightens: ±0.5s → ±0.3s → ±0.15s
#   Miss = jam (shake, 1s reset). Perfect = "CLICK", counter up.
# Token: Hidden compartment opens only during 3rd perfect tick moment
# Shrine: Time Kami — prefers Precision Tools, Polished Brass

enum TimingState { WAITING, IN_WINDOW, JAMMED, SOLVED }

# Escapement wheel
var escapement_wheel: Node2D
var wheel_rotation: float = 0.0
const WHEEL_SPEED: float = TAU / 4.0  # 1 revolution per 4 seconds
const TEETH_COUNT: int = 6

# Trigger switch
var trigger_switch: Node2D
var switch_pressed: bool = false

# Timing
var timing_state: TimingState = TimingState.WAITING
var click_count: int = 0
const CLICKS_NEEDED: int = 3
var timing_windows: Array[float] = [0.5, 0.3, 0.15]  # Seconds (half-window)
var current_window: float = 0.5
var window_active: bool = false
var window_timer: float = 0.0
var next_tick_time: float = 1.0  # Time until next alignment
const JAM_RESET_TIME: float = 1.0
var jam_timer: float = 0.0

# Hidden compartment
var compartment: Node2D
var compartment_open: bool = false

# Visual
var status_label: Label
var tick_zone: Polygon2D
var jam_shake: float = 0.0

func _ready():
	room_id = 7
	room_name = "The Escapement"
	super._ready()

func _setup_visuals():
	# Escapement wheel (center-left)
	escapement_wheel = _create_escapement_wheel()
	escapement_wheel.position = Vector2(-30, 0)
	add_child(escapement_wheel)
	
	# Trigger switch (right side)
	trigger_switch = _create_trigger_switch()
	trigger_switch.position = Vector2(50, 0)
	add_child(trigger_switch)
	
	# Tick zone indicator (between wheel and switch)
	tick_zone = _create_tick_zone()
	tick_zone.position = Vector2(10, 0)
	add_child(tick_zone)
	
	# Hidden compartment (below wheel)
	compartment = _create_compartment()
	compartment.position = Vector2(-30, 40)
	add_child(compartment)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Wait for the tick... 0/3"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-100, -80)
	status_label.size = Vector2(200, 24)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.modulate = Color(0.8, 0.8, 0.9)
	add_child(status_label)

func _create_escapement_wheel() -> Node2D:
	var wheel = Node2D.new()
	wheel.name = "EscapementWheel"
	
	# Wheel sprite
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_escapement_clock.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_escapement_clock.png")
		sprite.scale = Vector2(0.7, 0.7)
	else:
		# Fallback: gear wheel with teeth
		var rim = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in 24:
			var a = (TAU / 24.0) * i
			var r = 35.0 if i % 2 == 0 else 30.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		rim.polygon = pts
		rim.color = Color(0.5, 0.5, 0.55)
		wheel.add_child(rim)
		
		for i in TEETH_COUNT:
			var tooth = Polygon2D.new()
			var a = (TAU / TEETH_COUNT) * i
			var tooth_pts = PackedVector2Array([
				Vector2(cos(a - 0.15) * 30, sin(a - 0.15) * 30),
				Vector2(cos(a) * 42, sin(a) * 42),
				Vector2(cos(a + 0.15) * 30, sin(a + 0.15) * 30)
			])
			tooth.polygon = tooth_pts
			tooth.color = Color(0.6, 0.6, 0.65)
			wheel.add_child(tooth)
	wheel.add_child(sprite)
	
	return wheel

func _create_trigger_switch() -> Node2D:
	var sw = Node2D.new()
	sw.name = "TriggerSwitch"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_escapement_switch.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_escapement_switch.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		var base = Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-10, -10), Vector2(10, -10),
			Vector2(10, 10), Vector2(-10, 10)
		])
		base.color = Color(0.4, 0.4, 0.45)
		sw.add_child(base)
		
		var lever = Line2D.new()
		lever.name = "Lever"
		lever.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -18)])
		lever.width = 4
		lever.default_color = Color(0.7, 0.5, 0.3)
		sw.add_child(lever)
	sw.add_child(sprite)
	
	return sw

func _create_tick_zone() -> Polygon2D:
	var zone = Polygon2D.new()
	zone.name = "TickZone"
	zone.polygon = PackedVector2Array([
		Vector2(-15, -8), Vector2(15, -8),
		Vector2(15, 8), Vector2(-15, 8)
	])
	zone.color = Color(0.2, 0.8, 0.3, 0.2)  # Faint green
	return zone

func _create_compartment() -> Node2D:
	var comp = Node2D.new()
	comp.name = "Compartment"
	
	# Door
	var door = Polygon2D.new()
	door.name = "Door"
	door.polygon = PackedVector2Array([
		Vector2(-15, -10), Vector2(15, -10),
		Vector2(15, 10), Vector2(-15, 10)
	])
	door.color = Color(0.35, 0.35, 0.4)
	comp.add_child(door)
	
	return comp

func _setup_interactables():
	# Trigger switch
	interactables.append(trigger_switch)
	
	# Compartment (for token collection after it opens)
	interactables.append(compartment)

func _setup_shrine():
	# Time Kami - prefers precision/clockwork offerings
	kami_shrine = _create_shrine_from_db("time_kami", Vector2(60, -50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	if timing_state == TimingState.JAMMED:
		jam_timer -= delta
		jam_shake = sin(Time.get_time_dict_from_system()["second"] * 30.0) * 3.0
		escapement_wheel.position.x = -30 + jam_shake
		if jam_timer <= 0:
			timing_state = TimingState.WAITING
			jam_shake = 0.0
			escapement_wheel.position.x = -30
			_update_status("Reset. Wait for the tick...")
		return
	
	if timing_state == TimingState.SOLVED:
		return
	
	# Rotate wheel
	wheel_rotation += WHEEL_SPEED * delta
	escapement_wheel.rotation = wheel_rotation
	
	# Calculate when next tooth aligns with tick zone
	# Each tooth is at rotation = (TAU/6) * n. Zone is at rotation 0 (right side).
	var current_rot = fmod(wheel_rotation, TAU)
	var teeth_spacing = TAU / TEETH_COUNT
	
	# Find nearest upcoming tooth
	var next_tooth_rot = ceil(current_rot / teeth_spacing) * teeth_spacing
	if next_tooth_rot >= TAU:
		next_tooth_rot = 0.0
	
	var dist_to_next = next_tooth_rot - current_rot
	if dist_to_next < 0:
		dist_to_next += TAU
	
	# Time until next alignment
	var time_to_tick = dist_to_next / WHEEL_SPEED
	
	# Update window
	current_window = timing_windows[min(click_count, timing_windows.size() - 1)]
	
	# Check if we're in the timing window
	if time_to_tick <= current_window:
		window_active = true
		tick_zone.color = Color(0.2, 0.9, 0.3, 0.4)  # Bright green
		if timing_state != TimingState.IN_WINDOW:
			timing_state = TimingState.IN_WINDOW
			_update_status("TICK! NOW! (%d/3)" % (click_count + 1))
	elif window_active:
		# Just passed the window without trigger
		window_active = false
		tick_zone.color = Color(0.2, 0.8, 0.3, 0.2)  # Back to faint
		if timing_state == TimingState.IN_WINDOW:
			# Missed the window!
			_trigger_jam()
	else:
		# Waiting
		if timing_state != TimingState.WAITING:
			timing_state = TimingState.WAITING
			_update_status("Wait for the tick... %d/3" % click_count)

func _trigger_jam():
	timing_state = TimingState.JAMMED
	jam_timer = JAM_RESET_TIME
	_update_status("JAMMED! Too early/late. Resetting...")
	
	# Visual shake
	var tween = create_tween()
	tween.tween_property(escapement_wheel, "rotation", escapement_wheel.rotation - 0.2, 0.1)
	tween.tween_property(escapement_wheel, "rotation", escapement_wheel.rotation, 0.1)
	
	# Red flash on tick zone
	tick_zone.color = Color(0.9, 0.2, 0.2, 0.5)
	
	_play_sound("jam")

func _on_trigger_pull():
	if timing_state == TimingState.JAMMED or timing_state == TimingState.SOLVED:
		return
	
	if timing_state == TimingState.IN_WINDOW:
		# Perfect!
		click_count += 1
		
		# Visual: switch depresses
		var lever = trigger_switch.get_node("Lever")
		if lever:
			var tween = create_tween()
			tween.tween_property(lever, "rotation_degrees", 20.0, 0.1)
			tween.tween_property(lever, "rotation_degrees", 0.0, 0.1)
		
		# Audio
		_play_sound("tick_click")
		
		if click_count >= CLICKS_NEEDED:
			_solve_puzzle()
		else:
			_update_status("PERFECT! %d/3" % click_count)
			
			# Flash tick zone white briefly
			tick_zone.color = Color(1.0, 1.0, 1.0, 0.6)
			await get_tree().create_timer(0.15).timeout
			tick_zone.color = Color(0.2, 0.8, 0.3, 0.2)
	else:
		# Too early or too late!
		_trigger_jam()

func _solve_puzzle():
	timing_state = TimingState.SOLVED
	_update_status("MECHANISM UNLOCKED! 3/3 perfect ticks!")
	
	# Open compartment
	compartment_open = true
	var door = compartment.get_node("Door")
	var tween = create_tween()
	tween.tween_property(door, "scale:x", 0.1, 0.5)
	
	# Reveal token inside
	if gear_devil_token:
		gear_devil_token.visible = true
		gear_devil_token.position = compartment.position + Vector2(0, -5)
		gear_devil_token.modulate.a = 0.0
		var tween2 = create_tween()
		tween2.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)
	
	# Activate emitter
	if light_emitter:
		light_emitter.visible = true
		var tween3 = create_tween()
		tween3.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The escapement clicks into perfect harmony! A hidden compartment opens, revealing the Gear Devil Token.")

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

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	if obj == trigger_switch:
		if timing_state == TimingState.JAMMED:
			return "[E] Trigger (JAMMED)"
		return "[E] Pull Trigger"
	elif obj == compartment:
		if compartment_open and gear_devil_token and not token_collected:
			return "[E] Collect Token from Compartment"
		if compartment_open:
			return "[E] Inspect Compartment"
		return "[E] Inspect Closed Compartment"
	return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	if obj == trigger_switch:
		_on_trigger_pull()
	elif obj == compartment:
		if compartment_open and gear_devil_token and not token_collected:
			_on_token_collected()
	else:
		super._on_interact(obj)

func activate_puzzle():
	super.activate_puzzle()
	_update_status("Wait for the tick... Pull trigger at the exact moment. 0/3")

func _update_status(text: String):
	status_label.text = text

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["click_count"] = click_count
	data["timing_state"] = timing_state
	data["compartment_open"] = compartment_open
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("click_count"):
		click_count = data["click_count"]
	if data.has("timing_state"):
		timing_state = data["timing_state"]
	if data.has("compartment_open"):
		compartment_open = data["compartment_open"]
		if compartment_open:
			var door = compartment.get_node("Door")
			door.scale.x = 0.1
			if gear_devil_token:
				gear_devil_token.visible = true

func reset_puzzle():
	click_count = 0
	timing_state = TimingState.WAITING
	window_active = false
	compartment_open = false
	wheel_rotation = 0.0
	escapement_wheel.rotation = 0.0
	
	var door = compartment.get_node("Door")
	door.scale.x = 1.0
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	_update_status("Wait for the tick... 0/3")
