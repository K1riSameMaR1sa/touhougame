extends Node2D

signal shot_fired(position: Vector2, direction: Vector2, speed: float, color: Color)
signal spell_changed(card_name: String, active: bool)
signal defeated

var hp := 150
var max_hp := 150
var cards: Array = []
var phase_thresholds: Array = []
var card_index := 0
var active_card: Dictionary = {}
var spell_time := 0.0
var fire_timer := 0.0
var pattern_time := 0.0
var pattern_interval := 0.18
var phase_name := "Normal"

func configure(data: Dictionary) -> void:
	hp = int(data.get("boss_hp", 150))
	max_hp = hp
	cards = data.get("cards", [])
	phase_thresholds = data.get("phase_thresholds", [])
	if phase_thresholds.is_empty() and cards.size() > 0:
		for card in cards:
			phase_thresholds.append(card.get("threshold", 0.0))
	card_index = 0
	active_card = {}
	spell_time = 0.0
	fire_timer = 0.6
	pattern_time = 0.0
	phase_name = _resolve_phase_name(float(hp) / max_hp if max_hp > 0 else 1.0)

func _ready() -> void:
	var body := Polygon2D.new()
	body.color = Color("#c77dff")
	body.polygon = PackedVector2Array([Vector2(0, -30), Vector2(28, -10), Vector2(36, 18), Vector2(0, 32), Vector2(-36, 18), Vector2(-28, -10)])
	add_child(body)

func _process(delta: float) -> void:
	pattern_time += delta
	position.x = 240.0 + sin(pattern_time * 0.8) * 120.0
	phase_name = _resolve_phase_name(float(hp) / max_hp if max_hp > 0 else 1.0)
	if not active_card.is_empty():
		spell_time -= delta
		pattern_interval = max(0.12, float(active_card.get("fire_interval", 0.22)))
		pattern_timer_logic(delta, active_card.get("pattern", "starlit_bloom"), active_card.get("color", "#d9e6ff"))
		if spell_time <= 0.0:
			spell_changed.emit("", false)
			active_card = {}
			phase_name = _resolve_phase_name(float(hp) / max_hp if max_hp > 0 else 1.0)
		return
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = 0.75
		_fire_normal_pattern()
		_update_spell_state_if_needed()
		return
	_update_spell_state_if_needed()

func _update_spell_state_if_needed() -> void:
	if cards.is_empty():
		return
	var ratio := float(hp) / max_hp if max_hp > 0 else 1.0
	var target_card: Dictionary = {}
	for index in range(cards.size() - 1, -1, -1):
		var entry: Dictionary = cards[index]
		var threshold := float(entry.get("threshold", 0.6))
		if ratio <= threshold:
			target_card = entry
			card_index = index
			break
	if target_card.is_empty():
		return
	if active_card.is_empty() or active_card.get("name", "") != target_card.get("name", ""):
		active_card = target_card
		spell_time = float(active_card.get("duration", 8.0))
		pattern_interval = max(0.12, float(active_card.get("fire_interval", 0.22)))
		spell_changed.emit(active_card.get("name", "Spell Card"), true)

func pattern_timer_logic(delta: float, pattern: String, color_value) -> void:
	var color := _parse_color(color_value)
	if pattern == "starlit_bloom":
		_fire_ring_pattern(pattern, color, 16, 0.24, delta)
	elif pattern == "lunar_spiral":
		_fire_ring_pattern(pattern, color, 20, 0.2, delta)
	elif pattern == "abyss_ring":
		_fire_ring_pattern(pattern, color, 24, 0.16, delta)
	else:
		_fire_ring_pattern(pattern, color, 16, 0.18, delta)

func _fire_ring_pattern(pattern: String, color: Color, count: int, rotation_speed: float, delta: float) -> void:
	var interval = pattern_interval
	if pattern == "lunar_spiral":
		interval = max(0.12, pattern_interval * 1.25)
	if pattern == "abyss_ring":
		interval = max(0.1, pattern_interval * 0.9)
	if not has_meta("_pattern_timer"):
		set_meta("_pattern_timer", 0.0)
	var timer: float = get_meta("_pattern_timer")
	timer -= delta
	if timer > 0.0:
		set_meta("_pattern_timer", timer)
		return
	set_meta("_pattern_timer", interval)
	var rotation := pattern_time * rotation_speed
	for index in count:
		var angle := rotation + float(index) * TAU / count
		shot_fired.emit(global_position, Vector2.from_angle(angle), 210.0 if pattern == "abyss_ring" else 240.0, color)

func _fire_normal_pattern() -> void:
	for index in 12:
		var angle := -PI / 2.0 + float(index) * TAU / 12.0
		shot_fired.emit(global_position, Vector2.from_angle(angle), 220.0, Color("#ff70a6"))

func _resolve_phase_name(ratio: float) -> String:
	if phase_thresholds.is_empty():
		return "Normal"
	for index in range(phase_thresholds.size() - 1, -1, -1):
		if ratio <= float(phase_thresholds[index]):
			return "Phase %d" % (index + 1)
	return "Phase %d" % phase_thresholds.size()

func _parse_color(value) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(value, Color.WHITE)
	return Color.WHITE

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp == 0:
		defeated.emit()
		queue_free()
