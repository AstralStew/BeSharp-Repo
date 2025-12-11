class_name DofAssassinStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFAssassinSR(",card_name,")] OnLeaderReveal. Adjusted!")
	DeckOfFate.clear_combat_strength_p2()

func on_support_reveal() -> void:
	print("[DoFAssassinSR(",card_name,")] OnSupportReveal. Adjusted!")
	DeckOfFate.add_combat_strength_p2(-2)

func on_combat_finished() -> void:
	print("[DoFAssassinSR(",card_name,")] OnCombatFinished.")

func on_enter_backline() -> void:
	print("[DoFAssassinSR(",card_name,")] OnEnterBackline.")

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFAssassinSR(",card_name,")] CalculateAdjacency, using '",card,"'")
	if card.card_name == "ShieldBearer":
		print("[DoFAssassinSR(",card_name,")] 'ShieldBearer' found! Returning true!")
		return true
	print("[DoFAssassinSR(",card_name,")] No 'ShieldBearer' found :( Returning false.")
	return false
