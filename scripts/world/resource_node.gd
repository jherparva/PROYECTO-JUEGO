## ResourceNode — Nodo de recurso recolectable (árbol, mina, arbusto, etc.)
##
## Implementa la interfaz que requiere StateGathering:
##   get_resource_type() → String   ("wood", "food", "gold", "iron", "stone")
##   extract(amount: int) → int     (cuánto se pudo extraer realmente)
##   is_depleted() → bool
##
## Uso en escena: coloca este script en un Node2D con Sprite2D + CollisionShape2D.
## Configura `resource_type` y `max_amount` en el inspector.

class_name ResourceNode
extends Node2D

# ─── Señales ───────────────────────────────────────────────────────────────────
signal depleted(node: ResourceNode)
signal amount_changed(current: int, maximum: int)

# ─── Exports ───────────────────────────────────────────────────────────────────
@export_enum("wood", "food", "gold", "iron", "stone") var resource_type: String = "wood"
@export var max_amount: int = 200
## Si true, el recurso se regenera después de respawn_time segundos.
@export var respawn_enabled: bool = false
@export var respawn_time: float = 60.0

# ─── Estado ────────────────────────────────────────────────────────────────────
var current_amount: int = 0
var _respawn_timer: float = 0.0

@onready var sprite: Sprite2D                  = $Sprite2D if has_node("Sprite2D") else null
@onready var collision: CollisionShape2D       = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var interaction_area: Area2D          = $InteractionArea if has_node("InteractionArea") else null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	current_amount = max_amount
	add_to_group("resources")

func _process(delta: float) -> void:
	if is_depleted() and respawn_enabled:
		_respawn_timer += delta
		if _respawn_timer >= respawn_time:
			_respawn()

# ─── Interfaz para StateGathering ─────────────────────────────────────────────

## Retorna el tipo de recurso como string compatible con ResourceManager.
func get_resource_type() -> String:
	return resource_type

## Extrae hasta `amount` unidades del nodo. Retorna cuánto se extrajo realmente.
func extract(amount: int) -> int:
	if is_depleted():
		return 0
	var extracted := mini(amount, current_amount)
	current_amount -= extracted
	amount_changed.emit(current_amount, max_amount)
	if is_depleted():
		_on_depleted()
	return extracted

## Retorna true si el recurso está completamente agotado.
func is_depleted() -> bool:
	return current_amount <= 0

# ─── Interno ───────────────────────────────────────────────────────────────────

func _on_depleted() -> void:
	depleted.emit(self)
	# Feedback visual: oscurecer el sprite
	if is_instance_valid(sprite):
		sprite.modulate = Color(0.4, 0.4, 0.4, 0.7)
	# Deshabilitar colisión para que las unidades no rodeen el nodo agotado
	if is_instance_valid(collision):
		collision.set_deferred("disabled", true)
	if not respawn_enabled:
		# Pequeño delay antes de eliminarse para que el aldeano termine su animación
		await get_tree().create_timer(1.5).timeout
		queue_free()

func _respawn() -> void:
	_respawn_timer = 0.0
	current_amount = max_amount
	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE
	if is_instance_valid(collision):
		collision.set_deferred("disabled", false)
	amount_changed.emit(current_amount, max_amount)
