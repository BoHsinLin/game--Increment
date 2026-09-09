extends Node

var generators: Array = []
var upgrades: Array = []
var state: Dictionary = {}
var _accumulator := 0.0
var _autosave_elapsed := 0.0
var judgement_phase := 0.0
var judgement_target_center := 0.52
var judgement_gate := 1
var judgement_direction := 1
var judgement_combo := 0
var _judgement_rng := RandomNumberGenerator.new()
var fate_card_options: Array = []
var fate_cards: Array = []
var rune_unlocks: Array = []
var skill_nodes: Array = []
var deity_cosmetics: Array = []
var special_shop_items: Array = []
var soul_catalog: Array = []
var selected_fate_card: Dictionary = {}
var card_revealed := false
var rune_locks: Array = []
var active_rune := 0
var round_seconds := 30.0

const JUDGEMENT_CYCLE_SECONDS := 1.8
const GOOD_WINDOW := 0.28
const PERFECT_WINDOW := 0.09

func _ready() -> void:
	_judgement_rng.randomize()
	generators = ConfigLoader.load_json("res://src/config/generators/generators.json")
	upgrades = ConfigLoader.load_json("res://src/config/upgrades/upgrades.json")
	fate_cards = ConfigLoader.load_json("res://src/config/fate_cards/fate_cards.json")
	rune_unlocks = ConfigLoader.load_json("res://src/config/fate_cards/rune_unlocks.json")
	skill_nodes = ConfigLoader.load_json("res://src/config/skills/constellation_nodes.json")
	deity_cosmetics = ConfigLoader.load_json("res://src/config/deity/astraea_cosmetics.json")
	special_shop_items = ConfigLoader.load_json("res://src/config/shop/special_items.json")
	soul_catalog = ConfigLoader.load_json("res://src/config/souls/souls.json")
	state = _initial_state()
	var loaded := SaveManager.load_game()
	if not loaded.is_empty(): state.merge(loaded, true)
	_ensure_content_state()
	_apply_offline_progress()
	_begin_constellation_round()

func _process(delta: float) -> void:
	_accumulator += minf(delta, 0.25)
	while _accumulator >= GameConstants.SIMULATION_STEP:
		_tick(GameConstants.SIMULATION_STEP)
		_accumulator -= GameConstants.SIMULATION_STEP
	_autosave_elapsed += delta
	if _autosave_elapsed >= GameConstants.AUTO_SAVE_SECONDS:
		save()
		_autosave_elapsed = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
		get_tree().quit()

func _initial_state() -> Dictionary:
	var owned := {}
	for config: Dictionary in generators: owned[config.id] = 0
	return {
		"version": GameConstants.SAVE_VERSION, "saved_at": Time.get_unix_time_from_system(),
		"souls": 1.0, "karma": 0.0, "soul_fragments": 0, "destiny_seals": 0, "lifetime_karma": 0.0, "total_souls_processed": 0.0,
		"total_clicks": 0, "play_time": 0.0, "universe_age": 0.0, "samsara": 0,
		"generators": owned, "upgrades": {}, "prestige_count": 0,
		"owned_fate_cards": ["starfall", "tide", "comet", "mercy", "echo", "aurora", "eclipse", "orbit", "prism", "nova"],
		"soul_codex": ["ember_memory", "waking_star"], "soul_inventory": [], "soul_storage_capacity": 3,
		"onboarding_step": 0, "rune_capacity": 3, "skill_nodes": {},
		"owned_cosmetics": ["star_crystal", "nebula_cloak", "origin_chart"], "equipped_cosmetics": {"頭飾":"star_crystal", "斗篷":"nebula_cloak", "星盤":"origin_chart"},
		"owned_shop_relics": [], "limited_items": {}, "next_round_karma_bonus": 0.0, "weekly_records": {}, "honor": 0, "unlocked_titles": ["新任引魂者"],
		"settings": {"reduce_flashes": false, "ui_scale": 1.0, "tutorial_replay": false, "auto_ritual": false}
	}

