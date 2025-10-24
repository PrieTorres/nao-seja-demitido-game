extends HBoxContainer
class_name OptionsRow

@export var options: Array[String] = ["Numero 1", "Outra"]
const FalasOptionScene := preload("res://Scenes/Levels/Estevao/FalasOptions.tscn")

func _ready() -> void:
	# Make sure this row actually takes space in its parent
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_theme_constant_override("separation", 0)

	# Build: Left option, spacer (expands), Right option
	var left := FalasOptionScene.instantiate() as FalasOption
	add_child(left)
	left.set_text(options[0])

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # pushes items to edges
	add_child(spacer)

	var right := FalasOptionScene.instantiate() as FalasOption
	add_child(right)
	right.set_text(options[1])
