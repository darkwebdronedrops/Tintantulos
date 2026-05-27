extends CanvasLayer
class_name OfferingInventoryUI

# OfferingInventoryUI — Standalone inventory for carried offerings
# Shows 10 slots, item details, kami preferences, boon possibilities
# Open with [I] in overworld

signal inventory_closed

const MAX_SLOTS: int = 10
const QUALITY_COLORS = {
	0: Color(0.5, 0.5, 0.5),   # Trash — grey
	1: Color(0.6, 0.7, 0.6),  # Common — pale green
	2: Color(0.3, 0.6, 0.9),  # Uncommon — blue
	3: Color(0.8, 0.4, 0.9),  # Rare — purple
	4: Color(1.0, 0.6, 0.2),  # Epic — orange
	5: Color(0.9, 0.2, 0.2),  # Legendary — red
}

var selected_slot: int = -1
var slot_panels: Array[PanelContainer] = []
var detail_panel: PanelContainer
var detail_title: Label
var detail_desc: Label
var detail_kami: Label
var detail_boon: Label
var detail_drop_btn: Button

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	GameState.offerings_changed.connect(_refresh_inventory)

func _build_ui():
	for child in get_children():
		child.queue_free()
	
	# Background dim
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.9)
	bg.size = Vector2(1920, 1080)
	bg.position = Vector2.ZERO
	add_child(bg)
	
	# Main panel
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 20)
	main_hbox.position = Vector2(360, 200)
	main_hbox.size = Vector2(1200, 680)
	add_child(main_hbox)
	
	# --- LEFT: Inventory Grid ---
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(500, 680)
	main_hbox.add_child(left_panel)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 12)
	left_vbox.position = Vector2(15, 15)
	left_vbox.size = Vector2(470, 650)
	left_panel.add_child(left_vbox)
	
	# Header
	var header = Label.new()
	header.text = "📦 OFFERINGS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	left_vbox.add_child(header)
	
	# Capacity counter
	var capacity = Label.new()
	capacity.name = "CapacityLabel"
	capacity.text = "Carried: 0 / %d" % MAX_SLOTS
	capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	capacity.add_theme_font_size_override("font_size", 12)
	capacity.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	left_vbox.add_child(capacity)
	
	# Separator
	var sep = ColorRect.new()
	sep.color = Color(0.4, 0.35, 0.3, 0.5)
	sep.custom_minimum_size = Vector2(450, 2)
	left_vbox.add_child(sep)
	
	# Grid: 2 rows x 5 columns
	for row in range(2):
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 8)
		row_hbox.custom_minimum_size = Vector2(470, 140)
		left_vbox.add_child(row_hbox)
		
		for col in range(5):
			var slot_idx = row * 5 + col
			var slot = _create_slot(slot_idx)
			row_hbox.add_child(slot)
			slot_panels.append(slot)
	
	# Bottom hint
	var hint = Label.new()
	hint.text = "[Click] Select  |  [Drop] Remove  |  [ESC] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	left_vbox.add_child(hint)
	
	# --- RIGHT: Detail Panel ---
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(400, 680)
	main_hbox.add_child(detail_panel)
	
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	detail_vbox.position = Vector2(15, 15)
	detail_vbox.size = Vector2(370, 650)
	detail_panel.add_child(detail_vbox)
	
	# Detail header
	var detail_header = Label.new()
	detail_header.text = "🔍 DETAILS"
	detail_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_header.add_theme_font_size_override("font_size", 18)
	detail_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	detail_vbox.add_child(detail_header)
	
	# Detail separator
	var dsep = ColorRect.new()
	dsep.color = Color(0.4, 0.35, 0.3, 0.5)
	dsep.custom_minimum_size = Vector2(350, 2)
	detail_vbox.add_child(dsep)
	
	# Sprite display
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(370, 120)
	detail_vbox.add_child(sprite_container)
	
	var sprite_rect = TextureRect.new()
	sprite_rect.name = "DetailSprite"
	sprite_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	sprite_rect.custom_minimum_size = Vector2(100, 100)
	sprite_rect.visible = false
	sprite_container.add_child(sprite_rect)
	
	# Title
	detail_title = Label.new()
	detail_title.text = "Select an offering"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_size_override("font_size", 16)
	detail_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	detail_vbox.add_child(detail_title)
	
	# Quality stars
	detail_desc = Label.new()
	detail_desc.text = ""
	detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.custom_minimum_size = Vector2(350, 60)
	detail_desc.add_theme_font_size_override("font_size", 12)
	detail_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	detail_vbox.add_child(detail_desc)
	
	# Kami preferences
	detail_kami = Label.new()
	detail_kami.text = ""
	detail_kami.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_kami.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_kami.custom_minimum_size = Vector2(350, 50)
	detail_kami.add_theme_font_size_override("font_size", 11)
	detail_kami.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	detail_vbox.add_child(detail_kami)
	
	# Boon info
	detail_boon = Label.new()
	detail_boon.text = ""
	detail_boon.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	detail_boon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_boon.custom_minimum_size = Vector2(350, 80)
	detail_boon.add_theme_font_size_override("font_size", 11)
	detail_boon.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
	detail_vbox.add_child(detail_boon)
	
	# Spacer
	var dspacer = Control.new()
	dspacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_child(dspacer)
	
	# Drop button
	detail_drop_btn = Button.new()
	detail_drop_btn.text = "Drop Offering"
	detail_drop_btn.disabled = true
	detail_drop_btn.custom_minimum_size = Vector2(200, 40)
	detail_drop_btn.add_theme_font_size_override("font_size", 14)
	detail_drop_btn.pressed.connect(_on_drop_selected)
	detail_vbox.add_child(detail_drop_btn)
	
	# Gem total
	var gem_total = Label.new()
	gem_total.name = "GemTotalLabel"
	gem_total.text = "Total Value: 0💎"
	gem_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem_total.add_theme_font_size_override("font_size", 14)
	gem_total.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	detail_vbox.add_child(gem_total)

