class_name DofThiefStyleResource extends DofCardStyleResource

	
func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFThiefSR] OnSupportReveal. Adjusted!")
	
	# Support ability > On win, gain 1 VP
	player_manager.draw_cards(1)
	
	super.on_support_reveal()

func on_combat_finished() -> void:
	
	# Leader ability > On win, gain 1 VP
	if was_leader && player_manager.did_i_win:
		player_manager.adjust_points(1)
	
	super.on_combat_finished()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFThiefSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Wizard":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFThiefSR] 'Wizard' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFThiefSR] No 'Wizard' found :( Returning false.")
	return false
