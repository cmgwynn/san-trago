extends RefCounted

## Turns saved lab runs into balance-worksheet values. Only the station mode (C)
## is used for prep time, since that's the chosen interaction. The first trials of
## each run count as "learning"; the rest count as "settled".

const LEARNING_TRIALS := 3
const STATION_EXPERIMENT := "C_station"
const SERVICE_EXPERIMENT := "service_equipment_comparison"


## Reads every .json file in the given folders (subfolders included).
static func load_runs(dirs: Array[String]) -> Dictionary:
	var runs := {"interaction": [], "service": [], "skipped": []}
	for dir: String in dirs:
		_collect(dir, runs)
	return runs


static func _collect(dir: String, runs: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), runs)
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() != "json":
			continue
		var path := dir.path_join(file)
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("experiment") == SERVICE_EXPERIMENT:
			runs.service.append(data)
		elif data is Dictionary and data.has("trials"):
			runs.interaction.append(data)
		else:
			runs.skipped.append(path)


## Measurements plus sample sizes. Missing measurements are left out, so applying
## a summary never overwrites a hypothesis with a guess.
static func measure(runs: Dictionary) -> Dictionary:
	var settled := {"draft_beer": [], "rum_cola": []}
	var learning: Array[float] = []
	var settled_all: Array[float] = []
	var trials: int = 0
	var learning_mistakes: int = 0
	var station_runs: int = 0
	for run: Dictionary in runs.interaction:
		if run.get("experiment") != STATION_EXPERIMENT:
			continue
		station_runs += 1
		var index: int = 0
		for trial: Dictionary in run.trials:
			var seconds := float(trial.seconds)
			trials += 1
			if index < LEARNING_TRIALS:
				learning.append(seconds)
				learning_mistakes += int(trial.get("discards", 0)) + int(trial.get("incorrect_serve_attempts", 0))
			else:
				settled_all.append(seconds)
				if settled.has(trial.recipe_id):
					settled[trial.recipe_id].append(seconds)
			index += 1
	var m := {"station_runs": station_runs, "station_trials": trials, "service_runs": runs.service.size()}
	if not settled.draft_beer.is_empty():
		m.beer_active_seconds = _mean(settled.draft_beer)
	if not settled.rum_cola.is_empty():
		m.mixed_active_seconds = _mean(settled.rum_cola)
	if not learning.is_empty() and not settled_all.is_empty():
		m.learning_time_multiplier = _mean(learning) / _mean(settled_all)
		m.learning_mistakes_per_order = float(learning_mistakes) / learning.size()
	var washes: int = 0
	var cleaning: float = 0.0
	for run: Dictionary in runs.service:
		washes += int(run.get("manual_washes_started", 0))
		cleaning += float(run.get("hands_busy_cleaning_seconds", 0.0))
	if washes > 0:
		m.manual_wash_seconds = cleaning / washes
	if not runs.service.is_empty():
		var run: Dictionary = runs.service[-1]
		m.guest_holds_glass_seconds = float(run.timing.drinking)
		var bought := 2 if String(run.equipment).contains("rack") else 0
		m.starting_glasses = int(run.owned_glasses) - bought
		m.service_check = {
			"served": int(run.served),
			"elapsed_seconds": float(run.elapsed_seconds),
			"seconds_per_serve": float(run.elapsed_seconds) / maxf(1.0, float(run.served)),
			"missed_arrivals": int(run.missed_arrivals),
			"walkouts": int(run.walkouts),
			"arrivals": int(run.scheduled_arrivals),
			"open_seconds": float(run.timing.open),
		}
	return m


## Writes measured values into the worksheet and returns a line per change.
static func apply(a: Resource, m: Dictionary) -> PackedStringArray:
	var changes := PackedStringArray()
	for field: String in ["beer_active_seconds", "mixed_active_seconds", "learning_time_multiplier", "manual_wash_seconds", "guest_holds_glass_seconds", "starting_glasses"]:
		if not m.has(field):
			continue
		var value: Variant = int(m[field]) if field == "starting_glasses" else snappedf(m[field], 0.01)
		if a.get(field) != value:
			changes.append("%s: %s -> %s" % [field, a.get(field), value])
			a.set(field, value)
	return changes


static func _mean(values: Array) -> float:
	var total := 0.0
	for value: float in values:
		total += value
	return total / values.size()
