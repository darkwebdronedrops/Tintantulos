extends Node
class_name ImbueManager

# ImbueManager — Overlay Card Fusion System
# Handles Combat Imbue (free, hand-based) and Shop Transmutation (paid, deck-based)
# 
# Design:
# - Any overlay + any faction card = permanent fused card
# - Fused card counts as 2 toward the 50-card Compiler threshold
# - Unfused overlay in hand = playable but weak, counts as 1
# - No un-imbue. Fusion is permanent for the run.

const FUSION_GEM_COST: int = 15  # Shop Transmutation cost

# Overlay type → Rider effect description
const RIDER_EFFECTS: Dictionary = {
	"Arcane": "When played: Draw 1 card. If it shares a faction with this card, it costs 1 less Attention.",
	"Divine": "When played: Heal 3 HP. If you have no summons, gain 5 Shield instead.",
	"Infernal": "When played: Deal 2 damage to ALL enemies. If this card kills an enemy, gain 1 Quiddity."
}

# --- Core Fusion ---

static func imbue(overlay_id: String, target_id: String, source: String = "combat") -> String:
	"""Fuse an Overlay onto a target card. Returns the new fused card ID.
	
	Args:
		overlay_id: The overlay card to consume
		target_id: The base faction card to enhance
		source: "combat" (free, hand-based) or "shop" (15 Gems, deck-based)
	
	Returns:
		The new fused card ID, or empty string if fusion failed.
	"""
	var overlay = CardDB.get_card(overlay_id)
	var base = CardDB.get_card(target_id)
	
	if not overlay or not base:
		push_warning("ImbueManager: Missing card data — overlay=%s target=%s" % [overlay_id, target_id])
		return ""
	
	if not overlay.is_overlay:
		push_warning("ImbueManager: %s is not an overlay card" % overlay_id)
		return ""
	
	if base.is_overlay:
		push_warning("ImbueManager: Cannot fuse overlay onto another overlay (%s)" % target_id)
		return ""
	
	if base.is_fused:
		push_warning("ImbueManager: %s is already fused. Cannot stack overlays." % target_id)
		return ""
	
	# --- Create fused card ---
	var fused = base.duplicate()
	var overlay_type = overlay.overlay_type  # "Arcane", "Divine", "Infernal"
	var faction_lower = base.faction.to_lower()
	var overlay_lower = overlay_type.to_lower()
	
	# Generate unique fused ID
	fused.id = "%s_fused_%s_%s" % [target_id, overlay_lower, _generate_fusion_hash(target_id, overlay_id)]
	fused.is_fused = true
	fused.fused_overlay_id = overlay_id
	fused.fused_overlay_type = overlay_type
	
	# Merge keywords (base + overlay)
	fused.keywords = base.keywords.duplicate()
	for kw in overlay.keywords:
		if not kw in fused.keywords:
			fused.keywords.append(kw)
	fused.fused_keywords = overlay.keywords.duplicate()
	
	# Update name and description
	fused.card_name = "%s [%s]" % [base.card_name, overlay_type]
	fused.description = _build_fused_description(base, overlay, overlay_type)
	
	# Set fused frame texture
	var frame_path = "res://assets/sprites/cards/%s_%s_frame.png" % [faction_lower, overlay_lower]
	if ResourceLoader.exists(frame_path):
		fused.frame_texture_path = frame_path
	else:
		push_warning("ImbueManager: Fused frame not found — %s (using base frame)" % frame_path)
		fused.frame_texture_path = base.frame_texture_path
	
	# Preserve sprite art from base card
	fused.sprite_texture_path = base.sprite_texture_path
	
	# Register the fused card in CardDB
	CardDB.cards[fused.id] = fused
	
	# --- Update deck ---
	# Remove both source cards, add fused card
	GameState.remove_card_from_deck(target_id)
	GameState.remove_card_from_deck(overlay_id)
	
	var added = GameState.add_card_to_deck(fused.id)
	if not added:
		# Deck full — this shouldn't happen since we removed 2 and added 1,
		# but fused cards count as 2 toward compiler count
		push_warning("ImbueManager: Failed to add fused card to deck")
		return ""
	
	print("ImbueManager: %s + %s → %s (source: %s)" % [overlay_id, target_id, fused.id, source])
	
	# Emit fusion event for UI/FX
	GameState.deck_changed.emit()
	
	return fused.id

static func _build_fused_description(base: CardData, overlay: CardData, overlay_type: String) -> String:
	"""Build the fused card description showing base + overlay + rider."""
	var desc = base.description
	
	# Add overlay effect
	if not overlay.description.is_empty():
		desc += "\n[Overlay: %s]" % overlay.description
	
	# Add rider effect
	var rider = RIDER_EFFECTS.get(overlay_type, "")
	if not rider.is_empty():
		desc += "\n[Rider: %s]" % rider
	
	# Note compiler weight
	desc += "\n(⚠ Compiler weight: 2)"
	
	return desc

