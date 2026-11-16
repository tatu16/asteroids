extends Node2D

@export var max_points := 60
@export var trail_offset := 8.0
@export var rear_offset := 24.0
@export var minimum_speed := 10.0
@export var trail_width := 4.0
@export var trail_color := Color(1.0, 1.0, 1.0, 0.6)

@onready var left_trail: Line2D = $LeftTrail
@onready var right_trail: Line2D = $RightTrail

var player: CharacterBody2D
var ship_sprite: Sprite2D
var prev_position := Vector2.ZERO
var has_prev_position := false

func _ready() -> void:
    _find_references()

    left_trail.top_level = true
    right_trail.top_level = true

    left_trail.global_position = Vector2.ZERO
    left_trail.global_rotation = 0.0
    left_trail.global_scale = Vector2.ONE
    right_trail.global_position = Vector2.ZERO
    right_trail.global_rotation = 0.0
    right_trail.global_scale = Vector2.ONE

    # render behind the ship
    left_trail.z_as_relative = false
    right_trail.z_as_relative = false
    left_trail.z_index = 0
    right_trail.z_index = 0

    # gradient for fadeout effect
    var gradient := Gradient.new()
    gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
    gradient.set_color(1, trail_color)
    left_trail.gradient = gradient
    right_trail.gradient = gradient

    # width curve
    var width_curve := Curve.new()
    width_curve.add_point(Vector2(0.0, 0.0))
    width_curve.add_point(Vector2(1.0, 1.0))
    left_trail.width_curve = width_curve
    right_trail.width_curve = width_curve
    left_trail.width = trail_width
    right_trail.width = trail_width

func _find_references() -> void:
    if player == null:
        var current: Node = get_parent()
        while current != null:
            if current is CharacterBody2D:
                player = current as CharacterBody2D
                break
            current = current.get_parent()

    if ship_sprite == null and player != null:
        ship_sprite = player.get_node_or_null("Visuals/ShipSprite") as Sprite2D
        if ship_sprite == null and get_parent() != null:
            ship_sprite = get_parent().get_node_or_null("ShipSprite") as Sprite2D

func _process(delta: float) -> void:
    if player == null or ship_sprite == null:
        _find_references()
        if player == null or ship_sprite == null:
            return

    var current_pos := player.global_position
    var speed := player.velocity.length()
    if speed <= 0.0 and delta > 0.0 and has_prev_position:
        speed = (current_pos - prev_position).length() / delta
    prev_position = current_pos
    has_prev_position = true

    if speed < minimum_speed:
        # Smoothly shrink trail when below speed threshold
        if left_trail.get_point_count() > 0:
            left_trail.remove_point(0)
        if right_trail.get_point_count() > 0:
            right_trail.remove_point(0)
        return

    var ship_rotation := ship_sprite.global_rotation
    var origin := ship_sprite.global_position

    # Rear offset: ship sprite faces up (+Y local = rear due to 90° rotation offset)
    var rear_dir := Vector2(0, rear_offset).rotated(ship_rotation)
    var rear_center := origin + rear_dir

    # Left/right offset perpendicular to facing direction
    var side_dir := Vector2(trail_offset, 0).rotated(ship_rotation)
    var left_position := rear_center - side_dir
    var right_position := rear_center + side_dir

    # Points are in world space since trails are top-level
    left_trail.add_point(left_trail.to_local(left_position))
    right_trail.add_point(right_trail.to_local(right_position))

    while left_trail.get_point_count() > max_points:
        left_trail.remove_point(0)

    while right_trail.get_point_count() > max_points:
        right_trail.remove_point(0)
