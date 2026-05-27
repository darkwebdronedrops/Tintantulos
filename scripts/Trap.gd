extends Node2D
class_name Trap

# Base Trap class for Floor 3 environmental hazards
# Traps can: modify terrain, deal damage, push to combat

enum TrapState { IDLE, ACTIVE, TRIGGERED, DISABLED }

signal trap_triggered(trap_name: String, effect: String)
signal trap_damage_dealt(amount: int, damage_type: String)
signal trap_terrain_changed(hexes: Array[Vector2i], passable: bool)
signal trap_combat_forced(enemy_list: Array)

# Core properties
var trap_id: String = ""
var trap_name: String = "Unknown Trap"
var description: String = ""
var damage_dice: String = ""  # e.g. "2d6", "1d4", "3d6"
var damage_flat: int = 0
var damage_type: String = "physical"  # physical, fire, fall, psychic

# State
var state: TrapState = TrapState.IDLE
var is_triggered: bool = false
var trigger_count: int = 0
var max_triggers: int = -1  # -1 = infinite

# Visual
var visual_node: Node2D
var warning_label: Label

# Affected hexes (for terrain modification)
var affected_hexes: Array[Vector2i] = []
var blocks_movement: bool = false

# Combat push
var pushes_to_combat: bool = false
var combat_enemies: Array = []  # Array of enemy data dicts

# Timing
var tick_interval: float = 5.0  # For dot traps (Compression)
var tick_timer: float = 0.0

# Duration (0 = permanent until disarmed)
var duration: float = 0.0
var lifetime: float = 0.0

func _ready():
	_setup_visuals()

func _setup_visuals():
	"""Override in subclass"""
	pass

func _process(delta: float):
	if state == TrapState.ACTIVE:
		_tick(delta)
		
		if duration > 0:
			lifetime += delta
			if lifetime >= duration:
				_disable_trap()

func _tick(delta: float):
	"""Override in subclass for ongoing effects (dot damage, etc.)"""
	pass

func trigger_trap():
	"""Activate the trap — called when player enters trigger zone"""
	if state == TrapState.DISABLED:
		return
	if is_triggered and max_triggers > 0 and trigger_count >= max_triggers:
		return
	
	state = TrapState.ACTIVE
	is_triggered = true
	trigger_count += 1
	
	_apply_trap_effect()
	_show_trigger_visual()
	trap_triggered.emit(trap_name, _get_effect_description())

func _apply_trap_effect():
	"""Override in subclass — apply damage, terrain changes, combat push"""
	pass

func _get_effect_description() -> String:
	return "%s triggered" % trap_name

func _deal_damage():
	var damage = damage_flat
	if not damage_dice.is_empty():
		damage += _roll_dice(damage_dice)
	
	if damage > 0:
		GameState.damage_player(damage)
		trap_damage_dealt.emit(damage, damage_type)
		_show_damage_popup(damage)

func _roll_dice(dice_string: String) -> int:
	var parts = dice_string.split("d")
	if parts.size() != 2:
		return 0
	
	var count = int(parts[0])
	var sides = int(parts[1])
	var total = 0
	
	for i in range(count):
		total += randi() % sides + 1
	
	return total

func _modify_terrain(hexes: Array[Vector2i], passable: bool):
	"""Mark hexes as passable or impassable"""
	affected_hexes = hexes
	blocks_movement = not passable
	trap_terrain_changed.emit(hexes, passable)

func _force_combat():
	"""Push player into combat encounter"""
	if pushes_to_combat and combat_enemies.size() > 0:
		trap_combat_forced.emit(combat_enemies)

func _disable_trap():
	state = TrapState.DISABLED
	if blocks_movement and affected_hexes.size() > 0:
		# Restore terrain
		trap_terrain_changed.emit(affected_hexes, true)
		blocks_movement = false
	visible = false

func disarm():
	"""Player successfully disarmed the trap"""
	_disable_trap()

func _show_trigger_visual():
	"""Flash/animate the trap when triggered"""
	if visual_node:
		var tween = create_tween()
		tween.tween_property(visual_node, "modulate", Color(1.5, 0.3, 0.3), 0.2)
		tween.tween_property(visual_node, "modulate", Color(1, 1, 1), 0.3)

func _show_damage_popup(damage: int):
	var popup = Label.new()
	popup.text = "-%d %s!" % [damage, damage_type.to_upper()]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(-30, -40)
	popup.size = Vector2(60, 20)
	popup.add_theme_font_size_override("font_size", 12)
	popup.modulate = Color(0.9, 0.2, 0.2)
	add_child(popup)
	
	var tween = create_tween()
	tween.tween_property(popup, "position:y", -60, 0.5)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.5)
	tween.tween_callback(popup.queue_free)

func get_save_data() -> Dictionary:
	return {
		"trap_id": trap_id,
		"state": state,
		"triggered": is_triggered,
		"trigger_count": trigger_count,
		"lifetime": lifetime
	}

func load_save_data(data: Dictionary):
	state = data.get("state", TrapState.IDLE)
	is_triggered = data.get("triggered", false)
	trigger_count = data.get("trigger_count", 0)
	lifetime = data.get("lifetime", 0.0)
	if state == TrapState.ACTIVE:
		_show_trigger_visual()
