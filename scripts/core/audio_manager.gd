extends Node

## Manages audio buses and playback for music and SFX.

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _music_playing: String = ""


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


# --- SFX hooks (stubs — play when audio assets are added) ---

func play_sfx(sfx_name: String) -> void:
	## Play a named SFX. Stub — logs until audio assets exist.
	GameManager.log_debug(GameManager.DEBUG_BATTLE, "SFX: %s" % sfx_name)


func play_hit_sfx() -> void:
	play_sfx("hit")


func play_miss_sfx() -> void:
	play_sfx("miss")


func play_crit_sfx() -> void:
	play_sfx("crit")


func play_spell_sfx(spell_name: String) -> void:
	play_sfx("spell_%s" % spell_name)


func play_item_sfx() -> void:
	play_sfx("item_use")


func play_level_up_sfx() -> void:
	play_sfx("level_up")


# --- Music hooks (stubs — play when music assets are added) ---

func play_battle_music() -> void:
	## Start battle music track. Stub until music assets exist.
	_music_playing = "battle"
	GameManager.log_debug(GameManager.DEBUG_BATTLE, "Music: battle start")


func play_victory_music() -> void:
	_music_playing = "victory"
	GameManager.log_debug(GameManager.DEBUG_BATTLE, "Music: victory")


func play_defeat_music() -> void:
	_music_playing = "defeat"
	GameManager.log_debug(GameManager.DEBUG_BATTLE, "Music: defeat")


func stop_music() -> void:
	_music_playing = ""
	GameManager.log_debug(GameManager.DEBUG_BATTLE, "Music: stopped")


func is_music_playing() -> bool:
	return _music_playing != ""
