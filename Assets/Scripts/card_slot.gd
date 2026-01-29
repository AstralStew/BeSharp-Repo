@tool @icon("uid://1g0jb8x0i516")
class_name CardSlot extends CardHand
# THIS IS OURS! We made this class from scratch!

var deckOfFate : DeckOfFate = null

@export var adjacent_left : CardSlot = null
@export var adjacent_right : CardSlot = null

signal slot_clicked(slot)

func is_full() -> bool:
	return get_card_count() > 0

func _ready() -> void:
	if adjacent_left == null:
		push_warning("[CardSlot(",name,")] ERROR -> No adjacent left victory slot assigned! :(")
	if adjacent_right == null:
		push_warning("[CardSlot(",name,")] ERROR -> No adjacent right victory slot assigned! :(")
	deckOfFate = find_parent("DeckOfFate")
	slot_clicked.connect(deckOfFate.select_slot.bind(self))
	
	super._ready()


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		#if get_card_count() > 0:
			#print("[CardSlot(",name,")] Cannot select! Already has a card in slot.")
			#return
		
		print("[CardSlot(",name,")] Slot clicked!")
		slot_clicked.emit()
