class_name DofSpyStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSpySR] OnLeaderReveal.")
	
	# Leader ability > Gain 2 strength if opponent is Rogue or Mystic
	var leader_type = player_manager.get_leader_type()
	if leader_type == CardType.Rogue || leader_type == CardType.Mystic:
		player_manager.adjust_strength_counters(2)

	super.on_leader_reveal()


func on_enter_backline() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSpySR] OnEnterBackline.")
	
	# Support ability > Remove from play and swap in card from hand
	if !was_leader:
		player_manager.remove_card(player_manager.get_support())
		player_manager.backline_hand_card()
		await player_manager.resolution_step
	
	super.on_enter_backline()



func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSpySR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Thief":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFSpySR] 'Thief' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFSpySR] No 'Thief' found :( Returning false.")
	return false
