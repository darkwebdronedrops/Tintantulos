extends CanvasLayer
class_name PostCombatUI

# PostCombatUI — The "Buying cards with Quiddity" screen
# Appears after every combat. Player can:
#   - Buy 0-3 cards from 3 offered picks (costs Quiddity)
#   - Burn a card from their deck for Gems
#   - Confirm and return to overworld

signal rewards_confirmed(bought_cards: Array[String], burned_cards: Array[String], gems_earned: int)
signal ui_closed

# UI State
var quiddity_earned: int = 0
var quiddity_available: int = 0
var card_picks: Array[CardData] = []  # 3 cards offered
var pick_costs: Array[int] = []  # Quiddity cost for each pick
var current_deck: Array[CardData] = []  # Player's current deck
var selected_picks: Array[bool] = [false, false, false]  # Which picks are bought
var burned_card_ids: Array[String] = []  # Cards the player burned
var max_burns: int = 1  # Max cards that can be burned per post-combat
var burns_used: int = 0

# Visual nodes
var main_panel: PanelContainer
var card_pick_container: HBoxContainer
var deck_container: ScrollContainer
var quiddity_label: Label
var gems_label: Label
var deck_count_label: Label
var confirm_btn: Button

# Styling
const CARD_WIDTH: float = 140.0
const CARD_HEIGHT: float = 200.0
const DECK_CARD_HEIGHT: float = 50.0

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS  # Keep processing when game paused

func show_post_combat(victory: bool, quiddity: int, defeated_faction: String = ""):
	"""Show the post-combat reward screen.
	
	Args:
		victory: True if player won
		quiddity: Quiddity earned during combat (from stakes, card plays, etc.)
		defeated_faction: Faction of defeated enemies (for card pick theme)
	"""
	quiddity_earned = quiddity
	quiddity_available = GameState.player_quiddity + quiddity
	burned_card_ids.clear()
	burns_used = 0
	selected_picks = [false, false, false]
	
	# Generate card picks
	_generate_card_picks(defeated_faction)
	
	# Get current deck
	current_deck = GameState.get_deck_card_data()
	
	# Build UI
	_build_ui(victory)
	
	visible = true
	print("PostCombatUI: Show — %s, %d quiddity, faction: %s" % [
		"VICTORY" if victory else "DEFEAT", quiddity, defeated_faction
	])

func _generate_card_picks(faction: String):
	"""Generate 3 card picks from the defeated faction (or random if no faction)."""
	card_picks.clear()
	pick_costs.clear()
	
	# Get pool of cards
	var pool: Array[CardData] = []
	if not faction.is_empty():
		pool = CardDB.get_cards_by_faction(faction)
	
	# Fallback to Universal or random if faction pool too small
	if pool.size() < 3:
		var universal = CardDB.get_cards_by_faction("Universal")
		pool.append_array(universal)
	
	# Fallback to all cards if still too small
	if pool.size() < 3:
		for card in CardDB.cards.values():
			pool.append(card)
	
	# Shuffle and pick 3 unique
	pool.shuffle()
	for card in pool:
		if card_picks.size() >= 3:
			break
		# Skip duplicates
		var already_picked = false
		for picked in card_picks:
			if picked.id == card.id:
				already_picked = true
				break
		if not already_picked:
			card_picks.append(card)
			pick_costs.append(_calculate_card_cost(card))
	
	# If still not enough, just fill with basic cards
	while card_picks.size() < 3:
		var basic = CardDB._get_or_create_basic_card("Construct", "Attack")
		basic.id = "basic_fill_%d" % card_picks.size()
		card_picks.append(basic)
		pick_costs.append(1)

func _calculate_card_cost(card: CardData) -> int:
	"""Calculate quiddity cost for a card based on its power."""
	var cost = 1
	
	# Base on attention cost
	cost += card.attention_cost
	
	# Dice cards cost more
	if card.uses_dice:
		cost += 2
	
	# Damage scaling
	cost += card.damage_flat / 5
	
	# Summons
	cost += card.summon_count * 2
	cost += card.summon_hp / 5
	cost += card.summon_attack / 3
	
	# Shield/heal
	cost += card.shield_amount / 5
	cost += card.heal_amount / 5
	
	# Special effects
	if not card.special_effect.is_empty():
		cost += 2
	
	# Overlay cards are expensive
	if card.is_overlay:
		cost += 5
	
	# Keywords add cost
	cost += card.keywords.size()
	
	return clamp(cost, 1, 20)

