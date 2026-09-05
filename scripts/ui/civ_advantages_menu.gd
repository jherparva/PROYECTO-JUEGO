## CivAdvantagesMenu — Panel de Ventajas de Civilización y Candado de Compra Única (Godot 4.3).
##
## Permite al jugador distribuir su bolsa inicial de 100 Civ Points entre ramas militares y económicas.
## Al presionar '%BtnLockCivSettings', guarda permanentemente los multiplicadores en ResourceManager,
## descuenta los puntos gastados e inhabilita de forma estricta todos los botones del panel ('disabled = true').

class_name CivAdvantagesMenu
extends Control

signal settings_locked()
signal points_changed(new_points: int)

# ─── Nodos y Controles UI (%UniqueNames) ───────────────────────────────────────
@onready var btn_lock_civ_settings: Button = get_node_or_null("%BtnLockCivSettings") as Button
@onready var lbl_points: Label = get_node_or_null("%LblCivPoints") as Label

var cpm: Node = null
var is_locked: bool = false
var buttons_list: Array[Button] = []

# Ramas de ventajas con su coste en Civ Points y multiplicador acumulado
var branches: Dictionary = {
	"infantry_melee": {"level": 0, "cost": 10, "bonus": 0.10},
	"infantry_ranged": {"level": 0, "cost": 10, "bonus": 0.15},
	"economy_speed": {"level": 0, "cost": 10, "bonus": 0.10},
	"cavalry_speed": {"level": 0, "cost": 10, "bonus": 0.15},
	"siege_power": {"level": 0, "cost": 10, "bonus": 0.20},
	"defense_walls": {"level": 0, "cost": 10, "bonus": 0.20},
	"cyber_robotic": {"level": 0, "cost": 10, "bonus": 0.10}
}

func _init() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	add_to_group("civ_advantages_menu")
	_resolve_cpm()
	_ensure_ui_elements()
	_update_ui()

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	add_to_group("civ_advantages_menu")

	_resolve_cpm()
	_ensure_ui_elements()
	_update_ui()

const CivPointsManagerClass = preload("res://scripts/core/civ_points_manager.gd")

func _resolve_cpm() -> Node:
	if is_instance_valid(cpm):
		return cpm
	if is_instance_valid(CivPointsManagerClass.instance):
		cpm = CivPointsManagerClass.instance
		return cpm
	if is_inside_tree() and get_tree() and get_tree().root:
		cpm = get_tree().root.get_node_or_null("CivPointsManager")
	return cpm

func _ensure_ui_elements() -> void:
	# Si no se instanció desde un archivo .tscn, generar la estructura programática con %UniqueNames
	if not is_instance_valid(btn_lock_civ_settings):
		var btn := find_child("BtnLockCivSettings", true, false) as Button
		if not is_instance_valid(btn):
			btn = Button.new()
			btn.name = "BtnLockCivSettings"
			btn.unique_name_in_owner = true
			btn.text = "🔒 BLOQUEAR Y CONFIRMAR VENTAJAS"
			add_child(btn)
			btn.owner = self
		btn_lock_civ_settings = btn

	if not is_instance_valid(lbl_points):
		var lbl := find_child("LblCivPoints", true, false) as Label
		if not is_instance_valid(lbl):
			lbl = Label.new()
			lbl.name = "LblCivPoints"
			lbl.unique_name_in_owner = true
			lbl.text = "Puntos de Civilización: 100"
			add_child(lbl)
		lbl_points = lbl

	# Crear o enlazar botones por cada rama si no existen
	for branch_id in branches.keys():
		var btn_name: String = "BtnUpgrade_" + branch_id
		var btn_branch: Button = find_child(btn_name, true, false) as Button
		if not is_instance_valid(btn_branch):
			btn_branch = Button.new()
			btn_branch.name = btn_name
			btn_branch.text = "+ " + branch_id.capitalize()
			add_child(btn_branch)
		if not buttons_list.has(btn_branch):
			buttons_list.append(btn_branch)
			var b_id: String = branch_id
			btn_branch.pressed.connect(func(): distribuir_punto(b_id))

	if not buttons_list.has(btn_lock_civ_settings):
		buttons_list.append(btn_lock_civ_settings)

	if not btn_lock_civ_settings.pressed.is_connected(bloquear_ventajas_civ):
		btn_lock_civ_settings.pressed.connect(bloquear_ventajas_civ)

