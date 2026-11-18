extends Node2D

var velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var bounds: Rect2

func initialize(polygon_points: PackedVector2Array, color: Color, spawn_bounds: Rect2) -> void:
    bounds = spawn_bounds

    var poly := Polygon2D.new()
    poly.polygon = polygon_points
    poly.color = color
    add_child(poly)

    var angle = randf_range(0.0, TAU)
    var speed = randf_range(15.0, 50.0)
    velocity = Vector2.from_angle(angle) * speed
    spin = randf_range(-1.2, 1.2)

func _process(delta: float) -> void:
    position += velocity * delta
    rotation += spin * delta
    if not bounds.has_point(position):
        queue_free()
