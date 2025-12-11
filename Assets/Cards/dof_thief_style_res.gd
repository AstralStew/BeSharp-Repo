class_name DofthiefStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFthiefSR(",card_name,")] OnLeaderReveal. Adjusted!")

func on_support_reveal() -> void:
	print("[DoFthiefSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.draw_cards_p1(1)

func on_combat_finished() -> void:
	print("[DoFthiefSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFthiefSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFthiefSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Wizard":
		print("[DoFthiefSR(",card_name,")] 'Wizard' found! Returning true!")
		return true
	print("[DoFthiefSR(",card_name,")] No 'Wizard' found :( Returning false.")
	return false
