extends Area2D

export var path : String
export var inside : bool

func _ready():
	pass

func _on_Area2D_body_entered(body):
	if body.name == "Espeon":
		inside = true

func _on_DoorEspeon_body_exited(body):
	if body.name == "Espeon":
		inside = false
