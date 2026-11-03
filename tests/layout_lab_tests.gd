extends SceneTree

const Scene = preload("res://scenes/layout_lab.tscn")
const SIZES: Array[Vector2] = [Vector2(1280, 800), Vector2(1024, 768), Vector2(1920, 1080), Vector2(2560, 1080)]

var checks: int = 0
var failures: int = 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab: Control = Scene.instantiate()
	root.add_child(lab)
	await process_frame
	_zones(lab)
	await _scaling(lab)
	_book_loop(lab)
	_hotkeys(lab)
	lab.queue_free()
	await process_frame
	print("Layout lab checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _interactive(lab: Control) -> Array[Control]:
	var found: Array[Control] = []
	var pending: Array[Node] = [lab.stage]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node == lab.overlay:
			continue
		if node is BaseButton:
			found.append(node)
		pending.append_array(node.get_children())
	return found


func _zones(lab: Control) -> void:
	var screen := Rect2(Vector2.ZERO, lab.DESIGN)
	var names: Array = lab.ZONES.keys()
	for zone_name: String in names:
		expect(screen.encloses(lab.ZONES[zone_name]), "%s zone fits on screen" % zone_name)
	# The stage layers seats and the glass over the back bar on purpose; bar-top and lower-bar zones must stay apart.
	for group: Array in [
		["glass_rack", "tutorial", "mat", "tip_jar", "churro", "book_counter", "toast"],
		["ticket_rail", "speed_rail", "back_bar", "day_dial"],
	]:
		for i: int in group.size():
			for j: int in range(i + 1, group.size()):
				expect(not lab.ZONES[group[i]].intersects(lab.ZONES[group[j]]), "%s and %s do not overlap" % [group[i], group[j]])
	expect(lab.ZONES.arch.encloses(lab.FACE), "the face sits inside the arch")
	for zone_name: String in ["seat_left", "seat_right", "mat", "toast", "tutorial"]:
		expect(not lab.ZONES[zone_name].intersects(lab.FACE), "%s keeps clear of the guest's face" % zone_name)
		expect(not lab.ZONES[zone_name].intersects(lab.ZONES.arch) or zone_name == "mat", "%s stays outside the arch" % zone_name)
	expect(lab.ZONES.mat.get_center().x == lab.DESIGN.x / 2.0, "the work area is centered under the guest")
	var glass: Control = lab.stage.get_node("Glass")
	expect(glass.size.x >= 120 and glass.size.y >= 150, "the glass is large enough to be the focus")
	expect(lab.stage.get_node_or_null("BookButton") == null, "the guest book has one entry point")
	var buttons := _interactive(lab)
	expect(buttons.size() >= 12, "service screen has its controls")
	for button: Control in buttons:
		var rect := Rect2(button.position, button.size)
		expect(screen.encloses(rect), "%s fits on screen" % button.name)
		expect(not rect.intersects(lab.FACE), "%s keeps clear of the guest's face" % button.name)
	for i: int in buttons.size():
		for j: int in range(i + 1, buttons.size()):
			var a := Rect2(buttons[i].position, buttons[i].size)
			var b := Rect2(buttons[j].position, buttons[j].size)
			expect(not a.intersects(b), "%s and %s do not overlap" % [buttons[i].name, buttons[j].name])
	for ticket: Button in lab.tickets.values():
		expect(lab.ZONES.ticket_rail.encloses(Rect2(ticket.position, ticket.size)), "%s hangs on the rail" % ticket.name)
	for source: Button in lab.rail.values():
		expect(lab.ZONES.speed_rail.encloses(Rect2(source.position, source.size)), "%s sits in the speed rail" % source.name)
	var toast_rect: Rect2 = lab.ZONES.toast
	for button: Control in buttons:
		expect(not toast_rect.intersects(Rect2(button.position, button.size)), "the toast never covers %s" % button.name)
	var pending: Array[Node] = [lab.stage]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if node is Label or node is Button:
			var font_size: int = node.get_theme_font_size("font_size")
			expect(font_size >= lab.MIN_FONT, "%s text is at least %d px (%d)" % [node.name, lab.MIN_FONT, font_size])


func _scaling(lab: Control) -> void:
	for window: Vector2 in SIZES:
		lab.size = window
		await process_frame
		var scaled := Rect2(lab.stage.position, lab.DESIGN * lab.stage.scale)
		expect(Rect2(Vector2.ZERO, window).grow(0.5).encloses(scaled), "stage fits inside %s (lab %s, stage %s)" % [window, lab.size, scaled])
		expect(is_equal_approx(scaled.size.x, window.x) or is_equal_approx(scaled.size.y, window.y), "stage fills one axis at %s" % window)
		expect(absf(scaled.get_center().x - window.x / 2.0) <= 1.0 and absf(scaled.get_center().y - window.y / 2.0) <= 1.0, "stage is centered at %s" % window)
		var smallest: float = lab.stage.scale.x * 15.0
		expect(window.y < 800 or smallest >= 11.0, "smallest text stays readable at %s (%.1f px)" % [window, smallest])


func _book_loop(lab: Control) -> void:
	expect(lab.selected == "maya" and lab.tickets.maya.button_pressed, "Maya starts in the arch")
	expect(not lab.badge.visible, "no badge before learning anything")
	lab.tickets.jules.pressed.emit()
	expect(lab.selected == "jules" and lab.tickets.jules.button_pressed and not lab.tickets.maya.button_pressed, "clicking a ticket selects that guest")
	expect(lab.speaker.text == "Jules", "the speech card follows the selected guest")
	lab.select_guest("maya")
	lab.serve(true)
	expect(lab.badge.visible and lab.badge.text == "+1", "serving Maya her usual raises the badge")
	expect(lab.toast.text.contains("Usual: rum and cola"), "the unlock is announced")
	lab.serve(false)
	expect(lab.badge.text == "+2", "a second visit unlocks the tower fact")
	expect(lab.book.page("maya")[2].known == false, "a sloppy serve does not count as perfect")
	var event := InputEventKey.new()
	event.keycode = KEY_TAB
	event.pressed = true
	lab._unhandled_input(event)
	expect(lab.book_open and lab.overlay.visible and lab.book_guest == "maya", "Tab opens the book at the guest with news")
	expect(lab.fact_list.get_child_count() == 5, "the page lists every fact")
	expect(lab.book_role.text.contains("2 of 5"), "the page counts known facts")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	lab._unhandled_input(space)
	expect(lab.book.page("maya")[2].known == false, "Space does not serve while the book is open")
	lab.tabs.churro.pressed.emit()
	expect(lab.book_guest == "churro" and lab.book.unread_count("maya") == 0, "turning the page marks the last page read")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	lab._unhandled_input(escape)
	expect(not lab.book_open and not lab.overlay.visible and not lab.badge.visible, "Esc closes the book and clears the badge")
	lab.pet_churro()
	expect(lab.badge.visible and lab.toast.text.contains("Churro"), "petting Churro teaches something about him")
	lab.small_talk()
	expect(lab.book.is_known("maya", "pier_surfer"), "chatting about the pier unlocks Maya's topic fact")


func _hotkeys(lab: Control) -> void:
	expect(lab.source == "cola" and lab.rail.cola.button_pressed, "cola is the starting source")
	for i: int in lab.SOURCES.size():
		var key := InputEventKey.new()
		key.keycode = KEY_1 + i
		key.pressed = true
		lab._unhandled_input(key)
		var id: String = lab.SOURCES[i]
		expect(lab.source == id and lab.rail[id].button_pressed, "key %d picks %s" % [i + 1, id])
		expect(lab.tutorial.text.begins_with("%d  Hold to pour %s" % [i + 1, id]), "the tutorial names key %d" % [i + 1])
	lab.rail.rum.pressed.emit()
	expect(lab.source == "rum", "clicking a rail slot picks it")
	lab.select_guest("maya")
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.pressed = true
	lab._unhandled_input(right)
	expect(lab.selected == "jules" and lab.seat.text.begins_with("Maya"), "Right moves to the next guest; Maya waits at the bar")
	lab._unhandled_input(right)
	expect(lab.selected == "maya", "guest selection wraps around")
	lab.serve(true)
	expect(lab.toast.size.x <= lab.ZONES.toast.size.x + 0.5, "long toasts wrap inside their zone (%.0f px wide)" % lab.toast.size.x)
	lab.select_guest("maya")
	expect(lab.tickets.maya.text.contains("Rum & cola") and lab.tickets.maya.text.contains("R C C"), "tickets come from Maya's usual drink: %s" % lab.tickets.maya.text.replace("\n", " / "))
	expect(lab.tickets.jules.text.contains("D D"), "Jules's ticket shows his recipe blocks")
	expect(lab.speech.text == lab.book.profiles.maya.topics[0].line, "the speech card shows the guest's authored topic line")
