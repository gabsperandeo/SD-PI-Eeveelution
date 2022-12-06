extends Node

# Deveria ser implementado uma função para sincronizar os itens dos mapas entre todos os clientes.
#
# Uma das formas de implementar seria:
# Criar aqui no servidor um vetor que guardaria os estados e as posições dos itens a serem spawnados
# em cada mapa. Quando o cliente conectar ele iria fazer uma rpc para o servidor pedindo qual é o
# mapa atual, e receberia junto com essa informação os dados de onde teria que spawnar os itens e 
# os seus estados atuais. Assim quando um item fosse consumido o cliente comunicaria o servidor onde
# o mesmo teria seu estado modificado, e o servidor comunicaria os outros clientes informando que
# determinado item deve ser removido do mapa. Mantendo assim o controle e uso dos itens disponiveis
# no lado do servidor.
#
# O mais importante para a implementação dessa parte do jogo é os itens não estarem sendo controlados
# pelo cliente, já que seria muito fácil para criar por exemplo um item infinito ou com propriedades
# aumentadas. Sendo controlado pelo servidor os status dos itens e se eles existem ou não é mais fácil
# fazer o controle, já que se um usuário utilizar um item que não existe, o efeito simplemente não
# será aplicado ao personagem dele pelo servidor.
#
#
#
# Uma outra melhoria para o jogo seria, os status do personagens serem de responsabilidade do servidor
# e não do cliente como é no momento.
#
# Se o servidor controla por exemplo a força do salto dos personagens, dificulta o player
# hackear o cliente para deixar o personagem dele com um pulo gigantesco. Já que, se o cliente 
# modificasse o valor do pulo localmente, seria atualizado pelo servidor, e o movimento dele
# seria em relação ao valor que está no servidor e não no cliente, impedindo(dificultando, já que sempre
# se acha um jeito) do cliente ser capaz de modificar propriedades do proprio personagem. 

const DEFAULT_PORT = 25565
const MAX_PLAYERS = 2

var ip_address = ""

var levels = [
	"res://Níveis/Level_01.tscn",
	"res://Níveis/Level_02.tscn",
	"res://Níveis/Level_03.tscn",
	"res://Níveis/Level_04.tscn",
	"res://Níveis/Level_05.tscn",
]

var current_level_id = 0
var current_level = "res://Níveis/Level_01.tscn"
const players_types = ["Espeon", "Umbreon"]
var current_players_types = {}

# Guarda os ids dos players que chegaram ao fim da fase.
var level_finished = []

var spawn_points = {
	"res://Níveis/Level_01.tscn": {"Espeon": Vector2(24,300), "Umbreon": Vector2(56,300)},
	"res://Níveis/Level_02.tscn": {"Espeon": Vector2(17,118), "Umbreon": Vector2(17,278)},
	"res://Níveis/Level_03.tscn": {"Espeon": Vector2(18,14), "Umbreon": Vector2(627,14)},
	"res://Níveis/Level_04.tscn": {"Espeon": Vector2(15,330), "Umbreon": Vector2(625,16)},
	"res://Níveis/Level_05.tscn": {"Espeon": Vector2(27,340), "Umbreon": Vector2(27,27)},	
}

func _ready() -> void:
	#if OS.get_name() == "Windows" or OS.get_name() == "x11":
	#	ip_address = IP.get_local_addresses()[3]

	ip_address = "127.0.0.1"
	print("IP DO SERVIDOR -> " + str(ip_address))
	with_multiplayerapi()

func with_multiplayerapi():
	var server = NetworkedMultiplayerENet.new()
	var err = server.create_server(DEFAULT_PORT, MAX_PLAYERS)
	if err != OK:
		print("Unnable to start server.")
		return

	get_tree().network_peer = server
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	print("Server created")

func _player_connected(id) -> void:
	# Os players são spawnados fora dos limites da janela, posteriormente são reposicionados. Quando
	# o for enviado ao cliente em outras funções a posição de spawn.
	if current_players_types.empty():
		current_players_types["Espeon"] = str(id)
		rpc_id(0, "instance_player", Vector2(-80, -49), current_players_types)
	else:
		if current_players_types.has("Espeon"):
			current_players_types["Umbreon"] = str(id)
			rpc_id(0, "instance_player", Vector2(-80, -40), current_players_types)
		elif current_players_types.has("Umbreon") and not current_players_types.has("Espeon"):
			current_players_types["Espeon"] = str(id)
			rpc_id(0, "instance_player", Vector2(-80, -40), current_players_types)

func _player_disconnected(id) -> void:
	for key in current_players_types.keys():
		if current_players_types[key] == str(id):
			print("O player " + str(id) + " do tipo " + key + " se desconectou.")
			current_players_types.erase(key)

# Função temporaria, usada por motivos de bug na "DoorEspeon" e "DoorUmbreon"
# O correto seria utilizar a função update_level() para trocar de fase.
remote func next_level() -> void:
	if current_level_id + 1 < len(levels):
		current_level_id += 1
	current_level = levels[current_level_id] if current_level_id <= len(levels) else levels[current_level_id-1]
	rpc("load_level", current_level, spawn_points[current_level], true)

remote func update_level(id):
	# Toda vez que um player está na sua respectiva porta o mapa manda uma rpc para esta função
	# A função adiciona o id dele a um vetor, quando os dois personagens estão nas respectivas portas
	# a função verifica se os ids estão realmente conectados(são realmente players), se sim
	# o servidor manda o aviso para que seja feita a troca de mapas.
	var already_exists = false
	for idx in level_finished:
		if idx == id:
			already_exists = true
	if not already_exists:
		level_finished.append(id)

	if len(level_finished) == 2:
		var approved = false
		var tmp = []
		for key in current_players_types:
			tmp.append(current_players_types[key])
			
		# Se os players que mandaram mensagem informando que chegaram ao final da fase são realmente
		# players é feito a troca de mapas.
		if tmp in level_finished:
			current_level_id += 1
			current_level = levels[current_level_id] if current_level_id <= len(levels) else levels[current_level_id-1]
			rpc("load_level", current_level, spawn_points[current_level], true)

remote func reset_level() -> void:
	# Informa aos clientes para resetarem a fase.
	rpc("load_level", current_level, spawn_points[current_level], true)

remote func request_level():
	# Função usada quando um novo cliente é conectado.
	# Informa ao cliente qual é a fase que está rodando no momento, e seus respectivos spawn points.
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "load_level", current_level, spawn_points[current_level])

remote func update_transform(position, velocity):
	# Manda a posição dos players para todos os clientes, para que atualizem as posições dos personagens.
	var player_id = get_tree().get_rpc_sender_id()
	rpc_unreliable("update_player_transform", player_id, position, velocity)
