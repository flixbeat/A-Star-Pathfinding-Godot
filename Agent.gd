extends KinematicBody2D

onready var path_finder = $Sprite/PathFinder

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		_go_to_position(get_global_mouse_position())

func _go_to_position(target_position: Vector2):
	path_finder.move(self, position, target_position)

