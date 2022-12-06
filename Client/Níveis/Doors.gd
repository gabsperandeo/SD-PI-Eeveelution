extends Node2D

export var finished : bool
export var next_scene : String

func _ready():
	finished = false

func _process(delta):
	if $DoorEspeon.inside and $DoorUmbreon.inside:
		finished = true
	else:
		finished = false
