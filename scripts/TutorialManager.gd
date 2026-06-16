extends Node

# TutorialManager — Autoload singleton for managing the new player tutorial
# Steps players through core game mechanics before they begin Floor 1

signal tutorial_started
signal tutorial_advanced(step_index: int)
signal tutorial_completed

var current_step: int = 0
var is_active: bool = false

const STEPS: Array[String] = [
	"You are a Wizard from another place, come to Tintantulos — the Lighthouse of Giants who sailed the storms from Torespar to its moon. Here, oceans are Quintessence, and the giants' history is alive.",
	"Move with [W][E][A][D][Z][X] or click on the ground to walk. The hex grid responds to your steps.",
	"Enemies patrol these halls. Approach from behind to ambush them. If they spot you first, they attack!",
	"When combat begins, you draw cards. Each card costs Attention to play.",
	"Play cards to deal damage, gain Shield, or Heal. Hover over cards to see what they do.",
	"When you're done playing cards, press [Space] or click 'End Turn'.",
	"Defeat all enemies to win the encounter. Explore rooms, find loot, and ascend the Tower.",
	"Press [Enter] or click to begin your climb."
]

const TOTAL_STEPS: int = 8

var _overlay = null

func start_tutorial():
	if is_active:
		return
	is_active = true
	current_step = 0
	tutorial_started.emit()
	_show_overlay()

func advance_step():
	if not is_active:
		return
	
	if current_step < TOTAL_STEPS - 1:
		current_step += 1
		tutorial_advanced.emit(current_step)
		_update_overlay()
	else:
		# On final step, advancing completes the tutorial
		_complete_tutorial()

func skip_tutorial():
	if not is_active:
		return
	_complete_tutorial()

func is_complete() -> bool:
	return not is_active and current_step >= TOTAL_STEPS - 1

func _show_overlay():
	if _overlay == null or not is_instance_valid(_overlay):
		var overlay_scene = load("res://scenes/TutorialOverlay.tscn")
		if overlay_scene:
			_overlay = overlay_scene.instantiate()
		else:
			push_error("TutorialManager: Could not load TutorialOverlay.tscn")
			return
	
	var root = get_tree().root
	if _overlay.get_parent() == null:
		root.add_child(_overlay)
	
	_overlay.set_step(current_step)
	_overlay.step_advance_requested.connect(_on_overlay_advance)
	_overlay.skip_requested.connect(skip_tutorial)
	_overlay.show_overlay()

func _update_overlay():
	if _overlay and is_instance_valid(_overlay):
		_overlay.set_step(current_step)

func _complete_tutorial():
	is_active = false
	if _overlay and is_instance_valid(_overlay):
		_overlay.step_advance_requested.disconnect(_on_overlay_advance)
		_overlay.skip_requested.disconnect(skip_tutorial)
		_overlay.hide_overlay()
		_overlay.queue_free()
		_overlay = null
	tutorial_completed.emit()

func _on_overlay_advance():
	advance_step()
