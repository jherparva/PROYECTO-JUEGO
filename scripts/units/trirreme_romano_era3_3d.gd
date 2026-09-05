## Trirreme_Romano_Era3 — Trirreme de Guerra Imperial (Edad de Hierro / Era 3).
##
## Navío pesado de combate imperial equipado con espolón de bronce en proa.
## Permite ejecutar el ataque táctico de espolón contra embarcaciones enemigas,
## infligiendo daño crítico instantáneo síncrono por red.
class_name Trirreme_Romano_Era3
extends "res://scripts/units/soldier_3d.gd"

signal espolon_ejecutado(target: Node3D)

var is_naval_unit: bool = true
var dano_espolon_critico: float = 260.0

func _init() -> void:
	unit_id = "trirreme_romano_era3"
	unit_name = "Trirreme Romano"
	attack_type = "melee"
	weapon_type = "ram_spur"
	impact_type = "MELEE_SHOCK"
	_salud_base = 320.0
	salud_maxima = 320.0
	salud_actual = 320.0
	_daño_base = 35.0
	daño = 35.0
	rango_ataque = 5.0
	velocidad_ataque = 1.8
	speed = 5.6 # Veloz galera a tres órdenes de remos
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("naval_units")
	add_to_group("warships")
	add_to_group("ships")
	add_to_group("units_3d")
	_setup_galley_visuals()

func _setup_galley_visuals() -> void:
	if not has_node("GalleyHull"):
		var hull := MeshInstance3D.new()
		hull.name = "GalleyHull"
		var box := BoxMesh.new()
		box.size = Vector3(1.6, 1.2, 4.5)
		hull.mesh = box
		hull.position = Vector3(0.0, 0.4, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.18, 0.12)
		hull.material_override = mat
		add_child(hull)

	if not has_node("EspolonBronce"):
		var spur := MeshInstance3D.new()
		spur.name = "EspolonBronce"
		var box_s := BoxMesh.new()
		box_s.size = Vector3(0.6, 0.5, 1.0)
		spur.mesh = box_s
		spur.position = Vector3(0.0, 0.1, -2.6) # En proa delantera
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_color = Color(0.80, 0.55, 0.20) # Bronce fundido
		mat_b.metallic = 0.9
		spur.material_override = mat_b
		add_child(spur)

## Ataque especial de espolón sincronizado por red
func ataque_espolon(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	_ejecutar_espolon(target)
	if is_inside_tree() and multiplayer != null and multiplayer.has_multiplayer_peer():
		rpc("rpc_espolon_critico", target.get_path())

@rpc("call_remote", "reliable")
func rpc_espolon_critico(target_path: NodePath) -> void:
	var target: Node3D = null
	if not str(target_path).is_empty():
		if is_inside_tree():
			target = get_node_or_null(target_path) as Node3D
		if not is_instance_valid(target) and Engine.get_main_loop() is SceneTree:
			target = (Engine.get_main_loop() as SceneTree).root.get_node_or_null(target_path) as Node3D
	_ejecutar_espolon(target)

func _ejecutar_espolon(target: Node3D) -> void:
	if not is_instance_valid(target):
		return

	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dano_espolon_critico, self)
	elif target.has_method("take_damage"):
		target.call("take_damage", dano_espolon_critico)
	elif "salud_actual" in target:
		var cur: float = float(target.get("salud_actual"))
		target.set("salud_actual", maxf(0.0, cur - dano_espolon_critico))
		if float(target.get("salud_actual")) <= 0.0 and target.has_method("die"):
			target.call("die")

	print("Trirreme_Romano_Era3 '%s': ¡Espolón de bronce clavado en '%s'! Daño crítico: %.1f." % [name, target.name, dano_espolon_critico])
	espolon_ejecutado.emit(target)
