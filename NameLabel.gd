extends Node3D

@onready var label = $SubViewport/Label
@onready var subviewport = $SubViewport

func _ready():
    subviewport.size = Vector2(200, 50)

func set_name(new_name: String):
    label.text = new_name
    # Автоматический размер текста
    var font = label.get_theme_font("font")
    var font_size = label.get_theme_font_size("font_size")
    var text_size = font.get_string_size(new_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
    subviewport.size = text_size + Vector2(20, 10)
