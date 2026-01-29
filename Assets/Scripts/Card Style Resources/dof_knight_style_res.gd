class_name DofKnightStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnLeaderReveal.")
	if DeckOfFate.get_leader_type_p2() == CardType.Monster:
		DeckOfFate.add_combat_strength_p1(2)
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFKnightSR(",card_name,")] OnSupportReveal. Adjusted!")
	super.on_support_reveal()

func on_combat_finished() -> void:
	print("[DoFKnightSR(",card_name,")] OnCombatFinished.")
	super.on_combat_finished()
	
func on_enter_backline() -> void:
	print("[DoFKnightSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFKnightSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Dragon":
		print("[DoFSquireSR(",card_name,")] 'Dragon' found! Returning true!")
		return true
	print("[DoFSquireSR(",card_name,")] No 'Dragon' found :( Returning false.")
	return false
