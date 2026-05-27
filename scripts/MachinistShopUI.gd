extends CanvasLayer
class_name MachinistShopUI

# MachinistShopUI — "The Machinist" at Crown Cog
# Buy offerings with gems, sell offerings for gems, upgrade cards with keyword injection, buy consumables

signal shop_closed
signal boss_challenged

# Shop State
var current_tab: String = "buy"  # buy | sell | consumables | upgrade | equipment | overlays | inventory
var shop_stock: Array[Dictionary] = []  # {offering_id, price, quantity}
var selected_card_index: int = -1
var selected_offering_index: int = -1

# Keyword Database (all injectable keywords)
const KEYWORD_DATABASE: Dictionary = {
	"precision": {"name": "Precision", "faction": "Construct", "cost": 15, "desc": "Attack immediately when summoned"},
	"machine": {"name": "Machine", "faction": "Construct", "cost": 15, "desc": "Averages damage dealt by/to"},
	"sneaky": {"name": "Sneaky", "faction": "Goblin", "cost": 15, "desc": "+2d6 if enemy lacks keyword"},
	"sharp": {"name": "Sharp", "faction": "Goblin", "cost": 15, "desc": "Damage scale +1"},
	"fast": {"name": "Fast", "faction": "Goblin", "cost": 15, "desc": "Resolves before enemy actions"},
	"death": {"name": "Death", "faction": "Undead", "cost": 15, "desc": "Cast from Discard by sacrificing lowest-HP summon. Still costs attention."},
	"bone": {"name": "Bone", "faction": "Universal", "cost": 15, "desc": "Gain shield = attention cost (vanishes next turn)"},
	"poison": {"name": "Poison", "faction": "Goblin", "cost": 15, "desc": "Applies poison DoT on cast (3 dmg/turn, 4 turns)"},
	"fire": {"name": "Fire", "faction": "Elemental", "cost": 15, "desc": "Applies fire DoT on cast (4 dmg/turn, 2 turns)"},
	"corruption": {"name": "Corruption", "faction": "Demon", "cost": 15, "desc": "Applies corruption DoT on cast (2 dmg/turn, 3 turns)"},
	"glitch": {"name": "Glitch", "faction": "Aberration", "cost": 15, "desc": "25% chance for bonus effect based on card type (heal, cost reduction, AoE damage)"},
	"pact": {"name": "Pact", "faction": "Demon", "cost": 15, "desc": "Triggers again next turn (with attention cost, can debt)"},
	"void": {"name": "Void", "faction": "Aberration", "cost": 15, "desc": "Counts as NO keywords. Same-faction target = backfire"},
	"nature": {"name": "Nature", "faction": "Elemental", "cost": 15, "desc": "+2 dmg per CHARGE. Ignores Shield"},
	"flow": {"name": "Flow", "faction": "Elemental", "cost": 15, "desc": "+1d6 per CHARGE. Consume CHARGE for burst"}
}

# Consumables
const CONSUMABLES: Array[Dictionary] = [
	{"id": "hp_potion_small", "name": "Gear Grease", "heal": 15, "cost": 5, "desc": "Thick lubricant that soothes metal wounds. +15 HP."},
	{"id": "hp_potion_medium", "name": "Brass Tonic", "heal": 30, "cost": 10, "desc": "Warm restorative brewed from copper salts. +30 HP."},
	{"id": "hp_potion_full", "name": "Machinist's Elixir", "heal": 999, "cost": 25, "desc": "The Machinist's personal blend. Full heal."}
]

const MAX_UPGRADE_SLOTS: int = 2

# Visual nodes
var main_panel: PanelContainer
var tab_container: HBoxContainer
var content_container: VBoxContainer
var currency_label: Label
var boss_btn: Button

# Styling
const CARD_WIDTH: float = 140.0
const CARD_HEIGHT: float = 200.0
const SLOT_SIZE: Vector2 = Vector2(120, 140)

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS

func show_shop():
	"""Show the Machinist shop. Always available at Crown Cog."""
	current_tab = "buy"
	selected_card_index = -1
	selected_offering_index = -1
	_generate_shop_stock()
	_build_ui()
	visible = true

