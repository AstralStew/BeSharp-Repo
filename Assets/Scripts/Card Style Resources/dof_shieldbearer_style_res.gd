class_name DofShieldbearerStyleResource extends DofCardStyleResource


func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFShieldBearerSR] OnCombatFinished.")
	
	if !player_manager.did_i_win:
		
		# Leader ability > On loss, return leader (i.e. itself)
		player_manager.return_to_hand(player_manager.get_leader())
	
		# Support ability > On loss, return leader (above) + remove itself 
		if !was_leader:
			player_manager.remove_card(player_manager.get_support())
	
	super.on_combat_finished()



func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireBearerSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Squire":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireBearerSR] 'Squire' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireBearerSR] No 'Squire' found :( Returning false.")
	return false