func distribuir_punto(branch_id: String) -> bool:
	if is_locked:
		return false
	_ensure_ui_elements()
	_resolve_cpm()
	var cur_pts: int = int(cpm.total_civ_points) if is_instance_valid(cpm) else 100
	if not branches.has(branch_id):
		return false

	var cost: int = int(branches[branch_id]["cost"])
	if cur_pts < cost:
		return false

	branches[branch_id]["level"] += 1
	if is_instance_valid(cpm):
		cpm.total_civ_points -= cost
		cpm.puntos_civ = cpm.total_civ_points
		if "upgrade_levels" in cpm and cpm.upgrade_levels.has(branch_id):
			cpm.upgrade_levels[branch_id] = branches[branch_id]["level"]
		cpm.civ_points_changed.emit(cpm.puntos_civ)

	_update_ui()
	return true

func bloquear_ventajas_civ() -> void:
	if is_locked:
		return

	is_locked = true
	_ensure_ui_elements()
	_resolve_cpm()

	# 1. Guardar de forma permanente los multiplicadores en el ResourceManager local
	var ml = Engine.get_main_loop()
	var rm: Node = null
	if ml and "root" in ml and ml.root:
		rm = ml.root.get_node_or_null("ResourceManager")
		if not is_instance_valid(rm):
			rm = ml.root.get_node_or_null("GlobalResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/ResourceManager")
	if not is_instance_valid(rm):
		rm = get_node_or_null("/root/GlobalResourceManager")

	if is_instance_valid(rm):
		# Multiplicadores de recolección económica
		var eco_lvl: int = int(branches["economy_speed"]["level"])
		if eco_lvl > 0 and "tech_gather_bonuses" in rm:
			var bonus_mult: float = 1.0 + (float(eco_lvl) * float(branches["economy_speed"]["bonus"]))
			for res_key in ["wood", "food", "gold", "iron", "stone"]:
				rm.tech_gather_bonuses[res_key] = float(rm.tech_gather_bonuses.get(res_key, 1.0)) * bonus_mult

		# Bonos de ataque militar
		var melee_lvl: int = int(branches["infantry_melee"]["level"])
		var ranged_lvl: int = int(branches["infantry_ranged"]["level"])
		if "civ_attack_bonuses" in rm:
			rm.civ_attack_bonuses["infantry_melee"] = 1.0 + (float(melee_lvl) * 0.10)
			rm.civ_attack_bonuses["infantry_ranged"] = 1.0 + (float(ranged_lvl) * 0.15)
		else:
			rm.set_meta("civ_infantry_melee_mult", 1.0 + (float(melee_lvl) * 0.10))
			rm.set_meta("civ_infantry_ranged_mult", 1.0 + (float(ranged_lvl) * 0.15))

	# 2. Sincronizar con CivPointsManager
	if is_instance_valid(cpm):
		cpm.lock_civ_settings(0)

	# 3. BLOQUEO ESTRICTO: Inhabilitar todos los botones del panel ('disabled = true')
	for btn in buttons_list:
		if is_instance_valid(btn):
			btn.disabled = true

	if is_instance_valid(btn_lock_civ_settings):
		btn_lock_civ_settings.disabled = true
		btn_lock_civ_settings.text = "🔒 VENTAJAS BLOQUEADAS PERMANENTEMENTE"

	_update_ui()
	settings_locked.emit()
	print("CivAdvantagesMenu: ✅ Ventajas confirmadas y panel BLOQUEADO estricto (disabled = true).")

func _update_ui() -> void:
	_resolve_cpm()
	var cur_pts: int = int(cpm.total_civ_points) if is_instance_valid(cpm) else 100
	if is_instance_valid(lbl_points):
		lbl_points.text = "Puntos de Civilización: %d%s" % [cur_pts, " (BLOQUEADO)" if is_locked else ""]
