extends Node
class_name DayTimer

var hour:int = 7 # current hour
var minute:int = 45 # current minute
var pm: bool = false # am/pm

var day_started: bool = false # has the day started?
var day_ended: bool = false # has the day ended?

var spedup: bool = false # debug variable to speed up time for testing purposes, if true, time will advance faster.

var accum: float = 0.0 # accumulator for tracking time, when it reaches the tick value, we will advance the time by TICK_TO_GAME_MINUTES and reset the accumulator.

signal day_start
signal day_end
signal time_changed

const TICK_TO_GAME_MINUTES: int = 5 # how many in game minutes pass for every tick, can be adjusted for testing or to change the pacing of the game.
var tick: float = 2.5

func _process(delta: float) -> void:
    accum += delta # iterate the accumulator by the delta time
    if accum >= tick: # if the accumulator has reached the tick value, we will advance the time and reset the accumulator.
        advance_time()
        accum -= tick
    # debug speedup
    if Input.is_action_pressed("debug_speedup"): 
        tick = 0.5
        spedup = true
    else: 
        spedup = false
        tick = 2.5
    
    
# advances the time by TICK_TO_GAME_MINUTES and updates PM 
func advance_time():
    minute += TICK_TO_GAME_MINUTES
    if minute >= 60:
        hour += 1
        minute = minute % 60
    if hour >= 12:
        hour = hour % 12
        pm = not pm
    
    emit_signal("time_changed", hour, minute, pm, spedup)
    check_signals()
# checks if we need to emit the day start or day end signals based on the current time. The day starts at 8:00 AM and ends at 8:00 PM.
func check_signals():
    if not day_started and hour == 8 and not pm:
        day_started = true
        emit_signal("day_start")
    elif not day_ended and hour == 8 and pm:
        day_ended = true
        emit_signal("day_end")