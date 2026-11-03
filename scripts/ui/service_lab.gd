extends "res://scripts/ui/bartending_lab.gd"

const Shift = preload("res://scripts/systems/service_shift.gd")
var shift := Shift.new()
var selected_spot: int = 0
var guest_buttons: Array[Button] = []
var wash_button: Button
var glass_status: Label
var preparation_recipe: Recipe
var selected_guest_id: int = -1
var equipment_choice: OptionButton
var machine_button: Button
var pressure_choice: OptionButton


func _ready() -> void:
	super._ready()
	_stabilize_layout()
	mode.hide()
	%Export.text = "Export service comparison (JSON)"
	%Start.text = "Start short shift"
	equipment_choice = OptionButton.new()
	equipment_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_choice.clip_text = true
	equipment_choice.custom_minimum_size.x = 280
	equipment_choice.add_item("Starter / 4 glasses")
	equipment_choice.add_item("Rack / 6 glasses")
	equipment_choice.add_item("Machine / 4 glasses")
	equipment_choice.add_item("Rack + machine / 6 glasses")
	$Margin/Layout/Toolbar.add_child(equipment_choice)
	$Margin/Layout/Toolbar.move_child(equipment_choice, 0)
	equipment_choice.item_selected.connect(_equipment_changed)
	pressure_choice = OptionButton.new()
	pressure_choice.clip_text = true
	pressure_choice.custom_minimum_size.x = 180
	for preset: Dictionary in Shift.PRESSURES:
		pressure_choice.add_item(preset.label)
	$Margin/Layout/Toolbar.add_child(pressure_choice)
	$Margin/Layout/Toolbar.move_child(pressure_choice, 1)
	pressure_choice.item_selected.connect(_equipment_changed)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	$Margin/Layout.add_child(row)
	$Margin/Layout.move_child(row, 3)
	for spot: int in range(3):
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 68
		button.clip_text = true
		button.toggle_mode = true
		button.pressed.connect(_select_guest.bind(spot))
		row.add_child(button)
		guest_buttons.append(button)
	glass_status = Label.new()
	%Ingredients.add_child(glass_status)
	wash_button = Button.new()
	wash_button.clip_text = true
	wash_button.text = "Wash one glass / 3s"
	wash_button.custom_minimum_size.y = 42
	wash_button.pressed.connect(_wash)
	%Ingredients.add_child(wash_button)
	machine_button = Button.new()
	machine_button.clip_text = true
	machine_button.custom_minimum_size.y = 42
	machine_button.pressed.connect(_machine)
	%Ingredients.add_child(machine_button)
	feedback.text = "Start a short shift. Select a guest, make their drink, and wash returned glasses."
	_update()


func _stabilize_layout() -> void:
	# Reserve changing copy and gauge space so controls remain fixed targets.
	%Start.custom_minimum_size.x = 160
	%Pause.custom_minimum_size.x = 110
	for label: Label in [%Order, %Recipe, %TargetLabel, %PourHint, %Feedback, %Metrics]:
		label.add_theme_font_size_override("font_size", 16)
		label.max_lines_visible = 2
		label.custom_minimum_size.y = 50
	for label: Label in [%Order, %Recipe]:
		label.max_lines_visible = 1
		label.custom_minimum_size.y = 24
		label.clip_text = true
	for node: Node in find_children("*", "Button", true, false):
		var button := node as Button
		button.clip_text = true
	for button: Button in stations.values():
		button.custom_minimum_size.y = 44


func _start() -> void:
	if active or not content_valid:
		return
	shift = Shift.new(equipment_choice.selected, pressure_choice.selected)
	selected_spot = 0
	selected_guest_id = -1
	preparation_recipe = null
	super._start()
	shift.advance(0.01)
	_sync_selection()
	feedback.text = "First guest is here. Select glass, dock, hold to pour, then serve to the selected guest."
	_update()


