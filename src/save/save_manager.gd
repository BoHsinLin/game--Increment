class_name SaveManager
extends RefCounted

static func save_game(state: Dictionary) -> bool:
	var payload := state.duplicate(true)
	payload.version = GameConstants.SAVE_VERSION
	payload.saved_at = Time.get_unix_time_from_system()
	var file := FileAccess.open(GameConstants.SAVE_PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(payload))
	return true

static func load_game() -> Dictionary:
	if not FileAccess.file_exists(GameConstants.SAVE_PATH): return {}
	var file := FileAccess.open(GameConstants.SAVE_PATH, FileAccess.READ)
	if file == null: return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary: return {}
	return migrate(data)

static func migrate(data: Dictionary) -> Dictionary:
	var version: int = data.get("version", 0)
	if version < 1:
		data["total_souls_processed"] = data.get("total_souls_processed", 0.0)
		data["version"] = 1
	return data

