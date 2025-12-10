class_name DofKnightStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnLeaderReveal.")
	
func on_support_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.add_combat_strength_p1(6)

func on_combat_finished() -> void:
	print("[DoFKnightSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFKnightSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFKnightSR(",card_name,")] CalculateAdjacency using '",card,"'")
	print("[DoFKnightSR(",card_name,")] Not implemented, returning false.")
	return false
