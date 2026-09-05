## Stable3D — Establo Real y Corral Primitivo 3D (GDScript 2.0 / Godot 4).
##
## Edificación militar y ecuestre:
## - En la Edad de Piedra (Era 1): Actúa como Corral Temprano, permitiendo la investigación
##   pasiva de velocidad de monturas ('investigar_velocidad_monturas()') para la IA Skirmish.
## - A partir de la Edad del Cobre (Era 2+): Entrena tropas de caballería montada y carros.

class_name Stable3D
extends "res://scripts/buildings/barracks_3d.gd"

signal mount_speed_researched()
signal cavalry_trained(unit: Node3D)

var velocidad_monturas_investigada: bool = false
var research_cost: Dictionary = {"food": 60, "wood": 40}

func _init() -> void:
	building_name = "Corral / Establo Temprano"
	salud_maxima = 600.0
	salud_actual = 600.0

func _ready() -> void:
	super._ready()
	add_to_group("stables")
	add_to_group("military_buildings")
	add_to_group("player_buildings" if bando == Bando.PLAYER else "enemy_buildings")

	rally_point = global_position + Vector3(4.0, 0.0, 4.0)

## Investigación pasiva de velocidad de monturas para la IA Skirmish y el jugador
func investigar_velocidad_monturas() -> bool:
	if is_dead or is_under_construction or velocidad_monturas_investigada:
		return false

	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm):
		var success := false
		if rm.has_method("gastar_recursos"):
			success = rm.gastar_recursos(research_cost)
		elif rm.has_method("spend_resources"):
			success = rm.spend_resources(research_cost)

		if not success:
			print("Stable3D: Recursos insuficientes para investigar velocidad de monturas.")
			return false

	velocidad_monturas_investigada = true

	# Aplicar bonificación en CivPointsManager
	var cpm: Node = get_node_or_null("/root/CivPointsManager")
	if is_instance_valid(cpm):
		if cpm.has_method("comprar_mejora_local"):
			cpm.call("comprar_mejora_local", "cavalry_speed")

	mount_speed_researched.emit()
	print("Stable3D '%s': ¡Investigación completada! Velocidad de monturas y caballería incrementada (+15%%)." % name)
	return true
