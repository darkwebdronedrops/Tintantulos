extends Floor1RoomBase
class_name Floor9RoomBase

# Base class for all Floor 9 rooms — The Bone Forges
# Extends Floor1RoomBase with:
#   - Soul Furnaces (destroy vs use)
#   - Assembly Stations (craft companions, repair self)
#   - Conveyor Belts (ride, direction)
#   - Bone / Gear Crates (salvage)

# Floor 9 specific flags
@export var soul_furnace_present: bool = false
@export var assembly_station_present: bool = false
@export var conveyor_present: bool = false
@export var bone_crate_present: bool = false
@export var gear_crate_present: bool = false

# Soul furnace state
var furnace_was_interacted: bool = false
var furnace_was_destroyed: bool = false
var furnace_was_used: bool = false

# Assembly station state
var station_used: bool = false

# Conveyor state
var conveyor_direction: String = "east"  # east, west, north, south, random
var conveyor_was_ridden: bool = false

# Crate state
var bone_was_salvaged: bool = false
var gear_was_salvaged: bool = false

func _ready():
    super._ready()

# -------------------------------------------------------------------
# SOUL FURNACE
# -------------------------------------------------------------------

func interact_furnace():
    """Called when player interacts with a soul furnace"""
    if not soul_furnace_present:
        _show_notification("No soul furnace here.", Color(0.7, 0.7, 0.7))
        return
    
    if furnace_was_interacted:
        _show_notification("Furnace already %s." % ("destroyed" if furnace_was_destroyed else "used"), Color(0.7, 0.7, 0.7))
        return
    
    emit_signal("furnace_interacted")
    print("[Floor9] Furnace interacted in '%s'" % room_display_name)

func destroy_furnace():
    """Mark this room's furnace as destroyed (free souls)"""
    if not soul_furnace_present or furnace_was_interacted:
        return
    furnace_was_interacted = true
    furnace_was_destroyed = true
    emit_signal("furnace_destroyed")
    _show_notification("✨ Souls freed!", Color(0.3, 0.9, 0.3))
    print("[Floor9] Furnace destroyed in '%s'" % room_display_name)

func use_furnace():
    """Mark this room's furnace as used (burn souls, power door)"""
    if not soul_furnace_present or furnace_was_interacted:
        return
    furnace_was_interacted = true
    furnace_was_used = true
    emit_signal("furnace_used")
    _show_notification("🔥 Souls burned. Door powered.", Color(0.9, 0.3, 0.3))
    print("[Floor9] Furnace used in '%s'" % room_display_name)

func is_furnace_available() -> bool:
    return soul_furnace_present and not furnace_was_interacted

func is_furnace_was_destroyed() -> bool:
    return furnace_was_destroyed

func is_furnace_was_used() -> bool:
    return furnace_was_used

# -------------------------------------------------------------------
# ASSEMBLY STATION
# -------------------------------------------------------------------

func interact_station():
    """Called when player interacts with an assembly station"""
    if not assembly_station_present:
        _show_notification("No assembly station here.", Color(0.7, 0.7, 0.7))
        return
    
    emit_signal("station_interacted")
    print("[Floor9] Assembly station interacted in '%s'" % room_display_name)

func craft_companion():
    """Craft a companion card at this station"""
    if not assembly_station_present:
        return
    station_used = true
    emit_signal("companion_crafted")
    _show_notification("🤖 Companion crafted!", Color(0.3, 0.9, 0.3))
    print("[Floor9] Companion crafted in '%s'" % room_display_name)

func repair_self():
    """Repair self at this station (heal + block)"""
    if not assembly_station_present:
        return
    station_used = true
    emit_signal("self_repaired")
    _show_notification("🔧 Repaired! HP + Block gained.", Color(0.3, 0.9, 0.3))
    print("[Floor9] Self repaired in '%s'" % room_display_name)

func is_station_available() -> bool:
    return assembly_station_present

# -------------------------------------------------------------------
# CONVEYOR BELT
# -------------------------------------------------------------------

func interact_conveyor():
    """Called when player interacts with a conveyor belt"""
    if not conveyor_present:
        _show_notification("No conveyor here.", Color(0.7, 0.7, 0.7))
        return
    
    emit_signal("conveyor_interacted")
    print("[Floor9] Conveyor interacted in '%s'" % room_display_name)

func ride_conveyor():
    """Ride the conveyor belt"""
    if not conveyor_present:
        return
    conveyor_was_ridden = true
    emit_signal("conveyor_ridden")
    _show_notification("🏭 Riding conveyor... (%s)" % conveyor_direction, Color(0.6, 0.6, 0.7))
    print("[Floor9] Conveyor ridden in '%s'" % room_display_name)

func set_conveyor_direction(dir: String):
    """Set conveyor direction"""
    conveyor_direction = dir

func get_conveyor_direction() -> String:
    return conveyor_direction

func is_conveyor_available() -> bool:
    return conveyor_present

# -------------------------------------------------------------------
# BONE / GEAR CRATES
# -------------------------------------------------------------------

func salvage_bone():
    """Salvage bone material from a bone crate"""
    if not bone_crate_present:
        _show_notification("No bone crate here.", Color(0.7, 0.7, 0.7))
        return
    
    if bone_was_salvaged:
        _show_notification("Bone crate empty.", Color(0.7, 0.7, 0.7))
        return
    
    bone_was_salvaged = true
    emit_signal("bone_salvaged")
    _show_notification("🦴 Bone salvaged!", Color(0.8, 0.8, 0.7))
    print("[Floor9] Bone salvaged in '%s'" % room_display_name)

func salvage_gear():
    """Salvage gear material from a gear crate"""
    if not gear_crate_present:
        _show_notification("No gear crate here.", Color(0.7, 0.7, 0.7))
        return
    
    if gear_was_salvaged:
        _show_notification("Gear crate empty.", Color(0.7, 0.7, 0.7))
        return
    
    gear_was_salvaged = true
    emit_signal("gear_salvaged")
    _show_notification("⚙ Gear salvaged!", Color(0.6, 0.6, 0.7))
    print("[Floor9] Gear salvaged in '%s'" % room_display_name)

func is_bone_available() -> bool:
    return bone_crate_present and not bone_was_salvaged

func is_gear_available() -> bool:
    return gear_crate_present and not gear_was_salvaged

# -------------------------------------------------------------------
# NOTIFICATION HELPER
# -------------------------------------------------------------------

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.9)):
    var label = Label.new()
    label.text = text
    label.position = Vector2(20, 20)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    var timer = get_tree().create_timer(3.0)
    timer.timeout.connect(label.queue_free)

# Additional signals
signal furnace_interacted
signal furnace_destroyed
signal furnace_used
signal station_interacted
signal companion_crafted
signal self_repaired
signal conveyor_interacted
signal conveyor_ridden
signal bone_salvaged
signal gear_salvaged
