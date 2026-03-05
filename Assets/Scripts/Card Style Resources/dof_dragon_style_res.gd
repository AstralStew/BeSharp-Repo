class_name DofDragonStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFDragonSR] OnLeaderReveal.")
	
	# Leader ability > Clear all strength counters
	player_manager.clear_strength_counters()
	
	super.on_leader_reveal()



func on_enter_backline() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFDragonSR] OnEnterBackline.")
	
	# Support ability > Remove an adjacent card 
	#if !was_leader:
	
	super.on_enter_backline()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFDragonSR] CalculateAdjacency, using '",card,"' (this card always returns false)")
	return false
