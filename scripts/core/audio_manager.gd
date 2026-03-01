extends Node

## Manages audio buses and playback for music and SFX.

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0


func _ready() -> void:
	GameManager.log_info("AudioManager ready")


func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	var db := linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_volume))
