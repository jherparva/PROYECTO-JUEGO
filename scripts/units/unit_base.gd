## UnitBase — Clase base para todas las unidades del juego.
##
## Proporciona: stats, HP/daño/muerte, selección, registro de población,
## y un puente de comandos hacia la StateMachine.
##
## API de selección compatible con SelectionManager del usuario:
##   select()   → llamado por SelectionManager.select_units()
##   deselect() → llamado por SelectionManager.deselect_all()
##
## Para crear una unidad nueva, extiende UnitBase y sobreescribe:
##   _setup_stats()   → define los valores base
##   play_animation() → conecta con AnimatedSprite2D / AnimationPlayer

class_name UnitBase
extends CharacterBody2D

# ─── Señales ───────────────────────────────────────────────────────────────────
## Emitida cuando la unidad muere (justo antes de queue_free).
signal died(unit: UnitBase)
## Emitida cada vez que cambia el HP.
signal hp_changed(current: int, maximum: int)
## Emitida al seleccionar / deseleccionar.
signal selected_changed(is_selected: bool)

# ─── Stats Exportables ─────────────────────────────────────────────────────────
@export_group("Identidad")
@export var unit_name: String = "Unit"
## Era de la unidad (0=Piedra, 1=Bronce, 2=Hierro, 3=Medieval, …)
@export var era: int = 0

@export_group("Combat")
@export var max_hp: int = 100
@export var attack_damage: int = 5
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0

@export_group("Movement")
@export var speed: float = 100.0

@export_group("Ranged Combat")
@export var projectile_scene: PackedScene = null
@export var aoe_radius: float = 0.0

# ─── Estado en Tiempo de Ejecución ────────────────────────────────────────────
var hp: int = 0
var is_dead: bool = false
var is_selected: bool = false

# ─── Referencias a Hijos ───────────────────────────────────────────────────────
## La StateMachine DEBE ser un hijo directo de la unidad en la escena.
@onready var state_machine: StateMachine = $StateMachine
## Indicador visual de selección (ej: anillo debajo de la unidad). Opcional.
@onready var selection_indicator: Node2D = $SelectionIndicator if has_node("SelectionIndicator") else null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _ready() -> void:
	hp = max_hp
	add_to_group("units")
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("change_current_population"):
		rm.change_current_population(1)
	_setup_stats()
	# Configurar sprites automáticamente si no tienen SpriteFrames asignados
	call_deferred("_auto_setup_sprite")

func _auto_setup_sprite() -> void:
	pass # Override en cada subclase (Villager, Soldier)

## Override para aplicar stats de un UnitData resource o lógica específica.
func _setup_stats() -> void:
	pass

## Aplica stats desde un UnitData resource (llamar desde el spawner o _ready).
func apply_unit_data(data: UnitData) -> void:
	if data == null:
		return
	unit_name       = data.unit_name
	max_hp          = data.base_hp
	speed           = data.base_speed
	attack_damage   = data.base_attack_damage
	attack_range    = data.base_attack_range
	attack_cooldown = data.base_attack_cooldown
	
	if "projectile_scene" in data:
		projectile_scene = data.projectile_scene
	if "aoe_radius" in data:
		aoe_radius = data.aoe_radius
		
	hp = max_hp

# ─── Combate ───────────────────────────────────────────────────────────────────

## Recibe daño. source es el nodo atacante (para futura lógica de aggro).
func take_damage(amount: int, _source: Node = null) -> void:
	if is_dead:
		return
	hp = maxi(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		die()

## Recupera HP (no supera max_hp).
func heal(amount: int) -> void:
	if is_dead:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

## Mata la unidad: la elimina de la selección activa, de todos los grupos de
## control y descuenta la población antes de liberarse del árbol de escena.
func die() -> void:
	if is_dead:
		return
	is_dead = true

	var sm: Node = get_node_or_null("/root/SelectionManager")
	if is_instance_valid(sm):
		if "selected_units" in sm and sm.selected_units.has(self):
			sm.selected_units.erase(self)
			if sm.has_signal("selection_changed"):
				sm.selection_changed.emit(sm.selected_units)

		if "control_groups" in sm:
			for group_id in sm.control_groups:
				sm.control_groups[group_id].erase(self)

	# Descontar población
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_method("change_current_population"):
		rm.change_current_population(-1)

	died.emit(self)
	queue_free()

# ─── Selección (API requerida por SelectionManager) ───────────────────────────

## Llamado por SelectionManager.select_units() al seleccionar.
func select() -> void:
	is_selected = true
	selected_changed.emit(true)
	if is_instance_valid(selection_indicator):
		selection_indicator.visible = true

## Llamado por SelectionManager.deselect_all() al deseleccionar.
func deselect() -> void:
	is_selected = false
	selected_changed.emit(false)
	if is_instance_valid(selection_indicator):
		selection_indicator.visible = false

# ─── Comandos (llamados por input del jugador o IA) ────────────────────────────

## Ordena moverse a una posición destino.
func command_move(target_pos: Vector2) -> void:
	if state_machine:
		state_machine.change_state(&"Move", {"target_position": target_pos})

## Ordena atacar a un nodo objetivo.
func command_attack(target: Node) -> void:
	if state_machine:
		state_machine.change_state(&"Attacking", {"target": target})

## Detiene cualquier acción activa y vuelve a Idle.
func command_stop() -> void:
	if state_machine:
		state_machine.change_state(&"Idle")

# ─── Animación (override en subclases) ────────────────────────────────────────

## Reproduce una animación por nombre. Sobreescribir para conectar al sprite.
func play_animation(_anim_name: String) -> void:
	pass  # Override en Villager / Soldier
