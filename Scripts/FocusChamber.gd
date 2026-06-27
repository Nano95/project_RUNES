extends Control
class_name FocusChamber

@export var number_pad:Control
@export var code_label:Label
@export var player_label:Label 
@export var timer_progress_bar:TextureProgressBar
@export var player_input:String = "" # What the player types

func connect_number_pad() -> void:
	# Loop through all Button children of this Control node
	for button in number_pad.get_children():
		if button is Button:
			button.connect("pressed", Callable(self, "_on_number_pad_button_pressed").bind(button))
