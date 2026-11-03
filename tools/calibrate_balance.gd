extends SceneTree

## Calibrates the balance worksheet from saved lab runs.
##   -- --collect --player=NAME  copy this computer's lab runs into playtests/NAME/
##   -- --write                  save measured values into content/balance/worksheet.tres
## With no options it only prints what it would change.

const Calibration = preload("res://scripts/systems/playtest_calibration.gd")
const WORKSHEET := "res://content/balance/worksheet.tres"
const PLAYTESTS := "res://playtests"
const LOCAL_DIRS: Array[String] = ["user://interaction_runs", "user://service_comparisons"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var player := "owner"
	for arg: String in args:
		if arg.begins_with("--player="):
			player = arg.trim_prefix("--player=").to_lower().validate_filename()
	if args.has("--collect"):
		_collect(player)
	var runs := Calibration.load_runs([PLAYTESTS])
	for path: String in runs.skipped:
		print("Skipped (not a lab run): ", path)
	var m := Calibration.measure(runs)
	print("Runs: %d station (%d trials), %d service" % [m.station_runs, m.station_trials, m.service_runs])
	var worksheet: Resource = load(WORKSHEET)
	var changes := Calibration.apply(worksheet, m)
	if m.has("learning_mistakes_per_order"):
		print("Learning mistakes per order (not applied, sample too small): %.2f" % m.learning_mistakes_per_order)
	if m.has("service_check"):
		var check: Dictionary = m.service_check
		print("Service run: %d of %d served in %.0f s (%.1f s per serve), %d turned away (seats full), %d walkouts" % [
			check.served, check.arrivals, check.elapsed_seconds, check.seconds_per_serve, check.missed_arrivals, check.walkouts])
	if changes.is_empty():
		print("Worksheet already matches the measurements.")
	for change: String in changes:
		print("  ", change)
	if args.has("--write") and not changes.is_empty():
		var error := ResourceSaver.save(worksheet, WORKSHEET)
		if error != OK:
			printerr("Cannot save worksheet: ", error_string(error))
			quit(1)
			return
		print("Saved ", WORKSHEET, ". Run tools/balance_report.gd to see the effect.")
	quit(0)


func _collect(player: String) -> void:
	var dest := PLAYTESTS.path_join(player)
	DirAccess.make_dir_recursive_absolute(dest)
	var copied: int = 0
	for dir: String in LOCAL_DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() == "json" and not FileAccess.file_exists(dest.path_join(file)):
				DirAccess.copy_absolute(dir.path_join(file), dest.path_join(file))
				copied += 1
	print("Collected %d new run(s) into %s" % [copied, dest])