func _calculate_burn_value(card: CardData) -> int:
	"""Calculate gems earned when burning a card."""
	return GameState._calculate_card_gem_value(card)

# --- UI Building ---

func _build_ui(victory: bool):
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Background dim
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	# Main panel — sized and positioned relative to viewport
	var viewport_size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	main_panel = PanelContainer.new()
	main_panel.size = Vector2(min(900, viewport_size.x - 40), min(650, viewport_size.y - 40))
	main_panel.position = Vector2(
		(viewport_size.x - main_panel.size.x) / 2,
		(viewport_size.y - main_panel.size.y) / 2 - 30  # Slightly above center
	)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(main_vbox)
	
	# === HEADER ===
	var header = _create_header(victory)
	main_vbox.add_child(header)
	
	# === CARD PICKS SECTION ===
	var picks_section = _create_picks_section()
	main_vbox.add_child(picks_section)
	
	# === DECK + BURN SECTION ===
	var deck_section = _create_deck_section()
	main_vbox.add_child(deck_section)
	
	# === BOTTOM BAR ===
	var bottom_bar = _create_bottom_bar()
	main_vbox.add_child(bottom_bar)
	
	# Update all displays
	_update_currency_display()
	_update_deck_count()

func _create_header(victory: bool) -> HBoxContainer:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Title
	var title = Label.new()
	title.text = "⚔ VICTORY ⚔" if victory else "💀 DEFEAT 💀"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if victory else Color(0.9, 0.3, 0.3))
	header.add_child(title)
	
	# Quiddity earned
	var quiddity_icon = Label.new()
	quiddity_icon.text = "  ◈ %d Quiddity earned" % quiddity_earned
	quiddity_icon.add_theme_font_size_override("font_size", 16)
	quiddity_icon.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	header.add_child(quiddity_icon)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Continue button (replaces ESC hint)
	var continue_btn_top = Button.new()
	continue_btn_top.name = "ContinueButtonTop"
	continue_btn_top.text = "Continue"
	continue_btn_top.add_theme_font_size_override("font_size", 12)
	continue_btn_top.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	continue_btn_top.pressed.connect(_on_confirm)
	header.add_child(continue_btn_top)
	
	return header

func _create_picks_section() -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	
	# Section label
	var label = Label.new()
	label.text = "Choose cards to add to your deck:"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	section.add_child(label)
	
	# Card picks container
	card_pick_container = HBoxContainer.new()
	card_pick_container.add_theme_constant_override("separation", 16)
	card_pick_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(card_pick_container)
	
	# Create card pick panels
	for i in range(3):
		var card_panel = _create_card_pick_panel(i)
		card_pick_container.add_child(card_panel)
	
	return section

