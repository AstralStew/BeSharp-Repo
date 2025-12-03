@tool @icon("uid://1g0jb8x0i516")
class_name CardSlot extends CardHand
# THIS IS OURS! We made this class from scratch!

var deckOfFate : DeckOfFate = null

signal slot_clicked(slot)

func _ready() -> void:
	deckOfFate = find_parent("DeckOfFate")
	slot_clicked.connect(deckOfFate.select_slot.bind(self))
	
	super._ready()


func _gui_input(event: InputEvent):	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if get_card_count() > 0:
			print("[CardSlot] Cannot select! Already has a card in slot.")
			return
		
		print("[CardSlot] Slot clicked!")
		slot_clicked.emit()
