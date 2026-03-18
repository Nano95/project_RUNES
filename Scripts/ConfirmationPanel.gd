extends Control
class_name ConfirmationPanel

var yes_cta:Callable

func _ready() -> void:
	Utils.animate_summary_in_happy(self)

func setup(yes:Callable, title:String, desc:String) -> void:
	yes_cta = yes
	$Panel/Title.text = title
	$Panel/Description.text = desc
	$Panel/yes.pressed.connect(yes)
	$Exitbutton.pressed.connect(close_panel)
	$Panel/no.pressed.connect(close_panel)

func close_panel() -> void:
	Utils.animate_summary_out_and_free(self)
