extends CanvasLayer

## Slow autonomous drift speed (world-space units per second).
@export var drift_speed := Vector2(8.0, 4.0)

@export_group("Floating Objects")
@export var max_objects: int = 15
@export var spawn_interval: float = 2.5

@onready var deep_space: ColorRect = $DeepSpace
@onready var nebula: ColorRect = $Nebula
@onready var starfield: ColorRect = $Starfield
@onready var objects_container: Node2D = $ObjectsContainer

const FLOATING_OBJECT_SCRIPT = preload("res://scripts/ui/menu_floating_object.gd")

var deep_material: ShaderMaterial
var nebula_material: ShaderMaterial
var star_material: ShaderMaterial

var _offset := Vector2.ZERO
var _spawn_timer: float = 0.0

var SHAPES: Array[PackedVector2Array] = [
    PackedVector2Array([Vector2(-24, 16), Vector2(0, -24), Vector2(24, 16)]), # triangle
    PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)]), # square
    PackedVector2Array([Vector2(-16, -19), Vector2(16, -19), Vector2(24, 5), Vector2(0, 21), Vector2(-24, 5)]), # pentagon
]

const COLORS: Array[Color] = [
    Color(0.35, 0.75, 0.95, 0.65), # cyan
    Color(0.65, 0.45, 0.95, 0.65), # purple
    Color(0.95, 0.95, 0.95, 0.65), # white
]

func _ready() -> void:
    layer = -1

    deep_material   = deep_space.material.duplicate()
    nebula_material = nebula.material.duplicate()
    star_material   = starfield.material.duplicate()

    deep_space.material = deep_material
    nebula.material     = nebula_material
    starfield.material  = star_material

    deep_space.mouse_filter  = Control.MOUSE_FILTER_IGNORE
    nebula.mouse_filter      = Control.MOUSE_FILTER_IGNORE
    starfield.mouse_filter   = Control.MOUSE_FILTER_IGNORE

    deep_space.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    nebula.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    starfield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    nebula_material.set_shader_parameter("noise_texture", _generate_noise())

    _initial_spawn()

func _exit_tree() -> void:
    clear_all_objects()

func clear_all_objects() -> void:
    if is_instance_valid(objects_container):
        for child in objects_container.get_children():
            child.queue_free()

func _initial_spawn() -> void:
    var viewport_rect := get_viewport().get_visible_rect()
    var count := randi_range(5, 8)
    for i in count:
        var pos = Vector2(
            randf_range(viewport_rect.position.x, viewport_rect.end.x),
            randf_range(viewport_rect.position.y, viewport_rect.end.y)
        )
        _spawn_object_at(pos)

func _process(delta: float) -> void:
    _offset += drift_speed * delta

    var viewport_size := get_viewport().get_visible_rect().size

    deep_material.set_shader_parameter("camera_position", _offset * 0.015)
    deep_material.set_shader_parameter("world_scale", viewport_size)
    deep_material.set_shader_parameter("zoom", 1.0)

    nebula_material.set_shader_parameter("camera_position", _offset * 0.30)
    nebula_material.set_shader_parameter("world_scale", viewport_size)
    nebula_material.set_shader_parameter("zoom", 1.0)

    star_material.set_shader_parameter("star_speed", drift_speed * 0.000012)

    _spawn_timer += delta
    if _spawn_timer >= spawn_interval:
        _spawn_timer = 0.0
        _try_spawn_object()

func _try_spawn_object() -> void:
    if not is_instance_valid(objects_container):
        return

    if objects_container.get_child_count() >= max_objects:
        return

    var viewport_rect := get_viewport().get_visible_rect()
    var padding := 50.0

    # pick an edge outside the screen to spawn from
    var edge := randi() % 4
    var spawn_pos := Vector2.ZERO
    match edge:
        0: # Top
            spawn_pos = Vector2(randf_range(0.0, viewport_rect.size.x), -padding)
        1: # Bottom
            spawn_pos = Vector2(randf_range(0.0, viewport_rect.size.x), viewport_rect.size.y + padding)
        2: # Left
            spawn_pos = Vector2(-padding, randf_range(0.0, viewport_rect.size.y))
        3: # Right
            spawn_pos = Vector2(viewport_rect.size.x + padding, randf_range(0.0, viewport_rect.size.y))

    _spawn_object_at(spawn_pos)

func _spawn_object_at(pos: Vector2) -> void:
    if not is_instance_valid(objects_container):
        return

    var viewport_rect := get_viewport().get_visible_rect()
    # once object drifts out of this extended bounds, it will be freed
    var extended_bounds := viewport_rect.grow(120.0)

    var obj := Node2D.new()
    obj.set_script(FLOATING_OBJECT_SCRIPT)
    obj.position = pos

    var shape_points: PackedVector2Array = SHAPES.pick_random()
    var color: Color = COLORS.pick_random()
    var random_scale := randf_range(0.7, 1.4)
    obj.scale = Vector2(random_scale, random_scale)

    obj.initialize(shape_points, color, extended_bounds)
    objects_container.add_child(obj)

func _generate_noise() -> ImageTexture:
    var size := 256
    var image := Image.create(size, size, false, Image.FORMAT_RGBA8)

    var cfgs := [
        [42,   0.006, 4, 0.50],
        [1234, 0.018, 5, 0.48],
        [5678, 0.045, 3, 0.40],
    ]
    var noises: Array[FastNoiseLite] = []
    for cfg in cfgs:
        var n := FastNoiseLite.new()
        n.seed               = cfg[0]
        n.noise_type         = FastNoiseLite.TYPE_SIMPLEX
        n.frequency          = cfg[1]
        n.fractal_type       = FastNoiseLite.FRACTAL_FBM
        n.fractal_octaves    = cfg[2]
        n.fractal_lacunarity = 2.0
        n.fractal_gain       = cfg[3]
        noises.append(n)

    for y in size:
        for x in size:
            var px := float(x)
            var py := float(y)
            var s  := float(size)
            image.set_pixel(x, y, Color(
                _seamless(noises[0], px, py, s),
                _seamless(noises[1], px, py, s),
                _seamless(noises[2], px, py, s),
                _seamless(noises[2], px + s * 0.37, py + s * 0.61, s)
            ))

    return ImageTexture.create_from_image(image)

func _seamless(n: FastNoiseLite, x: float, y: float, size: float) -> float:
    var tx := x / size
    var ty := y / size
    var wx := tx * tx * (3.0 - 2.0 * tx)
    var wy := ty * ty * (3.0 - 2.0 * ty)
    var v := lerpf(
        lerpf(n.get_noise_2d(x, y),        n.get_noise_2d(x - size, y),        wx),
        lerpf(n.get_noise_2d(x, y - size), n.get_noise_2d(x - size, y - size), wx),
        wy
    )
    return clamp(v * 0.5 + 0.5, 0.0, 1.0)
