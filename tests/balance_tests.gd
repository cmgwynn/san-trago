extends SceneTree

const Model = preload("res://scripts/systems/balance_model.gd")
const Assumptions = preload("res://scripts/content/balance_assumptions.gd")
var checks: int = 0
var failures: int = 0


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	var a := Assumptions.new()
	var report := Model.calculate(a)
	expect(report.errors.is_empty() and report.rows.size() == 9, "three profiles times three equipment choices")
	var row: Dictionary = report.rows[0]
	expect(row.active_seconds_per_order == 10.5, "baseline is weighted prep plus manual washing")
	expect(row.shift_workload_ratio == 0.788, "baseline workload matches hand calculation")
	expect(is_equal_approx(row.rush_workload_ratio, 1.4), "rush overload is surfaced")
	expect(is_equal_approx(row.rush_backlog_orders_estimate, 1.14), "rush backlog uses arrival minus service capacity")
	expect(row.sales_cents_if_all_served == 13500, "weighted drink sales")
	expect(row.ingredient_cost_cents_if_all_served == 3375, "ingredient cost counted once")
	expect(row.profit_cents_if_all_served == 11475, "all-served profit matches hand calculation")
	expect(row.shifts_to_dishwasher_if_all_served == 2, "affordability rounds up")
	expect(report.rows[1].shift_workload_ratio == row.shift_workload_ratio, "extra glasses do not make hands faster")
	expect(report.rows[1].glasses == row.glasses + 2, "rack increases inventory")
	expect(report.rows[2].active_seconds_per_order == 7.25, "dishwasher reduces active cleaning only")
	expect(report.rows[2].dishwasher_utilization_ratio == 0.225, "machine capacity includes cycle duration")
	expect(report.rows[3].waste_cost_cents_included == 338, "learning waste is explicit")
	expect(report.rows[3].ingredient_cost_cents_if_all_served == 3713, "waste is not double charged")
	expect(report.rows[6].shift_workload_ratio > 1.0, "mistake-heavy case warns about sustained overload")
	for result: Dictionary in report.rows:
		expect(result.keys().size() == Model.COLUMNS.size(), "every row matches CSV schema")
	a.arrivals = 0
	a.rush_arrivals_per_minute = 0.0
	report = Model.calculate(a)
	expect(report.errors.is_empty(), "zero arrivals is a valid no-demand case")
	expect(report.rows[2].profit_cents_if_all_served == 0, "no arrivals makes no profit")
	expect(report.rows[2].shifts_to_rack_if_all_served == -1, "zero profit cannot fund upgrade")
	expect(report.rows[2].steady_glasses_needed_estimate == 0, "zero demand avoids batch division by zero")
	a.shift_seconds = 0
	report = Model.calculate(a)
	expect(not report.errors.is_empty() and report.rows.is_empty(), "invalid inputs do not produce plausible results")
	a = Assumptions.new()
	a.beer_share = NAN
	expect(not Model.calculate(a).errors.is_empty(), "nonfinite values rejected")
	a = Assumptions.new()
	a.dishwasher_capacity = 0
	expect(not Model.calculate(a).errors.is_empty(), "zero machine capacity rejected")
	a = Assumptions.new()
	a.rush_arrivals_per_minute = 100
	expect(not Model.calculate(a).errors.is_empty(), "inconsistent rush and total demand rejected")
	print("%d balance checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)
