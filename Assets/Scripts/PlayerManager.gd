class_name PlayerManager extends Node
#Manages all deck functions etc for a player

@export_category("REFERENCES")
@onready var deck_manager: DoFDeckManager = $DeckManager
@onready var leader_slot: CardHand = $LeaderSlot
@onready var support_slot: CardHand = $SupportSlot
@onready var player_hand: CardHand = $Hand
@export var victory_slots: Array[CardSlot] # set by hand in inspector

@export_category("READ ONLY")
@export var combat_tokens : int = 0
@export var waiting_for_card : bool = false
@export var waiting_for_playable_card : bool = false
@export var waiting_for_slot : bool = false
@export var waiting_for_empty_slot : bool = false
@export var waiting_for_full_slot : bool = false
@export var waiting_for_resolution : bool = false
@export var selected_card : Card = null
@export var selected_slot : CardSlot = null

signal card_selected
signal slot_selected
signal resolution_completed
signal resolution_step

var hand_size: int

var backline_slots_available:bool:
	get:
		print("[PlayerManager(",name,")] Backline_slots_available getter...")
		for slot in victory_slots:
			print("[PlayerManager(",name,")] Slot '",slot,"' is ","full, continuing..." if slot.is_hand_full() else "empty, good to go!")
			if !slot.is_hand_full():
				return true
		return false

var backline_empty:bool:
	get:
		print("[PlayerManager(",name,")] Backline_empty getter...")
		for slot in victory_slots:
			print("[PlayerManager(",name,")] Slot '",slot,"' is ","empty, continuing..." if !slot.is_hand_full() else "full, cancelling.")
			if slot.is_hand_full():
				return false
		return true



func _init() -> void:
	pass

func _ready() -> void:
	for victory_slot in victory_slots:
		victory_slot.player_manager = self
		victory_slot.initialise_slot()



func complete_resolution() -> void:
	print("[PlayerManager(",name,")] Resolution complete! Returning to next_phase() loop...")
	resolution_completed.emit()


#region Phase functions

