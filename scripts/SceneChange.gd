extends CanvasLayer

@onready var animator = $AnimationPlayer # used for the fade effect
@onready var bar = $ProgressBar # loading progress

var is_changing_scene = false # are we currently waiting to change scene

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	animator.process_mode = Node.PROCESS_MODE_ALWAYS
	bar.process_mode = Node.PROCESS_MODE_ALWAYS

func change_scene(target: String) -> void: # call this to change scene
	if is_changing_scene: # if we're already in the process of changing scene, return to avoid multiple calls
		return
	is_changing_scene = true

	await fade_out() # wait for the fade out animation to finish before loading the new scene
	await load_scene(target) # wait for the new scene to load before fading back in
	await fade_in() # wait for the fade in animation to finish before allowing another scene change

	is_changing_scene = false # allow future scene changes

func fade_out() -> void:
	animator.play("fade_out")
	await animator.animation_finished

func fade_in() -> void:
	animator.play("fade_in")
	await animator.animation_finished

func load_scene(target: String) -> void:
	bar.visible = true # set the progress bar to visible
	bar.value = 0 # set the value to 0

	ResourceLoader.load_threaded_request(target) # start loading the scene in a separate thread

	while true:
		var progress = [] # this will hold the progress value from the threaded loader
		var status = ResourceLoader.load_threaded_get_status(target, progress) # get the current status and progress of the threaded loader
		bar.value = int(progress[0] * 100) # update the progress bar with the current progress
		if status == ResourceLoader.THREAD_LOAD_LOADED: # if the scene has finished loading,
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE: # if the scene failed to load
			push_error("Failed to load scene: " + target)
			bar.visible = false
			return
		await get_tree().process_frame  # lets the UI update

	var packed_scene = ResourceLoader.load_threaded_get(target) as PackedScene # get the loaded scene as a PackedScene
	get_tree().current_scene.free()  # free old scene
	var new_scene = packed_scene.instantiate() # instantiate the new scene
	get_tree().root.add_child(new_scene) # add the new scene to the scene tree
	get_tree().current_scene = new_scene # set the new scene as the current scene

	bar.visible = false # hide the progress bar after loading is complete
