extends CanvasLayer

@export_group("Parallax")
@export_range(0.0, 1.0) var deep_parallax := 0.015
@export_range(0.0, 1.0) var nebula_parallax := 0.30
@export_range(0.0, 1.0) var star_parallax := 0.85

@export_group("Animation")
@export var animation_enabled := true
@export var nebula_animation_speed := 0.018

@export_group("Grid")
@export var grid_enabled := true
@export var grid_animation_enabled := true
@export_range(0.0, 2.0, 0.01) var grid_animation_speed := 0.15
@export_range(10.0, 1000.0, 10.0) var grid_size := 180.0
@export_range(0.5, 5.0, 0.1) var grid_line_thickness := 1.5
@export_range(0.0, 3.0, 0.1) var grid_glow_strength := 1.2
@export_range(0.0, 1.0, 0.01) var camera_exclusion_radius := 0.12
@export_range(0.001, 0.5, 0.001) var camera_fade_softness := 0.08

@export_group("Nebula Noise")
@export_range(64, 2048, 64) var noise_texture_size := 256

@export_group("Large Scale Noise")
@export var large_seed := 42
@export var large_frequency := 0.006
@export_range(1, 8) var large_octaves := 4
@export var large_gain := 0.5

@export_group("Medium Scale Noise")
@export var medium_seed := 1234
@export var medium_frequency := 0.018
@export_range(1, 8) var medium_octaves := 5
@export var medium_gain := 0.48

@export_group("Fine Scale Noise")
@export var fine_seed := 5678
@export var fine_frequency := 0.045
@export_range(1, 8) var fine_octaves := 3
@export var fine_gain := 0.4

@onready var deep_space: ColorRect = $DeepSpace
@onready var nebula_layer: ColorRect = $Nebula
@onready var starfield: ColorRect = $Starfield
@onready var grid_layer: ColorRect = $Grid

var camera: Camera2D

var deep_material: ShaderMaterial
var nebula_material: ShaderMaterial
var star_material: ShaderMaterial
var grid_material: ShaderMaterial

func _ready() -> void:
    layer = -1

    deep_material = deep_space.material.duplicate()
    nebula_material = nebula_layer.material.duplicate()
    star_material = starfield.material.duplicate()
    grid_material = grid_layer.material.duplicate()
    
    deep_space.material = deep_material
    nebula_layer.material = nebula_material
    starfield.material = star_material
    grid_layer.material = grid_material

    deep_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    nebula_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    starfield.mouse_filter = Control.MOUSE_FILTER_IGNORE
    grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

    deep_space.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    nebula_layer.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    starfield.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    grid_layer.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )

    nebula_material.set_shader_parameter(
        "noise_texture", generate_nebula_noise())
        
    grid_layer.visible = grid_enabled
    camera = get_viewport().get_camera_2d()

func _process(_delta: float) -> void:
    if not is_instance_valid(camera):
        camera = get_viewport().get_camera_2d()
    if not is_instance_valid(camera):
        return

    var camera_pos := camera.get_screen_center_position()
    var zoom := camera.zoom.x
    var viewport_size := (get_viewport().get_visible_rect().size)
    
    update_layer(
        deep_material,
        camera_pos,
        deep_parallax,
        zoom,
        viewport_size
    )

    update_layer(
        nebula_material,
        camera_pos,
        nebula_parallax,
        zoom,
        viewport_size
    )

    update_layer(
        star_material,
        camera_pos,
        star_parallax,
        zoom,
        viewport_size
    )

    # --------------------------------
    # GRID
    # --------------------------------
    
    grid_layer.visible = grid_enabled
    if grid_enabled:
        grid_material.set_shader_parameter(
            "camera_position", camera.get_screen_center_position())
        grid_material.set_shader_parameter(
            "zoom", camera.zoom.x)
        grid_material.set_shader_parameter(
            "viewport_size", viewport_size)
        grid_material.set_shader_parameter(
            "grid_size", grid_size)
        grid_material.set_shader_parameter(
            "line_thickness", grid_line_thickness)
        grid_material.set_shader_parameter(
            "animation_speed",
            grid_animation_speed if grid_animation_enabled else 0.0)
        grid_material.set_shader_parameter(
            "glow_strength", grid_glow_strength)
        grid_material.set_shader_parameter(
            "camera_exclusion_radius", camera_exclusion_radius)
        grid_material.set_shader_parameter(
            "camera_fade_softness", camera_fade_softness)

    # --------------------------------
    # NEBULA ANIMATION
    # --------------------------------

    nebula_material.set_shader_parameter(
        "timeScaleFactor",
        nebula_animation_speed if animation_enabled else 0.0
    )

func generate_nebula_noise() -> ImageTexture:
    var large_noise := create_noise(
        large_seed,
        large_frequency,
        large_octaves,
        large_gain
    )

    var medium_noise := create_noise(
        medium_seed,
        medium_frequency,
        medium_octaves,
        medium_gain
    )

    var fine_noise := create_noise(
        fine_seed,
        fine_frequency,
        fine_octaves,
        fine_gain
    )

    var size := noise_texture_size
    var image := Image.create(
        size,
        size,
        false,
        Image.FORMAT_RGBA8
    )

    for y in range(size):
        for x in range(size):
            var px := float(x)
            var py := float(y)
            var s := float(size)

            var large := seamless_noise(large_noise, px, py, s)
            var medium := seamless_noise(medium_noise, px, py, s)
            var fine := seamless_noise(fine_noise, px, py, s)

            # Secondary fine detail.
            var fine_secondary := seamless_noise(
                fine_noise,
                px + s * 0.37,
                py + s * 0.61,
                s
            )

            image.set_pixel(
                x, y,
                Color(
                    large,
                    medium,
                    fine,
                    fine_secondary
                )
            )

    return ImageTexture.create_from_image(image)

func create_noise(
    seed_value: int,
    frequency: float,
    octaves: int,
    gain: float
) -> FastNoiseLite:
    var noise := FastNoiseLite.new()

    noise.seed = seed_value
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

    noise.frequency = frequency

    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = octaves
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = gain

    return noise


# Blends four offset samples to create a repeating noise tile.
func seamless_noise(
    noise: FastNoiseLite,
    x: float,
    y: float,
    size: float
) -> float:
    var tx := x / size
    var ty := y / size

    var wx := tx * tx * (3.0 - 2.0 * tx)
    var wy := ty * ty * (3.0 - 2.0 * ty)

    var n00 := noise.get_noise_2d(x, y)
    var n10 := noise.get_noise_2d(x - size, y)

    var n01 := noise.get_noise_2d(x, y - size)
    var n11 := noise.get_noise_2d(
        x - size,
        y - size
    )

    var top := lerpf(n00, n10, wx)
    var bottom := lerpf(n01, n11, wx)

    return clamp(
        lerp(top, bottom, wy) * 0.5 + 0.5,
        0.0,
        1.0
    )

func update_layer(
    material: ShaderMaterial,
    camera_pos: Vector2,
    parallax: float,
    zoom: float,
    viewport_size: Vector2
) -> void:
    material.set_shader_parameter(
        "camera_position", camera_pos * parallax)
    material.set_shader_parameter(
        "zoom", zoom)
    material.set_shader_parameter(
        "world_scale", viewport_size)
