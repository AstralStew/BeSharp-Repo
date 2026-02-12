class_name DofDragonStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFdragonSR(",card_name,")] OnLeaderReveal. Adjusted!")
	#DeckOfFate.clear_combat_strength_p1()
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFdragonSR(",card_name,")] OnSupportReveal. Adjusted!")
	super.on_support_reveal()

func on_combat_finished() -> void:
	print("[DoFdragonSR(",card_name,")] OnCombatFinishused.")
	#if (DeckOfFate.get_leader_p1().card_data as DofCardStyleResource).card_name == "dragon":
		#DeckOfFate.remove_card_p1(DeckOfFate.get_leader_p1())
	#elif DeckOfFate.get_combat_result() == DeckOfFate.CombatResult.win:
		#DeckOfFate.add_points_p1(1)
		#DeckOfFate.remove_card_p1(DeckOfFate.get_leader_p1())
	super.on_combat_finished()

func on_enter_backline() -> void:
	print("[DoFdragonSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFdragonSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Thief":
		print("[DoFdragonSR(",card_name,")] 'Thief' found! Returning true!")
		return true
	print("[DoFdragonSR(",card_name,")] No 'Thief' found :( Returning false.")
	return false
