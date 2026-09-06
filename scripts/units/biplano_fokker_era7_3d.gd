## Biplano_Fokker_Era7 — Caza Biplano de Lienzo (Edad Atómica - 1ra Guerra Mundial / Era 7).
##
## El primer vehículo aéreo militar de la línea de tiempo.
## Navega en una capa de altura constante en el eje Y (Y = 10.0m) a 9.5 m/s.
## Realiza pasadas de ametrallamiento con ametralladora sincronizada (daño 32.0).
## Al agotar su munición (max_ammo = 3), aborta de forma autónoma el patrullaje y regresa
## a la pista del aeródromo local para rearmarse.
class_name Biplano_Fokker_Era7
extends "res://scripts/units/soldier_3d.gd"

signal municion_agotada()
signal regreso_a_base_iniciado()
signal aterrizaje_completado()

var altura_vuelo: float = 10.0
var max_ammo: int = 3
var current_ammo: int = 3
var estado_vuelo: String = "patrulla" # "patrulla", "ametrallamiento", "regresando"
var is_aircraft: bool = true

func _init() -> void:
	unit_id = "biplano_fokker_era7"
	unit_name = "Biplano Fokker"
	attack_type = "ranged"
	weapon_type = "gun"
	impact_type = "GUN"
	projectile_type = "bullet"
	_salud_base = 180.0
	salud_maxima = 180.0
	salud_actual = 180.0
	_daño_base = 32.0
	daño = 32.0
	rango_ataque = 24.0
	velocidad_ataque = 1.2
	speed = 9.5
	era_entrenada = 7

func _ready() -> void:
	super._ready()
	remove_from_group("infantry_3d")
	add_to_group("air_units")
	add_to_group("aircraft")
	add_to_group("military_units")
	add_to_group("units_3d")
	position.y = altura_vuelo
	_setup_biplano_visuals()

func _setup_biplano_visuals() -> void:
	if not has_node("ProjectileMuzzle"):
		var muzzle := Marker3D.new()
		muzzle.name = "ProjectileMuzzle"
		muzzle.position = Vector3(0.0, 0.2, -1.6)
		add_child(muzzle)

	if not has_node("Fuselage"):
		var fuse := MeshInstance3D.new()
		fuse.name = "Fuselage"
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.6, 3.2)
		fuse.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.15, 0.15) # Rojo Barón / Fokker
		fuse.material_override = mat
		add_child(fuse)

	if not has_node("UpperWing"):
		var wing1 := MeshInstance3D.new()
		wing1.name = "UpperWing"
		var box_w1 := BoxMesh.new()
		box_w1.size = Vector3(4.6, 0.06, 0.8)
		wing1.mesh = box_w1
		wing1.position = Vector3(0.0, 0.5, -0.2)
		var mat_w := StandardMaterial3D.new()
		mat_w.albedo_color = Color(0.70, 0.12, 0.12)
		wing1.material_override = mat_w
		add_child(wing1)

	if not has_node("LowerWing"):
		var wing2 := MeshInstance3D.new()
		wing2.name = "LowerWing"
		var box_w2 := BoxMesh.new()
		box_w2.size = Vector3(4.2, 0.06, 0.75)
		wing2.mesh = box_w2
		wing2.position = Vector3(0.0, -0.2, -0.2)
		var mat_w2 := StandardMaterial3D.new()
		mat_w2.albedo_color = Color(0.70, 0.12, 0.12)
		wing2.material_override = mat_w2
		add_child(wing2)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Mantiene capa física aérea fija en Y = 10.0m mientras vuela
	if estado_vuelo != "aterrizado":
		position.y = altura_vuelo

## Realiza una pasada de ametrallamiento sobre el terreno consumiendo munición
func ametrallar_objetivo(target: Node3D) -> bool:
	if current_ammo <= 0:
		regresar_a_aerodromo()
		return false

	current_ammo -= 1
	if is_instance_valid(target):
		var dmg: float = CombatDamageCalculator.calcular_dano(daño, "gun", self, target)
		if target.has_method("recibir_dano"):
			target.call("recibir_dano", dmg)
		elif "salud_actual" in target:
			target.set("salud_actual", maxf(0.0, float(target.get("salud_actual")) - dmg))

	if current_ammo <= 0:
		regresar_a_aerodromo()
	return true

## Aborta patrulla y regresa al aeródromo local para rearmarse
func regresar_a_aerodromo(aerodromo_pos: Vector3 = Vector3.ZERO) -> void:
	estado_vuelo = "regresando"
	municion_agotada.emit()
	regreso_a_base_iniciado.emit()
	print("Biplano_Fokker_Era7 '%s': Munición agotada (0/%d). Regresando a aeródromo para rearme." % [name, max_ammo])
