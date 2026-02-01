extends Control
class_name Board

signal add_score(score: int)

@export var width := 8
@export var height := 8
var blocked: Array = []
var grid_space_scene: PackedScene = preload("res://Scenes/Objects/grid_space.tscn")
var piece_scene: PackedScene = preload("res://Scenes/Objects/Pieces/piece.tscn")
var multiplayer_on: bool = false

var spaces := []
var current_cleared: Array[GridSpace] = []
var input_locked := false

@onready var grid := $GridContainer

func _ready():
	if not multiplayer_on:
		start()

func set_width(new_width):
	width = new_width

func set_height(new_height):
	height = new_height

func set_blocked(new_blocked):
	blocked = new_blocked

func start():
	grid.columns = width
	grid.size_flags_horizontal = Control.SIZE_FILL
	grid.size_flags_vertical = Control.SIZE_FILL
	await get_tree().process_frame
	create_grid()
	set_blocked_spaces()
	scale_grid_to_screen()
	spawn_initial_pieces()
	add_score.connect(get_node("..")._add_score)

func get_valid_piece_type(x: int, y: int) -> Piece.Type:
	var forbidden: Array[Piece.Type] = []

	if x >= 2:
		var a = spaces[y][x - 1].piece
		var b = spaces[y][x - 2].piece
		if a and b and a.type == b.type:
			forbidden.append(a.type)

	if y >= 2:
		var a = spaces[y - 1][x].piece
		var b = spaces[y - 2][x].piece
		if a and b and a.type == b.type:
			forbidden.append(a.type)

	var candidates: Array[Piece.Type] = []
	for t in Piece.Type.values():
		if t not in forbidden:
			candidates.append(t)

	return candidates.pick_random()

func scale_grid_to_screen():
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var board_size = size 
	
	var h_sep = grid.get_theme_constant("h_separation")
	var v_sep = grid.get_theme_constant("v_separation")
	
	var cell_width = (board_size.x - (h_sep * (width - 1))) / width
	var cell_height = (board_size.y - (v_sep * (height - 1))) / height
	var cell_size = Vector2(cell_width, cell_height)

	for y in range(height):
		for x in range(width):
			var space = spaces[y][x]

func scale_piece_to_cell(piece: TextureRect, cell_size: Vector2):
	var piece_size = cell_size * 0.75

	piece.size = piece_size

	piece.anchor_left = 0.5
	piece.anchor_top = 0.5
	piece.anchor_right = 0.5
	piece.anchor_bottom = 0.5

	piece.offset_left = -piece_size.x / 2
	piece.offset_top = -piece_size.y / 2
	piece.offset_right = piece_size.x / 2
	piece.offset_bottom = piece_size.y / 2

	# Stretch the texture to keep the aspect ratio
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func get_random_type() -> Piece.Type:
	return Piece.Type.values().pick_random()

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
			
