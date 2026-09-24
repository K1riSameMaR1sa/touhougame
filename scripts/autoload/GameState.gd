extends Node

signal score_changed(value: int)
signal lives_changed(value: int)
signal bombs_changed(value: int)
signal state_changed(state: String)

var score := 0
var lives := 3
var bombs := 3
var run_state := "title"
var phase_name := "Ready"
var graze_count := 0
var boss_hits := 0
var shots_fired := 0
var shots_hit := 0
var enemy_shots_fired := 0

func reset_run() -> void:
	score = 0
	lives = 3
	bombs = 3
	run_state = "title"
	phase_name = "Ready"
	graze_count = 0
	boss_hits = 0
	shots_fired = 0
	shots_hit = 0
	enemy_shots_fired = 0
	score_changed.emit(score)
	lives_changed.emit(lives)
	bombs_changed.emit(bombs)
	state_changed.emit(run_state)

func set_run_state(state: String) -> void:
	run_state = state
	state_changed.emit(run_state)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func lose_life() -> void:
	lives = max(0, lives - 1)
	lives_changed.emit(lives)

func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	bombs_changed.emit(bombs)
	return true

func register_graze() -> void:
	graze_count += 1

func register_boss_hit() -> void:
	boss_hits += 1

func register_shot_fired() -> void:
	shots_fired += 1

func register_enemy_shot() -> void:
	enemy_shots_fired += 1

func stats_snapshot() -> Dictionary:
	return {
		"graze": graze_count,
		"boss_hits": boss_hits,
		"shots_fired": shots_fired,
		"enemy_shots": enemy_shots_fired,
		"shots_hit": shots_hit,
	}
