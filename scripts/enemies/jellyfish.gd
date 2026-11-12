extends Enemy

@export var slide_interval: float = 4.0
@export var slide_start_speed_multiplier: float = 4.0
@export var slide_deceleration: float = 35.0
@export var restart_delay: float = 0.50

var slide_direction := Vector2.ZERO
var slide_time_left: float = 0.0
var restart_time_left: float = 0.0

func _ready() -> void:
    super()
    if animated_sprite != null:
        animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
    if not multiplayer.is_server():
        return

    var closest_player := get_closest_player() as Player
    if closest_player == null:
        velocity = Vector2.ZERO
        return

    if slide_time_left <= 0.0 and velocity.is_zero_approx():
        if restart_time_left > 0.0:
            restart_time_left = maxf(restart_time_left - delta, 0.0)
            move_and_slide()
            return

        slide_direction = global_position.direction_to(closest_player.global_position)
        slide_time_left = slide_interval
        velocity = slide_direction * move_speed * slide_start_speed_multiplier
        rotation = slide_direction.angle() + GameManager.SPRITE_ROTATION_OFFSET
        play_move_animation()

    slide_time_left = maxf(slide_time_left - delta, 0.0)
    velocity = velocity.move_toward(
        Vector2.ZERO,
        slide_deceleration * delta
    )
    if velocity.is_zero_approx():
        restart_time_left = restart_delay
    move_and_slide()

func play_move_animation() -> void:
    if animated_sprite == null or animated_sprite.sprite_frames == null:
        return
    if animated_sprite.sprite_frames.has_animation(&"move"):
        animated_sprite.play(&"move")

func _on_animation_finished() -> void:
    if animated_sprite == null:
        return
    if animated_sprite.animation == &"move":
        play_default_animation()
