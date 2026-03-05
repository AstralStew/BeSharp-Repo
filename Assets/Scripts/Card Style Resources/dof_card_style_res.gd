class_name DofCardStyleResource extends CardResource

enum CardType {Warrior, Rogue, Mystic, Monster, Jester, NULL}

#this defines card values
@export_category("CARD VALUES")
@export var card_name: String
@export var card_type : CardType
@export var strength: int
@export var top_texture: Texture2D

var player_manager : PlayerManager
var current_slot : CardSlot
var playable : bool = true

var was_leader:bool = false

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnLeaderReveal finished, sending completed resolution signal...")
	was_leader = true
	
	await player_manager.get_tree().process_frame
	player_manager.complete_resolution()
	
func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnSupportReveal finished, sending completed resolution signal...")
	was_leader = false
	
	await player_manager.get_tree().process_frame
	player_manager.complete_resolution()

func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnCombatFinished finished, sending completed resolution signal...")
	await player_manager.get_tree().process_frame
	player_manager.complete_resolution()

func on_enter_backline() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnEnterBackline finished, sending completed resolution signal...")
	await player_manager.get_tree().process_frame
	player_manager.complete_resolution()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,")] CalculateAdjacency using '",card,"'")
	print("[DoFCSR(",player_manager,"/",card_name,")] Not implemented, returning false.")
	return false
