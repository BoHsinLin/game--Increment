extends Node

signal state_changed
signal toast_requested(message: String, tier: String)
signal offline_income_applied(seconds: float, karma: float, souls: float)
signal prestige_completed(samsara_gained: int)

