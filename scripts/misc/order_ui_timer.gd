extends RichTextLabel

signal timer_finished #the timer has reached zero

var timer_duration: int = 120   # total time in seconds
var elapsed: float = 0.0 #time that has elapsed
var fin: bool = false #is the timer over or not
var gtr: bool = true # used for flashing timer effect
var gtw: bool = false # used for flashing timer effect
var value = 1.0 # value used for flashing timer effect, will oscillate between 1.0 and 0.0 to create a flashing effect when the timer is done.

func _process(delta):
	# flashing timer effect when the timer is done, will oscillate the text color between white and red to indicate that the timer is finished.
	if fin:
		if gtr:
			value -= delta
			if value <= 0.0:
				value = 0.0
				gtr = false
				gtw = true

		if gtw:
			value += delta
			if value >= 1.0:
				value = 1.0
				gtr = true
				gtw = false

		add_theme_color_override(
			"default_color",
			Color(1, value, value)
		)
		return
	
	elapsed += delta #increment elapsed time
	#find the remaining time
	var remaining := timer_duration - int(elapsed)
	#nothing remaining, finished 
	if remaining <= 0:
		remaining = 0
		fin = true
		#send out the signal indicating this timer is done.
		emit_signal("timer_finished")
	#set the label text to the formatted ramining time.
	text = format_time(remaining)

# helper function to format the remaining time in MM:SS format for display on the timer label.
func format_time(seconds: int) -> String:
	var mins := int(seconds / 60)
	var secs := seconds % 60
	
	return "%02d:%02d" % [mins, secs]
