extends Node
## 离线每日首领轮换。默认每日 05:00 按设备本地时间刷新。
signal daily_boss_changed(state: Dictionary)
signal daily_boss_defeated(boss_id: String)

const RESET_HOUR := 5
const SAVE_KEY := "daily_boss_state"
const BOSS_ROTATION := [
	{"id": "daily_celestial_guardian", "name": "每日试炼：星宫守护者", "level_offset": 0, "exp": 180, "coins": 160},
	{"id": "daily_silver_champion", "name": "每日试炼：白银斗士", "level_offset": 2, "exp": 220, "coins": 190},
	{"id": "daily_black_knight", "name": "每日试炼：暗黑斗士", "level_offset": 4, "exp": 260, "coins": 220},
	{"id": "daily_gold_trial", "name": "每日试炼：黄金试炼者", "level_offset": 6, "exp": 320, "coins": 260},
	{"id": "daily_mariner", "name": "每日试炼：海界强敌", "level_offset": 8, "exp": 380, "coins": 300},
	{"id": "daily_specter", "name": "每日试炼：冥界强敌", "level_offset": 10, "exp": 440, "coins": 340},
	{"id": "daily_divine_trial", "name": "每日试炼：神域挑战者", "level_offset": 12, "exp": 520, "coins": 400}
]

var state: Dictionary = {}
var _refresh_check_timer := 0.0

func _ready() -> void:
	RPGState.slot_loaded.connect(_on_slot_loaded)
	_refresh_cycle(true)
	set_process(true)

func _process(delta: float) -> void:
	_refresh_check_timer += delta
	if _refresh_check_timer >= 30.0:
		_refresh_check_timer = 0.0
		_refresh_cycle(false)

func _on_slot_loaded(_slot: int) -> void:
	_refresh_cycle(true)

func _cycle_id(unix_time: int = -1) -> String:
	var timestamp := unix_time if unix_time >= 0 else int(Time.get_unix_time_from_system())
	var reset_timestamp := timestamp - RESET_HOUR * 3600
	var date := Time.get_datetime_dict_from_unix_time(reset_timestamp, true)
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]

func _boss_for_cycle(cycle_id: String) -> Dictionary:
	var day_number := int(cycle_id.replace("-", ""))
	var index := posmod(day_number, BOSS_ROTATION.size())
	return BOSS_ROTATION[index].duplicate(true)

func _refresh_cycle(force: bool) -> void:
	var saved: Variant = RPGState.profile.get(SAVE_KEY, {})
	if typeof(saved) != TYPE_DICTIONARY:
		saved = {}
	var current_cycle := _cycle_id()
	var saved_cycle := str(saved.get("cycle_id", ""))
	# Prevent a backward device-clock change from reopening an earlier daily reward.
	if not saved_cycle.is_empty() and saved_cycle > current_cycle:
		current_cycle = saved_cycle
	if not force and str(state.get("cycle_id", "")) == current_cycle:
		return
	if saved_cycle == current_cycle:
		state = saved.duplicate(true)
	else:
		var boss := _boss_for_cycle(current_cycle)
		state = {
			"version": 1,
			"cycle_id": current_cycle,
			"boss_id": str(boss.id),
			"boss_name": str(boss.name),
			"defeated": false,
			"reward_claimed": false
		}
		_save_state()
	daily_boss_changed.emit(get_state())

func _save_state() -> bool:
	RPGState.profile[SAVE_KEY] = state.duplicate(true)
	return RPGState.save_slot(RPGState.active_slot)

func get_state() -> Dictionary:
	var result := state.duplicate(true)
	result["reset_hour_local"] = RESET_HOUR
	result["next_refresh_unix"] = _next_refresh_unix()
	result["seconds_until_refresh"] = maxi(0, _next_refresh_unix() - int(Time.get_unix_time_from_system()))
	result["available"] = not bool(result.get("defeated", false))
	return result

func _next_refresh_unix() -> int:
	var now := int(Time.get_unix_time_from_system())
	var local := Time.get_datetime_dict_from_system()
	var today_reset := {"year": local.year, "month": local.month, "day": local.day, "hour": RESET_HOUR, "minute": 0, "second": 0}
	var reset_today := int(Time.get_unix_time_from_datetime_dict(today_reset))
	return reset_today + (86400 if now >= reset_today else 0)

func can_challenge() -> bool:
	return not state.is_empty() and not bool(state.get("defeated", false))

func mark_boss_defeated(boss_id: String) -> bool:
	if not can_challenge() or boss_id != str(state.get("boss_id", "")):
		return false
	state["defeated"] = true
	if not _save_state():
		state["defeated"] = false
		return false
	daily_boss_defeated.emit(boss_id)
	daily_boss_changed.emit(get_state())
	return true

func claim_reward() -> Dictionary:
	if state.is_empty() or not bool(state.get("defeated", false)):
		return {"success": false, "reason": "请先击败今日首领"}
	if bool(state.get("reward_claimed", false)):
		return {"success": false, "reason": "今日奖励已经领取"}
	var boss := _boss_for_cycle(str(state.get("cycle_id", "")))
	var previous := state.duplicate(true)
	state["reward_claimed"] = true
	if not _save_state():
		state = previous
		return {"success": false, "reason": "奖励状态保存失败"}
	RPGState.add_exp(int(boss.get("exp", 0)))
	RPGState.add_currency(int(boss.get("coins", 0)))
	return {"success": true, "exp": int(boss.get("exp", 0)), "coins": int(boss.get("coins", 0))}

func get_rotation_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in BOSS_ROTATION:
		result.append(entry.duplicate(true))
	return result
