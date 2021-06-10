extends Node2D

onready var tilemap = $TileMap
onready var start_point = $StartPoint
onready var tween = $StartPoint/Tween
onready var end_point = $EndPoint

var _tileset : TileSet
var _cur_pos : Vector2

func _ready():
	_cur_pos = start_point.position
	var path = _get_path()
	_move_along_path(path)

func _move_along_path(path):
	for p in path:
		var next_pos = tilemap.map_to_world(p.position)
		next_pos.x += tilemap.cell_size.x / 2
		next_pos.y += tilemap.cell_size.y / 2
		tween.interpolate_property(start_point,"position",_cur_pos,next_pos,0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
		_cur_pos = next_pos
		yield(tween,"tween_all_completed")
# A*
func _get_path():
	var open = [] # Cell[]
	var closed = [] # Cell[]

	_tileset = tilemap.tile_set
	var start_coord = tilemap.world_to_map(start_point.position)
	var end_coord = tilemap.world_to_map(end_point.position)
	
	# put starting node to open
	open.append(Cell.new(start_coord,0,0))
	
	# while there's an open cell to explore
	while not open.empty():
		
		# find least f from open list
		var q = Cell.new(Vector2.ZERO,INF,INF)
		for cell in open:
			if cell.get_f() < q.get_f():
				q = cell
		
		open.remove(open.find(q))
		closed.append(q)
		
		# if goal was reached
		if q.position == end_coord:
			var current = q
			var path = [] # Cell[]
			# get path
			while current != null:
				path.append(current)
				current = current.parent
			
			path.invert()
			return path
		
		# get neighbors
		var neighbors = _get_neighbors(q.position.x,q.position.y)
		var successors = [] # Cell
		
		# generate successor and set their parents to q
		for n in neighbors:
			var tile_index = tilemap.get_cell(n.x,n.y)
			var is_walkable = _tileset.tile_get_name(tile_index) == "walkable"
			
			if not is_walkable:
				continue
			
			var g = q.g + q.position.distance_to(n)
			var h = n.distance_to(end_point.position)
			var cell = Cell.new(n,g,h)
			
			# if in the closed list skip
			if closed.find(cell) != -1:
				continue
			
			# check if it's not in the open list
			var in_open_id = open.find(cell)
			if in_open_id == -1:
				cell.parent = q
				open.append(cell)
			else:
				var in_open = open[in_open_id]
				if cell.g < in_open.g:
					in_open.parent = cell
					in_open.g = cell.g + cell.position.direction_to(in_open.position)
					in_open.h = cell.position.distance_to(end_point.position)
					
	
func _get_neighbors(x: int, y: int): # Vector2 array
	# top, bottom, left, right
	return [Vector2(x,y-1),Vector2(x,y+1),Vector2(x-1,y),Vector2(x+1,y)]

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
