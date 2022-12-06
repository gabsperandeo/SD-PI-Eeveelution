extends Area2D

export var path : String
export var inside : bool

func _ready():
	pass

func _on_DoorEspeon_body_exited(body):
	for key in Server.players:
		if body.name == Server.players[key] and key == "Espeon":
			inside = false

func _on_DoorEspeon_body_entered(body):
	for key in Server.players:
		if body.name == Server.players[key] and key == "Espeon":
			inside = true
