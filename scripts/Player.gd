extends Node2D

signal shoot_requested(position: Vector2, direction: Vector2)
signal bomb_requested
signal player_died

var speed := 260.0
var fire_timer := 0.0
var invulnerable_time := 0.0
var alive := true

func _ready() -> void:
	var body := Polygon2D.new()
	body.color = Color("#90e0ef")
	body.polygon = PackedVector2Array([Vector2(0, -18), Vector2(12, 16), Vector2(0, 6), Vector2(-12, 16)])
	add_child(body)

func _process(delta: float) -> void:
	if not alive:
		return
	invulnerable_time = max(0.0, invulnerable_time - delta)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += movement.normalized() * speed * delta
	position.x = clamp(position.x, 20.0, 460.0)
	position.y = clamp(position.y, 30.0, 700.0)
	fire_timer -= delta
	if Input.is_action_pressed("shoot") and fire_timer <= 0.0:
		fire_timer = 0.12
		shoot_requested.emit(global_position + Vector2(0, -20), Vector2.UP)
	if Input.is_action_just_pressed("bomb"):
		bomb_requested.emit()

func take_damage(_amount: int) -> void:
	if not alive or invulnerable_time > 0.0:
		return
	alive = false
	visible = false
	player_died.emit()

func reset_state() -> void:
	alive = true
	visible = true
	position = Vector2(240, 650)
	invulnerable_time = 2.0
