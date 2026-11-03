extends RefCounted

const Assumptions = preload("res://scripts/content/balance_assumptions.gd")
const COLUMNS: Array[String] = [
	"profile", "equipment", "glasses", "purchase_cents",
	"active_seconds_per_order", "shift_workload_ratio", "rush_workload_ratio",
	"rush_backlog_orders_estimate", "comfortable_arrivals_per_shift",
	"steady_glasses_needed_estimate", "rush_glasses_to_skip_washing",
	"dishwasher_utilization_ratio", "sales_cents_if_all_served",
	"tips_cents_if_all_served", "ingredient_cost_cents_if_all_served",
	"waste_cost_cents_included", "profit_cents_if_all_served",
	"shifts_to_rack_if_all_served", "shifts_to_dishwasher_if_all_served", "warnings",
]


static func calculate(a: Assumptions) -> Dictionary:
	var errors := a.validation_errors()
	if not errors.is_empty():
		return {"errors": errors, "rows": []}
	var rows: Array[Dictionary] = []
	var profiles: Array[Dictionary] = [
		{"id": "efficient", "speed": 1.0, "waste": 0.0},
		{"id": "learning", "speed": a.learning_time_multiplier, "waste": a.learning_waste_fraction},
		{"id": "mistake_heavy", "speed": a.mistake_time_multiplier, "waste": a.mistake_waste_fraction},
	]
	var base_prep := lerpf(a.mixed_active_seconds, a.beer_active_seconds, a.beer_share)
	var price := lerpf(a.mixed_price_cents, a.beer_price_cents, a.beer_share)
	var cost := lerpf(a.mixed_cost_cents, a.beer_cost_cents, a.beer_share)
	var rate := float(a.arrivals) / a.shift_seconds
	var rush_rate := a.rush_arrivals_per_minute / 60.0
	for profile: Dictionary in profiles:
		for equipment: String in ["baseline", "extra_glasses", "dishwasher"]:
			var machine := equipment == "dishwasher"
			var glasses := a.starting_glasses + (a.extra_glasses if equipment == "extra_glasses" else 0)
			var attempts := 1.0 + float(profile.waste)
			var prep := base_prep * float(profile.speed) * attempts
			var cleaning := a.dishwasher_load_seconds_per_glass if machine else a.manual_wash_seconds
			var work := prep + cleaning * attempts
			var dishwasher_ratio := rate * attempts * a.dishwasher_cycle_seconds / a.dishwasher_capacity if machine else 0.0
			# A full-batch planning approximation includes average batch-fill wait.
			var fill_wait := (a.dishwasher_capacity - 1) / (2.0 * rate * attempts) if machine and rate > 0 else 0.0
			var glass_cycle := prep + a.guest_holds_glass_seconds + cleaning * attempts
			if machine:
				glass_cycle += fill_wait + a.dishwasher_cycle_seconds
			var needed := ceili(rate * glass_cycle)
			# Serving a whole rush before washing needs a clean glass per drink made
			# during the rush, plus the one in hand. This is what extra glasses buy.
			var rush_served := minf(rush_rate, 1.0 / prep) * a.rush_seconds
			var rush_glasses := ceili(rush_served - 0.0001) + 1 if rush_rate > 0 else 0
			var sales := roundi(a.arrivals * price)
			var tips := a.arrivals * a.average_tip_cents
			var base_cost := roundi(a.arrivals * cost)
			var waste_cost := roundi(a.arrivals * cost * float(profile.waste))
			var ingredients := base_cost + waste_cost
			var profit := sales + tips - ingredients
			var warnings := PackedStringArray()
			if rate * work >= 1.0:
				warnings.append("Sustained active work consumes all capacity")
			if rush_rate * work > 1.0:
				warnings.append("Rush builds a queue")
			if needed > glasses:
				warnings.append("Steady glass-buffer estimate exceeds inventory")
			if not machine and rush_glasses > glasses:
				warnings.append("Must stop to wash mid-rush")
			if dishwasher_ratio >= 1.0:
				warnings.append("Dishwasher cannot sustain estimated demand")
			if profit <= 0:
				warnings.append("Nonpositive all-served profit")
			var purchase := 0
			if equipment == "extra_glasses":
				purchase = a.rack_price_cents
			elif machine:
				purchase = a.dishwasher_price_cents
			rows.append({
				"profile": profile.id, "equipment": equipment, "glasses": glasses,
				"purchase_cents": purchase,
				"active_seconds_per_order": snappedf(work, 0.001),
				"shift_workload_ratio": snappedf(rate * work, 0.001),
				"rush_workload_ratio": snappedf(rush_rate * work, 0.001),
				"rush_backlog_orders_estimate": snappedf(maxf(0.0, rush_rate - 1.0 / work) * a.rush_seconds, 0.01),
				"comfortable_arrivals_per_shift": floori(a.comfortable_workload * a.shift_seconds / work),
				"steady_glasses_needed_estimate": needed,
				"rush_glasses_to_skip_washing": rush_glasses,
				"dishwasher_utilization_ratio": snappedf(dishwasher_ratio, 0.001),
				"sales_cents_if_all_served": sales,
				"tips_cents_if_all_served": tips,
				"ingredient_cost_cents_if_all_served": ingredients,
				"waste_cost_cents_included": waste_cost,
				"profit_cents_if_all_served": profit,
				"shifts_to_rack_if_all_served": ceili(float(a.rack_price_cents) / profit) if profit > 0 else -1,
				"shifts_to_dishwasher_if_all_served": ceili(float(a.dishwasher_price_cents) / profit) if profit > 0 else -1,
				"warnings": "; ".join(warnings),
			})
	return {"errors": errors, "rows": rows}
