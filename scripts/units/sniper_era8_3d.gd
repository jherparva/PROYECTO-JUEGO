## Sniper_Era8 — Tirador de Élite WWII (Edad Atómica / Era 8).
##
## Unidad de rango sigilosa con fusil de precisión telescópico.
## Rango masivo de 30.0 metros. Se vuelve invisible (is_invisible = true) en reposo (Idle),
## ocultando su presencia hasta que abre fuego.
## Multiplicador crítico de x3.0 contra aldeanos civiles y sacerdotes.
class_name Sniper_Era8
extends "res://scripts/units/soldier_3d.gd"

signal sigilo_cambiado(es_invisible: bool)

@onready var muzzle_node: Marker3D = $ProjectileMuzzle if has_node("ProjectileMuzzle") else null

func _init() -> void:
	unit_id = "sniper_era8"
	unit_name = "Tirador de Élite WWII"
	attack_type = "ranged"
	weapon_type = "sniper"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 140.0
	salud_maxima = 140.0
	salud_actual = 140.0
	_daño_base = 65.0
	daño = 65.0
	rango_ataque = 30.0
	velocidad_ataque = 2.2
	speed = 4.2
	era_entrenada = 8
	is_invisible = true

func _ready() -> void:
	super._ready()
	add_to_group("snipers")
	add_to_group("infantry_3d")
	add_to_group("military_units")
	add_to_group("units_3d")
	_setup_sniper_visuals()
	establecer_sigilo(true)

func _setup_sniper_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 1.2, -0.9)
		add_child(muzzle)

	if not has_node("RifleMesh"):
		var rifle := MeshInstance3D.new()
		rifle.name = "RifleMesh"
		var box := BoxMesh.new()
		box.size = Vector3(0.1, 0.1, 1.4)
		rifle.mesh = box
		rifle.position = Vector3(0.25, 1.1, -0.4)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.15, 0.1)
		rifle.material_override = mat
		add_child(rifle)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Si la unidad no se está moviendo y no está en ataque activo, entra en sigilo
	if velocity.length() < 0.1 and not is_dead:
		if not is_invisible:
			establecer_sigilo(true)
	elif velocity.length() >= 0.1:
		if is_invisible:
			establecer_sigilo(false)

## Conmuta el estado de invisibilidad y visibilidad de los componentes visuales
func establecer_sigilo(invisible: bool) -> void:
	is_invisible = invisible
	sigilo_cambiado.emit(is_invisible)
	var body_mesh := get_node_or_null("BodyMesh") as MeshInstance3D
	var rifle_mesh := get_node_or_null("RifleMesh") as MeshInstance3D
	if is_instance_valid(body_mesh):
		body_mesh.visible = not is_invisible
	if is_instance_valid(rifle_mesh):
		rifle_mesh.visible = not is_invisible

## Dispara un tiro de francotirador revelando la posición
func disparar_sniper(target: Node3D) -> float:
	establecer_sigilo(false)
	if not is_instance_valid(target):
		return 0.0

	var dmg: float = CombatDamageCalculator.calcular_dano(daño, weapon_type, self, target)
	if target.has_method("recibir_dano"):
		target.call("recibir_dano", dmg)
	elif "salud_actual" in target:
		target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))
	return dmg
