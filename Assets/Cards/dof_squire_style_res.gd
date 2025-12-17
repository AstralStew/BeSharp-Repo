class_name DofSquireStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFSquireSR(",card_name,")] OnLeaderReveal. Adjusted!")
	if DeckOfFate.get_support_type_p1() == CardType.Warrior:
		DeckOfFate.add_combat_strength_p1(2)
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFSquireSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.add_combat_strength_p1(2)
	super.on_support_reveal()

func on_combat_finished() -> void:
	print("[DoFSquireSR(",card_name,")] OnCombatFinished.")
	super.on_combat_finished()

func on_enter_backline() -> void:
	print("[DoFSquireSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFSquireSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Knight":
		print("[DoFSquireSR(",card_name,")] 'Knight' found! Returning true!")
		return true
	print("[DoFSquireSR(",card_name,")] No 'Knight' found :( Returning false.")
	return false
