extends SceneTree

## Plays each service preset with the scripted bartender at settled, learning, and
## mistake-heavy speeds (from the calibrated worksheet) and prints the outcome.
##   godot --headless --path . --script tools/day_ramp_report.gd

const Bot = preload("res://scripts/systems/service_bot.gd")
const Shift = preload("res://scripts/systems/service_shift.gd")
const WORKSHEET = preload("res://content/balance/worksheet.tres")
const EQUIPMENT: Array[String] = ["starter", "rack", "dishwasher", "rack+machine"]


func _initialize() -> void:
	var a: Resource = WORKSHEET
	# Mistake-heavy play is at least as slow as learning, and remakes drinks.
	var profiles := {
		"settled": [1.0, 0.0],
		"learning": [a.learning_time_multiplier, a.learning_waste_fraction],
		"mistakes": [maxf(a.mistake_time_multiplier, a.learning_time_multiplier), a.mistake_waste_fraction],
	}
	print("# Scripted bartender, not a real player. busy = share of open time spent working.")
	for pressure: int in range(Shift.PRESSURES.size()):
		for equipment: int in range(EQUIPMENT.size()):
			var cells := PackedStringArray()
			for profile: String in profiles:
				var r: Dictionary = Bot.new(a.beer_active_seconds, a.mixed_active_seconds, profiles[profile][0], 1.0, profiles[profile][1]).play(equipment, pressure)
				cells.append("%s %d/%d served, %d left, %d away, busy %d%%" % [
					profile, r.served, r.scheduled_arrivals, r.walkouts, r.missed_arrivals, roundi(r.busy_ratio * 100)])
			print("%-9s %-13s | %s" % [Shift.PRESSURES[pressure].id, EQUIPMENT[equipment], " | ".join(cells)])
	quit(0)