func _generate_shop_stock():
	shop_stock.clear()
	var cleared = GameState.get_cleared_room_count()
	var pool = GameState.OFFERING_DATABASE.keys()
	pool.shuffle()
	var stock_size = clamp(3 + cleared / 2, 3, 8)
	for i in range(min(stock_size, pool.size())):
		var offering_id = pool[i]
		var data = GameState.get_offering_data(offering_id)
		var base_price = data.get("gem_value", 2)
		var price = base_price + randi() % 3
		shop_stock.append({
			"offering_id": offering_id,
			"price": price,
			"quantity": 1,
			"name": data.get("name", offering_id),
			"description": data.get("description", ""),
			"sprite": data.get("sprite", ""),
			"quality": data.get("quality", 1)
		})

# --- UI Building ---

func _build_ui():
	for child in get_children():
		child.queue_free()
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.9)
	bg.size = get_viewport().get_visible_rect().size if get_viewport() else Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	main_panel = PanelContainer.new()
	main_panel.size = Vector2(1000, 700)
	main_panel.position = Vector2(460, 190)
	add_child(main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(main_vbox)
	
	main_vbox.add_child(_create_header())
	
	tab_container = HBoxContainer.new()
	tab_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(tab_container)
	
	var tab_names = [
		{"id": "buy", "label": "Buy Offerings"},
		{"id": "sell", "label": "Sell Offerings"},
		{"id": "consumables", "label": "Consumables"},
		{"id": "upgrade", "label": "Upgrade Cards"},
		{"id": "equipment", "label": "Equipment"},
		{"id": "overlays", "label": "Overlays"},
		{"id": "inventory", "label": "Inventory"}
	]
	for tab in tab_names:
		var btn = Button.new()
		btn.name = "Tab_" + tab.id
		btn.text = tab.label
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
		btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
		btn.name = "Tab_" + tab.id
		btn.text = tab.label
		btn.toggle_mode = true
		btn.button_pressed = tab.id == current_tab
		btn.pressed.connect(_on_tab_changed.bind(tab.id))
		btn.custom_minimum_size = Vector2(120, 35)
		btn.add_theme_font_size_override("font_size", 12)
		tab_container.add_child(btn)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 8)
	main_vbox.add_child(content_container)
	
	main_vbox.add_child(_create_bottom_bar())
	_refresh_content()

func _create_header() -> HBoxContainer:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	
	var title = Label.new()
	title.text = "🔧 THE MACHINIST"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	header.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "  " + _get_machinist_flavor()
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	header.add_child(subtitle)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.add_theme_font_size_override("font_size", 18)
	currency_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	header.add_child(currency_label)
	_update_currency_display()
	
	return header

func _get_machinist_flavor() -> String:
	var flavors = [
		"*clank* ... *whir* ... what do you need?",
		"Gears don't lie. People do.",
		"I deal in grease and gems. You?",
		"The machine provides. For a price.",
		"*grind* ... *click* ... show me your gems."
	]
	return flavors[randi() % flavors.size()]