func _ensure_content_state() -> void:
	var defaults := _initial_state()
	for key in ["soul_fragments", "destiny_seals", "owned_fate_cards", "soul_codex", "soul_inventory", "soul_storage_capacity", "onboarding_step", "rune_capacity", "skill_nodes", "owned_cosmetics", "equipped_cosmetics", "owned_shop_relics", "limited_items", "next_round_karma_bonus", "weekly_records", "honor", "unlocked_titles", "settings"]:
		if not state.has(key): state[key] = defaults[key]

func _tick(delta: float) -> void:
	_advance_judgement(delta)
	var incoming := incoming_souls_per_second() * delta
	state.souls += incoming
	var rates := get_rates()
	var processed := minf(state.souls, rates.processing * delta)
	var efficiency := processed / maxf(rates.processing * delta, 0.000001)
	var earned: float = float(rates.karma) * delta * efficiency
	state.souls -= processed
	state.karma += earned
	state.lifetime_karma += earned
	state.total_souls_processed += processed
	state.play_time += delta
	state.universe_age += delta * 1_000_000.0

func _advance_judgement(delta: float) -> void:
	judgement_phase += delta / JUDGEMENT_CYCLE_SECONDS
	if judgement_phase >= 1.0:
		judgement_phase = fmod(judgement_phase, 1.0)
		judgement_target_center = _judgement_rng.randf_range(0.22, 0.78)
		judgement_gate = _judgement_rng.randi_range(0, 2)
	round_seconds = maxf(round_seconds - delta, 0.0)
	if round_seconds <= 0.0:
		if can_use_auto_ritual() and bool(state.settings.get("auto_ritual", false)) and selected_fate_card.is_empty() and not fate_card_options.is_empty():
			_launch_automated_ritual()
		else:
			_begin_constellation_round()

func _begin_constellation_round() -> void:
	fate_card_options.clear()
	var used := {}
	var owned_cards: Array = fate_cards.filter(func(card: Dictionary) -> bool: return card.id in state.owned_fate_cards)
	while fate_card_options.size() < mini(3, owned_cards.size()):
		var card: Dictionary = owned_cards[_judgement_rng.randi_range(0, owned_cards.size() - 1)]
		if not used.has(card.id):
			used[card.id] = true
			fate_card_options.append(card)
	selected_fate_card = {}
	card_revealed = false
	rune_locks.clear()
	active_rune = 0
	round_seconds = 30.0

func select_fate_card(index: int) -> void:
	if index < 0 or index >= fate_card_options.size() or not selected_fate_card.is_empty(): return
	selected_fate_card = fate_card_options[index]
	card_revealed = true
	EventBus.state_changed.emit()

func confirm_revealed_card() -> Dictionary:
	if selected_fate_card.is_empty() or not card_revealed: return {"result": "not_ready"}
	card_revealed = false
	if requires_fate_alignment():
		EventBus.state_changed.emit()
		return {"result": "fate_ready"}
	return launch_constellation_orb()

func lock_active_rune() -> Dictionary:
	if selected_fate_card.is_empty(): return {"result": "choose_card"}
	# 初次體驗只需翻牌，讓第一顆靈魂立刻穿過閘門；重生後才開啟命運校準。
	if not requires_fate_alignment(): return launch_constellation_orb()
	if active_rune >= get_rune_capacity(): return launch_constellation_orb()
	var position := judgement_phase
	rune_locks.append(position)
	active_rune += 1
	if active_rune >= get_rune_capacity():
		EventBus.state_changed.emit()
		return {"result": "ready"}
	EventBus.state_changed.emit()
	return {"result": "locked", "rune": active_rune}

