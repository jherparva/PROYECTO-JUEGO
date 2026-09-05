## DockEra13D / Dock_Era1 — Muelle de Piedra Labrada (Era 1 / Edad de Piedra).
##
## Extiende Dock3D reutilizando toda la arquitectura náutica, colas de barcos y zona DropOffPoint.

class_name DockEra13D
extends "res://scripts/buildings/dock_3d.gd"

func _init() -> void:
	super._init()
	building_name = "Muelle de Piedra Labrada"
	salud_maxima = 1000.0
	salud_actual = 1000.0

func _ready() -> void:
	super._ready()
	add_to_group("docks_era1")
