class_name DofseerStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFseerSR(",card_name,")] OnLeaderReveal. Adjusted!")
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFseerSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.draw_cards_p1(2)
	super.on_support_reveal()
	
func on_combat_finished() -> void:
	print("[DoFseerSR(",card_name,")] OnCombatFinished.")
	super.on_combat_finished()
	
func on_enter_backline() -> void:
	print("[DoFseerSR(",card_name,")] OnEnterBackline.")
	super.on_enter_backline()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFseerSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Assassin":
		print("[DoFseerSR(",card_name,")] 'Assassin' found! Returning true!")
		return true
	print("[DoFseerSR(",card_name,")] No 'Assassin' found :( Returning false.")
	return false
