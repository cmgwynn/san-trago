extends SceneTree

## Content catalog checks, including proof that a new drink and a guest who orders
## it work end to end with no code changes: only new .tres files.

const Catalog = preload("res://scripts/content/content_catalog.gd")
const Recipe = preload("res://scripts/content/drink_recipe.gd")
const Profile = preload("res://scripts/content/guest_profile.gd")
const Fact = preload("res://scripts/content/guest_fact.gd")
const Topic = preload("res://scripts/content/guest_topic.gd")
const Book = preload("res://scripts/systems/guest_book.gd")
const Workbench = preload("res://scripts/systems/drink_workbench.gd")
const PROBE := "user://catalog_probe"

var checks: int = 0
var failures: int = 0


func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	_shipped_content()
	_new_content_needs_no_code()
	_mistakes_are_reported()
	_clean_probe()
	print("Content checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _shipped_content() -> void:
	var drinks: Array[Resource] = Catalog.load_dir(Catalog.DRINKS_DIR)
	var guests: Array[Resource] = Catalog.load_dir(Catalog.GUESTS_DIR)
	var drink_ids: Array = drinks.map(func(d: Resource) -> String: return d.id)
	expect(drink_ids == ["draft_beer", "rum_cola"], "drinks load sorted by file name: %s" % [drink_ids])
	expect(guests.size() == 3, "all three guests load")
	var errors := Catalog.validation_errors(drinks, guests)
	expect(errors.is_empty(), "shipped content validates: %s" % [errors])
	expect(Catalog.by_id(drinks).rum_cola.rum_units == 1, "drinks can be looked up by ID")


func _new_content_needs_no_code() -> void:
	_clean_probe()
	DirAccess.make_dir_recursive_absolute(PROBE + "/drinks")
	DirAccess.make_dir_recursive_absolute(PROBE + "/guests")
	var drink := Recipe.new()
	drink.id = "dark_and_cola"
	drink.display_name = "Dark & cola"
	drink.description = "Two rum and one cola in a clean glass."
	drink.rum_units = 2
	drink.cola_units = 1
	expect(ResourceSaver.save(drink, PROBE + "/drinks/dark_and_cola.tres") == OK, "a new drink saves as a .tres")
	var fact := Fact.new()
	fact.id = "usual"
	fact.text = "Usual: dark and cola"
	fact.unlock = Fact.Unlock.SERVED_DRINK
	fact.target = "dark_and_cola"
	var topic := Topic.new()
	topic.id = "harbor"
	topic.line = "The harbor seals were loud today."
	var guest := Profile.new()
	guest.id = "rosa"
	guest.display_name = "Rosa Diaz"
	guest.role = "Harbor pilot"
	guest.usual_drink = "dark_and_cola"
	guest.topics = [topic]
	guest.facts = [fact]
	expect(ResourceSaver.save(guest, PROBE + "/guests/rosa.tres") == OK, "a new guest saves as a .tres")

	var drinks: Array[Resource] = Catalog.load_dir(Catalog.DRINKS_DIR)
	drinks.append_array(Catalog.load_dir(PROBE + "/drinks"))
	var guests: Array[Resource] = Catalog.load_dir(Catalog.GUESTS_DIR)
	guests.append_array(Catalog.load_dir(PROBE + "/guests"))
	var errors := Catalog.validation_errors(drinks, guests)
	expect(errors.is_empty(), "new drink and guest validate alongside shipped content: %s" % [errors])
	var loaded: Resource = Catalog.by_id(drinks).dark_and_cola
	expect(loaded != null and loaded.quantities() == {"draft": 0, "rum": 2, "cola": 1}, "the new drink is found by folder scan")

	var bench := Workbench.new()
	bench.select_glass()
	for ingredient: String in ["rum", "rum", "cola"]:
		bench.add_unit(ingredient)
	expect(bench.check_recipe(loaded.quantities()).is_empty(), "the drink workbench accepts the new recipe as authored")
	bench.add_unit("cola")
	expect(not bench.check_recipe(loaded.quantities()).is_empty(), "and rejects an over-poured one")
	var book := Book.new(guests)
	expect(book.record_serve("rosa", "dark_and_cola", true) == ["usual"], "the guest book unlocks a fact for the new drink")


func _mistakes_are_reported() -> void:
	var drinks: Array[Resource] = Catalog.load_dir(Catalog.DRINKS_DIR)
	var stray := Recipe.new()
	stray.id = "rum_cola"
	stray.display_name = "Copy"
	stray.cola_units = 1
	ResourceSaver.save(stray, PROBE + "/drinks/copy.tres")
	drinks.append(load(PROBE + "/drinks/copy.tres"))
	var lost := Profile.new()
	lost.id = "lost"
	lost.display_name = "Lost"
	lost.usual_drink = "mai_tai"
	var bad_fact := Fact.new()
	bad_fact.id = "f"
	bad_fact.text = "Likes mojitos"
	bad_fact.unlock = Fact.Unlock.SERVED_DRINK
	bad_fact.target = "mojito"
	lost.facts = [bad_fact]
	var errors := Catalog.validation_errors(drinks, [lost])
	for needle: String in ["rename the file", "Two files use the ID 'rum_cola'", "orders 'mai_tai'", "needs drink 'mojito'"]:
		var found := false
		for error: String in errors:
			found = found or error.contains(needle)
		expect(found, "catalog reports '%s'" % needle)


func _clean_probe() -> void:
	for sub: String in ["drinks", "guests"]:
		var dir := PROBE + "/" + sub
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir + "/" + file)
		DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(PROBE)