func _create_slot(slot_idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "Slot_%d" % slot_idx
	panel.custom_minimum_size = Vector2(90, 130)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	
	# Sprite area
	var sprite_rect = TextureRect.new()
	sprite_rect.name = "SlotSprite"
	sprite_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	sprite_rect.custom_minimum_size = Vector2(70, 55)
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(sprite_rect)
	
	# Name label
	var name_label = Label.new()
	name_label.name = "SlotName"
	name_label.text = "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	vbox.add_child(name_label)
	
	# Quality dot
	var quality_label = Label.new()
	quality_label.name = "SlotQuality"
	quality_label.text = ""
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quality_label.add_theme_font_size_override("font_size", 9)
	quality_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(quality_label)
	
	# Gem value
	var value_label = Label.new()
	value_label.name = "SlotValue"
	value_label.text = ""
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 9)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(value_label)
	
	# Click to select
	var btn = Button.new()
	btn.name = "SlotButton"
	btn.custom_minimum_size = Vector2(80, 20)
	btn.text = "Select"
	btn.add_theme_font_size_override("font_size", 9)
	btn.pressed.connect(_on_slot_selected.bind(slot_idx))
	vbox.add_child(btn)
	
	return panel

func _refresh_inventory():
	"""Refresh all slots based on current inventory."""
	var inventory = GameState.inventory_offerings
	var total_gems = 0
	
	# Update capacity label
	var cap = get_node_or_null("CapacityLabel")
	if cap:
		cap.text = "Carried: %d / %d" % [inventory.size(), MAX_SLOTS]
		if inventory.size() >= MAX_SLOTS:
			cap.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		else:
			cap.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	
	# Fill slots
	for i in range(MAX_SLOTS):
		var panel = slot_panels[i]
		var sprite = panel.get_node("SlotSprite")
		var name_label = panel.get_node("SlotName")
		var quality_label = panel.get_node("SlotQuality")
		var value_label = panel.get_node("SlotValue")
		var btn = panel.get_node("SlotButton")
		
		if i < inventory.size():
			var item_id = inventory[i]
			var data = GameState.get_offering_data(item_id)
			var quality = data.get("quality", 0)
			var gem_val = data.get("gem_value", 0)
			
			# Load sprite
			var sprite_path = data.get("sprite", "")
			if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
				sprite.texture = load(sprite_path)
				sprite.visible = true
			else:
				sprite.visible = false
			
			# Text
			name_label.text = data.get("name", item_id)
			quality_label.text = _stars(quality)
			value_label.text = "%d💎" % gem_val
			
			# Color by quality
			var qcolor = QUALITY_COLORS.get(quality, Color(0.5, 0.5, 0.5))
			name_label.add_theme_color_override("font_color", qcolor)
			quality_label.add_theme_color_override("font_color", qcolor)
			
			btn.text = "Select"
			btn.disabled = false
			total_gems += gem_val
		else:
			# Empty slot
			sprite.visible = false
			name_label.text = "Empty"
			name_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			quality_label.text = ""
			value_label.text = ""
			btn.text = "—"
			btn.disabled = true
	
	# Update total gem value
	var gem_total = get_node_or_null("GemTotalLabel")
	if gem_total:
		gem_total.text = "Total Value: %d💎" % total_gems
	
	# If selected slot is now out of range, clear selection
	if selected_slot >= inventory.size():
		selected_slot = -1
		_clear_detail_panel()
	elif selected_slot >= 0:
		_refresh_detail_panel()

func _on_slot_selected(slot_idx: int):
	selected_slot = slot_idx
	_refresh_detail_panel()

