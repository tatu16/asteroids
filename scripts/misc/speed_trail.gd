extends Node2D

@export var max_points := 30
@export var trail_offset := 9.0
@export var rear_offset := 16.0
@export var minimum_speed := 10.0
@export var trail_width := 3.0
@export var trail_color := Color(1.0, 1.0, 1.0, 0.6)

@onready var left_trail: Line2D = $LeftTrail
@onready var right_trail: Line2D = $RightTrail
@onready var player := get_parent() as CharacterBody2D
@onready var ship_visuals := player.get_node_or_null("Visuals") as Node2D

func _ready() -> void:
    # Make trails top-level so they render in world space, not relative to player
    left_trail.top_level = true
    right_trail.top_level = true

    # Set up gradient for fade-out effect
    var gradient := Gradient.new()
    gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
    gradient.set_color(1, trail_color)
    left_trail.gradient = gradient
    right_trail.gradient = gradient

    # Width curve: thin at tail, full at head
    var width_curve := Curve.new()
    width_curve.add_point(Vector2(0.0, 0.0))
    width_curve.add_point(Vector2(1.0, 1.0))
    left_trail.width_curve = width_curve
    right_trail.width_curve = width_curve
    left_trail.width = trail_width
    right_trail.width = trail_width

func _process(_delta: float) -> void:
    if player == null or ship_visuals == null:
        return

    var speed := player.velocity.length()

    if speed < minimum_speed:
        # Shrink trail when below speed threshold
        while left_trail.get_point_count() > 0:
            left_trail.remove_point(0)
        while right_trail.get_point_count() > 0:
            right_trail.remove_point(0)
        return

    var ship_rotation := ship_visuals.global_rotation
    var origin := ship_visuals.global_position

    # Rear offset: ship sprite faces up (+Y local = rear due to 90° rotation offset)
    var rear_dir := Vector2(0, rear_offset).rotated(ship_rotation)
    var rear_center := origin + rear_dir

    # Left/right offset perpendicular to facing direction
    var side_dir := Vector2(trail_offset, 0).rotated(ship_rotation)
    var left_position := rear_center - side_dir
    var right_position := rear_center + side_dir

    # Points are in world space since trails are top-level
    left_trail.add_point(left_position)
    right_trail.add_point(right_position)

    if left_trail.get_point_count() > max_points:
        left_trail.remove_point(0)

    if right_trail.get_point_count() > max_points:
        right_trail.remove_point(0)
