extends Node

# Steamworks is optional at development time. This adapter never replaces a
# leaderboard with a custom database; it exposes a single seam for GodotSteam.
var available := false
var initialized := false
var last_error := "GodotSteam extension not installed"

func _ready() -> void:
	available = Engine.has_singleton("Steam")
	if available:
		last_error = "Steam extension detected; initialization must use the shipping App ID."

func get_status() -> Dictionary:
	return {"available": available, "initialized": initialized, "message": last_error}

func initialize(app_id: int) -> Dictionary:
	if not available:
		return {"result": "unavailable", "message": last_error}
	if app_id <= 0:
		return {"result": "invalid_app_id"}
	# GodotSteam API is intentionally not called until the extension/version is
	# supplied. This prevents a development build from pretending it is online.
	return {"result": "needs_adapter_binding", "message": "Bind this service to the installed GodotSteam API before release."}

func upload_weekly_score(_score: int, _week_id: String) -> Dictionary:
	if not initialized:
		return {"result": "unavailable", "message": "Steam leaderboard unavailable; local weekly record remains authoritative offline."}
	return {"result": "pending"}

func sync_cloud_save() -> Dictionary:
	if not initialized:
		return {"result": "unavailable", "message": "Steam Cloud unavailable; local SaveManager save remains active."}
	return {"result": "pending"}
