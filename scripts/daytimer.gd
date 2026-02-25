extends Label



signal day_start
signal day_end

const REAL_TO_GAME_MINUTES: int = 5
var tick: float = 2.5

var hour = 7
var minute = 45
var pm = false

var day_started = false
var day_ended = false

var accum = 0.0

func _ready() -> void:

	update_label()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	accum += delta
	if accum >= tick:
		advance_time()
		accum -= tick
		
	if Input.is_action_pressed("debug_speedup"): tick = 0.5
	else: tick = 2.5
	update_label()

func advance_time():
	minute += REAL_TO_GAME_MINUTES
	
	if minute >= 60:
		hour += 1
		minute = minute % 60
	
	if hour >= 12:
		hour = hour % 12
		pm = not pm
	
	update_label()
	check_signals()

func update_label():
	var display_hour = hour
	if display_hour == 0:
		display_hour = 12
	var am_pm = "PM" if pm else "AM"
	if Input.is_action_pressed("debug_speedup"):
		text = "%02d:%02d %s ▶▶" % [display_hour, minute, am_pm]
	else:
		text = "%02d:%02d %s" % [display_hour, minute, am_pm]

func check_signals():
	if not day_started and hour == 8 and not pm:
		emit_signal("day_start")
		day_started = true
	if not day_ended and hour == 5 and pm:
		emit_signal("day_end")
		day_ended = true;
		day_started = false;
