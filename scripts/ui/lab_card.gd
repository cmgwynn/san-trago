@tool
extends Button

## A launcher card: a title, a line about what to try, and the scene it opens.
## Restyle it in lab_card.tscn; every card in the launcher updates.

signal open_requested(scene_path: String)

@export var title: String = "Lab":
	set(value):
		title = value
		_sync()
@export_multiline var blurb: String = "":
	set(value):
		blurb = value
		_sync()
@export_file("*.tscn") var scene_path: String = ""


func _ready() -> void:
	_sync()
	pressed.connect(func() -> void: open_requested.emit(scene_path))


func _sync() -> void:
	if not is_node_ready():
		return
	%Title.text = title
	%Blurb.text = blurb
