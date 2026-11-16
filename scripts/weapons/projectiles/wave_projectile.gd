extends Projectile

@onready var animation_player := $AnimationPlayer as AnimationPlayer

func _ready() -> void:
    super()
    animation_player.play("attack")

func finish_wave() -> void:
    if multiplayer.is_server():
        queue_free()
