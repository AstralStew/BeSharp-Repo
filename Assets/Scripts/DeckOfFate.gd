class_name DeckOfFate extends CanvasLayer
#Runs the game

enum CombatResult {win,draw,loss}

@export_category("REFERENCES")
static var instance:DeckOfFate = null
@onready var dof_deck_manager: DoFDeckManager = $DoFDeckManager
@onready var player_hand: CardHand = $PlayerHand
@onready var leader_slot: CardHand = $LeaderSlot
@onready var support_slot: CardHand = $SupportSlot
@onready var phase_label: RichTextLabel = $PhaseLabel
@onready var p1_score_label: RichTextLabel = $P1ScoreDesc_VB/P1Score_RTL
@onready var p2_score_label: RichTextLabel = $P2ScoreDesc_VB/P2Score_RTL
@onready var helper_label: RichTextLabel = $HelperText_MC/HelperText_VB/HelperText_RTL
@export var victory_slots: Array[CardSlot]	# set by hand in inspector

@export_category("CONTROL")
@export var number_of_rounds : int = 3

@export_category("READ ONLY")
@export var current_round : int = 0
@export var p1_score : int = 0
@export var p2_score : int = 0
@export var current_phase : phases = phases.TurnStart
@export var first_draw_completed : bool = false
@export var waiting_for_card : bool = false
@export var waiting_for_playable_card : bool = false
@export var waiting_for_slot : bool = false
@export var waiting_for_empty_slot : bool = false
@export var waiting_for_full_slot : bool = false
@export var waiting_for_resolution : bool = false
@export var selected_card : Card = null
@export var selected_slot : CardSlot = null
@export var p1_combat_tokens : int = 0
@export var p2_combat_tokens : int = 0
@export var combat_result : CombatResult = CombatResult.loss

enum phases {TurnStart, PickLeader, PickSupport, RevealSupport, RevealLeader, Battle, BacklineLeader, BacklineSupport, TurnEnd}

signal card_selected
signal slot_selected
signal resolution_completed
signal resolution_step

var hand_size: int

var backline_slots_available:bool:
	get:
		print("[DeckOfFate] Backline_slots_available getter...")
		for slot in victory_slots:
			print("[DeckOfFate] Slot '",slot,"' is ","full, continuing..." if slot.is_full() else "empty, good to go!")
			if !slot.is_full():
				return true
		return false


func _init() -> void:
	CG.def_front_layout = "Default"

func _ready() -> void:
	instance = self
	dof_deck_manager.setup()
	_start_game()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_F):
		Engine.time_scale = 5
	else: 
		Engine.time_scale = 1


func _start_game() -> void:
	
	# Reset the listed scores
	p1_score_label.text = "0"
	p2_score_label.text = "0"
	
	# Start the "next phase" loop
	await get_tree().create_timer(1).timeout 
	_next_phase()


