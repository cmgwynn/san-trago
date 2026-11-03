extends Control

## Gray-box of the concept 02 service layout, wired to the real guest book.
## Art, pouring, and the shift timer are deliberately absent: this checks zones,
## sizes, hotkeys, and the guest-book loop at real resolution. Authored at
## 1600 x 900 and letterboxed to fit any window.

const Book = preload("res://scripts/systems/guest_book.gd")
const DESIGN := Vector2(1600, 900)
const Catalog = preload("res://scripts/content/content_catalog.gd")
## Recipe block letters, in ticket order.
const PART_LETTERS := {"rum": "R", "cola": "C", "draft": "D"}
const QUEUE: Array[String] = ["maya", "jules"]
## Speed rail, left to right. Number keys 1-4 pick a source.
const SOURCES: Array[String] = ["draft", "rum", "cola", "nuts"]
## Smallest font size on the 1600 x 900 stage: 12 px on a Steam Deck.
const MIN_FONT := 15

const WOOD := Color("2e1c13")
const WOOD_LIGHT := Color("6b3f25")
const SHADOW := Color("120b08")
const BRASS := Color("c9973f")
const BRASS_LIGHT := Color("f2d08a")
const PAPER := Color("f1e2bf")
const INK := Color("3b2418")
const SOFT_INK := Color("7a5a40")
const SKY := Color("c4566c")
const HEART := Color("d9534f")

## Named zones, in design pixels. Tests assert these stay inside the screen and apart.
const ZONES := {
	"top_bar": Rect2(0, 0, 1600, 48),
	"cabinet_left": Rect2(40, 76, 492, 480),
	"cabinet_right": Rect2(1068, 76, 492, 480),
	"arch": Rect2(600, 120, 400, 452),
	"seat_left": Rect2(388, 420, 148, 152),
	"seat_right": Rect2(1076, 420, 148, 152),
	"bar_top": Rect2(0, 572, 1600, 144),
	"glass_rack": Rect2(76, 596, 250, 118),
	"tutorial": Rect2(418, 618, 228, 62),
	"mat": Rect2(650, 536, 300, 168),
	"tip_jar": Rect2(1004, 616, 56, 74),
	"churro": Rect2(1240, 528, 104, 186),
	"book_counter": Rect2(1396, 590, 132, 124),
	"toast": Rect2(1352, 508, 238, 76),
	"ticket_rail": Rect2(22, 728, 478, 168),
	"speed_rail": Rect2(512, 728, 564, 164),
	"back_bar": Rect2(1084, 728, 310, 164),
	"day_dial": Rect2(1406, 724, 168, 168),
}
## The guest's face inside the arch. No interactive control may cover it.
const FACE := Rect2(740, 280, 120, 150)

var book: Book
var selected: String = "maya"
var book_open: bool = false
var book_guest: String = "maya"
var stage: Control
var speech: Label
var speaker: Label
var guest_name: Label
var badge: Label
var tutorial: Label
var toast: Label
var seat: Label
var tickets: Dictionary = {}
var rail: Dictionary = {}
var source: String = "cola"
var overlay: Control
var book_title: Label
var book_role: Label
var fact_list: VBoxContainer
var tabs: Dictionary = {}
var capture_path: String = ""
var frames: int = 0
var drinks: Dictionary = {}
## Book page order: the queue first, then everyone else in the catalog.
var guest_ids: Array[String] = []


func _ready() -> void:
	var profiles: Array[Resource] = Catalog.load_dir(Catalog.GUESTS_DIR)
	drinks = Catalog.by_id(Catalog.load_dir(Catalog.DRINKS_DIR))
	book = Book.new(profiles)
	guest_ids.assign(QUEUE)
	for profile: Resource in profiles:
		if not guest_ids.has(profile.id):
			guest_ids.append(profile.id)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_fit)
	_fit()
	_refresh()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")


func _process(_delta: float) -> void:
	if capture_path.is_empty():
		return
	frames += 1
	if frames == 4 and capture_path.contains("book"):
		serve(true)
		serve(true)
		open_book()
	if frames == 8:
		get_viewport().get_texture().get_image().save_png(capture_path)
		get_tree().quit()


