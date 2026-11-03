extends Control

const Recipe = preload("res://scripts/content/drink_recipe.gd")
const Workbench = preload("res://scripts/systems/drink_workbench.gd")
const MeteredPour = preload("res://scripts/systems/metered_pour.gd")
const Station = preload("res://scripts/ui/pour_station.gd")
const RECIPES: Array[Resource] = [
	preload("res://content/drinks/draft_beer.tres"),
	preload("res://content/drinks/rum_cola.tres"),
]
const TARGET: int = 10
const ORDER_SEQUENCE: Array[int] = [0, 1, 1, 0, 0, 1, 0, 1, 1, 0]
const EXPERIMENTS: Array[String] = ["A_click", "B_hold", "C_station"]
const TARGET_TOLERANCE: float = 0.25

var bench := Workbench.new()
var pour := MeteredPour.new()
var active: bool = false
var paused: bool = false
var records: Array[Dictionary] = []
var trial_seconds: float = 0.0
var trial_errors: int = 0
var trial_discards: int = 0
var trial_units: float = 0.0
var trial_hold_units: float = 0.0
var docked_station: String = ""
var station_pouring: bool = false
var trial_drags: int = 0
var trial_taps: int = 0
var exported: bool = false
var run_mode: int = 0
var content_valid: bool = false
var buttons: Array[Button] = []
var stations: Dictionary = {}
var measured_buttons: Array[Button] = []

@onready var mode: OptionButton = %Mode
@onready var order_label: Label = %Order
@onready var recipe_label: Label = %Recipe
@onready var contents_label: Label = %Contents
@onready var feedback: Label = %Feedback
@onready var metrics: Label = %Metrics
@onready var confirmation: ConfirmationDialog = %DiscardConfirmation


func _ready() -> void:
	mode.add_item("A / Click measured portions")
	mode.add_item("B / Hold to pour")
	mode.add_item("C / Dock glass + timed pour")
	mode.select(2)
	%Start.pressed.connect(_start)
	%Pause.pressed.connect(_toggle_pause)
	%Glass.pressed.connect(_select_glass)
	%Serve.pressed.connect(_serve)
	%Discard.pressed.connect(_request_discard)
	%Export.pressed.connect(_export)
	confirmation.confirmed.connect(_discard)
	confirmation.visibility_changed.connect(_confirmation_changed)
	mode.item_selected.connect(_mode_changed)
	for ingredient: String in Workbench.INGREDIENTS:
		var row := HBoxContainer.new()
		%Ingredients.add_child(row)
		var hold := Station.new()
		hold.text = ingredient.capitalize()
		hold.custom_minimum_size = Vector2(0, 52)
		hold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hold.button_down.connect(_ingredient_down.bind(ingredient))
		hold.button_up.connect(_stop_pour)
		hold.mouse_exited.connect(_stop_pour)
		hold.glass_docked.connect(_dock.bind(ingredient, true))
		row.add_child(hold)
		buttons.append(hold)
		stations[ingredient] = hold
		var measured := Button.new()
		measured.text = "+1"
		measured.tooltip_text = "Add one measured unit of %s (both modes)." % ingredient
		measured.custom_minimum_size = Vector2(54, 52)
		measured.pressed.connect(_add_unit.bind(ingredient, false))
		row.add_child(measured)
		buttons.append(measured)
		measured_buttons.append(measured)
	var errors := PackedStringArray()
	var ids: Array[String] = []
	for recipe: Recipe in RECIPES:
		errors.append_array(recipe.validation_errors())
		if recipe.id in ids:
			errors.append("Duplicate recipe ID: %s" % recipe.id)
		ids.append(recipe.id)
	if not errors.is_empty():
		feedback.text = "Content validation failed: " + " ".join(errors)
		push_error(feedback.text)
	else:
		content_valid = true
	_update()


func _process(delta: float) -> void:
	if not active or paused or confirmation.visible:
		return
	trial_seconds += delta
	if station_pouring:
		_add_continuous(delta / MeteredPour.SECONDS_PER_UNIT)
	if not pour.ingredient.is_empty():
		var ingredient := pour.ingredient
		var units := pour.advance(delta)
		for unit: int in range(units):
			_add_unit(ingredient, true)
	if mode.selected != 2:
		%PourProgress.value = pour.progress() * 100.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if confirmation.visible:
			return
		_toggle_pause()
	if event is InputEventMouseButton and not event.pressed:
		_stop_pour()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and not is_queued_for_deletion():
		_stop_pour()
		if active and not paused:
			_toggle_pause()


func _mode_changed(_index: int) -> void:
	_stop_pour()
	_update()


func _start() -> void:
	if not content_valid or active or (not records.is_empty() and not exported):
		return
	records.clear()
	bench.clear_glass()
	_stop_pour()
	docked_station = ""
	active = true
	paused = false
	exported = false
	run_mode = mode.selected
	_reset_trial()
	feedback.text = "Select a glass, drag or tap to dock at a station, then hold the station to pour." if run_mode == 2 else "Select a glass. Make the requested drink, then serve. There is no patience timer."
	_update()


