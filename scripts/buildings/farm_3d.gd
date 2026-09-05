## Farm3D — Granja Agrícola de Producción de Comida (GDScript 2.0 / Godot 4).
##
## Edificio económico de recolección de comida que funciona como nodo de recurso exclusivo
## de 1 aldeano por granja, con sistema de agotamiento y resiembra por 50 de madera.

class_name Farm3D
extends "res://scripts/buildings/building_base_3d.gd"

signal farm_depleted(farm: Farm3D)
signal farm_reseeded(farm: Farm3D, current_food: int)
signal resource_extracted(amount: int, remaining: int)

# ─── Configuración de Recurso y Resiembra ──────────────────────────────────────
@export_group("Parámetros Agrícolas")
@export var resource_type: String = "food"
@export var max_food_amount: int = 2000
@export var current_food_amount: int = 2000
@export var reseed_cost: Dictionary = {"wood": 50}

# ─── Control de Ocupación Estricta (1 Aldeano Máximo) y Reserva Temporal ──────
var assigned_villager: Node3D = null
var is_occupied: bool = false
var is_depleted_state: bool = false
var reserved_villager: Node3D = null
var reservation_timer: float = 0.0
const RESERVATION_DURATION: float = 12.0

func _physics_process(delta: float) -> void:
	if reservation_timer > 0.0:
		reservation_timer -= delta
		if reservation_timer <= 0.0:
			reserved_villager = null

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func _init() -> void:
	building_name = "Granja Agrícola"
	salud_maxima = 300.0
	salud_actual = 300.0

func _ready() -> void:
	super._ready()
	current_food_amount = max_food_amount
	add_to_group("resources")
	add_to_group("resources_3d")
	add_to_group("farms_3d")
	add_to_group("farms")

	if bando == Bando.PLAYER:
		add_to_group("player_buildings")
	else:
		add_to_group("enemy_buildings")

	# Conectar a la señal global de cambio de era para swap visual
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

# ─── Interfaz de Nodo de Recurso (Compatible con ResourceNode3D) ─────────────

func get_resource_type() -> String:
	return resource_type

func is_depleted() -> bool:
	return is_depleted_state or current_food_amount <= 0

## Gestión de Ranuras: Máximo 1 Aldeano Estricto por Granja con Dispersión Radial y Reserva
func request_gather_slot(villager: Node3D) -> Dictionary:
	if is_depleted():
		return {"has_slot": false, "reason": "Granja agotada"}

	# Validar si el aldeano asignado previamente sigue existiendo y es válido
	if is_occupied:
		if not is_instance_valid(assigned_villager):
			is_occupied = false
			assigned_villager = null
		elif "is_dead" in assigned_villager and assigned_villager.is_dead:
			is_occupied = false
			assigned_villager = null

	# Si hay reserva temporal activa para el agricultor que fue a depositar
	if is_instance_valid(reserved_villager) and reservation_timer > 0.0:
		if reserved_villager == villager:
			# El titular regresa del Town Center: reactivar asignación inmediata
			assigned_villager = villager
			is_occupied = true
			reserved_villager = null
			reservation_timer = 0.0
			var slot_p := global_position + Vector3(0.0, 0.0, 3.4)
			return {"has_slot": true, "slot_pos": slot_p, "wait_pos": slot_p}
		elif assigned_villager != villager:
			# Otro aldeano intenta usurpar la granja mientras el titular va a depositar
			var wait_ang: float = randf() * TAU
			var wait_p := global_position + Vector3(cos(wait_ang), 0.0, sin(wait_ang)) * 5.2
			return {
				"has_slot": false,
				"slot_pos": wait_p,
				"wait_pos": wait_p,
				"reason": "Granja reservada por agricultor titular (1/1)"
			}

	# Si ya está ocupada por otro aldeano activo
	if is_occupied and is_instance_valid(assigned_villager) and assigned_villager != villager:
		var wait_ang: float = randf() * TAU
		var wait_p := global_position + Vector3(cos(wait_ang), 0.0, sin(wait_ang)) * 5.2
		return {
			"has_slot": false,
			"slot_pos": wait_p,
			"wait_pos": wait_p,
			"reason": "Granja ocupada (1/1)"
		}

	# Asignar ranura única al aldeano en el perímetro exterior de la colisión (extents = 3.0m)
	assigned_villager = villager
	is_occupied = true
	var slot_p := global_position + Vector3(0.0, 0.0, 3.4)
	return {
		"has_slot": true,
		"slot_pos": slot_p,
		"wait_pos": slot_p
	}

