class_name DofAssassinStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFAssassinSR] OnLeaderReveal.")
	
	# Leader ability > Clear strength counters from opponent
	player_manager.get_other_player().clear_strength_counters()
	
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFAssassinSR] OnSupportReveal.")
	
	# Support ability > Remove 2 strength from opponent
	player_manager.get_other_player().adjust_strength_counters(-2)
	
	super.on_support_reveal()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFAssassinSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "ShieldBearer":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFAssassinSR] 'ShieldBearer' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFAssassinSR] No 'ShieldBearer' found :( Returning false.")
	return false
