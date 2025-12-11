class_name DofSquireStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFSquireSR(",card_name,")] OnLeaderReveal. Adjusted!")
	if DeckOfFate.get_support_type_p1() == CardType.Warrior:
		DeckOfFate.add_combat_strength_p1(2)

func on_support_reveal() -> void:
	print("[DoFSquireSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.add_combat_strength_p1(2)

func on_combat_finished() -> void:
	print("[DoFSquireSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFSquireSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFSquireSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Knight":
		print("[DoFSquireSR(",card_name,")] 'Knight' found! Returning true!")
		return true
	print("[DoFSquireSR(",card_name,")] No 'Knight' found :( Returning false.")
	return false
