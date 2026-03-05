class_name DofSeerStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSeerSR] OnLeaderReveal.")
	
	# Leader ability > Draw 2 cards
	player_manager.draw_cards(2)
	
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSeerSR] OnSupportReveal.")
	
	# Support ability > Search deck for card and draw it
	#
	
	super.on_support_reveal()



func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSeerSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Assassin":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFSeerSR] 'Assassin' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSeerSR] No 'Assassin' found :( Returning false.")
	return false
