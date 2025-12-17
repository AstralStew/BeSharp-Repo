class_name DofSpyStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFspySR(",card_name,")] OnLeaderReveal. Adjusted!")
	if DeckOfFate.get_leader_type_p2() == CardType.Rogue || DeckOfFate.get_leader_type_p2() == CardType.Mystic:
		DeckOfFate.add_combat_strength_p1(2)
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFspySR(",card_name,")] OnSupportReveal. Adjusted!")
	super.on_support_reveal()

func on_combat_finished() -> void:
	print("[DoFspySR(",card_name,")] OnCombatFinished.")
	super.on_combat_finished()

func on_enter_backline() -> void:
	print("[DoFspySR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFspySR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Thief":
		print("[DoFspySR(",card_name,")] 'Thief' found! Returning true!")
		return true
	print("[DoFspySR(",card_name,")] No 'Thief' found :( Returning false.")
	return false
