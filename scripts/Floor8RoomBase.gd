extends Floor1RoomBase
class_name Floor8RoomBase

# Base class for all Floor 8 rooms — The Overclock Forge / Kami Crucible
# Extends Floor1RoomBase with:
#   - Containment vessels (vent/overclock/patch)
#   - Goblin alarms (pull to spawn reinforcements)
#   - Coolant pipes (destroy in boss phase 2)
#   - Padlock door puzzle
#   - Union hall morale mechanics

# Floor 8 specific flags
@export var containment_vessel_present: bool = false
@export var goblin_alarm_present: bool = false
@export var coolant_pipe_present: bool = false
@export var is_union_hall: bool = false

# Containment vessel state
var vessel_was_interacted: bool = false
var vessel_action_taken: String = ""  # "vent", "overclock", "patch"

# Goblin alarm state
var alarm_was_pulled: bool = false

# Coolant pipe state
var pipe_was_destroyed: bool = false

# Padlock door state
var padlock_count: int = 0
var padlocks_opened: int = 0

# Union hall state
var morale_was_broken: bool = false
var leader_was_killed: bool = false

func _ready():
	super._ready()

# -------------------------------------------------------------------
# CONTAINMENT VESSEL
# -------------------------------------------------------------------

func interact_vessel():
	"""Called when player interacts with a containment vessel"""
	if not containment_vessel_present:
		_show_notification("No containment vessel here.", Color(0.7, 0.7, 0.7))
		return
	
	if vessel_was_interacted:
		_show_notification("Vessel already %s." % vessel_action_taken, Color(0.7, 0.7, 0.7))
		return
	
	# The actual vent/overclock/patch logic is handled by Floor8Controller
	# This signals that interaction happened
	emit_signal("vessel_interacted")
	print("[Floor8] Vessel interacted in '%s'" % room_display_name)

func set_vessel_action(action: String):
	"""Mark this room's vessel as handled with chosen action"""
	vessel_was_interacted = true
	vessel_action_taken = action
	print("[Floor8] Vessel %s in '%s'" % [action, room_display_name])

func is_vessel_available() -> bool:
	return containment_vessel_present and not vessel_was_interacted

func get_vessel_action() -> String:
	return vessel_action_taken

# -------------------------------------------------------------------
# GOBLIN ALARM
# -------------------------------------------------------------------

func pull_alarm():
	"""Called when player or enemy pulls the goblin alarm"""
	if not goblin_alarm_present:
		_show_notification("No alarm here.", Color(0.7, 0.7, 0.7))
		return
	
	if alarm_was_pulled:
		_show_notification("Alarm already pulled!", Color(0.9, 0.3, 0.3))
		return
	
	alarm_was_pulled = true
	emit_signal("alarm_pulled")
	_show_notification("🚨 ALARM PULLED! Goblin reinforcements incoming!", Color(0.9, 0.3, 0.3))
	print("[Floor8] Alarm pulled in '%s'" % room_display_name)

func is_alarm_available() -> bool:
	return goblin_alarm_present and not alarm_was_pulled

func reset_alarm():
	"""Reset alarm state (for testing/debug)"""
	alarm_was_pulled = false

# -------------------------------------------------------------------
# COOLANT PIPE
# -------------------------------------------------------------------

func destroy_pipe():
	"""Called when player destroys a coolant pipe in boss phase 2"""
	if not coolant_pipe_present:
		_show_notification("No coolant pipe here.", Color(0.7, 0.7, 0.7))
		return
	
	if pipe_was_destroyed:
		_show_notification("Pipe already destroyed.", Color(0.7, 0.7, 0.7))
		return
	
	pipe_was_destroyed = true
	emit_signal("pipe_destroyed")
	_show_notification("💨 Coolant pipe destroyed! CHARGE vented!", Color(0.3, 0.9, 0.3))
	print("[Floor8] Coolant pipe destroyed in '%s'" % room_display_name)

func is_pipe_intact() -> bool:
	return coolant_pipe_present and not pipe_was_destroyed

# -------------------------------------------------------------------
# PADLOCK DOOR
# -------------------------------------------------------------------

func set_padlock_count(count: int):
	"""Set the number of padlocks on this room's door"""
	padlock_count = count
	padlocks_opened = 0

func open_padlock() -> bool:
	"""Attempt to open one padlock. Returns true if door is now open."""
	if padlocks_opened >= padlock_count:
		return true
	
	padlocks_opened += 1
	emit_signal("padlock_opened", padlocks_opened, padlock_count)
	_show_notification("🔓 Padlock opened! %d/%d" % [padlocks_opened, padlock_count], Color(0.3, 0.9, 0.3))
	print("[Floor8] Padlock %d/%d opened in '%s'" % [padlocks_opened, padlock_count, room_display_name])
	
	if padlocks_opened >= padlock_count:
		emit_signal("door_unlocked")
		_show_notification("🚪 DOOR UNLOCKED!", Color(0.3, 0.9, 0.3))
		return true
	return false

func is_door_open() -> bool:
	return padlock_count > 0 and padlocks_opened >= padlock_count

func get_padlocks_remaining() -> int:
	return max(0, padlock_count - padlocks_opened)

# -------------------------------------------------------------------
# UNION HALL MORALE
# -------------------------------------------------------------------

func break_morale():
	"""Break goblin morale in this room"""
	if not is_union_hall:
		return
	
	morale_was_broken = true
	emit_signal("morale_broken")
	_show_notification("😰 Goblin morale BROKEN!", Color(0.9, 0.7, 0.3))
	print("[Floor8] Morale broken in '%s'" % room_display_name)

func kill_leader():
	"""Leader killed — test remaining goblins for panic"""
	if not is_union_hall:
		return
	
	leader_was_killed = true
	emit_signal("leader_killed")
	_show_notification("💀 Chief Handler killed! Goblins panic!", Color(0.9, 0.7, 0.3))
	print("[Floor8] Leader killed in '%s'" % room_display_name)

func is_morale_was_broken() -> bool:
	return is_union_hall and morale_was_broken

func is_leader_alive() -> bool:
	return is_union_hall and not leader_was_killed

# -------------------------------------------------------------------
# NOTIFICATION HELPER
# -------------------------------------------------------------------

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.9)):
	var label = Label.new()
	label.text = text
	label.position = Vector2(20, 20)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	# Auto-remove after 3 seconds
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(label.queue_free)

# Additional signals
signal vessel_interacted
signal alarm_pulled
signal pipe_destroyed
signal padlock_opened(current: int, total: int)
signal door_unlocked
signal morale_broken
signal leader_killed