func _fit() -> void:
	var factor: float = min(size.x / DESIGN.x, size.y / DESIGN.y)
	stage.scale = Vector2(factor, factor)
	stage.position = ((size - DESIGN * factor) / 2.0).round()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_TAB:
			close_book() if book_open else open_book()
		KEY_ESCAPE:
			if book_open:
				close_book()
		KEY_1, KEY_2, KEY_3, KEY_4:
			if not book_open:
				pick_source(SOURCES[event.keycode - KEY_1])
		KEY_LEFT, KEY_RIGHT:
			if not book_open:
				var step := 1 if event.keycode == KEY_RIGHT else -1
				select_guest(QUEUE[posmod(QUEUE.find(selected) + step, QUEUE.size())])
		KEY_SPACE:
			if not book_open:
				serve(true)
		_:
			return
	get_viewport().set_input_as_handled()


# ---------- actions ----------

func select_guest(guest_id: String) -> void:
	selected = guest_id
	_refresh()


func pick_source(source_id: String) -> void:
	source = source_id
	_refresh()


func serve(perfect: bool) -> void:
	var drink: Resource = _usual(selected)
	var unlocked: Array[String] = book.record_visit(selected)
	unlocked.append_array(book.record_serve(selected, drink.id, perfect))
	_announce(selected, unlocked, "Served %s%s." % [drink.display_name.to_lower(), "" if perfect else ", a little sloppy"])


func small_talk() -> void:
	_announce(selected, book.record_topic(selected, _topic(selected).id), "You chat for a moment.")


func pet_churro() -> void:
	var unlocked: Array[String] = book.record_visit("churro")
	unlocked.append_array(book.record_topic("churro", "pet"))
	_announce("churro", unlocked, "Churro purrs.")


func open_book(guest_id: String = "") -> void:
	if guest_id.is_empty():
		guest_id = _first_unread() if book.unread_count() > 0 else selected
	book_guest = guest_id
	book_open = true
	overlay.visible = true
	_refresh_book()


func close_book() -> void:
	book.mark_read(book_guest)
	book_open = false
	overlay.visible = false
	_refresh()


func show_page(guest_id: String) -> void:
	book.mark_read(book_guest)
	book_guest = guest_id
	_refresh_book()


func _first_unread() -> String:
	for id: String in guest_ids:
		if book.unread_count(id) > 0:
			return id
	return selected


func _announce(guest_id: String, unlocked: Array[String], base: String) -> void:
	var name: String = book.profiles[guest_id].display_name.get_slice(" ", 0)
	toast.text = base if unlocked.is_empty() else "%s  New about %s: %s" % [base, name, book.profiles[guest_id].fact(unlocked[0]).text]
	_refresh()


# ---------- view ----------

func _refresh() -> void:
	guest_name.text = _short(selected)
	speaker.text = guest_name.text
	speech.text = _topic(selected).line
	for id: String in tickets:
		var ticket: Button = tickets[id]
		ticket.button_pressed = id == selected
		var drink: Resource = _usual(id)
		ticket.text = "%s\n%s\n%s\n%s" % [_short(id), "ordering" if id == selected else "waiting", drink.display_name, _recipe_blocks(drink)]
	var waiting: Array[String] = []
	for id: String in QUEUE:
		if id != selected:
			waiting.append(_short(id))
	seat.text = "%s\nwaiting…" % ", ".join(waiting)
	for id: String in rail:
		rail[id].button_pressed = id == source
	tutorial.text = "%d  Hold to pour %s\nLet go anytime; the fill stays" % [SOURCES.find(source) + 1, source]
	var unread := book.unread_count()
	badge.visible = unread > 0
	badge.text = "+%d" % unread


func _usual(guest_id: String) -> Resource:
	return drinks[book.profiles[guest_id].usual_drink]


func _topic(guest_id: String) -> Resource:
	return book.profiles[guest_id].topics[0]


