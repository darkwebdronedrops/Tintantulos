extends RoomPuzzle
class_name TemperPuzzle

# The Temper - Room 5
# Puzzle: Manage furnace temperature to expand a thermal lens to correct focal length
# Mechanic: Adjust fuel intake (LOW/MEDIUM/HIGH). Temperature changes slowly (thermal inertia).
#   Cold (<30): lens too small, no light
#   Goldilocks (50-70): lens perfect, light path opens, emitter activates
#   Too hot (>85): backfire (5 dmg + reset to 40)
# Token: Embedded in forge anvil — must quench it while furnace is in goldilocks zone
# Shrine: Heat Treatment Kami - prefers Sacred Gasket, Phosphor Crystal

enum FuelLevel { LOW, MEDIUM, HIGH }
enum TempZone { COLD, WARM, GOLDILOCKS, HOT, DANGER }

# Furnace
var furnace: Node2D
var temperature: float = 25.0  # Starts room temp
var fuel_setting: FuelLevel = FuelLevel.MEDIUM
var fuel_indicator: Node2D
const TEMP_MIN: float = 0.0
const TEMP_MAX: float = 100.0
const TEMP_CYCLE_TIME: float = 1.5
var temp_cycle_timer: float = 0.0

# Thermal lens
var thermal_lens: Node2D
var lens_position: float = 0.0  # 0.0 = too small, 1.0 = perfect, >1.0 = overshot
const LENS_COLD_POS: float = 0.0
const LENS_PERFECT_MIN: float = 0.85
const LENS_PERFECT_MAX: float = 1.15
const LENS_WARP_THRESHOLD: float = 1.5

# Forge anvil + token
var anvil: Node2D
var anvil_temperature: float = 25.0
var quench_bucket: Node2D
var token_quenched: bool = false

# Visual
var temp_gauge: Node2D
var status_label: Label
var lens_beam: Line2D

func _ready():
	room_id = 5
	room_name = "The Temper"
	super._ready()

func _setup_visuals():
	# Furnace (bottom center)
	furnace = Node2D.new()
	furnace.name = "Furnace"
	furnace.position = Vector2(0, 50)
	
	var furnace_sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_temper_forge.png"):
		furnace_sprite.texture = load("res://assets/sprites/puzzles/puzzle_temper_forge.png")
		furnace_sprite.scale = Vector2(0.7, 0.7)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-40, -30), Vector2(40, -30),
			Vector2(50, 30), Vector2(-50, 30)
		])
		poly.color = Color(0.6, 0.3, 0.2)
		furnace.add_child(poly)
	furnace.add_child(furnace_sprite)
	add_child(furnace)
	
	# Fuel indicator (above furnace)
	fuel_indicator = _create_fuel_indicator()
	fuel_indicator.position = Vector2(0, -40)
	furnace.add_child(fuel_indicator)
	
	# Temperature gauge (left side)
	temp_gauge = _create_temp_gauge()
	temp_gauge.position = Vector2(-80, 0)
	add_child(temp_gauge)
	
	# Thermal lens (center, above furnace)
	thermal_lens = _create_thermal_lens()
	thermal_lens.position = Vector2(0, -10)
	add_child(thermal_lens)
	
	# Light beam path (from lens upward)
	lens_beam = Line2D.new()
	lens_beam.name = "LensBeam"
	lens_beam.points = PackedVector2Array([Vector2(0, -20), Vector2(0, -60)])
	lens_beam.width = 0
	lens_beam.default_color = Color(0.9, 0.8, 0.4, 0.6)
	add_child(lens_beam)
	
	# Anvil (right side)
	anvil = _create_anvil()
	anvil.position = Vector2(70, 30)
	add_child(anvil)
	
	# Quench bucket (near anvil)
	quench_bucket = _create_quench_bucket()
	quench_bucket.position = Vector2(70, 60)
	add_child(quench_bucket)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Temp: 25°F | Fuel: MEDIUM"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(-120, -80)
	status_label.size = Vector2(240, 24)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.modulate = Color(0.9, 0.7, 0.5)
	add_child(status_label)

