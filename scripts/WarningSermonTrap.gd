extends Trap
class_name WarningSermonTrap

# Warning Sermon Trap
# Gear Devil face hologram broadcasts "INEFFICIENT" across the room.
# All combat cards cost +1 Attention while this trap is active.
# No direct damage, but severe combat handicap.
# Visual: Holographic Gear Devil face, red glowing eyes, broadcast waves.

var attention_penalty: int = 1  # +1 to all card costs
var broadcast_range_hexes: int = 3  # Affects all combat in this radius

func _ready():
	trap_id = "warning_sermon"
	trap_name = "Warning Sermon"
	description = "The Gear Devil's voice booms: 'INEFFICIENT.' All actions require more focus."
	damage_dice = ""
	damage_flat = 0
	damage_type = "psychic"
	blocks_movement = false  # Doesn't block, just debuffs
	pushes_to_combat = false
	max_triggers = 1
	duration = 60.0  # Lasts 1 minute
	super._ready()

func _setup_visuals():
	visual_node = Node2D.new()
	visual_node.name = "SermonVisual"
	
	# Hologram base
	var holo = Polygon2D.new()
	holo.name = "Hologram"
	holo.polygon = PackedVector2Array([
		Vector2(-20, -25), Vector2(20, -25),
		Vector2(25, 0), Vector2(20, 25),
		Vector2(-20, 25), Vector2(-25, 0)
	])
	holo.color = Color(0.8, 0.1, 0.1, 0.4)  # Red translucent
	visual_node.add_child(holo)
	
	# Gear Devil face (stylized)
	var face = Polygon2D.new()
	face.name = "Face"
	face.polygon = PackedVector2Array([
		Vector2(-12, -15), Vector2(12, -15),
		Vector2(15, 0), Vector2(12, 15),
		Vector2(-12, 15), Vector2(-15, 0)
	])
	face.color = Color(0.6, 0.05, 0.05, 0.6)
	visual_node.add_child(face)
	
	# Eyes (glowing)
	for side in [-1, 1]:
		var eye = Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(side * 6 - 3, -5), Vector2(side * 6 + 3, -5),
			Vector2(side * 6 + 3, 2), Vector2(side * 6 - 3, 2)
		])
		eye.color = Color(1.0, 0.0, 0.0, 0.9)
		eye.name = "Eye_%d" % side
		visual_node.add_child(eye)
	
	# Broadcast wave rings (animated)
	for i in 3:
		var ring = Line2D.new()
		ring.name = "Ring_%d" % i
		ring.width = 2
		ring.default_color = Color(0.9, 0.2, 0.2, 0.3)
		visual_node.add_child(ring)
	
	# Sprite fallback
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/trap_warning_sermon.png"):
		sprite.texture = load("res://assets/sprites/puzzles/trap_warning_sermon.png")
		sprite.scale = Vector2(0.8, 0.8)
		visual_node.add_child(sprite)
	
	# Text label (the sermon)
	var sermon = Label.new()
	sermon.name = "SermonText"
	sermon.text = "INEFFICIENT"
	sermon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sermon.position = Vector2(-40, 30)
	sermon.size = Vector2(80, 20)
	sermon.add_theme_font_size_override("font_size", 10)
	sermon.modulate = Color(0.9, 0.1, 0.1)
	sermon.visible = false
	visual_node.add_child(sermon)
	
	add_child(visual_node)

func trigger_trap():
	super.trigger_trap()
	
	# Apply attention penalty as temp effect
	GameState.add_temp_effect("warning_sermon", int(duration / 5.0))  # Duration in 5-turn chunks
	
	# Show sermon text
	var sermon = visual_node.get_node_or_null("SermonText")
	if sermon:
		sermon.visible = true
		var tween = create_tween()
		tween.tween_property(sermon, "modulate:a", 0.0, 2.0)
		tween.tween_property(sermon, "modulate:a", 1.0, 2.0)
		tween.set_loops(int(duration / 4.0))

func _tick(delta: float):
	# Animate broadcast rings
	if visual_node:
		var time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
		for i in 3:
			var ring = visual_node.get_node_or_null("Ring_%d" % i)
			if ring:
				var radius = 30 + i * 15 + (time % 3) * 10
				var pts = PackedVector2Array()
				for j in 16:
					var a = (TAU / 16.0) * j
					pts.append(Vector2(cos(a) * radius, sin(a) * radius))
				ring.points = pts
				ring.default_color.a = 0.5 - (time % 3) * 0.15
		
		# Pulse eyes
		for side in [-1, 1]:
			var eye = visual_node.get_node_or_null("Eye_%d" % side)
			if eye:
				var pulse = 0.7 + 0.3 * sin(time * 3.0)
				eye.modulate.a = pulse
	
	# Check if effect expired
	if not GameState.has_temp_effect("warning_sermon"):
		_disable_trap()

func _disable_trap():
	super._disable_trap()
	# Remove temp effect if still active
	if GameState.has_temp_effect("warning_sermon"):
		GameState.temp_effects.erase("warning_sermon")
	
	if visual_node:
		var tween = create_tween()
		tween.tween_property(visual_node, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): visual_node.visible = false)

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["attention_penalty"] = attention_penalty
	data["broadcast_range"] = broadcast_range_hexes
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	if data.has("attention_penalty"):
		attention_penalty = data["attention_penalty"]
	if data.has("broadcast_range"):
		broadcast_range_hexes = data["broadcast_range"]
	if state == TrapState.ACTIVE:
		GameState.add_temp_effect("warning_sermon", int(duration / 5.0))
