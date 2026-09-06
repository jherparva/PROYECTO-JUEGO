## Soldier3D — Unidad Militar / Infantería de Combate 3D (GDScript 2.0 / Godot 4).
##
## Extiende UnitBase3D para unidades de infantería (cuerpo a cuerpo y distancia).
## Administra la FSM de combate (Idle, Move, Chase, Attack), posturas tácticas
## (Agresiva, Defensiva, Mantener Terreno) y escalado dinámico por Eras históricas.

class_name Soldier3D
extends "res://scripts/units/unit_base_3d.gd"

const CombatDamageCalculator = preload("res://scripts/core/combat_damage_calculator.gd")


# ─── Posturas Tácticas de Combate ─────────────────────────────────────────────
enum Postura {
	AGRESIVA,         ## Persigue y ataca a cualquier enemigo en su radio de visión (por defecto).
	DEFENSIVA,        ## Ataca enemigos cercanos pero regresa a su posición original si se alejan.
	MANTENER_TERRENO  ## Ataca solo en su rango de alcance directo sin moverse.
}

# ─── Configuración de Infantería ───────────────────────────────────────────────
@export_group("Configuración Militar")
@export var unit_id: String = "garrotero"
@export var attack_type: String = "melee" # "melee" o "ranged"
@export var projectile_type: String = "bullet" # "stone", "arrow", "bullet", "plasma"
@export var postura_actual: Postura = Postura.AGRESIVA
@export var weapon_type: String = "spear"
@export var impact_type: String = "NONE"
@export var civilizacion: String = ""
@export var is_cavalry: bool = false

# Backup de atributos base para escalado por Eras
var _salud_base: float = 120.0
var _daño_base: float = 18.0
var _guard_position: Vector3 = Vector3.ZERO
var _scan_timer: float = 0.0
const SCAN_INTERVAL: float = 0.4 # Escanear enemigos cada 0.4 segundos

# ─── Ciclo de Vida ─────────────────────────────────────────────────────────────

func configurar_soldado(uid: String) -> void:
	unit_id = uid
	_setup_stats()

