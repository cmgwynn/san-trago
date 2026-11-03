extends RefCounted

## A simple scripted bartender that plays the real service rules, for checking
## whether a day's schedule is comfortable. Prep times are the calibrated worksheet
## values; `overhead` covers picking a guest and moving between stations, which the
## service-run cross-check showed the model leaves out.
## It plays sensibly but not cleverly: one order at a time, most impatient guest
## first, washing when idle or out of glasses. Real players will differ.

const Shift = preload("res://scripts/systems/service_shift.gd")
const STEP := 0.05

var beer_seconds: float
var mixed_seconds: float
var overhead: float
## Extra discarded drinks per served drink (worksheet waste fraction). Mistakes are
## spread evenly, so runs are repeatable.
var waste: float


func _init(beer: float, mixed: float, speed: float = 1.0, overhead_seconds: float = 1.0, waste_fraction: float = 0.0) -> void:
	beer_seconds = beer * speed
	mixed_seconds = mixed * speed
	overhead = overhead_seconds
	waste = waste_fraction


## Plays one shift and returns its summary, plus how much of the open period the
## player spent working ("busy_ratio") and the longest stretch without a break.
func play(equipment: int, pressure: int) -> Dictionary:
	var shift := Shift.new(equipment, pressure)
	var target := -1
	var prep_left := 0.0
	var busy := 0.0
	var streak := 0.0
	var longest := 0.0
	var mistakes := 0.0
	var discards: int = 0
	while not shift.finished:
		var working := prep_left > 0.0 or shift.hands_busy()
		if prep_left > 0.0:
			prep_left -= STEP
			if prep_left <= 0.0:
				var spot := target if _waiting(shift, target) else _most_impatient(shift)
				mistakes += waste
				if spot < 0 or mistakes >= 1.0:
					shift.discard()
					discards += 1
					mistakes = maxf(0.0, mistakes - 1.0) if spot >= 0 else mistakes
				else:
					shift.serve(spot)
				target = -1
		elif not shift.hands_busy():
			target = _most_impatient(shift)
			if target >= 0 and shift.preparing == 0 and shift.clean > 0:
				shift.select_glass()
				var recipe: int = shift.guests[target].recipe
				prep_left = (beer_seconds if recipe == 0 else mixed_seconds) + overhead
				working = true
			elif shift.dirty > 0 and (target < 0 or shift.clean == 0):
				working = _clean(shift)
		if shift.elapsed < shift.open_seconds:
			busy += STEP if working else 0.0
			streak = streak + STEP if working else 0.0
			longest = maxf(longest, streak)
		shift.advance(STEP)
	var summary := shift.comparison_summary()
	summary.busy_ratio = snappedf(busy / shift.open_seconds, 0.01)
	summary.longest_busy_seconds = snappedf(longest, 0.1)
	summary.discards = discards
	summary.total_glasses = shift.total_glasses()
	return summary


func _clean(shift: Shift) -> bool:
	if shift.has_dishwasher and shift.machine_glasses == 0 and shift.dirty >= Shift.DISHWASHER_CAPACITY:
		return shift.start_machine().is_empty()
	return shift.start_wash().is_empty()


func _waiting(shift: Shift, spot: int) -> bool:
	return spot >= 0 and not shift.guests[spot].is_empty() and shift.guests[spot].state == "waiting"


func _most_impatient(shift: Shift) -> int:
	var best := -1
	for spot: int in range(shift.guests.size()):
		if _waiting(shift, spot) and (best < 0 or shift.guests[spot].remaining < shift.guests[best].remaining):
			best = spot
	return best
