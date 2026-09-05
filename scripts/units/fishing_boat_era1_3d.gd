## FishingBoatEra13D / Barco_Pesca_Piedra — Barco de Pesca con Redes de Fibra (Era 1).
##
## Extiende FishingBoat3D reutilizando la navegación a Y = -1.8m, bodega de 20 peces y descarga DropOffPoint.

class_name FishingBoatEra13D
extends "res://scripts/units/fishing_boat_3d.gd"

func _init() -> void:
	unit_name = "Barco de Pesca de Piedra"
	salud_maxima = 450.0
	salud_actual = 450.0
	speed = 5.2

func _ready() -> void:
	super._ready()
	add_to_group("fishing_boats_era1")
