## Soldier — Unidad de combate con detección de enemigos y auto-agresión.
##
## Extiende UnitBase con:
##   • Área de detección para agresión automática en Idle.
##   • Comando de patrulla entre dos puntos.
##   • Stats de combate superiores al Villager.
##
## Conecta la escena:
##   Hijos requeridos: StateMachine (con estados Idle/Move/Attacking)
##                     Area2D llamada "DetectionArea" con CollisionShape2D
##   Hijos opcionales: AnimatedSprite2D, SelectionIndicator

class_name Soldier
extends UnitBase

# ─── Stats de Patrulla ─────────────────────────────────────────────────────────
@export_group("Detection")
## Rango de detección automática de enemigos (en píxeles).
@export var detection_range: float = 150.0

# ─── Referencias a Hijos ───────────────────────────────────────────────────────
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var detection_area: Area2D = $DetectionArea if has_node("DetectionArea") else null

# ─── Inicialización ────────────────────────────────────────────────────────────

func _setup_stats() -> void:
	unit_name       = "Soldier"
	max_hp          = 120
	hp              = max_hp
	speed           = 100.0
	attack_damage   = 12
	attack_range    = 40.0
	attack_cooldown = 1.2

	# Conectar el área de detección para auto-agresión
	if is_instance_valid(detection_area):
		if not detection_area.body_entered.is_connected(_on_enemy_detected):
			detection_area.body_entered.connect(_on_enemy_detected)

func _auto_setup_sprite() -> void:
	if not is_instance_valid(animated_sprite):
		return
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle"):
		return
	var texture := load("res://resources/sprites/units/soldier.png") as Texture2D
	if texture == null:
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var fw := texture.get_width() / 8.0
	var fh := float(texture.get_height())
	var anims := [
		{"name": "idle",   "start": 0, "count": 4, "fps": 6.0,  "loop": true},
		{"name": "walk",   "start": 4, "count": 4, "fps": 8.0,  "loop": true},
		{"name": "attack", "start": 4, "count": 4, "fps": 10.0, "loop": false},
	]
	for anim in anims:
		var anim_name: StringName = anim["name"]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim["loop"])
		frames.set_animation_speed(anim_name, anim["fps"])
		for i in anim["count"]:
			var col: int = anim["start"] + i
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * fw, 0, fw, fh)
			frames.add_frame(anim_name, atlas)
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")

# ─── Auto-Agresión ─────────────────────────────────────────────────────────────

## Se activa cuando un cuerpo entra al área de detección.
## Solo ataca si la unidad está en Idle para no interrumpir órdenes del jugador.
func _on_enemy_detected(body: Node) -> void:
	if body == self:
		return
	if not state_machine or not state_machine.is_in_state(&"Idle"):
		return
	if body.is_in_group("enemies"):
		command_attack(body)

# ─── Comandos Específicos ──────────────────────────────────────────────────────

## Ordena patrullar entre dos puntos. Implementación simple: mueve a B,
## el StateMove retornará a Idle y se puede conectar un loop externo.
func command_patrol(point_a: Vector2, point_b: Vector2) -> void:
	if state_machine:
		# Guardamos point_a para el retorno en el contexto (extensible)
		state_machine.change_state(&"Move", {
			"target_position":    point_b,
			"on_arrival_state":   &"Move",
			"on_arrival_context": {
				"target_position":    point_a,
				"on_arrival_state":   &"Idle",
			},
		})

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
