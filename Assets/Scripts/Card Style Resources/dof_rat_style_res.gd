class_name DofRatStyleResource extends DofCardStyleResource



func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFRatSR] OnSupportReveal.")
	
	# Support ability > Opponent chooses hand card to remove
	player_manager.get_other_player().remove_hand_card()
	await player_manager.get_other_player().resolution_step
	
	
	super.on_support_reveal()


func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFRatSR] OnCombatFinished.")
	
	# Leader ability > Both players pick a combat card to remove
	#
	
	super.on_combat_finished()

func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFRatSR] CalculateAdjacency, using '",card,"' (this card always returns false)")
	return false
