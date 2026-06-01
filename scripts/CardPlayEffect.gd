extends Node
class_name CardPlayEffect

# CardPlayEffect - Visual mist burst when a card is played
# Attach to CombatUI or root of combat scene

@export var effect_rect: ColorRect

var _material: ShaderMaterial
var _tween: Tween

# Faction color mappings (primary, secondary)
const FACTION_COLORS: Dictionary = {
	"Aberration": [Color(0.6, 0.2, 0.7), Color(0.3, 0.1, 0.4)],      # Sickly purple
	"Construct": [Color(0.7, 0.7, 0.8), Color(0.4, 0.5, 0.6)],        # Steel grey/blue
	"Demon": [Color(0.9, 0.1, 0.1), Color(0.6, 0.05, 0.05)],         # Blood red
	"Dragon": [Color(0.9, 0.4, 0.1), Color(0.6, 0.2, 0.05)],         # Amber/orange
	"Elemental": [Color(0.2, 0.6, 0.9), Color(0.1, 0.3, 0.6)],        # Cyan/blue
	"Goblin": [Color(0.2, 0.7, 0.2), Color(0.1, 0.4, 0.1)],           # Sickly green
	"Undead": [Color(0.5, 0.5, 0.3), Color(0.3, 0.3, 0.15)],          # Bone/sepia
	"Universal": [Color(0.8, 0.8, 0.9), Color(0.5, 0.5, 0.7)],       # Pale silver
	"Arcane": [Color(0.5, 0.2, 0.8), Color(0.3, 0.1, 0.5)],           # Deep violet
	"Divine": [Color(0.9, 0.9, 0.6), Color(0.7, 0.6, 0.3)],           # Soft gold
}

const DEFAULT_PRIMARY: Color = Color(0.5, 0.5, 0.5)
const DEFAULT_SECONDARY: Color = Color(0.3, 0.3, 0.3)

func _ready():
	if effect_rect:
		_material = effect_rect.material as ShaderMaterial
		effect_rect.visible = false
	else:
		push_warning("CardPlayEffect: No effect_rect assigned")

func trigger_effect(faction: String):
	if not effect_rect or not _material:
		return
	
	# Set faction colors
	var colors = FACTION_COLORS.get(faction, [DEFAULT_PRIMARY, DEFAULT_SECONDARY])
	_material.set_shader_parameter("color_primary", colors[0])
	_material.set_shader_parameter("color_secondary", colors[1])
	_material.set_shader_parameter("progress", 0.0)
	
	# Show and animate
	effect_rect.visible = true
	
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_method(_set_progress, 0.0, 1.0, 0.8)
	_tween.tween_callback(_hide_effect)

func _set_progress(val: float):
	if _material:
		_material.set_shader_parameter("progress", val)

func _hide_effect():
	if effect_rect:
		effect_rect.visible = false

func _get_faction_from_card(card: CardData) -> String:
	if not card:
		return "Universal"
	return card.faction if card.faction in FACTION_COLORS else "Universal"