func _reset_trial() -> void:
	trial_seconds = 0.0
	trial_errors = 0
	trial_discards = 0
	trial_units = 0
	trial_hold_units = 0
	trial_drags = 0
	trial_taps = 0


func _can_act() -> bool:
	return active and not paused and not confirmation.visible


func _select_glass() -> void:
	if not _can_act():
		return
	if mode.selected == 2 and bench.has_glass:
		feedback.text = "Drag this glass to a station, or tap a station to dock it."
	else:
		var error := bench.select_glass()
		feedback.text = error if not error.is_empty() else "Clean glass ready. Choose an ingredient station."
	_update()


func _ingredient_down(ingredient: String) -> void:
	if not _can_act():
		return
	if mode.selected == 0:
		_add_unit(ingredient, false)
	elif mode.selected == 2:
		if not bench.has_glass:
			feedback.text = "Select a clean glass before docking."
		elif docked_station != ingredient:
			_dock(ingredient, false)
		else:
			station_pouring = true
			feedback.text = "Pouring %s. Release inside the marked target band." % ingredient
	elif not bench.has_glass:
		feedback.text = "Select a clean glass before pouring."
	else:
		pour.start(ingredient)
		feedback.text = "Pouring %s. Release or move off the button to stop." % ingredient


func _dock(ingredient: String, from_drag: bool) -> void:
	if not _can_act() or not bench.has_glass:
		return
	_stop_pour()
	docked_station = ingredient
	if from_drag:
		trial_drags += 1
	else:
		trial_taps += 1
	feedback.text = "Glass docked at %s. Hold this station to pour; release preserves the fill." % ingredient
	_update()


func _add_continuous(amount: float) -> void:
	var error := bench.add_amount(docked_station, amount)
	if not error.is_empty():
		feedback.text = error
		_stop_pour()
		return
	trial_units += amount
	trial_hold_units += amount
	_update()


func _add_unit(ingredient: String, from_hold: bool) -> void:
	if not _can_act():
		return
	var error := bench.add_unit(ingredient)
	if not error.is_empty():
		feedback.text = error
		_stop_pour()
	else:
		trial_units += 1
		if from_hold:
			trial_hold_units += 1
		feedback.text = "Added one %s." % ingredient
	_update()


func _stop_pour() -> void:
	var was_station_pouring := station_pouring
	pour.stop()
	station_pouring = false
	if is_node_ready() and not is_queued_for_deletion():
		%PourProgress.value = 0.0
		if was_station_pouring:
			feedback.text = "Pour stopped. Fill kept. Hold the docked station to resume, or move the glass."


func _confirmation_changed() -> void:
	_stop_pour()
	_update()


func _serve() -> void:
	if not _can_act():
		return
	_stop_pour()
	var recipe := _current_recipe()
	var error := bench.check_recipe(recipe.quantities(), TARGET_TOLERANCE if mode.selected == 2 else 0.0)
	if not error.is_empty():
		trial_errors += 1
		feedback.text = "Not served. " + error
	else:
		records.append({
			"recipe_id": recipe.id,
			"seconds": snappedf(trial_seconds, 0.01),
			"incorrect_serve_attempts": trial_errors,
			"discards": trial_discards,
			"units_added": trial_units,
			"units_from_hold": trial_hold_units,
			"station_drags": trial_drags,
			"station_taps": trial_taps,
			"served_contents": bench.contents.duplicate(),
		})
		bench.clear_glass()
		docked_station = ""
		if records.size() == TARGET:
			active = false
			feedback.text = "Run complete. Export before starting another run. Note what felt satisfying or repetitive."
		else:
			_reset_trial()
			feedback.text = "Served correctly. Test glass returned instantly; select it for the next order."
	_update()


func _request_discard() -> void:
	if not _can_act():
		return
	_stop_pour()
	if bench.contents.is_empty():
		_discard()
	else:
		confirmation.popup_centered()


func _discard() -> void:
	_stop_pour()
	bench.clear_glass()
	docked_station = ""
	trial_discards += 1
	feedback.text = "Drink discarded. Select a glass to retry the same order."
	_update()


func _toggle_pause() -> void:
	if not active:
		return
	_stop_pour()
	paused = not paused
	feedback.text = "Paused. Timing and pouring stopped. Resume with Escape or the pause button." if paused else "Resumed. Select an ingredient to continue."
	_update()


