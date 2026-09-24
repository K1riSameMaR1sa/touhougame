extends Node

signal configuration_failed(message: String)

const STAGES_PATH := "res://data/stages.json"
const BOSSES_PATH := "res://data/bosses.json"
const SPELL_CARDS_PATH := "res://data/spell_cards.json"

var _stages: Dictionary = {}
var _bosses: Dictionary = {}
var _spell_cards: Dictionary = {}
var load_error := ""

func _ready() -> void:
	_load_configuration()

func get_stage(stage_id: String) -> Dictionary:
	if not load_error.is_empty():
		push_error(load_error)
		return {}
	if not _stages.has(stage_id):
		push_error("Unknown stage id: " + stage_id)
		return {}
	var stage: Dictionary = _stages[stage_id].duplicate(true)
	var boss_id: String = stage["boss_id"]
	var boss: Dictionary = _bosses[boss_id].duplicate(true)
	var cards: Array = []
	for card_id in boss["spell_cards"]:
		cards.append(_spell_cards[card_id].duplicate(true))
	stage["boss_name"] = boss["name"]
	stage["boss_hp"] = boss["hp"]
	stage["phase_thresholds"] = boss["phase_thresholds"].duplicate()
	stage["cards"] = cards
	return stage

func _load_configuration() -> void:
	var stages_value = _read_json(STAGES_PATH)
	var bosses_value = _read_json(BOSSES_PATH)
	var cards_value = _read_json(SPELL_CARDS_PATH)
	if load_error.is_empty():
		_load_entries(stages_value, "stages", _stages)
	if load_error.is_empty():
		_load_entries(bosses_value, "bosses", _bosses)
	if load_error.is_empty():
		_load_entries(cards_value, "spell_cards", _spell_cards)
	if load_error.is_empty():
		_validate_references()
	if not load_error.is_empty():
		configuration_failed.emit(load_error)
		push_error(load_error)

func _read_json(path: String):
	if not load_error.is_empty():
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Could not open configuration: %s" % path)
		return null
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		_fail("Invalid JSON in %s at line %d: %s" % [
			path, parser.get_error_line(), parser.get_error_message()
		])
		return null
	var value = parser.data
	if not value is Dictionary:
		_fail("Configuration root must be an object: " + path)
		return null
	return value

func _load_entries(value, key: String, target: Dictionary) -> void:
	if not value.has(key) or not value[key] is Array:
		_fail("Configuration must contain an array named '%s'" % key)
		return
	for entry in value[key]:
		if not entry is Dictionary:
			_fail("Every %s entry must be an object" % key)
			return
		var id = entry.get("id", "")
		if not id is String or id.is_empty():
			_fail("Every %s entry needs a non-empty string id" % key)
			return
		if target.has(id):
			_fail("Duplicate %s id: %s" % [key, id])
			return
		target[id] = entry

func _validate_references() -> void:
	for stage_id in _stages:
		var stage: Dictionary = _stages[stage_id]
		if not _is_non_empty_string(stage.get("boss_id", "")):
			_fail("Stage %s has an invalid boss_id" % stage_id)
			return
		if not _bosses.has(stage["boss_id"]):
			_fail("Stage %s references unknown boss %s" % [stage_id, stage["boss_id"]])
			return
	for boss_id in _bosses:
		var boss: Dictionary = _bosses[boss_id]
		if not _is_non_empty_string(boss.get("name", "")) or not _is_positive_number(boss.get("hp", 0)):
			_fail("Boss %s has invalid name or hp" % boss_id)
			return
		if not boss.get("phase_thresholds", []) is Array:
			_fail("Boss %s phase_thresholds must be an array" % boss_id)
			return
		for threshold in boss["phase_thresholds"]:
			if not _is_ratio(threshold):
				_fail("Boss %s has an invalid phase threshold" % boss_id)
				return
		if not boss.get("spell_cards", []) is Array:
			_fail("Boss %s spell_cards must be an array" % boss_id)
			return
		for card_id in boss["spell_cards"]:
			if not _is_non_empty_string(card_id) or not _spell_cards.has(card_id):
				_fail("Boss %s references unknown spell card %s" % [boss_id, card_id])
				return
	for card_id in _spell_cards:
		var card: Dictionary = _spell_cards[card_id]
		if not _is_non_empty_string(card.get("name", "")):
			_fail("Spell card %s has an invalid name" % card_id)
			return
		for field in ["duration", "fire_interval"]:
			if not _is_positive_number(card.get(field, 0)):
				_fail("Spell card %s has an invalid %s" % [card_id, field])
				return
		if not _is_ratio(card.get("threshold", -1)):
			_fail("Spell card %s has an invalid threshold" % card_id)
			return
		if not _is_non_empty_string(card.get("pattern", "")) or not _is_non_empty_string(card.get("color", "")):
			_fail("Spell card %s has an invalid pattern or color" % card_id)
			return

func _is_non_empty_string(value) -> bool:
	return value is String and not value.is_empty()

func _is_positive_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) > 0.0

func _is_ratio(value) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and float(value) <= 1.0

func _fail(message: String) -> void:
	load_error = message
