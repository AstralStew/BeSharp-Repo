extends CardLayout
#this applies values to a card
@onready var card_color: PanelContainer = %PanelContainer
@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %Label
@onready var strength_label: Label = %Label2

var res: DofCardStyleResource

func _update_display() -> void:
	res = card_resource as DofCardStyleResource
	#set_color()
	texture_rect.texture = res.top_texture
	name_label.text = res.card_name
	strength_label.text = str(res.strength)
