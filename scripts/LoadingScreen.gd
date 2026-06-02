extends CanvasLayer
class_name LoadingScreen

# LoadingScreen - Floor transition with backdrop fade
# Usage: LoadingScreen.show_for_floor(floor_num, parent_node)

var backdrop: TextureRect
var floor_name_label: Label
var subtitle_label: Label
var loading_bar: ProgressBar
var fade_rect: ColorRect

var _target_scene: String = ""
var _is_loading: bool = false

func _ready():
	visible = false
	layer = 100
	_create_ui()

func _create_ui():
	# Full-screen black fade
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.color = Color(0, 0, 0, 0)
	add_child(fade_rect)
	
	# Backdrop image
	backdrop = TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	backdrop.modulate = Color(1, 1, 1, 0)
	add_child(backdrop)
	
	# Dark overlay for text readability (reduced opacity)
	var vignette = ColorRect.new()
	vignette.name = "Vignette"
	vignette.anchor_right = 1.0
	vignette.anchor_bottom = 1.0
	vignette.color = Color(0, 0, 0, 0.35)
	add_child(vignette)
	
	# Floor name
	floor_name_label = Label.new()
	floor_name_label.name = "FloorName"
	floor_name_label.anchor_right = 1.0
	floor_name_label.anchor_bottom = 1.0
	floor_name_label.offset_top = -60
	floor_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floor_name_label.add_theme_font_size_override("font_size", 72)
	floor_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	floor_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	floor_name_label.add_theme_constant_override("font_outline_size", 4)
	floor_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	floor_name_label.add_theme_constant_override("font_shadow_offset_x", 4)
	floor_name_label.add_theme_constant_override("font_shadow_offset_y", 4)
	floor_name_label.modulate = Color(1, 1, 1, 0)
	add_child(floor_name_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.anchor_right = 1.0
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.offset_top = 40
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	subtitle_label.add_theme_constant_override("font_outline_size", 2)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	subtitle_label.add_theme_constant_override("font_shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("font_shadow_offset_y", 2)
	subtitle_label.modulate = Color(1, 1, 1, 0)
	add_child(subtitle_label)
	
	# Loading bar
	loading_bar = ProgressBar.new()
	loading_bar.name = "LoadingBar"
	loading_bar.anchor_left = 0.3
	loading_bar.anchor_right = 0.7
	loading_bar.anchor_top = 0.88
	loading_bar.anchor_bottom = 0.92
	loading_bar.min_value = 0
	loading_bar.max_value = 100
	loading_bar.value = 0
	loading_bar.modulate = Color(1, 1, 1, 0)
	add_child(loading_bar)

# Floor data
const FLOOR_BACKDROPS = {
	2: "res://assets/sprites/floor2/bg_entry_old.png",
}

const FLOOR_NAMES = {
	2: "Floor 2 — The Spore",
}

const FLOOR_SUBTITLES = {
	2: "Beneath the garden, the roots remember.",
}

func show_for_floor(floor_num: int):
	_setup_for_floor(floor_num)

func _setup_for_floor(floor_num: int):
	var backdrop_path = FLOOR_BACKDROPS.get(floor_num, "")
	if backdrop_path != "":
		var tex = load(backdrop_path)
		if tex:
			backdrop.texture = tex
		else:
			push_warning("LoadingScreen: Could not load backdrop %s" % backdrop_path)
	
	floor_name_label.text = FLOOR_NAMES.get(floor_num, "Floor %d" % floor_num)
	subtitle_label.text = FLOOR_SUBTITLES.get(floor_num, "")
	
	visible = true
	_is_loading = true
	
	_fade_in()

func _fade_in():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_property(backdrop, "modulate:a", 0.7, 0.8).set_delay(0.2)
	tween.tween_property(floor_name_label, "modulate:a", 1.0, 0.6).set_delay(0.4)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6).set_delay(0.6)
	tween.tween_property(loading_bar, "modulate:a", 1.0, 0.4).set_delay(0.5)
	await tween.finished
	loading_ready.emit()

func _fade_out():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(floor_name_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(loading_bar, "modulate:a", 0.0, 0.3)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.5)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5).set_delay(0.2)
	await tween.finished
	visible = false
	_is_loading = false

func transition_to(scene_path: String, hold_time: float = 2.0):
	"""Show loading screen, wait, then change scene and fade out."""
	_target_scene = scene_path
	
	# Animate loading bar
	var tween = create_tween()
	tween.tween_property(loading_bar, "value", 100.0, hold_time)
	
	await get_tree().create_timer(hold_time).timeout
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	
	# Fade out after brief delay (let new scene render)
	# Safety: check if still in tree after scene change
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		_fade_out()

func dismiss():
	if _is_loading:
		_fade_out()

signal loading_ready
