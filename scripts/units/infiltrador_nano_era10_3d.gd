## Infiltrador_Nano — Infantería de Camuflaje Óptico Nanotecnológico (Edad Digital / Era 10).
##
## Unidad de sigilo terminal avanzada con traje de nanofibras refractarias.
## FSM incorpora el flag 'is_invisible = true' de forma PERMANENTE en reposo (Idle)
## y en marcha (Move), desactivando el camuflaje únicamente durante el frame del impacto
## en estado 'Attacking', volviendo a camuflarse de forma automática al perder el objetivo.
class_name Infiltrador_Nano
extends "res://scripts/units/soldier_3d.gd"

signal camuflaje_optico_conmutado(activo: bool)

func _init() -> void:
	unit_id = "infiltrador_nano_era10"
	unit_name = "Infiltrador Nanotecnológico"
	attack_type = "melee"
	weapon_type = "sword"
	impact_type = "PIERCE"
	is_invisible = true
	_salud_base = 260.0
	salud_maxima = 260.0
	salud_actual = 260.0
	_daño_base = 40.0
	daño = 40.0
	rango_ataque = 2.5
	velocidad_ataque = 0.8
	speed = 5.6
	era_entrenada = 10

func _ready() -> void:
	super._ready()
	add_to_group("infiltrators")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_nano_visuals()
	establecer_sigilo(true)

func _setup_nano_visuals() -> void:
	if not has_node("NanoBlades"):
		var blades := MeshInstance3D.new()
		blades.name = "NanoBlades"
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.04, 0.7)
		blades.mesh = box
		blades.position = Vector3(0.3, 0.9, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.0, 0.9, 1.0) # Neón cian nanotecnológico
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.9, 1.0)
		mat.emission_energy_multiplier = 2.0
		blades.material_override = mat
		add_child(blades)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return

	# Camuflaje permanente en reposo y en movimiento sigiloso
	var st = get("current_state")
	var st_name: String = st.state_name if is_instance_valid(st) and "state_name" in st else ""
	if st_name == "Attacking":
		if is_invisible:
			establecer_sigilo(false)
	else:
		# En Idle, Move, o cualquier estado no ofensivo, permanece permanentemente invisible
		if not is_invisible:
			establecer_sigilo(true)

## Conmuta el camuflaje óptico y la visibilidad de los nodos gráficos
func establecer_sigilo(activo: bool) -> void:
	is_invisible = activo
	camuflaje_optico_conmutado.emit(is_invisible)
	var body_mesh := get_node_or_null("BodyMesh") as MeshInstance3D
	var blades := get_node_or_null("NanoBlades") as MeshInstance3D
	if is_instance_valid(body_mesh):
		body_mesh.visible = not is_invisible
	if is_instance_valid(blades):
		blades.visible = not is_invisible

## Ataque que expone el camuflaje durante el impacto
func ejecutar_ataque_sigiloso(target: Node3D) -> float:
	establecer_sigilo(false)
	var dmg: float = CombatDamageCalculator.calcular_dano(daño, "sword", self, target)
	if is_instance_valid(target):
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg)
		elif target.has_method("recibir_daño"):
			target.call("recibir_daño", dmg)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))
	return dmg