func _process(delta: float) -> void:
	if not active or paused or confirmation.visible:
		return
	var previous_walkouts := shift.walkouts
	var previous_missed := shift.missed_arrivals
	var was_washing := shift.washing > 0
	var machine_before := shift.machine_glasses
	var remaining := delta
	while remaining > 0.000001 and active:
		var step := minf(remaining, 0.05)
		if not shift.hands_busy():
			super._process(step)
		shift.advance(step)
		_sync_selection()
		if shift.finished:
			break
		remaining -= step
	if was_washing and shift.washing == 0:
		feedback.text = "Glass washed. Clean supply updated; your preparation is kept."
	if machine_before > 0 and shift.machine_glasses == 0 and not shift.finished:
		feedback.text = "Dishwasher finished. Batch returned to clean supply."
	if shift.walkouts > previous_walkouts:
		feedback.text = "A guest left after waiting. Your drink is kept; select another compatible order or discard it."
	elif shift.missed_arrivals > previous_missed:
		feedback.text = "The counter was full and an arrival moved on. No extra penalty in this experiment."
	if shift.finished:
		_stop_pour()
		bench.clear_glass()
		docked_station = ""
		preparation_recipe = null
		active = false
		feedback.text = "Finished: %d served / %d walkouts / %d missed / %d at closing.\n%d sink washes / %d batches / %.1fs hands busy. Export before restarting to keep this comparison." % [
			shift.served, shift.walkouts, shift.missed_arrivals, shift.closing_unserved,
			shift.manual_washes, shift.machine_batches, shift.hands_busy_seconds,
		]
	_update()


func _can_act() -> bool:
	return super._can_act() and not shift.hands_busy()


func _select_glass() -> void:
	if not _can_act():
		return
	if bench.has_glass:
		super._select_glass()
		return
	var error := shift.select_glass()
	if not error.is_empty():
		feedback.text = error
		return
	var guest := _selected_guest()
	if not guest.is_empty() and guest.state == "waiting":
		preparation_recipe = RECIPES[int(guest.recipe)]
	super._select_glass()
	if preparation_recipe == null:
		feedback.text = "Glass ready. Select a waiting guest to set the recipe target, then dock at a station."


func _select_guest(spot: int) -> void:
	if not _can_act() or spot < 0 or spot >= shift.guests.size():
		return
	var guest: Dictionary = shift.guests[spot]
	if guest.is_empty() or guest.state != "waiting":
		feedback.text = "This spot has no waiting order. Your preparation is kept."
		return
	_stop_pour()
	selected_spot = spot
	selected_guest_id = int(guest.id)
	if bench.has_glass:
		preparation_recipe = RECIPES[int(guest.recipe)]
	feedback.text = "Selected spot %d. Your current drink is kept." % (spot + 1)
	_update()


func _current_recipe() -> Recipe:
	if preparation_recipe != null:
		return preparation_recipe
	var guest := _selected_guest()
	return RECIPES[int(guest.recipe)] if not guest.is_empty() else RECIPES[0]


func _selected_guest() -> Dictionary:
	if selected_spot < 0 or selected_spot >= shift.guests.size():
		return {}
	var guest: Dictionary = shift.guests[selected_spot]
	if guest.is_empty() or int(guest.id) != selected_guest_id:
		return {}
	return guest


func _sync_selection() -> void:
	var guest := _selected_guest()
	if not guest.is_empty() and guest.state == "waiting":
		return
	var had_selection := selected_guest_id != -1
	selected_spot = -1
	selected_guest_id = -1
	if had_selection:
		_stop_pour()
	# Never change a prepared drink's reference because a spot was reused.
	if bench.has_glass and preparation_recipe != null:
		return
	for spot: int in range(shift.guests.size()):
		guest = shift.guests[spot]
		if not guest.is_empty() and guest.state == "waiting":
			selected_spot = spot
			selected_guest_id = int(guest.id)
			if bench.has_glass:
				preparation_recipe = RECIPES[int(guest.recipe)]
			return


func _serve() -> void:
	if not _can_act():
		return
	_stop_pour()
	var guest := _selected_guest()
	if guest.is_empty() or guest.state != "waiting":
		feedback.text = "Select a guest who is waiting for a drink. Your preparation is kept."
		return
	var error := bench.check_recipe(_current_recipe().quantities(), TARGET_TOLERANCE)
	if error.is_empty():
		error = shift.serve(selected_spot)
	if not error.is_empty():
		trial_errors += 1
		feedback.text = "Not served. " + error
	else:
		bench.clear_glass()
		docked_station = ""
		preparation_recipe = null
		_sync_selection()
		feedback.text = "Served! The glass returns dirty after this guest finishes."
	_update()


