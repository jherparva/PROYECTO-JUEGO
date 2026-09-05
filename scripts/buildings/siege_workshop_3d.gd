## SiegeWorkshop3D — Taller de Asedio 3D (GDScript 2.0 / Godot 4).
##
## Edificio de producción de maquinaria de asedio y vehículos de guerra.
## Se habilita en el panel del aldeano cuando GlobalResourceManager.era_actual >= 2.
##
## HERENCIA TOTAL: Reutiliza la lógica completa de Barracks3D:
##   - Cola de producción (Array[String], máx 5)
##   - Timer de producción ($ProductionTimer)
##   - Reembolso al cancelar (100%)
##   - Marker3D de spawn (SpawnPoint)
##   - Escalado de stats por Era
##   - Filtro de era (era_min / era_max en CATALOGO_UNIDADES)
## Solo se sobreescribe: building_name, HP, filtro de building_type y check de Era 2.

class_name SiegeWorkshop3D
extends "res://scripts/buildings/barracks_3d.gd"

# ─── Constante: tipo de edificio para filtrar catálogo ───────────────────────
const BUILDING_TYPE: String = "siege_workshop"

func _init() -> void:
	building_name = "Taller de Asedio"
	salud_maxima  = 700.0
	salud_actual  = 700.0

func _ready() -> void:
	super._ready()
	add_to_group("siege_workshops")
	add_to_group("military_buildings")
	add_to_group("buildings_3d")
	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

# ─── Override: entrenar_unidad con validación de Era >= 2 ────────────────────

## Sobreescribe entrenar_unidad para bloquear el taller si era_actual < 2
## y para filtrar solo las unidades de tipo "siege_workshop" del catálogo.
func entrenar_unidad(unit_id: String) -> bool:
	# Validar que la Era del jugador sea >= 2 (Edad del Cobre)
	var rm: Node = _get_resource_manager()
	if is_instance_valid(rm):
		var cur_era: int = int(rm.era_actual) if "era_actual" in rm else 0
		if cur_era < 2:
			print("SiegeWorkshop3D: Taller de Asedio bloqueado. Requiere Era 2 (Edad del Cobre). Era actual: %d" % cur_era)
			return false

	# Validar que la unidad pertenezca al tipo "siege_workshop" o maquinaria de asedio/carros
	if CATALOGO_UNIDADES.has(unit_id):
		var udata: Dictionary = CATALOGO_UNIDADES[unit_id]
		var btype: String = str(udata.get("building_type", ""))
		if btype != BUILDING_TYPE and btype != "siege" and not ("carro" in unit_id or "chariot" in unit_id or "ram" in unit_id or "ariete" in unit_id):
			print("SiegeWorkshop3D: La unidad '%s' no es de tipo asedio o vehículo (tipo: %s)." % [unit_id, btype])
			return false

	# Delegar toda la lógica al padre (cola, recursos, timer, spawn, era-scaling)
	var result: bool = super.entrenar_unidad(unit_id)
	if result:
		# Redireccionar el print del padre para identificar el edificio
		print("SiegeWorkshop3D: Unidad de asedio '%s' añadida a la cola (%d/%d)." % [
			CATALOGO_UNIDADES.get(unit_id, {}).get("name", unit_id),
			production_queue.size(), MAX_QUEUE_SIZE
		])
	return result

# ─── Helper: unidades disponibles para el HUD del aldeano ────────────────────

## Retorna el array de unidades de asedio disponibles para la era actual.
## Usado por el HUD del aldeano para mostrar/ocultar botones de producción.
func get_siege_units_for_current_era() -> Array[Dictionary]:
	var rm: Node = _get_resource_manager()
	var cur_era: int = int(rm.era_actual) if is_instance_valid(rm) and "era_actual" in rm else 0
	return Barracks3D.get_unidades_disponibles_era(cur_era, BUILDING_TYPE)

# ─── Swap Visual por Era ─────────────────────────────────────────────────────

func _actualizar_modelo_visual_era(era_val: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1, 2:
			_activar_mesh_por_nombre("EraMesh_WoodWorkshop")
			building_name = "Taller de Madera (Asedio Primitivo)"
		3, 4, 5:
			_activar_mesh_por_nombre("EraMesh_StoneWorkshop")
			building_name = "Taller de Asedio de Piedra"
		6, 7:
			_activar_mesh_por_nombre("EraMesh_IndustrialArsenal")
			building_name = "Arsenal Industrial"
		8, 9:
			_activar_mesh_por_nombre("EraMesh_AdvancedWeaponLab")
			building_name = "Laboratorio de Armamento Avanzado"
