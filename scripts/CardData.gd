extends Resource
class_name CardData

# CardData - Full card definition matching the existing card system

@export var id: String = ""
@export var card_name: String = ""
@export var faction: String = ""  # Construct, Goblin, Undead, Elemental, Demon, Aberration, Dragon, Universal
@export var card_type: String = ""  # Attack, Defense, Skill, Summon, Trap, Field

# Core stats
@export var attention_cost: int = 1
@export var quiddity_gain: int = 0

# Damage
@export var damage_dice: String = ""  # e.g., "2d6"
@export var damage_flat: int = 0
@export var uses_dice: bool = false

# Defense
@export var shield_amount: int = 0
@export var heal_amount: int = 0

# Summons
@export var summon_attack: int = 0
@export var summon_hp: int = 0
@export var summon_count: int = 0
@export var summon_growth_atk: int = 0
@export var summon_growth_hp: int = 0

# Attack properties
@export var attack_type: String = ""
@export var attack_roll: String = ""
@export var range_type: String = ""  # melee, ranged, aoe
@export var aoe_radius: int = 0
@export var targets_all: bool = false

# Keywords
@export var keywords: PackedStringArray = []

# Traps
@export var trap_cast_cost: int = 0
@export var trap_trigger_cost: int = 0
@export var trap_disarm_cost: int = 0
@export var trap_trigger_action: String = ""
@export var trap_disarm_action: String = ""

# Fields
@export var field_persist: bool = false

# Special
@export var special_effect: String = ""
@export var requires_condition: String = ""
@export var corruption_gain: int = 0
@export var is_overlay: bool = false
@export var overlay_type: String = ""
@export var gem_cost: int = 0

@export var survives_reset: bool = false
@export var ng_plus_generation: int = 0  # Which NG+ run this card was earned on (0 = base game)

# Description and art
@export var description: String = ""
@export var frame_texture_path: String = ""
@export var sprite_texture_path: String = ""  # Path to card art

# --- Overlay Fusion ---
# When an Overlay card is fused onto this card, these fields capture the result
@export var is_fused: bool = false
@export var fused_overlay_id: String = ""        # Which overlay card ID was consumed
@export var fused_overlay_type: String = ""       # "Arcane", "Divine", or "Infernal"
@export var fused_keywords: PackedStringArray = [] # Keywords added by overlay

func get_compiler_weight() -> int:
	"""Return card weight toward the 50-card Compiler threshold.
	Fused cards count as 2. Unfused cards count as 1."""
	return 2 if is_fused else 1

func get_effective_frame_path() -> String:
	"""Return the frame texture path to use for rendering.
	If fused, returns the fused frame path; otherwise the base frame."""
	if is_fused and not frame_texture_path.is_empty():
		return frame_texture_path
	return frame_texture_path

func get_effective_description() -> String:
	"""Return description showing base + overlay effects."""
	var desc = description
	if is_fused:
		desc += "\n[— %s Overlay —]" % fused_overlay_type
	if fused_keywords.size() > 0:
		desc += "\nKeywords: " + ", ".join(fused_keywords)
	return desc

func get_damage() -> int:
	"""Calculate damage (flat or dice roll)"""
	if uses_dice and damage_dice != "":
		return _roll_dice(damage_dice)
	return damage_flat

func _roll_dice(dice_str: String) -> int:
	"""Parse and roll dice (e.g., '2d6' = 2 six-sided dice)"""
	if dice_str == "":
		return 0
	
	var parts = dice_str.split("d")
	if parts.size() != 2:
		return 0
	
	var num_dice = int(parts[0])
	var dice_sides = int(parts[1])
	
	var total = 0
	for i in range(num_dice):
		total += randi() % dice_sides + 1
	
	return total

func has_keyword(keyword: String) -> bool:
	return keyword in keywords

func _to_string() -> String:
	return "%s (%s %s)" % [card_name, faction, card_type]
