extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_pos(id, pos):
	var p = get_node("/root/Nodes/"+id)
	p.set_position(pos)
