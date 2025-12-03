class_name DeckOfFate extends CanvasLayer
#Runs the game

@export_category("REFERENCES")
@onready var dof_deck_manager: DoFDeckManager = $DoFDeckManager
@onready var player_hand: CardHand = $PlayerHand
@onready var leader_slot: CardHand = $LeaderSlot
@onready var support_slot: CardHand = $SupportSlot
@onready var victory_slot_1: CardHand = $VictoryDisplay/VictorySlot1
@onready var victory_slot_2: CardHand = $VictoryDisplay/VictorySlot2
@onready var victory_slot_3: CardHand = $VictoryDisplay/VictorySlot3
@onready var victory_slot_4: CardHand = $VictoryDisplay/VictorySlot4
@onready var victory_slot_5: CardHand = $VictoryDisplay/VictorySlot5
@onready var victory_slot_6: CardHand = $VictoryDisplay/VictorySlot6
@onready var phase_label: RichTextLabel = $PhaseLabel
@onready var p1_score_label: RichTextLabel = $P1ScoreDesc_VB/P1Score_RTL
@onready var p2_score_label: RichTextLabel = $P2ScoreDesc_VB/P2Score_RTL


@export_category("READ ONLY")
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
	dof_deck_manager.setup()	
	_start_game()



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
			# Flip the card in the support slot
			support_slot.get_card(0).flip()
		
		phases.RevealLeader:
			# Flip the card in the leader slot
			leader_slot.get_card(0).flip()
		
		phases.Battle:
			# Grab the stats for the leader card (just ignoring 2nd player for now)
			var p1_leader_stats = leader_slot.get_card(0).card_data as DofCardStyleResource
			var p1_leader_strength = p1_leader_stats.strength			
			var p2_leader_strength = 2
			
			# Compare the strength of the leaders and score points accordingly
			print("[DeckOfFate] BATTLE: My strength = ",p1_leader_strength,", opponent strength = ", p2_leader_strength)
			if p1_leader_strength > p2_leader_strength:
				print("[DeckOfFate] I WIN BATTLE! :D")
				p1_score += 1
			elif p1_leader_strength == p2_leader_strength:
				print("[DeckOfFate] BATTLE DRAW :O")
				p1_score += 1
				p2_score += 1
			else:
				print("[DeckOfFate] I LOSE BATTLE :(")
				p2_score += 1
			
			# Update the label to match the current scores
			p1_score_label.text = str(p1_score)
			p2_score_label.text = str(p2_score)
		
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
			pass
		
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
	# If its the first draw, add 4 cards to player's hand
	if !first_draw_completed:
		player_hand.add_cards(dof_deck_manager.draw_cards(4))
		first_draw_completed = true
		return
	# Otherwise, add 2 cards to player's hand
	player_hand.add_cards(dof_deck_manager.draw_cards(2))
	



##Tween the phase label
var _visibility_tween
func tween_visibility(canvas_item:CanvasItem, desired_visibility: Color = Color.WHITE, duration: float = 0.5, ease:Tween.EaseType=Tween.EASE_OUT,trans:Tween.TransitionType=Tween.TRANS_LINEAR) -> void:
	# If we're already tweening, kill it and start again
	if _visibility_tween:
		_visibility_tween.kill()
	# Tween the transparency of whatever we're targetting 
	_visibility_tween = create_tween().set_ease(ease).set_trans(trans)
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