func _recipe_blocks(drink: Resource) -> String:
	var parts := PackedStringArray()
	var amounts: Dictionary = drink.quantities()
	for part: String in PART_LETTERS:
		for i: int in amounts.get(part, 0):
			parts.append(PART_LETTERS[part])
	return " ".join(parts)


func _short(guest_id: String) -> String:
	return book.profiles[guest_id].display_name.get_slice(" ", 0)


func _refresh_book() -> void:
	var profile: Resource = book.profiles[book_guest]
	book_title.text = profile.display_name
	book_role.text = "%s  ·  %d of %d known" % [profile.role, book.known_count(book_guest), profile.facts.size()]
	for child: Node in fact_list.get_children():
		child.queue_free()
	for entry: Dictionary in book.page(book_guest):
		var row := Label.new()
		row.name = "Fact_" + entry.id
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size.x = 400
		var mark := "NEW  " if entry.new else ("✓  " if entry.known else "🔒  ")
		row.text = mark + entry.text + ("" if entry.known else "\n      " + entry.hint)
		row.add_theme_color_override("font_color", INK if entry.known else SOFT_INK)
		row.add_theme_font_size_override("font_size", 22 if entry.known else 19)
		fact_list.add_child(row)
	for id: String in tabs:
		tabs[id].button_pressed = id == book_guest
		tabs[id].text = book.profiles[id].display_name.get_slice(" ", 0) + ("  •" if book.unread_count(id) > 0 and id != book_guest else "")


# ---------- construction ----------