static func _generate_fusion_hash(target_id: String, overlay_id: String) -> String:
	"""Generate a short deterministic hash for fused card IDs."""
	var combined = target_id + "_" + overlay_id
	var hash_val = combined.hash()
	return str(abs(hash_val) % 10000).pad_zeros(4)

# --- Validation Helpers ---

static func can_imbue_in_combat(overlay_id: String, target_id: String, hand: Array[String]) -> bool:
	"""Check if both cards are present in the current hand for free combat fusion."""
	return overlay_id in hand and target_id in hand

static func can_imbue_in_shop(overlay_id: String, target_id: String) -> bool:
	"""Check if both cards are in the deck for paid shop fusion (no hand requirement)."""
	return overlay_id in GameState.player_deck and target_id in GameState.player_deck

static func get_valid_overlay_targets(overlay_id: String, hand_only: bool = false) -> Array[String]:
	"""Get all valid target cards for a given overlay.
	
	Args:
		overlay_id: The overlay card to check
		hand_only: If true, only check current hand. If false, check full deck.
	
	Returns:
		Array of valid target card IDs.
	"""
	var overlay = CardDB.get_card(overlay_id)
	if not overlay or not overlay.is_overlay:
		return []
	
	var source_pool = GameState.player_hand if hand_only and "player_hand" in GameState else GameState.player_deck
	var valid: Array[String] = []
	
	for card_id in source_pool:
		var card = CardDB.get_card(card_id)
		if card and not card.is_overlay and not card.is_fused:
			valid.append(card_id)
	
	return valid

static func get_overlay_cards_in_pool(pool: Array[String]) -> Array[String]:
	"""Filter a card pool to only unfused overlay cards."""
	var overlays: Array[String] = []
	for card_id in pool:
		var card = CardDB.get_card(card_id)
		if card and card.is_overlay and not card.is_fused:
			overlays.append(card_id)
	return overlays

# --- Shop Transmutation ---

static func transmute_in_shop(overlay_id: String, target_id: String) -> String:
	"""Paid shop fusion. Costs 15 Gems. No hand requirement."""
	if GameState.gems < FUSION_GEM_COST:
		push_warning("ImbueManager: Not enough gems for transmutation (%d < %d)" % [GameState.gems, FUSION_GEM_COST])
		return ""
	
	if not can_imbue_in_shop(overlay_id, target_id):
		push_warning("ImbueManager: Cards not in deck — overlay=%s target=%s" % [overlay_id, target_id])
		return ""
	
	GameState.gems -= FUSION_GEM_COST
	GameState.gems_changed.emit(GameState.gems)
	
	return imbue(overlay_id, target_id, "shop")

# --- Overlay Stock Generation ---

static func get_overlay_stock_for_floor(floor_num: int) -> Array[String]:
	"""Generate overlay card stock for a shop based on floor tier.
	
	Shop tier distribution:
	- Lower floors (1-3): Arcane overlays
	- Mid floors (4-7): Infernal overlays
	- High floors (8-10): Divine overlays
	"""
	var all_overlays = _get_all_overlay_ids()
	var target_type: String = ""
	
	if floor_num <= 3:
		target_type = "Arcane"
	elif floor_num <= 7:
		target_type = "Infernal"
	else:
		target_type = "Divine"
	
	# Filter to target type, shuffle, pick 3
	var candidates: Array[String] = []
	for card_id in all_overlays:
		var card = CardDB.get_card(card_id)
		if card and card.overlay_type == target_type:
			candidates.append(card_id)
	
	candidates.shuffle()
	var stock_size = min(3, candidates.size())
	return candidates.slice(0, stock_size)

static func _get_all_overlay_ids() -> Array[String]:
	"""Get all overlay card IDs from CardDB."""
	var overlays: Array[String] = []
	for card_id in CardDB.cards.keys():
		var card = CardDB.get_card(card_id)
		if card and card.is_overlay:
			overlays.append(card_id)
	return overlays

# --- Fusion Preview (for UI tooltips) ---

static func preview_fusion(overlay_id: String, target_id: String) -> Dictionary:
	"""Generate a preview of what fusion would produce (without actually fusing).
	Returns dict with: name, description, frame_path, compiler_weight, valid (bool)"""
	var overlay = CardDB.get_card(overlay_id)
	var base = CardDB.get_card(target_id)
	
	if not overlay or not base or not overlay.is_overlay or base.is_overlay or base.is_fused:
		return {"valid": false}
	
	var faction_lower = base.faction.to_lower()
	var overlay_lower = overlay.overlay_type.to_lower()
	var frame_path = "res://assets/sprites/cards/%s_%s_frame.png" % [faction_lower, overlay_lower]
	
	return {
		"valid": true,
		"name": "%s [%s]" % [base.card_name, overlay.overlay_type],
		"description": _build_fused_description(base, overlay, overlay.overlay_type),
		"frame_path": frame_path if ResourceLoader.exists(frame_path) else base.frame_texture_path,
		"compiler_weight": 2,
		"gem_cost": FUSION_GEM_COST
	}
