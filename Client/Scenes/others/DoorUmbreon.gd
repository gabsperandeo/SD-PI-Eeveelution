extends Area2D

export var path : String
export var inside : bool

func _ready():
	pass

func _on_DoorUmbreon_body_exited(body):
	print("SAIU")
	for key in Server.players:
		if body.name == Server.players[key] and key == "Umbreon":
			inside = false

func _on_DoorUmbreon_body_entered(body):
	for key in Server.players:
		if body.name == Server.players[key] and key == "Umbreon":
			inside = true
