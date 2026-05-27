extends Floor1RoomBase
class_name Floor7RoomBase

# Base class for all Floor 7 rooms — The Broken Pact
# Extends Floor1RoomBase with:
#   - Contract stations (pact signing)
#   - Void cracks (reality tears)
#   - Docket reading (court rooms)
#   - Boss arena helpers (witness spawning, final pact)

# Floor 7 specific flags
@export var contract_station_active: bool = false
@export var void_crack_present: bool = false
@export var docket_readable: bool = false

# Contract station state
var contract_signed: bool = false
var contract_type: String = ""  # "blood_contract", "soul_mortgage", "void_bond", "silence_clause"

# Void crack state
var void_crack_stabilized: bool = false
var void_crack_positions: Array[Vector2] = []

# Docket state
var docket_was_read: bool = false

# Boss arena state
var witnesses_spawned: Array[String] = []
var final_pact_was_shown: bool = false

func _ready():
	super._ready()

# -------------------------------------------------------------------
# CONTRACT STATION
# -------------------------------------------------------------------

func interact_contract_station():
	"""Called when player interacts with a contract station"""
	if contract_signed:
		_show_notification("Contract already signed.", Color(0.7, 0.7, 0.7))
		return
	
	contract_station_active = true
	# The actual pact logic is handled by Floor7Controller
	# This method signals that interaction happened
	emit_signal("contract_station_interacted", contract_type)
	print("[Floor7] Contract station interacted in '%s'" % room_display_name)

func sign_contract(pact_type: String):
	"""Mark this room's contract as signed"""
	contract_signed = true
	contract_type = pact_type
	contract_station_active = false
	print("[Floor7] Contract signed in '%s': %s" % [room_display_name, pact_type])

func is_contract_available() -> bool:
	return contract_station_active and not contract_signed

# -------------------------------------------------------------------
# VOID CRACK
# -------------------------------------------------------------------

func interact_void_crack():
	"""Called when player interacts with a void crack"""
	if void_crack_stabilized:
		_show_notification("Void crack already stabilized.", Color(0.5, 0.8, 0.5))
		return
	
	void_crack_present = true
	emit_signal("void_crack_interacted")
	print("[Floor7] Void crack interacted in '%s'" % room_display_name)

func stabilize_void_crack():
	"""Mark void crack as stabilized"""
	void_crack_stabilized = true
	void_crack_present = false
	print("[Floor7] Void crack stabilized in '%s'" % room_display_name)

func is_near_void_crack(player_pos: Vector2, threshold: float = 100.0) -> bool:
	"""Check if player is near any void crack in this room"""
	for crack_pos in void_crack_positions:
		if player_pos.distance_to(crack_pos) < threshold:
			return true
	return false

func add_void_crack_position(pos: Vector2):
	void_crack_positions.append(pos)

# -------------------------------------------------------------------
# DOCKET (Court rooms)
# -------------------------------------------------------------------

func read_docket():
	"""Called when player reads the docket in a court room"""
	if not docket_readable:
		return
	
	if docket_was_read:
		_show_notification("Docket already read.", Color(0.7, 0.7, 0.7))
		return
	
	docket_was_read = true
	emit_signal("docket_read")
	print("[Floor7] Docket read in '%s'" % room_display_name)

# -------------------------------------------------------------------
# BOSS ARENA HELPERS
# -------------------------------------------------------------------

func spawn_witness(witness_name: String, position: Vector2):
	"""Spawn a witness ghost in the boss arena"""
	witnesses_spawned.append(witness_name)
	print("[Floor7] Witness spawned: %s at %s" % [witness_name, position])
	emit_signal("witness_spawned", witness_name, position)

func show_final_pact():
	"""Show the final pact UI in boss arena"""
	if final_pact_was_shown:
		return
	final_pact_was_shown = true
	emit_signal("final_pact_shown")
	print("[Floor7] Final pact shown in '%s'" % room_display_name)

func break_all_pacts():
	"""Called when player chooses to break all pacts"""
	contract_signed = false
	contract_type = ""
	contract_station_active = false
	emit_signal("all_pacts_broken")
	print("[Floor7] All pacts broken in '%s'" % room_display_name)

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
signal contract_station_interacted(pact_type: String)
signal void_crack_interacted
signal docket_read
signal witness_spawned(witness_name: String, position: Vector2)
signal final_pact_shown
signal all_pacts_broken
