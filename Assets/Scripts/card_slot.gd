@tool @icon("uid://1g0jb8x0i516")
class_name CardSlot extends CardHand
# THIS IS OURS! We made this class from scratch!

var player_manager : PlayerManager = null

@export var adjacent_left : CardSlot = null
@export var adjacent_right : CardSlot = null

signal slot_clicked(slot)

func is_full() -> bool:
	return get_card_count() > 0

func initialise_slot() -> void:
	if player_manager == null:
		push_error("[CardSlot] ERROR -> No PlayerManager defined! :(")
		return
	
	if adjacent_left == null:
		push_warning("[CardSlot(",name,")] ERROR -> No adjacent left victory slot assigned! :(")
	if adjacent_right == null:
		push_warning("[CardSlot(",name,")] ERROR -> No adjacent right victory slot assigned! :(")
		
	slot_clicked.connect(player_manager.select_slot.bind(self))
	


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		#if get_card_count() > 0:
			#print("[CardSlot(",name,")] Cannot select! Already has a card in slot.")
			#return
		
		print("[CardSlot(",name,")] Slot clicked!")
		slot_clicked.emit()
