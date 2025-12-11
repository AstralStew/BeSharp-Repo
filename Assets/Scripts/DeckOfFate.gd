class_name DeckOfFate extends CanvasLayer
#Runs the game

@export_category("REFERENCES")
static var instance:DeckOfFate = null
@onready var dof_deck_manager: DoFDeckManager = $DoFDeckManager
@onready var player_hand: CardHand = $PlayerHand
@onready var leader_slot: CardHand = $LeaderSlot
@onready var support_slot: CardHand = $SupportSlot
@onready var phase_label: RichTextLabel = $PhaseLabel
@onready var p1_score_label: RichTextLabel = $P1ScoreDesc_VB/P1Score_RTL
@onready var p2_score_label: RichTextLabel = $P2ScoreDesc_VB/P2Score_RTL
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
@export var waiting_for_slot : bool = false
@export var selected_card : Card = null
@export var selected_slot : CardSlot = null

enum phases {TurnStart, PickLeader, PickSupport, RevealSupport, RevealLeader, Battle, BacklineLeader, BacklineSupport, TurnEnd}

signal card_selected
signal slot_selected

var hand_size: int

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
		
		# Deal 2 cards (or 4 on the first turn)
		phases.TurnStart:
			current_round += 1
			print("[DeckOfFate] TurnStart - Current round set to ", current_round)
			deal()
		
		phases.PickLeader:
			# Wait till the player selects a card
			waiting_for_card = true
			await card_selected
			# Hide + disable the card from being grabbed etc
			selected_card.flip()
			selected_card.undraggable = true
			selected_card.disabled = true
			# Add the card to the leader slot
			leader_slot.add_card(selected_card)
			selected_card = null
		
		phases.PickSupport:
			# Wait till the player selects a card
			waiting_for_card = true
			await card_selected
			# Hide + disable the card from being grabbed etc
			selected_card.flip()
			selected_card.undraggable = true
			selected_card.disabled = true
			# Add the card to the support slot
			support_slot.add_card(selected_card)
			selected_card = null
		
		phases.RevealSupport:
			var support_card = support_slot.get_card(0)
			# Flip the card in the support slot
			support_card.flip()
			
			# Perform the support ability
			(support_card.card_data as DofCardStyleResource).on_support_reveal()
		
		phases.RevealLeader:
			
			var leader_card = leader_slot.get_card(0)
			# Flip the card in the leader slot
			leader_card.flip()
			
			# Perform the support ability
			(leader_card.card_data as DofCardStyleResource).on_leader_reveal()
			
			
			
		
		phases.Battle:
			# Grab the stats for the leader card (just ignoring 2nd player for now)
			var p1_leader_stats = leader_slot.get_card(0).card_data as DofCardStyleResource
			var p1_leader_strength = p1_leader_stats.strength
			var p2_leader_strength = 2
			
			# Compare the strength of the leaders and score points accordingly
			print("[DeckOfFate] BATTLE: My strength = ",p1_leader_strength,", opponent strength = ", p2_leader_strength)
			if p1_leader_strength > p2_leader_strength:
				print("[DeckOfFate] I WIN BATTLE! :D")
				add_p1_points(1)
			elif p1_leader_strength == p2_leader_strength:
				print("[DeckOfFate] BATTLE DRAW :O")
				add_p1_points(1)
				add_p2_points(1)
			else:
				print("[DeckOfFate] I LOSE BATTLE :(")
				add_p2_points(1)
			
			# Perform after-combat effects
			(support_slot.get_card(0).card_data as DofCardStyleResource).on_support_reveal()
			await get_tree().create_timer(1).timeout #Should be a callback
			(leader_slot.get_card(0).card_data as DofCardStyleResource).on_leader_reveal()
			await get_tree().create_timer(1).timeout #Should be a callback
			
		
		phases.BacklineLeader:
			# Wait till the player selects a backline slot
			waiting_for_slot = true
			await slot_selected
			# Add card to chosen backline slot
			selected_slot.add_card(leader_slot.get_card(0))
			selected_slot = null
		
		phases.BacklineSupport:
			# Wait till the player selects a backline slot
			waiting_for_slot = true
			await slot_selected
			# Add card to chosen backline slot
			selected_slot.add_card(support_slot.get_card(0))
			selected_slot = null
		
		phases.TurnEnd:
			if current_round == number_of_rounds:
				print("[DeckOfFate] TurnEnd - Reached end of game!")
				end_game()
				return
			print("[DeckOfFate] TurnEnd - Current round = ", current_round)
	
	# Arrange cards
	arrange_decks()
	
	# Wait a second then repeat this whole function
	await get_tree().create_timer(1).timeout 
	_next_phase()
	

