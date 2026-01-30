extends TextureRect

class_name Piece

enum Type {
	RED,
	BLUE,
	GREEN,
	YELLOW,
	PURPLE,
	PINK,
	ORANGE,
	TURQUOISE
}

enum Special {
	NORMAL,
	HORIZONTAL,
	VERTICAL,
	BOMB,
	RAINBOW
}

signal swap_requested(from_space: GridSpace, direction: Vector2i)

var type: Type
var special: Special
@export var textures: Array[Texture2D] = []
@export var horizontal_textures: Array[Texture2D] = []
@export var vertical_textures: Array[Texture2D] = []
@export var bomb_textures: Array[Texture2D] = []
@export var rainbow_texture: Texture2D

var space: GridSpace
var touch_start := Vector2.ZERO
var is_dragging := false

func _ready():
	update_texture()
	mouse_filter = Control.MOUSE_FILTER_STOP
	
func update_texture():
	match special:
		Special.NORMAL:
			texture = textures[type]
		Special.HORIZONTAL:
			texture = horizontal_textures[type]
		Special.VERTICAL:
			texture = vertical_textures[type]
		Special.BOMB:
			texture = bomb_textures[type]
		Special.RAINBOW:
			texture = rainbow_texture

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			is_dragging = true
		else:
			is_dragging = false

	elif event is InputEventScreenDrag and is_dragging:
		handle_drag(event.position)

func handle_drag(current_pos: Vector2):
	var delta = current_pos - touch_start

	if delta.length() < 20:
		return

	var dir := Vector2i.ZERO
	if abs(delta.x) > abs(delta.y):
		dir.x = sign(delta.x)
	else:
		dir.y = sign(delta.y)

	is_dragging = false
	swap_requested.emit(space, dir)
