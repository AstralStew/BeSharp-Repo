extends Node

@onready var label_gamestarting = $Label_GameStarting

@onready var player_name : String = ""
@onready var ip_address : String = ""
@onready var port : int = 7000

@export var game_file_path : String = "res://Assets/Scenes/GameManager.tscn"

func _on_line_edit_name_text_changed(new_text: String) -> void:
	print("[LobbyUI] Name text edited!")
	Lobby.player_info["name"] = new_text

func _on_line_edit_ip_address_text_changed(new_text: String) -> void:
	print("[LobbyUI] IP address text edited!")
	ip_address = new_text

func _on_line_edit_port_text_changed(new_text: String) -> void:
	print("[LobbyUI] Port text edited!")
	port = new_text.to_int()



func _on_host_button_pressed() -> void:
	print("[LobbyUI] Host bustton pressed!")
	Lobby.create_game(port)
	Lobby.player_connected.connect(on_player_connected)


func _on_join_button_pressed() -> void:
	print("[LobbyUI] Join button pressed!")
	Lobby.join_game(ip_address,port)


func on_player_connected(new_player_id, new_player_info) -> void:
	label_gamestarting.visible = true
	await get_tree().create_timer(3).timeout
	game_starting()


func game_starting() -> void:
	Lobby.load_game.rpc(game_file_path)
