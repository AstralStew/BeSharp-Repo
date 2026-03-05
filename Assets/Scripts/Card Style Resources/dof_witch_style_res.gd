class_name DofWitchStyleResource extends DofCardStyleResource


func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWitchSR] OnSupportReveal.")
	
	# Support ability > Swap opponent's leader + support
	player_manager.get_other_player().swap_leader_and_support()
	
	super.on_support_reveal()



func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWitchSR] OnCombatFinished.")
	
	# Leader ability > Look at top card of deck + may remove it
	# if was_leader:
	
	super.on_combat_finished()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWitchSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Demon":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFWitchSR] 'Demon' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWitchSR] No 'Demon' found :( Returning false.")
	return false