func _setup_stats() -> void:
	unit_name        = "Infantería de Combate"
	_salud_base      = 120.0
	_daño_base       = 18.0
	salud_maxima     = _salud_base
	salud_actual     = salud_maxima
	daño             = _daño_base
	rango_ataque     = 3.2 if attack_type == "melee" else 18.0
	velocidad_ataque = 0.9 # 1 golpe cada 0.9s
	speed            = 5.2
	radio_vision     = 28.0

	match unit_id:
		"brawler_primitivo":
			unit_name = "Luchador Primitivo"
			weapon_type = "fist"
			_daño_base = 12.0
			daño = 12.0
			velocidad_ataque = 0.6
			speed = 5.6
		"garrotero", "clubman_era0":
			unit_name = "Guerrero con Garrote"
			weapon_type = "bludgeoning"
			_daño_base = 16.0
			daño = 16.0
			velocidad_ataque = 0.85
			speed = 5.2
		"spearman_era0", "lancero_silex":
			unit_name = "Lancero de Sílex"
			weapon_type = "piercing"
			_daño_base = 15.0
			daño = 15.0
			rango_ataque = 3.5
			velocidad_ataque = 0.9
			speed = 5.0
		"lanzador_piedras":
			unit_name = "Lanzador de Piedras"
			attack_type = "ranged"
			weapon_type = "sling"
			projectile_type = "stone"
			_salud_base = 85.0
			salud_maxima = 85.0
			salud_actual = 85.0
			_daño_base = 10.0
			daño = 10.0
			rango_ataque = 15.0
			velocidad_ataque = 1.1
			speed = 5.2
			era_entrenada = 1
		"maceman_era1":
			unit_name = "Guerrero con Maza"
			attack_type = "melee"
			weapon_type = "bludgeoning"
			_salud_base = 135.0
			salud_maxima = 135.0
			salud_actual = 135.0
			_daño_base = 18.4 # +15% pasivo respecto a Clubman (16.0 * 1.15)
			daño = 18.4
			rango_ataque = 3.2
			velocidad_ataque = 0.85
			speed = 5.2
			era_entrenada = 1
		"axeman_era1":
			unit_name = "Guerrero con Hacha de Piedra"
			attack_type = "melee"
			weapon_type = "axe"
			_salud_base = 140.0
			salud_maxima = 140.0
			salud_actual = 140.0
			_daño_base = 17.0
			daño = 17.0
			rango_ataque = 3.2
			velocidad_ataque = 0.9
			speed = 5.1
			era_entrenada = 1
		"bowman_era1":
			unit_name = "Arquero de Piedra"
			attack_type = "ranged"
			weapon_type = "arrow"
			projectile_type = "arrow"
			_salud_base = 75.0
			salud_maxima = 75.0
			salud_actual = 75.0
			_daño_base = 11.0
			daño = 11.0
			rango_ataque = 14.0
			velocidad_ataque = 1.0
			speed = 5.0
			era_entrenada = 1
			_aplicar_bonos_civilizacion()
		"scout_era1":
			unit_name = "Explorador a Pie"
			attack_type = "melee"
			weapon_type = "fist"
			_salud_base = 110.0
			salud_maxima = 110.0
			salud_actual = 110.0
			_daño_base = 8.0
			daño = 8.0
			rango_ataque = 2.5
			velocidad_ataque = 1.0
			speed = 6.5
			radio_vision = 56.0 # +100% de 28.0m
			era_entrenada = 1

		# ────────────────────────────────────────────────────────────
		# ERA 2 — EDAD DEL COBRE (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"maceman_bronze", "maceman_era2":
			# Macero de Cobre: MELEE_SHOCK / Bludgeoning
			# dbunitset.dat: HP 160, DAÑO 21.0, x1.45 vs madera/palizada
			unit_name = "Macero de Cobre"
			attack_type = "melee"
			weapon_type = "bludgeoning"
			_salud_base = 160.0
			salud_maxima = 160.0
			salud_actual = 160.0
			_daño_base = 21.0
			daño = 21.0
			rango_ataque = 3.2
			velocidad_ataque = 0.82
			speed = 5.2
			era_entrenada = 2

		"retiarius_gladiador":
			# Gladiador con Red: infantería de choque Era 2
			# Ataque especial: Red_Tridente lanzada que aplica is_slowed -50% por 3.5s
			unit_name = "Gladiador Lanzador de Redes"
			attack_type = "melee"
			weapon_type = "net_trident"
			_salud_base = 145.0
			salud_maxima = 145.0
			salud_actual = 145.0
			_daño_base = 19.0
			daño = 19.0
			rango_ataque = 4.5  # Lanza la red desde un poco más lejos
			velocidad_ataque = 1.0
			speed = 5.4
			era_entrenada = 2

		"chariot_archer_era2", "carro_primitivo":
			# Carro de Guerra de Rango: primer vehículo veloz (6.0 m/s)
			# Doble socket ProjectileMuzzle, polvo al galopar
			unit_name = "Carro de Guerra Primitivo"
			attack_type = "ranged"
			weapon_type = "arrow"
			projectile_type = "arrow"
			_salud_base = 180.0
			salud_maxima = 180.0
			salud_actual = 180.0
			_daño_base = 14.0
			daño = 14.0
			rango_ataque = 12.0
			velocidad_ataque = 1.2
			speed = 6.0  # Vel base más alta del juego en Era 2
			era_entrenada = 2

		# ────────────────────────────────────────────────────────────
		# ERA 3 — EDAD DE HIERRO (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"espadachin_hierro", "espadachin":
			unit_name = "Espadachín de Hierro"
			attack_type = "melee"
			weapon_type = "sword"
			impact_type = "MELEE_SHOCK"
			_salud_base = 180.0
			salud_maxima = 180.0
			salud_actual = 180.0
			_daño_base = 22.0
			daño = 22.0
			rango_ataque = 3.2
			velocidad_ataque = 0.85
			speed = 5.0
			era_entrenada = 3

		"legionary_era3":
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
			speed = 5.2
			era_entrenada = 3

		"cataphract_era3":
			unit_name = "Catafracta de Hierro"
			attack_type = "melee"
			weapon_type = "lance"
			impact_type = "MELEE_SHOCK"
			_salud_base = 240.0
			salud_maxima = 240.0
			salud_actual = 240.0
			_daño_base = 26.0
			daño = 26.0
			rango_ataque = 3.6
			velocidad_ataque = 0.95
			speed = 5.5
			era_entrenada = 3

		"war_elephant_era3":
			unit_name = "Elefante de Guerra"
			attack_type = "melee"
			weapon_type = "tusk_trample"
			impact_type = "MELEE_SHOCK"
			_salud_base = 350.0
			salud_maxima = 350.0
			salud_actual = 350.0
			_daño_base = 28.0
			daño = 28.0
			rango_ataque = 4.2
			velocidad_ataque = 1.1
			speed = 4.6
			era_entrenada = 3

		"ariete_carnero_era3":
			unit_name = "Ariete de Carnero"
			attack_type = "melee"
			weapon_type = "bludgeoning"
			impact_type = "Bludgeoning"
			_salud_base = 380.0
			salud_maxima = 380.0
			salud_actual = 380.0
			_daño_base = 40.0
			daño = 40.0
			rango_ataque = 3.8
			velocidad_ataque = 1.6
			speed = 3.2
			era_entrenada = 3

		"catapulta_onagro_era3":
			unit_name = "Onagro de Torsión"
			attack_type = "ranged"
			weapon_type = "siege_stone"
			projectile_type = "fire_stone"
			_salud_base = 220.0
			salud_maxima = 220.0
			salud_actual = 220.0
			_daño_base = 45.0
			daño = 45.0
			rango_ataque = 24.0
			velocidad_ataque = 3.0
			speed = 3.0
			era_entrenada = 3

		"balista_torsion_era3":
			unit_name = "Balista de Torsión"
			attack_type = "ranged"
			weapon_type = "piercing_bolt"
			projectile_type = "bolt"
			_salud_base = 200.0
			salud_maxima = 200.0
			salud_actual = 200.0
			_daño_base = 38.0
			daño = 38.0
			rango_ataque = 22.0
			velocidad_ataque = 2.2
			speed = 3.4
			era_entrenada = 3

		"trirreme_romano_era3":
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
			speed = 5.6
			era_entrenada = 3

		"caballero_pesado":
			unit_name = "Caballero Pesado"
			attack_type = "melee"
			weapon_type = "melee_shock"
			impact_type = "MELEE_SHOCK"
			is_cavalry = true
			_salud_base = 280.0
			salud_maxima = 280.0
			salud_actual = 280.0
			_daño_base = 32.0
			daño = 32.0
			rango_ataque = 3.6
			velocidad_ataque = 0.95
			speed = 6.0
			era_entrenada = 4

		"pikeman_era4":
			unit_name = "Piquero Medieval"
			attack_type = "melee"
			weapon_type = "melee_pierce"
			impact_type = "MELEE_PIERCE"
			_salud_base = 180.0
			salud_maxima = 180.0
			salud_actual = 180.0
			_daño_base = 20.0
			daño = 20.0
			rango_ataque = 2.8
			velocidad_ataque = 0.9
			speed = 4.8
			era_entrenada = 4

		"crossbowman_era4":
			unit_name = "Ballestero Medieval"
			attack_type = "ranged"
			weapon_type = "arrow"
			impact_type = "PIERCE"
			projectile_type = "bolt"
			_salud_base = 140.0
			salud_maxima = 140.0
			salud_actual = 140.0
			_daño_base = 22.0
			daño = 22.0
			rango_ataque = 12.0
			velocidad_ataque = 1.5
			speed = 4.4
			era_entrenada = 4

		"longbowman_era4":
			unit_name = "Arquero de Tiro Largo"
			attack_type = "ranged"
			weapon_type = "arrow"
			impact_type = "ARROW"
			projectile_type = "arrow"
			_salud_base = 130.0
			salud_maxima = 130.0
			salud_actual = 130.0
			_daño_base = 15.0
			daño = 15.0
			rango_ataque = 16.0
			velocidad_ataque = 1.2
			speed = 4.5
			era_entrenada = 4

		"trabuquete_contrapeso":
			unit_name = "Trabuquete de Contrapeso"
			attack_type = "ranged"
			weapon_type = "siege_stone"
			projectile_type = "fire_stone"
			_salud_base = 320.0
			salud_maxima = 320.0
			salud_actual = 320.0
			_daño_base = 120.0
			daño = 120.0
			rango_ataque = 45.0
			velocidad_ataque = 4.0
			speed = 2.5
			era_entrenada = 4

		"mosquetero_era5":
			unit_name = "Mosquetero de Pólvora"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 150.0
			salud_maxima = 150.0
			salud_actual = 150.0
			_daño_base = 24.0
			daño = 24.0
			rango_ataque = 18.0
			velocidad_ataque = 1.8
			speed = 4.3
			era_entrenada = 5

		"halberdier_era5":
			unit_name = "Alabardero Suizo"
			attack_type = "melee"
			weapon_type = "melee_pierce"
			impact_type = "MELEE_PIERCE"
			_salud_base = 207.0
			salud_maxima = 207.0
			salud_actual = 207.0
			_daño_base = 24.0
			daño = 24.0
			rango_ataque = 3.0
			velocidad_ataque = 0.95
			speed = 4.7
			era_entrenada = 5

		"conquistador_era5":
			unit_name = "Conquistador Ecuestre"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			is_cavalry = true
			_salud_base = 220.0
			salud_maxima = 220.0
			salud_actual = 220.0
			_daño_base = 22.0
			daño = 22.0
			rango_ataque = 10.0
			velocidad_ataque = 1.4
			speed = 6.2
			era_entrenada = 5

		"canon_culebrina_era5":
			unit_name = "Cañón Culebrina"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "GUNPOWDER"
			projectile_type = "fire_stone"
			_salud_base = 250.0
			salud_maxima = 250.0
			salud_actual = 250.0
			_daño_base = 110.0
			daño = 110.0
			rango_ataque = 28.0
			velocidad_ataque = 3.5
			speed = 2.4
			era_entrenada = 5

		"carro_blindado_davinci":
			unit_name = "Carro Blindado Da Vinci"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "SIEGE"
			projectile_type = "bullet"
			_salud_base = 340.0
			salud_maxima = 340.0
			salud_actual = 340.0
			_daño_base = 28.0
			daño = 28.0
			rango_ataque = 16.0
			velocidad_ataque = 2.0
			speed = 3.8
			era_entrenada = 5

		# ────────────────────────────────────────────────────────────
		# ERA 6 — EDAD INDUSTRIAL (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"fusilero_imperial":
			unit_name = "Fusilero Imperial"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 175.0
			salud_maxima = 175.0
			salud_actual = 175.0
			_daño_base = 28.0
			daño = 28.0
			rango_ataque = 20.0
			velocidad_ataque = 1.7
			speed = 4.4
			era_entrenada = 6

		"hussar_era6":
			unit_name = "Húsar a Caballo"
			attack_type = "melee"
			weapon_type = "sword"
			impact_type = "MELEE_SHOCK"
			is_cavalry = true
			_salud_base = 230.0
			salud_maxima = 230.0
			salud_actual = 230.0
			_daño_base = 26.0
			daño = 26.0
			rango_ataque = 3.2
			velocidad_ataque = 0.8
			speed = 6.8
			era_entrenada = 6

		"ametralladora_gatling":
			unit_name = "Ametralladora Gatling"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 220.0
			salud_maxima = 220.0
			salud_actual = 220.0
			_daño_base = 14.0
			daño = 14.0
			rango_ataque = 18.0
			velocidad_ataque = 1.2
			speed = 2.8
			era_entrenada = 6

		"steamtank_era6":
			unit_name = "Tanque de Vapor"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "GUNPOWDER"
			projectile_type = "fire_stone"
			is_cavalry = true
			is_stun_immune = true
			_salud_base = 450.0
			salud_maxima = 450.0
			salud_actual = 450.0
			_daño_base = 90.0
			daño = 90.0
			rango_ataque = 22.0
			velocidad_ataque = 3.2
			speed = 2.6
			era_entrenada = 6

		"camion_industrial":
			unit_name = "Camión Industrial"
			attack_type = "melee"
			weapon_type = "none"
			impact_type = "NONE"
			is_cavalry = true
			_salud_base = 320.0
			salud_maxima = 320.0
			salud_actual = 320.0
			_daño_base = 0.0
			daño = 0.0
			rango_ataque = 0.0
			velocidad_ataque = 1.0
			speed = 5.0
			era_entrenada = 6

		# ────────────────────────────────────────────────────────────
		# ERA 7 — EDAD ATÓMICA / PRIMERA GUERRA MUNDIAL (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"doughboy_era7":
			unit_name = "Doughboy de Trinchera"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 190.0
			salud_maxima = 190.0
			salud_actual = 190.0
			_daño_base = 30.0
			daño = 30.0
			rango_ataque = 22.0
			velocidad_ataque = 1.6
			speed = 4.3
			era_entrenada = 7

		"ametralladora_maxim":
			unit_name = "Ametralladora Maxim"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 240.0
			salud_maxima = 240.0
			salud_actual = 240.0
			_daño_base = 16.0
			daño = 16.0
			rango_ataque = 22.0
			velocidad_ataque = 1.0
			speed = 2.6
			era_entrenada = 7

		"mark_iv_tanque":
			unit_name = "Tanque Mark IV"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "GUNPOWDER"
			projectile_type = "bullet"
			is_cavalry = true
			is_stun_immune = true
			_salud_base = 400.0
			salud_maxima = 400.0
			salud_actual = 400.0
			_daño_base = 35.0
			daño = 35.0
			rango_ataque = 20.0
			velocidad_ataque = 2.0
			speed = 2.8
			era_entrenada = 7

		"biplano_fokker_era7":
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

		# ────────────────────────────────────────────────────────────
		# ERA 8 — EDAD ATÓMICA / SEGUNDA GUERRA MUNDIAL (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"gi_soldier_era8":
			unit_name = "Soldado GI WWII"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 210.0
			salud_maxima = 210.0
			salud_actual = 210.0
			_daño_base = 32.0
			daño = 32.0
			rango_ataque = 22.0
			velocidad_ataque = 0.85
			speed = 4.6
			era_entrenada = 8

		"sniper_era8":
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

		"hazmat_worker_era8":
			unit_name = "Técnico Biológico Hazmat"
			attack_type = "melee"
			weapon_type = "none"
			impact_type = "NONE"
			is_radiation_immune = true
			is_civilian = true
			_salud_base = 160.0
			salud_maxima = 160.0
			salud_actual = 160.0
			_daño_base = 0.0
			daño = 0.0
			rango_ataque = 0.0
			velocidad_ataque = 1.0
			speed = 4.8
			era_entrenada = 8

		"tanque_sherman_t34":
			unit_name = "Tanque Sherman T-34"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "GUN"
			projectile_type = "bullet"
			is_cavalry = true
			is_stun_immune = true
			_salud_base = 380.0
			salud_maxima = 380.0
			salud_actual = 380.0
			_daño_base = 55.0
			daño = 55.0
			rango_ataque = 22.0
			velocidad_ataque = 1.8
			speed = 5.2
			era_entrenada = 8

		"caza_helice_era8":
			unit_name = "Caza Monoplano P-51"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 220.0
			salud_maxima = 220.0
			salud_actual = 220.0
			_daño_base = 42.0
			daño = 42.0
			rango_ataque = 26.0
			velocidad_ataque = 1.0
			speed = 12.0
			era_entrenada = 8

		# ────────────────────────────────────────────────────────────
		# ERA 9 — EDAD ATÓMICA / MODERNA (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"spec_ops_era9":
			unit_name = "Operador SpecOps"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			has_thermal_vision = true
			_salud_base = 230.0
			salud_maxima = 230.0
			salud_actual = 230.0
			_daño_base = 35.0
			daño = 35.0
			rango_ataque = 24.0
			velocidad_ataque = 0.9
			speed = 5.0
			era_entrenada = 9

		"anti_tank_soldier_era9":
			unit_name = "Soldado Anti-Tanque"
			attack_type = "ranged"
			weapon_type = "missile"
			impact_type = "PIERCE"
			projectile_type = "rocket"
			_salud_base = 220.0
			salud_maxima = 220.0
			salud_actual = 220.0
			_daño_base = 45.0
			daño = 45.0
			rango_ataque = 16.0
			velocidad_ataque = 2.0
			speed = 4.2
			era_entrenada = 9

		"m1_abrams_tank":
			unit_name = "Tanque M1 Abrams"
			attack_type = "ranged"
			weapon_type = "cannon"
			impact_type = "GUN"
			projectile_type = "bullet"
			is_cavalry = true
			is_tank = true
			is_stun_immune = true
			_salud_base = 520.0
			salud_maxima = 520.0
			salud_actual = 520.0
			_daño_base = 80.0
			daño = 80.0
			rango_ataque = 24.0
			velocidad_ataque = 2.0
			speed = 5.5
			era_entrenada = 9

		"caza_reaccion_era9":
			unit_name = "Caza F-15 Jet"
			attack_type = "ranged"
			weapon_type = "missile"
			impact_type = "EXPLOSIVE"
			projectile_type = "rocket"
			_salud_base = 260.0
			salud_maxima = 260.0
			salud_actual = 260.0
			_daño_base = 60.0
			daño = 60.0
			rango_ataque = 28.0
			velocidad_ataque = 1.0
			speed = 18.0
			era_entrenada = 9

		"helicoptero_apache_era9":
			unit_name = "Helicóptero Apache"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			_salud_base = 320.0
			salud_maxima = 320.0
			salud_actual = 320.0
			_daño_base = 25.0
			daño = 25.0
			rango_ataque = 20.0
			velocidad_ataque = 0.6
			speed = 8.0
			era_entrenada = 9

		# ────────────────────────────────────────────────────────────
		# ERA 10 — EDAD DIGITAL (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"infiltrador_nano_era10", "infiltrador_nano":
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

		"soldado_emp_era10", "soldado_emp":
			unit_name = "Soldado de Pulso EMP"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "SHOCK"
			projectile_type = "bullet"
			_salud_base = 250.0
			salud_maxima = 250.0
			salud_actual = 250.0
			_daño_base = 30.0
			daño = 30.0
			rango_ataque = 18.0
			velocidad_ataque = 1.2
			speed = 4.8
			era_entrenada = 10

		"cyborg_militar_era10", "cyborg_militar":
			unit_name = "Cyborg Militar Pesado"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "GUN"
			projectile_type = "bullet"
			is_slow_immune = true
			_salud_base = 400.0
			salud_maxima = 400.0
			salud_actual = 400.0
			_daño_base = 28.0
			daño = 28.0
			rango_ataque = 20.0
			velocidad_ataque = 0.125 # 8 disparos por segundo
			speed = 4.6
			era_entrenada = 10

		"caza_furtivo_era10", "caza_furtivo":
			unit_name = "Caza Furtivo F-22"
			attack_type = "ranged"
			weapon_type = "missile"
			impact_type = "EXPLOSIVE"
			projectile_type = "rocket"
			is_stealth = true
			is_invisible = true
			_salud_base = 280.0
			salud_maxima = 280.0
			salud_actual = 280.0
			_daño_base = 65.0
			daño = 65.0
			rango_ataque = 28.0
			velocidad_ataque = 2.0
			speed = 20.0
			era_entrenada = 10

		# ────────────────────────────────────────────────────────────
		# ERA 11 — EDAD NANO-FUTURISTA (dbunitset.dat)
		# ────────────────────────────────────────────────────────────
		"cyber_hacker_era11", "cyber_hacker":
			unit_name = "Exosoldado Hacker de Red"
			attack_type = "ranged"
			weapon_type = "gun"
			impact_type = "ENERGY"
			projectile_type = "bullet"
			_salud_base = 320.0
			salud_maxima = 320.0
			salud_actual = 320.0
			_daño_base = 34.0
			daño = 34.0
			rango_ataque = 18.0
			velocidad_ataque = 1.1
			speed = 4.8
			era_entrenada = 11

		"humanoide_plasma_era11", "humanoide_plasma":
			unit_name = "Sintético de Plasma"
			attack_type = "ranged"
			weapon_type = "energy"
			impact_type = "ENERGY"
			projectile_type = "plasma"
			_salud_base = 450.0
			salud_maxima = 450.0
			salud_actual = 450.0
			_daño_base = 48.0
			daño = 48.0
			rango_ataque = 22.0
			velocidad_ataque = 1.0
			speed = 5.0
			era_entrenada = 11

		"plasmamech_bipedo_era11", "plasmamech_bipedo":
			unit_name = "PlasmaMech Bípedo"
			attack_type = "ranged"
			weapon_type = "plasma_cannon"
			impact_type = "ENERGY"
			projectile_type = "plasma"
			is_stun_immune = true
			is_slow_immune = true
			is_hack_immune = true
			_salud_base = 600.0
			salud_maxima = 600.0
			salud_actual = 600.0
			_daño_base = 65.0
			daño = 65.0
			rango_ataque = 20.0
			velocidad_ataque = 1.5
			speed = 4.8
			era_entrenada = 11

	_guard_position = global_position

