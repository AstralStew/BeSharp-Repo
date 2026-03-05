class_name DofSquireStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireSR] OnLeaderReveal.")
	
	# Leader ability > Gain 2 strength if support is Warrior
	if player_manager.get_support_type() == CardType.Warrior:
		player_manager.adjust_strength_counters(2)
	
	super.on_leader_reveal()

func on_support_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireSR] OnSupportReveal.")
	
	# Support ability > Gain 2 strength if opponent is Rogue or Mystic	
	player_manager.adjust_strength_counters(2)
	
	super.on_support_reveal()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Knight":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireSR] 'Knight' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSquireSR] No 'Knight' found :( Returning false.")
	return false
