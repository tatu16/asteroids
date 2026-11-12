extends Projectile

func _ready() -> void:
    super()

func finish_wave() -> void:
    if multiplayer.is_server():
        queue_free()
