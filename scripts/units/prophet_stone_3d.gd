## ProphetStone3D — Héroe Místico / Profeta de Piedra (Era 1) (Godot 4.3 / GDScript 2.0).
##
## Unidad mística especializada de la Edad de Piedra capaz de convertir tropas enemigas
## e invocar el Terremoto de Piedra (radio 8m, DoT 5 HP/s por 6s a estructuras enemigas).

class_name ProphetStone3D
extends Prophet3D

func _init() -> void:
	unit_id = "prophet_stone"
	_setup_stats()
