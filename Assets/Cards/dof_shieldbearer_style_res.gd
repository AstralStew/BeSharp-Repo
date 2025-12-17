class_name DofshieldbearerStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFshieldbearerSR(",card_name,")] OnLeaderReveal. Adjusted!")
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFshieldbearerSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.draw_cards_p1(2)
	super.on_support_reveal()
	
func on_combat_finished() -> void:
	print("[DoFshieldbearerSR(",card_name,")] OnCombatFinished.")
	if DeckOfFate.get_combat_result() == DeckOfFate.CombatResult.loss:
		DeckOfFate.return_to_hand_p1(DeckOfFate.get_leader_p1())
		if (DeckOfFate.get_support_p1().card_data as DofCardStyleResource).card_name == "Shieldbearer":
			DeckOfFate.remove_card_p1(DeckOfFate.get_support_p1())
	super.on_combat_finished()
	
func on_enter_backline() -> void:
	print("[DoFshieldbearerSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()
	
func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFshieldbearerSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Assassin":
		print("[DoFshieldbearerSR(",card_name,")] 'Assassin' found! Returning true!")
		return true
	print("[DoFshieldbearerSR(",card_name,")] No 'Assassin' found :( Returning false.")
	return false
