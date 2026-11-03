extends RefCounted

const OWNED: int = 4
const OPEN_SECONDS: float = 120.0
const GRACE_SECONDS: float = 25.0
const PATIENCE_SECONDS: float = 60.0
const DRINK_SECONDS: float = 10.0
const WASH_SECONDS: float = 3.0
const DISHWASHER_CAPACITY: int = 2
const DISHWASHER_LOAD_SECONDS: float = 1.5
const DISHWASHER_CYCLE_SECONDS: float = 8.0
const ARRIVAL_TIMES: Array[float] = [0.0, 15.0, 32.0, 38.0, 64.0, 83.0, 89.0, 108.0]
const RECIPE_SEQUENCE: Array[int] = [0, 1, 1, 0, 1, 0, 0, 1]
const BUSY_ARRIVAL_TIMES: Array[float] = [0.0, 8.0, 16.0, 20.0, 24.0, 42.0, 52.0, 60.0, 64.0, 68.0, 86.0, 94.0, 102.0, 106.0, 110.0, 114.0]
const BUSY_RECIPE_SEQUENCE: Array[int] = [0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1]
## Proposed day ramp (balance worksheet, 2026-11-03): 4-minute shifts with small
## waves and recovery gaps. Day 3 waves match the worksheet rush (8 per minute).
const DAY_1_ARRIVALS: Array[float] = [0.0, 22.0, 48.0, 72.0, 96.0, 104.0, 135.0, 165.0, 195.0, 220.0]
const DAY_1_RECIPES: Array[int] = [0, 1, 0, 1, 1, 0, 0, 1, 0, 1]
const DAY_2_ARRIVALS: Array[float] = [0.0, 18.0, 38.0, 55.0, 62.0, 70.0, 100.0, 125.0, 145.0, 160.0, 167.0, 175.0, 210.0]
const DAY_2_RECIPES: Array[int] = [0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0]
const DAY_3_ARRIVALS: Array[float] = [0.0, 14.0, 30.0, 40.0, 48.0, 56.0, 64.0, 92.0, 110.0, 126.0, 140.0, 150.0, 158.0, 166.0, 174.0, 205.0, 225.0]
const DAY_3_RECIPES: Array[int] = [0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0]
## Pressure presets, in menu order. Indexes 0 and 1 keep earlier comparisons valid.
const PRESSURES: Array[Dictionary] = [
	{"id": "baseline", "label": "Baseline / 8 guests", "open": OPEN_SECONDS, "arrivals": ARRIVAL_TIMES, "recipes": RECIPE_SEQUENCE},
	{"id": "busier", "label": "Busier / 16 guests", "open": OPEN_SECONDS, "arrivals": BUSY_ARRIVAL_TIMES, "recipes": BUSY_RECIPE_SEQUENCE},
	{"id": "day_1", "label": "Day 1 / 10 guests", "open": 240.0, "arrivals": DAY_1_ARRIVALS, "recipes": DAY_1_RECIPES},
	{"id": "day_2", "label": "Day 2 / 13 guests", "open": 240.0, "arrivals": DAY_2_ARRIVALS, "recipes": DAY_2_RECIPES},
	{"id": "day_3", "label": "Day 3 / 17 guests", "open": 240.0, "arrivals": DAY_3_ARRIVALS, "recipes": DAY_3_RECIPES},
]

var guests: Array[Dictionary] = [{}, {}, {}]
var elapsed: float = 0.0
var clean: int = OWNED
var preparing: int = 0
var dirty: int = 0
var washing: int = 0
var wash_left: float = 0.0
var next_arrival: int = 0
var served: int = 0
var walkouts: int = 0
var missed_arrivals: int = 0
var closing_unserved: int = 0
var finished: bool = false
var owned: int = OWNED
var has_dishwasher: bool = false
var machine_glasses: int = 0
var machine_load_left: float = 0.0
var machine_cycle_left: float = 0.0
var manual_washes: int = 0
var machine_batches: int = 0
var hands_busy_seconds: float = 0.0
var equipment_preset: int = 0
var pressure_preset: int = 0
var open_seconds: float = OPEN_SECONDS
var arrival_times: Array[float] = []
var recipe_sequence: Array[int] = []
var no_clean_seconds: float = 0.0
var glass_blocked_seconds: float = 0.0
var blocked_during_machine_seconds: float = 0.0
var machine_running_seconds: float = 0.0


func _init(equipment: int = 0, pressure: int = 0) -> void:
	equipment_preset = equipment
	pressure_preset = pressure
	owned = OWNED + (2 if equipment == 1 or equipment == 3 else 0)
	clean = owned
	has_dishwasher = equipment == 2 or equipment == 3
	var preset: Dictionary = PRESSURES[pressure]
	open_seconds = preset.open
	arrival_times.assign(preset.arrivals)
	recipe_sequence.assign(preset.recipes)


func hands_busy() -> bool:
	return washing > 0 or machine_load_left > 0.0


func select_glass() -> String:
	if finished:
		return "Shift is over."
	if hands_busy():
		return "Hands busy cleaning or loading."
	if preparing > 0:
		return "A glass is already on the counter."
	if clean == 0:
		return "No clean glasses. Wash a dirty glass at the sink."
	clean -= 1
	preparing += 1
	return ""


func serve(spot: int) -> String:
	if finished:
		return "Shift is over."
	if hands_busy():
		return "Hands busy cleaning or loading."
	if spot < 0 or spot >= guests.size() or guests[spot].is_empty():
		return "Select a waiting guest."
	if guests[spot].state != "waiting":
		return "This guest already has a drink."
	if preparing == 0:
		return "Select a clean glass before serving."
	preparing -= 1
	guests[spot].state = "drinking"
	guests[spot].remaining = DRINK_SECONDS
	served += 1
	return ""


