extends Node2D

var player: Node2D
var boss: Node2D
var bullets: Array[Node] = []
var effects: Array[Node] = []
var stage_data: Dictionary = {}
var hud: CanvasLayer
var flow_ui: CanvasLayer
var is_stage_running := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.state_changed.connect(_on_state_changed)
	stage_data = StageManager.get_stage("stage_1_1")
	_build_background()
	hud = preload("res://scripts/HUD.gd").new()
	add_child(hud)
	flow_ui = preload("res://scripts/FlowUI.gd").new()
	add_child(flow_ui)
	flow_ui.start_requested.connect(_on_start_clicked)
	flow_ui.quit_requested.connect(func() -> void: get_tree().quit())
	flow_ui.restart_requested.connect(_on_restart_clicked)
	flow_ui.pause_requested.connect(_toggle_pause)
	flow_ui.continue_requested.connect(_continue_run)
	flow_ui.return_title_requested.connect(_on_return_title)
	GameState.reset_run()
	flow_ui.show_title()
	if stage_data.is_empty():
		flow_ui.set_start_enabled(false)
		hud.set_status("Config Error")
	elif stage_data.has("boss_name"):
		hud.set_boss_name(stage_data.get("boss_name", "Boss"))

func _process(_delta: float) -> void:
	if not is_stage_running:
		return
	_check_collisions()

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("#10152e")
	background.position = Vector2.ZERO
	background.size = Vector2(480, 720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)

func _on_state_changed(state: String) -> void:
	if flow_ui == null:
		return
	match state:
		"title":
			flow_ui.show_title()
		"playing":
			flow_ui.hide_all()
		"paused":
			flow_ui.show_pause()
		"continue":
			flow_ui.show_continue(GameState.score, 7.0)
		"game_over":
			flow_ui.show_game_over(GameState.score, GameState.stats_snapshot())
		"stage_clear":
			flow_ui.show_stage_clear(GameState.score, GameState.stats_snapshot())

func _start_run() -> void:
	_clear_stage()
	GameState.reset_run()
	GameState.set_run_state("playing")
	get_tree().paused = false
	is_stage_running = true
	_spawn_player()
	_spawn_boss()
	if stage_data.has("boss_name"):
		hud.set_boss_name(stage_data.get("boss_name", "Boss"))

func _restart_run() -> void:
	_start_run()

func _clear_stage() -> void:
	for bullet in bullets.duplicate():
		if is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()
	for effect in effects.duplicate():
		if is_instance_valid(effect):
			effect.queue_free()
	effects.clear()
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(boss):
		boss.queue_free()
	player = null
	boss = null
	is_stage_running = false

func _spawn_player() -> void:
	player = preload("res://scripts/Player.gd").new()
	player.position = Vector2(240, 650)
	player.shoot_requested.connect(_on_player_shoot)
	player.bomb_requested.connect(_on_player_bomb)
	player.player_died.connect(_on_player_died)
	add_child(player)

func _spawn_boss() -> void:
	boss = preload("res://scripts/Boss.gd").new()
	boss.configure(stage_data)
	boss.position = Vector2(240, 120)
	boss.shot_fired.connect(_on_enemy_shot)
	boss.spell_changed.connect(_on_spell_changed)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	if stage_data.has("boss_name"):
		hud.set_boss_name(stage_data.get("boss_name", "Boss"))

func _on_player_shoot(pos: Vector2, direction: Vector2) -> void:
	GameState.register_shot_fired()
	_spawn_bullet(pos, direction, 560.0, true, Color("#bde0fe"))

func _on_enemy_shot(pos: Vector2, direction: Vector2, speed: float, color: Color) -> void:
	GameState.register_enemy_shot()
	_spawn_bullet(pos, direction, speed, false, color)

func _spawn_bullet(pos: Vector2, direction: Vector2, speed: float, player_owned: bool, color: Color) -> void:
	var bullet = preload("res://scripts/Bullet.gd").new()
	bullet.setup(pos, direction, speed, player_owned, color)
	bullet.tree_exited.connect(func() -> void: bullets.erase(bullet))
	add_child(bullet)
	bullets.append(bullet)