func _refresh_detail_panel():
	var inventory = GameState.inventory_offerings
	if selected_slot < 0 or selected_slot >= inventory.size():
		_clear_detail_panel()
		return
	
	var item_id = inventory[selected_slot]
	var data = GameState.get_offering_data(item_id)
	var quality = data.get("quality", 0)
	var gem_val = data.get("gem_value", 0)
	
	# Sprite
	var sprite_rect = detail_panel.get_node("DetailSprite")
	var sprite_path = data.get("sprite", "")
	if not sprite_path.is_empty() and ResourceLoader.exists(sprite_path):
		sprite_rect.texture = load(sprite_path)
		sprite_rect.visible = true
	else:
		sprite_rect.visible = false
	
	# Title with quality
	var qcolor = QUALITY_COLORS.get(quality, Color(0.5, 0.5, 0.5))
	detail_title.text = "%s\n%s" % [data.get("name", item_id), _stars(quality)]
	detail_title.add_theme_color_override("font_color", qcolor)
	
	# Description
	detail_desc.text = data.get("description", "No description.")
	
	# Find which kami prefer this offering
	var preferred_kami = []
	for kami_id in GameState.KAMI_DATABASE:
		var kami_data = GameState.KAMI_DATABASE[kami_id]
		var preferred = kami_data.get("preferred", [])
		if item_id in preferred:
			preferred_kami.append(kami_data.get("name", kami_id))
	
	if preferred_kami.size() > 0:
		detail_kami.text = "Preferred by:\n" + "\n".join(preferred_kami)
	else:
		detail_kami.text = "No kami specifically prefer this offering.\nMay still be accepted as a generic tribute."
	
	# Show potential boons based on quality
	var boon_text = "Potential blessings if accepted:\n"
	boon_text += _get_boon_preview(item_id, quality)
	detail_boon.text = boon_text
	
	# Enable drop button
	detail_drop_btn.disabled = false

func _get_boon_preview(item_id: String, quality: int) -> String:
	"""Return a preview of what boons this offering might grant based on quality."""
	# Find which kami would grant what for this quality tier
	var previews = []
	
	for kami_id in GameState.KAMI_DATABASE:
		var kami_data = GameState.KAMI_DATABASE[kami_id]
		var preferred = kami_data.get("preferred", [])
		
		if item_id in preferred or kami_data.get("accepts_any", false):
			var boon_key = ""
			if quality >= 5:
				boon_key = kami_data.get("epic_boon", "")
			elif quality >= 3:
				boon_key = kami_data.get("major_boon", "")
			else:
				boon_key = kami_data.get("minor_boon", "")
			
			if boon_key:
				var boon_data = GameState.get_boon_data(boon_key)
				var boon_name = boon_data.get("name", boon_key)
				var boon_desc = boon_data.get("description", "")
				var tier = "EPIC" if quality >= 5 else ("MAJOR" if quality >= 3 else "Minor")
				previews.append("  • %s (%s): %s" % [boon_name, tier, boon_desc])
	
	if previews.is_empty():
		return "  • Unknown blessing (offering quality too low or no receptive kami)"
	
	# Show up to 3 previews
	return "\n".join(previews.slice(0, 3))

func _clear_detail_panel():
	var sprite_rect = detail_panel.get_node("DetailSprite")
	sprite_rect.visible = false
	
	detail_title.text = "Select an offering"
	detail_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	
	detail_desc.text = "Click an offering in your inventory to see details, kami preferences, and potential blessings."
	detail_kami.text = ""
	detail_boon.text = ""
	
	detail_drop_btn.disabled = true

func _on_drop_selected():
	if selected_slot < 0 or selected_slot >= GameState.inventory_offerings.size():
		return
	
	var item_id = GameState.inventory_offerings[selected_slot]
	var item_name = GameState.get_offering_name(item_id)
	
	# Remove from inventory
	GameState.remove_offering(item_id)
	
	# Show notification
	_show_notification("Dropped %s" % item_name, Color(0.7, 0.7, 0.7))
	
	selected_slot = -1
	_refresh_inventory()

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.8)):
	var notif = Label.new()
	notif.text = text
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(760, 900)
	notif.size = Vector2(400, 30)
	notif.add_theme_font_size_override("font_size", 14)
	notif.modulate = color
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 850, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

func show_inventory():
	visible = true
	selected_slot = -1
	_refresh_inventory()
	_clear_detail_panel()

func hide_inventory():
	visible = false
	selected_slot = -1

func _stars(quality: int) -> String:
	"""Generate star string for quality rating."""
	if quality <= 0:
		return "☆"
	var s = ""
	for i in range(quality):
		s += "★"
	return s

func _input(event: InputEvent):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				hide_inventory()
				inventory_closed.emit()
				get_viewport().set_input_as_handled()
			KEY_I:
				hide_inventory()
				inventory_closed.emit()
				get_viewport().set_input_as_handled()