func _create_fuel_indicator() -> Node2D:
	var ind = Node2D.new()
	ind.name = "FuelIndicator"
	
	# 3 bars: LOW (small), MEDIUM (medium), HIGH (tall)
	for i in 3:
		var bar = Polygon2D.new()
		bar.name = "Bar_%d" % i
		var h = 6 + i * 5
		bar.polygon = PackedVector2Array([
			Vector2(-15 + i * 12, 0), Vector2(-7 + i * 12, 0),
			Vector2(-7 + i * 12, -h), Vector2(-15 + i * 12, -h)
		])
		bar.color = Color(0.4, 0.4, 0.4)
		ind.add_child(bar)
	
	return ind

func _create_temp_gauge() -> Node2D:
	var gauge = Node2D.new()
	gauge.name = "TempGauge"
	
	# Background arc
	var bg = Polygon2D.new()
	bg.polygon = PackedVector2Array([
		Vector2(-20, 30), Vector2(20, 30),
		Vector2(20, -30), Vector2(-20, -30)
	])
	bg.color = Color(0.2, 0.2, 0.2)
	gauge.add_child(bg)
	
	# Zone markers
	var cold_zone = Polygon2D.new()
	cold_zone.polygon = PackedVector2Array([Vector2(-20, 30), Vector2(-10, 30), Vector2(-10, 15), Vector2(-20, 15)])
	cold_zone.color = Color(0.2, 0.4, 0.8, 0.3)
	gauge.add_child(cold_zone)
	
	var gold_zone = Polygon2D.new()
	gold_zone.polygon = PackedVector2Array([Vector2(-5, 30), Vector2(5, 30), Vector2(5, 10), Vector2(-5, 10)])
	gold_zone.color = Color(0.2, 0.8, 0.3, 0.3)
	gauge.add_child(gold_zone)
	
	var danger_zone = Polygon2D.new()
	danger_zone.polygon = PackedVector2Array([Vector2(10, 30), Vector2(20, 30), Vector2(20, 5), Vector2(10, 5)])
	danger_zone.color = Color(0.8, 0.2, 0.2, 0.3)
	gauge.add_child(danger_zone)
	
	# Needle
	var needle = Line2D.new()
	needle.name = "Needle"
	needle.points = PackedVector2Array([Vector2(0, 25), Vector2(0, -25)])
	needle.width = 2
	needle.default_color = Color(0.9, 0.9, 0.9)
	gauge.add_child(needle)
	
	return gauge

func _create_thermal_lens() -> Node2D:
	var lens = Node2D.new()
	lens.name = "ThermalLens"
	
	# Lens body
	var body = Polygon2D.new()
	body.name = "LensBody"
	body.polygon = PackedVector2Array([
		Vector2(-15, 8), Vector2(15, 8),
		Vector2(8, -8), Vector2(-8, -8)
	])
	body.color = Color(0.6, 0.7, 0.8, 0.5)
	lens.add_child(body)
	
	# Lens glow
	var glow = Polygon2D.new()
	glow.name = "LensGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-12, 6), Vector2(12, 6),
		Vector2(6, -6), Vector2(-6, -6)
	])
	glow.color = Color(0.8, 0.9, 1.0, 0.2)
	lens.add_child(glow)
	
	return lens

func _create_anvil() -> Node2D:
	var a = Node2D.new()
	a.name = "Anvil"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_temper_anvil.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_temper_anvil.png")
		sprite.scale = Vector2(0.5, 0.5)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-15, 10), Vector2(15, 10),
			Vector2(12, -15), Vector2(-12, -15)
		])
		poly.color = Color(0.4, 0.4, 0.45)
		a.add_child(poly)
	a.add_child(sprite)
	
	# Heat glow (changes with temperature)
	var glow = Polygon2D.new()
	glow.name = "HeatGlow"
	glow.polygon = PackedVector2Array([
		Vector2(-20, 15), Vector2(20, 15),
		Vector2(18, -20), Vector2(-18, -20)
	])
	glow.color = Color(0.8, 0.2, 0.1, 0.0)
	a.add_child(glow)
	
	return a

func _create_quench_bucket() -> Node2D:
	var bucket = Node2D.new()
	bucket.name = "QuenchBucket"
	
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/puzzle_temper_bucket.png"):
		sprite.texture = load("res://assets/sprites/puzzles/puzzle_temper_bucket.png")
		sprite.scale = Vector2(0.4, 0.4)
	else:
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-10, -8), Vector2(10, -8),
			Vector2(8, 10), Vector2(-8, 10)
		])
		poly.color = Color(0.3, 0.5, 0.7, 0.8)
		bucket.add_child(poly)
	bucket.add_child(sprite)
	
	return bucket

