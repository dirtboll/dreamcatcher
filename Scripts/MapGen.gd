tool
extends TileMap

enum Step {LEFT, RIGHT, UP, DOWN}
enum RType {LRNN, LRBN, LRNT, LRBT, END, FILL}

const STEP_DIST := [Step.LEFT, Step.LEFT, Step.LEFT, Step.LEFT, Step.DOWN]
const ROOM_STEP	:= [
	[RType.LRNN, RType.LRBN, RType.LRNT, RType.LRBT],
	[RType.LRNN, RType.LRBN, RType.LRNT, RType.LRBT],
	[RType.LRNT, RType.LRBT],
	[RType.LRBT]
]
const STEP_VEC	:= [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const TILE_DIFFS := [2,10,9,8]

var difficulty = Global.difficulty
var grid_x = 5 + difficulty - 1
var grid_y = 5 + difficulty - 1
var room_x = 16
var room_y = 16
var frame_thick = 20
var max_chance = 0.95

var max_diff = 50
var collectable_max_chance = 0.75
export var mob_spawners := {}
export var spawn_pos := Vector2()
export var end_pos := Vector2()

var TILE_DIST		= Global.get_tile_dist()
var TILE_GROUP 		= Global.get_tile_group()
var _empty_rooms 	= {}
var _grid 			= []
var _start_room 	= Vector2()
var _end_room 		= Vector2()
var _rng 			:= RandomNumberGenerator.new()
var _simplex 		= OpenSimplexNoise.new()

onready var MapRooms: Node2D = preload("res://Scenes/MapRooms.tscn").instance()
onready var Background: TileMap = $Background
onready var Platform: TileMap = $Platform


var generated_collectables = []

func _ready():
	loadzzzz()


func loadzzzz():
	_pregen()
	_gen_path()
	_gen_path_fill()
	_gen_tiles()
	_gen_spawn_end()
	_gen_randomize()
	_postgen()


# Reset vars
func _pregen():
	clear()
	Background.clear()
	Platform.clear()
	randomize()
	_rng.randomize()
	_simplex.seed = _rng.randi()
	_grid = []
	_empty_rooms = {}
	mob_spawners = {}
	for x in range(grid_x):
		var gridY = []
		for y in range(grid_y):
			gridY.append(-1)
			_empty_rooms[Vector2(x,y)] = true
		_grid.append(gridY)


# Not-so-random random walker algorithm implementation
# to generate top-down path to ensure player have a way
# to reach end point.
func _gen_path():
	var curr_room = Vector2(_rng.randi() % grid_x, 0)
	_start_room = curr_room
	var prev_step = -1
	var curr_step = _rand_choose(STEP_DIST)
	curr_step = ( 
		curr_step 
		if curr_step == Step.DOWN 
		else _rand_choose([Step.LEFT, Step.RIGHT]) 
	)
	
	# Generate up to down path
	while curr_room.y < grid_y-1:
		#yield(timer, "timeout")

		# Prevent generation outside x boundary
		var next_room = curr_room + STEP_VEC[curr_step]
		if next_room.x == -1 or next_room.x == grid_x:
			curr_step = Step.DOWN

		# Get room type
		var rtype = ROOM_STEP[(
			Step.UP 
			if prev_step == Step.DOWN and curr_step != Step.DOWN 
			else curr_step
		)]
		_grid[curr_room.x][curr_room.y] = _rand_choose(rtype)
		_empty_rooms.erase(curr_room)

		# Prepare next iteration
		curr_room += STEP_VEC[curr_step]
		var next_step = _rand_choose(STEP_DIST)
		next_step = ( 
			next_step 
			if next_step == Step.DOWN 
			else _rand_choose([Step.LEFT, Step.RIGHT]) 
		)
		
		# Prevent Left to Right & vice versa
		if curr_step != Step.DOWN and next_step != Step.DOWN:
			next_step = curr_step
		
		# Reroute on crash
		elif curr_step == Step.DOWN and ((curr_room + STEP_VEC[next_step]).x == -1 or (curr_room + STEP_VEC[next_step]).x == grid_x):
			next_step = Step.LEFT if next_step == Step.RIGHT else Step.RIGHT
		
		prev_step = curr_step
		curr_step = next_step

	_end_room = curr_room
	for x in range(grid_x):
		_grid[x][grid_y-1] = RType.FILL
		_empty_rooms.erase(Vector2(x, grid_y-1))
	_grid[_end_room.x][_end_room.y] = RType.END
	_empty_rooms.erase(Vector2(_end_room.x, _end_room.y))


# Fill the rest non path with random rooms
func _gen_path_fill():
	var rtypes = [RType.LRNN, RType.LRBN, RType.LRNT, RType.LRBT]
	for pos in _empty_rooms:
		_grid[pos.x][pos.y] = _rand_choose(rtypes)
	_empty_rooms.clear()

func _fill_room(x, y, rtype):
	var origin_cell = Vector2( x*room_x,y*room_y )
	var room: TileMap = _rand_choose( MapRooms.get_child(rtype).get_children() )
	for cell_pos in room.get_used_cells():
		set_cellv(origin_cell + cell_pos, room.get_cellv(cell_pos))

# Generate tiles based on _grid room type
func _gen_tiles():
	for x in range(len(_grid)):
		for y in range(len(_grid[x])):
			_fill_room(x,y,_grid[x][y])


# Generate spawn and end world position
func _gen_spawn_end():
	var spawn_map_pos = Vector2()
	for pos in get_used_cells():
		if get_cellv(pos) == 22:
			if (pos/Vector2(room_x,room_y)).floor().is_equal_approx(_start_room):
				spawn_map_pos = pos
			else:
				set_cellv(pos, 18)
	spawn_pos = map_to_world(spawn_map_pos) + Vector2(5,7)
	end_pos = map_to_world(_end_room*Vector2(room_x, room_y)+Vector2(8,8))


# Generate randomization on tiles based on it's distribution
# in TILE_DIST
func _gen_randomize():
	var new_tile_dist = _get_dist_diff()

	var collectables_pos = {
		10: [],
		9: [],
		8: [],
	}

	for pos in get_used_cells():
		var cell = get_cellv(pos)

		# Randomize stone tiles
		if cell == 2:
			if new_tile_dist[cell] < (_simplex.get_noise_2d(pos.x * 5.0, pos.y * 5.0) + 1.0) / 2.0:
				cell = -1
			else:
				cell = 1
		
		# Move platform cell to $Platform
		elif cell == 4:
			cell = -1
			Platform.set_cellv(pos, 0)

		# Randomize mob spawn tiles
		elif cell == 14:
			var index = floor(clamp(_rng.randf() * len(TILE_GROUP[cell]), 0, len(TILE_GROUP[cell]) - 0.0001))
			cell = TILE_GROUP[cell][index]

			mob_spawners[map_to_world(pos) + cell_size / 2] = {
				"cell":  cell,
				"i": index,
				"mpos": pos
			}

		elif not cell in new_tile_dist:
			continue

		# Get collectables pos
		elif cell in collectables_pos:
			collectables_pos[cell].append(pos)
			continue

		# Randomize Folliage
		elif new_tile_dist[cell] < _rng.randf():
			cell = -1
		else:
			cell = _rand_choose(TILE_GROUP[cell])

		set_cellv(pos, cell)

	for collectable in collectables_pos.keys():
		
		var pos_arr: Array = collectables_pos[collectable]
		pos_arr.shuffle()

		var deleted = []
		while not pos_arr.empty():

			var pos = pos_arr.pop_front()
			if new_tile_dist[collectable] < 0.001:
				deleted.append(pos)
				continue
			if new_tile_dist[collectable] > _rng.randf():
				generated_collectables.append([map_to_world(pos) + cell_size / 2, pos, collectable])
			else:
				deleted.append(pos)
		
		#Delete not passed
		for pos in deleted:
			set_cellv(pos, -1)


# Get new chance distribution with tiles that's 
# affected by difficulty.
func _get_dist_diff() -> Dictionary:
	var tile_dist = TILE_DIST
	for tile in TILE_DIFFS:
		if tile_dist[tile] < 0.001:
			continue
		if not(tile in [10,9,8]):
			tile_dist[tile] = _chance_from_diff(tile_dist[tile])
	return tile_dist


# Generate chance from difficulty with linear function
func _chance_from_diff(val: float) -> float:
	var a = Vector2(0.0,val)
	var b = Vector2(0.0,max_chance)
	var pre_a = a 
	var post_b = b
	var t = float(difficulty)/max_diff
	var res = a.cubic_interpolate(b, pre_a, post_b, t)
	return res.y


# Clean-up, palce walls, and background
func _postgen():
	# Generate border and background
	for x in range(-frame_thick, room_x*grid_x + frame_thick):
		for y in range(-frame_thick, room_y*grid_y + frame_thick):
			if x < 0 or x >= room_x*grid_x \
			or y < 0 or y >= room_y*grid_y:
				set_cell(x, y, 1)

			Background.set_cell(x, y, 30)

	update_bitmask_region(Vector2(-frame_thick, -frame_thick), Vector2(room_x*grid_x + frame_thick, room_y*grid_y + frame_thick))
	Background.update_bitmask_region(Vector2(-frame_thick, -frame_thick), Vector2(room_x*grid_x + frame_thick, room_y*grid_y + frame_thick))
	Platform.update_bitmask_region(Vector2(-frame_thick, -frame_thick), Vector2(room_x*grid_x + frame_thick, room_y*grid_y + frame_thick))


func _rand_choose(arr: Array):
	if len(arr) == 0: 
		return
	return arr[_rng.randi() % len(arr)]
