## Villager — Unidad recolectora y constructora.
##
## Extiende UnitBase con mecánicas de recolección de recursos y reparación.
## Stats por defecto bajos en combate, alta eficiencia en trabajo.
##
## Comandos adicionales:
##   command_gather(resource_node) → StateGathering
##   command_repair(building)      → StateRepairing
##
## Conecta la escena:
##   Hijos requeridos: StateMachine (con estados Idle/Move/Gathering/Attacking/Repairing)
##   Hijos opcionales: AnimatedSprite2D, SelectionIndicator

class_name Villager
extends UnitBase

# ─── Stats de Trabajo ──────────────────────────────────────────────────────────
@export_group("Gathering")
## Capacidad máxima de carga de recursos (en unidades).
@export var carry_capacity: int = 10
## Recursos recolectados por segundo.
@export var gather_rate: float = 1.0

@export_group("Construction")
## HP de edificio reparado/construido por segundo (convertido en ticks de repair_interval).
@export var build_speed: float = 10.0

# ─── Referencias a Hijos ───────────────────────────────────────────────────────
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# ─── Inicialización ────────────────────────────────────────────────────────────

func _setup_stats() -> void:
	unit_name       = "Villager"
	max_hp          = 60
	hp              = max_hp
	speed           = 90.0
	attack_damage   = 3
	attack_range    = 25.0
	attack_cooldown = 1.5

func _auto_setup_sprite() -> void:
	if not is_instance_valid(animated_sprite):
		return
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle"):
		return
	var texture := load("res://resources/sprites/units/villager.png") as Texture2D
	if texture == null:
		_create_placeholder_visual(Color(0.8, 0.6, 0.2))
		return
	# Usar la imagen completa como un único frame (sin spritesheet)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in ["idle", "walk", "attack", "gather", "repair"]:
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 1.0)
		frames.add_frame(anim_name, texture)
	animated_sprite.sprite_frames = frames
	animated_sprite.scale = Vector2(1.0, 1.0)
	animated_sprite.play("idle")

## Dibuja un shape simple con código cuando los PNG aún no están importados.
func _create_placeholder_visual(body_color: Color) -> void:
	# Cuerpo (círculo)
	var body := Polygon2D.new()
	var points: PackedVector2Array = []
	var segments := 12
	for i in segments:
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	body.polygon = points
	body.color = body_color
	body.position = Vector2.ZERO
	add_child(body)
	# Cabeza
	var head := Polygon2D.new()
	var hpoints: PackedVector2Array = []
	for i in segments:
		var angle := TAU * i / segments
		hpoints.append(Vector2(cos(angle), sin(angle)) * 5)
	head.polygon = hpoints
	head.color = body_color.lightened(0.3)
	head.position = Vector2(0, -14)
	add_child(head)
	# Indicador de dirección (punto azul)
	var dir_dot := Polygon2D.new()
	var dpoints: PackedVector2Array = []
	for i in 8:
		var angle := TAU * i / 8
		dpoints.append(Vector2(cos(angle), sin(angle)) * 3)
	dir_dot.polygon = dpoints
	dir_dot.color = Color(0.2, 0.5, 1.0)
	dir_dot.position = Vector2(0, -8)
	add_child(dir_dot)

# ─── Comandos Específicos ──────────────────────────────────────────────────────

## Ordena al aldeano recolectar un nodo de recurso.
func command_gather(resource_node: Node) -> void:
	if state_machine:
		state_machine.change_state(&"Gathering", {"target_node": resource_node})

## Ordena al aldeano reparar (o construir) un edificio.
func command_repair(building: Node) -> void:
	if state_machine:
		state_machine.change_state(&"Repairing", {"target": building})

# ─── Animación ─────────────────────────────────────────────────────────────────

func play_animation(anim_name: String) -> void:
	if not is_instance_valid(animated_sprite):
		return
	if animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	
	# Voltear el sprite según la velocidad horizontal
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
