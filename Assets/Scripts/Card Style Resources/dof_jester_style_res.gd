class_name DofJesterStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFJesterSR] OnLeaderReveal.")
	
	# Leader ability > Choose a card in backline, becomes copy of it with 0 strength
	# 
	
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFJesterSR] OnSupportReveal.")
	
	# Support ability > Choose a card in backline, becomes copy of it with 0 strength
	# 
	
	super.on_support_reveal()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFJesterSR] CalculateAdjacency, using '",card,"' (this card always returns false)")
	return false
