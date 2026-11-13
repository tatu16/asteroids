extends StaticBody2D

@export var change_interval: float = 30.0
@export var collision_thickness: float = 12.0
@export var transition_duration: float = 3.0
@export var minimum_sides: int = 4
@export var maximum_sides: int = 10
@export var arena_size := Vector2(1920.0, 1080.0)
@export var movement_amplitude := Vector2(8.0, 5.0)
@export var movement_speed: float = 0.35
@export var rotation_amplitude: float = 0.025
@export var rotation_speed: float = 0.25
@export var shrink_interval: float = 60.0
@export var shrink_factor: float = 0.9
@export var minimum_arena_size := Vector2(1152.0, 648.0)
@export var shrink_duration: float = 4.0
@export var outside_shade_color := Color(0.005, 0.008, 0.02, 0.65)
@export var outside_shade_extent: float = 8.0

@onready var line: Line2D = $Line2D
@onready var glow_line: Line2D = $GlowLine2D
@onready var change_timer: Timer = $ChangeTimer
@onready var shrink_timer: Timer = $ShrinkTimer

var current_points := PackedVector2Array()
var target_points := PackedVector2Array()
var collision_segments: Array[CollisionShape2D] = []
var outside_shades: Array[Polygon2D] = []
var transition_progress: float = 1.0
var current_sides: int = 4
var base_position := Vector2.ZERO
var motion_time: float = 0.0
var current_arena_size := Vector2.ZERO
var target_arena_size := Vector2.ZERO

func _ready() -> void:
    add_to_group("wall")
    base_position = position
    current_arena_size = arena_size
    target_arena_size = arena_size
    line.closed = true
    glow_line.closed = true
    change_timer.wait_time = change_interval
    change_timer.timeout.connect(_on_change_timer_timeout)
    shrink_timer.wait_time = shrink_interval
    shrink_timer.timeout.connect(_on_shrink_timer_timeout)
    _create_collision_segments()
    _create_outside_shades()
    if multiplayer.is_server():
        var highest_sides := maxi(minimum_sides, maximum_sides)
        var initial_minimum_sides := mini(maxi(minimum_sides, 6), highest_sides)
        current_sides = randi_range(
            initial_minimum_sides,
            highest_sides
        )
        set_target_shape.rpc(
            _generate_shape(current_sides, randf_range(0.0, TAU))
        )
        change_timer.start()
        shrink_timer.start()

func _process(delta: float) -> void:
    motion_time += delta
    position = base_position + Vector2(
        sin(motion_time * movement_speed) * movement_amplitude.x,
        cos(motion_time * movement_speed * 0.83) * movement_amplitude.y
    )
    rotation = sin(motion_time * rotation_speed) * rotation_amplitude

    if not current_arena_size.is_equal_approx(target_arena_size):
        current_arena_size = current_arena_size.lerp(
            target_arena_size,
            minf(delta / maxf(shrink_duration, 0.001), 1.0)
        )
        if not current_points.is_empty():
            _apply_shape(current_points)

    if transition_progress >= 1.0:
        return

    transition_progress = minf(
        transition_progress + delta / maxf(transition_duration, 0.001),
        1.0
    )
    var animated_points := PackedVector2Array()
    for index in current_points.size():
        animated_points.append(
            current_points[index].lerp(
                target_points[index],
                transition_progress
            )
        )
    _apply_shape(animated_points)

func _on_change_timer_timeout() -> void:
    if multiplayer.is_server():
        _change_shape()

func _on_shrink_timer_timeout() -> void:
    if not multiplayer.is_server():
        return

    var next_size := target_arena_size * shrink_factor
    next_size.x = maxf(next_size.x, minimum_arena_size.x)
    next_size.y = maxf(next_size.y, minimum_arena_size.y)
    set_target_arena_size.rpc(next_size)

@rpc("authority", "call_local", "reliable")
func set_target_arena_size(size: Vector2) -> void:
    target_arena_size = size

