## WarElephant_Era3 — Elefante de Guerra Blindado (Edad de Hierro / Era 3).
##
## Unidad montada colosal viviente de 350 HP según dbunitset.dat.
## Posee comportamiento de embestida pesada, aplicando un empuje de separación física
## RVO de 1.2m a la infantería enemiga al entrar en combate cuerpo a cuerpo.
class_name WarElephant_Era3
extends "res://scripts/units/soldier_3d.gd"

var is_colossal: bool = true
var distancia_empuje: float = 1.2

func _init() -> void:
	unit_id = "war_elephant_era3"
	unit_name = "Elefante de Guerra"
	attack_type = "melee"
	weapon_type = "tusk_trample"
	impact_type = "MELEE_SHOCK"
	_salud_base = 350.0 # 350 HP oficiales segun dbunitset.dat
	salud_maxima = 350.0
	salud_actual = 350.0
	_daño_base = 28.0
	daño = 28.0
	rango_ataque = 4.2
	velocidad_ataque = 1.1
	speed = 4.6 # Marcha de elefante de combate
	era_entrenada = 3

func _ready() -> void:
	super._ready()
	add_to_group("elephants")
	add_to_group("cavalry")
	add_to_group("heavy_cavalry")
	add_to_group("units_3d")
	_setup_elephant_visuals()

func _setup_elephant_visuals() -> void:
	if not has_node("ElephantTorso"):
		var torso := MeshInstance3D.new()
		torso.name = "ElephantTorso"
		var box := BoxMesh.new()
		box.size = Vector3(1.8, 2.2, 3.2)
		torso.mesh = box
		torso.position = Vector3(0.0, 1.4, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.44, 0.46) # Piel gruesa de elefante
		mat.roughness = 0.9
		torso.material_override = mat
		add_child(torso)

	if not has_node("CastleHowdah"):
		var howdah := MeshInstance3D.new()
		howdah.name = "CastleHowdah"
		var box_h := BoxMesh.new()
		box_h.size = Vector3(1.2, 0.8, 1.4)
		howdah.mesh = box_h
		howdah.position = Vector3(0.0, 2.8, -0.2)
		var mat_w := StandardMaterial3D.new()
		mat_w.albedo_color = Color(0.65, 0.18, 0.18) # Torreta roja
		howdah.material_override = mat_w
		add_child(howdah)

## Aplica el empuje de separación física RVO de 1.2m a la infantería enemiga
func aplicar_empuje_rvo(target: Node3D, distancia: float = 1.2) -> void:
	if not is_instance_valid(target):
		return

	# Calcular vector director de empuje horizontal en XZ
	var pos_target: Vector3 = target.position if target.position != Vector3.ZERO else target.global_position
	var pos_self: Vector3 = position if position != Vector3.ZERO else global_position
	var diff := pos_target - pos_self
	diff.y = 0.0
	var dir := diff.normalized()
	if dir.length_squared() < 0.001:
		dir = Vector3(0, 0, 1)

	var desplazamiento: Vector3 = dir * distancia
	target.position += desplazamiento
	if target.is_inside_tree():
		target.global_position += desplazamiento
	if "velocity" in target:
		target.set("velocity", target.get("velocity") + dir * (distancia * 4.0))

	print("WarElephant_Era3 '%s': ¡Embestida colosal! Empuje RVO de %.2fm aplicado sobre '%s'." % [name, distancia, target.name])