func _next_phase() -> void:
	# Increment phase enum (except for the first draw)
	if first_draw_completed:
		current_phase = ((current_phase + 1) % phases.size()) as phases
	
	
	# Tell the players which phase we are in
	phase_label.text = phases.keys()[current_phase]
	tween_visibility(phase_label,Color(1,1,1,1),0.5,Tween.EaseType.EASE_OUT,Tween.TransitionType.TRANS_LINEAR)
	await get_tree().create_timer(1).timeout 
	tween_visibility(phase_label,Color(1,1,1,0),0.5,Tween.EaseType.EASE_IN,Tween.TransitionType.TRANS_LINEAR)
	await get_tree().create_timer(0.51).timeout 
	
	# Check the phase enum 
	match current_phase:
		
		phases.TurnStart:
			helper_label.text = "Dealing cards..."
			combat_result = CombatResult.loss
			current_round += 1
			print("[DeckOfFate] TurnStart - Current round set to ", current_round)
			# Deal 2 cards (or 4 on the first turn)
			deal()
		
		phases.PickLeader:
			helper_label.text = "Pick a Leader from your hand"
			# Wait till the player selects a card
			waiting_for_card = true
			waiting_for_playable_card = true
			await card_selected
			# Hide + disable the card from being grabbed etc
			selected_card.flip()
			selected_card.undraggable = true
			(selected_card.card_data as DofCardStyleResource).playable = false
			# Add the card to the leader slot
			leader_slot.add_card(selected_card)
			selected_card = null
		
		phases.PickSupport:
			helper_label.text = "Pick a Support from your hand"
			# Wait till the player selects a card
			waiting_for_card = true
			waiting_for_playable_card = true
			await card_selected
			# Hide + disable the card from being grabbed etc
			selected_card.flip()
			selected_card.undraggable = true
			(selected_card.card_data as DofCardStyleResource).playable = false
			# Add the card to the support slot
			support_slot.add_card(selected_card)
			selected_card = null
		
		phases.RevealSupport:
			helper_label.text = "Revealing Support cards!"
			var support_card = support_slot.get_card(0)
			# Flip the card in the support slot
			support_card.flip()
			
			# Perform the support ability
			(support_card.card_data as DofCardStyleResource).on_support_reveal()
			await resolution_completed
		
		phases.RevealLeader:
			helper_label.text = "Revealing Leader cards!"
			var leader_card = leader_slot.get_card(0)
			# Flip the card in the leader slot
			leader_card.flip()
			
			# Perform the support ability
			(leader_card.card_data as DofCardStyleResource).on_leader_reveal()
			await resolution_completed
		
		phases.Battle:
			# Grab the stats for the leader card (just ignoring 2nd player for now)
			var p1_leader_stats = leader_slot.get_card(0).card_data as DofCardStyleResource
			var p1_leader_strength = p1_leader_stats.strength
			var p2_leader_strength = 2
			
			helper_label.text = ("Combat:")
			await get_tree().create_timer(1).timeout
			helper_label.text = ("Combat:" + \
				"P1 Strength = " + str(p1_leader_strength) + "(+" + str(p1_combat_tokens) + ")")
			await get_tree().create_timer(1).timeout
			helper_label.text = ("Combat:" + \
				"P1 Strength = " + str(p1_leader_strength) + "(+" + str(p1_combat_tokens) + ")" + \
				"P2 Strength = " + str(p2_leader_strength) + "(+" + str(p2_combat_tokens) + ")")
			await get_tree().create_timer(1.5).timeout
			
			# Compare the strength of the leaders and score points accordingly
			var helpermsg = ""
			print("[DeckOfFate] BATTLE: My strength = ",p1_leader_strength,", opponent strength = ", p2_leader_strength)
			if p1_leader_strength + p1_combat_tokens > p2_leader_strength + p2_combat_tokens:
				print("[DeckOfFate] I WIN BATTLE! :D")
				helpermsg = "YOU WON! :D"
				add_points_p1(1)
				combat_result = CombatResult.win
				
			elif p1_leader_strength + p1_combat_tokens == p2_leader_strength + p2_combat_tokens:
				print("[DeckOfFate] BATTLE DRAW :O")
				helpermsg = "DRAW! :O"
				add_points_p1(1)
				add_points_p2(1)
				combat_result = CombatResult.draw
			else:
				print("[DeckOfFate] I LOSE BATTLE :(")
				helpermsg = "YOU LOST! D:"
				add_points_p2(1)
				combat_result = CombatResult.loss
			
			
			helper_label.text = ("Combat:" + \
			"P1 Strength = " + str(p1_leader_strength) + "(+" + str(p1_combat_tokens) + ")" + \
			"P2 Strength = " + str(p2_leader_strength) + "(+" + str(p2_combat_tokens) + ")" + \
			"... " + helpermsg)
			
			await get_tree().create_timer(1.5).timeout
			
			# Reset combat tokens
			p1_combat_tokens = 0
			p2_combat_tokens = 0
			
			# Perform Support after-combat effect
			if support_slot.get_card_count() > 0:
				helper_label.text = "Support after-combat effects..."
				(support_slot.get_card(0).card_data as DofCardStyleResource).on_combat_finished()
				await resolution_completed
			else:
				helper_label.text = "Support has vanished! Skipping after-combat effects..."
				await get_tree().create_timer(1).timeout
			
			# Perform Leader after-combat effect
			if leader_slot.get_card_count() > 0:
				helper_label.text = "Leader after-combat effects..."
				(leader_slot.get_card(0).card_data as DofCardStyleResource).on_combat_finished()
				await resolution_completed
			else:
				helper_label.text = "Leader has vanished! Skipping after-combat effects..."
				await get_tree().create_timer(1).timeout
		
		phases.BacklineLeader:
			# Make sure there is still a card in Leader slot
			if leader_slot.get_card_count() <= 0:
				helper_label.text = "No Leader in slot! Skipping backlining them..."
				await get_tree().create_timer(1).timeout
			# Make sure there are backline slots available for them
			elif !backline_slots_available:
				helper_label.text = "No backline slots available! Removing Leader from game..."
				remove_card_p1(leader_slot.get_card(0))
				await get_tree().create_timer(1).timeout
			else:
				helper_label.text = "Select a backline slot for your Leader"
				# Wait till the player selects a backline slot
				waiting_for_slot = true
				waiting_for_empty_slot = true
				await slot_selected
				# Add card to chosen backline slot
				if selected_slot.add_card(leader_slot.get_card(0)):
					(selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = selected_slot
					print("Current slot = ", (selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot)
				selected_slot = null
			
		
		phases.BacklineSupport:
			# Make sure there is still a card in Support slot
			if support_slot.get_card_count() <= 0:
				helper_label.text = "No Support in slot! Skipping backlining them..."
				await get_tree().create_timer(1).timeout
			# Make sure there are backline slots available for them
			elif !backline_slots_available:
				helper_label.text = "No backline slots available! Removing Support from game..."
				remove_card_p1(support_slot.get_card(0))
				await get_tree().create_timer(1).timeout
			else:
				helper_label.text = "Select a backline slot for your Support"
				# Wait till the player selects a backline slot
				waiting_for_slot = true
				waiting_for_empty_slot = true
				await slot_selected
				# Add card to chosen backline slot
				if selected_slot.add_card(support_slot.get_card(0)):
					(selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = selected_slot
					print("Current slot = ", (selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot)
				selected_slot = null
			
		phases.TurnEnd:
			if current_round == number_of_rounds:
				print("[DeckOfFate] TurnEnd - Reached end of game!")
				end_game()
				return
			print("[DeckOfFate] TurnEnd - Current round = ", current_round)
			helper_label.text = "Rounds remaining: " + str(3 - current_round)
	
	# Arrange cards
	arrange_decks()
	
	# Wait a second then repeat this whole function
	await get_tree().create_timer(1).timeout 
	_next_phase()
	

# This function is called when you click a card
# DoFDeckManager connects each card's "card_clicked" signal to this function
func select_card(card: Card) -> void:
	# Only if we are waiting for a card
	if waiting_for_card: 
		# Check to make sure this card is playable
		if waiting_for_playable_card:
			if !(card.card_data as DofCardStyleResource).playable:
				print("[DeckOfFate] Selected card '",card,"' is not playable, ignoring.")
				return
			waiting_for_playable_card = false
		print("[DeckOfFate] Selected card: ",card)
		#  Mark that we have selected this card
		waiting_for_card = false
		selected_card = card
		card_selected.emit()
	elif waiting_for_slot:
		print("[DeckOfFate] Selected card: ",card)
		# Make sure the card is in a slot to continue
		var chosen_slot = (card.card_data as DofCardStyleResource).current_slot
		print("[DeckOfFate] Checking if card has a slot... ")
		if chosen_slot == null:
			print("[DeckOfFate] Chosen card has no slot! Cancelling.")
			return
		# Select the chosen slot
		print("[DeckOfFate] Chosen card in slot '",chosen_slot,"', attempting to select it...")
		select_slot(chosen_slot)

# This function is called when you click a slot
# Our custom script "CardSlot" connects its signal to this function
func select_slot(slot: CardSlot) -> void:
	print("[DeckOfFate] Select slot.")
	# Cancel if we aren't waiting for a slot
	if !waiting_for_slot:
		print("[DeckOfFate] Not waiting for a slot right now, ignoring.")
		return
	if waiting_for_empty_slot: 
		# Check to make sure this slot hasn't already got a card
		if slot.is_full():
			print("[DeckOfFate] Waiting for an empty slot, but the selected slot '",slot,"' is full! Ignoring.")
			return
		waiting_for_empty_slot = false
	elif waiting_for_full_slot:
		# Check to make sure this slot already has a card
		if !slot.is_full():
			print("[DeckOfFate] Waiting for a full slot, but the selected slot '",slot,"' is empty! Ignoring.")
			return
		waiting_for_full_slot = false
	# Tell the next_phase() loop we have selected this slot
	waiting_for_slot = false
	selected_slot = slot
	slot_selected.emit()
	


static func complete_resolution() -> void:
	print("[DeckOfFate] Resolution complete! Returning to next_phase() loop...")
	instance.resolution_completed.emit()




func deal():
	# Draw 4 cards on the first draw, otherwise draw 2
	var number_of_cards_to_draw = 2
	if !first_draw_completed:
		number_of_cards_to_draw = 4
		first_draw_completed = true
	draw_cards_p1(number_of_cards_to_draw)

func arrange_decks() -> void:
	await get_tree().create_timer(0.25).timeout 
	leader_slot._arrange_cards()
	support_slot._arrange_cards()
	for slot in victory_slots:
		slot._arrange_cards()

func end_game() -> void:
	
	print("[DeckOfFate] Ending game! Checking victory slots...")
	
	helper_label.text = "GAME OVER"
	
	for victory_slot in victory_slots:
		if victory_slot.get_card_count() == 0:
			print("[DeckOfFate] No card in slot: '", victory_slot.name, "', skipping...")
			continue
		print("[DeckOfFate] Checking victory slot: '", victory_slot.name, "'...")
		# Save reference to card in this victory slot
		var my_card = victory_slot.get_card(0).card_data as DofCardStyleResource
		var has_adjacency = false
		if victory_slot.adjacent_left != null && victory_slot.adjacent_left.get_card_count() > 0:
			var left_card = victory_slot.adjacent_left.get_card(0).card_data as DofCardStyleResource
			print("[DeckOfFate] Left adjacent slot = '", victory_slot.adjacent_left, "' holding card '",left_card.card_name)
			if my_card.calculate_adjacency(left_card):
				has_adjacency = true
		if !has_adjacency && victory_slot.adjacent_right != null && victory_slot.adjacent_right.get_card_count() > 0:
			var right_card = victory_slot.adjacent_right.get_card(0).card_data as DofCardStyleResource
			print("[DeckOfFate] Right adjacent slot = '", victory_slot.adjacent_right, "' holding card '",right_card.card_name)
			if my_card.calculate_adjacency(right_card):
				has_adjacency = true
		if has_adjacency:
			add_points_p1(1)
	
	# Go through victory slots in order
	#for victory_slot in victory_slots:
		#print("[DeckOfFate] Checking victory slot: '", victory_slot.name, "'...")
		## Save reference to card in this victory slot
		#var my_card = victory_slot.get_card(0).card_data as DofCardStyleResource
		## Check if this slot has an adjacent slot
		#if victory_slot.adjacent_left != null:
			## Save reference to card in that adjacent slot
			#var adjacent_card = victory_slot.adjacent_left.get_card(0).card_data as DofCardStyleResource
			## Go through conditions listed on the card in this victory slot in order
			#for condition in my_card.adjacencies.keys():
				## If its looking for the card's name...
				#if (condition as DofCardStyleResource.AdjacencyTarget) == DofCardStyleResource.AdjacencyTarget.CardName:
					## Add a point if the card in the adjacent slot has the same name as this condition
					#if adjacent_card.card_name == my_card.adjacencies[condition]:
						#print("[DeckOfFate] Adding 1 point from matching name: '", adjacent_card.card_name, "'!")
						#add_p1_points(1)
				## If its looking for the card's type...
				#elif (condition as DofCardStyleResource.AdjacencyTarget) == DofCardStyleResource.AdjacencyTarget.CardType:
					## Add a point if the card in the adjacent slot has the same type as this condition
					#if adjacent_card.card_type == my_card.adjacencies[condition]:
						#print("[DeckOfFate] Adding 1 point from matching type: '", adjacent_card.card_type, "'!")
						#add_p1_points(1)
		#if victory_slot.adjacent_right != null:
			## Save reference to card in that adjacent slot
			#var adjacent_card = victory_slot.adjacent_right.get_card(0).card_data as DofCardStyleResource
			## Go through conditions listed on the card in this victory slot in order
			#for condition in my_card.adjacencies.keys():
				## If its looking for the card's name...
				#if (condition as DofCardStyleResource.AdjacencyTarget) == DofCardStyleResource.AdjacencyTarget.CardName:
					## Add a point if the card in the adjacent slot has the same name as this condition
					#if adjacent_card.card_name == my_card.adjacencies[condition]:
						#print("[DeckOfFate] Adding 1 point from matching name: '", adjacent_card.card_name, "'!")
						#add_p1_points(1)
				## If its looking for the card's type...
				#elif (condition as DofCardStyleResource.AdjacencyTarget) == DofCardStyleResource.AdjacencyTarget.CardType:
					## Add a point if the card in the adjacent slot has the same type as this condition
					#if adjacent_card.card_type == my_card.adjacencies[condition]:
						#print("[DeckOfFate] Adding 1 point from matching type: '", adjacent_card.card_type, "'!")
						#add_p1_points(1)
	
	
	# go through victory slots in order L > R
		#if left_adjacency victory condition || if right_adjacency victory condition:
			# add 1pt
	
	pass





#region Points functions

static func add_points_p1(amount:int):
	print("[DeckOfFate] Add points to p1 score:", amount)
	instance.p1_score += amount
	# Update the label to match the current scores
	instance.p1_score_label.text = str(instance.p1_score)

static func add_points_p2(amount:int):
	print("[DeckOfFate] Add points to p2 score:", amount)
	instance.p2_score += amount
	# Update the label to match the current scores
	instance.p2_score_label.text = str(instance.p2_score)

static func reset_points():
	print("[DeckOfFate] Resetting point scores.")
	instance.p1_score = 0
	instance.p2_score = 0
	# Update the label to match the current scores
	instance.p1_score_label.text = str(instance.p1_score)
	instance.p2_score_label.text = str(instance.p2_score)

#endregion

#region Card functions

static func draw_cards_p1(amount:int):
	print("[DeckOfFate] Draw cards to p1 hand:", amount)
	
	# Move the cards from the draw deck to the players hand
	var drawn_cards = instance.dof_deck_manager.draw_cards(amount)
	instance.player_hand.add_cards(drawn_cards)
	
	# Flip the cards so they are revealed in hand
	for drawn_card in drawn_cards: drawn_card.flip()

static func draw_cards_p2(amount:int):
	print("[DeckOfFate] Draw cards to p2 hand:", amount, " (NOTE -> not implemented, does nothing!)")
	
	## Move the cards from the draw deck to the players hand
	#var drawn_cards = instance.dof_deck_manager.draw_cards(amount)
	#instance.player_hand.add_cards(drawn_cards)
	#
	## Flip the cards so they are revealed in hand
	#for card in drawn_cards:
	#card.flip()

static func return_to_hand_p1(card:Card):
	print("[DeckOfFate] Return p1 '",card.name,"' to hand")
	instance.player_hand.add_card(card)

static func return_to_hand_p2(card:Card):
	print("[DeckOfFate] Return p2 '",card.name,"' to hand (NOTE -> not implemented, does nothing!)")

static func shuffle_hand_p1():
	print("[DeckOfFate] Shuffle p1 hand into deck")
	
	# Flip the cards so they are hidden in hand
	var hand_cards = instance.player_hand.cards
	for card in hand_cards:
		card.flip()
	
	# Move the cards from the players hand to the draw deck
	instance.dof_deck_manager.add_cards_to_draw_pile(hand_cards)
	instance.dof_deck_manager.shuffle()

static func shuffle_hand_p2():
	print("[DeckOfFate] Shuffle p2 hand into deck (NOTE -> not implemented, does nothing!)")
	
	## Flip the cards so they are hidden in hand
	#var hand_cards = instance.player_hand.cards
	#for card in hand_cards:
		#card.flip()
	#
	### Move the cards from the players hand to the draw deck
	#instance.dof_deck_manager.add_cards_to_draw_pile(hand_cards)
	#instance.dof_deck_manager.shuffle()

static func remove_card_p1(card:Card):
	print("[DeckOfFate] Remove p1 card '",card.name,"'")

	# Move the card to the discard pile
	instance.dof_deck_manager.add_card_to_discard_pile(card)

static func remove_card_p2(card:Card):
	print("[DeckOfFate] Remove p2 card '",card.name,"' (NOTE -> not implemented, does nothing!)")

	## Move the card to the discard pile
	#instance.dof_deck_manager.add_card_to_discard_pile(card)

static func backline_hand_card_p1():
	if !instance.backline_slots_available:
		instance.helper_label.text = "No backline slots available! Cancelling effect..."
		await instance.get_tree().create_timer(1).timeout
		instance.resolution_step.emit()
		return
	print("[DeckOfFate] Backline p1 hand card...")
	instance.helper_label.text = "Pick a card from your hand"
	# Wait till the player selects a card
	instance.waiting_for_card = true
	instance.waiting_for_playable_card = true
	await instance.card_selected
	# Disable the card from being grabbed etc
	instance.selected_card.undraggable = true
	(instance.selected_card.card_data as DofCardStyleResource).playable = false
	
	instance.helper_label.text = "Select a backline slot for your card"
	# Wait till the player selects a backline slot
	instance.waiting_for_slot = true
	instance.waiting_for_empty_slot = true
	await instance.slot_selected
	# Add card to chosen backline slot
	if instance.selected_slot.add_card(instance.selected_card):
		(instance.selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = instance.selected_slot
	
	instance.selected_card = null
	instance.selected_slot = null
	instance.resolution_step.emit()

static func backline_hand_card_p2():
	print("[DeckOfFate] Backline p2 hand card (NOTE -> not implemented, does nothing!)")

#endregion


#region Combat token functions

static func add_combat_strength_p1(amount:int):
	print("[DeckOfFate] Add strength tokens to p1 leader:", amount)
	instance.p1_combat_tokens += amount

static func add_combat_strength_p2(amount:int):
	print("[DeckOfFate] Add strength tokens to p2 leader:", amount)
	instance.p2_combat_tokens += amount

static func clear_combat_strength_p1():
	print("[DeckOfFate] Clear all strength tokens from p1 leader")
	instance.p1_combat_tokens = 0

static func clear_combat_strength_p2():
	print("[DeckOfFate] Clear all strength tokens from p2 leader")
	instance.p2_combat_tokens = 0

#endregion

#region Switch functions

### Need to work out if this happens just before combat instead
func swap_p1_leader_and_support():
	print("[DeckOfFate] Swap p1 leader and support cards...")
	helper_label.text = ("Swapping cards...")
	var leader_card = leader_slot.get_card(0)
	var support_card = support_slot.get_card(0)
	leader_slot.clear_hand()
	support_slot.clear_hand()
	leader_slot.add_card(support_card)
	support_slot.add_card(leader_card)
	
func swap_p1_backline_slots():
	print("[DeckOfFate] Swap two p1 backline slots...")
	var slot1 : CardSlot = null
	var slot2 : CardSlot = null
	# Let the player choose the first backline slot
	helper_label.text = ("Choose 1st slot to swap")
	while slot1 == null:
		waiting_for_slot = true
		await slot_selected
		slot1 = selected_slot
		selected_slot = null
		print("[DeckOfFate] Slot1 = ", slot1)
	# Let the player choose the second backline slot
	helper_label.text = ("Choose 2nd slot to swap")
	while slot2 == null:
		waiting_for_slot = true
		await slot_selected
		slot2 = selected_slot if selected_slot != slot1 else null
		selected_slot = null
		print("[DeckOfFate] Slot2 = ", slot2)
	# Swap cards between slots	
	helper_label.text = ("Swapping cards...")
	print("[DeckOfFate] Slot1 card = ", slot1.get_card(0))
	if slot1.get_card(0) != null:
		slot2.add_card(slot1.get_card(0))
	print("[DeckOfFate] Slot2 card = ", slot2.get_card(0))
	if slot2.get_card(0) != null:
		slot1.add_card(slot2.get_card(0))
	resolution_step.emit()


func swap_p2_backline_slots():
	print("[DeckOfFate] Swap 2 p1 backline cards... (not implemented, does nothing for now)...")
	helper_label.text = ("Swap 2 p1 backline cards... (not implemented, does nothing for now)")


#endregion


#region Getters

static func get_hand_size_p1() -> int:
	return instance.player_hand.get_card_count()
	
static func get_hand_size_p2() -> int:
	print("[DeckOfFate] Return p2 hand size! (not implemented, returns -1 for now)...")
	return -1

static func get_combat_result() -> CombatResult:
	print("[DeckOfFate] Return combat result! Returning '",instance.combat_result,"'...")
	return instance.combat_result

static func get_leader_p1() -> Card:
	print("[DeckOfFate] Return p1 leader card! Returning '",instance.leader_slot.get_card(0),"'...")
	return instance.leader_slot.get_card(0)

static func get_leader_p2() -> Card:
	print("[DeckOfFate] Return p2 leader card! (not implemented, returns null for now)...")
	return null

static func get_support_p1() -> Card:
	print("[DeckOfFate] Return p1 support card! Returning '",instance.support_slot.get_card(0),"'...")
	return instance.support_slot.get_card(0)

static func get_support_p2() -> Card:
	print("[DeckOfFate] Return p2 support card! (not implemented, returns null for now)...")
	return null

static func get_leader_type_p1() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetLeaderType from p1! Returning '",(instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_leader_type_p2() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetLeaderType from p2 (not implemented, always returns Warrior for now)...")
	return DofCardStyleResource.CardType.Warrior
	#return (instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_support_type_p1() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetSupportType from p1! Returning '",(instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_support_type_p2() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetSupportType from p2 (always returns Warrior for now)...")
	return DofCardStyleResource.CardType.Warrior
	#return (instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type

#endregion


#region Tweens + Animations

##Tween the phase label
var _visibility_tween
func tween_visibility(canvas_item:CanvasItem, desired_visibility: Color = Color.WHITE, duration: float = 0.5, ease_type:Tween.EaseType=Tween.EASE_OUT,trans_type:Tween.TransitionType=Tween.TRANS_LINEAR) -> void:
	# If we're already tweening, kill it and start again
	if _visibility_tween:
		_visibility_tween.kill()
	# Tween the transparency of whatever we're targetting 
	_visibility_tween = create_tween().set_ease(ease_type).set_trans(trans_type)
	_visibility_tween.tween_property(canvas_item, "modulate", desired_visibility, duration)

#endregion
