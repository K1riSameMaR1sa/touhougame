extends Node2D

var velocity := Vector2.ZERO
var from_player := false
var grazed := false

func setup(pos: Vector2, direction: Vector2, speed: float, owned_by_player: bool, color: Color) -> void:
	global_position = pos
	velocity = direction.normalized() * speed
	from_player = owned_by_player
	var shape := Polygon2D.new()
	shape.color = color
	shape.polygon = PackedVector2Array([Vector2(0, -5), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)])
	add_child(shape)

func _process(delta: float) -> void:
	position += velocity * delta
	if position.x < -60 or position.x > 540 or position.y < -60 or position.y > 780:
		queue_free()