func launch_constellation_orb(is_automated := false) -> Dictionary:
	if selected_fate_card.is_empty() or (requires_fate_alignment() and rune_locks.size() < 3): return {"result": "not_ready"}
	var precision := 0.58
	var rune_push := 0.0
	if not rune_locks.is_empty():
		precision = 0.0
		for lock: float in rune_locks:
			precision += 1.0 - absf(lock - 0.5) * 2.0
			rune_push += lock - 0.5
		precision /= float(rune_locks.size())
		rune_push /= float(rune_locks.size())
	precision = clampf(precision + get_skill_bonus("precision"), 0.0, 1.0)
	rune_push *= 1.0 + get_skill_bonus("rune_push")
	var bias := float(selected_fate_card.get("bias", 0.0))
	# 鎖在環線左／右側的浮文會直接推動落珠傾向；精準度仍決定獎勵品質。
	var path := clampf(0.5 + bias + rune_push * 0.42 + (precision - 0.5) * 0.35 + _judgement_rng.randf_range(-0.22, 0.22), 0.0, 1.0)
	var lane := 0 if path < 0.333 else (1 if path < 0.666 else 2)
	var base := 0.35 + precision * 1.65
	var reward := base * float(selected_fate_card.get("multiplier", 1.0)) * (1.0 + get_skill_bonus("karma_mult") + float(state.next_round_karma_bonus))
	if lane == 1: reward *= 1.35 + get_skill_bonus("center_bonus")
	if precision >= 0.86: reward *= 2.0
	reward *= float(get_weekly_challenge().multiplier)
	if is_automated: reward *= 0.58
	var fragments := 0
	var fragment_chance := float(selected_fate_card.get("fragment_chance", 0.0)) + (0.04 if lane == 0 else 0.0) + get_skill_bonus("fragment_chance") + get_shop_relic_bonus("fragment_chance")
	if _judgement_rng.randf() < fragment_chance:
		fragments = 1
		state.soul_fragments += fragments
	var acquired_soul := _roll_soul_reward(lane, precision)
	var stored_soul := false
	if not acquired_soul.is_empty():
		if not (String(acquired_soul.id) in state.soul_codex):
			state.soul_codex.append(String(acquired_soul.id))
		if String(acquired_soul.rarity) != "常見" and state.soul_inventory.size() < int(state.soul_storage_capacity):
			state.soul_inventory.append(String(acquired_soul.id))
			stored_soul = true
	state.karma += reward
	state.lifetime_karma += reward
	state.total_souls_processed += 1.0
	state.souls = maxf(state.souls - 1.0, 0.0)
	state.next_round_karma_bonus = 0.0
	judgement_combo = judgement_combo + 1 if precision >= 0.7 else 0
	var result := {"result": "launched", "automated": is_automated, "lane": lane, "reward": reward, "fragments": fragments, "soul": acquired_soul, "soul_stored": stored_soul, "precision": precision, "rune_push": rune_push, "card": selected_fate_card.name, "multiplier": selected_fate_card.multiplier}
	result.weekly = record_weekly_result(reward, precision)
	_begin_constellation_round()
	EventBus.state_changed.emit()
	return result

func get_constellation_round() -> Dictionary:
	var preview_bias := float(selected_fate_card.get("bias", 0.0))
	var anticipated := clampf(0.5 + preview_bias + (judgement_phase - 0.5) * 0.35, 0.0, 1.0)
	var max_runes := get_rune_capacity() if requires_fate_alignment() else 0
	return {"cards": fate_card_options, "selected": selected_fate_card, "card_revealed": card_revealed, "locks": rune_locks, "active_rune": active_rune, "max_runes": max_runes, "seconds": round_seconds, "prediction": anticipated, "next_rune_unlock": get_next_rune_unlock()}

func requires_fate_alignment() -> bool:
	return int(state.get("prestige_count", 0)) > 0

func can_use_auto_ritual() -> bool:
	return owns_skill_node("cosmic_12")

func toggle_auto_ritual() -> Dictionary:
	if not can_use_auto_ritual(): return {"result": "locked"}
	state.settings.auto_ritual = not bool(state.settings.get("auto_ritual", false))
	save()
	EventBus.state_changed.emit()
	return {"result": "enabled" if state.settings.auto_ritual else "disabled"}

