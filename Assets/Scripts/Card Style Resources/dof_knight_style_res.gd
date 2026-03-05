class_name DofKnightStyleResource extends DofCardStyleResource

func on_leader_reveal() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFKnightSR] OnLeaderReveal.")
	
	# Leader ability > Gain 2 strength counters if opponent is Monster
	if player_manager.get_other_player().get_leader_type() == CardType.Monster:
		player_manager.adjust_strength_counters(2)
	
	super.on_leader_reveal()

func on_combat_finished() -> void:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFKnightSR] OnCombatFinished.")
	
	# Support ability > Gain 1 point if we won combat by 2+
	if !was_leader && player_manager.get_relative_strength() >= 2:
		player_manager.adjust_points(1)
	
	super.on_combat_finished()


func calculate_adjacency(card:DofCardStyleResource) -> bool:
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFKnightSR] CalculateAdjacency, using '",card,"'")
	if card.card_name == "Dragon":
		print("[DoFCSR(",player_manager,"/",card_name,"/DoFKnightSR] 'Dragon' found! Returning true!")
		return true
	print("[DoFCSR(",player_manager,"/",card_name,"/DoFKnightSR] No 'Dragon' found :( Returning false.")
	return false