# This function is called when you click a card
# DoFDeckManager connects each card's "card_clicked" signal to this function
func select_card(card: Card) -> void:
	# Cancel if we aren't waiting for a card
	if !waiting_for_card: return
	print("[DeckOfFate] Selected card: ",card)
	# Tell the next_phase() loop we have selected this card
	waiting_for_card = false
	selected_card = card
	card_selected.emit()

# This function is called when you click a slot
# Our custom script "CardSlot" connects its signal to this function
func select_slot(slot: CardSlot) -> void:
	# Cancel if we aren't waiting for a slot
	if !waiting_for_slot: return
	print("[DeckOfFate] Selected slot: ",slot)
	# Tell the next_phase() loop we have selected this card
	waiting_for_slot = false
	selected_slot = slot
	slot_selected.emit()


func deal():
	# Draw 4 cards on the first draw, otherwise draw 2
	var number_of_cards_to_draw = 2
	if !first_draw_completed:
		number_of_cards_to_draw = 4
		first_draw_completed = true
	
	# Move the cards from the draw deck to the players hand
	var drawn_cards = dof_deck_manager.draw_cards(number_of_cards_to_draw)
	player_hand.add_cards(drawn_cards)
	
	# Flip the cards so they are revealed in hand
	for card in drawn_cards:
		card.flip()

func arrange_decks() -> void:
	await get_tree().create_timer(0.25).timeout 
	leader_slot._arrange_cards()
	support_slot._arrange_cards()
	for slot in victory_slots:
		slot._arrange_cards()

func end_game() -> void:
	
	print("[DeckOfFate] Ending game! Checking victory slots...")
		
	for victory_slot in victory_slots:
		var has_adjacency = false
		print("[DeckOfFate] Checking victory slot: '", victory_slot.name, "'...")
		# Save reference to card in this victory slot
		var my_card = victory_slot.get_card(0).card_data as DofCardStyleResource
		if victory_slot.adjacent_left != null:
			var left_card = victory_slot.adjacent_left.get_card(0).card_data as DofCardStyleResource
			print("[DeckOfFate] Left adjacent slot = '", victory_slot.adjacent_left, "' holding card '",left_card.card_name)
			if my_card.calculate_adjacency(left_card):
				has_adjacency = true
		if !has_adjacency && victory_slot.adjacent_right != null:
			var right_card = victory_slot.adjacent_right.get_card(0).card_data as DofCardStyleResource
			print("[DeckOfFate] Right adjacent slot = '", victory_slot.adjacent_right, "' holding card '",right_card.card_name)
			if my_card.calculate_adjacency(right_card):
				has_adjacency = true
		if has_adjacency:
			add_p1_points(1)
	
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



func add_p1_points(amount:int):
	print("[DeckOfFate] Add points to player 1 score:", amount)
	p1_score += amount
	# Update the label to match the current scores
	p1_score_label.text = str(p1_score)

func add_p2_points(amount:int):
	print("[DeckOfFate] Add points to player 2 score:", amount)
	p2_score += amount
	# Update the label to match the current scores
	p2_score_label.text = str(p2_score)



static func draw_cards_p1(amount:int):
	print("[DeckOfFate] Draw cards to p1 hand:", amount)

static func draw_cards_p2(amount:int):
	print("[DeckOfFate] Draw cards to p2 hand:", amount)

static func add_combat_strength_p1(amount:int):
	print("[DeckOfFate] Add strength tokens to p1 leader:", amount)

static func add_combat_strength_p2(amount:int):
	print("[DeckOfFate] Add strength tokens to p2 leader:", amount)

static func clear_combat_strength_p1():
	print("[DeckOfFate] Clear all strength tokens from p1 leader")

static func clear_combat_strength_p2():
	print("[DeckOfFate] Clear all strength tokens from p2 leader")

