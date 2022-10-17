extends Node2D

export var finished : bool
export var next_scene : String

func _ready():
	finished = false

func _process(delta):
	print($DoorEspeon.inside, $DoorUmbreon.inside)
	if $DoorEspeon.inside and $DoorUmbreon.inside:
		finished = true
	else:
		finished = false
