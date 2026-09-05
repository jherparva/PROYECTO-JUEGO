## BuildingBase — Clase base para todos los edificios del juego.
##
## Gestiona HP, estado de construcción, daño y destrucción.
## Contiene una ProductionQueue para edificios que producen unidades.
##
## Patrón: Template Method para destrucción y construcción.
## Uso: subclases como Barracks, TownCenter, etc. extienden esta clase.

class_name BuildingBase
extends StaticBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
## Emitida cada vez que cambia el HP del edificio.
signal hp_changed(current: int, maximum: int)
## Emitida cuando la construcción se completa (hp llega a max_hp por primera vez).
signal construction_completed()
## Emitida al ser destruido.
signal destroyed()

# ─── Stats Exportables ─────────────────────────────────────────────────────────
@export_group("Identidad")
@export var building_name: String = "Building"
## Era a la que pertenece este edificio (0=Piedra, 1=Bronce, …)
@export var era: int = 0

@export_group("HP")
@export var max_hp: int = 500
## Si true, el edificio empieza con HP=1 (en construcción).
@export var starts_under_construction: bool = false

# ─── Estado en Tiempo de Ejecución ────────────────────────────────────────────
var hp: int = 0
var is_under_construction: bool = false
var is_dead: bool = false

# ─── Hijos ─────────────────────────────────────────────────────────────────────
## Cola de producción (puede ser null si el edificio no produce unidades).
@onready var production_queue: ProductionQueue = $ProductionQueue if has_node("ProductionQueue") else null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	is_under_construction = starts_under_construction
	hp = 1 if is_under_construction else max_hp
	add_to_group("buildings")
	_update_visuals()
	call_deferred("_auto_setup_sprite")

func _auto_setup_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not is_instance_valid(sprite) or sprite.texture != null:
		return
	var texture := load("res://resources/sprites/buildings/buildings.png") as Texture2D
	if texture == null:
		return
	# El sheet tiene 4 edificios en 2x2. Usamos el Town Center (celda 0,0).
	var fw := texture.get_width() / 2.0
	var fh := texture.get_height() / 2.0
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, fw, fh)
	sprite.texture = atlas

# ─── Daño / Reparación ────────────────────────────────────────────────────────

## Recibe daño de cualquier fuente.
func take_damage(amount: int, _source: Node = null) -> void:
	if is_dead:
		return
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		_destroy()

## Repara el edificio en `amount` HP. Si estaba en construcción y llega a max_hp,
## marca la construcción como completada.
func repair(amount: int) -> void:
	if is_dead:
		return
	var was_under_construction := is_under_construction
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

	if was_under_construction:
		if hp >= max_hp:
			is_under_construction = false
			construction_completed.emit()
		_update_visuals()

## Alias para compatibilidad con duck-typing de StateRepairing.
func heal(amount: int) -> void:
	repair(amount)

# ─── Cola de Producción ────────────────────────────────────────────────────────

## Encola una unidad para producción. Retorna el id de la orden o -1 si falla.
func enqueue_unit(unit_data: UnitData) -> int:
	if is_under_construction or is_dead:
		push_warning("BuildingBase '%s': no puede producir (en construcción o destruido)." % building_name)
		return -1
	if production_queue == null:
		push_warning("BuildingBase '%s': no tiene ProductionQueue." % building_name)
		return -1
	return production_queue.enqueue(unit_data)

## Cancela una orden de producción por id.
func cancel_production(order_id: int) -> bool:
	if production_queue == null:
		return false
	return production_queue.cancel(order_id)

# ─── Interno ───────────────────────────────────────────────────────────────────

func _update_visuals() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if is_instance_valid(sprite):
		if is_under_construction:
			# Visual de andamiaje / cimiento: semitransparente y azulado
			sprite.modulate = Color(0.4, 0.6, 1.0, 0.6)
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _destroy() -> void:
	if is_dead:
		return
	is_dead = true
	# Cancelar toda la cola y reembolsar recursos
	if production_queue:
		production_queue.cancel_all(true)
	destroyed.emit()
	queue_free()