func _launch_automated_ritual() -> void:
	selected_fate_card = fate_card_options[0]
	card_revealed = false
	if requires_fate_alignment():
		for index in get_rune_capacity():
			rune_locks.append(0.14 if index % 2 == 0 else 0.84)
		active_rune = get_rune_capacity()
	launch_constellation_orb(true)

func get_rune_capacity() -> int:
	return clampi(int(state.get("rune_capacity", 3)), 3, 8)

func get_fate_card(card_id: String) -> Dictionary:
	for card: Dictionary in fate_cards:
		if String(card.get("id", "")) == card_id: return card
	return {}

func owns_fate_card(card_id: String) -> bool:
	return card_id in state.get("owned_fate_cards", [])

func get_soul(soul_id: String) -> Dictionary:
	for soul: Dictionary in soul_catalog:
		if String(soul.get("id", "")) == soul_id: return soul
	return {}

func release_stored_soul(index: int) -> Dictionary:
	if index < 0 or index >= state.soul_inventory.size(): return {"result": "missing"}
	var soul := get_soul(String(state.soul_inventory[index]))
	if soul.is_empty(): return {"result": "missing"}
	state.soul_inventory.remove_at(index)
	var karma := maxf(0.25, float(soul.base_karma) * 0.4 * (1.0 + get_skill_bonus("release_mult")))
	state.karma += karma
	state.lifetime_karma += karma
	save()
	EventBus.state_changed.emit()
	return {"result": "released", "soul": soul, "karma": karma}

func purchase_fate_card(card_id: String) -> Dictionary:
	var card := get_fate_card(card_id)
	if card.is_empty(): return {"result": "missing"}
	if owns_fate_card(card_id): return {"result": "owned"}
	var cost := float(card.get("cost", 0.0))
	if state.karma < cost: return {"result": "insufficient", "cost": cost}
	state.karma -= cost
	state.owned_fate_cards.append(card_id)
	save()
	EventBus.state_changed.emit()
	return {"result": "purchased", "card": card}

func get_skill_node(node_id: String) -> Dictionary:
	for node: Dictionary in skill_nodes:
		if String(node.get("id", "")) == node_id: return node
	return {}

func owns_skill_node(node_id: String) -> bool:
	return bool(state.get("skill_nodes", {}).get(node_id, false))

func can_purchase_skill(node_id: String) -> bool:
	var node := get_skill_node(node_id)
	if node.is_empty() or owns_skill_node(node_id): return false
	for requirement in node.get("requires", []):
		if not owns_skill_node(String(requirement)): return false
	var currency := String(node.get("currency", "karma"))
	var amount := float(node.get("cost", 0.0))
	match currency:
		"fragments": return float(state.soul_fragments) >= amount
		"seals": return float(state.destiny_seals) >= amount
		_: return float(state.karma) >= amount

func purchase_skill_node(node_id: String) -> Dictionary:
	var node := get_skill_node(node_id)
	if node.is_empty(): return {"result": "missing"}
	if owns_skill_node(node_id): return {"result": "owned"}
	for requirement in node.get("requires", []):
		if not owns_skill_node(String(requirement)): return {"result": "locked"}
	if not can_purchase_skill(node_id): return {"result": "insufficient"}
	var currency := String(node.currency)
	var cost := float(node.cost)
	match currency:
		"fragments": state.soul_fragments -= int(cost)
		"seals": state.destiny_seals -= int(cost)
		_: state.karma -= cost
	state.skill_nodes[node_id] = true
	if String(node.effect) == "storage": state.soul_storage_capacity += int(node.value)
	save()
	EventBus.state_changed.emit()
	return {"result": "purchased", "node": node}

