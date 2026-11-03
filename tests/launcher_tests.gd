extends SceneTree

## The playtest-build launcher: every card opens its lab, and Ctrl/Cmd+L returns.

const Scene = preload("res://scenes/lab_launcher.tscn")

var checks: int = 0
var failures: int = 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	expect(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/lab_launcher.tscn", "builds start at the launcher")
	var launcher: Control = Scene.instantiate()
	root.add_child(launcher)
	await process_frame
	var cards: Array[Node] = launcher.get_node("%Cards").get_children()
	expect(cards.size() == 3, "three lab cards")
	for card: Node in cards:
		expect(not card.title.is_empty() and card.get_node("%Title").text == card.title, "%s shows its title" % card.name)
		expect(card.get_node("%Blurb").text == card.blurb and not card.blurb.is_empty(), "%s shows its blurb" % card.name)
		expect(ResourceLoader.exists(card.scene_path), "%s opens a real scene: %s" % [card.name, card.scene_path])
		card.pressed.emit()
		await process_frame
		expect(launcher.current != null and launcher.current.scene_file_path == card.scene_path, "%s opens its lab" % card.name)
		expect(not launcher.menu.visible, "the menu hides while a lab runs")
		var lab: Node = launcher.current
		var key := InputEventKey.new()
		key.keycode = KEY_L
		key.pressed = true
		# Alternate Ctrl and Cmd so both are covered on every platform.
		key.ctrl_pressed = cards.find(card) % 2 == 0
		key.meta_pressed = not key.ctrl_pressed
		launcher._input(key)
		await process_frame
		expect(launcher.current == null and not is_instance_valid(lab), "Ctrl/Cmd+L closes the %s" % card.title.to_lower())
		expect(launcher.menu.visible, "and the menu is back")
	var plain := InputEventKey.new()
	plain.keycode = KEY_L
	plain.pressed = true
	launcher.open_lab(cards[2].scene_path)
	launcher._input(plain)
	expect(launcher.current != null, "L without Ctrl or Cmd doesn't leave the lab")
	launcher.close_lab()
	print("Launcher checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)