func _create_bottom_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	
	boss_btn = Button.new()
	boss_btn.name = "BossButton"
	boss_btn.text = "⚔ Challenge Boss"
	boss_btn.custom_minimum_size = Vector2(160, 45)
	boss_btn.add_theme_font_size_override("font_size", 15)
	boss_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	boss_btn.pressed.connect(_on_challenge_boss)
	bar.add_child(boss_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Leave"
	close_btn.custom_minimum_size = Vector2(100, 45)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.pressed.connect(_on_close_shop)
	bar.add_child(close_btn)
	
	return bar

# --- Content Refreshers ---

func _refresh_content():
	for child in content_container.get_children():
		child.queue_free()
	
	match current_tab:
		"buy": _refresh_buy_tab()
		"sell": _refresh_sell_tab()
		"consumables": _refresh_consumables_tab()
		"upgrade": _refresh_upgrade_tab()
		"equipment": _refresh_equipment_tab()
		"overlays": _refresh_overlays_tab()
		"inventory": _refresh_inventory_tab()
	
	_update_currency_display()
	_update_tab_buttons()

func _refresh_buy_tab():
	var label = Label.new()
	label.text = "Buy offerings with gems:"
	label.add_theme_font_size_override("font_size", 14)
	content_container.add_child(label)
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content_container.add_child(grid)
	
	for i in range(shop_stock.size()):
		var slot = _create_offering_slot(i, shop_stock[i], true)
		grid.add_child(slot)
	
	if shop_stock.is_empty():
		var empty = Label.new()
		empty.text = "Out of stock. Clear more rooms for better offerings."
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		content_container.add_child(empty)

func _refresh_sell_tab():
	var header = Label.new()
	header.text = "Sell offerings from your inventory:"
	header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(header)
	
	if GameState.inventory_offerings.is_empty():
		var empty = Label.new()
		empty.text = "Your inventory is empty."
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		content_container.add_child(empty)
		return
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content_container.add_child(grid)
	
	for i in range(GameState.inventory_offerings.size()):
		var item_id = GameState.inventory_offerings[i]
		var data = GameState.get_offering_data(item_id)
		var item = {
			"offering_id": item_id,
			"price": data.get("gem_value", 2),
			"name": data.get("name", item_id),
			"description": data.get("description", ""),
			"sprite": data.get("sprite", ""),
			"quality": data.get("quality", 1)
		}
		var slot = _create_offering_slot(i, item, false)
		grid.add_child(slot)

func _refresh_consumables_tab():
	var header = Label.new()
	header.text = "Buy consumables with gems:"
	header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(header)
	
	var subtitle = Label.new()
	subtitle.text = "Current HP: %d/%d" % [GameState.player_hp, GameState.player_max_hp]
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	content_container.add_child(subtitle)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	content_container.add_child(grid)
	
	for item in CONSUMABLES:
		var panel = _create_consumable_slot(item)
		grid.add_child(panel)

func _create_consumable_slot(item: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 160)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.5))
	vbox.add_child(name_label)
	
	var desc = Label.new()
	desc.text = item["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var effect = Label.new()
	effect.text = "❤ +%d HP" % item["heal"] if item["heal"] < 100 else "❤ Full Heal"
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.add_theme_font_size_override("font_size", 12)
	effect.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(effect)
	
	var price = Label.new()
	price.text = "%d💎" % item["cost"]
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 12)
	price.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(price)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "Buy"
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	btn.text = "Buy"
	btn.disabled = GameState.gems < item["cost"]
	btn.pressed.connect(_on_buy_consumable.bind(item))
	vbox.add_child(btn)
	
	return panel

func _refresh_upgrade_tab():
	var header = Label.new()
	header.text = "Keyword Upgrades — inject new mechanics into your cards:"
	header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(header)
	
	var subtitle = Label.new()
	subtitle.text = "Each card has 2 upgrade slots. Native keywords are free."
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	content_container.add_child(subtitle)
	
	var deck = GameState.get_deck_card_data()
	if deck.is_empty():
		var empty = Label.new()
		empty.text = "No cards in deck."
		content_container.add_child(empty)
		return
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(600, 350)
	content_container.add_child(scroll)
	
	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	
	for i in range(deck.size()):
		var row = _create_keyword_upgrade_row(i, deck[i])
		list.add_child(row)

