extends SceneTree

const Model = preload("res://scripts/systems/balance_model.gd")
const INPUT = preload("res://content/balance/worksheet.tres")


func _initialize() -> void:
	var report := Model.calculate(INPUT)
	if not report.errors.is_empty():
		for error: String in report.errors:
			printerr("Balance input error: ", error)
		quit(1)
		return
	print("# HYPOTHETICAL worksheet, not measured gameplay or a customer simulation.")
	print("# All-served profit ignores walkouts; workload and buffers are approximations.")
	print("# Currency is integer cents. -1 affordability means no positive profit.")
	var csv := FileAccess.open("user://balance-report.csv", FileAccess.WRITE)
	if csv == null:
		printerr("Cannot open balance report: ", error_string(FileAccess.get_open_error()))
		quit(1)
		return
	csv.store_csv_line(PackedStringArray(Model.COLUMNS))
	for row: Dictionary in report.rows:
		var values := PackedStringArray()
		for key: String in Model.COLUMNS:
			values.append(str(row[key]))
		csv.store_csv_line(values)
		print("%s / %s: workload %.3f, rush %.3f, profit if all served $%.2f. %s" % [
			row.profile, row.equipment, row.shift_workload_ratio,
			row.rush_workload_ratio, float(row.profit_cents_if_all_served) / 100.0,
			row.warnings,
		])
	csv.flush()
	var error := csv.get_error()
	csv.close()
	if error != OK:
		printerr("Cannot write balance report: ", error_string(error))
		quit(1)
		return
	print("CSV: ", ProjectSettings.globalize_path("user://balance-report.csv"))
	quit(0)
