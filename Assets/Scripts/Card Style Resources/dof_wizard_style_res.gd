class_name DofWizardStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWizardSR] OnLeaderReveal.")
	
	# Leader ability > Swap 2 backline slots
	player_manager.swap_backline_slots()
	await player_manager.resolution_step
	
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWizardSR] OnSupportReveal.")
	
	# Support ability > Shuffle hand into deck + draw that many cards
	var current_hand_size = player_manager.get_hand_size()
	player_manager.shuffle_hand()
	await player_manager.get_tree().create_timer(0.5).timeout
	player_manager.draw_cards(current_hand_size)
	
	super.on_support_reveal()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWizardSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Seer":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFWizardSR] 'Seer' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFWizardSR] No 'Seer' found :( Returning false.")
	return false