func get_skill_bonus(effect: String) -> float:
	var total := 0.0
	for node: Dictionary in skill_nodes:
		if String(node.get("effect", "")) == effect and owns_skill_node(String(node.id)):
			total += float(node.get("value", 0.0))
	return total

func get_deity_cosmetic(cosmetic_id: String) -> Dictionary:
	for cosmetic: Dictionary in deity_cosmetics:
		if String(cosmetic.get("id", "")) == cosmetic_id: return cosmetic
	return {}

func owns_deity_cosmetic(cosmetic_id: String) -> bool:
	return cosmetic_id in state.get("owned_cosmetics", [])

func unlock_or_equip_cosmetic(cosmetic_id: String) -> Dictionary:
	var cosmetic := get_deity_cosmetic(cosmetic_id)
	if cosmetic.is_empty(): return {"result": "missing"}
	if not owns_deity_cosmetic(cosmetic_id):
		var cost := float(cosmetic.cost)
		match String(cosmetic.currency):
			"fragments":
				if float(state.soul_fragments) < cost: return {"result": "insufficient"}
				state.soul_fragments -= int(cost)
			"seals":
				if float(state.destiny_seals) < cost: return {"result": "insufficient"}
				state.destiny_seals -= int(cost)
			_:
				if float(state.karma) < cost: return {"result": "insufficient"}
				state.karma -= cost
		state.owned_cosmetics.append(cosmetic_id)
	state.equipped_cosmetics[String(cosmetic.slot)] = cosmetic_id
	save()
	EventBus.state_changed.emit()
	return {"result": "equipped", "cosmetic": cosmetic}

func get_special_shop_offers() -> Dictionary:
	var bucket := int(floor(Time.get_unix_time_from_system() / 1200.0))
	var offers: Array = []
	for offset in 3:
		if special_shop_items.is_empty(): break
		offers.append(special_shop_items[(bucket + offset * 2) % special_shop_items.size()])
	var seconds_remaining := 1200 - int(Time.get_unix_time_from_system()) % 1200
	return {"offers": offers, "seconds_remaining": seconds_remaining}

func get_shop_relic_bonus(effect: String) -> float:
	var total := 0.0
	for item: Dictionary in special_shop_items:
		if String(item.get("effect", "")) == effect and String(item.get("id", "")) in state.get("owned_shop_relics", []):
			total += float(item.get("value", 0.0))
	return total

func get_weekly_challenge() -> Dictionary:
	var week_id := int(floor(Time.get_unix_time_from_system() / 604800.0))
	var rules := [
		{"name":"碎星潮","detail":"碎片閘門的回響提升。","multiplier":1.08},
		{"name":"靜默日蝕","detail":"高精準落點更具價值。","multiplier":1.12},
		{"name":"雙星匯流","detail":"中央閘門吸引更多靈魂。","multiplier":1.06},
		{"name":"迴響風暴","detail":"本週的每一次命運都留下更深印記。","multiplier":1.10}
	]
	var rule: Dictionary = rules[week_id % rules.size()].duplicate()
	rule.week_id = str(week_id)
	return rule

func record_weekly_result(reward: float, precision: float) -> Dictionary:
	var challenge := get_weekly_challenge()
	var key := String(challenge.week_id)
	var record: Dictionary = state.weekly_records.get(key, {"best_reward": 0.0, "best_precision": 0.0, "honor_awarded": false})
	var improved := reward > float(record.best_reward)
	if improved:
		record.best_reward = reward
		record.best_precision = maxf(float(record.best_precision), precision)
		if not bool(record.honor_awarded):
			state.honor += 1
			record.honor_awarded = true
			if int(state.honor) >= 5 and not ("星界觀測者" in state.unlocked_titles): state.unlocked_titles.append("星界觀測者")
		state.weekly_records[key] = record
	return {"name": challenge.name, "improved": improved, "best_reward": record.best_reward, "honor": state.honor}