func _export() -> void:
	if records.size() != TARGET:
		return
	var folder := "user://interaction_runs"
	var error := DirAccess.make_dir_recursive_absolute(folder)
	if error != OK:
		feedback.text = "Export failed: cannot create results folder (%s)." % error_string(error)
		push_error(feedback.text)
		return
	var path := "%s/%s-%s.json" % [folder, EXPERIMENTS[run_mode], Time.get_unix_time_from_system()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		feedback.text = "Export failed: %s." % error_string(FileAccess.get_open_error())
		push_error(feedback.text)
		return
	file.store_string(JSON.stringify({
		"schema_version": 2,
		"experiment": EXPERIMENTS[run_mode],
		"order_sequence": ORDER_SEQUENCE,
		"recipe_ids": RECIPES.map(func(recipe: Recipe) -> String: return recipe.id),
		"target_tolerance_units": TARGET_TOLERANCE if run_mode == 2 else 0.0,
		"godot_version": Engine.get_version_info().string,
		"seconds_per_hold_unit": MeteredPour.SECONDS_PER_UNIT,
		"trials": records,
		"timing_note": "Includes reading and recovery; excludes pause, focus loss and discard confirmation.",
	}, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		feedback.text = "Export failed while writing: %s." % error_string(write_error)
		push_error(feedback.text)
		return
	exported = true
	feedback.text = "Exported: " + ProjectSettings.globalize_path(path)
	_update()


func _update() -> void:
	var ready_for_actions := _can_act()
	mode.disabled = active or (not records.is_empty() and not exported)
	%Start.disabled = not content_valid or active or (not records.is_empty() and not exported)
	%Pause.disabled = not active
	%Pause.text = "Resume / Esc" if paused else "Pause / Esc"
	%Glass.disabled = not ready_for_actions or (bench.has_glass and mode.selected != 2)
	%Glass.drag_enabled = ready_for_actions and bench.has_glass and mode.selected == 2
	%Glass.text = "GLASS / Drag to station (or tap station)" if bench.has_glass and mode.selected == 2 else "Select clean glass"
	%Serve.disabled = not ready_for_actions
	%Discard.disabled = not ready_for_actions or not bench.has_glass
	%Export.disabled = records.size() != TARGET
	for button: Button in buttons:
		button.disabled = not ready_for_actions
	for ingredient: String in stations:
		var station: Button = stations[ingredient]
		station.docking_enabled = ready_for_actions and bench.has_glass and mode.selected == 2
		station.text = ingredient.capitalize() + (" / GLASS HERE - hold to pour" if docked_station == ingredient and mode.selected == 2 else " / Dock glass" if mode.selected == 2 else "")
	for button: Button in measured_buttons:
		button.visible = mode.selected != 2
	%PourProgress.visible = mode.selected != 2
	%TargetGauge.visible = mode.selected == 2
	%TargetGaugeSlot.visible = mode.selected == 2
	%TargetLabel.visible = mode.selected == 2
	%PourHint.text = "A: ingredient buttons and +1 add one unit." if mode.selected == 0 else "B: hold an ingredient for 0.65s per unit. +1 is the accessible alternative."
	if mode.selected == 2:
		%PourHint.text = "Drag or tap to dock. Hold station to pour; release pauses fill. Stop inside the target band. No automatic stop."
	if active:
		var recipe := _current_recipe()
		order_label.text = "Order %d / %d: %s" % [records.size() + 1, TARGET, recipe.display_name]
		recipe_label.text = recipe.description
	elif records.size() == TARGET:
		order_label.text = "Completed all ten orders."
		recipe_label.text = "Export, take notes, then switch mode. Try the opposite mode first with the next tester."
	var parts := PackedStringArray()
	for ingredient: String in Workbench.INGREDIENTS:
		parts.append("%s: %.2f" % [ingredient.capitalize(), bench.contents.get(ingredient, 0)])
	contents_label.text = "\n".join(parts) if bench.has_glass else "No glass selected."
	_update_target()
	var seconds := 0.0
	var errors := 0
	var discards := 0
	for record: Dictionary in records:
		seconds += float(record.seconds)
		errors += int(record.incorrect_serve_attempts)
		discards += int(record.discards)
	metrics.text = "%d / %d served | Completed-trial time: %.1fs | Incorrect serves: %d | Discards: %d" % [records.size(), TARGET, seconds, errors, discards]


func _current_recipe() -> Recipe:
	return RECIPES[ORDER_SEQUENCE[mini(records.size(), TARGET - 1)]]


func _update_target() -> void:
	var amount := float(bench.contents.get(docked_station, 0.0))
	var target := float(_current_recipe().quantities().get(docked_station, 0.0))
	%TargetGauge.amount = amount
	%TargetGauge.target = target
	%TargetGauge.tolerance = TARGET_TOLERANCE
	%TargetGauge.queue_redraw()
	if docked_station.is_empty():
		%TargetLabel.text = "Select a glass, then drag or tap to dock it at a station."
	elif target == 0.0:
		%TargetLabel.text = "%s: %.2f / Not in this recipe. Do not pour here." % [docked_station.capitalize(), amount]
	else:
		var status := "Keep pouring"
		if amount > target + TARGET_TOLERANCE + 0.00001:
			status = "Overpoured / discard to retry"
		elif amount >= target - TARGET_TOLERANCE - 0.00001:
			status = "In target / release now"
		%TargetLabel.text = "%s: %.2f / Target %.2f - %.2f / %s" % [
			docked_station.capitalize(), amount,
			target - TARGET_TOLERANCE, target + TARGET_TOLERANCE, status,
		]
