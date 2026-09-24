extends CanvasLayer

signal start_requested
signal quit_requested
signal restart_requested
signal continue_requested
signal return_title_requested
signal pause_requested

var title_panel: PanelContainer
var pause_panel: PanelContainer
var result_panel: PanelContainer
var continue_time_label: Label
var continue_countdown := 0.0
var continue_countdown_active := false
var panel_title: Label
var panel_detail: RichTextLabel
var primary_button: Button
var secondary_button: Button
var current_result_mode := "continue"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	show_title()

func _process(delta: float) -> void:
	if not continue_countdown_active:
		return
	continue_countdown = max(0.0, continue_countdown - delta)
	continue_time_label.text = "Continue in %d..." % int(ceil(continue_countdown))
	if continue_countdown <= 0.0:
		continue_countdown_active = false
		return_title_requested.emit()

func _build_ui() -> void:
	title_panel = _make_panel(Vector2(100, 150), Vector2(280, 340))
	var title_container := VBoxContainer.new()
	title_container.position = Vector2(20, 20)
	title_container.add_theme_constant_override("separation", 15)
	title_panel.add_child(title_container)

	var title_label := Label.new()
	title_label.text = "Moonlit Assault"
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = "Stage 1-1"
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_container.add_child(subtitle_label)

	var helper_label := Label.new()
	helper_label.text = "Move: WASD / Arrows\nShoot: J / Space\nBomb: X\nPause: P / Esc"
	helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_container.add_child(helper_label)

	var start_button := Button.new()
	start_button.name = "StartButton"
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(160, 32)
	start_button.pressed.connect(func() -> void: start_requested.emit())
	title_container.add_child(start_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(160, 32)
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	title_container.add_child(quit_button)
	add_child(title_panel)

	pause_panel = _make_panel(Vector2(100, 160), Vector2(280, 340))
	var pause_container := VBoxContainer.new()
	pause_container.position = Vector2(20, 20)
	pause_container.add_theme_constant_override("separation", 16)
	pause_panel.add_child(pause_container)

	var pause_title := Label.new()
	pause_title.text = "Paused"
	pause_title.add_theme_font_size_override("font_size", 28)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_container.add_child(pause_title)

	var continue_button := Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(160, 32)
	continue_button.pressed.connect(func() -> void: pause_requested.emit())
	pause_container.add_child(continue_button)

	var restart_button := Button.new()
	restart_button.text = "Restart"
	restart_button.custom_minimum_size = Vector2(160, 32)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	pause_container.add_child(restart_button)

	var title_button := Button.new()
	title_button.text = "Title"
	title_button.custom_minimum_size = Vector2(160, 32)
	title_button.pressed.connect(func() -> void: return_title_requested.emit())
	pause_container.add_child(title_button)
	add_child(pause_panel)

	result_panel = _make_panel(Vector2(100, 150), Vector2(280, 370))
	var result_container := VBoxContainer.new()
	result_container.position = Vector2(20, 20)
	result_container.add_theme_constant_override("separation", 12)
	result_panel.add_child(result_container)

	panel_title = Label.new()
	panel_title.text = "Result"
	panel_title.add_theme_font_size_override("font_size", 28)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_container.add_child(panel_title)

	panel_detail = RichTextLabel.new()
	panel_detail.bbcode_enabled = true
	panel_detail.fit_content = true
	panel_detail.scroll_active = false
	panel_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_detail.custom_minimum_size = Vector2(220, 110)
	result_container.add_child(panel_detail)

	continue_time_label = Label.new()
	continue_time_label.text = "Continue in 7..."
	continue_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_time_label.visible = false
	result_container.add_child(continue_time_label)

	primary_button = Button.new()
	primary_button.text = "Continue"
	primary_button.custom_minimum_size = Vector2(160, 32)
	primary_button.pressed.connect(_on_primary_result_clicked)
	result_container.add_child(primary_button)

	secondary_button = Button.new()
	secondary_button.text = "Give Up"
	secondary_button.custom_minimum_size = Vector2(160, 32)
	secondary_button.pressed.connect(_on_secondary_result_clicked)
	result_container.add_child(secondary_button)
	add_child(result_panel)

	hide_all()

func _make_panel(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111827cc")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("#c4b5fd")
	panel.add_theme_stylebox_override("panel", style)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	return panel

func show_title() -> void:
	hide_all()
	title_panel.visible = true

func set_start_enabled(enabled: bool) -> void:
	var start_button := title_panel.find_child("StartButton", true, false) as Button
	if start_button:
		start_button.disabled = not enabled

func show_pause() -> void:
	hide_all()
	pause_panel.visible = true

func show_continue(score_value: int, total_seconds: float = 7.0) -> void:
	hide_all()
	current_result_mode = "continue"
	panel_title.text = "Continue"
	panel_detail.text = "[center]Life lost.\nScore: %d\nContinue this run?[/center]" % score_value
	primary_button.text = "Continue"
	secondary_button.text = "Give Up"
	continue_countdown = total_seconds
	continue_countdown_active = true
	continue_time_label.visible = true
	continue_time_label.text = "Continue in %d..." % int(ceil(total_seconds))
	result_panel.visible = true

func show_game_over(score_value: int, stats: Dictionary) -> void:
	hide_all()
	current_result_mode = "game_over"
	panel_title.text = "Game Over"
	panel_detail.text = "[center]Final Score: %d\nGraze: %d\nBoss Hits: %d\nShots Fired: %d[/center]" % [score_value, stats.get("graze", 0), stats.get("boss_hits", 0), stats.get("shots_fired", 0)]
	primary_button.text = "Retry"
	secondary_button.text = "Title"
	continue_countdown_active = false
	continue_time_label.visible = false
	result_panel.visible = true

func show_stage_clear(score_value: int, stats: Dictionary) -> void:
	hide_all()
	current_result_mode = "stage_clear"
	panel_title.text = "Stage Clear"
	panel_detail.text = "[center]Stage Cleared!\nFinal Score: %d\nGraze: %d\nBoss Hits: %d\nShots Fired: %d[/center]" % [score_value, stats.get("graze", 0), stats.get("boss_hits", 0), stats.get("shots_fired", 0)]
	primary_button.text = "Restart"
	secondary_button.text = "Title"
	continue_countdown_active = false
	continue_time_label.visible = false
	result_panel.visible = true

func _on_primary_result_clicked() -> void:
	match current_result_mode:
		"continue":
			continue_requested.emit()
		"game_over":
			restart_requested.emit()
		"stage_clear":
			restart_requested.emit()

func _on_secondary_result_clicked() -> void:
	match current_result_mode:
		"continue":
			return_title_requested.emit()
		"game_over":
			return_title_requested.emit()
		"stage_clear":
			return_title_requested.emit()

func hide_all() -> void:
	title_panel.visible = false
	pause_panel.visible = false
	result_panel.visible = false
	continue_countdown_active = false
	continue_time_label.visible = false
