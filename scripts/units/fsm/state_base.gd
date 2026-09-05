## StateBase — Clase base abstracta para todos los estados de unidad.
##
## Hereda esta clase para crear estados concretos.
## Los métodos virtuales (enter, update, physics_update, exit) deben ser
## sobreescritos en cada subclase según la lógica del estado.
##
## Patrón: State Pattern (GOF)

class_name StateBase
extends Node

# ─── Identidad ─────────────────────────────────────────────────────────────────
## Nombre único de este estado. Sobreescribir en cada subclase con @export.
@export var state_name: StringName = &"State"

# ─── Referencias ───────────────────────────────────────────────────────────────
## Inyectado por StateMachine al llamar _ready(). No modificar manualmente.
var state_machine: StateMachine = null
## El nodo de unidad que posee la StateMachine (CharacterBody2D, etc.)
var unit: Node = null

# ─── Métodos Virtuales (sobreescribir en subclases) ────────────────────────────

## Llamado al entrar a este estado.
## [br]context: diccionario con datos de la transición (target_position, target, etc.)
func enter(_context: Dictionary = {}) -> void:
	pass

## Llamado cada frame (_process) mientras se está en este estado.
func update(_delta: float) -> void:
	pass

## Llamado cada frame de física (_physics_process) mientras se está en este estado.
func physics_update(_delta: float) -> void:
	pass

## Llamado al salir de este estado (cleanup de referencias y timers).
func exit() -> void:
	pass
