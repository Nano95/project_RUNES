extends Control
class_name FocusChamber

@export var number_pad:Control

func connect_number_pad() -> void:
	# Loop through all Button children of this Control node
	for button in number_pad.get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_number_pad_button_pressed").bind(button))
