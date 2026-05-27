extends Node
# class_name VFXManager — REMOVED: conflicts with autoload singleton

# VFXManager - Centralized visual effects system
# Handles particle effects, spawn/despawn animations, and combat feedback visuals.
# Singleton autoload.
#
# Usage:
#   VFXManager.play_spawn_effect(position, "summon")
#   VFXManager.play_hit_effect(position, "fire")
#   VFXManager.play_death_effect(position, "construct")

const MAX_POOL_SIZE := 32

# Preloaded effect scenes (extend as needed)
var _effect_scenes: Dictionary = {}
var _effect_pools: Dictionary = {}

func _ready():
	_setup_pools()

func _setup_pools():
	"""Initialize effect pools."""
	# Effect types: spawn, death, hit, shield, heal, trap_trigger, trap_disarm
	for effect_type in ["spawn", "death", "hit", "shield", "heal", "trap_trigger", "trap_disarm", "corruption_pulse", "attention_shift"]:
		_effect_pools[effect_type] = []

func _get_pool(effect_type: String) -> Array:
	if not _effect_pools.has(effect_type):
		_effect_pools[effect_type] = []
	return _effect_pools[effect_type]

# --- Public Effect Spawners ---

func play_spawn_effect(position: Vector2, spawn_type: String = "default"):
	"""Play a spawn/summon effect at position."""
	var color: Color = _get_spawn_color(spawn_type)
	_spawn_particle_burst(position, color, 12, 30.0, 0.6)
	AudioManager.play_sfx("summon_grow")

func play_death_effect(position: Vector2, enemy_type: String = "default"):
	"""Play a death/despawn effect at position."""
	var color: Color = _get_death_color(enemy_type)
	_spawn_particle_burst(position, color, 20, 50.0, 0.8)
	# Directional spray upward
	for i in range(8):
		var angle := -PI + (i / 7.0) * PI  # Arc upward
		var dir := Vector2(cos(angle), sin(angle))
		_spawn_particle(position, color, dir * randf_range(20.0, 60.0), randf_range(0.4, 0.8))

func play_hit_effect(position: Vector2, damage_type: String = "physical"):
	"""Play a damage hit effect at position."""
	var color: Color = _get_damage_color(damage_type)
	_spawn_particle_burst(position, color, 8, 40.0, 0.3)
	_flash_white(position)

func play_shield_effect(position: Vector2):
	"""Play a shield block effect."""
	_spawn_ring_expand(position, Color(0.2, 0.4, 0.9), 0.5)
	AudioManager.play_sfx("shield_block")

func play_heal_effect(position: Vector2, amount: int = 0):
	"""Play a heal effect at position."""
	var color := Color(0.1, 0.8, 0.2)
	# Rising particles
	for i in range(10):
		var offset := Vector2(randf_range(-10, 10), 0)
		_spawn_particle(position + offset, color, Vector2(0, -randf_range(20, 40)), randf_range(0.6, 1.0))
	AudioManager.play_sfx("heal")

func play_trap_trigger_effect(position: Vector2, trap_type: String = "default"):
	"""Play a trap activation effect."""
	var color := Color(1.0, 0.3, 0.1)  # Red-orange
	_spawn_particle_burst(position, color, 15, 60.0, 0.5)
	AudioManager.play_sfx("trap_trigger")

func play_trap_disarm_effect(position: Vector2):
	"""Play a trap disarm/fizzle effect."""
	var color := Color(0.5, 0.5, 0.5)  # Grey smoke
	_spawn_particle_burst(position, color, 10, 20.0, 0.6)
	AudioManager.play_sfx("trap_disarm")

func play_corruption_pulse(position: Vector2, intensity: float):
	"""Play a corruption heartbeat effect."""
	var color := Color(0.8, 0.1, 0.4).lerp(Color(1.0, 0.0, 0.0), intensity)
	_spawn_ring_pulse(position, color, 0.3 + intensity * 0.5)

func play_attention_shift(position: Vector2, state: String):
	"""Play attention state change effect."""
	match state.to_lower():
		"scream":
			_spawn_particle_burst(position, Color(1.0, 0.1, 0.1), 16, 80.0, 0.4)
			AudioManager.play_sfx("combat_cast")
		"whisper":
			_spawn_particle_burst(position, Color(0.3, 0.1, 0.8), 8, 20.0, 0.8)
			AudioManager.play_sfx("menu_hover")
		_:
			_spawn_particle_burst(position, Color(0.5, 0.5, 0.5), 6, 30.0, 0.5)

func play_dice_roll_effect(position: Vector2, result: int):
	"""Visual feedback for dice roll."""
	var color := Color(1.0, 0.9, 0.5) if result >= 6 else Color.WHITE
	_spawn_particle_burst(position, color, 6, 25.0, 0.4)

func play_critical_hit_effect(position: Vector2):
	"""Critical hit starburst."""
	var color := Color(1.0, 0.6, 0.0)
	# Starburst pattern
	for i in range(12):
		var angle := (i / 12.0) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		_spawn_particle(position, color, dir * 60.0, 0.5)
	_spawn_ring_expand(position, color, 0.4)
	ScreenShake.critical_hit()

func play_level_up_effect(position: Vector2):
	"""Floor clear / level up celebration."""
	var colors := [Color.GOLD, Color.YELLOW, Color.ORANGE]
	for i in range(30):
		var color: Color = colors[randi() % colors.size()]
		var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_spawn_particle(position + offset, color, Vector2(0, -randf_range(30, 60)), randf_range(0.8, 1.5))
	_spawn_ring_expand(position, Color.GOLD, 1.0)

# --- Internal Particle Spawners ---

