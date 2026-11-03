extends SceneTree

## Playtest calibration: hand-checked measurements from synthetic runs, and the
## shipped worksheet staying in sync with the collected playtests.

const Calibration = preload("res://scripts/systems/playtest_calibration.gd")
const Assumptions = preload("res://scripts/content/balance_assumptions.gd")
const PROBE := "user://calibration_probe"

var checks: int = 0
var failures: int = 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	_synthetic()
	_files()
	_shipped_worksheet()
	print("Calibration checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _trial(recipe: String, seconds: float, mistakes: int = 0) -> Dictionary:
	return {"recipe_id": recipe, "seconds": seconds, "discards": 0, "incorrect_serve_attempts": mistakes}


func _station_run() -> Dictionary:
	# Learning: 12, 9, 9 (mean 10). Settled: draft 4 and 6, rum_cola 5 and 5 (mean 5).
	return {"experiment": "C_station", "trials": [
		_trial("draft_beer", 12.0, 1), _trial("rum_cola", 9.0), _trial("rum_cola", 9.0, 2),
		_trial("draft_beer", 4.0), _trial("rum_cola", 5.0), _trial("draft_beer", 6.0), _trial("rum_cola", 5.0),
	]}


func _service_run() -> Dictionary:
	return {
		"experiment": "service_equipment_comparison", "equipment": "rack", "owned_glasses": 6,
		"manual_washes_started": 4, "hands_busy_cleaning_seconds": 14.0, "served": 10,
		"elapsed_seconds": 100.0, "missed_arrivals": 2, "walkouts": 1, "scheduled_arrivals": 13,
		"timing": {"drinking": 9.0, "open": 120.0},
	}


func _synthetic() -> void:
	var click := {"experiment": "A_click", "trials": [_trial("draft_beer", 99.0)]}
	var m := Calibration.measure({"interaction": [_station_run(), click], "service": [_service_run()]})
	expect(m.station_runs == 1 and m.station_trials == 7, "only station-mode runs count")
	expect(is_equal_approx(m.beer_active_seconds, 5.0), "settled draft time is the mean after the learning trials")
	expect(is_equal_approx(m.mixed_active_seconds, 5.0), "settled mixed time")
	expect(is_equal_approx(m.learning_time_multiplier, 2.0), "learning multiplier is learning mean over settled mean")
	expect(is_equal_approx(m.learning_mistakes_per_order, 1.0), "learning mistakes per order")
	expect(is_equal_approx(m.manual_wash_seconds, 3.5), "wash time is cleaning seconds per wash")
	expect(m.starting_glasses == 4 and m.guest_holds_glass_seconds == 9.0, "a rack run implies two fewer starting glasses")
	expect(m.service_check.served == 10 and is_equal_approx(m.service_check.seconds_per_serve, 10.0), "service check reports throughput")

	var a := Assumptions.new()
	var changes := Calibration.apply(a, m)
	expect(changes.size() == 5, "five fields change (draft time already matches 5.0): %s" % [changes])
	expect(a.beer_active_seconds == 5.0 and a.learning_time_multiplier == 2.0 and a.starting_glasses == 4, "values land in the worksheet")
	expect(a.learning_waste_fraction == Assumptions.new().learning_waste_fraction, "waste stays a hypothesis")
	expect(Calibration.apply(a, m).is_empty(), "applying twice changes nothing")

	var empty := Calibration.measure({"interaction": [], "service": []})
	var untouched := Assumptions.new()
	expect(Calibration.apply(untouched, empty).is_empty(), "no runs means no changes, not guesses")


func _files() -> void:
	DirAccess.make_dir_recursive_absolute(PROBE + "/nested")
	var station := FileAccess.open(PROBE + "/station.json", FileAccess.WRITE)
	station.store_string(JSON.stringify(_station_run()))
	station.close()
	var service := FileAccess.open(PROBE + "/nested/service.json", FileAccess.WRITE)
	service.store_string(JSON.stringify(_service_run()))
	service.close()
	var junk := FileAccess.open(PROBE + "/notes.json", FileAccess.WRITE)
	junk.store_string("[1, 2]")
	junk.close()
	var runs := Calibration.load_runs([PROBE, "user://missing_folder"])
	expect(runs.interaction.size() == 1 and runs.service.size() == 1, "runs load from folders and subfolders")
	expect(runs.skipped.size() == 1, "files that aren't runs are skipped, not fatal")
	for path: String in [PROBE + "/nested/service.json", PROBE + "/station.json", PROBE + "/notes.json", PROBE + "/nested", PROBE]:
		DirAccess.remove_absolute(path)


func _shipped_worksheet() -> void:
	var m := Calibration.measure(Calibration.load_runs(["res://playtests"]))
	var worksheet: Resource = load("res://content/balance/worksheet.tres")
	var copy: Resource = worksheet.duplicate()
	var drift := Calibration.apply(copy, m)
	expect(drift.is_empty(), "worksheet matches the collected playtests; run tools/calibrate_balance.gd -- --write: %s" % [drift])
