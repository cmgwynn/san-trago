extends Control

## Entry point for playtest builds: pick a lab, and press Ctrl+L (Cmd+L on Mac)
## inside any lab to come back here.

var current: Node = null

@onready var menu: Control = %Menu


func _ready() -> void:
	for card: Node in %Cards.get_children():
		card.open_requested.connect(open_lab)
	%Quit.pressed.connect(get_tree().quit)
	%Version.text = "Preproduction build %s  ·  Godot %s" % [
		ProjectSettings.get_setting("application/config/version", "dev"),
		Engine.get_version_info().string,
	]
	(%Cards.get_child(0) as Control).grab_focus()
	if OS.get_cmdline_user_args().has("--smoke"):
		_smoke.call_deferred()


func open_lab(scene_path: String) -> void:
	close_lab()
	current = (load(scene_path) as PackedScene).instantiate()
	add_child(current)
	menu.visible = false


func close_lab() -> void:
	if current != null:
		current.queue_free()
		current = null
	menu.visible = true
	(%Cards.get_child(0) as Control).grab_focus()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if current != null and key != null and key.pressed and not key.echo and key.keycode == KEY_L and (key.ctrl_pressed or key.meta_pressed):
		get_viewport().set_input_as_handled()
		close_lab()


## Build check: `<build> -- --smoke` opens every lab, confirms content loaded from
## the packed folders, prints one line, and exits 0 on success.
func _smoke() -> void:
	var opened: int = 0
	var guests: int = 0
	var drinks: int = 0
	for card: Node in %Cards.get_children():
		open_lab(card.scene_path)
		await get_tree().process_frame
		if current != null and current.is_inside_tree():
			opened += 1
			if "drinks" in current:
				guests = current.book.profiles.size()
				drinks = current.drinks.size()
		close_lab()
	var ok := opened == %Cards.get_child_count() and guests >= 3 and drinks >= 2
	print("SMOKE %s labs=%d guests=%d drinks=%d version=%s" % ["OK" if ok else "FAILED", opened, guests, drinks, ProjectSettings.get_setting("application/config/version")])
	get_tree().quit(0 if ok else 1)