func configurar_unidad(id: String) -> void:
	unit_id = id
	_setup_stats()

func _physics_process(_delta: float) -> void:
	if is_stunned or is_disabled:
		velocity = Vector3.ZERO
		move_and_slide()
		return

## Instancia y dispara físicamente un Projectile3D hacia el objetivo usando el socket ProjectileMuzzle.
func disparar_proyectil(target: Node3D) -> void:
	if is_dead or not is_instance_valid(target):
		return

	# Orientar hacia el enemigo antes de disparar
	var look_target := Vector3(target.global_position.x, global_position.y, target.global_position.z)
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)

	# 1. Búsqueda obligatoria del socket 'ProjectileMuzzle' ANTES de instanciar Projectile3D
	var muzzle: Node3D = find_child("ProjectileMuzzle", true, false) as Node3D
	var spawn_pos: Vector3
	if is_instance_valid(muzzle):
		spawn_pos = muzzle.global_position
	else:
		# Fallback con elevación de arma para mallas sin socket de Blender
		spawn_pos = global_position + Vector3(0.0, 1.2, 0.0)

	# 2. Instanciación del proyectil físico 3D con spawn exacto en el espacio 3D
	var proj_base_damage := daño * damage_modifier
	var proj := Projectile3D.new()
	proj.projectile_type = projectile_type
	proj.damage = proj_base_damage
	proj.bando = bando
	proj.source_unit = self
	proj.target_node = target
	proj.target_position = target.global_position + Vector3(0.0, 1.2, 0.0)

	var parent: Node = get_tree().current_scene.get_node_or_null("World/Projectiles") if get_tree() and get_tree().current_scene else null
	if not is_instance_valid(parent) and get_tree():
		parent = get_tree().current_scene
	if is_instance_valid(parent):
		parent.add_child(proj)
		proj.global_position = spawn_pos

	var snd: Node = get_node_or_null("/root/SoundManager")
	if is_instance_valid(snd):
		if snd.get("instance") != null and snd.instance.has_method("play_attack_alert"):
			snd.instance.play_attack_alert()
		elif snd.has_method("play_attack_alert"):
			snd.play_attack_alert()

	print("Soldier3D '%s': Disparado proyectil '%s' (Daño: %.1f) desde Muzzle en %s hacia '%s'" % [
		name, projectile_type, daño * damage_modifier, spawn_pos, target.name
	])