func _setup_interactables():
	# Furnace (toggle fuel)
	interactables.append(furnace)
	
	# Quench bucket
	interactables.append(quench_bucket)
	
	# Anvil (collect token after quench)
	interactables.append(anvil)

func _setup_shrine():
	# Heat Treatment Kami - prefers Sacred Gasket
	kami_shrine = _create_shrine_from_db("heat_treatment_kami", Vector2(-70, -50))
	add_child(kami_shrine)
	interactables.append(kami_shrine)

func _process(delta: float):
	if state != PuzzleState.ACTIVE:
		return
	
	temp_cycle_timer += delta
	if temp_cycle_timer >= TEMP_CYCLE_TIME:
		temp_cycle_timer = 0.0
		_tick_temperature()

func _tick_temperature():
	# Temperature changes based on fuel setting
	var change = 0.0
	match fuel_setting:
		FuelLevel.LOW:
			change = -8.0
		FuelLevel.MEDIUM:
			change = 3.0
		FuelLevel.HIGH:
			change = 12.0
	
	temperature += change
	temperature = clamp(temperature, TEMP_MIN, TEMP_MAX)
	
	# Update anvil temp (lags behind furnace slightly)
	anvil_temperature = lerp(anvil_temperature, temperature, 0.4)
	
	# Update visuals
	_update_furnace_visual()
	_update_temp_gauge()
	_update_lens_visual()
	_update_anvil_visual()
	_update_status()
	
	# Check danger zone
	if temperature >= 85.0:
		_trigger_backfire()
	
	# Check goldilocks solve
	if temperature >= 50.0 and temperature <= 70.0 and lens_beam.width < 4.0:
		# Lens is perfect — open light beam
		var tween = create_tween()
		tween.tween_property(lens_beam, "width", 6.0, 1.0)
		
		# But emitter only FULLY activates after quench + token
		if token_quenched and state != PuzzleState.SOLVED:
			_solve_puzzle()

func _update_furnace_visual():
	# Furnace color shifts from dark red → orange → bright yellow → white
	var t = temperature / 100.0
	var color: Color
	if t < 0.3:
		color = Color(0.5, 0.15, 0.1).lerp(Color(0.7, 0.3, 0.1), t / 0.3)
	elif t < 0.6:
		color = Color(0.7, 0.3, 0.1).lerp(Color(0.9, 0.6, 0.2), (t - 0.3) / 0.3)
	elif t < 0.85:
		color = Color(0.9, 0.6, 0.2).lerp(Color(1.0, 0.9, 0.5), (t - 0.6) / 0.25)
	else:
		color = Color(1.0, 0.9, 0.5).lerp(Color(1.0, 1.0, 1.0), (t - 0.85) / 0.15)
	
	# Apply to furnace sprite modulate
	var furnace_sprite = furnace.get_child(0)
	if furnace_sprite is Sprite2D:
		furnace_sprite.modulate = color

func _update_fuel_visual():
	for i in 3:
		var bar = fuel_indicator.get_node("Bar_%d" % i)
		if i == fuel_setting:
			bar.color = Color(0.9, 0.6, 0.2)  # Orange = active
		else:
			bar.color = Color(0.4, 0.4, 0.4)  # Grey = inactive

func _update_temp_gauge():
	# Rotate needle based on temp (0-100 maps to -90° to +90°)
	var needle = temp_gauge.get_node("Needle")
	var angle = -90.0 + (temperature / 100.0) * 180.0
	needle.rotation_degrees = angle

