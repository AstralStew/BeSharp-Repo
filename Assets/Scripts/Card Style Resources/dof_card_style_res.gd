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

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnLeaderReveal finished, sending completed resolution signal...")
	#DeckOfFate.instance.swap_p1_backline_slots()
	#await DeckOfFate.instance.resolution_step
	await player_manager.get_tree().process_frame
	player_manager.complete_resolution()
	
func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,")] OnSupportReveal finished, sending completed resolution signal...")
	#DeckOfFate.instance.remove_backline_card_p1()
	#await DeckOfFate.instance.resolution_step
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
