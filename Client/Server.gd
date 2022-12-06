extends Node

const DEFAULT_PORT = 25565 # Porta famosa

var ip_address = ""
onready var lobby_ui = get_node("/root/Lobby/Lobby_interface")
onready var join_game_button = get_node("/root/Lobby/Lobby_interface/Join_game")
onready var label = get_node("/root/Lobby/Lobby_interface/Label")
onready var game_ui = get_node("/root/Lobby/UI")
var current_level = ""

var espeon = preload("res://Scenes/Espeon.tscn")
var espeon_dummy = preload("res://Scenes/Espeon_Dummy.tscn")
var umbreon = preload("res://Scenes/Umbreon.tscn")
var umbreon_dummy = preload("res://Scenes/Umbreon_Dummy.tscn")

var players = {}

func _ready():

	# Não foi utilizado pois os PC'S da faculdade retornam IP da rede e não o local (192...)
	#if OS.get_name() == "Windows" or OS.get_name() == "x11":
	#	ip_address = IP.get_local_addresses()[3]

	ip_address = "127.0.0.1"

	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")

func join_server():
	var client = NetworkedMultiplayerENet.new()
	var err = client.create_client(ip_address, DEFAULT_PORT)
	if err != OK:
		print("Unable to connect.")
		return

	get_tree().network_peer = client

func _connection_failed() -> void:
	join_game_button.disabled = false
	# ISSUE
	# https://github.com/godotengine/godot/issues/19357
	# O ENet é implementado em UDP, logo caso o servidor não esteja ligado, irá demorar
	# 15 a 30 segundos para o sinal de connection_failed ser chamado pois o UDP não avisa se a 
	# conexão chegou realmente.
	label.text = "Não foi possível conectar ao servidor! Por favor tente novamente."
	print("Connection failed!")

func _connected_to_server() -> void:
	join_game_button.disabled = true
	lobby_ui.hide()
	game_ui.show()
	rpc_id(1, "request_level")

	print("Connected to the server!")

func reset_level() -> void:
	rpc_id(1, "reset_level")

remote func instance_player(location, data):
	# Verifica todos os players que recebeu do servidor
	for key in data.keys():
		# Se existir um player com o id da conexão do cliente atual, indica que é para ele instanciar
		# um player para ele mesmo. (O player real)
		if data[key] == str(get_tree().get_network_unique_id()):
			# Verifica se esse player já foi instanciando
			var already_exists
			for p in Nodes.get_children():
				if p.name == data[key]:
					already_exists = true
					break
			# Se ainda não foi instanciado, cria um player real para o cliente
			if not already_exists:
				print("Player do tipo: " + key + " spawnado.")
				var pty = espeon if key == "Espeon" else umbreon
				var pty_ins = Global.instance_node(pty, Nodes, location)
				players[key] = str(data[key])
				pty_ins.name = str(data[key])
		else:
			# Caso exista um player com um outro id de conexão, indica um outro player
			# ao qual deve ser instanciado um Dummy (player sem movimento, que apenas recebe as 
			# posições do servidor)
			var already_exists
			# Verifica se já foi instanciado anteriormente
			for p in Nodes.get_children():
				if p.name == data[key]:
					already_exists = true
					break
			# Se não foi instanciado cria um dummy para o tipo correspondente
			if not already_exists:
				players[key] = str(data[key])
				print("Dummy do tipo: " + key + " spawnado.")
				var dty = espeon_dummy if key == "Espeon" else umbreon_dummy
				var dty_ins = Global.instance_node(dty, Nodes, location)
				dty_ins.name = str(data[key])

func _server_disconnected() -> void:
	join_game_button.disabled = false
	lobby_ui.show()
	label.text = ""
	print("Server disconnected!")

func req_next_level() -> void:
	rpc_id(1, "update_level", get_tree().get_network_unique_id())

remote func disconnect_player(id):
	print("Disconnect -> " + str(id))
	Global.remove_node(str(id), Nodes)

remote func update_player_transform(id, position, velocity):
	# Função que atualiza os dummys
	if get_tree().get_network_unique_id() != id:
		Nodes.get_node(str(id)).update_transform(position, velocity)

# Função temporaria
remote func next_level() -> void:
	rpc_id(1, "next_level")

# Função parcialmente funcionando
# ISSUE: Por algum motivo os sinais das "DoorEspeon" e "DoorUmbreom" estão com problemas
# Caso seja corrijido o problema, basta o mapa quando receber a informação que ambos estão nas 
# respectivas portas que ele irá enviar uma requisição para o servidor para ir ao proximo mapa.
remote func load_level(level, spawn_point, rst=false):
	# @level: Nome do nivel a ser carregado
	# @spawn_point: Dicionario com os pontos de spawn para cada personagem
	# @rst: (RESET) é chamado pelo servidor para forçar o reset da fase caso algum personagem morra.
	if level != current_level or rst:
		var m = get_tree().root.get_node("/root/Map")
		get_tree().root.remove_child(m)
		current_level = str(level)
		var l = load(level)
		var scene = l.instance()
		scene.name = "Map"
		get_tree().root.add_child_below_node(Nodes, scene)
		
		# Move os players para o ponto de spawn
		print("Spawning Players")
		for key in spawn_point:
			for k in players:
				if key == k:
					# Apenas o player atribuido a sessao atual do cliente
					if players[k] == str(get_tree().get_network_unique_id()):
						Nodes.set_pos(players[k], spawn_point[key])

# Para a implementação da sincronia dos itens do mapa na parte do cliente.
#
# Poderia ser feito dessa forma:
#
# Os mapas que os clientes estão carregando não teriam posicionados os itens nele.
# Quando o cliente chamasse a função "request_level" como foi chamada em "_connected_to_server"
# Receberia também aonde o proprio cliente deveria spawnar os itens no mapa
# e os seus respectivos estados(no caso das barreiras). Essa função de spawn ou remoção de itens
# deveria ser também chamada pelo servidor quando um item fosse modificado, para que seu estado ou
# existencia fosse sincronizada entre os clientes.