func _box(parent: Control, zone: Rect2, color: Color, border: Color = Color.TRANSPARENT, radius: int = 6, node_name: String = "") -> Panel:
	var panel := Panel.new()
	if not node_name.is_empty():
		panel.name = node_name
	panel.position = zone.position
	panel.size = zone.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if border.a > 0:
		style.border_color = border
		style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Control, text: String, pos: Vector2, size_: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	# Wrap and size first, so long text wraps instead of widening the label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.position = pos
	label.size = size_
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, zone: Rect2, font_size: int, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = zone.position
	button.size = zone.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PAPER if state != "hover" else PAPER.lightened(0.15)
		style.set_corner_radius_all(6)
		style.border_color = BRASS_LIGHT if state.contains("pressed") else BRASS
		style.set_border_width_all(5 if state.contains("pressed") else 2)
		button.add_theme_stylebox_override(state, style)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, INK)
	parent.add_child(button)
	return button


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("0d0806")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	stage = Control.new()
	stage.name = "Stage"
	stage.size = DESIGN
	stage.clip_contents = true
	add_child(stage)
	_box(stage, Rect2(Vector2.ZERO, DESIGN), WOOD, Color.TRANSPARENT, 0)

	# Top bar: the guest book lives on the counter, so there is no second book button here
	_box(stage, ZONES.top_bar, SHADOW, Color.TRANSPARENT, 0, "TopBar")
	_label(stage, "Pacific Pour", Vector2(40, 4), Vector2(230, 40), 22, BRASS_LIGHT)
	_label(stage, "1-4  source    Space  serve    ←/→  guest    Tab  book", Vector2(620, 4), Vector2(760, 40), MIN_FONT, Color(PAPER, 0.6))
	_label(stage, "$128", Vector2(1396, 4), Vector2(128, 40), 22, BRASS_LIGHT)
	# Prototype controls (not part of the proposed UI)
	var sloppy := _button(stage, "Serve sloppy", Rect2(290, 6, 150, 36), MIN_FONT, "ServeSloppy")
	sloppy.pressed.connect(serve.bind(false))
	var perfect := _button(stage, "Serve perfect", Rect2(450, 6, 150, 36), MIN_FONT, "ServePerfect")
	perfect.pressed.connect(serve.bind(true))

	# Back bar, waiting seats, and the arch
	for side: String in ["cabinet_left", "cabinet_right"]:
		var cab := _box(stage, ZONES[side], SHADOW, WOOD_LIGHT, 4, side.capitalize().replace(" ", ""))
		_label(cab, "Shelves: decor and keepsakes\n(no interaction)", Vector2(0, 0), Vector2(cab.size.x, 200), 18, Color(PAPER, 0.25))
	_box(stage, ZONES.seat_left, WOOD.darkened(0.3), Color.TRANSPARENT, 60, "SeatLeft")
	seat = _label(stage, "", ZONES.seat_left.position, ZONES.seat_left.size, 17, Color(PAPER, 0.6))
	_box(stage, ZONES.seat_right, WOOD.darkened(0.3), Color.TRANSPARENT, 60, "SeatRight")
	_label(stage, "Empty seat", ZONES.seat_right.position, ZONES.seat_right.size, 17, Color(PAPER, 0.35))
	var arch := _box(stage, ZONES.arch, SKY.darkened(0.2), BRASS, 200, "Arch")
	arch.get_theme_stylebox("panel").corner_radius_bottom_left = 0
	arch.get_theme_stylebox("panel").corner_radius_bottom_right = 0
	_box(stage, FACE, Color("a8673f"), Color.TRANSPARENT, 60, "Face")
	guest_name = _label(stage, "", Vector2(FACE.position.x - 40, FACE.end.y + 10), Vector2(FACE.size.x + 80, 36), 24, PAPER)
	_box(stage, Rect2(680, 176, 240, 70), PAPER, BRASS, 10, "Speech")
	speech = _label(stage, "", Vector2(690, 180), Vector2(220, 62), 17, INK)
	_box(stage, Rect2(692, 160, 84, 26), SHADOW, BRASS, 5)
	speaker = _label(stage, "", Vector2(692, 160), Vector2(84, 26), 16, BRASS_LIGHT)
	var talk := _button(stage, "Chat", Rect2(930, 196, 60, 32), MIN_FONT, "ChatButton")
	talk.pressed.connect(small_talk)

	# Bar top: the glass sits large on the mat, under the guest
	_box(stage, ZONES.bar_top, WOOD_LIGHT, Color.TRANSPARENT, 0, "BarTop")
	_button(stage, "Clean glasses\n3", ZONES.glass_rack, 18, "GlassRack")
	_box(stage, ZONES.tutorial, PAPER, BRASS, 10, "Tutorial")
	tutorial = _label(stage, "", ZONES.tutorial.position + Vector2(8, 0), ZONES.tutorial.size - Vector2(16, 0), MIN_FONT, INK)
	_box(stage, ZONES.mat, Color("15100d"), Color.TRANSPARENT, 4, "Mat")
	_box(stage, Rect2(692, 556, 26, 136), BRASS, Color.TRANSPARENT, 11, "Gauge")
	_button(stage, "Glass\n(hold to pour)", Rect2(736, 538, 128, 162), 17, "Glass")
	_box(stage, ZONES.tip_jar, Color(PAPER, 0.2), Color.TRANSPARENT, 10, "TipJar")
	var cat := _button(stage, "Churro\n(pet)", ZONES.churro, 17, "Churro")
	cat.pressed.connect(pet_churro)
	var counter_book := _button(stage, "Guest\nbook", ZONES.book_counter, 20, "GuestBook")
	counter_book.pressed.connect(func() -> void: open_book())
	badge = _label(stage, "", Vector2(ZONES.book_counter.end.x - 30, ZONES.book_counter.position.y - 14), Vector2(36, 28), 16, Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = HEART
	badge_style.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("normal", badge_style)
	toast = _label(stage, "Serve guests or chat to learn about them.", ZONES.toast.position, ZONES.toast.size, MIN_FONT, BRASS_LIGHT)

	# Lower bar: orders, speed rail, back bar, day dial
	_box(stage, Rect2(22, 734, 478, 12), BRASS, Color.TRANSPARENT, 5, "TicketRail")
	for i: int in QUEUE.size():
		var id: String = QUEUE[i]
		var ticket := _button(stage, "", Rect2(30 + i * 158, 744, 148, 148), 17, "Ticket_" + id)
		ticket.toggle_mode = true
		ticket.pressed.connect(select_guest.bind(id))
		tickets[id] = ticket
	_label(stage, "Empty slot", Vector2(346, 744), Vector2(148, 148), 16, Color(PAPER, 0.3))
	_box(stage, ZONES.speed_rail, SHADOW, WOOD_LIGHT, 6, "SpeedRail")
	var slot_w: float = ZONES.speed_rail.size.x / 5.0
	for i: int in SOURCES.size():
		var id: String = SOURCES[i]
		var slot := Rect2(ZONES.speed_rail.position + Vector2(i * slot_w + 8, 10), Vector2(slot_w - 16, ZONES.speed_rail.size.y - 20))
		var button := _button(stage, "%d\n%s" % [i + 1, id.to_upper()], slot, 18, "Source_" + id)
		button.toggle_mode = true
		button.pressed.connect(pick_source.bind(id))
		rail[id] = button
	_label(stage, "+\nUpgrade", ZONES.speed_rail.position + Vector2(4 * slot_w, 0), Vector2(slot_w, ZONES.speed_rail.size.y), 18, Color(PAPER, 0.35))
	_box(stage, ZONES.back_bar, SHADOW, WOOD_LIGHT, 6, "BackBar")
	var wash_w: float = (ZONES.back_bar.size.x - 16) / 3.0
	for i: int in 3:
		var station: String = ["Dirty 1", "Sink", "Wash"][i]
		_button(stage, station, Rect2(ZONES.back_bar.position + Vector2(8 + i * wash_w, 10), Vector2(wash_w - 8, 112)), 17, "Wash_" + station.get_slice(" ", 0))
	_label(stage, "Busser: hire one in the shop", ZONES.back_bar.position + Vector2(0, 126), Vector2(ZONES.back_bar.size.x, 30), MIN_FONT, Color(PAPER, 0.5))
	var dial := _box(stage, ZONES.day_dial, BRASS, BRASS_LIGHT, 84, "DayDial")
	_label(dial, "DAY 1\nTuesday\n6:40 pm", Vector2.ZERO, dial.size, 20, INK)

	_build_overlay()


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "BookOverlay"
	overlay.size = DESIGN
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.01, 0.78)
	dim.size = DESIGN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	_label(overlay, "Guest book", Vector2(500, 120), Vector2(600, 48), 34, PAPER)
	_label(overlay, "Service paused", Vector2(500, 164), Vector2(600, 28), 18, Color(PAPER, 0.7))
	_box(overlay, Rect2(420, 220, 760, 440), Color("4a1e1a"), Color.TRANSPARENT, 10)
	_box(overlay, Rect2(432, 230, 364, 420), PAPER, Color.TRANSPARENT, 4, "LeftPage")
	_box(overlay, Rect2(804, 230, 364, 420), PAPER, Color.TRANSPARENT, 4, "RightPage")
	_box(overlay, Rect2(554, 270, 120, 150), Color("c8a27a"), Color("8a6a48"), 60, "Portrait")
	book_title = _label(overlay, "", Vector2(432, 440), Vector2(364, 40), 28, INK)
	book_role = _label(overlay, "", Vector2(432, 480), Vector2(364, 30), 18, SOFT_INK)
	_label(overlay, "What you know", Vector2(830, 244), Vector2(320, 40), 24, INK, HORIZONTAL_ALIGNMENT_LEFT)
	fact_list = VBoxContainer.new()
	fact_list.name = "Facts"
	fact_list.position = Vector2(830, 292)
	fact_list.size = Vector2(320, 340)
	fact_list.add_theme_constant_override("separation", 10)
	overlay.add_child(fact_list)
	var tab_y := 240
	for id: String in guest_ids:
		var tab := _button(overlay, "", Rect2(1180, tab_y, 130, 52), 18, "Tab_" + id)
		tab.toggle_mode = true
		tab.pressed.connect(show_page.bind(id))
		tabs[id] = tab
		tab_y += 64
	var close := _button(overlay, "Close  (Tab)", Rect2(700, 690, 200, 48), 18, "CloseBook")
	close.pressed.connect(close_book)
