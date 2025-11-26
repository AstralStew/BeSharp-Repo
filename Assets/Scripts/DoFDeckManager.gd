@icon("uid://u56pws80lkxh")
class_name DoFDeckManager extends CardDeckManager

var deckOfFate : DeckOfFate = null

func setup(deck: CardDeck = starting_deck):
	deckOfFate = get_parent()
	super.setup(deck)

func add_card_to_draw_pile(card: Card) -> void:
	super.add_card_to_draw_pile(card)
	card.card_clicked.connect(deckOfFate.select_card)
