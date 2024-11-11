extends Node

class Player:
	var id: String
	var peer_id: int
	var name: String

	func _init(c_id, c_peerId, c_name):
		id = c_id
		peer_id = c_peerId
		name = c_name

const MAX_PLAYERS = 4;
var player_slots: Array = [];
@export var joining_as_new_player_allowed := true
@export var free_up_player_slot_on_disconnect := true

var players_by_id: Dictionary = {}
var peer_id_to_player_id: Dictionary = {}

# Peers connected but not yet setup as a player
var connecting_peers: Dictionary = {}

func _ready():
	player_slots.resize(MAX_PLAYERS)
	WebsocketServer.connect("client_connected", _on_client_connect)
	WebsocketServer.connect("client_disconnected", _on_client_disconnect)
	WebsocketServer.connect("message_received", _on_client_message)

func _on_client_connect(peer_id: int):
	print("_on_client_connect %s" % str(peer_id))
	WebsocketServer.send(peer_id, JSON.stringify({ "type": "who-are-you" }))

func _on_client_disconnect(peer_id: int):
	print("_on_client_disconnect %s" % str(peer_id))
	var player_id = peer_id_to_player_id.get(peer_id)
	print("_on_client_disconnect player_id %s" % player_id)
	if (player_id != null and free_up_player_slot_on_disconnect):
		peer_id_to_player_id.erase(peer_id)
		for i in range(player_slots.size()):
			if (player_slots[i] != null):
				if (players_by_id[player_slots[i]].id == player_id):
					print("_on_client_disconnect clear player slot %s" % str(i))
					player_slots[i] = null
		print("_on_client_disconnect clear playsers_by_id %s" % player_id)
		players_by_id.erase(player_id)

func _next_player_idx():
	for i in range(player_slots.size()):
		if (player_slots[i] == null):
			return i
	return null

func _on_client_message(peer_id: int, message):
	print("_on_client_message %s" % message)
	if (message.type == "who-i-am"):
		var data = message.data;
		if not players_by_id.has(data.player_id):
			var next_idx = _next_player_idx()
			if joining_as_new_player_allowed and next_idx != null:
					players_by_id[data.player_id] = Player.new(data.player_id, peer_id, data.player_name)
					player_slots[next_idx as int] = data.player_id
					peer_id_to_player_id[peer_id] = data.player_id
					var scene = get_tree().current_scene
					if scene.name == "Game" and peer_id_to_player_id.has(peer_id):
						scene.player_joined(peer_id_to_player_id[peer_id])
			else:
				WebsocketServer.peer_disconnect(peer_id)
		else:
			players_by_id[data.player_id].peer_id = peer_id
			players_by_id[data.player_id].name = data.player_name
	elif (message.type == "get-game-state"):
		var scene = get_tree().current_scene
		# if (scene.name == "Game"):
		# 	WebsocketServer.send(peer_id, JSON.stringify({
		# 		"type": "game-state",
		# 		"data": scene.get_game_state(),
		# 	}))
		# else:
		WebsocketServer.send(peer_id, JSON.stringify({
			"type": "game-state",
			"data": {
				"state": "lobby",
			},
		}))
	elif (message.type == "phone-motion"):
		var scene = get_tree().current_scene
		print(scene.name)
		if scene.name == "Game" and peer_id_to_player_id.has(peer_id):
			var data = message.data;
			scene.set_phone_motion(peer_id_to_player_id[peer_id], data)

func broadcast_game_state(game_state):
	for i in range(len(player_slots)):
		var player = get_player_by_idx(i)
		if player != null:
			WebsocketServer.send(player.peer_id, JSON.stringify({
				"type": "game-state",
				"data": game_state,
			}))

func get_player_by_idx(idx: int):
	if (idx >= len(player_slots)):
		return null
	var player_id = player_slots[idx]
	if (player_id != null):
		return players_by_id[player_id]
	else:
		return null
