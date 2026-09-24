extends CanvasLayer

var score_label: Label
var lives_label: Label
var bombs_label: Label
var boss_label: Label
var phase_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_refresh_from_state()

func _build_hud() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(16, 16)
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)

	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(score_label)

	lives_label = Label.new()
	lives_label.text = "Lives: 3"
	lives_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(lives_label)

	bombs_label = Label.new()
	bombs_label.text = "Bombs: 3"
	bombs_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(bombs_label)

	phase_label = Label.new()
	phase_label.text = "Phase: Ready"
	phase_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(phase_label)

	boss_label = Label.new()
	boss_label.position = Vector2(300, 16)
	boss_label.text = "Boss"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(boss_label)

	GameState.score_changed.connect(func(value: int): score_label.text = "Score: %d" % value)
	GameState.lives_changed.connect(func(value: int): lives_label.text = "Lives: %d" % value)
	GameState.bombs_changed.connect(func(value: int): bombs_label.text = "Bombs: %d" % value)
	GameState.state_changed.connect(_on_state_changed)

func _on_state_changed(_state: String) -> void:
	_refresh_from_state()

func _refresh_from_state() -> void:
	score_label.text = "Score: %d" % GameState.score
	lives_label.text = "Lives: %d" % GameState.lives
	bombs_label.text = "Bombs: %d" % GameState.bombs
	phase_label.text = "Phase: %s" % GameState.phase_name

func set_boss_name(name: String) -> void:
	boss_label.text = name

func set_phase_name(name: String) -> void:
	GameState.phase_name = name
	phase_label.text = "Phase: %s" % name

func set_status(text: String) -> void:
	boss_label.text = text
