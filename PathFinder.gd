extends Node

signal target_reach()

enum Direction {FOUR, EIGHT}

export(NodePath) var tilemap_path
export(Direction) var directional_movement = Direction.FOUR
export var speed := 160

var _tilemap : TileMap
var _tileset : TileSet

# local coordinates
var _cur_pos : Vector2
var _target_pos : Vector2

# coordinates in tile
var _start_coord: Vector2
var _end_coord: Vector2
var _cur_coord: Vector2

var _object : KinematicBody2D
var _path # Cell[]

func _ready():
	_tilemap = get_node(tilemap_path)
	_tileset = _tilemap.tile_set
	
	set_physics_process(false)

# @param1: object to move. eg: KinematicBody2D/Sprite/...
func move(object, start_position: Vector2, target_position: Vector2):
	var path = yield(_get_path(start_position, target_position),"completed")
	
	if path == null:
		print("no path possible")
		return
	
	_object = object
	_path = path
	
	_path.pop_front()
	set_physics_process(true)

func _physics_process(delta):
	if _path.empty():
		set_physics_process(false)
		return
	
	var next_pos = _tilemap.map_to_world(_path[0].position)
	next_pos.x += _tilemap.cell_size.x / 2
	next_pos.y += _tilemap.cell_size.y / 2
	var direction = _cur_pos.direction_to(next_pos)
	
	#_object.move_and_slide(direction * speed)
	var distance_between_points = _object.position.distance_to(next_pos)
	_object.position = _object.position.linear_interpolate(next_pos, (delta * speed) / distance_between_points)
	
	_cur_coord = _tilemap.world_to_map(_object.position)
	
	var cur_point = Vector2(_object.position.x,_object.position.y)
	var next_point = Vector2(next_pos.x,next_pos.y)
	var distance = cur_point.distance_to(next_point)
	
	if distance <= 1:
		_cur_pos = next_pos
		_path.pop_front()
		_point_reached()

func _point_reached():
	if _cur_coord == _end_coord:
		emit_signal("target_reach")
		set_physics_process(false)

# A*
func _get_path(start_position: Vector2, target_position: Vector2):
	_cur_pos = start_position
	_target_pos = target_position
	
	var open = [] # Cell[]
	var closed = [] # Cell[]

	_start_coord = _tilemap.world_to_map(start_position)
	_end_coord = _tilemap.world_to_map(target_position)

	# put starting node to open
	open.append(Cell.new(_start_coord,0,0))
	
	# while there's an open cell to explore
	while not open.empty():
		# find least f from open list
		var q = Cell.new(Vector2.ZERO,INF,INF)
		for cell in open:
			if cell.get_f() < q.get_f():
				q = cell
		
		open.erase(q)
		closed.append(q)
		
		# if goal was reached
		if q.position == _end_coord:
			var current = q
			var path = [] # Cell[]
			# get path
			while current != null:
				path.append(current)
				current = current.parent
			
			path.invert()
			
			# wait for the loop to finish
			yield(Engine.get_main_loop().create_timer(0, false), "timeout")
			return path
		
		# get neighbors
		var neighbors = _get_neighbors(q.position.x,q.position.y)
		
		# generate successor and set their parents to q
		for n in neighbors:
			var g = q.g + q.position.distance_to(n)
			var h = n.distance_to(target_position)
			var neighbor = Cell.new(n,g,h)
			neighbor.parent = q
			
			# check if not in the close list
			var is_in_close = false
			for c in closed:
				if neighbor.position == c.position:
					is_in_close = true
			
			# if not in the closed list
			if not is_in_close:
				var is_in_open = false
				var in_open: Cell
				
				# check if in the open list
				for o in open:
					if neighbor.position == o.position:
						in_open = o
						is_in_open = true
				
				# if not in the open list
				if not is_in_open:
					open.append(neighbor)
	
	# no path found
	return null

func _get_neighbors(x: int, y: int): # Vector2 array	
	var neighbors = [Vector2(x,y-1),Vector2(x,y+1),Vector2(x-1,y),Vector2(x+1,y)]
	
	if directional_movement == Direction.EIGHT:
		var diagonal_neighbors = [Vector2(x-1,y-1),Vector2(x-1,y+1),Vector2(x-1,y+1),Vector2(x+1,y-1)]
		neighbors.append_array(diagonal_neighbors)
	
	var walkable_neighbors = []
	
	for n in neighbors:
		var tile_index = _tilemap.get_cell(n.x,n.y)
		
		# if there's a debugger error here, it means that there was no tile
		# on the current tile's neighbor(s), make sure that you put tile around the
		# current tile.
		# c = current tile, n = neighboring tile
		# .... n n n ....
		# .... n c n ....
		# .... n n n ....
		var is_walkable = _tileset.tile_get_name(tile_index) == "walkable"
		
		if is_walkable:
			walkable_neighbors.append(n)
			
	return walkable_neighbors

class Cell:
	var parent : Cell
	var position : Vector2
	var g: float # distance to next cell
	var h: float # distance to target cell
	var f: float # sum of g and h
	
	func _init(position=Vector2.ZERO, g=0, h=0):
		self.position = position
		self.g = g
		self.h = h
		
	func get_f() -> float:
		return self.g + self.h