func buy_special_shop_item(item_id: String) -> Dictionary:
	var item: Dictionary = {}
	for candidate: Dictionary in special_shop_items:
		if String(candidate.get("id", "")) == item_id: item = candidate
	if item.is_empty(): return {"result": "missing"}
	if String(item.type) == "card" and owns_fate_card(item_id): return {"result": "owned"}
	if String(item.type) == "relic" and item_id in state.owned_shop_relics: return {"result": "owned"}
	if state.karma < float(item.karma) or int(state.soul_fragments) < int(item.fragments) or int(state.destiny_seals) < int(item.seals): return {"result": "insufficient"}
	state.karma -= float(item.karma)
	state.soul_fragments -= int(item.fragments)
	state.destiny_seals -= int(item.seals)
	match String(item.type):
		"card": state.owned_fate_cards.append(item_id)
		"relic":
			state.owned_shop_relics.append(item_id)
			if String(item.effect) == "storage": state.soul_storage_capacity += int(item.value)
		"limited": state.next_round_karma_bonus += float(item.value)
	save()
	EventBus.state_changed.emit()
	return {"result": "purchased", "item": item}

func get_next_rune_unlock() -> Dictionary:
	var next_capacity := get_rune_capacity() + 1
	for unlock: Dictionary in rune_unlocks:
		if int(unlock.get("capacity", 0)) == next_capacity: return unlock
	return {}

func unlock_next_rune() -> Dictionary:
	var offer := get_next_rune_unlock()
	if offer.is_empty(): return {"result": "maxed"}
	var cost := int(offer.get("cost_destiny_seals", 0))
	if int(state.destiny_seals) < cost: return {"result": "insufficient", "cost": cost}
	state.destiny_seals -= cost
	state.rune_capacity = int(offer.capacity)
	save()
	EventBus.state_changed.emit()
	return {"result": "unlocked", "capacity": state.rune_capacity, "cost": cost}

func set_onboarding_step(step: int) -> void:
	if step <= int(state.get("onboarding_step", 0)): return
	state.onboarding_step = step
	save()
	EventBus.state_changed.emit()

func update_setting(key: String, value: Variant) -> void:
	state.settings[key] = value
	save()
	EventBus.state_changed.emit()

func replay_first_soul_tutorial() -> void:
	state.onboarding_step = 1
	state.settings.tutorial_replay = true
	save()
	EventBus.state_changed.emit()

func attempt_judgement() -> Dictionary:
	state.total_clicks += 1
	if state.souls < 1.0:
		return {"grade": "empty", "reward": 0.0, "combo": judgement_combo}
	var distance := absf(judgement_phase - judgement_target_center)
	if judgement_direction != judgement_gate:
		judgement_combo = 0
		EventBus.state_changed.emit()
		return {"grade": "wrong_gate", "reward": 0.0, "combo": judgement_combo}
	var grade := "miss"
	var multiplier := 0.0
	if distance <= PERFECT_WINDOW * 0.5:
		grade = "perfect"
		judgement_combo += 1
		multiplier = 3.0 * (1.0 + minf(float(judgement_combo), 10.0) * 0.05)
	elif distance <= GOOD_WINDOW * 0.5:
		grade = "good"
		judgement_combo += 1
		multiplier = 1.0 + minf(float(judgement_combo), 10.0) * 0.025
	else:
		judgement_combo = 0
		EventBus.state_changed.emit()
		return {"grade": grade, "reward": 0.0, "combo": judgement_combo}
	var value := ModifierEngine.click_multiplier(state, upgrades) * multiplier
	state.souls -= 1.0
	state.karma += value
	state.lifetime_karma += value
	state.total_souls_processed += 1.0
	EventBus.state_changed.emit()
	return {"grade": grade, "reward": value, "combo": judgement_combo}

func get_judgement_state() -> Dictionary:
	return {
		"phase": judgement_phase,
		"target_center": judgement_target_center,
		"good_window": GOOD_WINDOW,
		"perfect_window": PERFECT_WINDOW,
		"gate": judgement_gate,
		"direction": judgement_direction,
		"combo": judgement_combo,
		"seconds_remaining": (1.0 - judgement_phase) * JUDGEMENT_CYCLE_SECONDS
	}