func _create_keyword_upgrade_row(index: int, card: CardData) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(700, 80)
	row.name = "CardRow_%d" % index
	
	# Card info
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size = Vector2(250, 80)
	
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [card.card_name, card.card_type]
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", _get_faction_color(card.faction))
	info.add_child(name_label)
	
	# Current keywords
	var kw_text = _get_keyword_display(card)
	var kw_label = Label.new()
	kw_label.text = kw_text
	kw_label.add_theme_font_size_override("font_size", 10)
	kw_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	info.add_child(kw_label)
	
	# Upgrade slots
	var slot_text = _get_slot_display(card)
	var slot_label = Label.new()
	slot_label.text = slot_text
	slot_label.add_theme_font_size_override("font_size", 10)
	if card.keywords.size() >= MAX_UPGRADE_SLOTS:
		slot_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		slot_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	info.add_child(slot_label)
	
	row.add_child(info)
	
	# Available keyword buttons
	var btn_container = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 4)
	
	var available_slots = MAX_UPGRADE_SLOTS - card.keywords.size()
	
	if available_slots > 0:
		for kw_id in KEYWORD_DATABASE.keys():
			# Skip if card already has this keyword
			var has_it = false
			for existing in card.keywords:
				if existing.to_lower() == kw_id:
					has_it = true
					break
			if has_it:
				continue
			
			var kw_data = KEYWORD_DATABASE[kw_id]
			var cost = kw_data["cost"]
			var can_afford = GameState.gems >= cost
			
			var btn = Button.new()
			btn.text = "+%s (%d💎)" % [kw_data["name"], cost]
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
			btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
			btn.custom_minimum_size = Vector2(80, 28)
			btn.add_theme_font_size_override("font_size", 9)
			btn.disabled = not can_afford
			btn.pressed.connect(_on_inject_keyword.bind(index, card.id, kw_id))
			btn_container.add_child(btn)
	else:
		var full = Label.new()
		full.text = "FULL"
		full.add_theme_font_size_override("font_size", 12)
		full.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		btn_container.add_child(full)
	
	row.add_child(btn_container)
	
	return row

func _get_keyword_display(card: CardData) -> String:
	if card.keywords.size() == 0:
		return "Keywords: (none)"
	var parts: Array[String] = []
	for kw in card.keywords:
		parts.append(kw.capitalize())
	return "Keywords: " + ", ".join(parts)

func _get_slot_display(card: CardData) -> String:
	var used = card.keywords.size()
	var total = MAX_UPGRADE_SLOTS
	if used >= total:
		return "Slots: ⚫⚫ (FULL)"
	var filled = "⚫".repeat(used)
	var empty = "⚪".repeat(total - used)
	return "Slots: %s%s" % [filled, empty]

func _refresh_inventory_tab():
	var header = Label.new()
	header.text = "Your Offering Inventory (%d/10):" % GameState.inventory_offerings.size()
	header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(header)
	
	var gems_summary = Label.new()
	gems_summary.text = "Gems: %d💎  |  Deck: %d/50  |  HP: %d/%d" % [
		GameState.gems, GameState.player_deck.size(),
		GameState.player_hp, GameState.player_max_hp
	]
	gems_summary.add_theme_font_size_override("font_size", 12)
	gems_summary.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	content_container.add_child(gems_summary)
	
	if GameState.inventory_offerings.is_empty():
		var empty = Label.new()
		empty.text = "No offerings carried."
		content_container.add_child(empty)
		return
	
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content_container.add_child(grid)
	
	for item_id in GameState.inventory_offerings:
		var data = GameState.get_offering_data(item_id)
		var slot = _create_inventory_slot(data)
		grid.add_child(slot)
	
	for i in range(10 - GameState.inventory_offerings.size()):
		var empty = _create_empty_slot()
		grid.add_child(empty)