func _on_player_bomb() -> void:
	if not GameState.use_bomb():
		return
	for bullet in bullets.duplicate():
		if is_instance_valid(bullet) and not bullet.from_player:
			bullet.queue_free()
	if is_instance_valid(boss):
		boss.take_damage(20)
	if is_instance_valid(player):
		player.invulnerable_time = 1.5
	hud.set_status("Bomb!")
	_spawn_effect(Vector2(240, 310), Color("#dbeafe"), 22)

func _on_spell_changed(card_name: String, active: bool) -> void:
	if active:
		hud.set_status(card_name)
		GameState.phase_name = card_name
	else:
		hud.set_status(stage_data.get("boss_name", "Boss"))
		if is_instance_valid(boss):
			GameState.phase_name = boss.phase_name
		else:
			GameState.phase_name = "Ready"

func _spawn_effect(position: Vector2, color: Color, amount: int = 18) -> void:
	var particles := CPUParticles2D.new()
	particles.position = position
	particles.amount = amount
	particles.lifetime = 0.35
	particles.one_shot = true
	particles.emitting = true
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = color
	particles.modulate = color
	add_child(particles)
	effects.append(particles)
	particles.finished.connect(func() -> void:
		effects.erase(particles)
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _on_player_died() -> void:
	if GameState.run_state in ["title", "continue", "game_over", "stage_clear"]:
		return
	GameState.lose_life()
	if GameState.lives <= 0:
		is_stage_running = false
		get_tree().paused = true
		GameState.set_run_state("game_over")
		if is_instance_valid(player):
			player.visible = false
		return
	is_stage_running = false
	get_tree().paused = true
	GameState.set_run_state("continue")
	if is_instance_valid(player):
		player.visible = false
	if is_instance_valid(boss):
		boss.set_process(false)

func _continue_run() -> void:
	get_tree().paused = false
	if is_instance_valid(player):
		player.reset_state()
		player.visible = true
	if is_instance_valid(boss):
		boss.set_process(true)
	is_stage_running = true
	GameState.set_run_state("playing")

func _toggle_pause() -> void:
	if GameState.run_state == "playing":
		get_tree().paused = true
		GameState.set_run_state("paused")
	elif GameState.run_state == "paused":
		get_tree().paused = false
		GameState.set_run_state("playing")

func _check_collisions() -> void:
	if not is_instance_valid(player):
		return
	for bullet in bullets.duplicate():
		if not is_instance_valid(bullet):
			continue
		if bullet.from_player and is_instance_valid(boss):
			if bullet.global_position.distance_to(boss.global_position) < 30.0:
				boss.take_damage(1)
				GameState.add_score(10)
				GameState.register_boss_hit()
				_spawn_effect(bullet.global_position, Color("#bfe3ff"), 10)
				bullet.queue_free()
		elif not bullet.from_player:
			var distance: float = bullet.global_position.distance_to(player.global_position)
			if distance < 12.0:
				player.take_damage(1)
				_spawn_effect(bullet.global_position, Color("#fca5a5"), 16)
				bullet.queue_free()
			elif distance < 18.0 and not bullet.grazed:
				bullet.grazed = true
				GameState.register_graze()
				GameState.add_score(2)
				_spawn_effect(bullet.global_position, Color("#fde68a"), 8)

func _on_boss_defeated() -> void:
	if GameState.run_state in ["title", "paused", "continue", "game_over", "stage_clear"]:
		return
	is_stage_running = false
	get_tree().paused = true
	GameState.set_run_state("stage_clear")
	_spawn_effect(boss.global_position, Color("#fde68a"), 30)

func _on_return_title() -> void:
	get_tree().paused = false
	_clear_stage()
	GameState.reset_run()
	GameState.set_run_state("title")
	flow_ui.show_title()

func _on_start_clicked() -> void:
	_start_run()

func _on_restart_clicked() -> void:
	_restart_run()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and GameState.run_state == "title":
		_start_run()
	if event.is_action_pressed("ui_cancel"):
		if GameState.run_state == "title":
			get_tree().quit()
		elif GameState.run_state == "playing":
			_toggle_pause()
		elif GameState.run_state == "paused":
			_toggle_pause()
	if event.is_action_pressed("pause_game"):
		if GameState.run_state in ["playing", "paused"]:
			_toggle_pause()
	if event.is_key_pressed(KEY_P):
		if GameState.run_state in ["playing", "paused"]:
			_toggle_pause()
	if event.is_key_pressed(KEY_R) and GameState.run_state == "game_over":
		_restart_run()
