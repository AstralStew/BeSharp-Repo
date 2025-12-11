class_name DofKnightStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnLeaderReveal.")
	if DeckOfFate.get_leader_type_p2() == CardType.Monster:
		DeckOfFate.add_combat_strength_p1(2)
func on_support_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnSupportReveal. Adjusted!")
	

func on_combat_finished() -> void:
	print("[DoFKnightSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFKnightSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFKnightSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Dragon":
		print("[DoFSquireSR(",card_name,")] 'Dragon' found! Returning true!")
		return true
	print("[DoFSquireSR(",card_name,")] No 'Dragon' found :( Returning false.")
	return false