func discard() -> String:
	if finished or hands_busy():
		return "Cannot discard while closed or hands are busy."
	if preparing == 0:
		return "There is no glass to discard."
	preparing -= 1
	dirty += 1
	return ""


func start_wash() -> String:
	if finished:
		return "Shift is over."
	if washing > 0:
		return "Already washing one glass."
	if machine_load_left > 0.0:
		return "Finish loading the dishwasher first."
	if dirty == 0:
		return "No dirty glasses to wash."
	dirty -= 1
	washing = 1
	wash_left = WASH_SECONDS
	manual_washes += 1
	return ""


func start_machine() -> String:
	if finished:
		return "Shift is over."
	if not has_dishwasher:
		return "No dishwasher in this setup."
	if hands_busy():
		return "Hands busy cleaning or loading."
	if machine_glasses > 0:
		return "Dishwasher cycle is already active."
	if dirty == 0:
		return "No dirty glasses to load."
	machine_glasses = mini(dirty, DISHWASHER_CAPACITY)
	dirty -= machine_glasses
	machine_load_left = DISHWASHER_LOAD_SECONDS
	machine_cycle_left = DISHWASHER_CYCLE_SECONDS
	machine_batches += 1
	return ""


func advance(delta: float) -> void:
	# Small fixed slices keep arrivals and closing consistent under large frames.
	var remaining := delta
	while remaining > 0.000001 and not finished:
		var step := minf(remaining, 0.05)
		_tick(step)
		remaining -= step


func _tick(delta: float) -> void:
	elapsed += delta
	if clean == 0:
		no_clean_seconds += delta
		var waiting := false
		for guest: Dictionary in guests:
			if not guest.is_empty() and guest.state == "waiting":
				waiting = true
				break
		if preparing == 0 and waiting:
			glass_blocked_seconds += delta
			if machine_glasses > 0 and machine_load_left == 0.0:
				blocked_during_machine_seconds += delta
	if machine_glasses > 0 and machine_load_left == 0.0:
		machine_running_seconds += delta
	if hands_busy():
		hands_busy_seconds += delta
	if machine_load_left > 0.0:
		var loading := minf(delta, machine_load_left)
		machine_load_left = maxf(0.0, machine_load_left - loading)
		if machine_load_left < 0.000001:
			machine_load_left = 0.0
		machine_cycle_left = maxf(0.0, machine_cycle_left - (delta - loading))
	elif machine_glasses > 0:
		machine_cycle_left = maxf(0.0, machine_cycle_left - delta)
	if machine_glasses > 0 and machine_load_left == 0.0 and machine_cycle_left <= 0.000001:
		clean += machine_glasses
		machine_glasses = 0
		machine_cycle_left = 0.0
	if washing > 0:
		wash_left = maxf(0.0, wash_left - delta)
		if wash_left <= 0.000001:
			washing = 0
			clean += 1
	for spot: int in range(guests.size()):
		if guests[spot].is_empty():
			continue
		guests[spot].remaining -= delta
		if guests[spot].remaining <= 0.0:
			if guests[spot].state == "drinking":
				dirty += 1
			else:
				walkouts += 1
			guests[spot] = {}
	while next_arrival < arrival_times.size() and arrival_times[next_arrival] <= elapsed and elapsed < open_seconds:
		var available := -1
		for spot: int in range(guests.size()):
			if guests[spot].is_empty():
				available = spot
				break
		if available >= 0:
			guests[available] = {
				"id": next_arrival + 1,
				"recipe": recipe_sequence[next_arrival],
				"state": "waiting", "remaining": PATIENCE_SECONDS,
			}
		else:
			missed_arrivals += 1
		next_arrival += 1
	if elapsed >= open_seconds:
		var any_guest := false
		for guest: Dictionary in guests:
			any_guest = any_guest or not guest.is_empty()
		if not any_guest or elapsed >= open_seconds + GRACE_SECONDS:
			_finish()


func _finish() -> void:
	for spot: int in range(guests.size()):
		var guest := guests[spot]
		if not guest.is_empty():
			if guest.state == "drinking":
				dirty += 1
			else:
				closing_unserved += 1
		guests[spot] = {}
	dirty += preparing + washing + machine_glasses
	preparing = 0
	washing = 0
	wash_left = 0.0
	machine_glasses = 0
	machine_load_left = 0.0
	machine_cycle_left = 0.0
	finished = true


func total_glasses() -> int:
	var held := 0
	for guest: Dictionary in guests:
		if not guest.is_empty() and guest.state == "drinking":
			held += 1
	return clean + preparing + held + dirty + washing + machine_glasses


func comparison_summary() -> Dictionary:
	return {
		"equipment": ["starter", "rack", "dishwasher", "rack_and_dishwasher"][equipment_preset],
		"pressure": PRESSURES[pressure_preset].id,
		"owned_glasses": owned, "scheduled_arrivals": arrival_times.size(),
		"served": served, "walkouts": walkouts, "missed_arrivals": missed_arrivals,
		"closing_unserved": closing_unserved, "finished": finished,
		"elapsed_seconds": snappedf(elapsed, 0.01),
		"manual_washes_started": manual_washes, "machine_batches_started": machine_batches,
		"hands_busy_cleaning_seconds": snappedf(hands_busy_seconds, 0.01),
		"no_clean_supply_seconds": snappedf(no_clean_seconds, 0.01),
		"glass_blocked_seconds": snappedf(glass_blocked_seconds, 0.01),
		"glass_blocked_during_machine_seconds": snappedf(blocked_during_machine_seconds, 0.01),
		"machine_running_seconds": snappedf(machine_running_seconds, 0.01),
	}
