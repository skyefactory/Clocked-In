extends StaticBody3D
@export var crafting_station: CraftingStation

func can_interact(_interacting_player: Player) -> bool:
	return !crafting_station.visible

func get_interaction_text(_interacting_player: Player) -> String:
	return "Press E to open %s" % crafting_station.station_name

func interact(_interacting_player: Player) -> void:
	if crafting_station.visible:
		crafting_station.hide()
		crafting_station.player.capture_mouse()
	else:
		crafting_station.update_crafting_status()
		crafting_station.player.release_mouse()
		crafting_station.player.interact_target.emit(false,"")
		crafting_station.show()