func release_gather_slot(villager: Node3D) -> void:
	if assigned_villager == villager:
		# Si el aldeano sale con inventario cargado hacia el Town Center, activar reserva de 12 segundos
		var c_amt: int = 15
		if is_instance_valid(villager):
			var v_val = villager.get("carried_amount")
			if v_val != null:
				c_amt = int(v_val)
			elif villager.has_meta("carried_amount"):
				c_amt = int(villager.get_meta("carried_amount"))
		if is_instance_valid(villager) and c_amt > 0:
			reserved_villager = villager
			reservation_timer = RESERVATION_DURATION
		else:
			reserved_villager = null
			reservation_timer = 0.0
		assigned_villager = null
		is_occupied = false
	elif not is_instance_valid(assigned_villager):
		assigned_villager = null
		is_occupied = false

## Extracción de Comida por Ticks
func extract(amount: int) -> int:
	if is_depleted():
		return 0

	var extracted := mini(amount, current_food_amount)
	current_food_amount -= extracted
	resource_extracted.emit(extracted, current_food_amount)

	# Si se agotan las reservas de comida
	if current_food_amount <= 0:
		current_food_amount = 0
		is_depleted_state = true
		_on_farm_depleted()

	return extracted

func extraer_comida(cantidad: float) -> float:
	return float(extract(int(cantidad)))

# ─── Mecánica de Agotamiento y Resiembra ──────────────────────────────────────

func _on_farm_depleted() -> void:
	is_depleted_state = true
	release_gather_slot(assigned_villager)

	# Feedback visual de cultivo seco / marchito
	_set_crop_visual_active(false)

	# Alerta sonora y notificación en el HUD
	var sm = get_node_or_null("/root/SoundManager")
	if is_instance_valid(sm) and sm.has_method("play_attack_alert"):
		sm.play_attack_alert()

	var notif := get_tree().get_first_node_in_group("rts_notification_manager") if get_tree() else null
	if is_instance_valid(notif) and notif.has_method("add_notification"):
		notif.call("add_notification", "⚠️ Granja agotada en %s" % str(global_position))

	farm_depleted.emit(self)
	print("Farm3D '%s': Alimento agotado (0/%d). Esperando resiembra." % [name, max_food_amount])

## Resiembra la granja deduciendo 50 de Madera del ResourceManager.
func resembrar() -> bool:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		return false

	if rm.has_method("gastar_recursos") and not rm.gastar_recursos(reseed_cost):
		print("Farm3D: Madera insuficiente para resembrar (requiere 50 🪵)")
		return false

	current_food_amount = max_food_amount
	is_depleted_state = false
	_set_crop_visual_active(true)

	farm_reseeded.emit(self, current_food_amount)
	print("Farm3D '%s': Resembrada con éxito (+%d Comida)." % [name, max_food_amount])
	return true

func reseed() -> bool:
	return resembrar()

# ─── Evolución Estética del Cultivo por Era (Eras 0 a 9) ──────────────────────

func _on_era_evolucionada(player_id: int = 0, nueva_era: int = 0) -> void:
	if is_dead:
		return
	var p_id: int = player_id
	var era_val: int = nueva_era
	if self.owner_peer_id != p_id:
		return
	super._on_era_evolucionada(p_id, era_val)
	_actualizar_modelo_visual_era(era_val)

func _actualizar_modelo_visual_era(era_val: int) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("EraMesh_"):
			child.visible = false

	match era_val:
		0, 1: # Prehistórica y Piedra
			_activar_mesh_por_nombre("EraMesh_PrimitiveFarm")
			building_name = "Parcela Primitiva de Trigo"
		2, 3: # Bronce y Hierro
			_activar_mesh_por_nombre("EraMesh_WoodenFencedFarm")
			building_name = "Granja Cercada de Regadío"
		4, 5: # Medieval y Renacimiento
			_activar_mesh_por_nombre("EraMesh_WindmillFarm")
			building_name = "Granja Feudal con Molino"
		6, 7: # Industrial y Atómica
			_activar_mesh_por_nombre("EraMesh_IndustrialFarm")
			building_name = "Granja Mecanizada con Silos"
		8, 9: # Digital y Nano-Futurista
			_activar_mesh_por_nombre("EraMesh_HydroponicFarm")
			building_name = "Invernadero Hidropónico LED"

func _activar_mesh_por_nombre(mesh_name: String) -> void:
	var mesh_node := get_node_or_null(mesh_name)
	if is_instance_valid(mesh_node):
		mesh_node.visible = true

func _set_crop_visual_active(active: bool) -> void:
	var crops_node := get_node_or_null("CropVisuals")
	if is_instance_valid(crops_node):
		crops_node.visible = active