func is_inside_board(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height			
			
func spawn_initial_pieces():
	for y in height:
		for x in width:
			var space: GridSpace = spaces[y][x]
			if space.blocked:
				continue

			var piece: Piece = piece_scene.instantiate()
			piece.type = get_valid_piece_type(x, y)
			place_piece(space, piece)


func place_piece(space: GridSpace, piece: Piece):
	space.add_child(piece)
	space.piece = piece
	piece.space = space

	# Connect input
	piece.swap_requested.connect(_on_swap_requested)

func move_piece(from: GridSpace, to: GridSpace):
	var piece = from.piece
	from.piece = null
	to.piece = piece

	from.remove_child(piece)
	to.add_child(piece)
	piece.space = to

func _on_swap_requested(from: GridSpace, dir: Vector2i):
	if input_locked:
		return

	var target = from.grid_pos + dir
	if not is_inside_board(target):
		return

	var to = spaces[target.y][target.x]
	if to.blocked:
		return

	attempt_swap(from, to)

func attempt_swap(a: GridSpace, b: GridSpace):
	swap_spaces(a, b)

	var matches = find_matches()
	if matches.is_empty():
		swap_spaces(a, b)
	else:
		resolve_matches(matches)
			
func swap_spaces(a: GridSpace, b: GridSpace):
	var pa = a.piece
	var pb = b.piece

	a.piece = pb
	b.piece = pa

	if pa:
		a.remove_child(pa)
		b.add_child(pa)
		pa.space = b

	if pb:
		b.remove_child(pb)
		a.add_child(pb)
		pb.space = a
		
func find_matches() -> Array:
	var matches := []

	for y in height:
		var run := []
		for x in width:
			var space = spaces[y][x]
			if space.piece and (run.is_empty() or space.piece.type == run[0].piece.type or space.piece.special == Piece.Special.RAINBOW):
				run.append(space)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run.clear()
				if space.piece:
					run.append(space)
		if run.size() >= 3:
			matches.append(run)

	for x in width:
		var run := []
		for y in height:
			var space = spaces[y][x]
			if space.piece and (run.is_empty() or space.piece.type == run[0].piece.type):
				run.append(space)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run.clear()
				if space.piece:
					run.append(space)
		if run.size() >= 3:
			matches.append(run)

	return matches
	
func resolve_matches(matches: Array):
	input_locked = true
	clear_matches(matches)
	await get_tree().create_timer(0.2).timeout
	
	current_cleared.clear()
	
	apply_gravity()
	await get_tree().create_timer(0.2).timeout

	refill()
	await get_tree().create_timer(0.2).timeout

	var new_matches = find_matches()
	if new_matches.is_empty():
		input_locked = false
		if not has_available_move():
			shuffle_board()
	else:
		resolve_matches(new_matches)

func clear_matches(matches: Array):
	var already_had_bomb = false
	var current_type: Piece.Type
	for group in matches:
		for space in group:
			if space.piece:
				current_type = space.piece.type
				clear_space(space)
		if len(group) == 5:
			var new_piece = piece_scene.instantiate()
			new_piece.type = current_type
			new_piece.special = Piece.Special.RAINBOW
			place_piece(group[2], new_piece)
			add_score.emit(500)
		elif len(group) == 4:
			var new_piece = piece_scene.instantiate()
			new_piece.type = current_type
			new_piece.special = Piece.Special.HORIZONTAL if (group[0].grid_pos - group[1].grid_pos).y != 0 else Piece.Special.VERTICAL
			place_piece(group[1], new_piece)
			add_score.emit(300)
		var done: bool = false
		for group_a in matches:
			for group_b in matches:
				if group_a != group_b and len(group_a) == 3 and len(group_b) == 3:
					for space_a in group_a:
						for space_b in group_b:
							if space_a == space_b and not already_had_bomb:
								var new_piece = piece_scene.instantiate()
								new_piece.type = current_type
								new_piece.special = Piece.Special.BOMB
								place_piece(space_a, new_piece)
								print("bomb")
								already_had_bomb = true
								add_score.emit(300)
								done = true
								break
							if done:
								break
						if done:
							break
					if done:
						break
				if done:
					break
			if done:
				break
		if not done and len(group) == 3:
			add_score.emit(100)
		
func shuffle_board():
	var all_pieces = []
	for y in range(height):
		for x in range(width):
			var space = spaces[y][x]
			if space.piece:
				all_pieces.append(space.piece)

	all_pieces.shuffle()
	var index = 0
	for y in range(height):
		for x in range(width):
			var space = spaces[y][x]
			if space.piece:
				space.piece.type = all_pieces[index].type
				space.piece.type = all_pieces[index].special
				space.piece.update_texture()
				index += 1

	var matches = find_matches()
	if matches.is_empty():
		print("No matches found after shuffle, re-trying...")
		shuffle_board()
	else:
		resolve_matches(matches)

func clear_space(space: GridSpace):
	if space.piece and space not in current_cleared:
		current_cleared.append(space)
		match space.piece.special:
			Piece.Special.RAINBOW:
				for column in spaces:
					for board_space in column:
						if board_space.piece and board_space not in current_cleared:
							clear_space(board_space)
			Piece.Special.HORIZONTAL:
				for x in width:
					if spaces[space.grid_pos.y][x].piece and spaces[space.grid_pos.y][x] not in current_cleared:
						clear_space(spaces[space.grid_pos.y][x])
			Piece.Special.VERTICAL:
				for y in height:
					if spaces[y][space.grid_pos.x].piece and spaces[y][space.grid_pos.x] not in current_cleared:
						clear_space(spaces[y][space.grid_pos.x])
			Piece.Special.BOMB:
				for x_off in range(-1, 2):
					for y_off in range(-1, 2):
						if is_inside_board(Vector2i(space.grid_pos.x + x_off, space.grid_pos.y + y_off)):
							if spaces[space.grid_pos.y + y_off][space.grid_pos.x + x_off].piece and spaces[space.grid_pos.y + y_off][space.grid_pos.x + x_off] not in current_cleared:
								clear_space(spaces[space.grid_pos.y + y_off][space.grid_pos.x + x_off])
		space.piece.queue_free()
		space.piece = null

func has_available_move() -> bool:
	for y in range(height):
		for x in range(width):
			var space = spaces[y][x]
			
			if x < width - 1:
				var swap1 = spaces[y][x + 1]
				if swap_possible(space, swap1):
					return true

			if y < height - 1:
				var swap2 = spaces[y + 1][x]
				if swap_possible(space, swap2):
					return true

	return false


func swap_possible(space1: GridSpace, space2: GridSpace) -> bool:
	var piece1 = space1.piece
	var piece2 = space2.piece

	space1.piece = piece2
	space2.piece = piece1

	var matches = find_matches()

	space1.piece = piece1
	space2.piece = piece2

	return not matches.is_empty()

				
func apply_gravity():
	for x in width:
		for y in range(height - 1, -1, -1):
			var space = spaces[y][x]
			if space.piece == null and not space.blocked:
				for above_y in range(y - 1, -1, -1):
					var above = spaces[above_y][x]
					if above.piece:
						move_piece(above, space)
						break
						
func refill():
	for y in height:
		for x in width:
			var space = spaces[y][x]
			if space.piece == null and not space.blocked:
				var piece: Piece = piece_scene.instantiate()
				piece.type = Piece.Type.values().pick_random()
				place_piece(space, piece)