func _update_lens_visual():
	# Lens expands/contracts with temperature
	var target_scale = 0.5 + (temperature / 100.0) * 1.0
	thermal_lens.scale = Vector2(target_scale, target_scale)
	
	# Lens color shifts: blue (cold) → clear → warm glow (hot)
	var lens_body = thermal_lens.get_node("LensBody")
	var lens_glow = thermal_lens.get_node("LensGlow")
	if temperature < 30:
		lens_body.color = Color(0.4, 0.6, 0.9, 0.5)
		lens_glow.color = Color(0.5, 0.7, 1.0, 0.1)
	elif temperature < 50:
		lens_body.color = Color(0.6, 0.7, 0.8, 0.5)
		lens_glow.color = Color(0.7, 0.8, 0.9, 0.2)
	elif temperature <= 70:
		lens_body.color = Color(0.8, 0.9, 0.7, 0.6)  # Perfect = bright
		lens_glow.color = Color(0.9, 1.0, 0.6, 0.4)
	else:
		lens_body.color = Color(0.9, 0.7, 0.5, 0.5)
		lens_glow.color = Color(1.0, 0.6, 0.3, 0.3)

func _update_anvil_visual():
	var glow = anvil.get_node("HeatGlow")
	var t = anvil_temperature / 100.0
	glow.color = Color(0.8, 0.2, 0.1, t * 0.5)

func _update_status(text: String = ""):
	if text.is_empty():
		var zone_name = _get_zone_name()
		var fuel_name = ["LOW", "MEDIUM", "HIGH"][fuel_setting]
		status_label.text = "Temp: %d°F | Fuel: %s | %s" % [int(temperature), fuel_name, zone_name]
		
		# Color by zone
		match _get_temp_zone():
			TempZone.COLD:
				status_label.modulate = Color(0.4, 0.6, 0.9)
			TempZone.WARM, TempZone.GOLDILOCKS:
				status_label.modulate = Color(0.3, 0.9, 0.4)
			TempZone.HOT:
				status_label.modulate = Color(0.9, 0.7, 0.3)
			TempZone.DANGER:
				status_label.modulate = Color(0.9, 0.2, 0.2)
	else:
		status_label.text = text

func _get_temp_zone() -> TempZone:
	if temperature < 30:
		return TempZone.COLD
	elif temperature < 50:
		return TempZone.WARM
	elif temperature <= 70:
		return TempZone.GOLDILOCKS
	elif temperature < 85:
		return TempZone.HOT
	else:
		return TempZone.DANGER

func _get_zone_name() -> String:
	match _get_temp_zone():
		TempZone.COLD:
			return "TOO COLD"
		TempZone.WARM:
			return "WARMING UP"
		TempZone.GOLDILOCKS:
			return "PERFECT"
		TempZone.HOT:
			return "HOT"
		TempZone.DANGER:
			return "DANGER!"
	return ""

func _trigger_backfire():
	_update_status("BACKFIRE! Furnace too hot!")
	
	# Damage player
	GameState.damage_player(5)
	
	# Visual backfire
	var burst = _create_fire_burst()
	add_child(burst)
	
	# Reset temperature
	temperature = 40.0
	anvil_temperature = 40.0
	fuel_setting = FuelLevel.MEDIUM
	_update_fuel_visual()
	
	# Reset beam
	lens_beam.width = 0
	
	_play_sound("backfire")

func _create_fire_burst() -> Node2D:
	var burst = Node2D.new()
	burst.position = furnace.position
	for i in 5:
		var p = Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(0, -10)
		])
		p.color = Color(0.9, 0.4, 0.1, 0.7)
		p.position = Vector2(randf() * 40 - 20, randf() * 10)
		burst.add_child(p)
		
		var tween = create_tween()
		tween.tween_property(p, "position:y", p.position.y - 50, 0.8)
		tween.tween_property(p, "modulate:a", 0.0, 0.8)
	
	get_tree().create_timer(1.0).timeout.connect(func(): burst.queue_free())
	return burst

func _solve_puzzle():
	_update_status("THERMAL LENS PERFECT! Light emitter active!")
	
	# Animate emitter
	if light_emitter:
		light_emitter.visible = true
		var tween = create_tween()
		tween.tween_property(light_emitter, "modulate:a", 1.0, 0.5)
	
	solve_puzzle()
	_show_victory_popup("The thermal lens focuses perfectly! A beam of focused heat shoots upward, activating the light emitter.")

func _show_victory_popup(text: String):
	var popup = Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-200, -200)
	popup.size = Vector2(400, 50)
	popup.add_theme_font_size_override("font_size", 12)
	popup.modulate = Color(0.9, 0.7, 0.3)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 3.0)
	await tween.finished
	popup.queue_free()

