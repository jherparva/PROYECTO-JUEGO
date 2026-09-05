## SpriteSetup — Autoload utilitario para generar SpriteFrames programáticamente.
##
## Crea animaciones desde spritesheets PNG sin necesidad de configuración
## manual en el editor de Godot.
##
## Uso:
##   SpriteSetup.apply_unit_sprite(animated_sprite, "res://resources/sprites/units/villager.png", 4)

extends Node

# ─── Definición de animaciones ────────────────────────────────────────────────
# Cada entrada: { nombre: String, frame_start: int, frame_count: int, fps: float, loop: bool }

const UNIT_ANIMATIONS := [
	{ "name": "idle",   "start": 0, "count": 4, "fps": 6.0,  "loop": true  },
	{ "name": "walk",   "start": 4, "count": 4, "fps": 8.0,  "loop": true  },
	{ "name": "attack", "start": 4, "count": 4, "fps": 10.0, "loop": false },
	{ "name": "gather", "start": 4, "count": 4, "fps": 8.0,  "loop": true  },
	{ "name": "repair", "start": 4, "count": 4, "fps": 8.0,  "loop": true  },
]

# ─── API Pública ──────────────────────────────────────────────────────────────

## Genera y aplica SpriteFrames a un AnimatedSprite2D desde un spritesheet.
## sheet_path: ruta "res://" al PNG.
## total_cols: número de columnas (frames) en la fila del sheet.
## frame_size: tamaño de cada frame. Si es Vector2.ZERO se calcula automático.
static func apply_unit_sprite(
	sprite: AnimatedSprite2D,
	sheet_path: String,
	total_cols: int = 8,
	frame_size: Vector2 = Vector2.ZERO
) -> void:
	if not is_instance_valid(sprite):
		push_error("SpriteSetup: AnimatedSprite2D inválido.")
		return

	var texture := load(sheet_path) as Texture2D
	if texture == null:
		push_error("SpriteSetup: No se pudo cargar la textura: %s" % sheet_path)
		return

	# Calcular tamaño de frame si no se pasó
	var img_size := texture.get_size()
	var f_size := frame_size
	if f_size == Vector2.ZERO:
		f_size = Vector2(img_size.x / float(total_cols), img_size.y)

	var frames := SpriteFrames.new()
	frames.remove_animation("default")  # Quitar la animación por defecto vacía

	for anim_def in UNIT_ANIMATIONS:
		var anim_name: StringName = anim_def["name"]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim_def["loop"])
		frames.set_animation_speed(anim_name, anim_def["fps"])

		var start: int = anim_def["start"]
		var count: int = anim_def["count"]

		for i in count:
			var col := (start + i) % total_cols
			var region := Rect2(col * f_size.x, 0, f_size.x, f_size.y)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			frames.add_frame(anim_name, atlas)

	sprite.sprite_frames = frames
	sprite.animation = "idle"
	sprite.play("idle")

## Aplica una textura simple a un Sprite2D (para edificios y recursos).
## region: Rect2 de la región dentro del sheet. Rect2() = imagen completa.
static func apply_building_sprite(
	sprite: Sprite2D,
	sheet_path: String,
	region: Rect2 = Rect2()
) -> void:
	if not is_instance_valid(sprite):
		return
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		push_error("SpriteSetup: No se pudo cargar textura: %s" % sheet_path)
		return
	if region != Rect2():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		sprite.texture = atlas
	else:
		sprite.texture = texture