func _discard() -> void:
	var error := shift.discard()
	if not error.is_empty():
		feedback.text = error
		return
	super._discard()
	preparation_recipe = null
	_sync_selection()
	_update()
	feedback.text = "Discarded. Glass moved to dirty; wash it before reusing."


func _wash() -> void:
	if not _can_act():
		return
	_stop_pour()
	var error := shift.start_wash()
	feedback.text = error if not error.is_empty() else "Washing one glass. Guests keep waiting; your drink stays on the counter."
	_update()


func _machine() -> void:
	if not _can_act():
		return
	_stop_pour()
	var error := shift.start_machine()
	feedback.text = error if not error.is_empty() else "Loading batch / 1.5s. Then the 8s cycle runs while you serve."
	_update()


func _equipment_changed(_index: int) -> void:
	if active:
		return
	feedback.text = "Next shift setup selected. Compare equipment within the same pressure level. No purchase costs."
	_update()


func _export() -> void:
	if not shift.finished:
		return
	var folder := "user://service_comparisons"
	var error := DirAccess.make_dir_recursive_absolute(folder)
	if error != OK:
		feedback.text = "Export failed: cannot create comparison folder (%s)." % error_string(error)
		push_error(feedback.text)
		return
	var summary := shift.comparison_summary()
	var path := "%s/%s-%s-%s.json" % [folder, summary.equipment, summary.pressure, Time.get_unix_time_from_system()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		feedback.text = "Export failed: %s." % error_string(FileAccess.get_open_error())
		push_error(feedback.text)
		return
	summary["schema_version"] = 1
	summary["experiment"] = "service_equipment_comparison"
	summary["incorrect_serve_attempts"] = trial_errors
	summary["discards"] = trial_discards
	summary["arrival_times_seconds"] = shift.arrival_times
	summary["recipe_sequence"] = shift.recipe_sequence
	summary["recipe_ids"] = RECIPES.map(func(recipe: Recipe) -> String: return recipe.id)
	summary["target_tolerance_units"] = TARGET_TOLERANCE
	summary["seconds_per_pour_unit"] = MeteredPour.SECONDS_PER_UNIT
	summary["timing"] = {
		"open": shift.open_seconds, "closing_grace": Shift.GRACE_SECONDS,
		"patience": Shift.PATIENCE_SECONDS, "drinking": Shift.DRINK_SECONDS,
		"sink": Shift.WASH_SECONDS, "machine_load": Shift.DISHWASHER_LOAD_SECONDS,
		"machine_cycle": Shift.DISHWASHER_CYCLE_SECONDS,
		"machine_capacity": Shift.DISHWASHER_CAPACITY,
	}
	summary["measurement_note"] = "Simulation time excludes pause, focus loss and discard dialogs. Glass-blocked means waiting order, no clean glass and no preparation; not observed player inactivity. Machine-blocked is a subset, not a second cost."
	file.store_string(JSON.stringify(summary, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		feedback.text = "Export failed while writing: %s." % error_string(write_error)
		push_error(feedback.text)
		return
	feedback.text = "Exported: " + ProjectSettings.globalize_path(path)


func _update() -> void:
	super._update()
	if wash_button == null:
		return
	contents_label.text = contents_label.text.replace("\n", " / ")
	contents_label.custom_minimum_size.y = 24
	contents_label.max_lines_visible = 1
	contents_label.clip_text = true
	var can_act := _can_act()
	equipment_choice.disabled = active
	pressure_choice.disabled = active
	%Export.disabled = not shift.finished
	machine_button.disabled = not shift.has_dishwasher or not can_act or shift.machine_glasses > 0 or shift.dirty == 0
	machine_button.text = "Load up to 2 / Start batch" if shift.has_dishwasher else "Dishwasher / Not in this setup"
	if shift.machine_load_left > 0.0:
		machine_button.text = "Loading %d / %.1fs left" % [shift.machine_glasses, shift.machine_load_left]
	elif shift.machine_glasses > 0:
		machine_button.text = "Running %d / %.1fs left" % [shift.machine_glasses, shift.machine_cycle_left]
	wash_button.disabled = not can_act or shift.dirty == 0
	wash_button.text = "Washing / %.1fs left" % shift.wash_left if shift.washing > 0 else "Wash one glass / 3s"
	var held := shift.total_glasses() - shift.clean - shift.dirty - shift.preparing - shift.washing - shift.machine_glasses
	glass_status.text = "Glasses: %d clean / %d dirty\n%d preparing / %d with guests\n%d sink / %d machine / %d owned" % [
		shift.clean, shift.dirty, shift.preparing, held, shift.washing, shift.machine_glasses, shift.owned,
	]
	%Glass.disabled = not can_act or (not bench.has_glass and shift.clean == 0)
	if not bench.has_glass and shift.clean == 0:
		%Glass.text = "No clean glasses / wash at sink"
	for spot: int in range(guest_buttons.size()):
		var guest: Dictionary = shift.guests[spot]
		var button := guest_buttons[spot]
		button.disabled = not can_act or guest.is_empty() or guest.get("state") != "waiting"
		button.set_pressed_no_signal(selected_spot == spot and not guest.is_empty() and guest.get("state") == "waiting")
		var prefix := "> " if selected_spot == spot else ""
		if guest.is_empty():
			button.text = "%sSpot %d / Empty" % [prefix, spot + 1]
		elif guest.state == "drinking":
			button.text = "%sGuest %d / Enjoying drink\nGlass returns in %.0fs" % [prefix, guest.id, ceilf(guest.remaining)]
		else:
			button.text = "%sGuest %d / %s\n%s / %.0fs" % [
				prefix, guest.id, RECIPES[int(guest.recipe)].display_name,
				"Needs attention" if guest.remaining < 20.0 else "Waiting comfortably",
				ceilf(guest.remaining),
			]
	%Start.text = "Try another shift" if shift.finished else "Start short shift"
	var selected := _selected_guest()
	var waiting: bool = not selected.is_empty() and selected.state == "waiting"
	%Serve.disabled = not can_act or not waiting or not bench.has_glass
	%Serve.text = "Serve to spot %d" % (selected_spot + 1) if waiting else "Serve / Select a waiting guest"
	for station: Button in stations.values():
		station.disabled = not can_act or not bench.has_glass
		station.tooltip_text = "Select a clean glass before docking." if not bench.has_glass else "Tap to dock; hold the docked station to pour."
	if shift.washing > 0:
		%PourHint.text = "Hands busy washing. Your glass, liquid, and recipe target are kept. Pause is still available."
	elif shift.machine_load_left > 0.0:
		%PourHint.text = "Hands busy loading. When loading finishes you can pour while the machine runs."
	if not active:
		order_label.text = "Shift complete" if shift.finished else "Ready for a short shift?"
		recipe_label.text = "Compare four equipment setups at baseline or busier demand. No purchases or staff yet."
	elif selected.is_empty() or selected.state != "waiting":
		order_label.text = "Preparing: " + preparation_recipe.display_name if preparation_recipe != null else "No waiting guest selected"
		recipe_label.text = preparation_recipe.description if preparation_recipe != null else "Select a waiting guest when one arrives. You can wash or select a clean glass now."
	else:
		order_label.text = "Spot %d / %s" % [selected_spot + 1, _current_recipe().display_name]
	var phase := "Closing / %.0fs grace left" % maxf(0.0, shift.open_seconds + Shift.GRACE_SECONDS - shift.elapsed) if shift.elapsed >= shift.open_seconds else "Open / %.0fs until closing" % maxf(0.0, shift.open_seconds - shift.elapsed)
	metrics.text = "%s | Served %d | Walkouts %d | Missed %d | Errors %d | Discards %d\nNo clean supply %.1fs | Glass-blocked %.1fs (machine running %.1fs)" % [
		phase, shift.served, shift.walkouts, shift.missed_arrivals, trial_errors, trial_discards,
		shift.no_clean_seconds, shift.glass_blocked_seconds, shift.blocked_during_machine_seconds,
	]


func _update_target() -> void:
	var guest := _selected_guest()
	var has_reference: bool = preparation_recipe != null or (not guest.is_empty() and guest.state == "waiting")
	if has_reference:
		super._update_target()
	else:
		%TargetLabel.text = "Glass ready. Select a waiting guest for recipe targets." if bench.has_glass else "Select a waiting guest, then a clean glass."
	%TargetGauge.visible = bench.has_glass and has_reference and not docked_station.is_empty()
	if preparation_recipe != null and guest.is_empty():
		%TargetLabel.text += " / Recipe kept; select a waiting guest before serving."