func _refresh_equipment_tab():
	"""Equipment shop tab — buy, equip, and manage gear."""
	var floor_num = GameState.current_floor if GameState.current_floor > 0 else 3
	var stock = GameState.get_shop_stock_for_floor(floor_num)
	
	# --- Currently Equipped Section ---
	var equipped_header = Label.new()
	equipped_header.text = "Currently Equipped:"
	equipped_header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(equipped_header)
	
	var equipped_grid = GridContainer.new()
	equipped_grid.columns = 4
	equipped_grid.add_theme_constant_override("h_separation", 12)
	equipped_grid.add_theme_constant_override("v_separation", 12)
	content_container.add_child(equipped_grid)
	
	var equipped_items = [
		{"id": GameState.equipped_weapon, "cat": "weapon", "label": "Weapon"},
		{"id": GameState.equipped_armor, "cat": "armor", "label": "Armor"},
		{"id": GameState.equipped_shield, "cat": "shield", "label": "Shield"},
		{"id": GameState.equipped_trinket, "cat": "trinket", "label": "Trinket"}
	]
	
	for item in equipped_items:
		var slot = _create_equipment_slot(item["id"], item["cat"], item["label"], true)
		equipped_grid.add_child(slot)
	
	# --- Buy New Equipment Section ---
	var buy_header = Label.new()
	buy_header.text = "Available Equipment (Floor %d):" % floor_num
	buy_header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(buy_header)
	
	for category in ["weapons", "armor", "shields", "trinkets"]:
		var cat_label = Label.new()
		cat_label.text = category.capitalize() + ":"
		cat_label.add_theme_font_size_override("font_size", 12)
		cat_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
		content_container.add_child(cat_label)
		
		var grid = GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		content_container.add_child(grid)
		
		for item_id in stock[category]:
			var data = GameState.get_equipment_data(item_id, category.rstrip("s"))
			if not data.is_empty():
				var slot = _create_equipment_slot(item_id, category.rstrip("s"), data["name"], false)
				grid.add_child(slot)
		
		if stock[category].is_empty():
			var empty = Label.new()
			empty.text = "Nothing available yet."
			empty.add_theme_font_size_override("font_size", 10)
			empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
			content_container.add_child(empty)

func _create_equipment_slot(item_id: String, category: String, name_label: String, is_equipped: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 160)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Icon — use item-specific if available, fallback to category generic
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon.custom_minimum_size = Vector2(64, 64)
	
	var icon_path = ""
	if not item_id.is_empty():
		# Try item-specific icon first
		icon_path = "res://assets/sprites/ui/%s_%s.png" % [category, item_id]
		if not ResourceLoader.exists(icon_path):
			icon_path = ""
	
	if icon_path.is_empty():
		# Fallback to category generic
		icon_path = "res://assets/sprites/ui/ui_equip_%s.png" % category
	
	var tex = load(icon_path)
	if tex:
		icon.texture = tex
	vbox.add_child(icon)
	
	# Name
	var name = Label.new()
	name.text = name_label if not item_id.is_empty() else "None"
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name)
	
	if not item_id.is_empty():
		var data = GameState.get_equipment_data(item_id, category)
		if not data.is_empty():
			# Cost / stats
			var stats = Label.new()
			stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			stats.add_theme_font_size_override("font_size", 9)
			stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
			
			if category == "weapon":
				stats.text = "%d-%d dmg | Charge %d" % [data.get("damage_min", 0), data.get("damage_max", 0), data.get("charge", 0)]
			elif category == "armor":
				stats.text = "+%d HP | %s" % [data.get("hp_bonus", 0), data.get("special", "")]
			elif category == "shield":
				stats.text = "%s | %s" % [data.get("type", "").capitalize(), data.get("desc", "")]
			else:
				stats.text = data.get("desc", "")
			vbox.add_child(stats)
		
			# Cost
			var cost = Label.new()
			cost.text = "%d💎" % data.get("cost", 0)
			cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cost.add_theme_font_size_override("font_size", 10)
			cost.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
			vbox.add_child(cost)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Action button
	var btn = Button.new()
	if is_equipped:
		if item_id.is_empty():
			btn.text = "Empty"
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
		btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	if is_equipped:
		if item_id.is_empty():
			btn.text = "Empty"
			btn.disabled = true
		else:
			btn.text = "Unequip"
			btn.pressed.connect(_on_unequip_item.bind(category))
	else:
		if item_id.is_empty():
			btn.text = "Unavailable"
			btn.disabled = true
		else:
			var data = GameState.get_equipment_data(item_id, category)
			var cost = data.get("cost", 0)
			var can_afford = GameState.gems >= cost
			var already_owned = (item_id in GameState.inventory_weapons or 
							   item_id in GameState.inventory_armor or
							   item_id in GameState.inventory_shields or
							   item_id in GameState.inventory_trinkets)
			
			if already_owned:
				btn.text = "Equip"
				btn.pressed.connect(_on_equip_item.bind(item_id, category))
			else:
				btn.text = "Buy (%d💎)" % cost
				btn.disabled = not can_afford
				btn.pressed.connect(_on_buy_equipment.bind(item_id, category, cost))
	
	btn.custom_minimum_size = Vector2(100, 28)
	vbox.add_child(btn)
	
	return panel