func _change_shape() -> void:
    var lowest_sides := mini(minimum_sides, maximum_sides)
    var highest_sides := maxi(minimum_sides, maximum_sides)
    var sides := randi_range(lowest_sides, highest_sides)
    if sides == current_sides and highest_sides > lowest_sides:
        sides = lowest_sides if sides == highest_sides else sides + 1
    current_sides = sides
    set_target_shape.rpc(_generate_shape(sides))

func _generate_shape(
    sides: int,
    angle_offset: float = -PI / 2.0
) -> PackedVector2Array:
    var points := PackedVector2Array()
    var sample_count := maxi(maximum_sides, 4)
    var polygon := PackedVector2Array()

    for index in sides:
        var angle := angle_offset + TAU * float(index) / float(sides)
        polygon.append(Vector2(cos(angle), sin(angle)))

    for index in sample_count:
        var perimeter_position := float(index) * float(sides) / float(sample_count)
        var edge_index := mini(int(perimeter_position), sides - 1)
        var edge_progress := perimeter_position - float(edge_index)
        var next_index := (edge_index + 1) % sides
        points.append(
            polygon[edge_index].lerp(polygon[next_index], edge_progress)
        )

    var bounds := Rect2(points[0], Vector2.ZERO)
    for point in points:
        bounds = bounds.expand(point)
    for index in points.size():
        var center := (bounds.position + bounds.end) / 2.0
        points[index] = Vector2(
            (points[index].x - center.x) / maxf(bounds.size.x, 0.001),
            (points[index].y - center.y) / maxf(bounds.size.y, 0.001)
        )
    return points

@rpc("authority", "call_local", "reliable")
func set_target_shape(points: PackedVector2Array) -> void:
    if current_points.is_empty():
        current_points = points
        target_points = points
        _apply_shape(points)
        return

    current_points = target_points
    target_points = points
    transition_progress = 0.0

func _create_collision_segments() -> void:
    for index in maxi(maximum_sides, 4):
        var collision_shape := CollisionShape2D.new()
        collision_shape.shape = RectangleShape2D.new()
        add_child(collision_shape)
        collision_segments.append(collision_shape)

func _create_outside_shades() -> void:
    for index in maxi(maximum_sides, 4):
        var shade := Polygon2D.new()
        shade.color = outside_shade_color
        shade.z_index = -1
        add_child(shade)
        outside_shades.append(shade)

func _apply_shape(points: PackedVector2Array) -> void:
    var world_points := _to_world_points(points)
    line.points = world_points
    glow_line.points = world_points
    _apply_outside_shades(points)
    for index in collision_segments.size():
        var collision_shape := collision_segments[index]
        var is_active := index < points.size()
        collision_shape.disabled = not is_active
        if not is_active:
            continue

        var start := _to_world_point(points[index])
        var end := _to_world_point(points[(index + 1) % points.size()])
        var edge := end - start
        var rectangle := collision_shape.shape as RectangleShape2D
        rectangle.size = Vector2(edge.length(), collision_thickness)
        collision_shape.position = (start + end) / 2.0
        collision_shape.rotation = edge.angle()

func _apply_outside_shades(points: PackedVector2Array) -> void:
    for index in outside_shades.size():
        var shade := outside_shades[index]
        var is_active := index < points.size()
        shade.visible = is_active
        if not is_active:
            continue

        var start := _to_world_point(points[index])
        var end := _to_world_point(points[(index + 1) % points.size()])
        var outer_start := _to_world_point(points[index] * outside_shade_extent)
        var outer_end := _to_world_point(
            points[(index + 1) % points.size()] * outside_shade_extent
        )
        shade.polygon = PackedVector2Array([
            start,
            end,
            outer_end,
            outer_start
        ])

func _to_world_point(point: Vector2) -> Vector2:
    return Vector2(
        point.x * current_arena_size.x,
        point.y * current_arena_size.y
    )

func _to_world_points(points: PackedVector2Array) -> PackedVector2Array:
    var world_points := PackedVector2Array()
    for point in points:
        world_points.append(_to_world_point(point))
    return world_points
