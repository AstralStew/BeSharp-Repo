@icon("uid://u56pws80lkxh")
class_name DoFDeckManager extends CardDeckManager

@onready var player_manager : PlayerManager = self.get_parent()

#func setup(deck: CardDeck = starting_deck):
	#deckOfFate = get_parent()
	#super.setup(deck)

func add_card_to_draw_pile(card: Card) -> void:
	super.add_card_to_draw_pile(card)
	print("[",name,"] Adding '",player_manager,"' as the player manager for '",card,"'")
	(card.card_data as DofCardStyleResource).player_manager = player_manager
	card.card_clicked.connect(player_manager.select_card)
	card.flip()

##Add cards to the draw pile. [br]If a card is already a child [CardHand] the [member CardHand.remove_card] is used to reparent the card.
func add_cards_to_draw_pile(cards: Array[Card]) -> void:
	for card in cards:
		super.add_card_to_draw_pile(card)
		card.flip()
