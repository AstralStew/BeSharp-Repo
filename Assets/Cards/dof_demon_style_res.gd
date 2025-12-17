class_name DofdemonStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFdemonSR(",card_name,")] OnLeaderReveal. Adjusted!")
	super.on_leader_reveal()
	
func on_support_reveal() -> void:
	print("[DoFdemonSR(",card_name,")] OnSupportReveal. Adjusted!")
	super.on_support_reveal()
	
func on_combat_finished() -> void:
	print("[DoFdemonSR(",card_name,")] OnCombatFinished.")
	if (DeckOfFate.get_leader_p1().card_data as DofCardStyleResource).card_name == "Demon":
		DeckOfFate.remove_card_p1(DeckOfFate.get_leader_p1())
	elif DeckOfFate.get_combat_result() == DeckOfFate.CombatResult.win:
		DeckOfFate.add_points_p1(1)
		DeckOfFate.remove_card_p1(DeckOfFate.get_leader_p1())
	super.on_combat_finished()
	
func on_enter_backline() -> void:
	print("[DoFdemonSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()
	
func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFdemonSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Thief":
		print("[DoFdemonSR(",card_name,")] 'Thief' found! Returning true!")
		return true
	print("[DoFdemonSR(",card_name,")] No 'Thief' found :( Returning false.")
	return false
