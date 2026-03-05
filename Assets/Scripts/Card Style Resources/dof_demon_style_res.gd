class_name DofDemonStyleResource extends DofCardStyleResource


func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFDemonSR] OnCombatFinished.")
	
	# Leader ability > Remove itself
	if was_leader:
		player_manager.remove_card(player_manager.get_leader())
	
	# Support ability > On win, add 1 point + remove leader
	elif player_manager.did_i_win:
		DeckOfFate.add_points_p1(1)
		player_manager.remove_card(player_manager.get_leader())

	super.on_combat_finished()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFDemonSR] CalculateAdjacency, using '",card,"' (this card always returns false)")
	return false





	#if (player_manager.get_leader().card_data as DofCardStyleResource).card_name == "Demon":