static func get_leader_type_p1() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetLeaderType from p1! Returning '",(instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_leader_type_p2() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetLeaderType from p2 (always returns Warrior for now)...")
	return DofCardStyleResource.CardType.Warrior
	#return (instance.leader_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_support_type_p1() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetSupportType from p1! Returning '",(instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type,"'...")
	return (instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type

static func get_support_type_p2() -> DofCardStyleResource.CardType:
	print("[DeckOfFate] GetSupportType from p2 (always returns Warrior for now)...")
	return DofCardStyleResource.CardType.Warrior
	#return (instance.support_slot.get_card(0).card_data as DofCardStyleResource).card_type



##Tween the phase label
var _visibility_tween
func tween_visibility(canvas_item:CanvasItem, desired_visibility: Color = Color.WHITE, duration: float = 0.5, ease_type:Tween.EaseType=Tween.EASE_OUT,trans_type:Tween.TransitionType=Tween.TRANS_LINEAR) -> void:
	# If we're already tweening, kill it and start again
	if _visibility_tween:
		_visibility_tween.kill()
	# Tween the transparency of whatever we're targetting 
	_visibility_tween = create_tween().set_ease(ease_type).set_trans(trans_type)
	_visibility_tween.tween_property(canvas_item, "modulate", desired_visibility, duration)




























#
#
#
#@onready var gold_button: Button = %GoldButton
#@onready var silv_button: Button = %SilvButton
#@onready var none_button: Button = %NoneButton
#
#@onready var discard_button: Button = %DiscardButton
#@onready var play_button: Button = %PlayButton
#
#@onready var sort_suit_button: Button = %SortSuitButton
#@onready var sort_value_button: Button = %SortValueButton
#
#
	#
	#print(balatro_hand.max_hand_size)
	#hand_size = balatro_hand.max_hand_size
	#
	#gold_button.pressed.connect(_on_gold_pressed)
	#silv_button.pressed.connect(_on_silv_pressed)
	#none_button.pressed.connect(_on_none_pressed)
	#discard_button.pressed.connect(_on_discard_pressed)
	#play_button.pressed.connect(_on_play_button)
	#sort_suit_button.pressed.connect(_on_sort_suit_pressed)
	#sort_value_button.pressed.connect(_on_sort_value_pressed)
	#
	#
#func _on_gold_pressed() -> void:
	#for card: Card in balatro_hand.selected:
		#card.card_data.current_modiffier = 1
		#card.refresh_layout()
	#balatro_hand.clear_selected()
	#
#func _on_silv_pressed() -> void:
	#for card: Card in balatro_hand.selected:
		#card.card_data.current_modiffier = 2
		#card.refresh_layout()
	#balatro_hand.clear_selected()
	#
#func _on_none_pressed() -> void:
	#for card: Card in balatro_hand.selected:
		#card.card_data.current_modiffier = 0
		#card.refresh_layout()
	#balatro_hand.clear_selected()
#
#
#
#func _on_discard_pressed() -> void:
	#for card in balatro_hand.selected:
		#card_deck_manager.add_card_to_discard_pile(card)
	#balatro_hand.clear_selected()
	#
	#deal()
#
#
#func _on_play_button() -> void:
	#balatro_hand.sort_selected()
	#played_hand.add_cards(balatro_hand.selected)
	#balatro_hand.clear_selected()
	#
#
	#await get_tree().create_timer(2).timeout ##Replace with VFX/Logic
	#
	#for card in played_hand.cards:
		#card_deck_manager.add_card_to_discard_pile(card)
#
	#played_hand.clear_hand()
	#deal()
	#
#
#
#
#func _on_sort_suit_pressed() -> void:
	#sort_by_suit = true
	#balatro_hand.sort_by_suit()
#
#func _on_sort_value_pressed() -> void:
	#sort_by_suit = false
	#balatro_hand.sort_by_value()
#
#
#
	#if card_deck_manager.get_draw_pile_size() >= to_deal:
		#balatro_hand.add_cards(card_deck_manager.draw_cards(to_deal))
		#
	#elif card_deck_manager.get_draw_pile_size() < to_deal:
		#var overflow := to_deal - card_deck_manager.get_draw_pile_size()
		#balatro_hand.add_cards(card_deck_manager.draw_cards(card_deck_manager.get_draw_pile_size()))
		#card_deck_manager.reshuffle_discard_and_shuffle()
		#if card_deck_manager.get_draw_pile_size() >= overflow:
			#balatro_hand.add_cards(card_deck_manager.draw_cards(overflow))
	#
	#if sort_by_suit: balatro_hand.sort_by_suit()
	#else: balatro_hand.sort_by_value()
#
#
	#var to_deal: int = min(hand_size, balatro_hand.get_remaining_space())
	#if to_deal < 0:
		#to_deal = 7