func pick_leader() -> void:
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
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func pick_support() -> void:
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
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func reveal_support() -> void:
	# Flip the card in the support slot
	var support_card = support_slot.get_card(0)
	support_card.flip()
	
	# Perform the support ability
	get_support_data().on_support_reveal()
	await resolution_completed
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func reveal_leader() -> void:
	# Flip the card in the leader slot
	var leader_card = leader_slot.get_card(0)
	leader_card.flip()
	
	# Perform the leader ability
	get_leader_data().on_leader_reveal()
	await resolution_completed
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func post_combat_support() -> void:
	get_support_data().on_combat_finished()
	await resolution_completed
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func post_combat_leader() -> void:
	get_leader_data().on_combat_finished()
	await resolution_completed
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func backline_leader() -> void:
	# Make sure there is still a card in Leader slot
	if leader_slot.get_card_count() <= 0:
		# NOTE > This needs to be told to the players
		#helper_label.text = "No Leader in slot! Skipping backlining them..."
		await get_tree().create_timer(1).timeout
	# Make sure there are backline slots available for them
	elif !backline_slots_available:		
		# NOTE > This needs to be told to the players
		#helper_label.text = "No backline slots available! Removing Leader from game..."
		remove_card(leader_slot.get_card(0))
		await get_tree().create_timer(1).timeout
	else:
		# Wait till the player selects a backline slot
		waiting_for_slot = true
		waiting_for_empty_slot = true
		await slot_selected
		# Add card to chosen backline slot
		if selected_slot.add_card(leader_slot.get_card(0)):
			(selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = selected_slot
			print("Current slot = ", (selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot)
		selected_slot = null
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

func backline_support() ->void:
	# Make sure there is still a card in Support slot
	if support_slot.get_card_count() <= 0:
		# NOTE > This needs to be told to the players
		#helper_label.text = "No Support in slot! Skipping backlining them..."
		await get_tree().create_timer(1).timeout
	# Make sure there are backline slots available for them
	elif !backline_slots_available:
				# NOTE > This needs to be told to the players
		#helper_label.text = "No backline slots available! Removing Support from game..."
		remove_card(support_slot.get_card(0))
		await get_tree().create_timer(1).timeout
	else:
		# Wait till the player selects a backline slot
		waiting_for_slot = true
		waiting_for_empty_slot = true
		await slot_selected
		# Add card to chosen backline slot
		if selected_slot.add_card(support_slot.get_card(0)):
			(selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = selected_slot
			print("Current slot = ", (selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot)
		selected_slot = null
	
	# Tell DeckOfFate we are ready to continue
	DeckOfFate.player_ready(self)

#endregion





# This function is called when you click a card
# DoFDeckManager connects each card's "card_clicked" signal to this function
func select_card(card: Card) -> void:
	# Only if we are waiting for a card
	if waiting_for_card: 
		# Check to make sure this card is playable
		if waiting_for_playable_card:
			if !(card.card_data as DofCardStyleResource).playable:
				print("[PlayerManager(",name,")] Selected card '",card,"' is not playable, ignoring.")
				return
			waiting_for_playable_card = false
		print("[PlayerManager(",name,")] Selected card: ",card)
		#  Mark that we have selected this card
		waiting_for_card = false
		selected_card = card
		card_selected.emit()
	elif waiting_for_slot:
		print("[PlayerManager(",name,")] Selected card: ",card)
		# Make sure the card is in a slot to continue
		var chosen_slot = (card.card_data as DofCardStyleResource).current_slot
		print("[PlayerManager(",name,")] Checking if card has a slot... ")
		if chosen_slot == null:
			print("[PlayerManager(",name,")] Chosen card has no slot! Cancelling.")
			return
		# Select the chosen slot
		print("[PlayerManager(",name,")] Chosen card in slot '",chosen_slot,"', attempting to select it...")
		select_slot(chosen_slot)

# This function is called when you click a slot
# Our custom script "CardSlot" connects its signal to this function
func select_slot(slot: CardSlot) -> void:
	print("[PlayerManager(",name,")] Select slot.")
	# Cancel if we aren't waiting for a slot
	if !waiting_for_slot:
		print("[PlayerManager(",name,")] Not waiting for a slot right now, ignoring.")
		return
	if waiting_for_empty_slot: 
		# Check to make sure this slot hasn't already got a card
		if slot.is_full():
			print("[PlayerManager(",name,")] Waiting for an empty slot, but the selected slot '",slot,"' is full! Ignoring.")
			return
		print("[PlayerManager(",name,")] Chosen slot '",slot,"' is empty! Selecting slot...")
		waiting_for_empty_slot = false
	elif waiting_for_full_slot:
		# Check to make sure this slot already has a card
		if !slot.is_full():
			print("[PlayerManager(",name,")] Waiting for a full slot, but the selected slot '",slot,"' is empty! Ignoring.")
			return
		print("[PlayerManager(",name,")] Chosen slot '",slot,"' is full! Selecting slot...")
		waiting_for_full_slot = false
	# Tell the next_phase() loop we have selected this slot
	waiting_for_slot = false
	selected_slot = slot
	slot_selected.emit()




func deal(first_turn:bool):
	# Draw 4 cards on the first draw, otherwise draw 2
	if first_turn: draw_cards(4)
	else: draw_cards(2)

func arrange_decks() -> void:
	await get_tree().create_timer(0.25).timeout 
	leader_slot._arrange_cards()
	support_slot._arrange_cards()
	for slot in victory_slots:
		slot._arrange_cards()

func end_game() -> void:
	
	print("[PlayerManager(",name,")] Ending game! Checking victory slots...")
		
	for victory_slot in victory_slots:
		if victory_slot.get_card_count() == 0:
			print("[PlayerManager(",name,")] No card in slot: '", victory_slot.name, "', skipping...")
			continue
		print("[PlayerManager(",name,")] Checking victory slot: '", victory_slot.name, "'...")
		# Save reference to card in this victory slot
		var my_card = victory_slot.get_card(0).card_data as DofCardStyleResource
		var has_adjacency = false
		if victory_slot.adjacent_left != null && victory_slot.adjacent_left.get_card_count() > 0:
			var left_card = victory_slot.adjacent_left.get_card(0).card_data as DofCardStyleResource
			print("[PlayerManager(",name,")] Left adjacent slot = '", victory_slot.adjacent_left, "' holding card '",left_card.card_name)
			if my_card.calculate_adjacency(left_card):
				has_adjacency = true
		if !has_adjacency && victory_slot.adjacent_right != null && victory_slot.adjacent_right.get_card_count() > 0:
			var right_card = victory_slot.adjacent_right.get_card(0).card_data as DofCardStyleResource
			print("[PlayerManager(",name,")] Right adjacent slot = '", victory_slot.adjacent_right, "' holding card '",right_card.card_name)
			if my_card.calculate_adjacency(right_card):
				has_adjacency = true
		if has_adjacency:
			DeckOfFate.add_points(self,1)
	





#region Card functions

func draw_cards(amount:int):
	print("[PlayerManager(",name,")] Draw cards to hand:", amount)
	
	# Move the cards from the draw deck to the players hand
	var drawn_cards = deck_manager.draw_cards(amount)
	player_hand.add_cards(drawn_cards)
	
	# Flip the cards so they are revealed in hand
	for drawn_card in drawn_cards: drawn_card.flip()

func return_to_hand(card:Card):
	print("[PlayerManager(",name,")] Return '",card.name,"' to hand")
	player_hand.add_card(card)

func shuffle_hand():
	print("[PlayerManager(",name,")] Shuffle hand into deck")
	
	# Flip the cards so they are hidden in hand
	var hand_cards = player_hand.cards
	for card in hand_cards:
		card.flip()
	
	# Move the cards from the players hand to the draw deck
	deck_manager.add_cards_to_draw_pile(hand_cards)
	deck_manager.shuffle()

func remove_card(card:Card):
	print("[PlayerManager(",name,")] Remove card '",card.name,"'")

	# Move the card to the discard pile
	deck_manager.add_card_to_discard_pile(card)


#endregion


#region Combat token functions

func add_combat_strength(amount:int):
	print("[PlayerManager(",name,")] Add strength tokens to leader:", amount)
	combat_tokens += amount

func clear_combat_strength():
	print("[PlayerManager(",name,")] Clear all strength tokens from leader")
	combat_tokens = 0

#endregion


#region Switch functions

### Need to work out if this happens just before combat instead
func swap_leader_and_support():
	print("[PlayerManager(",name,")] Swap leader and support cards...")
	DeckOfFate.set_helper_message("Swapping cards...")
	
	var leader_card = leader_slot.get_card(0)
	var support_card = support_slot.get_card(0)
	leader_slot.clear_hand()
	support_slot.clear_hand()
	leader_slot.add_card(support_card)
	support_slot.add_card(leader_card)
	
func swap_backline_slots():
	print("[PlayerManager(",name,")] Swap two backline slots...")
	DeckOfFate.set_helper_message("Choose 1st slot to swap")
	
	var slot1 : CardSlot = null
	var slot2 : CardSlot = null
	
	# Let the player choose the first backline slot
	while slot1 == null:
		waiting_for_slot = true
		await slot_selected
		slot1 = selected_slot
		selected_slot = null
		print("[PlayerManager(",name,")] Slot1 = ", slot1)
	
	# Let the player choose the second backline slot
	DeckOfFate.set_helper_message("Choose 2nd slot to swap")
	while slot2 == null:
		waiting_for_slot = true
		await slot_selected
		slot2 = selected_slot if selected_slot != slot1 else null
		selected_slot = null
		print("[PlayerManager(",name,")] Slot2 = ", slot2)
		
	# Swap cards between slots
	DeckOfFate.set_helper_message("Swapping cards...")
	print("[PlayerManager(",name,")] Slot1 card = ", slot1.get_card(0))
	if slot1.get_card(0) != null:
		slot2.add_card(slot1.get_card(0))
	print("[PlayerManager(",name,")] Slot2 card = ", slot2.get_card(0))
	if slot2.get_card(0) != null:
		slot1.add_card(slot2.get_card(0))
	resolution_step.emit()


func backline_hand_card():
	if !backline_slots_available:
		DeckOfFate.set_helper_message("No backline slots available! Cancelling effect.")
		await get_tree().create_timer(1).timeout
		resolution_step.emit()
		return
	print("[PlayerManager(",name,")] Backline hand card...")
	DeckOfFate.set_helper_message("Pick a card from your hand")
	# Wait till the player selects a card
	waiting_for_card = true
	waiting_for_playable_card = true
	await card_selected
	# Disable the card from being grabbed etc
	selected_card.undraggable = true
	(selected_card.card_data as DofCardStyleResource).playable = false
	
	DeckOfFate.set_helper_message("Select a backline slot for your card")
	# Wait till the player selects a backline slot
	waiting_for_slot = true
	waiting_for_empty_slot = true
	await slot_selected
	# Add card to chosen backline slot
	if selected_slot.add_card(selected_card):
		(selected_slot.get_card(0).card_data as DofCardStyleResource).current_slot = selected_slot
	
	selected_card = null
	selected_slot = null
	resolution_step.emit()


func remove_backline_card():
	if backline_empty:
		DeckOfFate.set_helper_message("No cards in backline! Cancelling effect.")
		await get_tree().create_timer(1).timeout
		resolution_step.emit()
		return
	print("[PlayerManager(",name,")] Remove backline card...")
	DeckOfFate.set_helper_message("Select a backline card to remove")
	# Wait till the player selects a full backline slot
	waiting_for_slot = true
	waiting_for_full_slot = true
	await slot_selected
	# Remove the card from the game
	remove_card(selected_slot.get_card(0))
		
	selected_slot = null
	resolution_step.emit()

#endregion


#region Getters

func get_hand_size() -> int:
	return player_hand.get_card_count()

func get_combat_result() -> DeckOfFate.CombatResult:
	print("[PlayerManager(",name,")] Get combat result! Returning '",DeckOfFate.last_combat_result,"'...")
	return DeckOfFate.last_combat_result

func get_leader() -> Card:
	if !leader_slot.is_hand_full():
		print("[PlayerManager(",name,")] No leader card! Returning null...")
		return null
	print("[PlayerManager(",name,")] Get leader card! Returning '",leader_slot.get_card(0),"'...")
	return leader_slot.get_card(0)

func get_support() -> Card:
	if !support_slot.is_hand_full():
		print("[PlayerManager(",name,")] No support card! Returning null...")
		return null
	print("[PlayerManager(",name,")] Get support card! Returning '",support_slot.get_card(0),"'...")
	return support_slot.get_card(0)


func get_leader_data() -> DofCardStyleResource:
	if !leader_slot.is_hand_full():
		print("[PlayerManager(",name,")] No leader card! Returning null data...")
		return null
	print("[PlayerManager(",name,")] Get leader card data! Returning data of '",leader_slot.get_card(0),"'...")
	return leader_slot.get_card(0).card_data

func get_support_data() -> DofCardStyleResource:
	if !support_slot.is_hand_full():
		print("[PlayerManager(",name,")] No support card! Returning null data...")
		return null
	print("[PlayerManager(",name,")] Get support card data! Returning data of '",support_slot.get_card(0),"'...")
	return support_slot.get_card(0).card_data


func get_leader_type() -> DofCardStyleResource.CardType:
	if !leader_slot.is_hand_full():
		print("[PlayerManager(",name,")] No leader card! Returning NULL type...")
		return DofCardStyleResource.CardType.NULL
	print("[PlayerManager(",name,")] Get leader card type! Returning '",(leader_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (leader_slot.get_card(0).card_data as DofCardStyleResource).card_type

func get_support_type() -> DofCardStyleResource.CardType:
	if !support_slot.is_hand_full():
		print("[PlayerManager(",name,")] No support card! Returning NULL type...")
		return DofCardStyleResource.CardType.NULL
	print("[PlayerManager(",name,")] Get support card type! Returning '",(support_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (support_slot.get_card(0).card_data as DofCardStyleResource).card_type

#endregion
