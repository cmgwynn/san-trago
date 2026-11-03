extends SceneTree

const Workbench = preload("res://scripts/systems/drink_workbench.gd")
const MeteredPour = preload("res://scripts/systems/metered_pour.gd")
const Lab = preload("res://scenes/bartending_lab.tscn")
const Recipe = preload("res://scripts/content/drink_recipe.gd")

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var bench := Workbench.new()
	expect(not bench.add_unit("rum").is_empty(), "pouring requires a glass")
	expect(not bench.check_recipe({"draft": 2}).is_empty(), "serving requires a glass")
	expect(bench.select_glass().is_empty(), "select a glass")
	expect(not bench.select_glass().is_empty(), "cannot duplicate selected glass")
	expect(not bench.add_unit("unknown").is_empty(), "unknown ingredients report errors")
	bench.add_unit("rum")
	expect(bench.check_recipe({"rum": 1, "cola": 2}) == "Add 2 cola.", "missing quantity is explicit")
	bench.add_unit("cola")
	bench.add_unit("cola")
	expect(bench.check_recipe({"rum": 1, "cola": 2}).is_empty(), "mixed drink validates")
	bench.add_unit("rum")
	expect(bench.check_recipe({"rum": 1, "cola": 2}).contains("Too much rum"), "excess requires recovery")
	expect(int(bench.contents.rum) == 2, "validation does not mutate contents")
	bench.clear_glass()
	expect(not bench.has_glass and bench.contents.is_empty(), "reset clears both state and contents")
	var invalid := Recipe.new()
	expect(invalid.validation_errors().size() == 3, "invalid content gives useful validation errors")
	invalid.id = "test"
	invalid.display_name = "Test drink"
	invalid.draft_units = -1
	expect(invalid.validation_errors().has("Ingredient quantities cannot be negative."), "negative recipe quantity rejected")
	var pour := MeteredPour.new()
	expect(pour.advance(10.0) == 0, "inactive pour adds nothing")
	pour.start("rum")
	expect(pour.advance(0.4) == 0, "holding less than threshold adds nothing")
	expect(pour.advance(0.3) == 1, "holding across threshold adds a unit")
	expect(pour.advance(1.3) == 2, "multiple thresholds preserve elapsed time")
	pour.stop()
	expect(pour.advance(2.0) == 0 and pour.progress() == 0, "release clears partial pour")

	var lab := Lab.instantiate()
	root.add_child(lab)
	await process_frame
	lab.set_process(false)
	lab.mode.select(0)
	lab._start()
	lab._select_glass()
	lab._add_unit("rum", false)
	lab._serve()
	expect(lab.records.is_empty() and lab.trial_errors == 1, "incorrect serving does not complete trial")
	expect(lab.bench.has_glass, "rejection preserves glass")
	lab._request_discard()
	expect(lab.confirmation.visible, "nonempty drink requires discard confirmation")
	lab.confirmation.hide()
	expect(lab.bench.has_glass, "canceling discard preserves drink")
	expect(not lab.get_node("%Serve").disabled, "canceling confirmation restores controls")
	lab._discard()
	expect(lab.trial_discards == 1, "discard is counted")
	lab._select_glass()
	lab._add_unit("draft", false)
	lab._add_unit("draft", false)
	lab._serve()
	expect(lab.records.size() == 1 and lab.records[0].discards == 1, "trial records recovery metrics")
	lab._toggle_pause()
	var before: float = lab.trial_seconds
	lab._process(2.0)
	lab._add_unit("rum", false)
	expect(lab.trial_seconds == before and not lab.bench.has_glass, "pause blocks timing and input")
	lab._toggle_pause()
	for trial: int in range(1, 10):
		lab._select_glass()
		if lab.ORDER_SEQUENCE[trial] == 0:
			lab._add_unit("draft", false)
			lab._add_unit("draft", false)
		else:
			lab._add_unit("rum", false)
			lab._add_unit("cola", false)
			lab._add_unit("cola", false)
		lab._serve()
	expect(lab.records.size() == 10 and not lab.active, "ten varied successful drinks finish run")
	expect(not lab.get_node("%Export").disabled, "completed run can export")
	lab._start()
	expect(lab.records.size() == 10, "new run cannot overwrite unexported results")
	lab._export()
	expect(lab.exported, "completed run exports successfully")
	var export_path: String = lab.feedback.text.trim_prefix("Exported: ")
	expect(FileAccess.file_exists(export_path), "exported file exists")
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(result is Dictionary, "export is valid JSON")
	if result is Dictionary:
		expect(result.trials.size() == 10 and result.experiment == "A_click", "export has exact trial shape and mode")
		expect(result.trials[0].incorrect_serve_attempts == 1, "export preserves recovery metrics")
	expect(DirAccess.remove_absolute(export_path) == OK, "test removes only its own export")
	lab.mode.select(1)
	lab._start()
	expect(lab.run_mode == 1 and lab.records.is_empty(), "new mode resets exported run")
	lab._select_glass()
	lab._ingredient_down("draft")
	lab._process(0.7)
	expect(lab.bench.contents.get("draft", 0) == 1, "hold mode wires timer to ingredient")
	expect(lab.trial_hold_units == 1, "hold mode usage is measurable")
	lab._stop_pour()
	lab._process(1.0)
	expect(lab.bench.contents.get("draft", 0) == 1, "release prevents further pouring")
	lab._ingredient_down("cola")
	lab._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(lab.paused and lab.pour.ingredient.is_empty(), "focus loss pauses and stops pouring")
	lab._toggle_pause()
	lab._add_unit("rum", false)
	expect(lab.bench.contents.get("rum", 0) == 1, "measured alternative works in hold mode")
	lab._request_discard()
	before = lab.trial_seconds
	lab._process(5.0)
	expect(lab.trial_seconds == before, "discard dialog excludes timing")
	lab.confirmation.hide()

	# Finish the original B run so switching modes follows the UI's lifecycle.
	lab._discard()
	for trial: int in range(10):
		lab._select_glass()
		if lab.ORDER_SEQUENCE[trial] == 0:
			lab._add_unit("draft", false)
			lab._add_unit("draft", false)
		else:
			lab._add_unit("rum", false)
			lab._add_unit("cola", false)
			lab._add_unit("cola", false)
		lab._serve()
	lab.exported = true
	lab.mode.select(2)
	lab._start()
	lab._select_glass()
	expect(lab.get_node("%Glass").drag_enabled, "selected glass supports dragging in C")
	var station: Button = lab.stations.draft
	var payload := {"kind": "lab_glass", "source": lab.get_node("%Glass")}
	expect(station._can_drop_data(Vector2.ZERO, payload), "station accepts the selected lab glass")
	expect(not station._can_drop_data(Vector2.ZERO, {"kind": "other"}), "station rejects foreign payload")
	station._drop_data(Vector2.ZERO, payload)
	expect(lab.docked_station == "draft" and lab.trial_drags == 1, "drop docks glass without pouring")
	expect(not lab.station_pouring, "drop never starts a pour automatically")
	lab._ingredient_down("draft")
	lab._process(0.13)
	lab._stop_pour()
	var partial := float(lab.bench.contents.draft)
	expect(is_equal_approx(partial, 0.2), "C stores fractional liquid immediately")
	lab._process(1.0)
	expect(is_equal_approx(float(lab.bench.contents.draft), partial), "release preserves partial amount and stops flow")
	lab._ingredient_down("cola")
	expect(lab.docked_station == "cola" and not lab.station_pouring, "tap alternative docks without pouring")
	lab._ingredient_down("draft")
	expect(is_equal_approx(float(lab.bench.contents.draft), partial), "switching stations preserves each ingredient")
	lab._ingredient_down("draft")
	lab._process(1.04)
	lab._stop_pour()
	expect(is_equal_approx(float(lab.bench.contents.draft), 1.8), "resumed pour builds on prior partial fill")
	lab._serve()
	expect(lab.records.size() == 1, "inside lower target window serves successfully")
	expect(lab.records[0].station_drags == 1 and lab.records[0].station_taps == 2, "record docking methods separately")
	expect(is_equal_approx(float(lab.records[0].served_contents.draft), 1.8), "record actual fractional served quantities")
	expect(lab.docked_station.is_empty() and not lab.get_node("%Glass").drag_enabled, "service resets docking and drag state")
	lab._select_glass()
	lab._dock("rum", false)
	lab._ingredient_down("rum")
	lab._process(0.9)
	lab._stop_pour()
	lab._serve()
	expect(lab.records.size() == 1 and lab.feedback.text.contains("Too much rum"), "overpour rejected with explicit recovery")
	lab._ingredient_down("rum")
	lab._toggle_pause()
	var preserved: Dictionary = lab.bench.contents.duplicate()
	lab._process(2.0)
	expect(lab.bench.contents == preserved and not lab.station_pouring, "pause retains C fill without further pouring")
	expect(not station._can_drop_data(Vector2.ZERO, payload), "paused station rejects dragging")
	lab._toggle_pause()
	expect(not lab.station_pouring, "resume requires a fresh hold")
	lab._request_discard()
	lab.confirmation.hide()
	lab._discard()
	expect(lab.docked_station.is_empty() and lab.bench.contents.is_empty(), "discard clears all station fill")
	var continuous := Workbench.new()
	continuous.select_glass()
	expect(not continuous.add_amount("rum", -1.0).is_empty(), "negative amounts rejected")
	expect(not continuous.add_amount("rum", NAN).is_empty(), "nonfinite amounts rejected")
	continuous.add_amount("rum", 0.75)
	continuous.add_amount("cola", 2.25)
	expect(continuous.check_recipe({"rum": 1, "cola": 2}, 0.25).is_empty(), "both target boundaries included")
	continuous.add_amount("draft", 0.01)
	expect(continuous.check_recipe({"rum": 1, "cola": 2}, 0.25).contains("Too much draft"), "tolerance never permits wrong ingredients")
	continuous.clear_glass()
	continuous.select_glass()
	continuous.add_amount("draft", 1.74)
	expect(continuous.check_recipe({"draft": 2}, 0.25).contains("Add"), "below target window remains underfilled")
	continuous.add_amount("draft", 0.52)
	expect(continuous.check_recipe({"draft": 2}, 0.25).contains("Too much"), "above target window is overfilled")

	for trial: int in range(1, 10):
		lab._select_glass()
		var recipe: Recipe = lab._current_recipe()
		for ingredient: String in Workbench.INGREDIENTS:
			var amount := float(recipe.quantities()[ingredient])
			if amount > 0.0:
				lab._dock(ingredient, false)
				lab._ingredient_down(ingredient)
				lab._process(amount * MeteredPour.SECONDS_PER_UNIT)
				lab._stop_pour()
		lab._serve()
	expect(lab.records.size() == 10 and not lab.active, "C completes a full varied run")
	lab._export()
	export_path = lab.feedback.text.trim_prefix("Exported: ")
	result = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	expect(result is Dictionary and result.experiment == "C_station" and result.schema_version == 2, "C export identifies changed experiment and schema")
	if result is Dictionary:
		expect(result.target_tolerance_units == 0.25 and result.order_sequence.size() == 10, "export records tolerance and sequence")
	expect(DirAccess.remove_absolute(export_path) == OK, "C export test cleans up its own file")
	lab.exported = true
	lab._start()
	lab._select_glass()
	lab._dock("draft", false)
	lab._ingredient_down("draft")
	lab._process(0.5)
	lab._stop_pour()

	# Send pointer events through Godot's GUI, not only the docking callbacks.
	var token: Button = lab.get_node("%Glass")
	await process_frame
	await process_frame
	lab.paused = false
	lab._update()
	var origin := token.get_global_rect().get_center()
	var destination := station.get_global_rect().get_center()
	lab._dock("rum", false)
	var drags_before: int = lab.trial_drags
	_pointer_motion(origin, false)
	_pointer_button(origin, true)
	_pointer_motion(origin + Vector2(30, 0), true)
	await process_frame
	_pointer_motion(destination, true)
	await process_frame
	_pointer_button(destination, false)
	await process_frame
	expect(lab.trial_drags == drags_before + 1 and lab.docked_station == "draft", "Godot GUI drag routes token to station")
	expect(not lab.station_pouring, "GUI drop requires a new hold")
	var fill_before_hold: float = lab.bench.contents.draft
	_pointer_button(destination, true)
	lab._process(0.13)
	_pointer_button(destination, false)
	var released_fill: float = lab.bench.contents.draft
	expect(released_fill > fill_before_hold, "GUI hold actually adds liquid")
	lab._process(0.13)
	expect(is_equal_approx(float(lab.bench.contents.draft), released_fill), "GUI release stops continuous pour")

	for size: Vector2i in [Vector2i(1280, 800), Vector2i(1024, 768)]:
		root.size = size
		await process_frame
		await process_frame
		var layout := lab.get_node("Margin/Layout") as VBoxContainer
		expect(layout.get_global_rect().end.y <= lab.size.y, "workstation fits vertically at %s" % size)
		expect(layout.get_global_rect().end.x <= lab.size.x, "workstation fits horizontally at %s" % size)
	if "--capture" in OS.get_cmdline_user_args():
		root.size = Vector2i(1280, 800)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var capture_path := "user://bartending-lab-check.png"
		expect(image.save_png(capture_path) == OK, "native-rendered viewport capture saves")
		print("Visual check: ", ProjectSettings.globalize_path(capture_path))
	lab.queue_free()
	await process_frame
	print("%d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)


func _pointer_motion(position: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = position - root.get_mouse_position()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)


func _pointer_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)