func _spawn_particle(position: Vector2, color: Color, velocity: Vector2, lifetime: float):
	"""Spawn a single simple particle."""
	var particle := _create_particle_node()
	particle.global_position = position
	particle.modulate = color
	
	# Simple tween-based animation
	var tween := create_tween()
	particle.velocity = velocity
	particle.lifetime = lifetime
	
	get_tree().root.add_child(particle)

func _spawn_particle_burst(position: Vector2, color: Color, count: int, speed: float, lifetime: float):
	"""Spawn a burst of particles in random directions."""
	for i in range(count):
		var angle := randf() * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var vel := dir * randf_range(speed * 0.3, speed)
		var col := color.lightened(randf_range(0.0, 0.3))
		_spawn_particle(position, col, vel, lifetime * randf_range(0.7, 1.3))

func _spawn_ring_expand(position: Vector2, color: Color, lifetime: float):
	"""Spawn an expanding ring effect."""
	var ring := _create_ring_node()
	ring.global_position = position
	ring.modulate = color
	
	get_tree().root.add_child(ring)
	
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2(3.0, 3.0), lifetime)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, lifetime)
	tween.finished.connect(func(): ring.queue_free())

func _spawn_ring_pulse(position: Vector2, color: Color, lifetime: float):
	"""Spawn a pulsing ring that fades in and out."""
	var ring := _create_ring_node()
	ring.global_position = position
	ring.modulate = color
	ring.scale = Vector2.ZERO
	
	get_tree().root.add_child(ring)
	
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2(2.0, 2.0), lifetime * 0.5)
	tween.parallel().tween_property(ring, "modulate:a", 1.0, lifetime * 0.5)
	tween.chain().tween_property(ring, "scale", Vector2(2.5, 2.5), lifetime * 0.5)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, lifetime * 0.5)
	tween.finished.connect(func(): ring.queue_free())

func _flash_white(position: Vector2):
	"""Brief white flash at position."""
	var flash := _create_flash_node()
	flash.global_position = position
	
	get_tree().root.add_child(flash)
	
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1).from(0.8)
	tween.finished.connect(func(): flash.queue_free())

# --- Node Factories ---

func _create_particle_node() -> Node2D:
	"""Create a simple particle node."""
	var node := Node2D.new()
	node.set_script(_get_particle_script())
	return node

func _create_ring_node() -> Node2D:
	"""Create a ring visual node."""
	var node := Node2D.new()
	
	# Use a simple circle draw
	var circle := _create_circle_draw_node()
	circle.modulate.a = 0.5
	node.add_child(circle)
	
	return node

func _create_flash_node() -> Node2D:
	"""Create a white flash node."""
	var node := Node2D.new()
	
	var rect := ColorRect.new()
	rect.color = Color.WHITE
	rect.size = Vector2(32, 32)
	rect.position = Vector2(-16, -16)
	node.add_child(rect)
	
	return node

func _create_circle_draw_node() -> Node2D:
	"""Create a node that draws a circle."""
	var node := Node2D.new()
	node.set_script(_get_circle_draw_script())
	return node

# --- Color Helpers ---

func _get_spawn_color(spawn_type: String) -> Color:
	match spawn_type.to_lower():
		"construct": return Color(0.8, 0.6, 0.2)  # Brass
		"elemental": return Color(0.2, 0.5, 0.9)   # Blue
		"undead": return Color(0.4, 0.7, 0.3)    # Green-grey
		"goblin": return Color(0.2, 0.7, 0.2)    # Green
		"demon": return Color(0.9, 0.2, 0.2)     # Red
		"aberration": return Color(0.6, 0.2, 0.8) # Purple
		_: return Color(0.5, 0.5, 0.5)

func _get_death_color(enemy_type: String) -> Color:
	match enemy_type.to_lower():
		"construct": return Color(0.5, 0.5, 0.5)  # Grey metal
		"elemental": return Color(0.8, 0.8, 0.9)   # Dissipating mist
		"undead": return Color(0.3, 0.3, 0.3)     # Ash
		"goblin": return Color(0.2, 0.5, 0.2)    # Green blood
		"demon": return Color(0.9, 0.1, 0.1)     # Blood red
		"aberration": return Color(0.1, 0.1, 0.1) # Void black
		_: return Color(0.5, 0.5, 0.5)

func _get_damage_color(damage_type: String) -> Color:
	match damage_type.to_lower():
		"fire": return Color(1.0, 0.4, 0.1)
		"ice": return Color(0.4, 0.8, 1.0)
		"lightning": return Color(1.0, 1.0, 0.2)
		"acid": return Color(0.5, 0.9, 0.2)
		"void": return Color(0.1, 0.0, 0.2)
		_: return Color(0.9, 0.9, 0.9)
		"physical": return Color(1.0, 0.8, 0.8)
		_: return Color(1.0, 0.9, 0.9)

# --- Inline Scripts ---

func _get_particle_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = '''
extends Node2D

var velocity := Vector2.ZERO
var lifetime := 1.0
var _timer := 0.0

func _ready():
	# Create visual
	var sprite := ColorRect.new()
	sprite.color = modulate
	sprite.size = Vector2(4, 4)
	sprite.position = Vector2(-2, -2)
	add_child(sprite)
	modulate = Color.WHITE

func _process(delta):
	_timer += delta
	global_position += velocity * delta
	velocity *= 0.95  # Friction
	modulate.a = 1.0 - (_timer / lifetime)
	
	if _timer >= lifetime:
		queue_free()
'''
	script.reload()
	return script

func _get_circle_draw_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = '''
extends Node2D

func _draw():
	draw_arc(Vector2.ZERO, 16, 0, TAU, 32, modulate, 2.0)
'''
	script.reload()
	return script
