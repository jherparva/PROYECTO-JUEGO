## Projectile — Entidad para ataques a distancia.
##
## Se mueve hacia un objetivo (Homing) y aplica daño al impactar.
## Si aoe_radius > 0, aplica daño de área a todos los enemigos en el radio.
##
## Uso: instanciar desde StateAttacking, configurar target y stats, y añadir a la escena.

class_name Projectile
extends Area2D

# ─── Configuración ─────────────────────────────────────────────────────────────
var speed: float = 300.0
var damage: int = 5
var aoe_radius: float = 0.0
var target: Node = null
var source_unit: Node = null

# ─── Estado ────────────────────────────────────────────────────────────────────
var _is_dead: bool = false

# ─── Nodos Visuales ────────────────────────────────────────────────────────────
@onready var sprite := Sprite2D.new()
@onready var collision := CollisionShape2D.new()

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Configurar colisión (círculo pequeño)
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)
	
	# Placeholder visual si no hay sprite asignado
	if sprite.texture == null:
		# Dibujar un cuadrito o círculo temporal
		var grad := GradientTexture2D.new()
		grad.width = 8
		grad.height = 8
		grad.fill = GradientTexture2D.FILL_LINEAR
		sprite.texture = grad
	add_child(sprite)
	
	# No detectar física constantemente, solo al procesar nosotros mismos el choque
	monitoring = false
	monitorable = false
	
	if is_inside_tree() and get_tree():
		var timer := get_tree().create_timer(5.0)
		timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
		
	if not is_instance_valid(target):
		queue_free()
		return
		
	var target_pos: Vector2 = target.global_position
	var dir := (target_pos - global_position).normalized()
	
	# Rotar sprite
	rotation = dir.angle()
	
	# Mover
	global_position += dir * speed * delta
	
	# Chequear impacto
	if global_position.distance_to(target_pos) < 10.0:
		_on_impact()

# ─── Lógica de Impacto ────────────────────────────────────────────────────────

func _on_impact() -> void:
	_is_dead = true
	
	if aoe_radius > 0.0:
		_apply_aoe_damage()
	else:
		_apply_single_damage()
		
	# Placeholder: emitir partículas aquí
	queue_free()

func _apply_single_damage() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage, source_unit)

func _apply_aoe_damage() -> void:
	# Daño de área buscando nodos enemigos en el radio
	var enemies := get_tree().get_nodes_in_group("enemies") # Asumiendo que existen
	# También podríamos buscar en units y buildings que no sean de nuestra facción
	
	# Buscar unidades genéricas por ahora que sean distintas a nuestro source
	var targets = get_tree().get_nodes_in_group("units")
	targets.append_array(get_tree().get_nodes_in_group("buildings"))
	
	for t in targets:
		if t == source_unit:
			continue
		# Si tenemos sistema de facciones, validar que 't' es de otra facción
		
		if is_instance_valid(t) and t is Node2D:
			var dist = global_position.distance_to(t.global_position)
			if dist <= aoe_radius:
				if t.has_method("take_damage"):
					t.take_damage(damage, source_unit)