func _quench_anvil():
	if token_quenched:
		_update_status("Anvil already quenched.")
		return
	
	var zone = _get_temp_zone()
	match zone:
		TempZone.COLD:
			_update_status("Too cold to quench. Heat the furnace first.")
			return
		TempZone.HOT, TempZone.DANGER:
			# Steam explosion!
			_update_status("STEAM EXPLOSION! Anvil too hot!")
			GameState.damage_player(3)
			var steam = await _create_steam_burst(quench_bucket.position)
			add_child(steam)
			return
		TempZone.WARM, TempZone.GOLDILOCKS:
			# Successful quench!
			_update_status("QUENCHED! The token is now accessible.")
			token_quenched = true
			
			# Visual: anvil changes from red to dark grey
			var glow = anvil.get_node("HeatGlow")
			var tween = create_tween()
			tween.tween_property(glow, "color:a", 0.0, 1.0)
			
			# Reveal token
			if gear_devil_token:
				gear_devil_token.visible = true
				gear_devil_token.position = anvil.position + Vector2(0, -15)
				var tween2 = create_tween()
				tween2.tween_property(gear_devil_token, "modulate:a", 1.0, 0.5)
			
			_play_sound("quench")
			
			# If lens is also perfect, solve immediately
			if temperature >= 50.0 and temperature <= 70.0:
				_solve_puzzle()

func _create_steam_burst(pos: Vector2) -> Node2D:
	var burst = Node2D.new()
	burst.position = pos
	for i in 4:
		var p = Polygon2D.new()
		p.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(0, -8)
		])
		p.color = Color(0.8, 0.9, 0.9, 0.6)
		p.position = Vector2(randf() * 15 - 7, 0)
		burst.add_child(p)
		
		var tween = create_tween()
		tween.tween_property(p, "position:y", -40, 1.0)
		tween.tween_property(p, "modulate:a", 0.0, 1.0)
	
	await get_tree().create_timer(1.2).timeout
	burst.queue_free()
	return burst

# --- Interaction ---

func _get_interact_prompt(obj: Node2D) -> String:
	if obj == furnace:
		var fuel_name = ["LOW", "MEDIUM", "HIGH"][fuel_setting]
		return "[E] Adjust Fuel (%s)" % fuel_name
	elif obj == quench_bucket:
		if token_quenched:
			return "[E] Quench Bucket (empty)"
		return "[E] Quench Anvil"
	elif obj == anvil:
		if token_quenched and gear_devil_token and not token_collected:
			return "[E] Collect Token from Anvil"
		return "[E] Inspect Anvil"
	return super._get_interact_prompt(obj)

func _on_interact(obj: Node2D):
	if obj == furnace:
		_cycle_fuel()
	elif obj == quench_bucket:
		_quench_anvil()
	elif obj == anvil:
		if token_quenched and gear_devil_token and not token_collected:
			_on_token_collected()
	else:
		super._on_interact(obj)

func _cycle_fuel():
	fuel_setting = (fuel_setting + 1) % 3
	_update_fuel_visual()
	var fuel_name = ["LOW", "MEDIUM", "HIGH"][fuel_setting]
	_update_status("Fuel set to %s" % fuel_name)
	_play_sound("fuel_adjust")

# --- Save/Load ---

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["temperature"] = temperature
	data["fuel_setting"] = fuel_setting
	data["anvil_temp"] = anvil_temperature
	data["token_quenched"] = token_quenched
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	
	if data.has("temperature"):
		temperature = data["temperature"]
	if data.has("fuel_setting"):
		fuel_setting = data["fuel_setting"]
	if data.has("anvil_temp"):
		anvil_temperature = data["anvil_temp"]
	if data.has("token_quenched"):
		token_quenched = data["token_quenched"]
	
	_update_fuel_visual()
	_update_furnace_visual()
	_update_temp_gauge()
	_update_lens_visual()
	_update_anvil_visual()
	_update_status()

func reset_puzzle():
	temperature = 25.0
	anvil_temperature = 25.0
	fuel_setting = FuelLevel.MEDIUM
	token_quenched = false
	lens_beam.width = 0
	
	if gear_devil_token:
		gear_devil_token.visible = false
		gear_devil_token.modulate.a = 1.0
	
	_update_fuel_visual()
	_update_furnace_visual()
	_update_temp_gauge()
	_update_lens_visual()
	_update_anvil_visual()
	_update_status()
