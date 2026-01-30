extends Control

@export var width := 8
@export var height := 8
var blocked: Array = []
var grid_space_scene: PackedScene = preload("res://Scenes/Objects/grid_space.tscn")
var piece_scene: PackedScene = preload("res://Scenes/Objects/Pieces/piece.tscn")
var spaces := []
@onready var grid := $GridContainer

func start():
	grid.columns = width
	grid.size_flags_horizontal = Control.SIZE_FILL
	grid.size_flags_vertical = Control.SIZE_FILL
	await get_tree().process_frame
	create_grid()
	set_blocked_spaces()
	scale_grid_to_screen()

func create_grid():
	spaces.resize(height)
	for y in range(height):
		spaces[y] = []
		for x in range(width):
			var space: GridSpace = grid_space_scene.instantiate()
			space.grid_pos = Vector2i(x, y)
			grid.add_child(space)
			spaces[y].append(space)

func set_blocked_spaces():
	for entry in blocked:
		spaces[entry["y"]][entry["x"]].blocked = true
		
func scale_grid_to_screen():
	# Ensure the GridContainer matches the Board's size
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# We must wait for the container to update its size or use the parent's size
	var board_size = size 
	
	# Account for separation if you haven't set them to 0
	var h_sep = grid.get_theme_constant("h_separation")
	var v_sep = grid.get_theme_constant("v_separation")
	
	# Calculate cell size subtracting the gaps between cells
	var cell_width = (board_size.x - (h_sep * (width - 1))) / width
	var cell_height = (board_size.y - (v_sep * (height - 1))) / height
	var cell_size = Vector2(cell_width, cell_height)

	for y in range(height):
		for x in range(width):
			var space = spaces[y][x]

func place_piece(space: GridSpace, piece: Piece):
	space.add_child(piece)
	space.piece = piece
	piece.space = space