func _on_buy_equipment(item_id: String, category: String, cost: int):
	if GameState.gems < cost:
		_show_notification("Not enough gems!", Color(0.9, 0.5, 0.2))
		return
	
	GameState.gems -= cost
	match category:
		"weapon": GameState.inventory_weapons.append(item_id)
		"armor": GameState.inventory_armor.append(item_id)
		"shield": GameState.inventory_shields.append(item_id)
		"trinket": GameState.inventory_trinkets.append(item_id)
	
	_refresh_content()
	var data = GameState.get_equipment_data(item_id, category)
	_show_notification("Bought %s!" % data.get("name", item_id), Color(0.3, 0.9, 0.3))

func _on_equip_item(item_id: String, category: String):
	if GameState.equip_item(item_id, category):
		AudioManager.play_sfx("equip")
		_refresh_content()
		var data = GameState.get_equipment_data(item_id, category)
		_show_notification("Equipped %s!" % data.get("name", item_id), Color(0.3, 0.9, 0.3))
	else:
		_show_notification("Failed to equip!", Color(0.9, 0.5, 0.2))

func _on_unequip_item(category: String):
	var old_id = GameState.unequip_item(category)
	if not old_id.is_empty():
		_refresh_content()
		var data = GameState.get_equipment_data(old_id, category)
		_show_notification("Unequipped %s" % data.get("name", old_id), Color(0.9, 0.7, 0.3))

# --- Slot / Row Creators (Buy/Sell) ---

