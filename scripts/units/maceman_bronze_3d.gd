## Maceman_Bronze — Macero de Cobre (Edad del Cobre / Era 2).
##
## Infantería pesada de choque que blande maza de cobre con impacto MELEE_SHOCK / Bludgeoning.
## Aplica multiplicador oficial dbunitset.dat de x1.35 contra fortificaciones de madera
## y empalizadas modulares.
class_name Maceman_Bronze
extends "res://scripts/units/soldier_3d.gd"

func _init() -> void:
	unit_id = "maceman_bronze"
	unit_name = "Macero de Cobre"
	attack_type = "melee"
	weapon_type = "bludgeoning"
	_salud_base = 160.0
	salud_maxima = 160.0
	salud_actual = 160.0
	_daño_base = 21.0
	daño = 21.0
	rango_ataque = 3.2
	velocidad_ataque = 0.82
	speed = 5.2
	era_entrenada = 2

func _ready() -> void:
	super._ready()
	add_to_group("maceman_bronze")
	add_to_group("infantry_3d")

func is_maceman_bronze() -> bool:
	return true
