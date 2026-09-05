## Legionary_Era3 — Legionario Romano Imperial (Edad de Hierro / Era 3).
##
## Unidad militar de élite con postura táctica especial 'Testudo' (Formación de Tortuga)
## sincronizada por RPC local. Al activarse, reduce su velocidad de traslación en un -40%,
## pero incrementa su resistencia pasiva contra proyectiles de rango ('ARROW' / 'PIERCE')
## en un +60% estrictamente mediante la función 'aplicar_mitigacion_testudo()'.
class_name Legionary_Era3
extends "res://scripts/units/soldier_3d.gd"

signal testudo_cambiado(activo: bool)

var testudo_active: bool = false
var _speed_normal: float = 5.2
var testudo_shields_node: Node3D = null

func _init() -> void:
	unit_id = "legionary_era3"
	unit_name = "Legionario Romano"
	attack_type = "melee"
	weapon_type = "sword"
	impact_type = "MELEE_SHOCK"
	_salud_base = 190.0
	salud_maxima = 190.0
	salud_actual = 190.0
	_daño_base = 24.0
	daño = 24.0
	rango_ataque = 3.2
	velocidad_ataque = 0.82
	_speed_normal = 5.2
	speed = _speed_normal
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("legionaries")
	add_to_group("infantry_3d")
	add_to_group("heavy_infantry")
	_setup_testudo_visuals()

func _setup_testudo_visuals() -> void:
	if not has_node("TestudoShields"):
		testudo_shields_node = Node3D.new()
		testudo_shields_node.name = "TestudoShields"
		testudo_shields_node.visible = false

		# Escudo frontal
		var f_mesh := MeshInstance3D.new()
		f_mesh.name = "FrontShield"
		var box_f := BoxMesh.new()
		box_f.size = Vector3(0.7, 1.1, 0.1)
		f_mesh.mesh = box_f
		f_mesh.position = Vector3(0.0, 0.9, -0.4)
		var mat_red := StandardMaterial3D.new()
		mat_red.albedo_color = Color(0.75, 0.15, 0.15) # Rojo imperial romano
		mat_red.metallic = 0.4
		mat_red.roughness = 0.4
		f_mesh.material_override = mat_red
		testudo_shields_node.add_child(f_mesh)

		# Escudo superior (techo tortuga)
		var t_mesh := MeshInstance3D.new()
		t_mesh.name = "TopShield"
		var box_t := BoxMesh.new()
		box_t.size = Vector3(0.8, 0.1, 0.8)
		t_mesh.mesh = box_t
		t_mesh.position = Vector3(0.0, 1.5, 0.0)
		t_mesh.material_override = mat_red
		testudo_shields_node.add_child(t_mesh)

		add_child(testudo_shields_node)
	else:
		testudo_shields_node = get_node("TestudoShields") as Node3D

## Activa o desactiva la postura táctica Testudo
func activar_testudo(activar: bool = true) -> void:
	_ejecutar_activar_testudo(activar)
	if is_inside_tree() and multiplayer != null and multiplayer.has_multiplayer_peer():
		rpc("rpc_activar_testudo", activar)

@rpc("call_remote", "reliable")
func rpc_activar_testudo(activar: bool) -> void:
	_ejecutar_activar_testudo(activar)

func _ejecutar_activar_testudo(activar: bool) -> void:
	testudo_active = activar
	if testudo_active:
		# Reducción de velocidad en un -40% (opera al 60% de velocidad base)
		speed = _speed_normal * 0.6
		if is_instance_valid(testudo_shields_node):
			testudo_shields_node.visible = true
		print("Legionary_Era3 '%s': ¡Formación TESTUDO activada! Vel: %.2f m/s (-40%%), Mitigación balística: +60%%." % [name, speed])
	else:
		# Restauración de velocidad normal
		speed = _speed_normal
		if is_instance_valid(testudo_shields_node):
			testudo_shields_node.visible = false
		print("Legionary_Era3 '%s': Formación TESTUDO desactivada. Vel restaurada a %.2f m/s." % [name, speed])
	testudo_cambiado.emit(testudo_active)

## Aplica la mitigación estricta del +60% contra proyectiles de rango (flechas/punzantes)
func aplicar_mitigacion_testudo(dano_entrante: float, tipo_arma: String = "arrow") -> float:
	if not testudo_active:
		return dano_entrante

	var t: String = tipo_arma.to_lower()
	# Mitigación efectiva contra proyectiles balísticos (arrow, pierce, piercing, sling, stone)
	if t in ["arrow", "pierce", "piercing", "sling", "stone", "ranged"]:
		# +60% de resistencia -> el daño recibido se reduce en un 60% (se recibe el 40%)
		var dano_mitigado: float = dano_entrante * 0.40
		return dano_mitigado

	return dano_entrante