func _create_offering_slot(index: int, item: Dictionary, is_buy: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.name = "OfferingSlot_%d" % index
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var sprite_path = item.get("sprite", "")
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var sprite = TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		sprite.custom_minimum_size = Vector2(80, 60)
		sprite.texture = load(sprite_path)
		vbox.add_child(sprite)
	else:
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(80, 60)
		placeholder.color = _get_quality_color(item.get("quality", 1))
		vbox.add_child(placeholder)
	
	var name_label = Label.new()
	name_label.text = item.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", _get_quality_color(item.get("quality", 1)))
	vbox.add_child(name_label)
	
	var price_label = Label.new()
	price_label.text = "%d💎" % item.get("price", 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(price_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	if is_buy:
		btn.text = "Buy"
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
		btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	if is_buy:
		btn.text = "Buy"
		var price = item.get("price", 0)
		btn.disabled = GameState.gems < price
		btn.pressed.connect(_on_buy_offering.bind(index, item.get("offering_id"), price))
	else:
		btn.text = "Sell"
		btn.pressed.connect(_on_sell_offering.bind(index, item.get("offering_id"), item.get("price", 0)))
	btn.custom_minimum_size = Vector2(80, 28)
	vbox.add_child(btn)
	
	return panel

func _create_inventory_slot(data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 120)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var sprite_path = data.get("sprite", "")
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		var sprite = TextureRect.new()
		sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		sprite.custom_minimum_size = Vector2(60, 50)
		sprite.texture = load(sprite_path)
		vbox.add_child(sprite)
	else:
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(60, 50)
		placeholder.color = _get_quality_color(data.get("quality", 1))
		vbox.add_child(placeholder)
	
	var name_label = Label.new()
	name_label.text = data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", _get_quality_color(data.get("quality", 1)))
	vbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = "%d💎" % data.get("gem_value", 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(value_label)
	
	return panel

func _create_empty_slot() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 120)
	
	var label = Label.new()
	label.text = "Empty"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	panel.add_child(label)
	
	return panel

# --- Overlay Shop Functions ---

func _refresh_overlays_tab():
	"""Overlay shop tab — buy overlay cards with gems."""
	var header = Label.new()
	header.text = "Overlay Cards — Fuse with faction cards for power (⚠ counts as 2 toward Compiler)"
	header.add_theme_font_size_override("font_size", 14)
	content_container.add_child(header)
	
	var subtitle = Label.new()
	var floor_num = GameState.current_floor if GameState.current_floor > 0 else 1
	var shop_tier = "Arcane" if floor_num <= 3 else ("Infernal" if floor_num <= 7 else "Divine")
	subtitle.text = "Floor %d shop tier: %s Overlays | Compiler: %d/%d" % [
		floor_num, shop_tier, GameState.get_compiler_count(), GameState.deck_max_size
	]
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	content_container.add_child(subtitle)
	
	var overlay_stock = GameState.get_overlay_stock_for_floor(floor_num)
	
	if overlay_stock.is_empty():
		var empty = Label.new()
		empty.text = "No overlay cards available on this floor."
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		content_container.add_child(empty)
		return
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	content_container.add_child(grid)
	
	for card_id in overlay_stock:
		var slot = _create_overlay_slot(card_id)
		grid.add_child(slot)

func _create_overlay_slot(card_id: String) -> PanelContainer:
	var card = CardDB.get_card(card_id)
	if not card:
		return PanelContainer.new()
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 280)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = card.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", _get_overlay_color(card.overlay_type))
	vbox.add_child(name_label)
	
	# Overlay type badge
	var type_label = Label.new()
	type_label.text = "[%s Overlay]" % card.overlay_type
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(type_label)
	
	# Card art (frame preview)
	var art_rect = TextureRect.new()
	art_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	art_rect.custom_minimum_size = Vector2(120, 160)
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if card.frame_texture_path != "" and ResourceLoader.exists(card.frame_texture_path):
		var tex = load(card.frame_texture_path)
		if tex:
			art_rect.texture = tex
	else:
		# Fallback: use a generic overlay frame
		var fallback = "res://assets/sprites/cards/%s_frame.png" % card.overlay_type.to_lower()
		if ResourceLoader.exists(fallback):
			var tex = load(fallback)
			if tex:
				art_rect.texture = tex
	vbox.add_child(art_rect)
	
	# Description
	var desc = Label.new()
	desc.text = card.description if not card.description.is_empty() else "Fuse with any faction card."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 9)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(180, 40)
	vbox.add_child(desc)
	
	# Gem cost
	var cost = card.gem_cost if card.gem_cost > 0 else 25
	var price_label = Label.new()
	price_label.text = "%d💎" % cost
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(price_label)
	
	# Compiler warning
	var warn = Label.new()
	warn.text = "⚠ Compiler weight: 1 (2 when fused)"
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.add_theme_font_size_override("font_size", 9)
	warn.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
	vbox.add_child(warn)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Buy button
	var btn = Button.new()
	btn.text = "Buy"
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.7, 0.7))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	btn.disabled = GameState.gems < cost
	btn.pressed.connect(_on_buy_overlay_card.bind(card_id, cost))
	btn.custom_minimum_size = Vector2(100, 28)
	vbox.add_child(btn)
	
	return panel

func _get_overlay_color(overlay_type: String) -> Color:
	match overlay_type:
		"Arcane": return Color(0.3, 0.6, 0.9)
		"Divine": return Color(0.9, 0.8, 0.3)
		"Infernal": return Color(0.9, 0.3, 0.2)
		_: return Color(0.8, 0.8, 0.8)

func _on_buy_overlay_card(card_id: String, cost: int):
	if GameState.gems < cost:
		_show_notification("Not enough gems!", Color(0.9, 0.5, 0.2))
		return
	
	var added = GameState.add_card_to_deck(card_id)
	if not added:
		_show_notification("Compiler threshold reached! Cannot add more cards.", Color(0.9, 0.3, 0.3))
		return
	
	GameState.gems -= cost
	GameState.gems_changed.emit(GameState.gems)
	_refresh_content()
	
	var card = CardDB.get_card(card_id)
	_show_notification("Acquired %s! Fuse it with a faction card." % card.card_name, Color(0.3, 0.9, 0.3))
	print("MachinistShop: Bought overlay %s for %d gems" % [card_id, cost])

# --- Interaction Handlers ---

