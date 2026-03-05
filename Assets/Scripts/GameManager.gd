class_name GameManager extends CanvasLayer


var _debug_name : String :
	get:
		return "[GameManager(Server)]" if multiplayer.is_server() else "[GameManager(Client)]"

func _ready():
	# Preconfigure game.
	print(_debug_name,"Ready.")

	Lobby.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.


# Called only on the server.
func start_game():
	# All peers are ready to receive RPCs in this scene.
	print(_debug_name," Start game.")