func move_judgement_direction(amount: int) -> void:
	judgement_direction = clampi(judgement_direction + amount, 0, 2)
	EventBus.state_changed.emit()

func buy_generator(id: String, requested: int) -> bool:
	var config := get_generator(id)
	if config.is_empty(): return false
	var owned: int = state.generators.get(id, 0)
	var amount := PurchaseEngine.max_affordable(config, owned, state.karma) if requested < 0 else requested
	var cost := PurchaseEngine.bulk_cost(config, owned, amount)
	if amount <= 0 or state.karma + 0.000001 < cost: return false
	state.karma -= cost
	state.generators[id] = owned + amount
	EventBus.toast_requested.emit(tr("TOAST_DEPARTMENT_EXPANDED") % amount, "minor")
	EventBus.state_changed.emit()
	return true

func buy_upgrade(id: String) -> bool:
	for upgrade: Dictionary in upgrades:
		if upgrade.id == id and not state.upgrades.get(id, false) and state.karma >= float(upgrade.cost):
			state.karma -= float(upgrade.cost)
			state.upgrades[id] = true
			EventBus.toast_requested.emit(tr("TOAST_UPGRADE_APPROVED"), "normal")
			EventBus.state_changed.emit()
			return true
	return false

func reincarnate() -> bool:
	var gained := get_prestige_reward()
	if gained <= 0: return false
	var persistent := {"samsara": int(state.samsara) + gained, "prestige_count": int(state.prestige_count) + 1,
		"lifetime_karma": state.lifetime_karma, "total_souls_processed": state.total_souls_processed,
		"total_clicks": state.total_clicks, "play_time": state.play_time}
	state = _initial_state()
	state.merge(persistent, true)
	save()
	EventBus.prestige_completed.emit(gained)
	EventBus.state_changed.emit()
	return true

func get_rates() -> Dictionary: return ProductionEngine.rates(state, generators, upgrades)
func get_prestige_reward() -> int: return PrestigeEngine.reward(state.lifetime_karma)
func incoming_souls_per_second() -> float: return incoming_souls_per_second_for_state(state)

static func incoming_souls_per_second_for_state(data: Dictionary) -> float:
	return 0.65 * pow(1.012, minf(float(data.get("universe_age", 0.0)) / 1_000_000.0, 350.0))

func get_generator(id: String) -> Dictionary:
	for config: Dictionary in generators:
		if config.id == id: return config
	return {}

func save() -> void: SaveManager.save_game(state)

func reset_save() -> void:
	state = _initial_state()
	save()
	EventBus.state_changed.emit()

func _roll_soul_reward(lane: int, precision: float) -> Dictionary:
	var chance := 0.08 + precision * 0.10 + (0.13 if lane == 0 else 0.0) + get_skill_bonus("soul_chance")
	if _judgement_rng.randf() > chance: return {}
	var roll := _judgement_rng.randf()
	var index := 0
	if roll >= 0.55 and roll < 0.82: index = 2
	elif roll >= 0.82 and roll < 0.96: index = 3
	elif roll >= 0.96 and roll < 0.995: index = 4
	elif roll >= 0.995: index = 5
	return soul_catalog[index] if index < soul_catalog.size() else {}

func _apply_offline_progress() -> void:
	var elapsed := Time.get_unix_time_from_system() - float(state.get("saved_at", Time.get_unix_time_from_system()))
	if elapsed < 10.0: return
	var report := OfflineEngine.calculate(state, generators, upgrades, elapsed)
	state.souls += report.souls_incoming - report.souls_processed
	state.karma += report.karma
	state.lifetime_karma += report.karma
	state.total_souls_processed += report.souls_processed
	EventBus.offline_income_applied.emit(report.seconds, report.karma, report.souls_processed)
