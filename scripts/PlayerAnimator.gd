extends Node2D
class_name PlayerAnimator

# PlayerAnimator - Handles all player sprite animations
# 4 Stances: borrowed, scream, whisper, undefined
# 5 Actions: idle, walk, cast, hurt, death
# 8 Directions for walk: n, ne, e, se, s, sw, w, nw

var current_stance: String = "borrowed"
var current_action: String = "idle"
var current_direction: String = "s"

var frame_timer: float = 0.0
var frame_interval: float = 0.12
var current_frame: int = 0

var sprite: Sprite2D = null

const FRAME_COUNTS = {
	"idle": 4,
	"walk": 6,
	"cast": 8,
	"hurt": 6,
	"death": 8
}

const SPRITE_BASE = "res://assets/sprites/player/"

func _ready():
	var parent = get_parent()
	if parent:
		sprite = parent.get_node_or_null("PlayerSprite")
	
	if not sprite:
		push_error("PlayerAnimator: No PlayerSprite node found!")
		return
	
	_load_frame()

func _process(delta: float):
	if current_action in ["walk", "cast", "hurt", "death"]:
		frame_timer += delta
		if frame_timer >= frame_interval:
			frame_timer = 0.0
			var max_frames = FRAME_COUNTS[current_action]
			current_frame = (current_frame + 1) % max_frames
			_load_frame()

func set_state(stance: String, action: String, direction: String = "s"):
	var changed = (current_stance != stance) or (current_action != action)
	current_stance = stance
	current_action = action
	current_direction = direction
	
	if changed:
		current_frame = 0
		frame_timer = 0.0
	
	_load_frame()

func set_direction(direction: String):
	if current_direction != direction:
		current_direction = direction
		_load_frame()

func _load_frame():
	var path = _build_sprite_path()
	print("[PlayerAnimator] Loading: %s" % path)
	
	# Try detailed animation frame first
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex:
			sprite.texture = tex
			print("[PlayerAnimator] Loaded OK: %s" % path)
			return
		else:
			print("[PlayerAnimator] load() returned null: %s" % path)
	else:
		print("[PlayerAnimator] File not found: %s" % path)
	
	# Try fallback frame 0
	var fallback = _build_sprite_path(0)
	print("[PlayerAnimator] Trying fallback: %s" % fallback)
	if ResourceLoader.exists(fallback):
		var tex = load(fallback)
		if tex:
			sprite.texture = tex
			print("[PlayerAnimator] Fallback OK: %s" % fallback)
			return
	
	# Use character_sprite.png as reliable fallback
	var char_sprite_path = SPRITE_BASE + "character_sprite.png"
	print("[PlayerAnimator] Trying character_sprite: %s" % char_sprite_path)
	if ResourceLoader.exists(char_sprite_path):
		var tex = load(char_sprite_path)
		if tex:
			sprite.texture = tex
			print("[PlayerAnimator] character_sprite OK")
			return
	
	print("[PlayerAnimator] CRITICAL: No sprite available for %s_%s" % [current_stance, current_action])
	# Create visible fallback so player can be seen
	if sprite and sprite.texture == null:
		var fallback_tex = _create_fallback_texture()
		if fallback_tex:
			sprite.texture = fallback_tex
			print("[PlayerAnimator] Using blue fallback texture")

func _create_fallback_texture() -> Texture2D:
	"""Create a simple colored circle texture as visual fallback"""
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.6, 1.0, 1.0))  # Blue circle
	# Make it circular
	for x in range(64):
		for y in range(64):
			var dx = x - 32
			var dy = y - 32
			if dx * dx + dy * dy > 900:  # Outside circle radius ~30
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _build_sprite_path(frame: int = -1) -> String:
	var f = frame if frame >= 0 else current_frame
	
	# Idle, hurt, cast, death: no direction in filename
	if current_action in ["idle", "hurt", "cast", "death"]:
		return SPRITE_BASE + "player_%s_%s_f%d.png" % [current_stance, current_action, f]
	
	# Walk: includes direction
	return SPRITE_BASE + "player_%s_walk_%s_f%d.png" % [current_stance, current_direction, f]

func play_idle():
	set_state(current_stance, "idle", current_direction)

func play_walk(direction: String):
	set_state(current_stance, "walk", direction)

func play_cast():
	set_state(current_stance, "cast", current_direction)

func play_hurt():
	set_state(current_stance, "hurt", current_direction)

func play_death():
	set_state(current_stance, "death", current_direction)

func change_stance(new_stance: String):
	if current_stance != new_stance:
		current_stance = new_stance
		_load_frame()
