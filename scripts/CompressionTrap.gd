extends Trap
class_name CompressionTrap

# Compression Trap
# Ceiling-mounted piston/plate descends over time. Deals 1d4 damage every 5 seconds.
# Visual cue: hydraulic lines, pressure gauge, slow descending metal plate.
# Blocks movement through affected hex while active.

var compression_height: float = 60.0  # Starting height of ceiling plate
var current_height: float = 60.0
var descend_rate: float = 2.0  # Units per second
var min_height: float = 10.0  # Fully compressed

func _ready():
	trap_id = "compression"
	trap_name = "Compression"
	description = "The ceiling lowers with crushing force. Move quickly or be flattened."
	damage_dice = "1d4"
	damage_flat = 0
	damage_type = "physical"
	blocks_movement = true
	tick_interval = 5.0
	tick_timer = 0.0
	max_triggers = 1  # Only triggers once, then stays active as DOT
	duration = 30.0  # Stops after 30 seconds
	super._ready()

func _setup_visuals():
	visual_node = Node2D.new()
	visual_node.name = "CompressionVisual"
	
	# Ceiling plate
	var plate = Polygon2D.new()
	plate.name = "Plate"
	plate.polygon = PackedVector2Array([
		Vector2(-35, -5), Vector2(35, -5),
		Vector2(35, 5), Vector2(-35, 5)
	])
	plate.color = Color(0.4, 0.4, 0.45)
	visual_node.add_child(plate)
	
	# Hydraulic pistons
	for side in [-1, 1]:
		var piston = Line2D.new()
		piston.name = "Piston_%d" % side
		piston.points = PackedVector2Array([
			Vector2(side * 25, -60), Vector2(side * 25, 0)
		])
		piston.width = 4
		piston.default_color = Color(0.5, 0.5, 0.55)
		visual_node.add_child(piston)
	
	# Pressure gauge
	var gauge = Polygon2D.new()
	gauge.polygon = PackedVector2Array([
		Vector2(-8, -55), Vector2(8, -55),
		Vector2(8, -40), Vector2(-8, -40)
	])
	gauge.color = Color(0.3, 0.6, 0.3)
	visual_node.add_child(gauge)
	
	# Warning zone (floor marker)
	var warning_zone = Polygon2D.new()
	warning_zone.name = "WarningZone"
	warning_zone.polygon = PackedVector2Array([
		Vector2(-30, 20), Vector2(30, 20),
		Vector2(30, 30), Vector2(-30, 30)
	])
	warning_zone.color = Color(0.8, 0.2, 0.2, 0.2)
	visual_node.add_child(warning_zone)
	
	# Sprite fallback
	var sprite = Sprite2D.new()
	if ResourceLoader.exists("res://assets/sprites/puzzles/trap_compression.png"):
		sprite.texture = load("res://assets/sprites/puzzles/trap_compression.png")
		sprite.scale = Vector2(0.6, 0.6)
		visual_node.add_child(sprite)
	
	# Warning label
	var warning = Label.new()
	warning.name = "WarningLabel"
	warning.text = "⚠ COMPRESSION"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.position = Vector2(-50, -75)
	warning.size = Vector2(100, 20)
	warning.add_theme_font_size_override("font_size", 10)
	warning.modulate = Color(0.9, 0.3, 0.1)
	warning.visible = false
	visual_node.add_child(warning)
	warning_label = warning
	
	add_child(visual_node)

func trigger_trap():
	super.trigger_trap()
	if warning_label:
		warning_label.visible = true

func _tick(delta: float):
	# Descend ceiling
	if current_height > min_height:
		current_height -= descend_rate * delta
		current_height = max(current_height, min_height)
		_update_plate_position()
	
	# Damage tick
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_damage()
		_show_compression_pulse()

func _update_plate_position():
	if visual_node:
		var plate = visual_node.get_node("Plate")
		if plate:
			plate.position.y = -current_height
		
		# Update pistons
		for side in [-1, 1]:
			var piston = visual_node.get_node_or_null("Piston_%d" % side)
			if piston:
				piston.points = PackedVector2Array([
					Vector2(side * 25, -current_height - 10),
					Vector2(side * 25, 0)
				])
		
		# Update gauge color based on compression
		var gauge = visual_node.get_node_or_null("Gauge")
		if gauge:
			var t = 1.0 - (current_height - min_height) / (compression_height - min_height)
			gauge.color = Color(lerp(0.3, 0.9, t), lerp(0.6, 0.1, t), 0.3)

func _show_compression_pulse():
	if visual_node:
		var tween = create_tween()
		tween.tween_property(visual_node, "modulate", Color(1.3, 0.5, 0.5), 0.15)
		tween.tween_property(visual_node, "modulate", Color(1, 1, 1), 0.3)

func _disable_trap():
	super._disable_trap()
	if visual_node:
		# Retract ceiling
		var tween = create_tween()
		tween.tween_property(visual_node, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func():
			visual_node.visible = false
		)

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["current_height"] = current_height
	data["tick_timer"] = tick_timer
	return data

func load_save_data(data: Dictionary):
	super.load_save_data(data)
	if data.has("current_height"):
		current_height = data["current_height"]
	if data.has("tick_timer"):
		tick_timer = data["tick_timer"]
	_update_plate_position()