func _create_card_pick_panel(index: int) -> PanelContainer:
	var card = card_picks[index]
	var cost = pick_costs[index]
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.name = "CardPick_%d" % index
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Gold survivor indicator (header row)
	if card.survives_reset:
		var survivor_row = HBoxContainer.new()
		var crown = Label.new()
		crown.text = "★ GOLD"
		crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crown.add_theme_font_size_override("font_size", 10)
		crown.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		survivor_row.add_child(crown)
		vbox.add_child(survivor_row)
	
	# Card name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", _get_faction_color(card.faction))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# Faction badge
	var faction_label = Label.new()
	faction_label.text = card.faction
	faction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_label.add_theme_font_size_override("font_size", 10)
	faction_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(faction_label)
	
	# Type + cost
	var type_label = Label.new()
	type_label.text = "%s | Cost: %d◈" % [card.card_type, cost]
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(type_label)
	
	# Stats summary
	var stats = _get_card_stats_summary(card)
	if not stats.is_empty():
		var stats_label = Label.new()
		stats_label.text = stats
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 10)
		stats_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		vbox.add_child(stats_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Buy button
	var buy_btn = Button.new()
	buy_btn.name = "BuyButton"
	buy_btn.text = "Buy (%d◈)" % cost
	buy_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	buy_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	buy_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	buy_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	buy_btn.disabled = false
	buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	buy_btn.pressed.connect(_on_buy_card.bind(index))
	vbox.add_child(buy_btn)
	
	# Already owned indicator
	var owned_label = Label.new()
	owned_label.name = "OwnedLabel"
	owned_label.text = "In deck" if _is_card_in_deck(card.id) else ""
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.add_theme_font_size_override("font_size", 9)
	owned_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
	owned_label.visible = _is_card_in_deck(card.id)
	vbox.add_child(owned_label)
	
	# Selection highlight
	var highlight = ColorRect.new()
	highlight.name = "Highlight"
	highlight.color = Color(0.3, 0.9, 0.3, 0.0)
	highlight.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	highlight.z_index = -1
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(highlight)
	
	return panel

func _create_deck_section() -> HBoxContainer:
	var section = HBoxContainer.new()
	section.add_theme_constant_override("separation", 12)
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Left: Deck list
	var deck_vbox = VBoxContainer.new()
	deck_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var deck_header = Label.new()
	deck_header.text = "Your Deck (%d/%d) — Burn cards for Gems:" % [current_deck.size(), GameState.deck_max_size]
	deck_header.add_theme_font_size_override("font_size", 14)
	deck_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	deck_vbox.add_child(deck_header)
	
	deck_container = ScrollContainer.new()
	deck_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_container.custom_minimum_size = Vector2(400, 250)
	deck_vbox.add_child(deck_container)
	
	var deck_list = VBoxContainer.new()
	deck_list.add_theme_constant_override("separation", 4)
	deck_container.add_child(deck_list)
	
	for i in range(current_deck.size()):
		var card = current_deck[i]
		var row = _create_deck_card_row(i, card)
		deck_list.add_child(row)
	
	section.add_child(deck_vbox)
	
	# Right: Currency display
	var currency_vbox = VBoxContainer.new()
	currency_vbox.add_theme_constant_override("separation", 8)
	currency_vbox.custom_minimum_size = Vector2(200, 200)
	
	quiddity_label = Label.new()
	quiddity_label.name = "QuiddityLabel"
	quiddity_label.add_theme_font_size_override("font_size", 16)
	currency_vbox.add_child(quiddity_label)
	
	gems_label = Label.new()
	gems_label.name = "GemsLabel"
	gems_label.add_theme_font_size_override("font_size", 16)
	currency_vbox.add_child(gems_label)
	
	deck_count_label = Label.new()
	deck_count_label.name = "DeckCountLabel"
	deck_count_label.add_theme_font_size_override("font_size", 14)
	currency_vbox.add_child(deck_count_label)
	
	# Gem value reference
	var ref = Label.new()
	ref.text = "Burn value:\nBasic: 1-3 gems\nRare: 4-6 gems\nEpic: 7+ gems"
	ref.add_theme_font_size_override("font_size", 11)
	ref.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	currency_vbox.add_child(ref)
	
	section.add_child(currency_vbox)
	
	return section

func _create_deck_card_row(index: int, card: CardData) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(380, DECK_CARD_HEIGHT)
	row.name = "DeckCard_%d" % index
	
	# Gold survivor indicator
	if card.survives_reset:
		var crown = Label.new()
		crown.text = "★"
		crown.add_theme_font_size_override("font_size", 14)
		crown.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		crown.custom_minimum_size = Vector2(24, DECK_CARD_HEIGHT)
		row.add_child(crown)
	
	# Card name + type
	var name_label = Label.new()
	name_label.custom_minimum_size = Vector2(200, DECK_CARD_HEIGHT)
	name_label.text = "%s (%s)" % [card.card_name, card.card_type]
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", _get_faction_color(card.faction))
	row.add_child(name_label)
	
	# Burn value
	var burn_value = _calculate_burn_value(card)
	var burn_label = Label.new()
	burn_label.text = "+%d💎" % burn_value
	burn_label.add_theme_font_size_override("font_size", 11)
	burn_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	row.add_child(burn_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	
	# Burn button
	var burn_btn = Button.new()
	burn_btn.text = "Burn"
	burn_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	burn_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	burn_btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	burn_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	burn_btn.text = "Burn"
	burn_btn.custom_minimum_size = Vector2(60, 30)
	burn_btn.pressed.connect(_on_burn_card.bind(index, card.id))
	row.add_child(burn_btn)
	
	return row

func _create_bottom_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	
	# Continue button
	var continue_btn = Button.new()
	continue_btn.name = "ContinueButton"
	continue_btn.text = "Continue →"
	continue_btn.custom_minimum_size = Vector2(160, 50)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	continue_btn.pressed.connect(_on_confirm)
	bar.add_child(continue_btn)
	
	return bar

# --- Interaction Handlers ---

func _on_buy_card(index: int):
	var card = card_picks[index]
	var cost = pick_costs[index]
	
	if selected_picks[index]:
		# Deselect (refund)
		selected_picks[index] = false
		quiddity_available += cost
		GameState.remove_card_from_deck(card.id)
		_update_pick_visual(index, false)
		_update_currency_display()
		_update_deck_count()
		return
	
	# Check if can afford
	if quiddity_available < cost:
		_show_notification("Not enough Quiddity! Need %d◈" % cost, Color(0.9, 0.5, 0.2))
		return
	
	# Check deck limit
	if GameState.player_deck.size() >= GameState.deck_max_size:
		_show_notification("Deck full! (%d/%d) Burn a card first." % [GameState.player_deck.size(), GameState.deck_max_size], Color(0.9, 0.5, 0.2))
		return
	
	# Purchase
	if GameState.add_card_to_deck(card.id):
		selected_picks[index] = true
		quiddity_available -= cost
		_update_pick_visual(index, true)
		_update_currency_display()
		_update_deck_count()
		_show_notification("Added %s to deck!" % card.card_name, Color(0.3, 0.9, 0.3))
		# Auto-close after purchase
		call_deferred("_on_confirm")
	else:
		_show_notification("Failed to add card!", Color(0.9, 0.3, 0.3))

func _on_burn_card(index: int, card_id: String):
	# Check burn limit
	if burns_used >= max_burns:
		_show_notification("Can only burn %d card per combat!" % max_burns, Color(0.9, 0.5, 0.2))
		return
	
	# Check if already burned this card
	if card_id in burned_card_ids:
		_show_notification("Already burned this card!", Color(0.9, 0.5, 0.2))
		return
	
	var card = CardDB.get_card(card_id)
	if not card:
		return
	
	var gem_value = _calculate_burn_value(card)
	var result = GameState.burn_card_for_gems(card_id)
	
	if result > 0:
		AudioManager.play_sfx("burn")
		burned_card_ids.append(card_id)
		burns_used += 1
		
		# Remove the row from UI
		var deck_list = deck_container.get_child(0) if deck_container.get_child_count() > 0 else null
		if deck_list:
			var row = deck_list.get_node_or_null("DeckCard_%d" % index)
			if row:
				row.queue_free()
		
		# Refresh current_deck
		current_deck = GameState.get_deck_card_data()
		
		_update_currency_display()
		_update_deck_count()
		_show_notification("Burned %s for %d💎" % [card.card_name, gem_value], Color(0.9, 0.7, 0.3))
		
		# Disable all remaining burn buttons since limit reached
		if burns_used >= max_burns:
			_disable_all_burn_buttons()
		
		# Auto-close after burn
		call_deferred("_on_confirm")
	else:
		_show_notification("Failed to burn card!", Color(0.9, 0.3, 0.3))

func _disable_all_burn_buttons():
	var deck_list = deck_container.get_child(0) if deck_container.get_child_count() > 0 else null
	if deck_list:
		for child in deck_list.get_children():
			var burn_btn = child.get_node_or_null("BurnButton")
			if burn_btn:
				burn_btn.disabled = true
				burn_btn.text = "Burned"

func _on_confirm():
	# Spend the quiddity that was used
	var quiddity_spent = quiddity_earned - (quiddity_available - GameState.player_quiddity)
	if quiddity_spent > 0:
		GameState.spend_quiddity(quiddity_spent)
	
	# Collect bought cards
	var bought_cards: Array[String] = []
	for i in range(3):
		if selected_picks[i]:
			bought_cards.append(card_picks[i].id)
	
	var gems_earned = 0
	for bid in burned_card_ids:
		var card = CardDB.get_card(bid)
		if card:
			gems_earned += _calculate_burn_value(card)
	
	rewards_confirmed.emit(bought_cards, burned_card_ids, gems_earned)
	
	visible = false
	ui_closed.emit()
	
	print("PostCombatUI: Confirmed — bought %d cards, burned %d cards, earned %d gems" % [
		bought_cards.size(), burned_card_ids.size(), gems_earned
	])

# --- Visual Updates ---

func _update_pick_visual(index: int, selected: bool):
	var panel = card_pick_container.get_node_or_null("CardPick_%d" % index)
	if not panel:
		return
	
	var highlight = panel.get_node_or_null("Highlight")
	var buy_btn = panel.get_node_or_null("BuyButton")
	
	if selected:
		if highlight:
			highlight.color = Color(0.3, 0.9, 0.3, 0.3)
		if buy_btn:
			buy_btn.text = "Owned ✓"
			buy_btn.disabled = false  # Allow un-buying
	else:
		if highlight:
			highlight.color = Color(0.3, 0.9, 0.3, 0.0)
		if buy_btn:
			buy_btn.text = "Buy (%d◈)" % pick_costs[index]
			# Disable if can't afford
			buy_btn.disabled = quiddity_available < pick_costs[index]

func _update_currency_display():
	if quiddity_label:
		quiddity_label.text = "Quiddity: %d◈" % quiddity_available
		if quiddity_available < quiddity_earned + GameState.player_quiddity:
			quiddity_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		else:
			quiddity_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	if gems_label:
		gems_label.text = "Gems: %d💎" % GameState.gems
	
	# Update all buy button disabled states
	for i in range(3):
		var panel = card_pick_container.get_node_or_null("CardPick_%d" % i)
		if panel:
			var buy_btn = panel.get_node_or_null("BuyButton")
			if buy_btn and not selected_picks[i]:
				buy_btn.disabled = quiddity_available < pick_costs[i]

func _update_deck_count():
	if deck_count_label:
		deck_count_label.text = "Deck: %d/%d" % [GameState.player_deck.size(), GameState.deck_max_size]
		if GameState.player_deck.size() >= GameState.deck_max_size:
			deck_count_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			deck_count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

func _show_notification(text: String, color: Color):
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(0, -100)
	notif.size = Vector2(main_panel.size.x, 30)
	notif.add_theme_font_size_override("font_size", 14)
	notif.modulate = color
	main_panel.add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", -140, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

# --- Helpers ---

func _is_card_in_deck(card_id: String) -> bool:
	for id in GameState.player_deck:
		if id == card_id:
			return true
	return false

func _get_faction_color(faction: String) -> Color:
	match faction:
		"Construct": return Color(0.7, 0.7, 0.8)
		"Goblin": return Color(0.4, 0.8, 0.4)
		"Undead": return Color(0.6, 0.4, 0.7)
		"Elemental": return Color(0.3, 0.7, 0.9)
		"Demon": return Color(0.9, 0.3, 0.3)
		"Aberration": return Color(0.5, 0.3, 0.7)
		"Dragon": return Color(0.9, 0.6, 0.2)
		"Universal": return Color(0.9, 0.9, 0.7)
		_: return Color(0.8, 0.8, 0.8)

func _get_card_stats_summary(card: CardData) -> String:
	var parts: Array[String] = []
	if card.damage_flat > 0 or card.uses_dice:
		if card.uses_dice:
			parts.append("⚔ %s" % card.damage_dice)
		else:
			parts.append("⚔ %d" % card.damage_flat)
	if card.shield_amount > 0:
		parts.append("🛡 %d" % card.shield_amount)
	if card.heal_amount > 0:
		parts.append("❤ %d" % card.heal_amount)
	if card.summon_count > 0:
		parts.append("👥 %d" % card.summon_count)
	return "  ".join(parts)

# --- Input Handling ---

func _input(event: InputEvent):
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_confirm()
			get_viewport().set_input_as_handled()
