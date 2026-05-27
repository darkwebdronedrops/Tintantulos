extends Floor1RoomBase
class_name Floor4RoomBase

# ===================================================================
# FLOOR 4 ROOM BASE — Bazaar Booth Base Class
# ===================================================================
# Extends Floor1RoomBase with booth-specific logic:
#   - Vendor vs Trap booth detection
#   - Trap pre-combat effects
#   - Great Lifter part collection
#   - Booth interior (brass market aesthetic)
#
# All 12 booths use this base class. Differentiation is via:
#   - room_id (booth_1 through booth_12)
#   - is_trap_booth (true for 9 trap booths)
#   - vendor_type (for 3 real vendors)
# ===================================================================

@export var is_trap_booth: bool = false
@export var vendor_type: String = ""  # "gearwright", "steam_press", "curio", or ""
@export var trap_type: String = ""   # Set by Floor4Template at runtime

# Booth features
@onready var booth_entrance: Marker2D = $BoothEntrance
@onready var vendor_node: Node2D = $Interior/Vendor if has_node("Interior/Vendor") else null
@onready var trap_trigger: Area2D = $TrapTrigger if has_node("TrapTrigger") else null

# State
var trap_triggered: bool = false
var player_inside: bool = false

func _ready():
	# Look up trap type from template if not set
	if trap_type.is_empty() and is_trap_booth:
		var controller = get_parent()
		if controller and controller.has_method("get_trap_type_for_booth"):
			trap_type = controller.get_trap_type_for_booth(room_id)
	
	super._ready()

func show_interior():
	"""Called when player enters the booth"""
	if interior:
		interior.visible = true
	is_interior_visible = true
	player_inside = true
	emit_signal("room_entered")
	
	# Trap booths trigger when player enters
	if is_trap_booth and not trap_triggered and not is_cleared:
		_trigger_trap()

func hide_interior():
	"""Called when player exits"""
	if interior:
		interior.visible = false
	is_interior_visible = false
	player_inside = false
	emit_signal("room_exited")

func _trigger_trap():
	"""Trigger the booth's trap effect"""
	trap_triggered = true
	print("[Floor4] Trap triggered in booth '%s' (%s)" % [room_display_name, trap_type])
	
	# Notify controller to handle combat
	var controller = get_parent()
	if controller and controller.has_method("enter_trap_booth"):
		controller.enter_trap_booth(room_id)

func get_player_spawn_position() -> Vector2:
	"""Player appears at booth entrance"""
	if booth_entrance:
		return booth_entrance.global_position
	if portal_entrance:
		return portal_entrance.global_position
	return global_position

func get_exit_position() -> Vector2:
	"""Exit from booth"""
	if portal_exit:
		return portal_exit.global_position
	return global_position

func on_player_entered():
	show_interior()
	# Real vendors show their wares
	# Trap booths trigger combat (handled in show_interior)

func on_player_exited():
	hide_interior()

# Vendor interaction
func interact_with_vendor():
	"""Called when player presses E on vendor node"""
	if vendor_node and vendor_node.has_method("interact"):
		vendor_node.interact()
	else:
		# Fallback — emit signal for controller to handle
		print("[Floor4] Vendor interaction in '%s'" % room_display_name)

# Override mark_cleared for trap booths
func mark_cleared():
	if is_cleared:
		return
	is_cleared = true
	
	# Trap booths don't give transit tokens — they give "insight" or nothing
	# Real vendor booths might give parts (handled by controller)
	
	emit_signal("room_cleared")
	print("[Floor4] Booth '%s' cleared!" % room_display_name)
