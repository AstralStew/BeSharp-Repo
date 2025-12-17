class_name DofthiefStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFthiefSR(",card_name,")] OnLeaderReveal. Adjusted!")
	super.on_leader_reveal()
	
func on_support_reveal() -> void:
	print("[DoFthiefSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.draw_cards_p1(1)
	super.on_support_reveal()

func on_combat_finished() -> void:
	print("[DoFthiefSR(",card_name,")] OnCombatFinished.")
	super.on_combat_finished()
	
func on_enter_backline() -> void:
	print("[DoFthiefSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFthiefSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Wizard":
		print("[DoFthiefSR(",card_name,")] 'Wizard' found! Returning true!")
		return true
	print("[DoFthiefSR(",card_name,")] No 'Wizard' found :( Returning false.")
	return false
