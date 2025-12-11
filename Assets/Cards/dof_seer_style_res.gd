class_name DofseerStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFseerSR(",card_name,")] OnLeaderReveal. Adjusted!")
	

func on_support_reveal() -> void:
	print("[DoFseerSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.draw_cards_p1(2)

func on_combat_finished() -> void:
	print("[DoFseerSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFseerSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFseerSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Assassin":
		print("[DoFseerSR(",card_name,")] 'Assassin' found! Returning true!")
		return true
	print("[DoFseerSR(",card_name,")] No 'Assassin' found :( Returning false.")
	return false
