extends Resource

# These are hypotheses for a worksheet, not production balance or measured data.
@export var shift_seconds: float = 240.0
@export var arrivals: int = 18
@export var rush_arrivals_per_minute: float = 8.0
@export var rush_seconds: float = 30.0
@export var beer_share: float = 0.5
@export var beer_price_cents: int = 600
@export var mixed_price_cents: int = 900
@export var beer_cost_cents: int = 150
@export var mixed_cost_cents: int = 225
@export var average_tip_cents: int = 75
@export var beer_active_seconds: float = 5.0
@export var mixed_active_seconds: float = 8.0
@export var guest_holds_glass_seconds: float = 12.0
@export var manual_wash_seconds: float = 4.0
@export var starting_glasses: int = 6
@export var extra_glasses: int = 2
@export var rack_price_cents: int = 2400
@export var dishwasher_price_cents: int = 12000
@export var dishwasher_capacity: int = 4
@export var dishwasher_load_seconds_per_glass: float = 0.75
@export var dishwasher_cycle_seconds: float = 12.0
@export var learning_time_multiplier: float = 1.5
@export var learning_waste_fraction: float = 0.1
@export var mistake_time_multiplier: float = 1.75
@export var mistake_waste_fraction: float = 0.3


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var positive := {
		"shift_seconds": shift_seconds,
		"rush_seconds": rush_seconds,
		"beer_active_seconds": beer_active_seconds,
		"mixed_active_seconds": mixed_active_seconds,
		"manual_wash_seconds": manual_wash_seconds,
		"dishwasher_cycle_seconds": dishwasher_cycle_seconds,
		"learning_time_multiplier": learning_time_multiplier,
		"mistake_time_multiplier": mistake_time_multiplier,
		"starting_glasses": starting_glasses,
		"dishwasher_capacity": dishwasher_capacity,
	}
	for field: String in positive:
		if not is_finite(float(positive[field])) or float(positive[field]) <= 0.0:
			errors.append("%s must be finite and greater than zero." % field)
	var nonnegative := {
		"arrivals": arrivals, "rush_arrivals_per_minute": rush_arrivals_per_minute,
		"beer_price_cents": beer_price_cents, "mixed_price_cents": mixed_price_cents,
		"beer_cost_cents": beer_cost_cents, "mixed_cost_cents": mixed_cost_cents,
		"average_tip_cents": average_tip_cents,
		"guest_holds_glass_seconds": guest_holds_glass_seconds,
		"extra_glasses": extra_glasses, "rack_price_cents": rack_price_cents,
		"dishwasher_price_cents": dishwasher_price_cents,
		"dishwasher_load_seconds_per_glass": dishwasher_load_seconds_per_glass,
		"learning_waste_fraction": learning_waste_fraction,
		"mistake_waste_fraction": mistake_waste_fraction,
	}
	for field: String in nonnegative:
		if not is_finite(float(nonnegative[field])) or float(nonnegative[field]) < 0.0:
			errors.append("%s must be finite and nonnegative." % field)
	if not is_finite(beer_share) or beer_share < 0.0 or beer_share > 1.0:
		errors.append("beer_share must be between zero and one.")
	if rush_seconds > shift_seconds:
		errors.append("rush_seconds cannot exceed shift_seconds.")
	if rush_arrivals_per_minute * rush_seconds / 60.0 > arrivals:
		errors.append("The rush cannot contain more arrivals than the whole shift.")
	return errors
