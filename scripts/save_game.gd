class_name SaveGame
extends RefCounted
## The saved game, in user://save.cfg. Resting at a shrine saves; the title
## offers Continue when there is a save (Begin still starts the prologue
## and a new game). What is kept:
##  - the shrine he last rested at (he comes back there),
##  - the shrines he has rested at (lit on the map),
##  - the paper cranes found (by bundle),
##  - every drop of ink ever taken in (his marks),
##  - the shortcuts opened (the drain grate, the gatehouse gate, the ladder),
##  - whether the Hannya's cutscene has been seen, and whether she has fallen,
##  - the Smudge (where he last died, and the ink it holds),
##  - whether the Paper-Maker has told him, in pictures,
##  - the parts of the village he has explored (for the map).
## Everything lives in static variables, so it survives changing scenes
## (from the title into the game).

## Where it is saved. (The automated check and the debug start flags use
## files of their own, so they never touch a real saved game.)
static var file := "user://save.cfg"

static var last_shrine := ""
static var rested: Array[String] = []
static var cranes: Array[String] = []
static var ink_absorbed := 0
static var shortcuts: Array[String] = []
static var hannya_seen := false
static var hannya_fallen := false
## Abilities learned ("glide").
static var abilities: Array[String] = []
static var smudge_at := Vector3.INF
## Whether the Paper-Maker has told him, in pictures (paper_maker_tale.gd).
static var papermaker_told := false
## Akane: met (her warning seen), and her first duel won.
static var akane_met := false
static var akane_dueled := false
static var smudge_ink := 0
## Explored map cells: "layer:x" keys (layers "under", "street", "roofs").
static var explored := {}
## Set by the title's Continue: the game starts from the save.
static var continuing := false


static func exists() -> bool:
	return FileAccess.file_exists(file)


## Forget everything (a new game).
static func reset() -> void:
	last_shrine = ""
	rested = []
	cranes = []
	ink_absorbed = 0
	shortcuts = []
	hannya_seen = false
	hannya_fallen = false
	abilities = []
	smudge_at = Vector3.INF
	smudge_ink = 0
	explored = {}
	continuing = false
	papermaker_told = false
	akane_met = false
	akane_dueled = false


static func write() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "last_shrine", last_shrine)
	cfg.set_value("game", "rested", rested)
	cfg.set_value("game", "cranes", cranes)
	cfg.set_value("game", "ink_absorbed", ink_absorbed)
	cfg.set_value("game", "shortcuts", shortcuts)
	cfg.set_value("game", "hannya_seen", hannya_seen)
	cfg.set_value("game", "hannya_fallen", hannya_fallen)
	cfg.set_value("game", "abilities", abilities)
	cfg.set_value("game", "smudge_at", smudge_at if smudge_at != Vector3.INF else Vector3(0, -999, 0))
	cfg.set_value("game", "smudge_ink", smudge_ink)
	cfg.set_value("game", "papermaker_told", papermaker_told)
	cfg.set_value("game", "akane_met", akane_met)
	cfg.set_value("game", "akane_dueled", akane_dueled)
	cfg.set_value("game", "explored", explored.keys())
	cfg.save(file)


static func read() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(file) != OK:
		return false
	last_shrine = cfg.get_value("game", "last_shrine", "")
	rested.assign(cfg.get_value("game", "rested", []))
	cranes.assign(cfg.get_value("game", "cranes", []))
	ink_absorbed = cfg.get_value("game", "ink_absorbed", 0)
	shortcuts.assign(cfg.get_value("game", "shortcuts", []))
	hannya_seen = cfg.get_value("game", "hannya_seen", false)
	hannya_fallen = cfg.get_value("game", "hannya_fallen", false)
	abilities.assign(cfg.get_value("game", "abilities", []))
	var at: Vector3 = cfg.get_value("game", "smudge_at", Vector3(0, -999, 0))
	smudge_at = at if at.y > -900.0 else Vector3.INF
	smudge_ink = cfg.get_value("game", "smudge_ink", 0)
	papermaker_told = cfg.get_value("game", "papermaker_told", false)
	akane_met = cfg.get_value("game", "akane_met", false)
	akane_dueled = cfg.get_value("game", "akane_dueled", false)
	explored = {}
	for key: String in cfg.get_value("game", "explored", []):
		explored[key] = true
	return true


## A bundle of `count` cranes found (kept as "id:count").
static func found_crane(id: String, count: int) -> void:
	if not has_crane(id):
		cranes.append("%s:%d" % [id, count])


static func has_crane(id: String) -> bool:
	for entry: String in cranes:
		if entry.get_slice(":", 0) == id:
			return true
	return false


## How many cranes he has found in all.
static func crane_total() -> int:
	var total := 0
	for entry: String in cranes:
		total += int(entry.get_slice(":", 1))
	return total


static func opened(which: String) -> void:
	if which not in shortcuts:
		shortcuts.append(which)


## Marks the map cell he is in as explored.
static func explore(at: Vector3) -> void:
	var layer := "under" if at.y < -1.0 else ("roofs" if at.y > 4.5 else "street")
	explored["%s:%d" % [layer, floori(at.x / 4.0)]] = true
