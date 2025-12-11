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
@export var waiting_for_slot : bool = false
@export var selected_card : Card = null
@export var selected_slot : CardSlot = null
@export var p1_combat_tokens : int = 0
@export var p2_combat_tokens : int = 0
@export var combat_result : CombatResult = CombatResult.loss

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
			await card_selected
			# Hide + disable the card from being grabbed etc
			selected_card.flip()
			selected_card.undraggable = true
			selected_card.disabled = true
			# Add the card to the leader slot
			leader_slot.add_card(selected_card)
			selected_card = null
		
		phases.PickSupport:
			helper_label.text = "Pick a Support from your hand"
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
			helper_label.text = "Revealing Support cards!"
			var support_card = support_slot.get_card(0)
			# Flip the card in the support slot
			support_card.flip()
			
			# Perform the support ability
			(support_card.card_data as DofCardStyleResource).on_support_reveal()
		
		phases.RevealLeader:
			helper_label.text = "Revealing Leader cards!"
			var leader_card = leader_slot.get_card(0)
			# Flip the card in the leader slot
			leader_card.flip()
			
			# Perform the support ability
			(leader_card.card_data as DofCardStyleResource).on_leader_reveal()
		
		phases.Battle:
			#helper_label.text = """Combat:
			#- P1 strength = """,
			# Grab the stats for the leader card (just ignoring 2nd player for now)
			var p1_leader_stats = leader_slot.get_card(0).card_data as DofCardStyleResource
			var p1_leader_strength = p1_leader_stats.strength
			var p2_leader_strength = 2
			
			# Compare the strength of the leaders and score points accordingly
			print("[DeckOfFate] BATTLE: My strength = ",p1_leader_strength,", opponent strength = ", p2_leader_strength)
			if p1_leader_strength + p1_combat_tokens > p2_leader_strength + p2_combat_tokens:
				print("[DeckOfFate] I WIN BATTLE! :D")
				add_points_p1(1)
				combat_result = CombatResult.win
			elif p1_leader_strength + p1_combat_tokens == p2_leader_strength + p2_combat_tokens:
				print("[DeckOfFate] BATTLE DRAW :O")
				add_points_p1(1)
				add_points_p2(1)
				combat_result = CombatResult.draw
			else:
				print("[DeckOfFate] I LOSE BATTLE :(")
				add_points_p2(1)
				combat_result = CombatResult.loss
			
			# Reset combat tokens
			p1_combat_tokens = 0
			p2_combat_tokens = 0
			
			# Perform after-combat effects
			(support_slot.get_card(0).card_data as DofCardStyleResource).on_support_reveal()
			await get_tree().create_timer(1).timeout #Should be a callback
			(leader_slot.get_card(0).card_data as DofCardStyleResource).on_leader_reveal()
			await get_tree().create_timer(1).timeout #Should be a callback
		
		phases.BacklineLeader:
			# Make sure there is still a card in the slot
			if leader_slot.get_card_count() > 0:
				# Wait till the player selects a backline slot
				waiting_for_slot = true
				await slot_selected
				# Add card to chosen backline slot
				selected_slot.add_card(leader_slot.get_card(0))
				selected_slot = null
		
		phases.BacklineSupport:
			# Make sure there is still a card in the slot
			if support_slot.get_card_count() > 0:
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
	draw_cards_p1(number_of_cards_to_draw)

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
	print("[DeckOfFate] Remove p1 card")

	# Move the card to the discard pile
	instance.dof_deck_manager.add_card_to_discard_pile(card)

static func remove_card_p2(card:Card):
	print("[DeckOfFate] Remove p2 card (NOTE -> not implemented, does nothing!)")

	## Move the card to the discard pile
	#instance.dof_deck_manager.add_card_to_discard_pile(card)


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





#endregion


#region Getters

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
