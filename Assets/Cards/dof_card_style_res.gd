class_name DofCardStyleResource extends CardResource

enum CardType {Warrior, Rogue, Mystic, Monster, Jester}

#this defines card values
@export var card_name: String
@export var card_type : CardType
@export var strength: int
@export var top_texture: Texture2D

func on_leader_reveal() -> void:
	print("[DoFCSR(",card_name,")] OnLeaderReveal.")
	
func on_support_reveal() -> void:
	print("[DoFCSR(",card_name,")] OnSupportReveal.")

func on_combat_finished() -> void:
	print("[DoFCSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFCSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",card_name,")] CalculateAdjacency using '",card,"'")
	print("[DoFCSR(",card_name,")] Not implemented, returning false.")
	return false
