extends Control

onready var lobby_ui = $Lobby_interface
onready var label = $Lobby_interface/Label

func _ready():
	$UI.hide()

func _on_Join_game_pressed():
	print("Clicou em conectar no servidor.")
	label.text = "Tentando se conectar..."
	Server.join_server()


func _on_Next_level_pressed():
	Server.next_level()


func _on_Reset_level_pressed():
	Server.reset_level()