func _on_tab_changed(tab_id: String):
	current_tab = tab_id
	_refresh_content()

func _on_buy_offering(index: int, offering_id: String, price: int):
	if GameState.gems < price:
		_show_notification("Not enough gems!", Color(0.9, 0.5, 0.2))
		return
	if GameState.inventory_offerings.size() >= 10:
		_show_notification("Inventory full!", Color(0.9, 0.5, 0.2))
		return
	
	GameState.gems -= price
	GameState.add_offering(offering_id)
	shop_stock.remove_at(index)
	_refresh_content()
	_show_notification("Bought %s!" % GameState.get_offering_name(offering_id), Color(0.3, 0.9, 0.3))

func _on_sell_offering(index: int, offering_id: String, price: int):
	if GameState.remove_offering(offering_id):
		GameState.gems += price
		_refresh_content()
		_show_notification("Sold %s for %d💎" % [GameState.get_offering_name(offering_id), price], Color(0.9, 0.7, 0.3))

func _on_buy_consumable(item: Dictionary):
	var cost = item["cost"]
	if GameState.gems < cost:
		_show_notification("Not enough gems!", Color(0.9, 0.5, 0.2))
		return
	
	GameState.gems -= cost
	var heal_amount = item["heal"]
	if heal_amount >= 999:
		GameState.player_hp = GameState.player_max_hp
	else:
		GameState.heal_player(heal_amount)
	
	_refresh_content()
	_show_notification("Used %s! HP: %d/%d" % [item["name"], GameState.player_hp, GameState.player_max_hp], Color(0.3, 0.9, 0.3))

func _on_inject_keyword(index: int, card_id: String, keyword_id: String):
	var card = CardDB.get_card(card_id)
	if not card:
		return
	
	if card.keywords.size() >= MAX_UPGRADE_SLOTS:
		_show_notification("Card is full! (2/2 keywords)", Color(0.9, 0.3, 0.3))
		return
	
	var kw_data = KEYWORD_DATABASE[keyword_id]
	var cost = kw_data["cost"]
	
	if GameState.gems < cost:
		_show_notification("Not enough gems!", Color(0.9, 0.5, 0.2))
		return
	
	# Inject keyword
	GameState.gems -= cost
	card.keywords.append(keyword_id.capitalize())
	
	_refresh_content()
	_show_notification("Injected [%s] into %s!" % [kw_data["name"], card.card_name], Color(0.3, 0.9, 0.3))
	print("MachinistShop: Injected %s into %s" % [keyword_id, card_id])

func _on_challenge_boss():
	visible = false
	shop_closed.emit()
	boss_challenged.emit()

func _on_close_shop():
	visible = false
	shop_closed.emit()

# --- Visual Updates ---

func _update_currency_display():
	if currency_label:
		currency_label.text = "Gems: %d💎" % GameState.gems

func _update_tab_buttons():
	for child in tab_container.get_children():
		if child is Button and child.name.begins_with("Tab_"):
			var tab_id = child.name.replace("Tab_", "")
			child.button_pressed = tab_id == current_tab

func _show_notification(text: String, color: Color):
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(0, -80)
	notif.size = Vector2(main_panel.size.x, 30)
	notif.add_theme_font_size_override("font_size", 14)
	notif.modulate = color
	main_panel.add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", -120, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

# --- Helpers ---

func _get_quality_color(quality: int) -> Color:
	match quality:
		1: return Color(0.6, 0.6, 0.7)
		2: return Color(0.4, 0.7, 0.4)
		3: return Color(0.3, 0.6, 0.9)
		4: return Color(0.9, 0.6, 0.2)
		5: return Color(0.9, 0.3, 0.9)
		_: return Color(0.6, 0.6, 0.7)

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

# --- Input Handling ---

func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_shop()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_on_tab_changed("buy")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_on_tab_changed("sell")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_on_tab_changed("consumables")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_4:
			_on_tab_changed("upgrade")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_5:
			_on_tab_changed("equipment")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_6:
			_on_tab_changed("overlays")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_7:
			_on_tab_changed("inventory")
			get_viewport().set_input_as_handled()
