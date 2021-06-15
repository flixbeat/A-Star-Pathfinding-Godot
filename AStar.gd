extends Node2D

onready var _tilemap = $TileMap
onready var start_point = $StartPoint
onready var tween = $StartPoint/Tween

var _tileset : TileSet
var _cur_pos : Vector2

func _ready():
	_tileset = _tilemap.tile_set

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var path = _get_path(start_point.position, get_global_mouse_position())
		_move_along_path(start_point, path)

func _move_along_path(object, path):
	if path == null:
		print("there's no way there")
		return
	
	for p in path:
		var next_pos = _tilemap.map_to_world(p.position)
		next_pos.x += _tilemap.cell_size.x / 2
		next_pos.y += _tilemap.cell_size.y / 2
		tween.interpolate_property(object,"position",_cur_pos,next_pos,0.1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
		_cur_pos = next_pos
		yield(tween,"tween_all_completed")
# A*
func _get_path(start_position: Vector2, target_position: Vector2):	
	_cur_pos = start_position
	
	var open = [] # Cell[]
	var closed = [] # Cell[]

	var start_coord = _tilemap.world_to_map(start_position)
	var end_coord = _tilemap.world_to_map(target_position)

	# put starting node to open
	open.append(Cell.new(start_coord,0,0))
	
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
		if q.position == end_coord:
			var current = q
			var path = [] # Cell[]
			# get path
			while current != null:
				path.append(current)
				#_tilemap.set_cell(current.position.x, current.position.y,-1)
				current = current.parent
			
			path.invert()
			return path
			break
		
		# get neighbors
		var neighbors = _get_neighbors(q.position.x,q.position.y)
		
		# generate successor and set their parents to q
		for n in neighbors:
			var g = q.g + q.position.distance_to(n)
			var h = n.distance_to(target_position)
			var neighbor = Cell.new(n,g,h)
			neighbor.parent = q
			
			# check if not in the close list
			var in_close = false
			for c in closed:
				if neighbor.position == c.position:
					in_close = true
			
			# if not in the closed list
			if not in_close:
				var is_in_open = false
				var in_open: Cell
				
				# check if in the open list
				for o in open:
					if neighbor.position == o.position:
						in_open = o
						is_in_open = true
				
				# if not in the closed list
				if not is_in_open:
					open.append(neighbor)
					#_tilemap.set_cell(neighbor.position.x, neighbor.position.y, 18)
				else:
					var open_neighbor = in_open
					if neighbor.g < open_neighbor.g:
						open_neighbor.g = neighbor.g
						open_neighbor.parent = neighbor.parent
	return null

func _get_neighbors(x: int, y: int): # Vector2 array	
	var neighbors = [Vector2(x,y-1),Vector2(x,y+1),Vector2(x-1,y),Vector2(x+1,y)]
	
	var walkable_neighbors = []
	
	for n in neighbors:
		var tile_index = _tilemap.get_cell(n.x,n.y)
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