## Obtiene la posición global del socket de disparo 'ProjectileMuzzle' exportado desde Blender
func get_muzzle_position() -> Vector3:
	var muzzle: Node3D = find_child("ProjectileMuzzle", true, false) as Node3D
	if is_instance_valid(muzzle):
		return muzzle.global_position
	return global_position + Vector3(0.0, 1.2, 0.0)

func on_attack_impact(target: Node) -> void:
	if attack_type == "ranged" and is_instance_valid(target) and target is Node3D:
		disparar_proyectil(target as Node3D)
		_update_weapon_prop()
		return

	# Calcular daño base con counters EE (dbweapontohit.dat) y bono de altura (dbcliffterrain.dat)
	var base_dmg := daño * damage_modifier
	var effective_damage := base_dmg
	if target is Node3D:
		effective_damage = CombatDamageCalculator.calcular_dano(base_dmg, weapon_type, self, target as Node3D)

	# 0. Guerreros Era 0 (Prehistórica) - Counters Oficiales dbweapontohit.dat & dbanimals.dat
	if unit_id == "garrotero" or unit_id == "clubman_era0":
		# Clubman (Bludgeoning): multiplicador estricto x1.35 contra estructuras o empalizadas de madera
		if target is BuildingBase3D or target.is_in_group("buildings") or target.is_in_group("buildings_3d") or target.is_in_group("walls"):
			effective_damage = base_dmg * 1.35
			print("Clubman '%s': ¡Aplastamiento (Bludgeoning 1.35x) sobre estructura %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	elif unit_id == "maceman_bronze" or unit_id == "maceman_era2":
		# Macero de Cobre: x1.45 contra madera / palizada (superior al garrotero de piedra)
		var is_wood_structure: bool = target.is_in_group("walls") or target.is_in_group("walls_3d") or ("wall" in target.name.to_lower())
		var is_building: bool = target is BuildingBase3D or target.is_in_group("buildings") or target.is_in_group("buildings_3d")
		if is_wood_structure or is_building:
			effective_damage = base_dmg * 1.45
			print("Macero_Bronze '%s': ¡Aplastamiento de Cobre (1.45x) sobre estructura %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	elif unit_id == "retiarius_gladiador":
		# Gladiador Retiarius: lanza la red (ataque especial OneShot cada 8s)
		# La red aplica is_slowed = true (-50% velocidad) por 3.5 segundos
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)
		# Aplicar debuff de red (is_slowed) con duración oficial 3.5s
		_lanzar_red_retiarius(target)

	elif unit_id == "chariot_archer_era2" or unit_id == "carro_primitivo":
		# Carro de Guerra: ranged con polvo de galope
		if attack_type == "ranged" and is_instance_valid(target) and target is Node3D:
			disparar_proyectil(target as Node3D)
			_update_weapon_prop()
			return
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	elif unit_id == "spearman_era0" or unit_id == "lancero_silex":
		# Spearman (Piercing): multiplicador estricto x2.5 contra fauna pesada de la era (Mamuts / Elefantes)
		var is_heavy_fauna: bool = false
		if target.is_in_group("fauna") or target.is_in_group("animals"):
			is_heavy_fauna = true
		if "especie" in target:
			var esp: String = str(target.get("especie")).to_lower()
			if esp == "mamut" or esp == "elefante":
				is_heavy_fauna = true
		var tname := target.name.to_lower()
		if "mamut" in tname or "elefante" in tname:
			is_heavy_fauna = true
		if is_heavy_fauna:
			effective_damage = base_dmg * 2.5
			print("Spearman '%s': ¡Ataque Punzante (Piercing 2.5x) sobre fauna pesada %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# Guerreros Era 1 (Edad de Piedra) - Counters Oficiales dbweapontohit.dat
	elif unit_id == "axeman_era1":
		# Axeman (Slashing): x1.40 vs infantería ligera, x1.30 vs murallas de madera del rival
		var is_light_infantry: bool = target.is_in_group("infantry_3d") or target.is_in_group("villagers") or target is Soldier3D or target is Villager3D or CombatDamageCalculator._resolver_armor_type(target) == CombatDamageCalculator.ArmorType.INFANTRY
		var is_wall: bool = target.is_in_group("walls") or target.is_in_group("walls_3d") or ("wall" in target.name.to_lower())
		if is_light_infantry:
			effective_damage = base_dmg * 1.40
			print("Axeman '%s': ¡Filo de piedra pulida (1.40x) sobre infantería ligera %s!" % [name, target.name])
		elif is_wall:
			effective_damage = base_dmg * 1.30
			print("Axeman '%s': ¡Hachazo destructor (1.30x) sobre empalizada/muralla %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	elif unit_id == "lanzador_piedras":
		var is_infantry: bool = target.is_in_group("infantry_3d") or target.is_in_group("villagers") or target is Soldier3D or target is Villager3D or CombatDamageCalculator._resolver_armor_type(target) == CombatDamageCalculator.ArmorType.INFANTRY
		var target_wt: int = CombatDamageCalculator.WeaponType.NONE
		if "weapon_type" in target:
			target_wt = CombatDamageCalculator._resolver_weapon_type(str(target.get("weapon_type")))
		if is_infantry and target_wt == CombatDamageCalculator.WeaponType.MELEE_SHOCK:
			effective_damage = base_dmg * 1.5
			print("Lanzador_Piedras '%s': ¡Impacto balístico (1.5x) sobre infantería MELEE_SHOCK %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	elif unit_id == "scout_era1":
		var is_bld: bool = target is BuildingBase3D or target.is_in_group("buildings") or target.is_in_group("buildings_3d") or target.is_in_group("walls") or target.is_in_group("walls_3d")
		if is_bld:
			effective_damage = 0.0
			print("Scout '%s': Explorador no puede dañar estructuras." % name)
		else:
			if target.has_method("recibir_daño"):
				target.call("recibir_daño", effective_damage, self)

	elif unit_id == "maceman_era1":
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 4. Infiltrador Óptico (Golpe Crítico de Apertura 2.5x desde Oculto)
	elif unit_id == "infiltrador_nano":
		if is_cloaked:
			effective_damage *= 2.5
			is_cloaked = false
			print("Infiltrador Óptico '%s': ¡Disparo crítico de apertura (2.5x) sobre %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 5. Exosoldado Hacker (Hackeo y Sobreescritura de Red en Mecánicos/Torres)
	elif unit_id == "cyber_hacker":
		if target.has_method("aplicar_hackeo_red"):
			target.call("aplicar_hackeo_red", 4.0)
			print("Exosoldado Hacker '%s': Haz de hackeo transmitido hacia %s" % [name, target.name])

	# 6. Soldado EMP Anti-Drones (Cortocircuito Stun 4.0s sin daño humano)
	elif unit_id == "soldado_emp":
		if target.is_in_group("drones") or target.is_in_group("flying"):
			if target.has_method("aplicar_aturdimiento"):
				target.call("aplicar_aturdimiento", 4.0)
				print("Soldado EMP '%s': ¡Pulso EMP en masa! Dron %s deshabilitado 4.0s" % [name, target.name])
		else:
			print("Soldado EMP '%s': Objetivo no es dron. Pulso inefectivo." % name)

	# 7. Soldado Antiaéreo (Multiplicador de Daño 4.0x contra Drones / Voladores)
	elif unit_id == "soldado_antiaereo":
		if target.is_in_group("drones") or target.is_in_group("flying"):
			effective_damage *= 4.0
			print("Soldado Antiaéreo '%s': ¡Impacto pesado 4.0x contra dron/volador %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 8. Piquero Anti-Gregario (Multiplicador de Daño 3.5x contra Caballería/Vehículos)
	elif unit_id == "piquero_antigregario":
		if target.is_in_group("vehicles_3d"):
			effective_damage *= 3.5
			print("Piquero '%s': ¡Carga de caballería frenada! Impacto 3.5x sobre %s" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 9. Soldado RPG Perforante (Multiplicador de Daño 3.5x contra Tanques/Vehículos)
	elif unit_id == "soldado_rpg":
		if target.is_in_group("vehicles_3d"):
			effective_damage *= 3.5
			print("Soldado RPG '%s': ¡Misil perforante 3.5x sobre blindado %s!" % [name, target.name])
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 10. Tanque Pesado (Daño de Cañón de Asalto AoE 5.0m)
	elif unit_id == "tanque_pesado":
		var target_group := "enemy_units" if bando == Bando.PLAYER else "player_units"
		var target_bld := "enemy_buildings" if bando == Bando.PLAYER else "player_buildings"

		for u in get_tree().get_nodes_in_group(target_group) + get_tree().get_nodes_in_group(target_bld):
			if is_instance_valid(u) and u is Node3D:
				var dist := global_position.distance_to((u as Node3D).global_position)
				if dist <= 5.0:
					if u.has_method("recibir_daño"):
						u.call("recibir_daño", effective_damage * 0.9, self)

	else:
		if target.has_method("recibir_daño"):
			target.call("recibir_daño", effective_damage, self)

	# 1. Brawler Primitivo (Aturdimiento Stun 15% por 1.5s sobre infantería ligera)
	if unit_id == "brawler_primitivo":
		var is_light_infantry: bool = target.is_in_group("infantry_3d") or target.is_in_group("villagers") or target.is_in_group("unidades") or target is Soldier3D or target is Villager3D
		if not is_light_infantry and target is Node3D:
			var at := CombatDamageCalculator._resolver_armor_type(target)
			if at == CombatDamageCalculator.ArmorType.INFANTRY or at == CombatDamageCalculator.ArmorType.NONE:
				is_light_infantry = true
		if is_light_infantry:
			if randf() <= 0.15:
				if target.has_method("aplicar_aturdimiento"):
					target.call("aplicar_aturdimiento", 1.5)
				elif "is_stunned" in target:
					target.set("is_stunned", true)
				print("Brawler '%s': ¡Golpe aturdidor (15%% Stun 1.5s) exitoso sobre %s!" % [name, target.name])

	# 3. Lanzallamas de Trinchera (AoE DoT Fuego en 4.0m)
	elif unit_id == "flamethrower_atómico":
		var target_group := "enemy_units" if bando == Bando.PLAYER else "player_units"
		var target_bld := "enemy_buildings" if bando == Bando.PLAYER else "player_buildings"

		for u in get_tree().get_nodes_in_group(target_group) + get_tree().get_nodes_in_group(target_bld):
			if is_instance_valid(u) and u is Node3D:
				var dist := global_position.distance_to((u as Node3D).global_position)
				if dist <= 4.0:
					if u.has_method("recibir_daño"):
						u.call("recibir_daño", effective_damage * 0.8, self)
					if u.has_method("aplicar_quemadura"):
						u.call("aplicar_quemadura", 3.0, 5.0)

	_update_weapon_prop()

func _ready() -> void:
	super._ready()
	add_to_group("military_units")
	add_to_group("infantry_3d")

	if unit_id == "dron_enjambre" or unit_id == "dron_titan":
		add_to_group("drones")
		add_to_group("flying")
	elif unit_id == "caballero_pesado" or unit_id == "tanque_pesado":
		add_to_group("vehicles_3d")

	# Conectar al sistema global de Eras
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if is_instance_valid(rm) and rm.has_signal("era_evolucionada"):
		if not rm.era_evolucionada.is_connected(_on_era_evolucionada):
			rm.era_evolucionada.connect(_on_era_evolucionada)

func _process(delta: float) -> void:
	if is_dead:
		return

	# Aura de Inspiración del Oficial de Línea (10.0m)
	if unit_id == "line_officer":
		_process_line_officer_aura(delta)

	# Escaneo pasivo de enemigos en estado Idle o cuando no hay objetivo activo
	_scan_timer += delta
	if _scan_timer >= SCAN_INTERVAL:
		_scan_timer = 0.0
		if _debe_escanaer_enemigos():
			_scan_for_enemies()

func _process_line_officer_aura(_delta: float) -> void:
	var my_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
	for ally in get_tree().get_nodes_in_group(my_group):
		if is_instance_valid(ally) and ally != self and ally is Node3D:
			var dist := global_position.distance_to((ally as Node3D).global_position)
			if dist <= 10.0 and ally.has_method("set_status_text"):
				ally.call("set_status_text", "⭐ ¡Inspirado por el Oficial!", 1.0)

func morir() -> void:
	if unit_id == "line_officer":
		var my_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
		for ally in get_tree().get_nodes_in_group(my_group):
			if is_instance_valid(ally) and ally != self and ally is Node3D:
				var dist := global_position.distance_to((ally as Node3D).global_position)
				if dist <= 10.0 and ally.has_method("aplicar_penalizacion_moral"):
					ally.call("aplicar_penalizacion_moral", 0.2, 5.0)
					print("Oficial de Línea caído: Pánico moral (-20% daño) aplicado a %s" % (ally as Node3D).name)
	super.morir()

# ─── Fuerza de Separación Táctica RTS (Steering Evasion) ─────────────────────

func calculate_separation_force() -> Vector3:
	var separation := Vector3.ZERO
	var my_group := "player_units" if bando == Bando.PLAYER else "enemy_units"
	var count := 0

	for ally in get_tree().get_nodes_in_group(my_group):
		if ally != self and is_instance_valid(ally) and ally is Node3D:
			var ally_node := ally as Node3D
			var dist := global_position.distance_to(ally_node.global_position)
			if dist > 0.001 and dist < 1.2:
				var push_dir := (global_position - ally_node.global_position).normalized()
				separation += push_dir / dist
				count += 1

	if count > 0:
		separation = (separation / float(count)).normalized() * 1.8
	return separation

# ─── Comandos de Combate y Navegación ──────────────────────────────────────────

## Ordena a la unidad moverse a una coordenada 3D.
## Si la unidad está en combate, activa el override inmediato de la FSM.
func command_move(target_pos: Vector3) -> void:
	_guard_position = target_pos
	set_meta("new_move_command", target_pos)
	# Interrumpir el combate si estamos atacando (override manual del jugador)
	if state_machine and is_instance_valid(state_machine.current_state):
		if state_machine.current_state.state_name == &"Attacking":
			state_machine.current_state.set("_manual_move_override", true)
			state_machine.current_state.set("_target", null)
	if state_machine:
		state_machine.change_state(&"Move", {"target_position": target_pos})

func command_move_to(target_pos: Vector3) -> void:
	command_move(target_pos)

## Ordena atacar directamente a un nodo enemigo objetivo.
func command_attack(target: Node) -> void:
	if is_dead or not is_instance_valid(target) or target == self:
		return

	# Bloqueo estricto de fuego amigo
	if "bando" in target and int(target.bando) == int(bando):
		return
	if bando == Bando.PLAYER and (target.is_in_group("player_units") or target.is_in_group("player_buildings") or target.is_in_group("allies")):
		return
	if bando == Bando.ENEMY and (target.is_in_group("enemy_units") or target.is_in_group("enemy_buildings")):
		return

	# Scout_Era1 bloqueado por código de atacar estructuras
	if unit_id == "scout_era1":
		if target is BuildingBase3D or target.is_in_group("buildings") or target.is_in_group("buildings_3d") or target.is_in_group("walls") or target.is_in_group("walls_3d"):
			print("Scout '%s': Bloqueado por código para atacar estructuras." % name)
			return

	if state_machine:
		state_machine.change_state(&"Attacking", {"target": target})

## Bloqueo de recolección de recursos en unidades militares / exploradores
func command_gather(_target: Node3D) -> void:
	print("Soldier3D '%s': Esta unidad no puede recolectar recursos." % name)
	return

func _aplicar_bonos_civilizacion() -> void:
	var civ_name: String = civilizacion.strip_edges().to_lower()
	if civ_name == "" and has_meta("civilizacion"):
		civ_name = str(get_meta("civilizacion")).strip_edges().to_lower()

	if civ_name == "" or civ_name == "ninguna":
		var rm: Node = get_node_or_null("/root/GlobalResourceManager")
		if not is_instance_valid(rm):
			rm = get_node_or_null("/root/ResourceManager")
		if is_instance_valid(rm) and "civilizacion_activa" in rm and str(rm.civilizacion_activa) != "ninguna":
			civ_name = str(rm.civilizacion_activa).strip_edges().to_lower()

	if civ_name == "ingleses" or civ_name == "english":
		if unit_id == "bowman_era1" or attack_type == "ranged":
			daño = _daño_base * 1.15
			rango_ataque = 14.0 * 1.15
			print("Soldier3D '%s': Bono de civilización Inglesa (+15%% daño y rango) aplicado." % name)

## Cambia la postura táctica de la unidad.
func set_postura(nueva_postura: Postura) -> void:
	postura_actual = nueva_postura
	_guard_position = global_position
	print("Soldier3D '%s': Postura cambiada a %s" % [name, Postura.keys()[nueva_postura]])

# ─── Escaneo Pasivo y Posturas Tácticas ────────────────────────────────────────

func _debe_escanaer_enemigos() -> bool:
	if state_machine == null or state_machine.current_state == null:
		return true
	var sname: StringName = state_machine.current_state.state_name
	return sname == &"Idle" or sname == &"Move"

func _scan_for_enemies() -> void:
	if is_dead or postura_actual == Postura.MANTENER_TERRENO and state_machine.current_state.state_name != &"Idle":
		return

	var target_group: String = "enemy_units" if bando == Bando.PLAYER else "player_units"
	var target_buildings: String = "enemy_buildings" if bando == Bando.PLAYER else "player_buildings"

	var nearest_enemy: Node3D = null
	var min_dist: float = radio_vision

	# 1. Escanear unidades enemigas cercanas (ignorando camufladas)
	for u in get_tree().get_nodes_in_group(target_group):
		if is_instance_valid(u) and not (u.has_method("is_dead") and u.call("is_dead")):
			if "is_cloaked" in u and bool(u.get("is_cloaked")) == true:
				continue # Camuflaje cuántico activo: invisible al escáner enemigo
			var dist := global_position.distance_to((u as Node3D).global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_enemy = u as Node3D

	# 2. Escanear edificios enemigos si no hay unidades en rango
	if nearest_enemy == null:
		for b in get_tree().get_nodes_in_group(target_buildings):
			if is_instance_valid(b) and not (b.has_method("is_dead") and b.call("is_dead")):
				var dist := global_position.distance_to((b as Node3D).global_position)
				if dist < min_dist:
					min_dist = dist
					nearest_enemy = b as Node3D

	# 3. Reaccionar según la postura táctica
	if is_instance_valid(nearest_enemy):
		match postura_actual:
			Postura.AGRESIVA:
				command_attack(nearest_enemy)
			Postura.DEFENSIVA:
				if min_dist <= radio_vision * 0.7:
					command_attack(nearest_enemy)
			Postura.MANTENER_TERRENO:
				if min_dist <= rango_ataque:
					command_attack(nearest_enemy)

# ─── Actualización Visual y Respuesta a Eras ────────────────────────────────────

func _update_weapon_prop() -> void:
	if has_method("set_hand_prop"):
		call("set_hand_prop", weapon_type)

## Callback invocado cuando el Imperio evoluciona de Era.
func _on_era_evolucionada(player_id: int = 0, _nueva_era: int = 0) -> void:
	if is_dead:
		return

	if self.owner_peer_id != player_id:
		return

	# REGLA TÁCTICA EMPIRE EARTH: Preservación Militar
	# Soldier3D es por definición una unidad de combate militar. Las unidades militares ya desplegadas
	# físicamente en el mapa conservan su malla, velocidad de ataque y balística original (no mutan automáticamente).
	var e_entrenada: int = int(get("era_entrenada")) if get("era_entrenada") != null else 0
	print("Soldier3D '%s': Veterano militar (Era %d) preservado intacto en combate." % [name, e_entrenada])
	return

func _actualizar_modelo_visual_era(era_val: int) -> void:
	var target_key: String = "Primitive_Mesh"
	match era_val:
		0, 1, 2:
			target_key = "Primitive_Mesh"
		3, 4, 5:
			target_key = "Historical_Mesh"
		6, 7:
			target_key = "Industrial_Mesh"
		8, 9:
			target_key = "Futuristic_Mesh"

	var found := false
	for child in get_children():
		if child is MeshInstance3D:
			if child.name.contains(target_key) or child.name.begins_with("EraMesh_"):
				child.visible = true
				found = true
			else:
				child.visible = false

# ─── Era 2: Gladiador Retiarius — Debuff de Red ─────────────────────────────

## Lanza la red (Tridente Retiarius): aplica is_slowed = true en el objetivo
## reduciendo su velocidad exactamente un -50% durante 3.5 segundos.
## Se usa un timer interno para restaurar la velocidad al expirar.
func _lanzar_red_retiarius(target: Node) -> void:
	if not is_instance_valid(target):
		return

	# Aplicar estado is_slowed y reducir velocidad exactamente -50%
	if "is_slowed" in target:
		target.set("is_slowed", true)
	if "speed" in target:
		var original_speed: float = float(target.get("speed"))
		# Guardar velocidad original solo si no está ya ralentizado
		if not ("_original_speed_before_net" in target) or float(target.get("_original_speed_before_net")) <= 0.0:
			target.set_meta("_original_speed_before_net", original_speed)
		target.set("speed", original_speed * 0.5)
		print("Retiarius '%s': ¡Red lanzada! %s ralentizado -50%% (%.1f m/s) por 3.5s." % [name, target.name, original_speed * 0.5])

	# Timer de restauración de velocidad (3.5s oficial dbunitset.dat)
	var restore_timer := Timer.new()
	restore_timer.name = "_NetRestoreTimer"
	restore_timer.wait_time = 3.5
	restore_timer.one_shot = true
	add_child(restore_timer)
	# Conectar restauración con funcRef capturada
	restore_timer.timeout.connect(func() -> void:
		if is_instance_valid(target):
			if "is_slowed" in target:
				target.set("is_slowed", false)
			if target.has_meta("_original_speed_before_net"):
				target.set("speed", float(target.get_meta("_original_speed_before_net")))
				target.remove_meta("_original_speed_before_net")
		if is_instance_valid(restore_timer):
			restore_timer.queue_free()
	)
	restore_timer.start()

# ─── Era 2: Carro de Guerra — Polvo de Galope ────────────────────────────────

## Emite partículas de polvo continuo mientras el Carro de Guerra galopa.
## Llamado desde physics_update de la unidad/FSM si está en movimiento.
func _emit_chariot_dust_particles() -> void:
	if unit_id != "chariot_archer_era2" and unit_id != "carro_primitivo":
		return
	if velocity.length_squared() < 0.5:
		return
	# Buscar o crear nodo de partículas de polvo
	var dust: GPUParticles3D = get_node_or_null("ChariotDustParticles") as GPUParticles3D
	if not is_instance_valid(dust):
		dust = GPUParticles3D.new()
		dust.name = "ChariotDustParticles"
		dust.emitting = false
		dust.amount = 12
		dust.lifetime = 0.6
		dust.explosiveness = 0.0
		add_child(dust)
	dust.emitting = true
